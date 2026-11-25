<?php

namespace Tests\Feature\Api\V1;

use App\Enums\AuctionStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Jobs\CloseExpiredAuctionsJob;
use App\Models\Auction;
use App\Models\AuctionSession;
use App\Models\Category;
use App\Models\EscrowTransaction;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Product;
use App\Models\Review;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\UserAddress;
use App\Models\UserProfile;
use App\Models\WalletTransaction;
use App\Services\Auction\AuctionLifecycleService;
use App\Services\Governance\ProductModerationService;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class DemoV1HappyPathIntegrationTest extends TestCase
{
    protected function createIsolatedUser(string $prefix, UserRole $role = UserRole::REGISTERED_USER): User
    {
        $unique = $prefix . '_' . bin2hex(random_bytes(5));
        $user = User::create([
            'display_name' => 'Demo ' . $unique,
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

        $cart = DB::table('carts')->where('user_id', $userId)->first();
        if ($cart) {
            DB::table('cart_items')->where('cart_id', $cart->id)->delete();
            DB::table('carts')->where('id', $cart->id)->delete();
        }

        DB::table('user_addresses')->where('user_id', $userId)->delete();
        DB::table('seller_profiles')->where('user_id', $userId)->delete();
        DB::table('user_profiles')->where('user_id', $userId)->delete();
        DB::table('users')->where('id', $userId)->delete();
    }

    protected function cleanUpOrder(int $orderId): void
    {
        DB::table('reviews')->where('order_id', $orderId)->delete();
        DB::table('wallet_transactions')->where('order_id', $orderId)->delete();
        DB::table('escrow_transactions')->where('order_id', $orderId)->delete();
        DB::table('disputes')->where('order_id', $orderId)->delete();
        DB::table('shipments')->where('order_id', $orderId)->delete();
        DB::table('payments')->where('order_id', $orderId)->delete();
        DB::table('order_items')->where('order_id', $orderId)->delete();
        DB::table('orders')->where('id', $orderId)->delete();
    }

    /**
     * Demo V1: Complete 12-step happy path transaction from Auction Creation to Verified Review.
     */
    public function test_demo_v1_complete_twelve_step_happy_path_transaction(): void
    {
        $seller = null;
        $buyer = null;
        $admin = null;
        $product = null;
        $auction = null;
        $order = null;

        try {
            // Setup isolated actors
            $seller = $this->createIsolatedUser('v1_seller');
            $buyer = $this->createIsolatedUser('v1_buyer');
            $admin = $this->createIsolatedUser('v1_admin', UserRole::ADMIN);
            $category = Category::firstOrFail();
            $session = AuctionSession::firstOrFail();

            // Set up default buyer address for order generation snapshot
            UserAddress::create([
                'user_id' => $buyer->id,
                'recipient_name' => 'Người Mua Demo',
                'recipient_phone' => '0912345678',
                'province_city' => 'Thành phố Hồ Chí Minh',
                'district_ward' => 'Quận 1, Bến Nghé',
                'street_address' => '123 Đường Đồng Khởi',
                'is_default' => true,
            ]);

            // =========================================================================
            // STEP 1: Seller creates an auction product
            // =========================================================================
            $imageFile = UploadedFile::fake()->image('vintage_camera.jpg', 600, 600);
            $createRes = $this->actingAs($seller)->postJson('/api/v1/seller/products', [
                'category_id' => $category->id,
                'title' => 'Máy Ảnh Film Olympus OM-1 Vintage Hoạt Động Hoàn Hảo',
                'description' => 'Máy ảnh cơ khí sưu tầm thập niên 1970, cơ tốc chuẩn xác, kèm lens 50mm f/1.8.',
                'condition' => 'LIKE_NEW',
                'defect_info' => 'Không mốc rễ xước kính, thân máy đẹp đanh.',
                'listing_type' => 'AUCTION',
                'price' => 1500000,
                'total_quantity' => 1,
                'submit_for_review' => true,
                'images' => [$imageFile],
            ]);
            $createRes->assertStatus(201);
            $productId = $createRes->json('data.id');
            $this->assertNotNull($productId);

            $product = Product::findOrFail($productId);
            $this->assertEquals(ProductStatus::PENDING_REVIEW, $product->status);
            $this->assertEquals('AUCTION', $product->listing_type);

            // =========================================================================
            // STEP 2: Admin approves the product
            // =========================================================================
            app(ProductModerationService::class)->approveProduct($admin, $product, 'MODERATOR_REVIEWED', 'Đạt chuẩn kiểm duyệt đồ cổ Vintage.');
            $product->refresh();
            $this->assertEquals(ProductStatus::APPROVED, $product->status);

            // Create SCHEDULED Auction linked to the approved product
            $auction = Auction::create([
                'auction_code' => 'AUC-DEMO-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $session->id,
                'starting_price' => 1500000.00,
                'min_bid_increment' => 50000.00,
                'current_highest_bid' => 0.00,
                'bid_count' => 0,
                'status' => AuctionStatus::SCHEDULED,
                'auction_starts_at' => now()->subMinute(),
                'auction_ends_at' => now()->addMinutes(10),
            ]);

            // Transition auction to LIVE via domain service
            app(AuctionLifecycleService::class)->openDueScheduledAuctions();
            $auction->refresh();
            $this->assertEquals(AuctionStatus::LIVE, $auction->status);

            // =========================================================================
            // STEP 3: Buyer views the approved product & active auction
            // =========================================================================
            $viewRes = $this->actingAs($buyer)->getJson("/api/v1/products/{$product->id}");
            $viewRes->assertStatus(200);
            $productData = $viewRes->json('data.product.data') ?? $viewRes->json('data.product');
            $this->assertEquals($product->id, $productData['id']);
            $this->assertEquals('APPROVED', $productData['status']);

            $auctionViewRes = $this->actingAs($buyer)->getJson("/api/v1/auctions/{$auction->id}");
            $auctionViewRes->assertStatus(200);
            $auctionData = $auctionViewRes->json('data.auction.data') ?? $auctionViewRes->json('data.auction');
            $this->assertEquals($auction->id, $auctionData['id']);
            $this->assertEquals('LIVE', $auctionData['status']);

            // =========================================================================
            // STEP 4: Buyer places a valid bid
            // =========================================================================
            $bidAmount = 1550000.00;
            $bidRes = $this->actingAs($buyer)->postJson("/api/v1/auctions/{$auction->id}/bids", [
                'bid_amount' => $bidAmount,
            ]);
            $bidRes->assertStatus(200);

            $auction->refresh();
            $this->assertEquals(1, $auction->bid_count);
            $this->assertEquals($bidAmount, (float) $auction->current_highest_bid);
            $this->assertEquals($buyer->id, $auction->leading_bidder_id);

            // =========================================================================
            // STEP 5: Auction reaches its valid end time
            // =========================================================================
            $auction->update([
                'auction_starts_at' => now()->subHours(1),
                'auction_ends_at' => now()->subMinutes(1),
            ]);

            // =========================================================================
            // STEP 6: Scheduler finalizes auction and creates winner Order
            // =========================================================================
            $closeResult = app(AuctionLifecycleService::class)->closeExpiredLiveAuctions();
            $this->assertGreaterThanOrEqual(1, $closeResult['completed_count']);
            $this->assertContains($auction->id, $closeResult['completed_auction_ids']);

            $auction->refresh();
            $this->assertEquals(AuctionStatus::COMPLETED, $auction->status);
            $this->assertEquals($buyer->id, $auction->winner_id);
            $this->assertNotNull($auction->closed_at);

            $product->refresh();
            $this->assertEquals(ProductStatus::SOLD, $product->status);
            $this->assertEquals(0, $product->available_quantity);

            $order = Order::where('auction_id', $auction->id)->firstOrFail();
            $this->assertEquals($buyer->id, $order->buyer_id);
            $this->assertEquals($seller->id, $order->seller_id);
            $this->assertEquals('AUCTION', $order->order_source);
            $this->assertEquals(OrderStatus::PENDING_PAYMENT, $order->order_status);
            $this->assertEquals(PaymentStatus::UNPAID, $order->payment_status);
            $this->assertEquals(EscrowStatus::NONE, $order->escrow_status);
            $this->assertEquals($bidAmount, (float) $order->item_subtotal);

            // Buyer Protection Fee: 1,550,000 * 0.06 + 7,000 = 93,000 + 7,000 = 100,000 (DEC-04)
            $expectedFee = 100000.00;
            $this->assertEquals($expectedFee, (float) $order->buyer_protection_fee);
            $this->assertEquals(1650000.00, (float) $order->total_amount);
            $this->assertEquals($bidAmount, (float) $order->seller_net_amount);

            // =========================================================================
            // STEP 7: Buyer completes payment through mock QR flow
            // =========================================================================
            $payment = Payment::where('order_id', $order->id)->firstOrFail();
            $this->assertEquals(PaymentStatus::PENDING, $payment->status);

            $payRes = $this->actingAs($buyer)->postJson("/api/v1/payments/{$payment->id}/simulate-success");
            $payRes->assertStatus(200);

            $order->refresh();
            $payment->refresh();
            $this->assertEquals(OrderStatus::PAID, $order->order_status);
            $this->assertEquals(PaymentStatus::PAID, $order->payment_status);
            $this->assertEquals(EscrowStatus::HELD, $order->escrow_status);
            $this->assertEquals(PaymentStatus::PAID, $payment->status);

            // Verify Escrow HOLD transaction
            $holdTx = EscrowTransaction::where('order_id', $order->id)
                ->where('transaction_type', 'HOLD')
                ->firstOrFail();
            $this->assertEquals(1650000.00, (float) $holdTx->gross_amount);
            $this->assertEquals($bidAmount, (float) $holdTx->item_subtotal_amount);

            // =========================================================================
            // STEP 8: Seller processes and ships the order
            // =========================================================================
            // 8a. Seller prepares
            $prepRes = $this->actingAs($seller)->postJson("/api/v1/seller/orders/{$order->id}/prepare");
            $prepRes->assertStatus(200);
            $order->refresh();
            $this->assertEquals(OrderStatus::PREPARING, $order->order_status);
            $this->assertNotNull($order->preparing_at);

            // 8b. Seller ships
            $shipRes = $this->actingAs($seller)->postJson("/api/v1/seller/orders/{$order->id}/ship", [
                'carrier_name' => 'Giao Hàng Tiết Kiệm Vintage',
                'tracking_code' => 'GHTK-DEMO-' . time(),
                'shipping_note' => 'Hàng cổ giá trị cao, đóng gói 3 lớp xốp khí.',
            ]);
            $shipRes->assertStatus(200);
            $order->refresh();
            $this->assertEquals(OrderStatus::SHIPPED, $order->order_status);
            $this->assertNotNull($order->shipped_at);

            // 8c. Seller marks delivered
            $delivRes = $this->actingAs($seller)->postJson("/api/v1/seller/orders/{$order->id}/deliver");
            $delivRes->assertStatus(200);
            $order->refresh();
            $this->assertEquals(OrderStatus::DELIVERED, $order->order_status);
            $this->assertNotNull($order->delivered_at);
            $this->assertNotNull($order->auto_complete_at);

            // =========================================================================
            // STEP 9: Buyer confirms delivery
            // =========================================================================
            // =========================================================================
            // STEP 10: Escrow is released to Seller
            // =========================================================================
            $confirmRes = $this->actingAs($buyer)->postJson("/api/v1/orders/{$order->id}/confirm-delivery");
            $confirmRes->assertStatus(200);

            $order->refresh();
            $this->assertEquals(OrderStatus::COMPLETED, $order->order_status);
            $this->assertEquals(EscrowStatus::RELEASED, $order->escrow_status);
            $this->assertNotNull($order->completed_at);

            // Verify immutable escrow RELEASE transaction
            $releaseTx = EscrowTransaction::where('order_id', $order->id)
                ->where('transaction_type', 'RELEASE')
                ->firstOrFail();
            $this->assertEquals($bidAmount, (float) $releaseTx->seller_released_amount);
            $this->assertEquals($expectedFee, (float) $releaseTx->platform_fee_retained);

            // Verify seller wallet credit ledger
            $walletTx = WalletTransaction::where('order_id', $order->id)
                ->where('entry_type', 'CREDIT')
                ->firstOrFail();
            $this->assertEquals($bidAmount, (float) $walletTx->amount);

            $sellerProfile = SellerProfile::where('user_id', $seller->id)->firstOrFail();
            $this->assertEquals($bidAmount, (float) $sellerProfile->wallet_balance);
            $this->assertEquals(0.00, (float) $sellerProfile->escrow_held_balance);
            $this->assertEquals(1, $sellerProfile->completed_orders_count);

            // =========================================================================
            // STEP 11: Buyer submits a verified 5-star review
            // =========================================================================
            $reviewRes = $this->actingAs($buyer)->postJson("/api/v1/orders/{$order->id}/reviews", [
                'rating' => 5,
                'comment' => 'Máy ảnh chuẩn vintage, lens trong vắt, đóng gói cực kỳ cẩn thận!',
            ]);
            $reviewRes->assertStatus(201);

            $review = Review::where('order_id', $order->id)->firstOrFail();
            $this->assertEquals(5, $review->rating);
            $this->assertEquals($buyer->id, $review->reviewer_id);
            $this->assertEquals($seller->id, $review->seller_id);

            $sellerProfile->refresh();
            $this->assertEquals(1, $sellerProfile->review_count);
            $this->assertEquals(5.00, (float) $sellerProfile->average_rating);

            // =========================================================================
            // STEP 12: Final consistency audit across all domain entities
            // =========================================================================
            $this->assertEquals(AuctionStatus::COMPLETED, $auction->status);
            $this->assertEquals(ProductStatus::SOLD, $product->status);
            $this->assertEquals(OrderStatus::COMPLETED, $order->order_status);
            $this->assertEquals(PaymentStatus::PAID, $order->payment_status);
            $this->assertEquals(EscrowStatus::RELEASED, $order->escrow_status);
            $this->assertEquals(PaymentStatus::PAID, $payment->status);

            // Financial balance equation: wallet_balance == item_subtotal (zero drift)
            $this->assertEquals((float) $order->item_subtotal, (float) $sellerProfile->wallet_balance);
            $this->assertEquals(0.00, (float) $sellerProfile->escrow_held_balance);

        } finally {
            if ($order) {
                $this->cleanUpOrder($order->id);
            }
            if ($auction) {
                DB::table('auction_bids')->where('auction_id', $auction->id)->delete();
                DB::table('auction_watches')->where('auction_id', $auction->id)->delete();
                $auction->delete();
            }
            if ($product) {
                DB::table('product_images')->where('product_id', $product->id)->delete();
                DB::table('product_moderation_logs')->where('product_id', $product->id)->delete();
                $product->delete();
            }
            if ($seller) {
                $this->cleanUpUser($seller->id);
            }
            if ($buyer) {
                $this->cleanUpUser($buyer->id);
            }
            if ($admin) {
                $this->cleanUpUser($admin->id);
            }
        }
    }
}
