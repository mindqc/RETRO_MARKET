<?php

namespace Tests\Feature\Api\V1;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Cart;
use App\Models\CartItem;
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
use App\Services\Governance\PlatformConfigService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class CartOrderAndPaymentTest extends TestCase
{
    /**
     * 1. Test cart groups items by seller and blocks adding own product with 403 SELF_TRANSACTION_FORBIDDEN (M-CR-01 / BR-AC-02 / BR-OR-01).
     */
    public function test_cart_groups_items_by_seller_and_blocks_adding_own_product_with_403_self_transaction(): void
    {
        $buyer = null;
        $sellerProduct = null;
        $buyerOwnProduct = null;

        try {
            $buyer = User::create([
                'display_name' => 'Isolated Cart Buyer',
                'email' => 'cart.isolated.buyer.' . time() . '@izithrift.test',
                'password_hash' => Hash::make('Retro@2026'),
                'role' => UserRole::REGISTERED_USER,
                'status' => UserStatus::ACTIVE,
            ]);

            $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
            $category = Category::firstOrFail();

            $sellerProduct = Product::create([
                'product_code' => 'PRD-CART-1-' . time(),
                'seller_id' => $seller->id,
                'category_id' => $category->id,
                'title' => 'Áo Len Cổ Điển Cho Test Giỏ Hàng',
                'slug' => 'ao-len-co-dien-cart-1-' . time(),
                'description' => 'Mô tả chi tiết áo len',
                'condition' => 'LIKE_NEW',
                'defect_info' => 'Không lỗi',
                'listing_type' => 'FIXED_PRICE',
                'price' => 200000,
                'total_quantity' => 5,
                'available_quantity' => 5,
                'status' => 'APPROVED',
            ]);

            $buyerOwnProduct = Product::create([
                'product_code' => 'PRD-CART-2-' . time(),
                'seller_id' => $buyer->id,
                'category_id' => $category->id,
                'title' => 'Sản phẩm của chính người mua',
                'slug' => 'san-pham-chinh-nguoi-mua-' . time(),
                'description' => 'Mô tả sản phẩm tự bán',
                'condition' => 'GOOD',
                'defect_info' => 'Không lỗi',
                'listing_type' => 'FIXED_PRICE',
                'price' => 150000,
                'total_quantity' => 2,
                'available_quantity' => 2,
                'status' => 'APPROVED',
            ]);

            $token = $buyer->createToken('cart_test')->plainTextToken;

            // 1. Buyer successfully adds seller's product to cart
            $addResponse = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson('/api/v1/cart/items', [
                    'product_id' => $sellerProduct->id,
                    'quantity' => 2,
                ]);
            $addResponse->assertStatus(201);
            $this->assertEquals($sellerProduct->id, $addResponse->json('data.product_id'));
            $this->assertEquals(2, $addResponse->json('data.quantity'));

            // 2. GET /api/v1/cart verifies grouping by seller
            $cartResponse = $this->withHeader('Authorization', "Bearer {$token}")
                ->getJson('/api/v1/cart');
            $cartResponse->assertStatus(200);
            $cartResponse->assertJsonStructure([
                'success',
                'data' => [
                    'cart_id',
                    'total_items_count',
                    'selected_items_count',
                    'selected_subtotal',
                    'seller_groups' => [
                        '*' => [
                            'seller' => ['id', 'display_name'],
                            'items',
                            'seller_subtotal',
                        ],
                    ],
                ],
            ]);

            $this->assertCount(1, $cartResponse->json('data.seller_groups'));
            $this->assertEquals(400000.0, $cartResponse->json('data.selected_subtotal'));

            // 3. Buyer tries to add own product -> 403 SELF_TRANSACTION_FORBIDDEN (BR-AC-02)
            $selfResponse = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson('/api/v1/cart/items', [
                    'product_id' => $buyerOwnProduct->id,
                    'quantity' => 1,
                ]);
            $selfResponse->assertStatus(403);
            $this->assertEquals('SELF_TRANSACTION_FORBIDDEN', $selfResponse->json('error_code'));
        } finally {
            if ($buyerOwnProduct) {
                $buyerOwnProduct->delete();
            }
            if ($sellerProduct) {
                $sellerProduct->delete();
            }
            if ($buyer) {
                $buyer->tokens()->delete();
                $cart = Cart::where('user_id', $buyer->id)->first();
                if ($cart) {
                    CartItem::where('cart_id', $cart->id)->delete();
                    $cart->delete();
                }
                $buyer->delete();
            }
        }
    }

    /**
     * 2. Test checkout preview and place order calculates exact DEC-04 Buyer Protection Fee and freezes snapshots (M-OR-01 / DEC-04 / BR-OR-02).
     */
    public function test_checkout_preview_and_place_order_calculates_exact_dec04_buyer_protection_fee_and_freezes_snapshots(): void
    {
        $buyer = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $category = Category::firstOrFail();
        $address = UserAddress::where('user_id', $buyer->id)->firstOrFail();

        $product = null;
        $createdOrder = null;

        try {
            $product = Product::create([
                'product_code' => 'PRD-CHK-1-' . time(),
                'seller_id' => $seller->id,
                'category_id' => $category->id,
                'title' => 'Áo Dạ Vintage Cao Cấp Tuyển Chọn',
                'slug' => 'ao-da-vintage-chk-1-' . time(),
                'description' => 'Mô tả chi tiết áo dạ',
                'condition' => 'LIKE_NEW',
                'defect_info' => 'Sờn nhẹ một cúc bấm',
                'listing_type' => 'FIXED_PRICE',
                'price' => 300000.00,
                'total_quantity' => 2,
                'available_quantity' => 2,
                'status' => 'APPROVED',
            ]);

            $token = $buyer->createToken('checkout_test')->plainTextToken;

            /** @var PlatformConfigService $configService */
            $configService = app(PlatformConfigService::class);
            $expectedFeeBreakdown = $configService->calculateBuyerProtectionFee(300000.00);

            // 1. Preview Checkout breakdown
            $previewResponse = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson('/api/v1/checkout/preview', [
                    'source' => 'BUY_NOW',
                    'product_id' => $product->id,
                    'quantity' => 1,
                    'address_id' => $address->id,
                ]);

            $previewResponse->assertStatus(200);
            $previewResponse->assertJsonStructure([
                'success',
                'data' => [
                    'source',
                    'shipping_address',
                    'seller_groups',
                    'summary' => [
                        'item_subtotal',
                        'buyer_protection_fee',
                        'grand_total',
                    ],
                ],
            ]);

            $this->assertEquals((float) $expectedFeeBreakdown['buyer_protection_fee'], $previewResponse->json('data.summary.buyer_protection_fee'));
            $this->assertEquals((float) $expectedFeeBreakdown['total_amount'], $previewResponse->json('data.summary.grand_total'));

            // 2. Place Order (OF-02)
            $orderResponse = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson('/api/v1/orders', [
                    'source' => 'BUY_NOW',
                    'product_id' => $product->id,
                    'quantity' => 1,
                    'address_id' => $address->id,
                ]);

            $orderResponse->assertStatus(201);
            $orderId = $orderResponse->json('data.order.id');
            $createdOrder = Order::with('items')->findOrFail($orderId);

            // Verify DEC-04 Financial Equation on Order
            $this->assertEquals((float) $expectedFeeBreakdown['item_subtotal'], (float) $createdOrder->item_subtotal);
            $this->assertEquals(0.00, (float) $createdOrder->shipping_fee);
            $this->assertEquals((float) $expectedFeeBreakdown['buyer_protection_fee'], (float) $createdOrder->buyer_protection_fee);
            $this->assertEquals((float) $expectedFeeBreakdown['total_amount'], (float) $createdOrder->total_amount);
            $this->assertEquals((float) $expectedFeeBreakdown['seller_net_amount'], (float) $createdOrder->seller_net_amount);

            // Verify Snapshots frozen at order placement (BR-OR-02)
            $this->assertNotEmpty($createdOrder->shipping_address_snapshot);
            $this->assertEquals($address->recipient_name, $createdOrder->shipping_address_snapshot['recipient_name']);

            $firstItem = $createdOrder->items->first();
            $this->assertNotNull($firstItem);
            $this->assertEquals($product->title, $firstItem->product_title_snapshot);
            $this->assertEquals('LIKE_NEW', $firstItem->condition_snapshot);
            $this->assertEquals('Sờn nhẹ một cúc bấm', $firstItem->defect_info_snapshot);
            $this->assertEquals(300000.00, (float) $firstItem->unit_price_snapshot);
            $this->assertEquals(1, $firstItem->quantity);

            // Verify QR Payment created
            $payment = Payment::where('order_id', $createdOrder->id)->first();
            $this->assertNotNull($payment);
            $this->assertEquals('PENDING', $payment->status->value);
            $this->assertEquals((float) $expectedFeeBreakdown['total_amount'], (float) $payment->amount);
            $this->assertStringContainsString('IZITHRIFT_QR', $payment->qr_payload);
        } finally {
            $buyer->tokens()->delete();
            if ($createdOrder) {
                DB::table('order_items')->where('order_id', $createdOrder->id)->delete();
                DB::table('payments')->where('order_id', $createdOrder->id)->delete();
                DB::table('orders')->where('id', $createdOrder->id)->delete();
            }
            if ($product) {
                $product->delete();
            }
        }
    }

    /**
     * 3. Test placing order decrements stock, marks product SOLD, and blocks second purchase with 409 PRODUCT_OUT_OF_STOCK (OF-02).
     */
    public function test_placing_order_decrements_stock_marks_product_sold_and_blocks_second_purchase_with_409_out_of_stock(): void
    {
        $buyer1 = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $buyer2 = User::where('email', 'buyer.kiet@izithrift.local')->firstOrFail();
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $category = Category::firstOrFail();

        $product = null;
        $createdOrder = null;

        try {
            $product = Product::create([
                'product_code' => 'PRD-STOCK-1-' . time(),
                'seller_id' => $seller->id,
                'category_id' => $category->id,
                'title' => 'Món Đồ Độc Bản Duy Nhất Còn 1 Cái',
                'slug' => 'mon-do-doc-ban-1-' . time(),
                'description' => 'Mô tả chi tiết món đồ độc bản',
                'condition' => 'FAIR',
                'defect_info' => 'Vết ố mờ nhỏ',
                'listing_type' => 'FIXED_PRICE',
                'price' => 180000.00,
                'total_quantity' => 1,
                'available_quantity' => 1,
                'status' => 'APPROVED',
            ]);

            $token1 = $buyer1->createToken('buyer1_test')->plainTextToken;
            $token2 = $buyer2->createToken('buyer2_test')->plainTextToken;

            // Buyer 1 purchases the last remaining item
            $orderResponse = $this->withHeader('Authorization', "Bearer {$token1}")
                ->postJson('/api/v1/orders', [
                    'source' => 'BUY_NOW',
                    'product_id' => $product->id,
                    'quantity' => 1,
                ]);
            $orderResponse->assertStatus(201);
            $createdOrderId = $orderResponse->json('data.order.id');
            $createdOrder = Order::findOrFail($createdOrderId);

            // Product available_quantity becomes 0 and status transitions to SOLD
            $product->refresh();
            $this->assertEquals(0, $product->available_quantity);
            $this->assertEquals(ProductStatus::SOLD, $product->status);

            // Buyer 2 tries to purchase the same product -> 409 PRODUCT_OUT_OF_STOCK
            $failResponse = $this->withHeader('Authorization', "Bearer {$token2}")
                ->postJson('/api/v1/orders', [
                    'source' => 'BUY_NOW',
                    'product_id' => $product->id,
                    'quantity' => 1,
                ]);
            $failResponse->assertStatus(409);
            $this->assertContains($failResponse->json('error_code'), ['PRODUCT_OUT_OF_STOCK', 'INVALID_STATE_TRANSITION']);
        } finally {
            $buyer1->tokens()->delete();
            $buyer2->tokens()->delete();
            if ($createdOrder) {
                DB::table('order_items')->where('order_id', $createdOrder->id)->delete();
                DB::table('payments')->where('order_id', $createdOrder->id)->delete();
                DB::table('orders')->where('id', $createdOrder->id)->delete();
            }
            if ($product) {
                $product->delete();
            }
        }
    }

    /**
     * 4. Test simulate QR payment success is idempotent and creates single Escrow HOLD entry (M-PM-02 / BR-FN-03).
     */
    public function test_simulate_qr_payment_success_is_idempotent_and_creates_single_escrow_hold_entry(): void
    {
        $buyer = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $sellerProfile = SellerProfile::where('user_id', $seller->id)->firstOrFail();
        $initialHeldBalance = (float) $sellerProfile->escrow_held_balance;

        $order = null;
        $payment = null;

        try {
            $order = Order::create([
                'order_code' => 'ORD-TEST-PAY-' . time(),
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
                'shipping_address_snapshot' => ['recipient_name' => 'Linh', 'full_address' => 'Hà Nội'],
                'order_status' => OrderStatus::PENDING_PAYMENT,
                'payment_status' => PaymentStatus::UNPAID,
                'escrow_status' => 'NONE',
                'dispute_status' => 'NONE',
                'payment_expires_at' => now()->addMinutes(30),
            ]);

            $payment = Payment::create([
                'payment_reference' => 'PAY-TEST-' . time(),
                'order_id' => $order->id,
                'payer_id' => $buyer->id,
                'amount' => 219000.00,
                'qr_payload' => "IZITHRIFT_QR|{$order->order_code}|219000.00",
                'status' => PaymentStatus::PENDING,
                'expires_at' => now()->addMinutes(30),
            ]);

            $token = $buyer->createToken('payment_test')->plainTextToken;

            // First payment success call
            $response1 = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson("/api/v1/payments/{$payment->id}/simulate-success");

            $response1->assertStatus(200);
            $this->assertFalse($response1->json('data.idempotent_replay'));

            // Verify Order & Payment statuses in DB
            $order->refresh();
            $payment->refresh();
            $this->assertEquals(OrderStatus::PAID, $order->order_status);
            $this->assertEquals(PaymentStatus::PAID, $order->payment_status);
            $this->assertEquals('HELD', $order->escrow_status->value ?? (string) $order->escrow_status);
            $this->assertEquals(PaymentStatus::PAID, $payment->status);

            // Verify Escrow HOLD transaction recorded
            $escrowTxCount = EscrowTransaction::where('order_id', $order->id)->count();
            $this->assertEquals(1, $escrowTxCount);

            $escrowTx = EscrowTransaction::where('order_id', $order->id)->first();
            $this->assertEquals('HOLD', $escrowTx->transaction_type);
            $this->assertEquals(219000.00, (float) $escrowTx->gross_amount);
            $this->assertEquals(200000.00, (float) $escrowTx->item_subtotal_amount);

            // Verify seller escrow_held_balance incremented
            $sellerProfile->refresh();
            $this->assertEquals($initialHeldBalance + 200000.00, (float) $sellerProfile->escrow_held_balance);

            // Second payment success call (Idempotent replay test per BR-FN-03)
            $response2 = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson("/api/v1/payments/{$payment->id}/simulate-success");

            $response2->assertStatus(200);
            $this->assertTrue($response2->json('data.idempotent_replay'));

            // Ensure no duplicate escrow transaction was created
            $escrowTxCountAfter = EscrowTransaction::where('order_id', $order->id)->count();
            $this->assertEquals(1, $escrowTxCountAfter);

            // Ensure seller balance was NOT incremented twice
            $sellerProfile->refresh();
            $this->assertEquals($initialHeldBalance + 200000.00, (float) $sellerProfile->escrow_held_balance);
        } finally {
            $buyer->tokens()->delete();
            if ($order) {
                Notification::where('target_type', 'orders')->where('target_id', $order->id)->delete();
                DB::table('escrow_transactions')->where('order_id', $order->id)->delete();
                DB::table('payments')->where('order_id', $order->id)->delete();
                DB::table('orders')->where('id', $order->id)->delete();
            }
            $sellerProfile->update(['escrow_held_balance' => $initialHeldBalance]);
        }
    }

    /**
     * 5. Test simulate QR payment failure marks failed and issues new pending payment session (M-PM-02).
     */
    public function test_simulate_qr_payment_failure_marks_failed_and_issues_new_pending_payment_session(): void
    {
        $buyer = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();

        $order = null;
        $payment = null;

        try {
            $order = Order::create([
                'order_code' => 'ORD-TEST-FAIL-' . time(),
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
                'shipping_address_snapshot' => ['recipient_name' => 'Linh', 'full_address' => 'Hà Nội'],
                'order_status' => OrderStatus::PENDING_PAYMENT,
                'payment_status' => PaymentStatus::UNPAID,
                'escrow_status' => 'NONE',
                'dispute_status' => 'NONE',
                'payment_expires_at' => now()->addMinutes(30),
            ]);

            $payment = Payment::create([
                'payment_reference' => 'PAY-FAIL-' . time(),
                'order_id' => $order->id,
                'payer_id' => $buyer->id,
                'amount' => 113000.00,
                'qr_payload' => "IZITHRIFT_QR|{$order->order_code}|113000.00",
                'status' => PaymentStatus::PENDING,
                'expires_at' => now()->addMinutes(30),
            ]);

            $token = $buyer->createToken('fail_payment_test')->plainTextToken;

            $response = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson("/api/v1/payments/{$payment->id}/simulate-failure", [
                    'reason' => 'Ngân hàng từ chối do thẻ hết hạn',
                ]);

            $response->assertStatus(200);
            $this->assertEquals('FAILED', $response->json('data.failed_payment.status'));
            $this->assertEquals('Ngân hàng từ chối do thẻ hết hạn', $response->json('data.failed_payment.failure_reason'));
            $this->assertEquals('PENDING', $response->json('data.new_payment.status'));

            // Order remains PENDING_PAYMENT
            $order->refresh();
            $this->assertEquals(OrderStatus::PENDING_PAYMENT, $order->order_status);
        } finally {
            $buyer->tokens()->delete();
            if ($order) {
                DB::table('payments')->where('order_id', $order->id)->delete();
                DB::table('orders')->where('id', $order->id)->delete();
            }
        }
    }

    /**
     * 6. Test Tier 1 and Tier 2 buyer cancel at PAID triggers immediate 100% FULL_REFUND DEC-07 and restores stock (DEC-06 / DEC-07 / M-OR-04).
     */
    public function test_tier1_and_tier2_buyer_cancel_at_paid_triggers_immediate_100_percent_full_refund_dec07_and_restores_stock(): void
    {
        $buyer = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $category = Category::firstOrFail();
        $sellerProfile = SellerProfile::where('user_id', $seller->id)->firstOrFail();
        $initialHeld = (float) $sellerProfile->escrow_held_balance;

        $product = null;
        $order = null;

        try {
            $product = Product::create([
                'product_code' => 'PRD-T2-REF-' . time(),
                'seller_id' => $seller->id,
                'category_id' => $category->id,
                'title' => 'Sản phẩm thử nghiệm hủy hoàn tiền Cấp 2',
                'slug' => 'san-pham-t2-ref-' . time(),
                'description' => 'Mô tả chi tiết sản phẩm cấp 2',
                'condition' => 'LIKE_NEW',
                'defect_info' => 'Không lỗi',
                'listing_type' => 'FIXED_PRICE',
                'price' => 500000.00,
                'total_quantity' => 1,
                'available_quantity' => 0, // SOLD
                'status' => 'SOLD',
            ]);

            $order = Order::create([
                'order_code' => 'ORD-T2-REF-' . time(),
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
                'shipping_address_snapshot' => ['recipient_name' => 'Linh', 'full_address' => 'Hà Nội'],
                'order_status' => OrderStatus::PAID,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => 'HELD',
                'dispute_status' => 'NONE',
                'payment_expires_at' => now()->addMinutes(30),
                'paid_at' => now(),
            ]);

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => $product->id,
                'product_code_snapshot' => $product->product_code,
                'product_title_snapshot' => $product->title,
                'condition_snapshot' => 'LIKE_NEW',
                'defect_info_snapshot' => 'Không lỗi',
                'primary_image_snapshot' => '',
                'unit_price_snapshot' => 500000.00,
                'quantity' => 1,
                'line_total' => 500000.00,
            ]);

            Payment::create([
                'payment_reference' => 'PAY-T2-' . time(),
                'order_id' => $order->id,
                'payer_id' => $buyer->id,
                'amount' => 537000.00,
                'qr_payload' => "IZITHRIFT_QR|{$order->order_code}|537000.00",
                'status' => PaymentStatus::PAID,
                'expires_at' => now()->addMinutes(30),
                'paid_at' => now(),
            ]);

            // Give seller profile escrow held balance to simulate payment held
            $sellerProfile->update(['escrow_held_balance' => $initialHeld + 500000.00]);

            $token = $buyer->createToken('cancel_t2_test')->plainTextToken;

            $cancelResponse = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson("/api/v1/orders/{$order->id}/cancel", [
                    'reason' => 'Người bán chưa chuẩn bị hàng, tôi đổi ý muốn hủy đơn',
                ]);

            $cancelResponse->assertStatus(200);

            // Order must transition to CANCELLED and REFUNDED (DEC-07)
            $order->refresh();
            $this->assertEquals(OrderStatus::CANCELLED, $order->order_status);
            $this->assertEquals(PaymentStatus::REFUNDED, $order->payment_status);
            $this->assertEquals('REFUNDED', $order->escrow_status->value ?? (string) $order->escrow_status);

            // Escrow transaction must be FULL_REFUND with 100% of gross_amount refunded to buyer (DEC-07)
            $refundTx = EscrowTransaction::where('order_id', $order->id)
                ->where('transaction_type', 'FULL_REFUND')
                ->first();
            $this->assertNotNull($refundTx);
            $this->assertEquals(537000.00, (float) $refundTx->gross_amount);
            $this->assertEquals(537000.00, (float) $refundTx->buyer_refunded_amount);
            $this->assertEquals(0.00, (float) $refundTx->seller_released_amount);

            // Seller profile escrow_held_balance deducted back
            $sellerProfile->refresh();
            $this->assertEquals($initialHeld, (float) $sellerProfile->escrow_held_balance);

            // Stock restored
            $product->refresh();
            $this->assertEquals(1, $product->available_quantity);
            $this->assertEquals(ProductStatus::APPROVED, $product->status);
        } finally {
            $buyer->tokens()->delete();
            if ($order) {
                Notification::where('target_type', 'orders')->where('target_id', $order->id)->delete();
                DB::table('escrow_transactions')->where('order_id', $order->id)->delete();
                DB::table('payments')->where('order_id', $order->id)->delete();
                DB::table('order_items')->where('order_id', $order->id)->delete();
                DB::table('orders')->where('id', $order->id)->delete();
            }
            if ($product) {
                $product->delete();
            }
            $sellerProfile->update(['escrow_held_balance' => $initialHeld]);
        }
    }

    /**
     * 7. Test Tier 3 cancel at PREPARING supports withdraw and seller approve or reject (DEC-06 / M-SL-06).
     */
    public function test_tier3_cancel_at_preparing_supports_withdraw_and_seller_approve_or_reject_dec06(): void
    {
        $buyer = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $sellerProfile = SellerProfile::where('user_id', $seller->id)->firstOrFail();
        $initialHeld = (float) $sellerProfile->escrow_held_balance;

        $order = null;

        try {
            $order = Order::create([
                'order_code' => 'ORD-T3-' . time(),
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
                'shipping_address_snapshot' => ['recipient_name' => 'Linh', 'full_address' => 'Hà Nội'],
                'order_status' => OrderStatus::PREPARING,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => 'HELD',
                'dispute_status' => 'NONE',
                'payment_expires_at' => now()->addMinutes(30),
                'preparing_at' => now(),
            ]);

            Payment::create([
                'payment_reference' => 'PAY-T3-' . time(),
                'order_id' => $order->id,
                'payer_id' => $buyer->id,
                'amount' => 219000.00,
                'qr_payload' => "IZITHRIFT_QR|{$order->order_code}|219000.00",
                'status' => PaymentStatus::PAID,
                'expires_at' => now()->addMinutes(30),
                'paid_at' => now(),
            ]);

            $sellerProfile->update(['escrow_held_balance' => $initialHeld + 200000.00]);

            $buyerToken = $buyer->createToken('buyer_t3')->plainTextToken;
            $sellerToken = $seller->createToken('seller_t3')->plainTextToken;

            // 1. Buyer requests cancellation in PREPARING -> sets cancellation_requested = true
            $requestResponse = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->postJson("/api/v1/orders/{$order->id}/cancel", [
                    'reason' => 'Tôi muốn đổi địa chỉ giao hàng nên xin hủy',
                ]);
            $requestResponse->assertStatus(200);

            $order->refresh();
            $this->assertTrue($order->cancellation_requested);
            $this->assertEquals(OrderStatus::PREPARING, $order->order_status);

            // 2. Buyer withdraws request (UX-CHECK-02)
            $withdrawResponse = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->postJson("/api/v1/orders/{$order->id}/withdraw-cancel-request");
            $withdrawResponse->assertStatus(200);

            $order->refresh();
            $this->assertFalse($order->cancellation_requested);

            // 3. Buyer re-requests cancellation
            $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->postJson("/api/v1/orders/{$order->id}/cancel", [
                    'reason' => 'Xin người bán hủy giúp đơn này',
                ]);

            // 4. Seller approves cancellation (DEC-06 / DEC-07)
            auth()->forgetGuards();
            $sellerResponse = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->postJson("/api/v1/seller/orders/{$order->id}/respond-cancel", [
                    'decision' => 'APPROVE',
                    'note' => 'Đã xác nhận chưa gửi hàng và đồng ý hủy',
                ]);
            $sellerResponse->assertStatus(200);

            $order->refresh();
            $this->assertEquals(OrderStatus::CANCELLED, $order->order_status);
            $this->assertEquals(PaymentStatus::REFUNDED, $order->payment_status);
            $this->assertEquals('REFUNDED', $order->escrow_status->value ?? (string) $order->escrow_status);

            // Verify 100% refund recorded in Escrow ledger
            $refundTx = EscrowTransaction::where('order_id', $order->id)
                ->where('transaction_type', 'FULL_REFUND')
                ->first();
            $this->assertNotNull($refundTx);
            $this->assertEquals(219000.00, (float) $refundTx->buyer_refunded_amount);
        } finally {
            $buyer->tokens()->delete();
            $seller->tokens()->delete();
            if ($order) {
                Notification::where('target_type', 'orders')->where('target_id', $order->id)->delete();
                DB::table('escrow_transactions')->where('order_id', $order->id)->delete();
                DB::table('payments')->where('order_id', $order->id)->delete();
                DB::table('orders')->where('id', $order->id)->delete();
            }
            $sellerProfile->update(['escrow_held_balance' => $initialHeld]);
        }
    }

    /**
     * 8. Test buyer cannot cancel order once SHIPPED returns 409 INVALID_STATE_TRANSITION (BR-OR-04).
     */
    public function test_buyer_cannot_cancel_order_once_shipped_returns_409_invalid_state_transition(): void
    {
        $buyer = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();

        $order = null;

        try {
            $order = Order::create([
                'order_code' => 'ORD-SHIPPED-' . time(),
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
                'shipping_address_snapshot' => ['recipient_name' => 'Linh', 'full_address' => 'Hà Nội'],
                'order_status' => OrderStatus::SHIPPED,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => 'HELD',
                'dispute_status' => 'NONE',
                'payment_expires_at' => now()->addMinutes(30),
                'shipped_at' => now(),
            ]);

            $token = $buyer->createToken('cancel_shipped_test')->plainTextToken;

            $response = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson("/api/v1/orders/{$order->id}/cancel", [
                    'reason' => 'Đã giao nhưng tôi vẫn muốn hủy',
                ]);

            $response->assertStatus(409);
            $this->assertEquals('INVALID_STATE_TRANSITION', $response->json('error_code'));
        } finally {
            $buyer->tokens()->delete();
            if ($order) {
                DB::table('orders')->where('id', $order->id)->delete();
            }
        }
    }
}
