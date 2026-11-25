<?php

namespace Tests\Feature\Api\V1;

use App\Enums\AuctionStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Exceptions\EscrowLedgerIntegrityException;
use App\Models\Auction;
use App\Models\AuctionSession;
use App\Models\Category;
use App\Models\EscrowTransaction;
use App\Models\Notification;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\UserAddress;
use App\Models\UserProfile;
use App\Services\Escrow\MockQrPaymentService;
use App\Services\Order\OrderCancellationService;
use App\Services\Order\OrderExpirationService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Tests\TestCase;

class OrderCancellationMatrixTest extends TestCase
{
    protected ?Category $sharedCategory = null;

    protected function getSharedCategory(): Category
    {
        if ($this->sharedCategory === null) {
            $this->sharedCategory = Category::first() ?? Category::create([
                'name' => 'Vintage Fashion',
                'slug' => 'vintage-fashion-' . uniqid(),
            ]);
        }

        return $this->sharedCategory;
    }

    protected function createIsolatedBuyer(string $prefix = 'buyer'): User
    {
        $unique = $prefix . '_' . bin2hex(random_bytes(4));
        $user = User::create([
            'display_name' => 'Buyer ' . $unique,
            'email' => $unique . '@izithrift.test',
            'password_hash' => Hash::make('Retro@2026'),
            'role' => UserRole::REGISTERED_USER,
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
            'auction_default_count' => 0,
        ]);

        UserAddress::create([
            'user_id' => $user->id,
            'recipient_name' => 'Buyer ' . $unique,
            'recipient_phone' => '0901234567',
            'province_city' => 'TP Ho Chi Minh',
            'district_ward' => 'Quan 1, Ben Nghe',
            'street_address' => '123 Le Loi',
            'is_default' => true,
        ]);

        return $user;
    }

    protected function createIsolatedSeller(string $prefix = 'seller', float $heldBalance = 0.00): User
    {
        $unique = $prefix . '_' . bin2hex(random_bytes(4));
        $user = User::create([
            'display_name' => 'Seller ' . $unique,
            'email' => $unique . '@izithrift.test',
            'password_hash' => Hash::make('Retro@2026'),
            'role' => UserRole::REGISTERED_USER,
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
            'escrow_held_balance' => $heldBalance,
            'completed_orders_count' => 0,
            'dispute_lost_count' => 0,
            'auction_default_count' => 0,
        ]);

        UserAddress::create([
            'user_id' => $user->id,
            'recipient_name' => 'Seller ' . $unique,
            'recipient_phone' => '0909876543',
            'province_city' => 'TP Ho Chi Minh',
            'district_ward' => 'Quan 1, Ben Nghe',
            'street_address' => '456 Nguyen Hue',
            'is_default' => true,
        ]);

        return $user;
    }

    protected function createFixedPriceProduct(User $seller, float $price = 200000.00, int $quantity = 5): Product
    {
        $unique = 'prd_' . bin2hex(random_bytes(4));

        return Product::create([
            'product_code' => 'PRD-' . strtoupper($unique),
            'seller_id' => $seller->id,
            'category_id' => $this->getSharedCategory()->id,
            'title' => 'Vintage Product ' . $unique,
            'slug' => 'slug-' . $unique,
            'description' => 'Mô tả chi tiết sản phẩm vintage',
            'condition' => 'LIKE_NEW',
            'defect_info' => 'Không có lỗi',
            'listing_type' => 'FIXED_PRICE',
            'price' => $price,
            'original_price' => $price * 1.5,
            'available_quantity' => $quantity,
            'total_quantity' => $quantity,
            'status' => ProductStatus::APPROVED,
        ]);
    }

