<?php

namespace Tests\Feature\Admin;

use App\Enums\AuctionStatus;
use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductCondition;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Models\Auction;
use App\Models\AuctionBid;
use App\Models\AuctionSession;
use App\Models\AuditLog;
use App\Models\Category;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\Shipment;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use LogicException;
use Tests\TestCase;

class P803_AuctionsOrdersAndPaymentsTest extends TestCase
{
    use DatabaseTransactions;

    protected User $admin;
    protected User $moderator;
    protected User $support;
    protected User $buyer;
    protected User $seller;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $this->moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();
        $this->support = User::where('email', 'support@izithrift.local')->firstOrFail();
        $this->buyer = User::where('email', 'buyer.active@izithrift.local')->first() ?? User::where('role', UserRole::REGISTERED_USER)->firstOrFail();
        $this->seller = User::where('email', 'seller.active@izithrift.local')->first() ?? User::where('role', UserRole::REGISTERED_USER)->where('id', '!=', $this->buyer->id)->firstOrFail();
    }

    /**
     * Helper to create an auction product.
     */
    protected function createAuctionProduct(array $attributes = []): Product
    {
        $category = Category::whereNotNull('parent_id')->first() ?? Category::firstOrFail();

        return Product::create(array_merge([
            'product_code' => 'PRD-AUC-' . uniqid(),
            'seller_id' => $this->seller->id,
            'category_id' => $category->id,
            'title' => 'Vintage Archive Cotton Jacket ' . uniqid(),
            'slug' => 'vintage-archive-cotton-jacket-' . uniqid(),
            'description' => 'Rare Japanese Vintage Cotton Jacket from 1980s.',
            'condition' => ProductCondition::GOOD,
            'defect_info' => 'Vết sờn nhẹ ở tay áo bên trái.',
            'listing_type' => 'AUCTION',
            'price' => 200000.00,
            'total_quantity' => 1,
            'available_quantity' => 1,
            'status' => ProductStatus::APPROVED,
        ], $attributes));
    }

    /**
     * Helper to create an auction.
     */
    protected function createAuction(array $attributes = []): Auction
    {
        $product = $this->createAuctionProduct();
        $session = AuctionSession::first() ?? AuctionSession::create([
            'title' => 'Vintage Weekend Session ' . uniqid(),
            'status' => 'ACTIVE',
            'starts_at' => now()->subHours(1),
            'ends_at' => now()->addHours(3),
        ]);

        return Auction::create(array_merge([
            'auction_code' => 'AUC-TEST-' . strtoupper(uniqid()),
            'product_id' => $product->id,
            'seller_id' => $this->seller->id,
            'session_id' => $session->id,
            'starting_price' => 200000.00,
            'min_bid_increment' => 20000.00,
            'reserve_price' => 300000.00,
            'current_highest_bid' => 0.00,
            'bid_count' => 0,
            'watch_count' => 5,
            'auction_starts_at' => now()->subMinutes(30),
            'auction_ends_at' => now()->addMinutes(30),
            'extended_count' => 0,
            'status' => AuctionStatus::LIVE,
        ], $attributes));
    }

    /**
     * Helper to create an order.
     */
    protected function createOrder(array $attributes = []): Order
    {
        $subtotal = 500000.00;
        $protectionFee = round(($subtotal * 0.06) + 7000.00, 2); // 37,000 VND (DEC-04)
        $total = $subtotal + $protectionFee;

        return Order::create(array_merge([
            'order_code' => 'ORD-TEST-' . strtoupper(uniqid()),
            'buyer_id' => $this->buyer->id,
            'seller_id' => $this->seller->id,
            'order_source' => 'FIXED_PRICE',
            'item_subtotal' => $subtotal,
            'shipping_fee' => 0.00,
            'protection_fee_rate_applied' => 0.0600,
            'protection_fixed_fee_applied' => 7000.00,
            'buyer_protection_fee' => $protectionFee,
            'total_amount' => $total,
            'seller_net_amount' => $subtotal,
            'shipping_address_snapshot' => [
                'recipient_name' => 'Nguyễn Văn Test',
                'phone_number' => '0901234567',
                'street_address' => '123 Đường Cổ Điển',
                'ward' => 'Phường Bến Nghé',
                'district' => 'Quận 1',
                'city_province' => 'TP Hồ Chí Minh',
            ],
            'order_status' => OrderStatus::PAID,
            'payment_status' => PaymentStatus::PAID,
            'escrow_status' => EscrowStatus::HELD,
            'dispute_status' => DisputeStatus::NONE,
            'cancellation_requested' => false,
            'payment_expires_at' => now()->addMinutes(30),
            'paid_at' => now(),
        ], $attributes));
    }

    /**
     * AC-P803-01: Admin & Moderator can view auctions list with stats and filters.
     */
    public function test_admin_and_moderator_can_view_auctions_list_and_filters(): void
    {
        $auction = $this->createAuction(['status' => AuctionStatus::LIVE]);

        // Moderator can view
        $modResponse = $this->actingAs($this->moderator, 'web')->get('/admin/auctions');
        $modResponse->assertStatus(200);
        $modResponse->assertSee('Quản lý và Giám sát Đấu giá');
        $modResponse->assertSee($auction->auction_code);
        $modResponse->assertSee('Đang diễn ra (Live)');

        // Tab filter: live
        $liveResponse = $this->actingAs($this->admin, 'web')->get('/admin/auctions?tab=live');
        $liveResponse->assertStatus(200);
        $liveResponse->assertSee($auction->auction_code);

        // Status filter
        $filterResponse = $this->actingAs($this->admin, 'web')->get('/admin/auctions?status=LIVE');
        $filterResponse->assertStatus(200);
        $filterResponse->assertSee($auction->auction_code);
    }

    /**
     * AC-P803-01: Auction Ticket-Stub Motif Inspector displays pricing, Anti-Sniping and Bid Trail.
     */
    public function test_auction_ticket_stub_monitor_displays_pricing_anti_sniping_and_bid_trail(): void
    {
        $auction = $this->createAuction([
            'starting_price' => 200000.00,
            'min_bid_increment' => 20000.00,
            'reserve_price' => 350000.00,
            'current_highest_bid' => 360000.00,
            'leading_bidder_id' => $this->buyer->id,
            'bid_count' => 2,
            'extended_count' => 2,
            'last_extended_at' => now()->subMinutes(1),
            'status' => AuctionStatus::LIVE,
        ]);

        // Create 2 immutable bids
        $bid1 = AuctionBid::create([
            'auction_id' => $auction->id,
            'bidder_id' => $this->buyer->id,
            'bid_amount' => 250000.00,
            'previous_highest_bid' => 200000.00,
            'triggered_anti_sniping' => false,
        ]);

        $bid2 = AuctionBid::create([
            'auction_id' => $auction->id,
            'bidder_id' => $this->buyer->id,
            'bid_amount' => 360000.00,
            'previous_highest_bid' => 250000.00,
            'triggered_anti_sniping' => true,
        ]);

        $response = $this->actingAs($this->moderator, 'web')->get("/admin/auctions/{$auction->id}");

        $response->assertStatus(200);
        $response->assertSee('IZITHRIFT OFFICIAL AUCTION VOUCHER');
        $response->assertSee('LOT #' . $auction->auction_code);
        $response->assertSee('200,000 đ'); // Starting price
        $response->assertSee('+20,000 đ'); // Min increment
        $response->assertSee('350,000 đ'); // Reserve price
        $response->assertSee('360,000 đ'); // Current highest bid
        $response->assertSee('Đã đạt sàn'); // Reserve met
        $response->assertSee('Cơ chế Chống Bắn Tỉa (BR-AU-04)');
        $response->assertSee('Đã kích hoạt x2'); // Anti-sniping count
        $response->assertSee('2 lần (+4 phút)');
        $response->assertSee('Nhật ký Đặt giá Bất biến (Immutable Bid Trail)');
        $response->assertSee('Có (+2 phút)'); // Anti-sniping triggered for bid2
    }

    /**
     * AC-P803-01: Displays WINNER_DEFAULTED and 30-minute winner payment deadline rule.
     */
    public function test_winner_defaulted_auction_displays_30min_payment_rule(): void
    {
        $auction = $this->createAuction([
            'status' => AuctionStatus::WINNER_DEFAULTED,
            'winner_id' => $this->buyer->id,
            'current_highest_bid' => 400000.00,
        ]);

        $response = $this->actingAs($this->admin, 'web')->get("/admin/auctions/{$auction->id}");

        $response->assertStatus(200);
        $response->assertSee('WINNER_DEFAULTED');
        $response->assertSee('Hạn Thanh toán Người thắng (BR-AU-07 / DEC-02)');
        $response->assertSee('Người thắng đã quá hạn thanh toán 30 phút');
    }

    /**
     * AC-P803-01 & AC-P803-05: Administrative Intervention - Moderator/Admin can cancel auction.
     */
    public function test_admin_and_moderator_can_cancel_auction_and_restore_product(): void
    {
        $auction = $this->createAuction(['status' => AuctionStatus::LIVE]);
        $productId = $auction->product_id;

        // Moderator cancels auction with valid reason
        $response = $this->actingAs($this->moderator, 'web')->post("/admin/auctions/{$auction->id}/cancel", [
            'reason' => 'Nghi vấn sản phẩm có dấu hiệu vi phạm bản quyền thương hiệu theo báo cáo.',
        ]);

        $response->assertRedirect("/admin/auctions/{$auction->id}");
        $response->assertSessionHas('success');

        // Verify Auction Status is CANCELLED in DB
        $freshAuction = $auction->fresh();
        $this->assertEquals(AuctionStatus::CANCELLED, $freshAuction->status);
        $this->assertNotNull($freshAuction->closed_at);
        $this->assertEquals('Nghi vấn sản phẩm có dấu hiệu vi phạm bản quyền thương hiệu theo báo cáo.', $freshAuction->cancel_reason);

        // Verify Product Status restored to APPROVED
        $freshProduct = Product::findOrFail($productId);
        $this->assertEquals(ProductStatus::APPROVED, $freshProduct->status);
        $this->assertEquals(1, $freshProduct->available_quantity);

        // Verify Audit Log recorded
        $this->assertDatabaseHas('audit_logs', [
            'actor_id' => $this->moderator->id,
            'action' => 'AUCTION_CANCELLED',
            'target_type' => 'auctions',
            'target_id' => $auction->id,
        ]);
    }

    /**
     * AC-P803-02: Orders list displays 4 independent state machines.
     */
    public function test_orders_list_displays_4_independent_state_machines(): void
    {
        $order = $this->createOrder([
            'order_status' => OrderStatus::PAID,
            'payment_status' => PaymentStatus::PAID,
            'escrow_status' => EscrowStatus::HELD,
            'dispute_status' => DisputeStatus::NONE,
        ]);

        $response = $this->actingAs($this->support, 'web')->get('/admin/orders');

        $response->assertStatus(200);
        $response->assertSee('Quản lý Đơn hàng và Escrow');
        $response->assertSee($order->order_code);
        $response->assertSee('1. Trạng thái Đơn');
        $response->assertSee('2. Trạng thái Thanh toán');
        $response->assertSee('3. Trạng thái Escrow');
        $response->assertSee('4. Trạng thái Khiếu nại');
        $response->assertSee('HELD');
    }

    /**
     * AC-P803-02 & AC-P803-03: Order 360° Inspector displays DEC-04 formula, items snapshot, and shipment.
     */
    public function test_order_360_inspector_displays_dec04_breakdown_and_immutable_items(): void
    {
        $order = $this->createOrder([
            'item_subtotal' => 500000.00,
            'shipping_fee' => 0.00,
            'buyer_protection_fee' => 37000.00, // 500,000 * 6% + 7,000
            'total_amount' => 537000.00,
            'seller_net_amount' => 500000.00, // 100% item_subtotal
        ]);

        $product = $this->createAuctionProduct();

        // Create immutable OrderItem
        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'product_code_snapshot' => 'PRD-SNAP-123',
            'product_title_snapshot' => 'Snapshot Vintage Leather Boots',
            'condition_snapshot' => 'LIKE_NEW',
            'defect_info_snapshot' => 'Không có lỗi, đế còn nguyên gai.',
            'primary_image_snapshot' => 'https://images.unsplash.com/photo-1549298916-b41d501d3772',
            'unit_price_snapshot' => 500000.00,
            'quantity' => 1,
            'line_total' => 500000.00,
        ]);

        // Create Shipment
        Shipment::create([
            'order_id' => $order->id,
            'carrier_name' => 'Giao Hàng Tiết Kiệm (GHTK)',
            'tracking_code' => 'GHTK-RETRO-998877',
            'shipping_note' => 'Hàng vintage dễ gãy, vận chuyển cẩn thận.',
            'status' => 'SHIPPED',
            'shipped_at' => now(),
            'updated_by' => $this->seller->id,
        ]);

        $response = $this->actingAs($this->support, 'web')->get("/admin/orders/{$order->id}");

        $response->assertStatus(200);
        $response->assertSee('Soi 360° Đơn hàng');
        $response->assertSee($order->order_code);
        $response->assertSee('Hệ thống 4 Máy Trạng thái Độc lập');

        // Immutable Item Snapshot verification
        $response->assertSee('Snapshot Vintage Leather Boots');
        $response->assertSee('PRD-SNAP-123');
        $response->assertSee('LIKE_NEW');
        $response->assertSee('Không có lỗi, đế còn nguyên gai.');

        // DEC-04 Financial Breakdown verification
        $response->assertSee('Minh bạch Tài chính và Biểu phí DEC-04');
        $response->assertSee('500,000 đ'); // item_subtotal
        $response->assertSee('37,000 đ'); // buyer_protection_fee
        $response->assertSee('537,000 đ'); // total_amount
        $response->assertSee('4. Thực nhận Người bán (Seller Net Payout):');
        $response->assertSee('100% Tiền hàng (0% phí chiết khấu người bán theo chuẩn DEC-04)');

        // Shipment tracking verification
        $response->assertSee('Giao Hàng Tiết Kiệm (GHTK)');
        $response->assertSee('GHTK-RETRO-998877');
        $response->assertSee('Hàng vintage dễ gãy, vận chuyển cẩn thận.');
    }

    /**
     * AC-P803-04: Payment Management displays QR payment transactions linked to orders.
     */
    public function test_payment_management_displays_qr_sessions(): void
    {
        $order = $this->createOrder();

        $payment = Payment::create([
            'payment_reference' => 'PAY-QR-TEST-' . strtoupper(uniqid()),
            'order_id' => $order->id,
            'payer_id' => $this->buyer->id,
            'amount' => 537000.00,
            'qr_payload' => 'IZITHRIFT ' . $order->order_code,
            'status' => PaymentStatus::PAID,
            'expires_at' => now()->addMinutes(15),
            'paid_at' => now(),
        ]);

        $response = $this->actingAs($this->admin, 'web')->get('/admin/payments');

        $response->assertStatus(200);
        $response->assertSee('Quản lý Giao dịch Thanh toán (QR Sessions)');
        $response->assertSee($payment->payment_reference);
        $response->assertSee($order->order_code);
        $response->assertSee('537,000 đ');
        $response->assertSee('PAID');
    }

    /**
     * AC-P803-05: RBAC Matrix and Default Deny across all P8-03 screens.
     */
    public function test_rbac_matrix_and_default_deny_enforced_across_screens(): void
    {
        $auction = $this->createAuction();
        $order = $this->createOrder();

        // 1. Moderator can access auctions, but is strictly DENIED from orders and payments
        $this->actingAs($this->moderator, 'web')->get('/admin/auctions')->assertStatus(200);
        $this->actingAs($this->moderator, 'web')->get("/admin/auctions/{$auction->id}")->assertStatus(200);
        $this->actingAs($this->moderator, 'web')->get('/admin/orders')->assertStatus(403);
        $this->actingAs($this->moderator, 'web')->get("/admin/orders/{$order->id}")->assertStatus(403);
        $this->actingAs($this->moderator, 'web')->get('/admin/payments')->assertStatus(403);

        // 2. Support can access orders, but is strictly DENIED from auctions and payments
        $this->actingAs($this->support, 'web')->get('/admin/orders')->assertStatus(200);
        $this->actingAs($this->support, 'web')->get("/admin/orders/{$order->id}")->assertStatus(200);
        $this->actingAs($this->support, 'web')->get('/admin/auctions')->assertStatus(403);
        $this->actingAs($this->support, 'web')->get("/admin/auctions/{$auction->id}")->assertStatus(403);
        $this->actingAs($this->support, 'web')->get('/admin/payments')->assertStatus(403);

        // 3. Regular Registered User is strictly DENIED from all admin routes
        $this->actingAs($this->buyer, 'web')->get('/admin/auctions')->assertStatus(403);
        $this->actingAs($this->buyer, 'web')->get('/admin/orders')->assertStatus(403);
        $this->actingAs($this->buyer, 'web')->get('/admin/payments')->assertStatus(403);

        // 4. Admin has full access to all
        $this->actingAs($this->admin, 'web')->get('/admin/auctions')->assertStatus(200);
        $this->actingAs($this->admin, 'web')->get("/admin/auctions/{$auction->id}")->assertStatus(200);
        $this->actingAs($this->admin, 'web')->get('/admin/orders')->assertStatus(200);
        $this->actingAs($this->admin, 'web')->get("/admin/orders/{$order->id}")->assertStatus(200);
        $this->actingAs($this->admin, 'web')->get('/admin/payments')->assertStatus(200);
    }

    /**
     * AC-P803-05: Immutable ledger protection prevents updating or deleting AuctionBid and OrderItem.
     */
    public function test_immutable_ledger_protection_on_bids_and_order_items(): void
    {
        $auction = $this->createAuction();
        $bid = AuctionBid::create([
            'auction_id' => $auction->id,
            'bidder_id' => $this->buyer->id,
            'bid_amount' => 220000.00,
            'previous_highest_bid' => 200000.00,
            'triggered_anti_sniping' => false,
        ]);

        // Attempting to update bid must throw LogicException
        $updateBidFailed = false;
        try {
            $bid->update(['bid_amount' => 999999.00]);
        } catch (LogicException $e) {
            $updateBidFailed = true;
            $this->assertStringContainsString('Immutable ledger', $e->getMessage());
        }
        $this->assertTrue($updateBidFailed, 'AuctionBid must not be updatable.');

        // Attempting to delete bid must throw LogicException
        $deleteBidFailed = false;
        try {
            $bid->delete();
        } catch (LogicException $e) {
            $deleteBidFailed = true;
            $this->assertStringContainsString('Immutable ledger', $e->getMessage());
        }
        $this->assertTrue($deleteBidFailed, 'AuctionBid must not be deletable.');

        // Create Order and OrderItem
        $order = $this->createOrder();
        $product = $this->createAuctionProduct();
        $orderItem = OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'product_code_snapshot' => 'PRD-IMMUTABLE-1',
            'product_title_snapshot' => 'Immutable Vintage Denim',
            'condition_snapshot' => 'GOOD',
            'defect_info_snapshot' => 'Không có lỗi ghi nhận.',
            'primary_image_snapshot' => 'https://images.unsplash.com/photo-1549298916-b41d501d3772',
            'unit_price_snapshot' => 500000.00,
            'quantity' => 1,
            'line_total' => 500000.00,
        ]);

        // Attempting to update order item must throw LogicException
        $updateItemFailed = false;
        try {
            $orderItem->update(['unit_price_snapshot' => 1.00]);
        } catch (LogicException $e) {
            $updateItemFailed = true;
            $this->assertStringContainsString('Immutable ledger', $e->getMessage());
        }
        $this->assertTrue($updateItemFailed, 'OrderItem must not be updatable.');

        // Attempting to delete order item must throw LogicException
        $deleteItemFailed = false;
        try {
            $orderItem->delete();
        } catch (LogicException $e) {
            $deleteItemFailed = true;
            $this->assertStringContainsString('Immutable ledger', $e->getMessage());
        }
        $this->assertTrue($deleteItemFailed, 'OrderItem must not be deletable.');
    }
}
