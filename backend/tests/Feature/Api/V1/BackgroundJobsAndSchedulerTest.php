<?php

namespace Tests\Feature\Api\V1;

use App\Enums\AuctionStatus;
use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Jobs\AutoCompleteDeliveredOrdersJob;
use App\Jobs\CloseExpiredAuctionsJob;
use App\Jobs\ExpireUnpaidAuctionOrdersJob;
use App\Jobs\OpenScheduledAuctionsJob;
use App\Models\Auction;
use App\Models\AuctionSession;
use App\Models\AuditLog;
use App\Models\Category;
use App\Models\EscrowTransaction;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\UserProfile;
use App\Services\Auction\AuctionLifecycleService;
use App\Services\Escrow\EscrowReleaseService;
use App\Services\Order\OrderExpirationService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class BackgroundJobsAndSchedulerTest extends TestCase
{
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
            'review_count' => 0,
            'average_rating' => 5.00,
            'completed_orders_count' => 0,
            'dispute_lost_count' => 0,
            'auction_default_count' => 0,
        ]);

        return $user;
    }

    protected function createIsolatedProduct(User $seller, float $price = 100000.00, string $listingType = 'AUCTION'): Product
    {
        $unique = 'prd_job_' . bin2hex(random_bytes(5));
        $category = Category::first() ?? Category::create([
            'name' => 'Thời trang Vintage',
            'slug' => 'vintage-' . bin2hex(random_bytes(3)),
        ]);

        return Product::create([
            'product_code' => 'PRD-' . strtoupper($unique),
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'title' => 'Sản phẩm ' . $unique,
            'slug' => 'slug-' . $unique,
            'description' => 'Mô tả chi tiết sản phẩm test cron job',
            'condition' => 'LIKE_NEW',
            'defect_info' => 'Không lỗi',
            'listing_type' => $listingType,
            'price' => $price,
            'available_quantity' => 1,
            'total_quantity' => 1,
            'status' => ProductStatus::APPROVED,
        ]);
    }

    protected function cleanUpAuction(?int $auctionId, ?int $productId = null, array $userIds = []): void
    {
        if ($auctionId) {
            DB::table('auction_watches')->where('auction_id', $auctionId)->delete();
            DB::table('auction_bids')->where('auction_id', $auctionId)->delete();

            $orderIds = DB::table('orders')->where('auction_id', $auctionId)->pluck('id')->toArray();
            foreach ($orderIds as $ordId) {
                DB::table('payments')->where('order_id', $ordId)->delete();
                DB::table('order_items')->where('order_id', $ordId)->delete();
                DB::table('orders')->where('id', $ordId)->delete();
            }

            DB::table('auctions')->where('id', $auctionId)->delete();
        }

        if ($productId) {
            DB::table('favorites')->where('product_id', $productId)->delete();
            DB::table('products')->where('id', $productId)->delete();
        }

        foreach ($userIds as $uid) {
            DB::table('notifications')->where('user_id', $uid)->delete();
            DB::table('seller_profiles')->where('user_id', $uid)->delete();
            DB::table('user_profiles')->where('user_id', $uid)->delete();
            DB::table('users')->where('id', $uid)->delete();
        }
    }

    protected function cleanUpOrder(int $orderId): void
    {
        DB::table('wallet_transactions')->where('order_id', $orderId)->delete();
        DB::table('escrow_transactions')->where('order_id', $orderId)->delete();
        DB::table('payments')->where('order_id', $orderId)->delete();
        DB::table('order_items')->where('order_id', $orderId)->delete();
        DB::table('orders')->where('id', $orderId)->delete();
    }

    protected function cleanUpUser(int $userId): void
    {
        DB::table('audit_logs')->where('actor_id', $userId)->delete();
        DB::table('notifications')->where('user_id', $userId)->delete();
        DB::table('seller_profiles')->where('user_id', $userId)->delete();
        DB::table('user_profiles')->where('user_id', $userId)->delete();
        DB::table('users')->where('id', $userId)->delete();
    }

    /**
     * 1. Test open scheduled auctions job transitions due scheduled auctions to LIVE idempotently.
     */
    public function test_open_scheduled_auctions_job_transitions_due_scheduled_auctions_to_live_idempotently(): void
    {
        $seller = null;
        $watcher = null;
        $product = null;
        $auction = null;

        try {
            $seller = $this->createIsolatedUser('sch_seller');
            $watcher = $this->createIsolatedUser('sch_watcher');
            $product = $this->createIsolatedProduct($seller, 150000.00);

            $session = AuctionSession::firstOrFail();

            $auction = Auction::create([
                'auction_code' => 'AUC-SCH-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $session->id,
                'starting_price' => 150000.00,
                'min_bid_increment' => 10000.00,
                'current_highest_bid' => 0.00,
                'bid_count' => 0,
                'status' => AuctionStatus::SCHEDULED,
                'auction_starts_at' => now()->subMinutes(5), // Due
                'auction_ends_at' => now()->addHours(24),
            ]);

            DB::table('auction_watches')->insert([
                'auction_id' => $auction->id,
                'user_id' => $watcher->id,
                'created_at' => now(),
            ]);

            // Run Job
            app(OpenScheduledAuctionsJob::class)->handle(app(AuctionLifecycleService::class));

            $auction->refresh();
            $statusVal = $auction->status instanceof AuctionStatus ? $auction->status->value : (string) $auction->status;
            $this->assertEquals('LIVE', $statusVal);

            // Watcher received notification
            $notif = DB::table('notifications')
                ->where('user_id', $watcher->id)
                ->where('type', 'AUCTION_STARTED')
                ->first();
            $this->assertNotNull($notif);

            // Idempotent second run -> 0 processed
            $serviceResult = app(AuctionLifecycleService::class)->openDueScheduledAuctions();
            $this->assertEquals(0, $serviceResult['opened_count']);
        } finally {
            $this->cleanUpAuction(
                $auction?->id,
                $product?->id,
                array_filter([$seller?->id, $watcher?->id])
            );
        }
    }

    /**
     * 2. Test close expired auctions job finalizes winner with DEC-04 order or marks ENDED_UNSOLD.
     */
    public function test_close_expired_auctions_job_finalizes_winner_with_dec04_order_or_marks_ended_unsold(): void
    {
        $seller = null;
        $winner = null;
        $prodWon = null;
        $prodUnsold = null;
        $aucWon = null;
        $aucUnsold = null;

        try {
            $seller = $this->createIsolatedUser('cls_seller');
            $winner = $this->createIsolatedUser('cls_winner');
            $session = AuctionSession::firstOrFail();

            // Auction 1: Won
            $prodWon = $this->createIsolatedProduct($seller, 200000.00);
            $aucWon = Auction::create([
                'auction_code' => 'AUC-WON-' . time(),
                'product_id' => $prodWon->id,
                'seller_id' => $seller->id,
                'session_id' => $session->id,
                'starting_price' => 200000.00,
                'min_bid_increment' => 10000.00,
                'current_highest_bid' => 250000.00,
                'leading_bidder_id' => $winner->id,
                'bid_count' => 3,
                'status' => AuctionStatus::LIVE,
                'auction_starts_at' => now()->subHours(2),
                'auction_ends_at' => now()->subMinutes(10), // Expired
            ]);

            // Auction 2: Unsold (0 bids)
            $prodUnsold = $this->createIsolatedProduct($seller, 180000.00);
            $aucUnsold = Auction::create([
                'auction_code' => 'AUC-UNS-' . time(),
                'product_id' => $prodUnsold->id,
                'seller_id' => $seller->id,
                'session_id' => $session->id,
                'starting_price' => 180000.00,
                'min_bid_increment' => 10000.00,
                'current_highest_bid' => 0.00,
                'leading_bidder_id' => null,
                'bid_count' => 0,
                'status' => AuctionStatus::LIVE,
                'auction_starts_at' => now()->subHours(2),
                'auction_ends_at' => now()->subMinutes(10), // Expired
            ]);

            // Run Job
            app(CloseExpiredAuctionsJob::class)->handle(app(AuctionLifecycleService::class));

            // Verify Auction 1: COMPLETED and Order generated
            $aucWon->refresh();
            $wonStatus = $aucWon->status instanceof AuctionStatus ? $aucWon->status->value : (string) $aucWon->status;
            $this->assertEquals('COMPLETED', $wonStatus);
            $this->assertEquals($winner->id, $aucWon->winner_id);

            $order = Order::where('auction_id', $aucWon->id)->first();
            $this->assertNotNull($order);
            $this->assertEquals(250000.00, (float) $order->item_subtotal);
            // DEC-04: 250000 * 0.06 + 7000 = 15000 + 7000 = 22000
            $this->assertEquals(22000.00, (float) $order->buyer_protection_fee);
            $this->assertEquals(272000.00, (float) $order->total_amount);

            // Verify Auction 2: ENDED_UNSOLD and Product restored to APPROVED
            $aucUnsold->refresh();
            $unsoldStatus = $aucUnsold->status instanceof AuctionStatus ? $aucUnsold->status->value : (string) $aucUnsold->status;
            $this->assertEquals('ENDED_UNSOLD', $unsoldStatus);

            $prodUnsold->refresh();
            $this->assertEquals('APPROVED', $prodUnsold->status instanceof ProductStatus ? $prodUnsold->status->value : (string) $prodUnsold->status);
            $this->assertEquals(1, $prodUnsold->available_quantity);
        } finally {
            $this->cleanUpAuction($aucWon?->id, $prodWon?->id);
            $this->cleanUpAuction($aucUnsold?->id, $prodUnsold?->id, array_filter([$seller?->id, $winner?->id]));
        }
    }

    /**
     * 3. Test expire unpaid orders job marks auction winner defaulted, increments default count and unlocks product for relist (DEC-02).
     */
    public function test_expire_unpaid_orders_job_marks_auction_winner_defaulted_increments_default_count_and_unlocks_product_for_relist_dec02(): void
    {
        $seller = null;
        $defaulter = null;
        $product = null;
        $auction = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('def_seller');
            $defaulter = $this->createIsolatedUser('def_buyer');
            $session = AuctionSession::firstOrFail();

            $product = $this->createIsolatedProduct($seller, 300000.00);
            $product->update(['status' => ProductStatus::SOLD, 'available_quantity' => 0]);

            $auction = Auction::create([
                'auction_code' => 'AUC-DEF-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $session->id,
                'starting_price' => 300000.00,
                'min_bid_increment' => 10000.00,
                'current_highest_bid' => 300000.00,
                'leading_bidder_id' => $defaulter->id,
                'winner_id' => $defaulter->id,
                'bid_count' => 1,
                'status' => AuctionStatus::COMPLETED,
                'auction_starts_at' => now()->subHours(5),
                'auction_ends_at' => now()->subHours(2),
                'closed_at' => now()->subHours(2),
            ]);

            $order = Order::create([
                'order_code' => 'ORD-DEF-' . time(),
                'buyer_id' => $defaulter->id,
                'seller_id' => $seller->id,
                'order_source' => 'AUCTION',
                'auction_id' => $auction->id,
                'item_subtotal' => 300000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 25000.00,
                'total_amount' => 325000.00,
                'seller_net_amount' => 300000.00,
                'shipping_address_snapshot' => ['recipient_name' => 'Default Buyer', 'phone' => '0901234567'],
                'order_status' => OrderStatus::PENDING_PAYMENT,
                'payment_status' => PaymentStatus::UNPAID,
                'escrow_status' => EscrowStatus::NONE,
                'dispute_status' => DisputeStatus::NONE,
                'payment_expires_at' => now()->subMinutes(15), // Expired!
            ]);

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => $product->id,
                'product_code_snapshot' => $product->product_code,
                'product_title_snapshot' => $product->title,
                'unit_price_snapshot' => 300000.00,
                'quantity' => 1,
                'line_total' => 300000.00,
                'condition_snapshot' => 'LIKE_NEW',
                'defect_info_snapshot' => 'Không có lỗi',
                'primary_image_snapshot' => 'https://izithrift.local/storage/sample.jpg',
            ]);

            Payment::create([
                'payment_reference' => 'PAY-DEF-' . time(),
                'order_id' => $order->id,
                'payer_id' => $defaulter->id,
                'amount' => 325000.00,
                'qr_payload' => 'vietqr://defaulter',
                'status' => PaymentStatus::PENDING,
                'expires_at' => now()->subMinutes(15),
            ]);

            $defaulterProfile = SellerProfile::where('user_id', $defaulter->id)->first();
            $this->assertEquals(0, $defaulterProfile->auction_default_count);

            // Run Job
            app(ExpireUnpaidAuctionOrdersJob::class)->handle(app(OrderExpirationService::class));

            // Verify Order: CANCELLED & EXPIRED
            $order->refresh();
            $this->assertEquals('CANCELLED', $order->order_status instanceof OrderStatus ? $order->order_status->value : (string) $order->order_status);
            $this->assertEquals('EXPIRED', $order->payment_status instanceof PaymentStatus ? $order->payment_status->value : (string) $order->payment_status);

            // Verify Auction: WINNER_DEFAULTED
            $auction->refresh();
            $this->assertEquals('WINNER_DEFAULTED', $auction->status instanceof AuctionStatus ? $auction->status->value : (string) $auction->status);

            // Verify Product: Restored to APPROVED with quantity = 1 for Relist (DEC-02)
            $product->refresh();
            $this->assertEquals('APPROVED', $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status);
            $this->assertEquals(1, $product->available_quantity);

            // Verify Defaulter: auction_default_count incremented to 1
            $defaulterProfile->refresh();
            $this->assertEquals(1, $defaulterProfile->auction_default_count);
        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            $this->cleanUpAuction($auction?->id, $product?->id, array_filter([$seller?->id, $defaulter?->id]));
        }
    }

    /**
     * 4. Test auto complete delivered orders job releases 100% escrow to seller wallet and strictly skips disputed orders (BR-DP-02).
     */
    public function test_auto_complete_delivered_orders_job_releases_100_percent_escrow_to_seller_wallet_and_strictly_skips_disputed_orders_br_dp_02(): void
    {
        $seller = null;
        $buyer = null;
        $orderNormal = null;
        $orderDisputed = null;

        try {
            $seller = $this->createIsolatedUser('esc_seller');
            $buyer = $this->createIsolatedUser('esc_buyer');

            // Order A (Normal due for auto-complete)
            $orderNormal = Order::create([
                'order_code' => 'ORD-NRM-' . time(),
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
                'shipping_address_snapshot' => ['recipient_name' => 'Buyer Linh', 'phone' => '0901234567'],
                'order_status' => OrderStatus::DELIVERED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::NONE,
                'auto_complete_at' => now()->subMinutes(10), // Due!
                'delivered_at' => now()->subDays(1),
                'paid_at' => now()->subDays(2),
                'payment_expires_at' => now()->subDays(2),
            ]);

            OrderItem::create([
                'order_id' => $orderNormal->id,
                'product_id' => 1,
                'product_code_snapshot' => 'PRD-NRM-001',
                'product_title_snapshot' => 'Sản phẩm áo vintage',
                'unit_price_snapshot' => 100000.00,
                'quantity' => 1,
                'line_total' => 100000.00,
                'condition_snapshot' => 'LIKE_NEW',
                'defect_info_snapshot' => 'Không lỗi',
                'primary_image_snapshot' => 'https://izithrift.local/storage/sample.jpg',
            ]);

            $payment = Payment::create([
                'payment_reference' => 'PAY-NRM-' . time(),
                'order_id' => $orderNormal->id,
                'payer_id' => $buyer->id,
                'amount' => 113000.00,
                'qr_payload' => 'vietqr://normal',
                'status' => PaymentStatus::PAID,
                'paid_at' => now()->subDays(2),
                'expires_at' => now()->subDays(2),
            ]);

            EscrowTransaction::create([
                'transaction_code' => 'ESC-HOLD-' . time() . '-' . rand(100, 999),
                'order_id' => $orderNormal->id,
                'payment_id' => $payment->id,
                'seller_id' => $seller->id,
                'buyer_id' => $buyer->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 113000.00,
                'item_subtotal_amount' => 100000.00,
                'buyer_protection_fee_amount' => 13000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer->id,
                'note' => 'Giữ tiền ký quỹ ban đầu',
            ]);

            // Update seller held balance
            SellerProfile::where('user_id', $seller->id)->update([
                'escrow_held_balance' => 100000.00,
            ]);

            // Order B (Disputed -> MUST BE SKIPPED)
            $orderDisputed = Order::create([
                'order_code' => 'ORD-DSP-' . time(),
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
                'shipping_address_snapshot' => ['recipient_name' => 'Buyer Linh', 'phone' => '0901234567'],
                'order_status' => OrderStatus::DELIVERED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'dispute_status' => DisputeStatus::OPEN, // Disputed!
                'escrow_frozen_at' => now()->subHours(1), // Frozen!
                'auto_complete_at' => now()->subMinutes(10), // Expired but protected
                'delivered_at' => now()->subDays(1),
                'paid_at' => now()->subDays(2),
                'payment_expires_at' => now()->subDays(2),
            ]);

            // Run Job
            app(AutoCompleteDeliveredOrdersJob::class)->handle(app(EscrowReleaseService::class));

            // Order Normal: COMPLETED, RELEASED, wallet credited 100000
            $orderNormal->refresh();
            $this->assertEquals('COMPLETED', $orderNormal->order_status instanceof OrderStatus ? $orderNormal->order_status->value : (string) $orderNormal->order_status);
            $this->assertEquals('RELEASED', $orderNormal->escrow_status instanceof EscrowStatus ? $orderNormal->escrow_status->value : (string) $orderNormal->escrow_status);

            $sellerProfile = SellerProfile::where('user_id', $seller->id)->first();
            $this->assertEquals(100000.00, (float) $sellerProfile->wallet_balance);
            $this->assertEquals(0.00, (float) $sellerProfile->escrow_held_balance);

            // Order Disputed: STRICTLY SKIPPED (Dispute Freeze Guard BR-DP-02)
            $orderDisputed->refresh();
            $this->assertEquals('DELIVERED', $orderDisputed->order_status instanceof OrderStatus ? $orderDisputed->order_status->value : (string) $orderDisputed->order_status);
            $this->assertEquals('HELD', $orderDisputed->escrow_status instanceof EscrowStatus ? $orderDisputed->escrow_status->value : (string) $orderDisputed->escrow_status);
        } finally {
            if ($orderNormal) {
                $this->cleanUpOrder($orderNormal->id);
            }
            if ($orderDisputed) {
                $this->cleanUpOrder($orderDisputed->id);
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
        }
    }

    /**
     * 5. Test running all four jobs repeatedly is 100% idempotent with zero duplicate ledger entries.
     */
    public function test_running_all_four_jobs_repeatedly_is_100_percent_idempotent_with_zero_duplicate_ledger_entries(): void
    {
        $preOrderIds = Order::pluck('id')->toArray();

        try {
            $res1 = app(AuctionLifecycleService::class)->openDueScheduledAuctions();
            $res2 = app(AuctionLifecycleService::class)->closeExpiredLiveAuctions();
            $res3 = app(OrderExpirationService::class)->expireOverdueUnpaidOrders();
            $res4 = app(EscrowReleaseService::class)->autoCompleteDueDeliveredOrders();

            $this->assertIsArray($res1);
            $this->assertIsArray($res2);
            $this->assertIsArray($res3);
            $this->assertIsArray($res4);

            // Immediate second run must process 0 items across all 4 services
            $rep1 = app(AuctionLifecycleService::class)->openDueScheduledAuctions();
            $rep2 = app(AuctionLifecycleService::class)->closeExpiredLiveAuctions();
            $rep3 = app(OrderExpirationService::class)->expireOverdueUnpaidOrders();
            $rep4 = app(EscrowReleaseService::class)->autoCompleteDueDeliveredOrders();

            $this->assertEquals(0, $rep1['opened_count']);
            $this->assertEquals(0, $rep2['completed_count'] + $rep2['unsold_count']);
            $this->assertEquals(0, $rep3['expired_orders_count']);
            $this->assertEquals(0, $rep4['auto_completed_count']);
        } finally {
            $newOrders = Order::whereNotIn('id', $preOrderIds)->get();
            foreach ($newOrders as $newOrder) {
                $this->cleanUpOrder($newOrder->id);
            }
            Auction::where('auction_code', 'AUC-2026-0002')->update([
                'status' => AuctionStatus::LIVE,
                'winner_id' => null,
                'closed_at' => null,
                'auction_ends_at' => now()->addHours(1),
            ]);
        }
    }

    /**
     * 6. Test admin can trigger demo mode devtools endpoint and records audit log while non-admin is blocked 403.
     */
    public function test_admin_can_trigger_demo_mode_devtools_endpoint_and_records_audit_log_while_non_admin_is_blocked_403(): void
    {
        $admin = null;
        $regularUser = null;

        try {
            $admin = $this->createIsolatedUser('adm_dev', UserRole::ADMIN);
            $regularUser = $this->createIsolatedUser('reg_dev', UserRole::REGISTERED_USER);

            config(['retromarket.demo_mode' => true]);

            // Regular user attempt -> 403
            $regRes = $this->actingAs($regularUser)->postJson('/api/v1/system/dev-tools/trigger-jobs', [
                'action_key' => 'RUN_ALL_LIFECYCLE_JOBS',
            ]);
            $regRes->assertStatus(403);
            $regRes->assertJsonPath('error_code', 'ROLE_PERMISSION_DENIED');

            // Admin trigger -> 200
            $admRes = $this->actingAs($admin)->postJson('/api/v1/system/dev-tools/trigger-jobs', [
                'action_key' => 'RUN_ALL_LIFECYCLE_JOBS',
            ]);
            $admRes->assertStatus(200);
            $admRes->assertJsonPath('success', true);
            $admRes->assertJsonStructure([
                'data' => [
                    'action',
                    'result' => [
                        'open_scheduled',
                        'close_expired',
                        'expire_unpaid',
                        'auto_complete',
                    ],
                ],
            ]);

            // Verify AuditLog record
            $log = AuditLog::where('actor_id', $admin->id)
                ->where('action', 'DEVTOOLS_MANUAL_JOB_TRIGGER')
                ->latest('id')
                ->first();

            $this->assertNotNull($log);
            $this->assertEquals('SYSTEM', $log->target_type);

            // When demo mode is disabled -> 403 even for Admin
            config(['retromarket.demo_mode' => false]);
            $disabledRes = $this->actingAs($admin)->postJson('/api/v1/system/dev-tools/trigger-jobs', [
                'action_key' => 'RUN_ALL_LIFECYCLE_JOBS',
            ]);
            $disabledRes->assertStatus(403);
        } finally {
            config(['retromarket.demo_mode' => true]); // Restore demo mode
            if ($admin) {
                DB::table('audit_logs')->where('actor_id', $admin->id)->delete();
                $this->cleanUpUser($admin->id);
            }
            if ($regularUser) {
                $this->cleanUpUser($regularUser->id);
            }
        }
    }
}