    protected function createFixedPriceOrder(
        User $buyer,
        User $seller,
        Product $product,
        string $orderStatus = 'PENDING_PAYMENT',
        string $paymentStatus = 'UNPAID',
        string $escrowStatus = 'NONE',
        int $qty = 1
    ): Order {
        $subtotal = round($product->price * $qty, 2);
        $protFee = round($subtotal * 0.03, 2);
        $shipping = 0.00;
        $total = round($subtotal + $protFee, 2);
        $orderCode = 'ORD-' . strtoupper(Str::random(8));

        $order = Order::create([
            'order_code' => $orderCode,
            'buyer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'order_source' => 'FIXED_PRICE',
            'order_status' => $orderStatus,
            'payment_status' => $paymentStatus,
            'escrow_status' => $escrowStatus,
            'item_subtotal' => $subtotal,
            'buyer_protection_fee' => $protFee,
            'shipping_fee' => $shipping,
            'total_amount' => $total,
            'seller_net_amount' => $subtotal,
            'protection_fee_rate_applied' => 0.0300,
            'protection_fixed_fee_applied' => 0.00,
            'payment_expires_at' => now()->addMinutes(30),
            'shipping_address_snapshot' => [
                'recipient_name' => $buyer->display_name,
                'phone' => '0901234567',
                'street_address' => '123 Le Loi',
            ],
            'paid_at' => in_array($paymentStatus, ['PAID', 'REFUNDED'], true) ? now() : null,
        ]);

        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'product_code_snapshot' => $product->product_code,
            'product_title_snapshot' => $product->title,
            'condition_snapshot' => $product->condition,
            'defect_info_snapshot' => $product->defect_info,
            'primary_image_snapshot' => 'http://localhost/default.jpg',
            'unit_price_snapshot' => $product->price,
            'quantity' => $qty,
            'line_total' => $subtotal,
        ]);

        // Decrement product available_quantity as would happen during checkout
        $product->available_quantity = max(0, $product->available_quantity - $qty);
        if ($product->available_quantity === 0) {
            $product->status = ProductStatus::SOLD;
        }
        $product->save();

        $pStatus = $paymentStatus === 'PAID' ? PaymentStatus::PAID : ($paymentStatus === 'REFUNDED' ? PaymentStatus::REFUNDED : PaymentStatus::PENDING);
        $payment = Payment::create([
            'payment_reference' => 'PAY-' . strtoupper(Str::random(8)),
            'order_id' => $order->id,
            'payer_id' => $buyer->id,
            'amount' => $total,
            'status' => $pStatus,
            'qr_payload' => "IZITHRIFT_QR|{$order->order_code}|{$total}",
            'paid_at' => $order->paid_at,
            'expires_at' => $order->payment_expires_at,
        ]);

        if ($escrowStatus === 'HELD') {
            EscrowTransaction::create([
                'transaction_code' => 'ESC-HOLD-' . strtoupper(Str::random(8)),
                'order_id' => $order->id,
                'payment_id' => $payment->id,
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => $total,
                'item_subtotal_amount' => $subtotal,
                'buyer_protection_fee_amount' => $protFee,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer->id,
                'note' => 'Giữ tiền trung gian Escrow.',
            ]);
        }

        return $order->fresh(['items', 'seller.sellerProfile', 'payments']);
    }

    protected function createAuctionWithOrder(
        User $seller,
        User $buyer,
        string $orderStatus = 'PENDING_PAYMENT',
        string $paymentStatus = 'UNPAID'
    ): array {
        $unique = 'auc_' . bin2hex(random_bytes(4));
        $bidPrice = 150000.00;

        $product = Product::create([
            'product_code' => 'PRD-AUC-' . strtoupper($unique),
            'seller_id' => $seller->id,
            'category_id' => $this->getSharedCategory()->id,
            'title' => 'Vintage Auction Item ' . $unique,
            'slug' => 'slug-auc-' . $unique,
            'description' => 'Mô tả chi tiết sản phẩm đấu giá',
            'condition' => 'LIKE_NEW',
            'defect_info' => 'Không lỗi',
            'listing_type' => 'AUCTION',
            'price' => $bidPrice,
            'original_price' => $bidPrice * 1.5,
            'available_quantity' => 0,
            'total_quantity' => 1,
            'status' => ProductStatus::SOLD,
        ]);

        $session = AuctionSession::first() ?? AuctionSession::create([
            'title' => 'Phiên Đấu Giá Test',
            'slug' => 'phien-test-' . uniqid(),
            'start_time' => now()->subDay(),
            'end_time' => now()->addDay(),
            'status' => 'ACTIVE',
        ]);

        $auction = Auction::create([
            'auction_code' => 'AUC-' . strtoupper($unique),
            'session_id' => $session->id,
            'product_id' => $product->id,
            'seller_id' => $seller->id,
            'starting_price' => 100000.00,
            'min_bid_increment' => 10000.00,
            'current_highest_bid' => $bidPrice,
            'winning_bid' => $bidPrice,
            'winner_id' => $buyer->id,
            'leading_bidder_id' => $buyer->id,
            'bid_count' => 3,
            'auction_starts_at' => now()->subHours(2),
            'auction_ends_at' => now()->subMinute(),
            'status' => AuctionStatus::COMPLETED,
        ]);

        $protFee = round($bidPrice * 0.03, 2);
        $shipping = 0.00;
        $total = round($bidPrice + $protFee, 2);

        $order = Order::create([
            'order_code' => 'ORD-AUC-' . strtoupper(Str::random(8)),
            'buyer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'order_source' => 'AUCTION',
            'auction_id' => $auction->id,
            'order_status' => $orderStatus,
            'payment_status' => $paymentStatus,
            'escrow_status' => $paymentStatus === 'PAID' ? 'HELD' : 'NONE',
            'item_subtotal' => $bidPrice,
            'buyer_protection_fee' => $protFee,
            'shipping_fee' => $shipping,
            'total_amount' => $total,
            'seller_net_amount' => $bidPrice,
            'protection_fee_rate_applied' => 0.0300,
            'protection_fixed_fee_applied' => 0.00,
            'payment_expires_at' => now()->addMinutes(30),
            'shipping_address_snapshot' => [
                'recipient_name' => $buyer->display_name,
                'phone' => '0901234567',
                'street_address' => '123 Le Loi',
            ],
            'paid_at' => $paymentStatus === 'PAID' ? now() : null,
        ]);

        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'product_code_snapshot' => $product->product_code,
            'product_title_snapshot' => $product->title,
            'condition_snapshot' => $product->condition,
            'defect_info_snapshot' => $product->defect_info,
            'primary_image_snapshot' => 'http://localhost/default.jpg',
            'unit_price_snapshot' => $bidPrice,
            'quantity' => 1,
            'line_total' => $bidPrice,
        ]);

        $payment = Payment::create([
            'payment_reference' => 'PAY-AUC-' . strtoupper(Str::random(8)),
            'order_id' => $order->id,
            'payer_id' => $buyer->id,
            'amount' => $total,
            'status' => $paymentStatus === 'PAID' ? PaymentStatus::PAID : PaymentStatus::PENDING,
            'qr_payload' => "IZITHRIFT_QR|{$order->order_code}|{$total}",
            'paid_at' => $order->paid_at,
            'expires_at' => $order->payment_expires_at,
        ]);

        return [
            'auction' => $auction,
            'product' => $product,
            'order' => $order->fresh(['items', 'seller.sellerProfile', 'payments']),
            'payment' => $payment,
        ];
    }

    protected function createTransientWorkerScript(string $content): string
    {
        $tempPath = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'p903_worker_' . uniqid() . '.php';
        file_put_contents($tempPath, $content);

        return $tempPath;
    }

    // =========================================================================
    // SECTION 1: BUSINESS SCENARIOS (TESTS #01 TO #18)
    // =========================================================================

    /**
     * Test #01 (Scenario 01): Buyer cancels unpaid fixed-price order at PENDING_PAYMENT.
     */
    public function test_01_buyer_cancels_pending_fixed_price_order_immediately_restores_stock(): void
    {
        $seller = $this->createIsolatedSeller();
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PENDING_PAYMENT', 'UNPAID', 'NONE', 1);

        $this->assertEquals(4, $product->fresh()->available_quantity);

        $token = $buyer->createToken('auth')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/orders/{$order->id}/cancel", [
                'reason' => 'Tôi đổi ý không muốn mua nữa',
            ]);

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);

        $freshOrder = $order->fresh();
        $this->assertEquals(OrderStatus::CANCELLED, $freshOrder->order_status);
        $this->assertEquals(PaymentStatus::EXPIRED, $freshOrder->payment_status);
        $this->assertEquals('BUYER', $freshOrder->cancelled_by_role);
        $this->assertEquals('Tôi đổi ý không muốn mua nữa', $freshOrder->cancel_reason);
        $this->assertNotNull($freshOrder->cancelled_at);

        $this->assertEquals(5, $product->fresh()->available_quantity);
        $this->assertEquals(0, EscrowTransaction::where('order_id', $order->id)->count());
    }

    /**
     * Test #02 (Scenario 02): Buyer cancels paid fixed-price order at PAID (Tier 2 Full Refund).
     */
    public function test_02_buyer_cancels_paid_fixed_price_order_triggers_tier2_full_refund_and_restores_stock(): void
    {
        $seller = $this->createIsolatedSeller('seller', 200000.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PAID', 'PAID', 'HELD', 1);

        $token = $buyer->createToken('auth')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/orders/{$order->id}/cancel", [
                'reason' => 'Đặt nhầm kích thước',
            ]);

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);

        $freshOrder = $order->fresh();
        $this->assertEquals(OrderStatus::CANCELLED, $freshOrder->order_status);
        $this->assertEquals(PaymentStatus::REFUNDED, $freshOrder->payment_status);
        $this->assertEquals(EscrowStatus::REFUNDED, $freshOrder->escrow_status);
        $this->assertEquals('BUYER', $freshOrder->cancelled_by_role);

        $refundTx = EscrowTransaction::where('order_id', $order->id)
            ->where('transaction_type', 'FULL_REFUND')
            ->first();
        $this->assertNotNull($refundTx);
        $this->assertEquals((float) $order->total_amount, (float) $refundTx->buyer_refunded_amount);
        $this->assertEquals((float) $order->item_subtotal, (float) $refundTx->item_subtotal_amount);

        $sellerProfile = SellerProfile::where('user_id', $seller->id)->first();
        $this->assertEquals('0.00', (string) $sellerProfile->escrow_held_balance);

        $this->assertEquals(5, $product->fresh()->available_quantity);

        $notification = Notification::where('user_id', $seller->id)
            ->where('type', 'ORDER_CANCELLED')
            ->first();
        $this->assertNotNull($notification);
    }

    /**
     * Test #03 (Scenario 03): Buyer requests cancellation at PREPARING (Tier 3 Request).
     */
    public function test_03_buyer_cancels_preparing_fixed_price_order_creates_cancellation_request(): void
    {
        $seller = $this->createIsolatedSeller('seller', 200000.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PREPARING', 'PAID', 'HELD', 1);

        $token = $buyer->createToken('auth')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/orders/{$order->id}/cancel", [
                'reason' => 'Muốn đổi địa chỉ nhận hàng',
            ]);

        $response->assertStatus(200);

        $freshOrder = $order->fresh();
        $this->assertEquals(OrderStatus::PREPARING, $freshOrder->order_status);
        $this->assertTrue($freshOrder->cancellation_requested);
        $this->assertEquals('Muốn đổi địa chỉ nhận hàng', $freshOrder->cancellation_request_reason);

        $notification = Notification::where('user_id', $seller->id)
            ->where('type', 'ORDER_CANCEL_REQUESTED')
            ->first();
        $this->assertNotNull($notification);
    }

    /**
     * Test #04 (Scenario 04): Buyer attempts to cancel SHIPPED order -> 409 Conflict.
     */
    public function test_04_buyer_cancels_shipped_order_is_rejected_with_409_conflict(): void
    {
        $seller = $this->createIsolatedSeller('seller', 200000.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'SHIPPED', 'PAID', 'HELD', 1);

        $token = $buyer->createToken('auth')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/orders/{$order->id}/cancel", [
                'reason' => 'Tôi không muốn nhận hàng nữa',
            ]);

        $response->assertStatus(409);
        $this->assertEquals(OrderStatus::SHIPPED, $order->fresh()->order_status);
    }

    /**
     * Test #05 (Scenario 05): Buyer attempts to cancel DELIVERED or COMPLETED order -> 409 Conflict.
     */
    public function test_05_buyer_cancels_delivered_or_completed_order_is_rejected_with_409_conflict(): void
    {
        $seller = $this->createIsolatedSeller('seller', 200000.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'DELIVERED', 'PAID', 'HELD', 1);

        $token = $buyer->createToken('auth')->plainTextToken;
        $response1 = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/orders/{$order->id}/cancel", [
                'reason' => 'Hàng đã giao nhưng tôi muốn hủy',
            ]);
        $response1->assertStatus(409);

        $order->update(['order_status' => OrderStatus::COMPLETED]);
        $response2 = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/orders/{$order->id}/cancel", [
                'reason' => 'Đã hoàn tất nhưng tôi muốn hủy',
            ]);
        $response2->assertStatus(409);
    }

    /**
     * Test #06 (Scenario 06): Seller directly cancels PAID fixed-price order -> Full Refund.
     */
    public function test_06_seller_direct_cancel_paid_fixed_price_order_triggers_full_refund_and_restores_stock(): void
    {
        $seller = $this->createIsolatedSeller('seller', 200000.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PAID', 'PAID', 'HELD', 1);

        $token = $seller->createToken('auth')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/seller/orders/{$order->id}/cancel", [
                'reason' => 'Sản phẩm phát hiện bị rách góc',
            ]);

        $response->assertStatus(200);

        $freshOrder = $order->fresh();
        $this->assertEquals(OrderStatus::CANCELLED, $freshOrder->order_status);
        $this->assertEquals(PaymentStatus::REFUNDED, $freshOrder->payment_status);
        $this->assertEquals(EscrowStatus::REFUNDED, $freshOrder->escrow_status);
        $this->assertEquals('SELLER', $freshOrder->cancelled_by_role);
        $this->assertEquals('Sản phẩm phát hiện bị rách góc', $freshOrder->cancel_reason);

        $sellerProfile = SellerProfile::where('user_id', $seller->id)->first();
        $this->assertEquals('0.00', (string) $sellerProfile->escrow_held_balance);
        $this->assertEquals(5, $product->fresh()->available_quantity);

        $notification = Notification::where('user_id', $buyer->id)
            ->where('type', 'ORDER_CANCELLED')
            ->first();
        $this->assertNotNull($notification);
    }

    /**
     * Test #07 (Scenario 07): Seller directly cancels PREPARING order (Case A: cancellation_requested = false).
     */
    public function test_07_seller_direct_cancel_preparing_fixed_price_order_without_request_triggers_full_refund(): void
    {
        $seller = $this->createIsolatedSeller('seller', 200000.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PREPARING', 'PAID', 'HELD', 1);

        $token = $seller->createToken('auth')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/seller/orders/{$order->id}/cancel", [
                'reason' => 'Không tìm thấy hàng trong kho để đóng gói',
            ]);

        $response->assertStatus(200);

        $freshOrder = $order->fresh();
        $this->assertEquals(OrderStatus::CANCELLED, $freshOrder->order_status);
        $this->assertEquals(PaymentStatus::REFUNDED, $freshOrder->payment_status);
        $this->assertEquals('SELLER', $freshOrder->cancelled_by_role);
        $this->assertEquals(5, $product->fresh()->available_quantity);

        $sellerProfile = SellerProfile::where('user_id', $seller->id)->first();
        $this->assertEquals('0.00', (string) $sellerProfile->escrow_held_balance);
    }

    /**
     * Test #09 (Scenario 09): Seller direct cancel AUCTION order is rejected with 409 Conflict.
     */
    public function test_09_seller_direct_cancel_auction_order_is_rejected_with_409_conflict(): void
    {
        $seller = $this->createIsolatedSeller('seller', 150000.00);
        $buyer = $this->createIsolatedBuyer();
        $data = $this->createAuctionWithOrder($seller, $buyer, 'PAID', 'PAID');
        $order = $data['order'];

        $token = $seller->createToken('auth')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/seller/orders/{$order->id}/cancel", [
                'reason' => 'Tôi muốn hủy đơn đấu giá này',
            ]);

        $response->assertStatus(409);
        $response->assertJsonFragment([
            'message' => 'Không hỗ trợ người bán hủy đơn hàng đấu giá trực tiếp.',
        ]);
        $this->assertEquals(OrderStatus::PAID, $order->fresh()->order_status);
    }

    /**
     * Test #10 (Scenario 10): Seller direct cancel at invalid states (PENDING_PAYMENT, SHIPPED) -> 409 Conflict.
     */
    public function test_10_seller_direct_cancel_at_invalid_order_status_is_rejected_with_409_conflict(): void
    {
        $seller = $this->createIsolatedSeller('seller', 200000.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);

        $orderPending = $this->createFixedPriceOrder($buyer, $seller, $product, 'PENDING_PAYMENT', 'UNPAID', 'NONE', 1);

        $token = $seller->createToken('auth')->plainTextToken;
        $response1 = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/seller/orders/{$orderPending->id}/cancel", [
                'reason' => 'Người mua chưa thanh toán nhưng tôi muốn hủy',
            ]);
        $response1->assertStatus(409);

        $orderShipped = $this->createFixedPriceOrder($buyer, $seller, $product, 'SHIPPED', 'PAID', 'HELD', 1);
        $response2 = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/seller/orders/{$orderShipped->id}/cancel", [
                'reason' => 'Đã giao nhưng tôi muốn hủy',
            ]);
        $response2->assertStatus(409);
    }

    /**
     * Test #11 (Scenario 11): Seller approves buyer cancellation request at PREPARING (Case B) -> 100% Full Refund.
     */
    public function test_11_seller_approves_buyer_cancellation_request_at_preparing_triggers_full_refund(): void
    {
        $seller = $this->createIsolatedSeller('seller', 200000.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PREPARING', 'PAID', 'HELD', 1);

        $order->update([
            'cancellation_requested' => true,
            'cancellation_request_reason' => 'Người mua đổi ý',
        ]);

        $token = $seller->createToken('auth')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/seller/orders/{$order->id}/respond-cancel", [
                'decision' => 'APPROVE',
                'note' => 'Đồng ý hủy cho bạn',
            ]);

        $response->assertStatus(200);

        $freshOrder = $order->fresh();
        $this->assertEquals(OrderStatus::CANCELLED, $freshOrder->order_status);
        $this->assertEquals(PaymentStatus::REFUNDED, $freshOrder->payment_status);
        $this->assertEquals(EscrowStatus::REFUNDED, $freshOrder->escrow_status);
        $this->assertFalse($freshOrder->cancellation_requested);
        $this->assertEquals('BUYER', $freshOrder->cancelled_by_role);

        $sellerProfile = SellerProfile::where('user_id', $seller->id)->first();
        $this->assertEquals('0.00', (string) $sellerProfile->escrow_held_balance);
        $this->assertEquals(5, $product->fresh()->available_quantity);

        $notification = Notification::where('user_id', $buyer->id)
            ->where('type', 'ORDER_CANCEL_APPROVED')
            ->first();
        $this->assertNotNull($notification);
    }

    /**
     * Test #12 (Scenario 12): Seller rejects buyer cancellation request at PREPARING (Case B) -> remains PREPARING.
     */
    public function test_12_seller_rejects_buyer_cancellation_request_at_preparing_keeps_order_in_preparing(): void
    {
        $seller = $this->createIsolatedSeller('seller', 200000.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PREPARING', 'PAID', 'HELD', 1);

        $order->update([
            'cancellation_requested' => true,
            'cancellation_request_reason' => 'Người mua đổi ý',
        ]);

        $token = $seller->createToken('auth')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/seller/orders/{$order->id}/respond-cancel", [
                'decision' => 'REJECT',
                'note' => 'Hàng đã đóng gói xong rồi',
            ]);

        $response->assertStatus(200);

        $freshOrder = $order->fresh();
        $this->assertEquals(OrderStatus::PREPARING, $freshOrder->order_status);
        $this->assertFalse($freshOrder->cancellation_requested);

        $sellerProfile = SellerProfile::where('user_id', $seller->id)->first();
        $this->assertEquals('200000.00', (string) $sellerProfile->escrow_held_balance);
        $this->assertEquals(4, $product->fresh()->available_quantity);

        $notification = Notification::where('user_id', $buyer->id)
            ->where('type', 'ORDER_CANCEL_REJECTED')
            ->first();
        $this->assertNotNull($notification);
    }

    /**
     * Test #13 (Scenario 13): Buyer cancellation request on PREPARING AUCTION order is rejected with 409 (Option 3A).
     */
    public function test_13_buyer_cancellation_request_on_preparing_auction_order_is_rejected_with_409_option_3a(): void
    {
        $seller = $this->createIsolatedSeller('seller', 150000.00);
        $buyer = $this->createIsolatedBuyer();
        $data = $this->createAuctionWithOrder($seller, $buyer, 'PREPARING', 'PAID');
        $order = $data['order'];

        $token = $buyer->createToken('auth')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/orders/{$order->id}/cancel", [
                'reason' => 'Không muốn nhận hàng đấu giá nữa',
            ]);

        $response->assertStatus(409);
        $response->assertJsonFragment([
            'message' => 'Không thể yêu cầu hủy đơn hàng đấu giá ở trạng thái đang chuẩn bị hàng.',
        ]);

        $freshOrder = $order->fresh();
        $this->assertEquals(OrderStatus::PREPARING, $freshOrder->order_status);
        $this->assertFalse((bool) $freshOrder->cancellation_requested);
    }

    /**
     * Test #14 (Scenario 14): Buyer cancels unpaid AUCTION order -> Winner Default penalty and product relisting.
     */
    public function test_14_buyer_cancels_unpaid_auction_order_triggers_winner_default_penalty_and_unlocks_product(): void
    {
        $seller = $this->createIsolatedSeller('seller', 0.00);
        $buyer = $this->createIsolatedBuyer();
        $data = $this->createAuctionWithOrder($seller, $buyer, 'PENDING_PAYMENT', 'UNPAID');
        $order = $data['order'];
        $auction = $data['auction'];
        $product = $data['product'];

        $buyerProfile = SellerProfile::where('user_id', $buyer->id)->first();
        $this->assertEquals(0, $buyerProfile->auction_default_count);

        $token = $buyer->createToken('auth')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/v1/orders/{$order->id}/cancel", [
                'reason' => 'Tôi tự nguyện hủy phiên thắng đấu giá',
            ]);

        $response->assertStatus(200);

        $freshOrder = $order->fresh();
        $this->assertEquals(OrderStatus::CANCELLED, $freshOrder->order_status);
        $this->assertEquals(PaymentStatus::EXPIRED, $freshOrder->payment_status);
        $this->assertEquals('BUYER', $freshOrder->cancelled_by_role);

        $freshAuction = $auction->fresh();
        $this->assertEquals(AuctionStatus::WINNER_DEFAULTED, $freshAuction->status);

        $freshProduct = $product->fresh();
        $this->assertEquals(ProductStatus::APPROVED, $freshProduct->status);
        $this->assertEquals(1, $freshProduct->available_quantity);

        $freshBuyerProfile = SellerProfile::where('user_id', $buyer->id)->first();
        $this->assertEquals(1, $freshBuyerProfile->auction_default_count);

        $buyerNotif = Notification::where('user_id', $buyer->id)
            ->where('type', 'AUCTION_WINNER_DEFAULTED')
            ->first();
        $this->assertNotNull($buyerNotif);

        $sellerNotif = Notification::where('user_id', $seller->id)
            ->where('type', 'AUCTION_WINNER_DEFAULTED')
            ->first();
        $this->assertNotNull($sellerNotif);
    }

    /**
     * Test #15 (Scenario 15): Cron expiration of overdue unpaid AUCTION order -> Winner Default.
     */
    public function test_15_cron_expiration_of_overdue_unpaid_auction_order_triggers_winner_default(): void
    {
        $seller = $this->createIsolatedSeller('seller', 0.00);
        $buyer = $this->createIsolatedBuyer();
        $data = $this->createAuctionWithOrder($seller, $buyer, 'PENDING_PAYMENT', 'UNPAID');
        $order = $data['order'];
        $auction = $data['auction'];
        $product = $data['product'];

        $order->update(['payment_expires_at' => now()->subMinutes(10)]);

        $expirationService = app(OrderExpirationService::class);
        $result = $expirationService->expireOverdueUnpaidOrders();

        $this->assertContains($order->id, $result['expired_order_ids']);

        $freshOrder = $order->fresh();
        $this->assertEquals(OrderStatus::CANCELLED, $freshOrder->order_status);
        $this->assertEquals(PaymentStatus::EXPIRED, $freshOrder->payment_status);
        $this->assertEquals('SYSTEM', $freshOrder->cancelled_by_role);

        $this->assertEquals(AuctionStatus::WINNER_DEFAULTED, $auction->fresh()->status);
        $this->assertEquals(ProductStatus::APPROVED, $product->fresh()->status);
        $this->assertEquals(1, $product->fresh()->available_quantity);

        $buyerProfile = SellerProfile::where('user_id', $buyer->id)->first();
        $this->assertEquals(1, $buyerProfile->auction_default_count);
    }

    /**
     * Test #16 (Scenario 16): Cron expiration of overdue unpaid FIXED_PRICE order -> Restores stock.
     */
    public function test_16_cron_expiration_of_overdue_unpaid_fixed_price_order_restores_product_stock(): void
    {
        $seller = $this->createIsolatedSeller();
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PENDING_PAYMENT', 'UNPAID', 'NONE', 1);

        $order->update(['payment_expires_at' => now()->subMinutes(10)]);
        $this->assertEquals(4, $product->fresh()->available_quantity);

        $expirationService = app(OrderExpirationService::class);
        $result = $expirationService->expireOverdueUnpaidOrders();

        $this->assertContains($order->id, $result['expired_order_ids']);
        $this->assertEquals(OrderStatus::CANCELLED, $order->fresh()->order_status);
        $this->assertEquals(5, $product->fresh()->available_quantity);

        $buyerProfile = SellerProfile::where('user_id', $buyer->id)->first();
        $this->assertEquals(0, $buyerProfile->auction_default_count);
    }

    /**
     * Test #17 (Scenario 17): Non-owner authorization guards reject cancellation operations with 403.
     */
    public function test_17_non_owner_authorization_guards_reject_cancellation_operations_with_403(): void
    {
        $seller = $this->createIsolatedSeller('seller1', 200000.00);
        $buyer = $this->createIsolatedBuyer('buyer1');
        $otherBuyer = $this->createIsolatedBuyer('buyer2');
        $otherSeller = $this->createIsolatedSeller('seller2', 200000.00);

        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PREPARING', 'PAID', 'HELD', 1);

        // Other buyer cannot cancel
        $otherBuyerToken = $otherBuyer->createToken('auth')->plainTextToken;
        $resBuyer = $this->withHeader('Authorization', "Bearer {$otherBuyerToken}")
            ->postJson("/api/v1/orders/{$order->id}/cancel", ['reason' => 'Can thiệp']);
        $resBuyer->assertStatus(403);

        // Other seller cannot direct cancel
        $otherSellerToken = $otherSeller->createToken('auth')->plainTextToken;
        $resSeller = $this->withHeader('Authorization', "Bearer {$otherSellerToken}")
            ->postJson("/api/v1/seller/orders/{$order->id}/cancel", ['reason' => 'Can thiệp']);
        $resSeller->assertStatus(403);

        // Other seller cannot respond to cancel request
        $order->update(['cancellation_requested' => true, 'cancellation_request_reason' => 'Lý do']);
        $resRespond = $this->withHeader('Authorization', "Bearer {$otherSellerToken}")
            ->postJson("/api/v1/seller/orders/{$order->id}/respond-cancel", ['decision' => 'APPROVE']);
        $resRespond->assertStatus(403);
    }

    /**
     * Test #18 (Scenario 18): Escrow accounting reconciliation verifies ledger invariant and underflow prevention.
     */
    public function test_18_escrow_accounting_reconciliation_verifies_ledger_invariant_and_underflow_prevention(): void
    {
        $seller = $this->createIsolatedSeller('seller', 200000.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PAID', 'PAID', 'HELD', 1);

        // Invariant holds before cancel
        $sellerProfile = SellerProfile::where('user_id', $seller->id)->first();
        $holds = (float) EscrowTransaction::where('seller_id', $seller->id)->where('transaction_type', 'HOLD')->sum('item_subtotal_amount');
        $releases = (float) EscrowTransaction::where('seller_id', $seller->id)->where('transaction_type', 'RELEASE')->sum('item_subtotal_amount');
        $fullRefunds = (float) EscrowTransaction::where('seller_id', $seller->id)->where('transaction_type', 'FULL_REFUND')->sum('item_subtotal_amount');
        $partialRefunds = (float) EscrowTransaction::where('seller_id', $seller->id)->where('transaction_type', 'PARTIAL_REFUND')->sum('item_subtotal_amount');

        $expectedHeld = $holds - $releases - $fullRefunds - $partialRefunds;
        $this->assertEquals($expectedHeld, (float) $sellerProfile->escrow_held_balance);

        // Now test underflow prevention: artificially corrupt held balance to less than item_subtotal
        $sellerProfile->update(['escrow_held_balance' => 50000.00]);

        $cancellationService = app(OrderCancellationService::class);
        $this->expectException(EscrowLedgerIntegrityException::class);
        $this->expectExceptionMessage('Số dư ký quỹ không đủ để hoàn tiền');

        $cancellationService->sellerDirectCancel($seller, $order, 'Test underflow failure');
    }

    // =========================================================================
    // SECTION 2: CONCURRENCY & ISOLATION GUARANTEES (TESTS #19 TO #23)
    // =========================================================================

    /**
     * Test #19A (Scenario 19A): Concurrent QR payment vs Buyer cancellation.
     * When cancellation acquires order lock first, QR payment fails gracefully with 409/state error.
     */
    public function test_19a_concurrent_qr_payment_vs_buyer_cancel_when_cancel_wins_payment_fails_gracefully(): void
    {
        $seller = $this->createIsolatedSeller('seller', 0.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PENDING_PAYMENT', 'UNPAID', 'NONE', 1);

        $payment = Payment::where('order_id', $order->id)->first();
        $this->assertNotNull($payment);

        $cancellationService = app(OrderCancellationService::class);
        $qrPaymentService = app(MockQrPaymentService::class);

        // Cancellation executes first
        $cancelledOrder = $cancellationService->buyerCancelOrRequest($buyer, $order, 'Tôi muốn hủy ngay');
        $this->assertEquals(OrderStatus::CANCELLED, $cancelledOrder->order_status);

        // QR payment attempts to process on cancelled order
        $paymentFailed = false;
        try {
            $qrPaymentService->simulateSuccess($buyer, $payment->id);
        } catch (\Throwable $e) {
            $paymentFailed = true;
            $this->assertStringContainsString('CANCELLED', $e->getMessage());
        }

        $this->assertTrue($paymentFailed, 'QR payment must fail when order has already been cancelled.');
        $this->assertEquals(0, EscrowTransaction::where('order_id', $order->id)->where('transaction_type', 'HOLD')->count());
    }

    /**
     * Test #19B (Scenario 19B): Serialized QR payment followed by Buyer cancellation -> Tier 2 Full Refund.
     */
    public function test_19b_serialized_qr_payment_followed_by_buyer_cancel_executes_tier2_full_refund(): void
    {
        $seller = $this->createIsolatedSeller('seller', 0.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PENDING_PAYMENT', 'UNPAID', 'NONE', 1);

        $payment = Payment::where('order_id', $order->id)->first();
        $qrPaymentService = app(MockQrPaymentService::class);
        $cancellationService = app(OrderCancellationService::class);

        // 1. QR payment succeeds first
        $payResult = $qrPaymentService->simulateSuccess($buyer, $payment->id);
        $this->assertEquals(OrderStatus::PAID, $payResult['order']->order_status);

        // 2. Buyer cancels immediately after payment commit
        $cancelResult = $cancellationService->buyerCancelOrRequest($buyer, $order->fresh(), 'Tôi đổi ý sau khi vừa thanh toán xong');

        $this->assertEquals(OrderStatus::CANCELLED, $cancelResult->order_status);
        $this->assertEquals(PaymentStatus::REFUNDED, $cancelResult->payment_status);
        $this->assertEquals(EscrowStatus::REFUNDED, $cancelResult->escrow_status);

        $sellerProfile = SellerProfile::where('user_id', $seller->id)->first();
        $this->assertEquals('0.00', (string) $sellerProfile->escrow_held_balance);
        $this->assertEquals(5, $product->fresh()->available_quantity);
    }

    /**
     * Test #20A (Scenario 20A): Semantic SQL row-lock ordering verification.
     * Verifies that product IDs are locked in sorted ASC order BEFORE locking SellerProfile.
     */
    public function test_20a_semantic_sql_lock_hierarchy_verifies_product_sorted_asc_before_seller_profile(): void
    {
        $seller = $this->createIsolatedSeller('seller', 600000.00);
        $buyer = $this->createIsolatedBuyer();

        $prod1 = $this->createFixedPriceProduct($seller, 100000.00, 5);
        $prod2 = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $prod3 = $this->createFixedPriceProduct($seller, 300000.00, 5);

        // Ensure we test sorted acquisition order: product IDs sorted asc
        $order = $this->createFixedPriceOrder($buyer, $seller, $prod2, 'PAID', 'PAID', 'HELD', 1);

        // Add additional items to order
        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $prod1->id,
            'product_code_snapshot' => $prod1->product_code,
            'product_title_snapshot' => $prod1->title,
            'condition_snapshot' => $prod1->condition,
            'defect_info_snapshot' => $prod1->defect_info,
            'primary_image_snapshot' => 'http://localhost/default.jpg',
            'unit_price_snapshot' => $prod1->price,
            'quantity' => 1,
            'line_total' => $prod1->price,
        ]);
        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $prod3->id,
            'product_code_snapshot' => $prod3->product_code,
            'product_title_snapshot' => $prod3->title,
            'condition_snapshot' => $prod3->condition,
            'defect_info_snapshot' => $prod3->defect_info,
            'primary_image_snapshot' => 'http://localhost/default.jpg',
            'unit_price_snapshot' => $prod3->price,
            'quantity' => 1,
            'line_total' => $prod3->price,
        ]);

        $prod1->decrement('available_quantity', 1);
        $prod3->decrement('available_quantity', 1);

        $order->update([
            'item_subtotal' => 600000.00,
            'seller_net_amount' => 600000.00,
            'buyer_protection_fee' => 18000.00,
            'total_amount' => 618000.00,
        ]);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $cancellationService = app(OrderCancellationService::class);
        $cancellationService->buyerCancelOrRequest($buyer, $order->fresh(), 'Hủy đơn kiểm tra thứ tự khóa');

        $queryLog = DB::getQueryLog();
        DB::disableQueryLog();

        $productLockIndex = null;
        $sellerProfileLockIndex = null;

        foreach ($queryLog as $idx => $entry) {
            $sql = strtolower($entry['query']);
            if (str_contains($sql, 'products') && str_contains($sql, 'for update')) {
                $productLockIndex = $idx;
                $this->assertStringContainsString('order by "id" asc', $sql, 'Product row-locks must enforce ORDER BY id ASC.');
            }
            if (str_contains($sql, 'seller_profiles') && str_contains($sql, 'for update')) {
                $sellerProfileLockIndex = $idx;
            }
        }

        $this->assertNotNull($productLockIndex, 'Product FOR UPDATE query must be executed.');
        $this->assertNotNull($sellerProfileLockIndex, 'SellerProfile FOR UPDATE query must be executed.');
        $this->assertLessThan(
            $sellerProfileLockIndex,
            $productLockIndex,
            'Strict lock ordering: Product FOR UPDATE must precede SellerProfile FOR UPDATE.'
        );
    }

    /**
     * Test #20B (Scenario 20B): Product row-lock contention serializes concurrent inventory access.
     * Captures direct pg_blocking_pids() evidence between independent OS worker processes.
     */
    public function test_20b_product_lock_contention_serializes_concurrent_order_cancellation_and_inventory_access(): void
    {
        $seller = $this->createIsolatedSeller('seller', 200000.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PAID', 'PAID', 'HELD', 1);

        $workerAScript = null;
        $workerBScript = null;
        $workerAReadyFile = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'p903_20b_a_ready_' . uniqid();
        $workerAReleaseFile = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'p903_20b_a_rel_' . uniqid();
        $workerBReadyFile = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'p903_20b_b_ready_' . uniqid();

        $procA = null;
        $procB = null;

        try {
            $basePath = addslashes(base_path());

            // Worker A: Acquires lock on Product and holds until released
            $workerAContent = <<<PHP
<?php
require '{$basePath}/vendor/autoload.php';
\$app = require '{$basePath}/bootstrap/app.php';
\$app->make(\\Illuminate\\Contracts\\Console\\Kernel::class)->bootstrap();

use Illuminate\\Support\\Facades\\DB;
use App\\Models\\Product;

\$productId = (int) \$argv[1];
\$readyFile = \$argv[2];
\$releaseFile = \$argv[3];

DB::transaction(function () use (\$productId, \$readyFile, \$releaseFile) {
    Product::where('id', \$productId)->lockForUpdate()->first();
    \$pid = (int) DB::selectOne("SELECT pg_backend_pid() AS pid")->pid;
    file_put_contents(\$readyFile, json_encode(['pid' => \$pid, 'status' => 'LOCKED']));

    \$timeout = microtime(true) + 5.0;
    while (!file_exists(\$releaseFile) && microtime(true) < \$timeout) {
        usleep(5000);
    }
});
echo json_encode(['result' => 'COMMITTED']);
PHP;

            // Worker B: Attempts to cancel order, which requires product lock for stock restoration
            $workerBContent = <<<PHP
<?php
require '{$basePath}/vendor/autoload.php';
\$app = require '{$basePath}/bootstrap/app.php';
\$app->make(\\Illuminate\\Contracts\\Console\\Kernel::class)->bootstrap();

use Illuminate\\Support\\Facades\\DB;
use App\\Models\\User;
use App\\Models\\Order;
use App\\Services\\Order\\OrderCancellationService;

\$buyerId = (int) \$argv[1];
\$orderId = (int) \$argv[2];
\$readyFile = \$argv[3];

\$buyer = User::findOrFail(\$buyerId);
\$order = Order::findOrFail(\$orderId);

\$pid = (int) DB::selectOne("SELECT pg_backend_pid() AS pid")->pid;
file_put_contents(\$readyFile, json_encode(['pid' => \$pid, 'status' => 'STARTING']));

\$service = app(OrderCancellationService::class);
try {
    \$service->buyerCancelOrRequest(\$buyer, \$order, 'Hủy đơn kiểm tra khóa đối kháng');
    echo json_encode(['result' => 'SUCCESS']);
} catch (\\Throwable \$e) {
    echo json_encode(['result' => 'ERROR', 'class' => get_class(\$e), 'message' => \$e->getMessage()]);
}
PHP;

            $workerAScript = $this->createTransientWorkerScript($workerAContent);
            $workerBScript = $this->createTransientWorkerScript($workerBContent);

            $cmdA = sprintf('"%s" "%s" %d "%s" "%s"', PHP_BINARY, $workerAScript, $product->id, $workerAReadyFile, $workerAReleaseFile);
            $cmdB = sprintf('"%s" "%s" %d %d "%s"', PHP_BINARY, $workerBScript, $buyer->id, $order->id, $workerBReadyFile);

            $descriptors = [
                0 => ['pipe', 'r'],
                1 => ['pipe', 'w'],
                2 => ['pipe', 'w'],
            ];

            // 1. Launch Worker A
            $procA = proc_open($cmdA, $descriptors, $pipesA, base_path());
            $this->assertIsResource($procA);

            // Wait for Worker A to acquire lock
            $startWait = microtime(true);
            while (!file_exists($workerAReadyFile)) {
                if ((microtime(true) - $startWait) > 5.0) {
                    $errA = stream_get_contents($pipesA[2]);
                    $this->fail("Timed out waiting for Worker A to lock product. Stderr: {$errA}");
                }
                usleep(5000);
            }

            $workerAData = json_decode(file_get_contents($workerAReadyFile), true);
            $this->assertIsArray($workerAData);
            $pidA = (int) $workerAData['pid'];
            $this->assertGreaterThan(0, $pidA);

            // 2. Launch Worker B
            $procB = proc_open($cmdB, $descriptors, $pipesB, base_path());
            $this->assertIsResource($procB);

            // Wait for Worker B to reach STARTING status
            $startWait = microtime(true);
            while (!file_exists($workerBReadyFile)) {
                if ((microtime(true) - $startWait) > 5.0) {
                    $errB = stream_get_contents($pipesB[2]);
                    $this->fail("Timed out waiting for Worker B to start. Stderr: {$errB}");
                }
                usleep(5000);
            }

            $workerBData = json_decode(file_get_contents($workerBReadyFile), true);
            $this->assertIsArray($workerBData);
            $pidB = (int) $workerBData['pid'];
            $this->assertGreaterThan(0, $pidB);
            $this->assertNotEquals($pidA, $pidB, 'Worker A and Worker B must have distinct PostgreSQL backend PIDs.');

            // 3. Capture pg_blocking_pids() evidence
            $blockers = [];
            $startWait = microtime(true);
            while (empty($blockers) && (microtime(true) - $startWait) < 3.0) {
                $row = DB::selectOne('SELECT pg_blocking_pids(?) AS blockers', [$pidB]);
                if ($row && !empty($row->blockers)) {
                    $val = $row->blockers;
                    if (is_string($val)) {
                        $val = trim($val, '{}');
                        $blockers = array_filter(explode(',', $val));
                    } elseif (is_array($val)) {
                        $blockers = $val;
                    }
                }
                if (empty($blockers)) {
                    usleep(10000);
                }
            }

            $this->assertNotEmpty($blockers, 'Worker B must be blocked in PostgreSQL by Worker A holding the product row lock.');
            $this->assertContains((string) $pidA, array_map('strval', $blockers), 'Worker B pg_blocking_pids must contain Worker A backend PID.');

            // 4. Release Worker A to allow Worker B to proceed
            file_put_contents($workerAReleaseFile, 'release');

            // 5. Gather Worker A results
            $outA = stream_get_contents($pipesA[1]);
            $errA = stream_get_contents($pipesA[2]);
            fclose($pipesA[0]);
            fclose($pipesA[1]);
            fclose($pipesA[2]);
            proc_close($procA);
            $procA = null;

            $resA = json_decode(trim($outA), true);
            $this->assertIsArray($resA, "Worker A failed to commit. Stderr: {$errA}, Stdout: {$outA}");
            $this->assertEquals('COMMITTED', $resA['result']);

            // 6. Gather Worker B results
            $outB = stream_get_contents($pipesB[1]);
            $errB = stream_get_contents($pipesB[2]);
            fclose($pipesB[0]);
            fclose($pipesB[1]);
            fclose($pipesB[2]);
            proc_close($procB);
            $procB = null;

            $resB = json_decode(trim($outB), true);
            $this->assertIsArray($resB, "Worker B failed to complete cancellation. Stderr: {$errB}, Stdout: {$outB}");
            $this->assertEquals('SUCCESS', $resB['result']);

            // 7. Verify final database state
            $this->assertEquals(OrderStatus::CANCELLED, $order->fresh()->order_status);
            $this->assertEquals(PaymentStatus::REFUNDED, $order->fresh()->payment_status);
            $this->assertEquals(5, $product->fresh()->available_quantity);
        } finally {
            if ($procA && is_resource($procA)) {
                proc_terminate($procA);
                proc_close($procA);
            }
            if ($procB && is_resource($procB)) {
                proc_terminate($procB);
                proc_close($procB);
            }
            foreach ([$workerAScript, $workerBScript, $workerAReadyFile, $workerAReleaseFile, $workerBReadyFile] as $f) {
                if ($f && file_exists($f)) {
                    @unlink($f);
                }
            }
        }
    }

    /**
     * Test #21 (Scenario 21): Concurrency Auction Winner Default vs Cron SKIP LOCKED.
     * Demonstrates that SKIP LOCKED skips the locked record and prevents duplicate penalty/relisting.
     */
    public function test_21_concurrent_auction_winner_default_and_cron_skip_locked_prevents_duplicate_processing(): void
    {
        $seller = $this->createIsolatedSeller('seller', 0.00);
        $buyer = $this->createIsolatedBuyer();
        $data = $this->createAuctionWithOrder($seller, $buyer, 'PENDING_PAYMENT', 'UNPAID');
        $order = $data['order'];
        $auction = $data['auction'];
        $product = $data['product'];

        $order->update(['payment_expires_at' => now()->subMinutes(10)]);

        $workerScript = null;
        try {
            $basePath = addslashes(base_path());
            $workerContent = <<<PHP
<?php
require '{$basePath}/vendor/autoload.php';
\$app = require '{$basePath}/bootstrap/app.php';
\$app->make(\\Illuminate\\Contracts\\Console\\Kernel::class)->bootstrap();

use App\\Services\\Order\\OrderExpirationService;

\$service = app(OrderExpirationService::class);
\$result = \$service->expireOverdueUnpaidOrders();
echo json_encode(\$result);
PHP;
            $workerScript = $this->createTransientWorkerScript($workerContent);
            $cmd = sprintf('"%s" "%s"', PHP_BINARY, $workerScript);

            // Process 1: User transaction holds lock on Order
            DB::transaction(function () use ($order, $buyer, $cmd) {
                $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->first();

                // Process 2: Independent OS process runs cron with FOR UPDATE SKIP LOCKED
                $descriptors = [
                    0 => ['pipe', 'r'],
                    1 => ['pipe', 'w'],
                    2 => ['pipe', 'w'],
                ];
                $proc = proc_open($cmd, $descriptors, $pipes, base_path());
                $out = stream_get_contents($pipes[1]);
                $err = stream_get_contents($pipes[2]);
                proc_close($proc);

                $cronResult = json_decode($out, true);
                $this->assertIsArray($cronResult, "Cron worker failed. Stderr: {$err}, Stdout: {$out}");

                // Assert cron skipped the currently locked order
                $this->assertNotContains($order->id, $cronResult['expired_order_ids'], 'Cron SKIP LOCKED must skip currently locked order.');

                // Process 1 finishes processing default
                OrderExpirationService::processAuctionWinnerDefault($lockedOrder, 'BUYER', 'Người mua tự nguyện hủy');
            });
        } finally {
            if ($workerScript && file_exists($workerScript)) {
                @unlink($workerScript);
            }
        }

        $this->assertEquals(AuctionStatus::WINNER_DEFAULTED, $auction->fresh()->status);
        $this->assertEquals(ProductStatus::APPROVED, $product->fresh()->status);
        $this->assertEquals(1, $product->fresh()->available_quantity);

        $buyerProfile = SellerProfile::where('user_id', $buyer->id)->first();
        $this->assertEquals(1, $buyerProfile->auction_default_count, 'Buyer default count must be incremented exactly once.');
    }

    /**
     * Test #22 (Scenario 22): Concurrency Seller Approve vs Reject race is serialized by order lock.
     * Upgraded to genuine dual OS worker processes with pg_blocking_pids() capture and state revalidation.
     */
    public function test_22_concurrent_seller_approve_vs_reject_race_is_serialized_by_order_lock(): void
    {
        $seller = $this->createIsolatedSeller('seller', 200000.00);
        $buyer = $this->createIsolatedBuyer();
        $product = $this->createFixedPriceProduct($seller, 200000.00, 5);
        $order = $this->createFixedPriceOrder($buyer, $seller, $product, 'PREPARING', 'PAID', 'HELD', 1);

        $order->update([
            'cancellation_requested' => true,
            'cancellation_request_reason' => 'Yêu cầu hủy cần xử lý',
        ]);

        $workerAScript = null;
        $workerBScript = null;
        $workerASyncFile = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'p903_22_a_sync_' . uniqid();
        $workerAReleaseFile = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'p903_22_a_rel_' . uniqid();
        $workerBReadyFile = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'p903_22_b_ready_' . uniqid();

        $procA = null;
        $procB = null;

        try {
            $basePath = addslashes(base_path());

            // Worker A (Seller APPROVE): Holds Order row-lock inside transaction until release signal
            $workerAContent = <<<PHP
<?php
require '{$basePath}/vendor/autoload.php';
\$app = require '{$basePath}/bootstrap/app.php';
\$app->make(\\Illuminate\\Contracts\\Console\\Kernel::class)->bootstrap();

use Illuminate\\Support\\Facades\\DB;
use App\\Models\\User;
use App\\Models\\Order;
use App\\Services\\Order\\OrderCancellationService;

\$sellerId = (int) \$argv[1];
\$orderId = (int) \$argv[2];
\$syncFile = \$argv[3];
\$releaseFile = \$argv[4];

\$seller = User::findOrFail(\$sellerId);
\$order = Order::findOrFail(\$orderId);

\$captured = false;
DB::listen(function (\$query) use (&\$captured, \$syncFile, \$releaseFile) {
    if (!\$captured && str_contains(strtolower(\$query->sql), 'orders') && str_contains(strtolower(\$query->sql), 'for update')) {
        \$captured = true;
        \$pid = (int) DB::selectOne("SELECT pg_backend_pid() AS pid")->pid;
        file_put_contents(\$syncFile, json_encode(['pid' => \$pid, 'status' => 'HOLDING_LOCK']));
        \$timeout = microtime(true) + 5.0;
        while (!file_exists(\$releaseFile) && microtime(true) < \$timeout) {
            usleep(5000);
        }
    }
});

\$service = app(OrderCancellationService::class);
try {
    \$service->sellerRespondCancelRequest(\$seller, \$order, 'APPROVE', 'Đồng ý duyệt hủy');
    echo json_encode(['result' => 'APPROVED']);
} catch (\\Throwable \$e) {
    echo json_encode(['result' => 'ERROR', 'class' => get_class(\$e), 'message' => \$e->getMessage()]);
}
PHP;

            // Worker B (Seller REJECT): Attempts to respond REJECT to same order
            $workerBContent = <<<PHP
<?php
require '{$basePath}/vendor/autoload.php';
\$app = require '{$basePath}/bootstrap/app.php';
\$app->make(\\Illuminate\\Contracts\\Console\\Kernel::class)->bootstrap();

use Illuminate\\Support\\Facades\\DB;
use App\\Models\\User;
use App\\Models\\Order;
use App\\Services\\Order\\OrderCancellationService;

\$sellerId = (int) \$argv[1];
\$orderId = (int) \$argv[2];
\$readyFile = \$argv[3];

\$seller = User::findOrFail(\$sellerId);
\$order = Order::findOrFail(\$orderId);

\$pid = (int) DB::selectOne("SELECT pg_backend_pid() AS pid")->pid;
file_put_contents(\$readyFile, json_encode(['pid' => \$pid, 'status' => 'READY']));

\$service = app(OrderCancellationService::class);
try {
    \$service->sellerRespondCancelRequest(\$seller, \$order, 'REJECT', 'Từ chối hủy');
    echo json_encode(['result' => 'REJECTED']);
} catch (\\Throwable \$e) {
    echo json_encode(['result' => 'ERROR', 'class' => get_class(\$e), 'message' => \$e->getMessage()]);
}
PHP;

            $workerAScript = $this->createTransientWorkerScript($workerAContent);
            $workerBScript = $this->createTransientWorkerScript($workerBContent);

            $cmdA = sprintf('"%s" "%s" %d %d "%s" "%s"', PHP_BINARY, $workerAScript, $seller->id, $order->id, $workerASyncFile, $workerAReleaseFile);
            $cmdB = sprintf('"%s" "%s" %d %d "%s"', PHP_BINARY, $workerBScript, $seller->id, $order->id, $workerBReadyFile);

            $descriptors = [
                0 => ['pipe', 'r'],
                1 => ['pipe', 'w'],
                2 => ['pipe', 'w'],
            ];

            // 1. Launch Worker A (APPROVE)
            $procA = proc_open($cmdA, $descriptors, $pipesA, base_path());
            $this->assertIsResource($procA);

            // Wait for Worker A to acquire lock and signal HOLDING_LOCK
            $startWait = microtime(true);
            while (!file_exists($workerASyncFile)) {
                if ((microtime(true) - $startWait) > 5.0) {
                    $errA = stream_get_contents($pipesA[2]);
                    $this->fail("Timed out waiting for Worker A to acquire Order row lock. Stderr: {$errA}");
                }
                usleep(5000);
            }

            $workerAData = json_decode(file_get_contents($workerASyncFile), true);
            $this->assertIsArray($workerAData);
            $pidA = (int) $workerAData['pid'];
            $this->assertGreaterThan(0, $pidA);

            // 2. Launch Worker B (REJECT)
            $procB = proc_open($cmdB, $descriptors, $pipesB, base_path());
            $this->assertIsResource($procB);

            // Wait for Worker B to reach READY status
            $startWait = microtime(true);
            while (!file_exists($workerBReadyFile)) {
                if ((microtime(true) - $startWait) > 5.0) {
                    $errB = stream_get_contents($pipesB[2]);
                    $this->fail("Timed out waiting for Worker B to start. Stderr: {$errB}");
                }
                usleep(5000);
            }

            $workerBData = json_decode(file_get_contents($workerBReadyFile), true);
            $this->assertIsArray($workerBData);
            $pidB = (int) $workerBData['pid'];
            $this->assertGreaterThan(0, $pidB);
            $this->assertNotEquals($pidA, $pidB, 'Worker A and Worker B must have distinct PostgreSQL backend PIDs.');

            // 3. Capture pg_blocking_pids() evidence
            $blockers = [];
            $startWait = microtime(true);
            while (empty($blockers) && (microtime(true) - $startWait) < 3.0) {
                $row = DB::selectOne('SELECT pg_blocking_pids(?) AS blockers', [$pidB]);
                if ($row && !empty($row->blockers)) {
                    $val = $row->blockers;
                    if (is_string($val)) {
                        $val = trim($val, '{}');
                        $blockers = array_filter(explode(',', $val));
                    } elseif (is_array($val)) {
                        $blockers = $val;
                    }
                }
                if (empty($blockers)) {
                    usleep(10000);
                }
            }

            $this->assertNotEmpty($blockers, 'Worker B must be blocked in PostgreSQL by Worker A holding the order row lock.');
            $this->assertContains((string) $pidA, array_map('strval', $blockers), 'Worker B pg_blocking_pids must contain Worker A backend PID.');

            // 4. Release Worker A
            file_put_contents($workerAReleaseFile, 'release');

            // 5. Gather Worker A results
            $outA = stream_get_contents($pipesA[1]);
            $errA = stream_get_contents($pipesA[2]);
            fclose($pipesA[0]);
            fclose($pipesA[1]);
            fclose($pipesA[2]);
            proc_close($procA);
            $procA = null;

            $resA = json_decode(trim($outA), true);
            $this->assertIsArray($resA, "Worker A failed to approve. Stderr: {$errA}, Stdout: {$outA}");
            $this->assertEquals('APPROVED', $resA['result']);

            // 6. Gather Worker B results (should unblock, revalidate state, and fail with InvalidStateTransitionException)
            $outB = stream_get_contents($pipesB[1]);
            $errB = stream_get_contents($pipesB[2]);
            fclose($pipesB[0]);
            fclose($pipesB[1]);
            fclose($pipesB[2]);
            proc_close($procB);
            $procB = null;

            $resB = json_decode(trim($outB), true);
            $this->assertIsArray($resB, "Worker B failed to return structured error. Stderr: {$errB}, Stdout: {$outB}");
            $this->assertEquals('ERROR', $resB['result']);
            $this->assertStringContainsString('InvalidStateTransitionException', $resB['class']);
            $this->assertStringContainsString('không có yêu cầu hủy nào đang chờ', $resB['message']);

            // 7. Verify single terminal outcome and financial/inventory invariants
            $freshOrder = $order->fresh();
            $this->assertEquals(OrderStatus::CANCELLED, $freshOrder->order_status);
            $this->assertFalse((bool) $freshOrder->cancellation_requested);
            $this->assertEquals('BUYER', $freshOrder->cancelled_by_role);
            $this->assertEquals('0.00', (string) SellerProfile::where('user_id', $seller->id)->first()->escrow_held_balance);
            $this->assertEquals(5, $product->fresh()->available_quantity);

            $this->assertEquals(1, EscrowTransaction::where('order_id', $order->id)->where('transaction_type', 'FULL_REFUND')->count());
            $this->assertEquals(1, Notification::where('user_id', $buyer->id)->where('type', 'ORDER_CANCEL_APPROVED')->count());
            $this->assertEquals(0, Notification::where('user_id', $buyer->id)->where('type', 'ORDER_CANCEL_REJECTED')->count());
        } finally {
            if ($procA && is_resource($procA)) {
                proc_terminate($procA);
                proc_close($procA);
            }
            if ($procB && is_resource($procB)) {
                proc_terminate($procB);
                proc_close($procB);
            }
            foreach ([$workerAScript, $workerBScript, $workerASyncFile, $workerAReleaseFile, $workerBReadyFile] as $f) {
                if ($f && file_exists($f)) {
                    @unlink($f);
                }
            }
        }
    }
}
