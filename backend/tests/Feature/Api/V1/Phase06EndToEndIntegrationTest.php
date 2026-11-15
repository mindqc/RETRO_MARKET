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
use App\Models\Category;
use App\Models\Dispute;
use App\Models\EscrowTransaction;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\Review;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\UserAddress;
use App\Models\UserProfile;
use App\Models\WalletTransaction;
use App\Services\Auction\AuctionLifecycleService;
use App\Services\Escrow\EscrowReleaseService;
use App\Services\Governance\ProductModerationService;
use App\Services\Order\OrderExpirationService;
use App\Services\Product\SellerProductService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class Phase06EndToEndIntegrationTest extends TestCase
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

    protected function cleanUpUser(int $userId): void
    {
        DB::table('audit_logs')->where('actor_id', $userId)->delete();
        DB::table('notifications')->where('user_id', $userId)->delete();
        DB::table('reports')->where('reporter_id', $userId)->delete();
        DB::table('favorites')->where('user_id', $userId)->delete();
        DB::table('seller_follows')->where('follower_id', $userId)->orWhere('seller_id', $userId)->delete();
        DB::table('reviews')->where('reviewer_id', $userId)->orWhere('seller_id', $userId)->delete();

        // Conversations & messages
        $convIds = DB::table('conversations')
            ->where('user_one_id', $userId)
            ->orWhere('user_two_id', $userId)
            ->pluck('id')
            ->toArray();

        if (!empty($convIds)) {
            DB::table('messages')->whereIn('conversation_id', $convIds)->delete();
            DB::table('conversations')->whereIn('id', $convIds)->delete();
        }

        // Cart
        $cart = DB::table('carts')->where('user_id', $userId)->first();
        if ($cart) {
            DB::table('cart_items')->where('cart_id', $cart->id)->delete();
            DB::table('carts')->where('id', $cart->id)->delete();
        }

        // Orders
        $orderIds = DB::table('orders')->where('buyer_id', $userId)->orWhere('seller_id', $userId)->pluck('id')->toArray();
        foreach ($orderIds as $ordId) {
            $this->cleanUpOrder($ordId);
        }

        // Auctions
        $auctionIds = DB::table('auctions')->where('seller_id', $userId)->orWhere('winner_id', $userId)->pluck('id')->toArray();
        foreach ($auctionIds as $aucId) {
            DB::table('auction_watches')->where('auction_id', $aucId)->delete();
            DB::table('auction_bids')->where('auction_id', $aucId)->delete();
            DB::table('auctions')->where('id', $aucId)->delete();
        }

        // Products
        $productIds = DB::table('products')->where('seller_id', $userId)->pluck('id')->toArray();
        foreach ($productIds as $prdId) {
            DB::table('product_images')->where('product_id', $prdId)->delete();
            DB::table('product_moderation_logs')->where('product_id', $prdId)->delete();
            DB::table('products')->where('id', $prdId)->delete();
        }

        DB::table('seller_profiles')->where('user_id', $userId)->delete();
        DB::table('user_addresses')->where('user_id', $userId)->delete();
        DB::table('user_profiles')->where('user_id', $userId)->delete();
        DB::table('users')->where('id', $userId)->delete();
    }

    protected function cleanUpOrder(int $orderId): void
    {
        $disputeIds = DB::table('disputes')->where('order_id', $orderId)->pluck('id')->toArray();
        foreach ($disputeIds as $dspId) {
            DB::table('dispute_evidences')->where('dispute_id', $dspId)->delete();
            DB::table('disputes')->where('id', $dspId)->delete();
        }

        DB::table('reviews')->where('order_id', $orderId)->delete();
        DB::table('wallet_transactions')->where('order_id', $orderId)->delete();
        DB::table('escrow_transactions')->where('order_id', $orderId)->delete();
        DB::table('payments')->where('order_id', $orderId)->delete();
        DB::table('shipments')->where('order_id', $orderId)->delete();
        DB::table('order_items')->where('order_id', $orderId)->delete();
        DB::table('orders')->where('id', $orderId)->delete();
    }

    protected function cleanUpAuction(?int $auctionId = null, ?int $productId = null, array $userIds = []): void
    {
        if ($auctionId) {
            $orderIds = DB::table('orders')->where('auction_id', $auctionId)->pluck('id')->toArray();
            foreach ($orderIds as $ordId) {
                $this->cleanUpOrder($ordId);
            }
            DB::table('auction_watches')->where('auction_id', $auctionId)->delete();
            DB::table('auction_bids')->where('auction_id', $auctionId)->delete();
            DB::table('auctions')->where('id', $auctionId)->delete();
        }
        if ($productId) {
            DB::table('product_images')->where('product_id', $productId)->delete();
            DB::table('product_moderation_logs')->where('product_id', $productId)->delete();
            DB::table('products')->where('id', $productId)->delete();
        }
        foreach ($userIds as $uid) {
            if ($uid) {
                $this->cleanUpUser($uid);
            }
        }
    }

    /**
     * Journey 1: Full lifecycle of fixed-price listing, moderation, cart, checkout, payment, fulfillment, escrow release, and verified review.
     */
    public function test_e2e_journey_1_fixed_price_listing_moderation_checkout_escrow_release_and_verified_review(): void
    {
        $seller = null;
        $buyer = null;
        $moderator = null;
        $product = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('j1_seller');
            $buyer = $this->createIsolatedUser('j1_buyer');
            $moderator = $this->createIsolatedUser('j1_mod', UserRole::MODERATOR);
            $category = Category::firstOrFail();

            // 1. Seller creates listing
            $prodRes = $this->actingAs($seller)->postJson('/api/v1/seller/products', [
                'title' => 'Áo Khoác Denim Vintage 90s Cổ Điển',
                'description' => 'Áo khoác denim chất lượng cao sưu tầm từ thập niên 90',
                'category_id' => $category->id,
                'listing_type' => 'FIXED_PRICE',
                'condition' => 'GOOD',
                'defect_info' => 'Sờn nhẹ cổ áo tự nhiên theo thời gian',
                'price' => 350000.00,
                'total_quantity' => 1,
                'submit_for_review' => true,
            ]);
            $prodRes->assertStatus(201);
            $productId = $prodRes->json('data.id');
            $product = Product::findOrFail($productId);
            $this->assertEquals(ProductStatus::PENDING_REVIEW, $product->status);

            // 2. Moderator rejects with reason (DEC-05)
            $rejectReason = 'Vui lòng cung cấp thêm hình chụp cận cảnh nhãn mác thương hiệu.';
            $modService = app(ProductModerationService::class);
            $rejectedProduct = $modService->rejectOrHideProduct($moderator, $product, 'REJECTED', $rejectReason);
            $this->assertEquals(ProductStatus::REJECTED, $rejectedProduct->status);
            $this->assertEquals($rejectReason, $rejectedProduct->rejection_reason);

            // 3. Seller resubmits listing
            $sellerService = app(SellerProductService::class);
            $resubmittedProduct = $sellerService->updateOrResubmitListing($seller, $rejectedProduct, ['submit_for_review' => true]);
            $this->assertEquals(ProductStatus::PENDING_REVIEW, $resubmittedProduct->status);
            $this->assertNull($resubmittedProduct->rejection_reason);

            // 4. Moderator approves product
            $approvedProduct = $modService->approveProduct($moderator, $resubmittedProduct, 'MODERATOR_REVIEWED');
            $this->assertEquals(ProductStatus::APPROVED, $approvedProduct->status);

            // 5. Buyer adds to cart
            $buyerAddress = UserAddress::create([
                'user_id' => $buyer->id,
                'recipient_name' => 'Nguyễn Văn Người Mua',
                'recipient_phone' => '0901234567',
                'province_city' => 'TP. Hồ Chí Minh',
                'district_ward' => 'Quận 1',
                'street_address' => '45 Lê Duẩn, Bến Nghé',
                'is_default' => true,
            ]);

            $cartRes = $this->actingAs($buyer)->postJson('/api/v1/cart/items', [
                'product_id' => $approvedProduct->id,
                'quantity' => 1,
            ]);
            $cartRes->assertStatus(201);

            // 6. Buyer previews checkout (DEC-04)
            $prevRes = $this->actingAs($buyer)->postJson('/api/v1/checkout/preview', [
                'source' => 'CART',
                'cart_item_ids' => [$cartRes->json('data.id')],
            ]);
            $prevRes->assertStatus(200);
            $prevRes->assertJsonPath('data.summary.item_subtotal', 350000);
            // DEC-04: 350000 * 0.06 + 7000 = 21000 + 7000 = 28000
            $prevRes->assertJsonPath('data.summary.buyer_protection_fee', 28000);
            $prevRes->assertJsonPath('data.summary.grand_total', 378000);

            // 7. Buyer places order
            $orderRes = $this->actingAs($buyer)->postJson('/api/v1/orders', [
                'source' => 'CART',
                'seller_id' => $seller->id,
                'address_id' => $buyerAddress->id,
            ]);
            $orderRes->assertStatus(201);
            $orderId = $orderRes->json('data.order.id') ?? $orderRes->json('data.orders.0.id');
            $order = Order::findOrFail($orderId);
            $this->assertEquals('PENDING_PAYMENT', $order->order_status->value);

            // 8. Buyer pays via Mock QR simulate-success
            $payment = Payment::where('order_id', $order->id)->firstOrFail();
            $payRes = $this->actingAs($buyer)->postJson("/api/v1/payments/{$payment->id}/simulate-success");
            $payRes->assertStatus(200);

            $order->refresh();
            $this->assertEquals('PAID', $order->order_status->value);
            $this->assertEquals('HELD', $order->escrow_status->value);

            // 9. Seller fulfillment pipeline: prepare -> ship -> deliver (BR-OR-05)
            $prepRes = $this->actingAs($seller)->postJson("/api/v1/seller/orders/{$order->id}/prepare");
            $prepRes->assertStatus(200);

            $shipRes = $this->actingAs($seller)->postJson("/api/v1/seller/orders/{$order->id}/ship", [
                'carrier_name' => 'Giao Hàng Nhanh',
                'tracking_code' => 'GHN-J1-' . time(),
            ]);
            $shipRes->assertStatus(200);

            $delivRes = $this->actingAs($seller)->postJson("/api/v1/seller/orders/{$order->id}/deliver");
            $delivRes->assertStatus(200);

            $order->refresh();
            $this->assertEquals('DELIVERED', $order->order_status->value);
            $this->assertNotNull($order->auto_complete_at);

            // 10. Buyer confirms delivery -> Escrow releases 100% item_subtotal (DEC-04)
            $confRes = $this->actingAs($buyer)->postJson("/api/v1/orders/{$order->id}/confirm-delivery");
            $confRes->assertStatus(200);

            $order->refresh();
            $this->assertEquals('COMPLETED', $order->order_status->value);
            $this->assertEquals('RELEASED', $order->escrow_status->value);

            $sellerProfile = SellerProfile::where('user_id', $seller->id)->first();
            $this->assertEquals(350000.00, (float) $sellerProfile->wallet_balance);
            $this->assertEquals(0.00, (float) $sellerProfile->escrow_held_balance);

            // 11. Buyer writes verified 5-star review (BR-RV-01)
            $revRes = $this->actingAs($buyer)->postJson("/api/v1/orders/{$order->id}/reviews", [
                'rating' => 5,
                'comment' => 'Áo denim chuẩn vintage, form đẹp và thơm mùi gỗ!',
            ]);
            $revRes->assertStatus(201);

            $sellerProfile->refresh();
            $this->assertEquals(1, $sellerProfile->review_count);
            $this->assertEquals(5.00, (float) $sellerProfile->average_rating);
        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            if ($product) {
                DB::table('cart_items')->where('product_id', $product->id)->delete();
                $product->delete();
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
            if ($moderator) {
                $this->cleanUpUser($moderator->id);
            }
        }
    }

    /**
     * Journey 2: Full lifecycle of scheduled auction, anti-sniping extension, winner default penalty (DEC-02), and seller relist.
     */
    public function test_e2e_journey_2_auction_bidding_anti_sniping_winner_default_and_seller_relist_lifecycle(): void
    {
        $seller = null;
        $buyer1 = null;
        $buyer2 = null;
        $product = null;
        $auction = null;
        $relistedAuction = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('j2_seller');
            $buyer1 = $this->createIsolatedUser('j2_buyer1');
            $buyer2 = $this->createIsolatedUser('j2_buyer2');
            $session = AuctionSession::firstOrFail();

            $category = Category::firstOrFail();
            $product = Product::create([
                'product_code' => 'PRD-AUC-J2-' . time(),
                'seller_id' => $seller->id,
                'category_id' => $category->id,
                'title' => 'Đồng Hồ Seiko 5 Vintage Automatic',
                'slug' => 'dong-ho-seiko-5-vintage-' . time(),
                'description' => 'Đồng hồ cơ tự động chính hãng Nhật Bản',
                'condition' => 'LIKE_NEW',
                'defect_info' => 'Không lỗi trầy xước',
                'listing_type' => 'AUCTION',
                'price' => 500000.00,
                'total_quantity' => 1,
                'available_quantity' => 1,
                'status' => ProductStatus::APPROVED,
            ]);

            // 1. Create SCHEDULED auction due for opening
            $auction = Auction::create([
                'auction_code' => 'AUC-J2-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $session->id,
                'starting_price' => 500000.00,
                'min_bid_increment' => 50000.00,
                'current_highest_bid' => 0.00,
                'bid_count' => 0,
                'status' => AuctionStatus::SCHEDULED,
                'auction_starts_at' => now()->subMinute(),
                'auction_ends_at' => now()->addMinutes(10),
            ]);

            // Open via domain service
            app(AuctionLifecycleService::class)->openDueScheduledAuctions();
            $auction->refresh();
            $this->assertEquals('LIVE', $auction->status instanceof AuctionStatus ? $auction->status->value : (string) $auction->status);

            // 2. Buyer 1 places first bid (500,000)
            $bid1Res = $this->actingAs($buyer1)->postJson("/api/v1/auctions/{$auction->id}/bids", [
                'bid_amount' => 500000.00,
            ]);
            $bid1Res->assertStatus(200);

            // 3. Buyer 2 bids near the end (Anti-Sniping window BR-AU-04)
            // Adjust ends_at to trigger anti-sniping window (e.g. 20 seconds remaining <= 30s in demo or 120s in prod)
            $auction->update(['auction_ends_at' => now()->addSeconds(20)]);
            $initialEndsAt = $auction->auction_ends_at->copy();

            $bid2Res = $this->actingAs($buyer2)->postJson("/api/v1/auctions/{$auction->id}/bids", [
                'bid_amount' => 600000.00,
            ]);
            $bid2Res->assertStatus(200);

            $auction->refresh();
            $this->assertTrue($auction->auction_ends_at->gt($initialEndsAt));
            $this->assertGreaterThan(0, $auction->extended_count);
            $this->assertEquals($buyer2->id, $auction->leading_bidder_id);

            // 4. Close auction after expiration
            $auction->update([
                'auction_starts_at' => now()->subHours(2),
                'auction_ends_at' => now()->subMinutes(5),
            ]);
            app(CloseExpiredAuctionsJob::class)->handle(app(AuctionLifecycleService::class));

            $auction->refresh();
            $this->assertEquals('COMPLETED', $auction->status instanceof AuctionStatus ? $auction->status->value : (string) $auction->status);
            $this->assertEquals($buyer2->id, $auction->winner_id);

            $order = Order::where('auction_id', $auction->id)->firstOrFail();
            $this->assertEquals(600000.00, (float) $order->item_subtotal);
            // DEC-04: 600000 * 0.06 + 7000 = 36000 + 7000 = 43000
            $this->assertEquals(43000.00, (float) $order->buyer_protection_fee);
            $this->assertEquals(643000.00, (float) $order->total_amount);

            // 5. Buyer 2 defaults on payment (BR-AU-07 / DEC-02)
            $order->update(['payment_expires_at' => now()->subMinutes(10)]);
            app(ExpireUnpaidAuctionOrdersJob::class)->handle(app(OrderExpirationService::class));

            $order->refresh();
            $this->assertEquals('CANCELLED', $order->order_status instanceof OrderStatus ? $order->order_status->value : (string) $order->order_status);

            $auction->refresh();
            $this->assertEquals('WINNER_DEFAULTED', $auction->status instanceof AuctionStatus ? $auction->status->value : (string) $auction->status);

            $product->refresh();
            $this->assertEquals('APPROVED', $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status);
            $this->assertEquals(1, $product->available_quantity);

            $b2Profile = SellerProfile::where('user_id', $buyer2->id)->first();
            $this->assertEquals(1, $b2Profile->auction_default_count);

            // 6. Seller relists product into a new auction (DEC-02 / AF-09)
            $relistRes = $this->actingAs($seller)->postJson("/api/v1/seller/products/{$product->id}/relist", [
                'starting_price' => 550000.00,
                'min_bid_increment' => 50000.00,
                'reserve_price' => 550000.00,
                'auction_starts_at' => now()->subMinute()->toIso8601String(),
                'auction_ends_at' => now()->addHours(24)->toIso8601String(),
            ]);
            $relistRes->assertStatus(201);
            $relistedAuctionId = $relistRes->json('data.id');
            $relistedAuction = Auction::findOrFail($relistedAuctionId);

            // 7. Buyer 1 bids on new auction and Seller closes early (BR-AU-05)
            $relistedBidRes = $this->actingAs($buyer1)->postJson("/api/v1/auctions/{$relistedAuction->id}/bids", [
                'bid_amount' => 550000.00,
            ]);
            $relistedBidRes->assertStatus(200);

            $closeEarlyRes = $this->actingAs($seller)->postJson("/api/v1/auctions/{$relistedAuction->id}/close-early");
            $closeEarlyRes->assertStatus(200);

            $relistedAuction->refresh();
            $this->assertEquals('COMPLETED', $relistedAuction->status instanceof AuctionStatus ? $relistedAuction->status->value : (string) $relistedAuction->status);
            $this->assertEquals($buyer1->id, $relistedAuction->winner_id);
            $this->assertTrue((bool) $relistedAuction->closed_early_by_seller);
        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            $this->cleanUpAuction($relistedAuction?->id);
            $this->cleanUpAuction($auction?->id, $product?->id, array_filter([$seller?->id, $buyer1?->id, $buyer2?->id]));
        }
    }

    /**
     * Journey 3: Dispute freeze guard, evidence submission, RBAC protection and admin full refund (DEC-03 / DEC-07 / BR-DP-02).
     */
    public function test_e2e_journey_3_dispute_freezes_auto_complete_job_and_admin_verdicts_reconcile_ledger(): void
    {
        $seller = null;
        $buyer = null;
        $support = null;
        $admin = null;
        $order = null;

        try {
            $seller = $this->createIsolatedUser('j3_seller');
            $buyer = $this->createIsolatedUser('j3_buyer');
            $support = $this->createIsolatedUser('j3_support', UserRole::SUPPORT);
            $admin = $this->createIsolatedUser('j3_admin', UserRole::ADMIN);

            // 1. Create a DELIVERED order with held escrow
            $order = Order::create([
                'order_code' => 'ORD-J3-' . time(),
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
                'dispute_status' => DisputeStatus::NONE,
                'auto_complete_at' => now()->subMinutes(10), // Expired auto-complete window
                'delivered_at' => now()->subHours(24),
                'paid_at' => now()->subHours(48),
                'payment_expires_at' => now()->subHours(48),
            ]);

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => 1,
                'product_code_snapshot' => 'PRD-J3-001',
                'product_title_snapshot' => 'Váy vintage hoa nhí',
                'unit_price_snapshot' => 400000.00,
                'quantity' => 1,
                'line_total' => 400000.00,
                'condition_snapshot' => 'LIKE_NEW',
                'defect_info_snapshot' => 'Không lỗi',
                'primary_image_snapshot' => 'https://izithrift.local/storage/sample.jpg',
            ]);

            $payment = Payment::create([
                'payment_reference' => 'PAY-J3-' . time(),
                'order_id' => $order->id,
                'payer_id' => $buyer->id,
                'amount' => 431000.00,
                'qr_payload' => 'vietqr://j3',
                'status' => PaymentStatus::PAID,
                'paid_at' => now()->subHours(48),
                'expires_at' => now()->subHours(48),
            ]);

            EscrowTransaction::create([
                'transaction_code' => 'ESC-HOLD-J3-' . time(),
                'order_id' => $order->id,
                'payment_id' => $payment->id,
                'seller_id' => $seller->id,
                'buyer_id' => $buyer->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 431000.00,
                'item_subtotal_amount' => 400000.00,
                'buyer_protection_fee_amount' => 31000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer->id,
                'note' => 'Giữ tiền ký quỹ ban đầu J3',
            ]);

            SellerProfile::where('user_id', $seller->id)->update([
                'escrow_held_balance' => 400000.00,
            ]);

            // 2. Buyer opens dispute -> Escrow frozen (DEC-03)
            $dispRes = $this->actingAs($buyer)->postJson("/api/v1/orders/{$order->id}/disputes", [
                'reason_category' => 'ITEM_DEFECTIVE_NOT_DISCLOSED',
                'description' => 'Váy bị rách đường may thân sau không đúng với mô tả lúc mua.',
            ]);
            $dispRes->assertStatus(201);
            $disputeId = $dispRes->json('data.id');

            $order->refresh();
            $this->assertEquals('OPEN', $order->dispute_status instanceof DisputeStatus ? $order->dispute_status->value : (string) $order->dispute_status);
            $this->assertNotNull($order->escrow_frozen_at);

            // 3. AutoCompleteDeliveredOrdersJob is strictly blocked (BR-DP-02)
            app(AutoCompleteDeliveredOrdersJob::class)->handle(app(EscrowReleaseService::class));

            $order->refresh();
            $this->assertEquals('DELIVERED', $order->order_status instanceof OrderStatus ? $order->order_status->value : (string) $order->order_status);
            $this->assertEquals('HELD', $order->escrow_status instanceof EscrowStatus ? $order->escrow_status->value : (string) $order->escrow_status);

            $sellerProfile = SellerProfile::where('user_id', $seller->id)->first();
            $this->assertEquals(0.00, (float) $sellerProfile->wallet_balance);
            $this->assertEquals(400000.00, (float) $sellerProfile->escrow_held_balance);

            // 4. Seller submits counter-evidence
            $eviRes = $this->actingAs($seller)->postJson("/api/v1/disputes/{$disputeId}/evidences", [
                'message_note' => 'Chúng tôi đã kiểm tra kỹ trước khi đóng gói, có video quay lúc gửi.',
            ]);
            $eviRes->assertStatus(201);

            // 5. Support staff cannot resolve dispute financial verdicts (PERM-CM-09 -> 403)
            $suppResolveRes = $this->actingAs($support)->postJson("/api/v1/admin/disputes/{$disputeId}/resolve", [
                'verdict' => 'APPROVE_BUYER_REFUND',
                'resolution_note' => 'Chuyên viên Support thử phân xử tài chính trái thẩm quyền',
            ]);
            $suppResolveRes->assertStatus(403);

            // 6. Admin resolves dispute with 100% full refund (DEC-07 / BR-FN-06)
            $admResolveRes = $this->actingAs($admin)->postJson("/api/v1/admin/disputes/{$disputeId}/resolve", [
                'verdict' => 'APPROVE_BUYER_REFUND',
                'resolution_note' => 'Chấp thuận khiếu nại, hoàn trả 100% tổng số tiền thanh toán cho người mua.',
            ]);
            $admResolveRes->assertStatus(200);

            $order->refresh();
            $this->assertEquals('CANCELLED', $order->order_status instanceof OrderStatus ? $order->order_status->value : (string) $order->order_status);
            $this->assertEquals('REFUNDED', $order->payment_status instanceof PaymentStatus ? $order->payment_status->value : (string) $order->payment_status);
            $this->assertEquals('REFUNDED', $order->escrow_status instanceof EscrowStatus ? $order->escrow_status->value : (string) $order->escrow_status);
            $this->assertEquals('RESOLVED', $order->dispute_status instanceof DisputeStatus ? $order->dispute_status->value : (string) $order->dispute_status);

            // Verify escrow transaction: FULL_REFUND
            $refundTx = EscrowTransaction::where('order_id', $order->id)
                ->where('transaction_type', 'FULL_REFUND')
                ->first();
            $this->assertNotNull($refundTx);
            $this->assertEquals(431000.00, (float) $refundTx->buyer_refunded_amount);
            $this->assertEquals(0.00, (float) $refundTx->seller_released_amount);

            // Verify seller escrow held balance deducted back to 0
            $sellerProfile->refresh();
            $this->assertEquals(0.00, (float) $sellerProfile->escrow_held_balance);
            $this->assertEquals(0.00, (float) $sellerProfile->wallet_balance);
        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
            if ($support) {
                $this->cleanUpUser($support->id);
            }
            if ($admin) {
                $this->cleanUpUser($admin->id);
            }
        }
    }

    /**
     * Journey 4: Full database and ledger reconciliation audit after all transaction flows.
     */
    public function test_e2e_journey_4_full_database_and_ledger_reconciliation_audit_after_all_flows(): void
    {
        // 1. Verify all routes under /api/v1/* exist
        $routes = collect(Route::getRoutes()->getRoutes())
            ->filter(fn ($r) => str_starts_with($r->uri(), 'api/v1'))
            ->map(fn ($r) => $r->uri())
            ->unique();

        $this->assertGreaterThanOrEqual(40, $routes->count(), 'All required REST API endpoints must be registered.');

        // 2. Mathematical equation verification on 100% orders (DEC-04)
        $orders = Order::all();
        foreach ($orders as $o) {
            $expectedTotal = round((float) $o->item_subtotal + (float) $o->shipping_fee + (float) $o->buyer_protection_fee, 2);
            $actualTotal = round((float) $o->total_amount, 2);
            $this->assertEquals($expectedTotal, $actualTotal, "Order #{$o->order_code} violates DEC-04 equation.");

            $this->assertEquals(
                round((float) $o->item_subtotal, 2),
                round((float) $o->seller_net_amount, 2),
                "Order #{$o->order_code} violates 100% seller net equation."
            );
        }

        // 3. Ledger balance verification on all Seller Profiles
        $sellerProfiles = SellerProfile::all();
        foreach ($sellerProfiles as $sp) {
            $totalCredit = (float) WalletTransaction::where('seller_id', $sp->user_id)
                ->where('entry_type', 'CREDIT')
                ->sum('amount');

            $totalDebit = (float) WalletTransaction::where('seller_id', $sp->user_id)
                ->where('entry_type', 'DEBIT')
                ->sum('amount');

            $expectedWallet = round($totalCredit - $totalDebit, 2);
            $actualWallet = round((float) $sp->wallet_balance, 2);

            $this->assertEquals(
                $expectedWallet,
                $actualWallet,
                "SellerProfile user_id={$sp->user_id} wallet balance does not match ledger sum."
            );
        }

        // 4. Escrow transaction invariant: gross_amount == released + refunded + retained
        $escrowTxs = EscrowTransaction::all();
        foreach ($escrowTxs as $tx) {
            if (in_array($tx->transaction_type, ['RELEASE', 'PARTIAL_REFUND', 'FULL_REFUND'])) {
                $sum = round(
                    (float) $tx->seller_released_amount
                    + (float) $tx->buyer_refunded_amount
                    + (float) $tx->platform_fee_retained,
                    2
                );
                $this->assertEquals(
                    round((float) $tx->gross_amount, 2),
                    $sum,
                    "EscrowTransaction {$tx->transaction_code} violates accounting invariant."
                );
            }
        }
    }
}
