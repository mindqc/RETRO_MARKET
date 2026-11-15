<?php

namespace Tests\Feature\Api\V1;

use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\Dispute;
use App\Models\DisputeEvidence;
use App\Models\EscrowTransaction;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\SellerProfile;
use App\Models\Shipment;
use App\Models\User;
use App\Models\UserProfile;
use App\Models\WalletTransaction;
use App\Services\Escrow\DisputeService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class EscrowShippingAndDisputeTest extends TestCase
{
    /**
     * Helper to create an isolated user with profile and seller profile.
     */
    protected function createIsolatedUser(string $prefix, UserRole $role = UserRole::REGISTERED_USER): User
    {
        $unique = $prefix . '_' . bin2hex(random_bytes(5));
        $user = User::create([
            'display_name' => 'User ' . $unique,
            'email' => $unique . '@izithrift.test',
            'password_hash' => Hash::make('Retro@2026'),
            'role' => $role,
            'status' => UserStatus::ACTIVE,
        ]);

        UserProfile::create([
            'user_id' => $user->id,
            'seasonal_decor_enabled' => true,
        ]);

        SellerProfile::create([
            'user_id' => $user->id,
            'shop_slug' => 'shop-' . $unique,
            'trust_score' => 100.00,
            'wallet_balance' => 0.00,
            'escrow_held_balance' => 0.00,
            'completed_orders_count' => 0,
            'dispute_lost_count' => 0,
        ]);

        return $user;
    }

    /**
     * Clean up an isolated order and its linked ledger records.
     */
    protected function cleanUpOrder(int $orderId): void
    {
        DB::table('dispute_evidences')
            ->whereIn('dispute_id', function ($q) use ($orderId) {
                $q->select('id')->from('disputes')->where('order_id', $orderId);
            })->delete();

        DB::table('disputes')->where('order_id', $orderId)->delete();
        DB::table('wallet_transactions')->where('order_id', $orderId)->delete();
        DB::table('escrow_transactions')->where('order_id', $orderId)->delete();
        DB::table('payments')->where('order_id', $orderId)->delete();
        DB::table('shipments')->where('order_id', $orderId)->delete();
        DB::table('order_items')->where('order_id', $orderId)->delete();
        DB::table('orders')->where('id', $orderId)->delete();
    }

    /**
     * Clean up an isolated user.
     */
    protected function cleanUpUser(int $userId): void
    {
        DB::table('notifications')->where('user_id', $userId)->delete();
        DB::table('seller_profiles')->where('user_id', $userId)->delete();
        DB::table('user_profiles')->where('user_id', $userId)->delete();
        DB::table('users')->where('id', $userId)->delete();
    }

    /**
     * 1. Test seller fulfillment pipeline: PAID -> PREPARING -> SHIPPED -> DELIVERED
     * freezes auto_complete_at timestamp (BR-OR-05 / ADR-05).
     */
    public function test_seller_fulfillment_pipeline_paid_to_preparing_to_shipped_to_delivered_freezes_auto_complete_at_br_or_05(): void
    {
        $seller = null;
        $buyer = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('fulfill_seller');
            $buyer = $this->createIsolatedUser('fulfill_buyer');

            $order = Order::create([
                'order_code' => 'ORD-FULFILL-' . time(),
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 200000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 19000.00,
                'total_amount' => 219000.00,
                'seller_net_amount' => 200000.00,
                'shipping_address_snapshot' => ['recipient_name' => 'Linh', 'phone' => '0901234567'],
                'order_status' => OrderStatus::PAID,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::NONE,
                'payment_expires_at' => now()->addMinutes(30),
                'paid_at' => now(),
            ]);

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => 1,
                'product_code_snapshot' => 'PRD-FULFILL-001',
                'product_title_snapshot' => 'Váy vintage hoa nhí',
                'unit_price_snapshot' => 200000.00,
                'quantity' => 1,
                'line_total' => 200000.00,
                'condition_snapshot' => 'LIKE_NEW',
                'defect_info_snapshot' => 'Không có lỗi',
                'primary_image_snapshot' => 'https://izithrift.local/storage/sample.jpg',
            ]);

            $sellerToken = $seller->createToken('seller_token')->plainTextToken;

            // Step 1: Mark Preparing
            auth()->forgetGuards();
            $prepRes = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->postJson("/api/v1/seller/orders/{$order->id}/prepare");

            $prepRes->assertStatus(200);
            $this->assertEquals('PREPARING', $prepRes->json('data.order_status'));
            $this->assertNotNull($prepRes->json('data.preparing_at'));

            // Step 2: Mark Shipped
            auth()->forgetGuards();
            $shipRes = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->postJson("/api/v1/seller/orders/{$order->id}/ship", [
                    'carrier_name' => 'Giao Hàng Tiết Kiệm',
                    'tracking_code' => 'GHTK-99887711',
                    'shipping_note' => 'Hàng vintage dễ xước',
                ]);

            $shipRes->assertStatus(200);
            $this->assertEquals('SHIPPED', $shipRes->json('data.order_status'));
            $this->assertNotNull($shipRes->json('data.shipped_at'));
            $this->assertDatabaseHas('shipments', [
                'order_id' => $order->id,
                'carrier_name' => 'Giao Hàng Tiết Kiệm',
                'tracking_code' => 'GHTK-99887711',
                'status' => 'SHIPPED',
            ]);

            // Step 3: Mark Delivered (Freezes auto_complete_at)
            auth()->forgetGuards();
            $delivRes = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->postJson("/api/v1/seller/orders/{$order->id}/deliver");

            $delivRes->assertStatus(200);
            $this->assertEquals('DELIVERED', $delivRes->json('data.order_status'));
            $this->assertNotNull($delivRes->json('data.delivered_at'));
            $this->assertNotNull($delivRes->json('data.auto_complete_at'));

            // Verify auto_complete_at is strictly in the future
            $autoCompleteAt = strtotime($delivRes->json('data.auto_complete_at'));
            $this->assertGreaterThan(time(), $autoCompleteAt);

            $this->assertDatabaseHas('shipments', [
                'order_id' => $order->id,
                'status' => 'DELIVERED',
            ]);
        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
        }
    }

    /**
     * 2. Test buyer confirm delivery releases 100% item_subtotal to seller wallet idempotently (DEC-04 / OF-05 / BR-FN-07).
     */
    public function test_buyer_confirm_delivery_releases_100_percent_item_subtotal_to_seller_wallet_idempotently_dec04(): void
    {
        $seller = null;
        $buyer = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('esc_seller');
            $seller->sellerProfile()->update(['escrow_held_balance' => 500000.00]);

            $buyer = $this->createIsolatedUser('esc_buyer');

            $order = Order::create([
                'order_code' => 'ORD-ESC-' . time(),
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 500000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 37000.00,
                'total_amount' => 537000.00,
                'seller_net_amount' => 500000.00,
                'shipping_address_snapshot' => ['recipient_name' => 'Kiệt', 'phone' => '0907654321'],
                'order_status' => OrderStatus::DELIVERED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::NONE,
                'payment_expires_at' => now()->addMinutes(30),
                'paid_at' => now(),
                'delivered_at' => now(),
            ]);

            Payment::create([
                'payment_code' => 'PMT-ESC-' . time(),
                'order_id' => $order->id,
                'payer_id' => $buyer->id,
                'amount' => 537000.00,
                'qr_payload' => 'vietqr://mock-payload-537k',
                'payment_method' => 'MOCK_VIETQR',
                'payment_reference' => 'REF-ESC-' . time(),
                'status' => PaymentStatus::PAID,
                'expires_at' => now()->addMinutes(30),
                'paid_at' => now(),
            ]);

            $buyerToken = $buyer->createToken('buyer_token')->plainTextToken;

            // Buyer confirms delivery
            auth()->forgetGuards();
            $res = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->postJson("/api/v1/orders/{$order->id}/confirm-delivery");

            $res->assertStatus(200);
            $this->assertEquals('COMPLETED', $res->json('data.order_status'));
            $this->assertEquals('RELEASED', $res->json('data.escrow_status'));

            // Check immutable EscrowTransaction
            $this->assertDatabaseHas('escrow_transactions', [
                'order_id' => $order->id,
                'transaction_type' => 'RELEASE',
                'gross_amount' => '537000.00',
                'seller_released_amount' => '500000.00',
                'buyer_refunded_amount' => '0.00',
                'platform_fee_retained' => '37000.00',
            ]);

            // Check immutable WalletTransaction
            $this->assertDatabaseHas('wallet_transactions', [
                'seller_id' => $seller->id,
                'order_id' => $order->id,
                'entry_type' => 'CREDIT',
                'amount' => '500000.00',
                'balance_before' => '0.00',
                'balance_after' => '500000.00',
            ]);

            // Check SellerProfile balances
            $profile = $seller->sellerProfile()->first();
            $this->assertEquals(500000.00, (float) $profile->wallet_balance);
            $this->assertEquals(0.00, (float) $profile->escrow_held_balance);
            $this->assertEquals(1, $profile->completed_orders_count);

            // Test Idempotency: Calling confirm-delivery a second time does not double-credit
            auth()->forgetGuards();
            $idempotentRes = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->postJson("/api/v1/orders/{$order->id}/confirm-delivery");

            $idempotentRes->assertStatus(200);
            $this->assertEquals('COMPLETED', $idempotentRes->json('data.order_status'));

            $txCount = DB::table('wallet_transactions')->where('order_id', $order->id)->count();
            $this->assertEquals(1, $txCount);
            $this->assertEquals(500000.00, (float) $seller->sellerProfile()->value('wallet_balance'));
        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
        }
    }

    /**
     * 3. Test seller wallet endpoint returns accurate balances and immutable ledger history (M-SL-08).
     */
    public function test_seller_wallet_endpoint_returns_accurate_balances_and_immutable_ledger_history(): void
    {
        $seller = null;

        try {
            $seller = $this->createIsolatedUser('wallet_seller');
            $seller->sellerProfile()->update([
                'wallet_balance' => 850000.00,
                'escrow_held_balance' => 200000.00,
                'completed_orders_count' => 3,
            ]);

            $sellerToken = $seller->createToken('seller_token')->plainTextToken;

            auth()->forgetGuards();
            $res = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->getJson('/api/v1/seller/wallet');

            $res->assertStatus(200);
            $res->assertJsonPath('success', true);
            $this->assertEquals(850000.00, (float) $res->json('data.wallet_balance'));
            $this->assertEquals(200000.00, (float) $res->json('data.escrow_held_balance'));
            $this->assertEquals(3, (int) $res->json('data.completed_orders_count'));
            $this->assertIsArray($res->json('data.wallet_transactions'));
            $this->assertArrayHasKey('pagination', $res->json('data'));
        } finally {
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
        }
    }

    /**
     * 4. Test buyer can open dispute ONLY at SHIPPED or DELIVERED (DEC-03) and freezes escrow release (BR-DP-02).
     */
    public function test_buyer_can_open_dispute_only_at_shipped_or_delivered_dec03_and_freezes_escrow_release_br_dp_02(): void
    {
        $seller = null;
        $buyer = null;
        $paidOrder = null;
        $shippedOrder = null;

        try {
            $seller = $this->createIsolatedUser('dsp_seller');
            $buyer = $this->createIsolatedUser('dsp_buyer');
            $buyerToken = $buyer->createToken('buyer_token')->plainTextToken;

            // Order 1: PAID (Dispute must be blocked with 409 DEC-03)
            $paidOrder = Order::create([
                'order_code' => 'ORD-DISP-PAID-' . time(),
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 100000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 13000.00,
                'total_amount' => 113000.00,
                'seller_net_amount' => 100000.00,
                'shipping_address_snapshot' => ['recipient_name' => 'Buyer', 'phone' => '0901234567'],
                'order_status' => OrderStatus::PAID,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::NONE,
                'payment_expires_at' => now()->addMinutes(30),
            ]);

            auth()->forgetGuards();
            $blockedRes = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->postJson("/api/v1/orders/{$paidOrder->id}/disputes", [
                    'reason_category' => 'ITEM_DEFECTIVE',
                    'description' => 'Sản phẩm lỗi nhưng đơn chưa giao hàng.',
                ]);

            $blockedRes->assertStatus(409);

            // Order 2: SHIPPED (Dispute must succeed and freeze escrow)
            $shippedOrder = Order::create([
                'order_code' => 'ORD-DISP-SHIP-' . time(),
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 300000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 25000.00,
                'total_amount' => 325000.00,
                'seller_net_amount' => 300000.00,
                'shipping_address_snapshot' => ['recipient_name' => 'Buyer', 'phone' => '0901234567'],
                'order_status' => OrderStatus::SHIPPED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::NONE,
                'payment_expires_at' => now()->addMinutes(30),
                'shipped_at' => now(),
            ]);

            auth()->forgetGuards();
            $successRes = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->postJson("/api/v1/orders/{$shippedOrder->id}/disputes", [
                    'reason_category' => 'ITEM_NOT_AS_DESCRIBED',
                    'description' => 'Áo len bị rách một đường lớn ở tay áo không đúng mô tả.',
                ]);

            $successRes->assertStatus(201);
            $this->assertEquals('OPEN', $successRes->json('data.status'));
            $this->assertEquals('ITEM_NOT_AS_DESCRIBED', $successRes->json('data.reason_category'));

            // Check Order has dispute_status = OPEN and escrow_frozen_at is NOT NULL (BR-DP-02)
            $freshOrder = Order::find($shippedOrder->id);
            $this->assertEquals('OPEN', $freshOrder->dispute_status->value);
            $this->assertNotNull($freshOrder->escrow_frozen_at);

            // Try to confirm delivery while dispute is OPEN -> must be blocked with 409
            auth()->forgetGuards();
            $confirmBlockedRes = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->postJson("/api/v1/orders/{$shippedOrder->id}/confirm-delivery");

            $confirmBlockedRes->assertStatus(409);
        } finally {
            if ($paidOrder) {
                $this->cleanUpOrder($paidOrder->id);
            }
            if ($shippedOrder) {
                $this->cleanUpOrder($shippedOrder->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
        }
    }

    /**
     * 5. Test seller counter evidence and support request more info transitions dispute state (SF-11 / PERM-CM-08).
     */
    public function test_seller_counter_evidence_and_support_request_more_info_transitions_dispute_state(): void
    {
        $seller = null;
        $buyer = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('ev_seller');
            $buyer = $this->createIsolatedUser('ev_buyer');
            $support = User::where('email', 'support@izithrift.local')->firstOrFail();

            $order = Order::create([
                'order_code' => 'ORD-EV-' . time(),
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 250000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 22000.00,
                'total_amount' => 272000.00,
                'seller_net_amount' => 250000.00,
                'shipping_address_snapshot' => ['recipient_name' => 'Buyer', 'phone' => '0901234567'],
                'order_status' => OrderStatus::DELIVERED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::OPEN,
                'payment_expires_at' => now()->addMinutes(30),
                'escrow_frozen_at' => now(),
            ]);

            $dispute = Dispute::create([
                'dispute_code' => 'DSP-EV-' . time(),
                'order_id' => $order->id,
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'opened_at_order_status' => 'DELIVERED',
                'reason_category' => 'ITEM_DEFECTIVE',
                'buyer_description' => 'Hàng có vết ố vàng lớn.',
                'status' => DisputeStatus::OPEN,
            ]);

            $sellerToken = $seller->createToken('seller_token')->plainTextToken;
            $supportToken = $support->createToken('support_token')->plainTextToken;
            $buyerToken = $buyer->createToken('buyer_token')->plainTextToken;

            // 1. Seller submits counter evidence
            auth()->forgetGuards();
            $sellerEvRes = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->postJson("/api/v1/disputes/{$dispute->id}/evidences", [
                    'message_note' => 'Tôi đã gửi đúng ảnh chụp thật không có vết ố nào trước khi giao.',
                ]);

            $sellerEvRes->assertStatus(201);
            $this->assertEquals('SELLER', $sellerEvRes->json('data.uploader_role'));
            $this->assertEquals('SELLER_COUNTER_PROOF', $sellerEvRes->json('data.evidence_type'));
            $this->assertEquals('Tôi đã gửi đúng ảnh chụp thật không có vết ố nào trước khi giao.', Dispute::find($dispute->id)->seller_response);

            // 2. Support staff requests more information (PERM-CM-08)
            auth()->forgetGuards();
            $supportEvRes = $this->withHeader('Authorization', "Bearer {$supportToken}")
                ->postJson("/api/v1/disputes/{$dispute->id}/evidences", [
                    'message_note' => 'Yêu cầu cả hai bên cung cấp video mở hộp và hình ảnh cận cảnh nhãn mác.',
                ]);

            $supportEvRes->assertStatus(201);
            $this->assertEquals('SUPPORT', $supportEvRes->json('data.uploader_role'));
            $this->assertEquals('STAFF_REQUEST_NOTE', $supportEvRes->json('data.evidence_type'));

            $disputeAfterSupport = Dispute::find($dispute->id);
            $this->assertEquals('NEED_MORE_INFO', $disputeAfterSupport->status->value);
            $this->assertEquals($support->id, $disputeAfterSupport->assigned_support_id);

            // 3. Buyer provides requested evidence -> transitions status back to OPEN
            auth()->forgetGuards();
            $buyerEvRes = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->postJson("/api/v1/disputes/{$dispute->id}/evidences", [
                    'message_note' => 'Đây là hình chụp cận cảnh vết ố vàng theo yêu cầu của hỗ trợ.',
                ]);

            $buyerEvRes->assertStatus(201);
            $this->assertEquals('BUYER', $buyerEvRes->json('data.uploader_role'));
            $this->assertEquals('BUYER_PROOF', $buyerEvRes->json('data.evidence_type'));

            $disputeAfterBuyer = Dispute::find($dispute->id);
            $this->assertEquals('OPEN', $disputeAfterBuyer->status->value);
        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
        }
    }

    /**
     * 6. Test support and moderator are blocked from executing admin dispute verdict with 403 (PERM-CM-09).
     */
    public function test_support_and_moderator_are_blocked_from_executing_admin_dispute_verdict_403_perm_cm_09(): void
    {
        $seller = null;
        $buyer = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('perm_seller');
            $buyer = $this->createIsolatedUser('perm_buyer');
            $support = User::where('email', 'support@izithrift.local')->firstOrFail();
            $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();

            $order = Order::create([
                'order_code' => 'ORD-PERM-' . time(),
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 150000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 16000.00,
                'total_amount' => 166000.00,
                'seller_net_amount' => 150000.00,
                'shipping_address_snapshot' => ['recipient_name' => 'Buyer', 'phone' => '0901234567'],
                'order_status' => OrderStatus::DELIVERED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::OPEN,
                'payment_expires_at' => now()->addMinutes(30),
                'escrow_frozen_at' => now(),
            ]);

            $dispute = Dispute::create([
                'dispute_code' => 'DSP-PERM-' . time(),
                'order_id' => $order->id,
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'opened_at_order_status' => 'DELIVERED',
                'reason_category' => 'FAKE_ITEM',
                'buyer_description' => 'Nghi ngờ hàng nhái thương hiệu.',
                'status' => DisputeStatus::OPEN,
            ]);

            // Support attempts verdict via API
            $supportToken = $support->createToken('support_token')->plainTextToken;
            auth()->forgetGuards();
            $resSupport = $this->withHeader('Authorization', "Bearer {$supportToken}")
                ->postJson("/api/v1/admin/disputes/{$dispute->id}/resolve", [
                    'verdict' => 'APPROVE_BUYER_REFUND',
                    'resolution_note' => 'Support cố gắng ra phán quyết hoàn tiền.',
                ]);

            $resSupport->assertStatus(403);

            // Moderator attempts verdict via direct service call
            $moderatorToken = $moderator->createToken('mod_token')->plainTextToken;
            auth()->forgetGuards();
            $resMod = $this->withHeader('Authorization', "Bearer {$moderatorToken}")
                ->postJson("/api/v1/admin/disputes/{$dispute->id}/resolve", [
                    'verdict' => 'RELEASE_TO_SELLER',
                    'resolution_note' => 'Moderator cố gắng giải ngân.',
                ]);

            $resMod->assertStatus(403);

            // Verify direct domain service also enforces PERM-CM-09
            $this->expectException(RolePermissionDeniedException::class);
            app(DisputeService::class)->resolveDisputeByAdmin(
                $support,
                $dispute,
                'APPROVE_BUYER_REFUND',
                null,
                'Direct call blocked'
            );
        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
        }
    }

    /**
     * 7. Test admin verdict APPROVE_BUYER_REFUND returns 100% total_amount (DEC-07 / OF-09).
     */
    public function test_admin_verdict_approve_buyer_refund_returns_100_percent_total_amount_dec07(): void
    {
        $seller = null;
        $buyer = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('ref_seller');
            $seller->sellerProfile()->update(['escrow_held_balance' => 300000.00]);

            $buyer = $this->createIsolatedUser('ref_buyer');
            $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();

            $order = Order::create([
                'order_code' => 'ORD-REFUND-' . time(),
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 300000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 25000.00,
                'total_amount' => 325000.00,
                'seller_net_amount' => 300000.00,
                'shipping_address_snapshot' => ['recipient_name' => 'Buyer', 'phone' => '0901234567'],
                'order_status' => OrderStatus::DELIVERED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::OPEN,
                'payment_expires_at' => now()->addMinutes(30),
                'paid_at' => now(),
                'escrow_frozen_at' => now(),
            ]);

            Payment::create([
                'payment_code' => 'PMT-REF-' . time(),
                'order_id' => $order->id,
                'payer_id' => $buyer->id,
                'amount' => 325000.00,
                'qr_payload' => 'vietqr://mock-payload-325k',
                'payment_method' => 'MOCK_VIETQR',
                'payment_reference' => 'REF-PMT-' . time(),
                'status' => PaymentStatus::PAID,
                'expires_at' => now()->addMinutes(30),
                'paid_at' => now(),
            ]);

            $dispute = Dispute::create([
                'dispute_code' => 'DSP-REF-' . time(),
                'order_id' => $order->id,
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'opened_at_order_status' => 'DELIVERED',
                'reason_category' => 'DAMAGED_ITEM',
                'buyer_description' => 'Hàng bể vỡ hoàn toàn khi nhận.',
                'status' => DisputeStatus::OPEN,
            ]);

            $adminToken = $admin->createToken('admin_token')->plainTextToken;

            auth()->forgetGuards();
            $res = $this->withHeader('Authorization', "Bearer {$adminToken}")
                ->postJson("/api/v1/admin/disputes/{$dispute->id}/resolve", [
                    'verdict' => 'APPROVE_BUYER_REFUND',
                    'resolution_note' => 'Xác nhận kiện hàng vỡ nát do đóng gói sơ sài. Phê duyệt hoàn 100% tiền cho người mua.',
                ]);

            $res->assertStatus(200);
            $this->assertEquals('RESOLVED', $res->json('data.status'));
            $this->assertEquals('APPROVE_BUYER_REFUND', $res->json('data.admin_verdict'));

            // Check Order state
            $orderFresh = Order::find($order->id);
            $this->assertEquals('CANCELLED', $orderFresh->order_status->value);
            $this->assertEquals('REFUNDED', $orderFresh->payment_status->value);
            $this->assertEquals('REFUNDED', $orderFresh->escrow_status->value);
            $this->assertEquals('RESOLVED', $orderFresh->dispute_status->value);
            $this->assertEquals('ADMIN', $orderFresh->cancelled_by_role);

            // Check EscrowTransaction: 100% total_amount returned to buyer per DEC-07
            $this->assertDatabaseHas('escrow_transactions', [
                'order_id' => $order->id,
                'transaction_type' => 'FULL_REFUND',
                'gross_amount' => '325000.00',
                'seller_released_amount' => '0.00',
                'buyer_refunded_amount' => '325000.00',
                'platform_fee_retained' => '0.00',
            ]);

            // Check SellerProfile: escrow held deducted, dispute lost incremented
            $sellerProfile = $seller->sellerProfile()->first();
            $this->assertEquals(0.00, (float) $sellerProfile->escrow_held_balance);
            $this->assertEquals(1, $sellerProfile->dispute_lost_count);
        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
        }
    }

    /**
     * 8. Test admin verdict PARTIAL_REFUND splits item_subtotal and maintains zero ledger drift (BR-FN-06).
     */
    public function test_admin_verdict_partial_refund_splits_item_subtotal_and_maintains_zero_ledger_drift_br_fn_06(): void
    {
        $seller = null;
        $buyer = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('part_seller');
            $seller->sellerProfile()->update([
                'wallet_balance' => 100000.00,
                'escrow_held_balance' => 400000.00,
                'completed_orders_count' => 0,
            ]);

            $buyer = $this->createIsolatedUser('part_buyer');
            $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();

            // Order: item_subtotal = 400,000 VND, fee = 31,000 VND, total = 431,000 VND
            $order = Order::create([
                'order_code' => 'ORD-PART-' . time(),
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 400000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 31000.00,
                'total_amount' => 431000.00,
                'seller_net_amount' => 400000.00,
                'shipping_address_snapshot' => ['recipient_name' => 'Buyer', 'phone' => '0901234567'],
                'order_status' => OrderStatus::DELIVERED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::OPEN,
                'payment_expires_at' => now()->addMinutes(30),
                'paid_at' => now(),
                'escrow_frozen_at' => now(),
            ]);

            Payment::create([
                'payment_code' => 'PMT-PART-' . time(),
                'order_id' => $order->id,
                'payer_id' => $buyer->id,
                'amount' => 431000.00,
                'qr_payload' => 'vietqr://mock-payload-431k',
                'payment_method' => 'MOCK_VIETQR',
                'payment_reference' => 'REF-PART-' . time(),
                'status' => PaymentStatus::PAID,
                'expires_at' => now()->addMinutes(30),
                'paid_at' => now(),
            ]);

            $dispute = Dispute::create([
                'dispute_code' => 'DSP-PART-' . time(),
                'order_id' => $order->id,
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'opened_at_order_status' => 'DELIVERED',
                'reason_category' => 'MINOR_DEFECT',
                'buyer_description' => 'Sản phẩm có vết xước nhẹ, đồng ý nhận bồi hoàn một phần tiền.',
                'status' => DisputeStatus::OPEN,
            ]);

            $adminToken = $admin->createToken('admin_token')->plainTextToken;

            // Admin resolves with Partial Refund: 150,000 VND to Buyer, 250,000 VND to Seller
            auth()->forgetGuards();
            $res = $this->withHeader('Authorization', "Bearer {$adminToken}")
                ->postJson("/api/v1/admin/disputes/{$dispute->id}/resolve", [
                    'verdict' => 'PARTIAL_REFUND',
                    'partial_refund_to_buyer' => 150000.00,
                    'resolution_note' => 'Hòa giải thành công: Hoàn 150.000đ cho người mua, giải ngân 250.000đ cho người bán.',
                ]);

            $res->assertStatus(200);
            $this->assertEquals('RESOLVED', $res->json('data.status'));
            $this->assertEquals('PARTIAL_REFUND', $res->json('data.admin_verdict'));
            $this->assertEquals(150000.00, (float) $res->json('data.partial_refund_to_buyer'));

            // Check Order
            $orderFresh = Order::find($order->id);
            $this->assertEquals('COMPLETED', $orderFresh->order_status->value);
            $this->assertEquals('PARTIALLY_REFUNDED', $orderFresh->escrow_status->value);
            $this->assertEquals('RESOLVED', $orderFresh->dispute_status->value);

            // Check EscrowTransaction:
            // total_amount (431,000) = seller_released (250,000) + buyer_refunded (150,000) + platform_fee (31,000)
            $this->assertDatabaseHas('escrow_transactions', [
                'order_id' => $order->id,
                'transaction_type' => 'PARTIAL_REFUND',
                'gross_amount' => '431000.00',
                'seller_released_amount' => '250000.00',
                'buyer_refunded_amount' => '150000.00',
                'platform_fee_retained' => '31000.00',
            ]);

            // Check WalletTransaction for Seller
            $this->assertDatabaseHas('wallet_transactions', [
                'seller_id' => $seller->id,
                'order_id' => $order->id,
                'entry_type' => 'CREDIT',
                'amount' => '250000.00',
                'balance_before' => '100000.00',
                'balance_after' => '350000.00',
            ]);

            // Check SellerProfile: wallet balance increased by 250,000 to 350,000 VND
            $sellerProfile = $seller->sellerProfile()->first();
            $this->assertEquals(350000.00, (float) $sellerProfile->wallet_balance);
            $this->assertEquals(0.00, (float) $sellerProfile->escrow_held_balance);
            $this->assertEquals(1, $sellerProfile->completed_orders_count);
        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
        }
    }
}
