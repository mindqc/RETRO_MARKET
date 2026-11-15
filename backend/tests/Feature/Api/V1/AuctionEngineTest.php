<?php

namespace Tests\Feature\Api\V1;

use App\Enums\AuctionStatus;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Auction;
use App\Models\AuctionBid;
use App\Models\AuctionSession;
use App\Models\AuctionWatch;
use App\Models\Category;
use App\Models\Notification;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuctionEngineTest extends TestCase
{
    /**
     * Create isolated user with seller profile.
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
     * Create isolated auction product.
     */
    protected function createIsolatedProduct(User $seller, float $startingPrice = 100000.00): Product
    {
        $unique = 'prd_auc_' . bin2hex(random_bytes(5));
        $category = Category::first() ?? Category::create([
            'name' => 'Thời trang Vintage',
            'slug' => 'thoi-trang-vintage-' . bin2hex(random_bytes(3)),
        ]);

        return Product::create([
            'product_code' => 'PRD-' . strtoupper($unique),
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'title' => 'Sản Phẩm Đấu Giá ' . $unique,
            'slug' => 'slug-' . $unique,
            'description' => 'Mô tả chi tiết sản phẩm đấu giá',
            'condition' => 'LIKE_NEW',
            'defect_info' => 'Không lỗi',
            'listing_type' => 'AUCTION',
            'price' => $startingPrice,
            'original_price' => $startingPrice * 1.5,
            'available_quantity' => 1,
            'total_quantity' => 1,
            'status' => ProductStatus::APPROVED,
        ]);
    }

    protected function getTestSession(): AuctionSession
    {
        return AuctionSession::firstOrFail();
    }

    /**
     * Clean up an isolated auction, its linked product, bids, orders and users.
     */
    protected function cleanUpAuction(?int $auctionId, ?int $productId = null, array $userIds = []): void
    {
        if ($auctionId) {
            DB::table('auction_watches')->where('auction_id', $auctionId)->delete();
            DB::table('auction_bids')->where('auction_id', $auctionId)->delete();
            DB::table('payments')->whereIn('order_id', function ($q) use ($auctionId) {
                $q->select('id')->from('orders')->where('auction_id', $auctionId);
            })->delete();
            DB::table('order_items')->whereIn('order_id', function ($q) use ($auctionId) {
                $q->select('id')->from('orders')->where('auction_id', $auctionId);
            })->delete();
            DB::table('orders')->where('auction_id', $auctionId)->delete();
            DB::table('auctions')->where('id', $auctionId)->delete();
        }

        if ($productId) {
            // In case a relisted auction was created for this product
            $otherAuctions = DB::table('auctions')->where('product_id', $productId)->pluck('id');
            foreach ($otherAuctions as $oId) {
                DB::table('auction_watches')->where('auction_id', $oId)->delete();
                DB::table('auction_bids')->where('auction_id', $oId)->delete();
                DB::table('orders')->where('auction_id', $oId)->delete();
                DB::table('auctions')->where('id', $oId)->delete();
            }
            DB::table('product_images')->where('product_id', $productId)->delete();
            DB::table('products')->where('id', $productId)->delete();
        }

        foreach ($userIds as $uid) {
            if ($uid) {
                DB::table('notifications')->where('user_id', $uid)->delete();
                DB::table('seller_profiles')->where('user_id', $uid)->delete();
                DB::table('user_profiles')->where('user_id', $uid)->delete();
                DB::table('users')->where('id', $uid)->delete();
            }
        }
    }

    /**
     * 1. Test auction hub, my auctions and room detail return server time and hide secret reserve price.
     */
    public function test_auction_hub_my_auctions_and_room_detail_return_server_time_and_hide_secret_reserve_price(): void
    {
        $seller = null;
        $buyer = null;
        $product = null;
        $auction = null;

        try {
            $seller = $this->createIsolatedUser('hub_seller');
            $buyer = $this->createIsolatedUser('hub_buyer');
            $product = $this->createIsolatedProduct($seller, 200000.00);

            $session = AuctionSession::first();

            $auction = Auction::create([
                'auction_code' => 'AUC-HUB-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $session?->id,
                'starting_price' => 200000.00,
                'min_bid_increment' => 20000.00,
                'reserve_price' => 500000.00, // Secret reserve price!
                'current_highest_bid' => 200000.00,
                'bid_count' => 1,
                'watch_count' => 0,
                'status' => AuctionStatus::LIVE,
                'auction_starts_at' => now()->subHour(),
                'auction_ends_at' => now()->addHours(5),
            ]);

            // Step 1: GET Hub auctions (public/optional auth)
            $hubRes = $this->getJson('/api/v1/auctions?tab=live');
            $hubRes->assertStatus(200);
            $hubRes->assertJsonPath('success', true);
            $this->assertIsArray($hubRes->json('data'));

            // Step 2: GET Room Detail as Buyer (secret reserve_price MUST be null)
            $buyerToken = $buyer->createToken('buyer_token')->plainTextToken;
            auth()->forgetGuards();
            $roomBuyerRes = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->getJson("/api/v1/auctions/{$auction->id}");

            $roomBuyerRes->assertStatus(200);
            $this->assertNotNull($roomBuyerRes->json('data.server_time'));
            $this->assertTrue($roomBuyerRes->json('data.has_reserve_price'));
            $this->assertFalse($roomBuyerRes->json('data.reserve_price_met'));
            $this->assertNull($roomBuyerRes->json('data.reserve_price')); // HIDDEN from Buyer!
            $this->assertFalse($roomBuyerRes->json('data.is_owner'));

            // Step 3: GET Room Detail as Seller (reserve_price MUST be revealed)
            $sellerToken = $seller->createToken('seller_token')->plainTextToken;
            auth()->forgetGuards();
            $roomSellerRes = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->getJson("/api/v1/auctions/{$auction->id}");

            $roomSellerRes->assertStatus(200);
            $this->assertTrue($roomSellerRes->json('data.is_owner'));
            $this->assertEquals(500000.00, (float) $roomSellerRes->json('data.reserve_price')); // REVEALED to Seller!

            // Step 4: GET My auctions (participating, watchlist, won)
            $myRes = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->getJson('/api/v1/auctions/mine?tab=participating');
            $myRes->assertStatus(200);
            $this->assertIsArray($myRes->json('data'));
        } finally {
            $this->cleanUpAuction(
                $auction?->id,
                $product?->id,
                array_filter([$seller?->id, $buyer?->id])
            );
        }
    }

    /**
     * 2. Test seller cannot bid on own auction returns 403 SELF_TRANSACTION_FORBIDDEN (BR-AC-02 / BR-AU-02).
     */
    public function test_seller_cannot_bid_on_own_auction_returns_403_self_transaction_forbidden_br_ac_02(): void
    {
        $seller = null;
        $product = null;
        $auction = null;

        try {
            $seller = $this->createIsolatedUser('self_seller');
            $product = $this->createIsolatedProduct($seller, 150000.00);

            $auction = Auction::create([
                'auction_code' => 'AUC-SELF-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $this->getTestSession()->id,
                'starting_price' => 150000.00,
                'min_bid_increment' => 10000.00,
                'current_highest_bid' => 0.00,
                'bid_count' => 0,
                'watch_count' => 0,
                'status' => AuctionStatus::LIVE,
                'auction_starts_at' => now()->subHour(),
                'auction_ends_at' => now()->addHours(2),
            ]);

            $sellerToken = $seller->createToken('seller_token')->plainTextToken;
            auth()->forgetGuards();

            $res = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->postJson("/api/v1/auctions/{$auction->id}/bids", [
                    'bid_amount' => 160000.00,
                ]);

            $res->assertStatus(403);
            $this->assertEquals('SELF_TRANSACTION_FORBIDDEN', $res->json('error_code'));
        } finally {
            $this->cleanUpAuction(
                $auction?->id,
                $product?->id,
                array_filter([$seller?->id])
            );
        }
    }

    /**
     * 3. Test valid bid updates highest bid, records immutable bid, and notifies previous leader (AF-05).
     */
    public function test_valid_bid_updates_highest_bid_records_immutable_bid_and_notifies_previous_leader_af05(): void
    {
        $seller = null;
        $bidder1 = null;
        $bidder2 = null;
        $product = null;
        $auction = null;

        try {
            $seller = $this->createIsolatedUser('lead_seller');
            $bidder1 = $this->createIsolatedUser('lead_bidder1');
            $bidder2 = $this->createIsolatedUser('lead_bidder2');
            $product = $this->createIsolatedProduct($seller, 100000.00);

            $auction = Auction::create([
                'auction_code' => 'AUC-LEAD-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $this->getTestSession()->id,
                'starting_price' => 100000.00,
                'min_bid_increment' => 10000.00,
                'current_highest_bid' => 0.00,
                'bid_count' => 0,
                'watch_count' => 0,
                'status' => AuctionStatus::LIVE,
                'auction_starts_at' => now()->subHour(),
                'auction_ends_at' => now()->addHours(2),
            ]);

            $token1 = $bidder1->createToken('token1')->plainTextToken;
            $token2 = $bidder2->createToken('token2')->plainTextToken;

            // Bidder 1 bids 100,000 VND (starting price)
            auth()->forgetGuards();
            $res1 = $this->withHeader('Authorization', "Bearer {$token1}")
                ->postJson("/api/v1/auctions/{$auction->id}/bids", [
                    'bid_amount' => 100000.00,
                ]);

            $res1->assertStatus(200);
            $this->assertEquals(100000.00, (float) $res1->json('data.auction.current_highest_bid'));
            $this->assertEquals($bidder1->id, $res1->json('data.auction.leading_bidder.id'));

            // Check immutable AuctionBid
            $this->assertDatabaseHas('auction_bids', [
                'auction_id' => $auction->id,
                'bidder_id' => $bidder1->id,
                'bid_amount' => '100000.00',
                'previous_highest_bid' => '0.00',
            ]);

            // Bidder 2 outbids Bidder 1 with 120,000 VND
            auth()->forgetGuards();
            $res2 = $this->withHeader('Authorization', "Bearer {$token2}")
                ->postJson("/api/v1/auctions/{$auction->id}/bids", [
                    'bid_amount' => 120000.00,
                ]);

            $res2->assertStatus(200);
            $this->assertEquals(120000.00, (float) $res2->json('data.auction.current_highest_bid'));
            $this->assertEquals($bidder2->id, $res2->json('data.auction.leading_bidder.id'));

            // Check notification sent to Bidder 1 (AF-05)
            $this->assertDatabaseHas('notifications', [
                'user_id' => $bidder1->id,
                'type' => 'AUCTION_OUTBID',
                'target_type' => 'AUCTION',
                'target_id' => $auction->id,
            ]);
        } finally {
            $this->cleanUpAuction(
                $auction?->id,
                $product?->id,
                array_filter([$seller?->id, $bidder1?->id, $bidder2?->id])
            );
        }
    }

    /**
     * 4. Test underbid returns 409 AUCTION_OUTBID_CONFLICT with complete latest_state payload (BR-AU-02 / AF-04).
     */
    public function test_underbid_returns_409_auction_outbid_conflict_with_complete_latest_state_payload_br_au_02(): void
    {
        $seller = null;
        $bidder = null;
        $product = null;
        $auction = null;

        try {
            $seller = $this->createIsolatedUser('conflict_seller');
            $bidder = $this->createIsolatedUser('conflict_bidder');
            $product = $this->createIsolatedProduct($seller, 200000.00);

            $auction = Auction::create([
                'auction_code' => 'AUC-CONF-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $this->getTestSession()->id,
                'starting_price' => 200000.00,
                'min_bid_increment' => 20000.00,
                'current_highest_bid' => 220000.00, // Valid next bid must be >= 240,000
                'bid_count' => 2,
                'watch_count' => 0,
                'status' => AuctionStatus::LIVE,
                'auction_starts_at' => now()->subHour(),
                'auction_ends_at' => now()->addHours(3),
                'extended_count' => 0,
            ]);

            $token = $bidder->createToken('bidder_token')->plainTextToken;
            auth()->forgetGuards();

            // Bidder tries to bid 230,000 (less than 240,000)
            $res = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson("/api/v1/auctions/{$auction->id}/bids", [
                    'bid_amount' => 230000.00,
                ]);

            $res->assertStatus(409);
            $this->assertEquals('AUCTION_OUTBID_CONFLICT', $res->json('error_code'));

            // Verify complete latest_state payload for UI real-time refresh (M-AC-04)
            $this->assertNotNull($res->json('latest_state'));
            $this->assertEquals('220000.00', $res->json('latest_state.current_highest_bid'));
            $this->assertEquals('240000.00', $res->json('latest_state.minimum_next_bid'));
            $this->assertEquals(2, $res->json('latest_state.bid_count'));
            $this->assertArrayHasKey('auction_ends_at', $res->json('latest_state'));
        } finally {
            $this->cleanUpAuction(
                $auction?->id,
                $product?->id,
                array_filter([$seller?->id, $bidder?->id])
            );
        }
    }

    /**
     * 5. Test bid within sensitivity window triggers Anti-Sniping time extension (BR-AU-04 / ADR-05).
     */
    public function test_bid_within_sensitivity_window_triggers_anti_sniping_time_extension_br_au_04(): void
    {
        $seller = null;
        $bidder = null;
        $product = null;
        $auction = null;

        try {
            $seller = $this->createIsolatedUser('snip_seller');
            $bidder = $this->createIsolatedUser('snip_bidder');
            $product = $this->createIsolatedProduct($seller, 100000.00);

            // Set ends_at in 20 seconds (strictly within 120s / 30s sensitivity window)
            $initialEndsAt = now()->addSeconds(20);

            $auction = Auction::create([
                'auction_code' => 'AUC-SNIP-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $this->getTestSession()->id,
                'starting_price' => 100000.00,
                'min_bid_increment' => 10000.00,
                'current_highest_bid' => 0.00,
                'bid_count' => 0,
                'watch_count' => 0,
                'status' => AuctionStatus::LIVE,
                'auction_starts_at' => now()->subHour(),
                'auction_ends_at' => $initialEndsAt,
                'extended_count' => 0,
            ]);

            $token = $bidder->createToken('bidder_token')->plainTextToken;
            auth()->forgetGuards();

            $res = $this->withHeader('Authorization', "Bearer {$token}")
                ->postJson("/api/v1/auctions/{$auction->id}/bids", [
                    'bid_amount' => 100000.00,
                ]);

            $res->assertStatus(200);
            $this->assertTrue($res->json('data.triggered_anti_sniping'));
            $this->assertEquals(1, $res->json('data.auction.extended_count'));

            // Check that ends_at was extended past the initial 20s
            $freshAuction = Auction::find($auction->id);
            $this->assertEquals(1, $freshAuction->extended_count);
            $this->assertNotNull($freshAuction->last_extended_at);
            $this->assertGreaterThan($initialEndsAt->timestamp, $freshAuction->auction_ends_at->timestamp);
        } finally {
            $this->cleanUpAuction(
                $auction?->id,
                $product?->id,
                array_filter([$seller?->id, $bidder?->id])
            );
        }
    }

    /**
     * 6. Test seller close early blocks when reserve not met and succeeds when reserve met,
     * creating winning order with buyer protection fee (BR-AU-05 / DEC-04).
     */
    public function test_seller_close_early_blocks_when_reserve_not_met_and_succeeds_when_reserve_met_creating_winning_order_with_protection_fee_br_au_05_dec04(): void
    {
        $seller = null;
        $bidder = null;
        $product = null;
        $auction = null;

        try {
            $seller = $this->createIsolatedUser('close_seller');
            $bidder = $this->createIsolatedUser('close_bidder');
            $product = $this->createIsolatedProduct($seller, 300000.00);

            // Reserve price is 500,000 VND
            $auction = Auction::create([
                'auction_code' => 'AUC-CLOSE-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $this->getTestSession()->id,
                'starting_price' => 300000.00,
                'min_bid_increment' => 50000.00,
                'reserve_price' => 500000.00,
                'current_highest_bid' => 350000.00, // Reserve NOT met!
                'leading_bidder_id' => $bidder->id,
                'bid_count' => 2,
                'watch_count' => 0,
                'status' => AuctionStatus::LIVE,
                'auction_starts_at' => now()->subHour(),
                'auction_ends_at' => now()->addHours(5),
            ]);

            $sellerToken = $seller->createToken('seller_token')->plainTextToken;
            $bidderToken = $bidder->createToken('bidder_token')->plainTextToken;

            // Step 1: Seller tries to close early while reserve not met -> 409 Conflict
            auth()->forgetGuards();
            $blockedRes = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->postJson("/api/v1/auctions/{$auction->id}/close-early");

            $blockedRes->assertStatus(409);

            // Step 2: Bidder bids 500,000 VND (reserve price is met!)
            auth()->forgetGuards();
            $bidRes = $this->withHeader('Authorization', "Bearer {$bidderToken}")
                ->postJson("/api/v1/auctions/{$auction->id}/bids", [
                    'bid_amount' => 500000.00,
                ]);
            $bidRes->assertStatus(200);

            // Step 3: Seller closes early -> Succeeds (200 OK)
            auth()->forgetGuards();
            $successRes = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->postJson("/api/v1/auctions/{$auction->id}/close-early");

            $successRes->assertStatus(200);
            $this->assertEquals('COMPLETED', $successRes->json('data.auction.status'));
            $this->assertTrue($successRes->json('data.auction.closed_early_by_seller'));

            // Step 4: Verify Order creation with Buyer Protection Fee (DEC-04)
            // item_subtotal = 500,000 VND, fee = 500,000 * 0.06 + 7000 = 37,000 VND, total = 537,000 VND
            $orderData = $successRes->json('data.order');
            $this->assertEquals('AUCTION', $orderData['order_source']);
            $this->assertEquals(500000.00, (float) $orderData['item_subtotal']);
            $this->assertEquals(37000.00, (float) $orderData['buyer_protection_fee']);
            $this->assertEquals(537000.00, (float) $orderData['total_amount']);
            $this->assertEquals('PENDING_PAYMENT', $orderData['order_status']);
            $this->assertEquals('UNPAID', $orderData['payment_status']);
            $this->assertNotNull($orderData['payment_expires_at']);

            // Product marked as SOLD
            $freshProduct = Product::find($product->id);
            $this->assertEquals('SOLD', $freshProduct->status->value);
            $this->assertEquals(0, $freshProduct->available_quantity);
        } finally {
            $this->cleanUpAuction(
                $auction?->id,
                $product?->id,
                array_filter([$seller?->id, $bidder?->id])
            );
        }
    }

    /**
     * 7. Test seller can relist product after ENDED_UNSOLD or WINNER_DEFAULTED (DEC-02 / AF-09).
     */
    public function test_seller_can_relist_product_after_ended_unsold_or_winner_defaulted_dec02(): void
    {
        $seller = null;
        $product = null;
        $endedAuction = null;

        try {
            $seller = $this->createIsolatedUser('relist_seller');
            $product = $this->createIsolatedProduct($seller, 400000.00);

            // Previous auction ended with ENDED_UNSOLD
            $endedAuction = Auction::create([
                'auction_code' => 'AUC-UNSOLD-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $this->getTestSession()->id,
                'starting_price' => 400000.00,
                'min_bid_increment' => 20000.00,
                'current_highest_bid' => 0.00,
                'bid_count' => 0,
                'watch_count' => 0,
                'status' => AuctionStatus::ENDED_UNSOLD,
                'auction_starts_at' => now()->subDays(2),
                'auction_ends_at' => now()->subDay(),
                'closed_at' => now()->subDay(),
            ]);

            $sellerToken = $seller->createToken('seller_token')->plainTextToken;
            auth()->forgetGuards();

            // Seller relists product with new starting price and reserve price
            $res = $this->withHeader('Authorization', "Bearer {$sellerToken}")
                ->postJson("/api/v1/seller/products/{$product->id}/relist", [
                    'starting_price' => 350000.00,
                    'min_bid_increment' => 15000.00,
                    'reserve_price' => 450000.00,
                    'auction_starts_at' => now()->subMinute()->toDateTimeString(),
                    'auction_ends_at' => now()->addDays(2)->toDateTimeString(),
                ]);

            $res->assertStatus(201);
            $newAuctionId = $res->json('data.id');
            $this->assertNotEquals($endedAuction->id, $newAuctionId);
            $this->assertEquals(350000.00, (float) $res->json('data.starting_price'));
            $this->assertEquals('LIVE', $res->json('data.status'));

            // Product restored to APPROVED
            $freshProduct = Product::find($product->id);
            $this->assertEquals('APPROVED', $freshProduct->status->value);
            $this->assertEquals(1, $freshProduct->available_quantity);
            $this->assertEquals(350000.00, (float) $freshProduct->price);
        } finally {
            $this->cleanUpAuction(
                $endedAuction?->id,
                $product?->id,
                array_filter([$seller?->id])
            );
        }
    }

    /**
     * 8. Test toggle auction watch updates watch_count accurately (M-AC-01 / Watchlist).
     */
    public function test_toggle_auction_watch_updates_watch_count_accurately(): void
    {
        $seller = null;
        $watcher = null;
        $product = null;
        $auction = null;

        try {
            $seller = $this->createIsolatedUser('watch_seller');
            $watcher = $this->createIsolatedUser('watcher_user');
            $product = $this->createIsolatedProduct($seller, 150000.00);

            $auction = Auction::create([
                'auction_code' => 'AUC-WATCH-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $this->getTestSession()->id,
                'starting_price' => 150000.00,
                'min_bid_increment' => 10000.00,
                'current_highest_bid' => 0.00,
                'bid_count' => 0,
                'watch_count' => 0,
                'status' => AuctionStatus::LIVE,
                'auction_starts_at' => now()->subHour(),
                'auction_ends_at' => now()->addHours(4),
            ]);

            $watcherToken = $watcher->createToken('watcher_token')->plainTextToken;
            auth()->forgetGuards();

            // 1. First toggle -> Adds watch
            $res1 = $this->withHeader('Authorization', "Bearer {$watcherToken}")
                ->postJson("/api/v1/auctions/{$auction->id}/watch");

            $res1->assertStatus(200);
            $this->assertTrue($res1->json('data.is_watching'));
            $this->assertEquals(1, $res1->json('data.watch_count'));
            $this->assertEquals(1, Auction::find($auction->id)->watch_count);

            // 2. Second toggle -> Removes watch
            auth()->forgetGuards();
            $res2 = $this->withHeader('Authorization', "Bearer {$watcherToken}")
                ->postJson("/api/v1/auctions/{$auction->id}/watch");

            $res2->assertStatus(200);
            $this->assertFalse($res2->json('data.is_watching'));
            $this->assertEquals(0, $res2->json('data.watch_count'));
            $this->assertEquals(0, Auction::find($auction->id)->watch_count);
        } finally {
            $this->cleanUpAuction(
                $auction?->id,
                $product?->id,
                array_filter([$seller?->id, $watcher?->id])
            );
        }
    }
}
