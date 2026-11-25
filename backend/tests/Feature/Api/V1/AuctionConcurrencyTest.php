<?php

namespace Tests\Feature\Api\V1;

use App\Enums\AuctionStatus;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Auction;
use App\Models\AuctionBid;
use App\Models\AuctionSession;
use App\Models\Category;
use App\Models\Product;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\UserProfile;
use App\Services\Governance\PlatformConfigService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\Helpers\LocalHttpServerManager;
use Tests\TestCase;

/**
 * P9-02: High-Concurrency Auction Testing Suite
 *
 * Exercises auction bid processing under genuine concurrent requests
 * using independent database connections, independent OS processes,
 * real HTTP APIs, and comprehensive PostgreSQL state reconciliation.
 */
class AuctionConcurrencyTest extends TestCase
{
    public static function setUpBeforeClass(): void
    {
        parent::setUpBeforeClass();
        LocalHttpServerManager::start();
    }

    public static function tearDownAfterClass(): void
    {
        LocalHttpServerManager::stop();
        parent::tearDownAfterClass();
    }

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
        $unique = 'prd_conc_' . bin2hex(random_bytes(5));
        $category = Category::first() ?? Category::create([
            'name' => 'Thời trang Vintage',
            'slug' => 'thoi-trang-vintage-' . bin2hex(random_bytes(3)),
        ]);

        return Product::create([
            'product_code' => 'PRD-' . strtoupper($unique),
            'seller_id' => $seller->id,
            'category_id' => $category->id,
            'title' => 'Sản Phẩm Đấu Giá Concurrency ' . $unique,
            'slug' => 'slug-' . $unique,
            'description' => 'Mô tả chi tiết sản phẩm đấu giá concurrency test',
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
     * Clean up an isolated auction, its linked product, bids, orders, notifications, and users.
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
            DB::table('product_images')->where('product_id', $productId)->delete();
            DB::table('products')->where('id', $productId)->delete();
        }

        foreach ($userIds as $uid) {
            if ($uid) {
                DB::table('personal_access_tokens')->where('tokenable_id', $uid)->delete();
                DB::table('notifications')->where('user_id', $uid)->delete();
                DB::table('seller_profiles')->where('user_id', $uid)->delete();
                DB::table('user_profiles')->where('user_id', $uid)->delete();
                DB::table('users')->where('id', $uid)->delete();
            }
        }
    }

    /**
     * Clean up barrier files.
     */
    protected function cleanUpBarrierFiles(string $barrierPath): void
    {
        $dir = dirname($barrierPath);
        $base = basename($barrierPath);
        $files = glob("{$dir}/{$base}*");
        if ($files) {
            foreach ($files as $f) {
                @unlink($f);
            }
        }
    }

    /**
     * Wait for all worker ready files to appear, then release the barrier (.go).
     */
    protected function releaseBarrierWhenWorkersReady(string $barrierPath, array $workerIds, float $timeoutSeconds = 8.0): void
    {
        $start = microtime(true);
        while (true) {
            $allReady = true;
            foreach ($workerIds as $wid) {
                if (!file_exists("{$barrierPath}.ready.{$wid}")) {
                    $allReady = false;
                    break;
                }
            }
            if ($allReady) {
                break;
            }
            if ((microtime(true) - $start) > $timeoutSeconds) {
                throw new \RuntimeException("Workers failed to signal ready state within {$timeoutSeconds}s.");
            }
            usleep(1000); // 1ms
        }

        // Release all workers simultaneously
        file_put_contents("{$barrierPath}.go", (string) microtime(true));
    }

    /**
     * AC-P902-01: Genuine Concurrency & Row Lock Blocking Verification.
     *
     * Spawns two independent OS processes with distinct PostgreSQL connections.
     * Worker 1 acquires row lock via SELECT ... FOR UPDATE and holds it.
     * Worker 2 attempts to acquire the lock during that window and is blocked.
     * Captures and asserts:
     * - Distinct PostgreSQL backend PIDs.
     * - Worker 2 requested lock before Worker 1 released (temporal overlap).
     * - Worker 2 acquired lock only after Worker 1 committed (wait_duration_ms > 0).
     */
    public function test_ac_p902_01_true_concurrency_and_row_lock_blocking_demonstrated(): void
    {
        $seller = null;
        $product = null;
        $auction = null;
        $barrierPath = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'p902_barr_' . uniqid();

        try {
            $seller = $this->createIsolatedUser('p902_lock_seller');
            $product = $this->createIsolatedProduct($seller, 100000.00);

            $auction = Auction::create([
                'auction_code' => 'AUC-CONC-LOCK-' . time(),
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
                'extended_count' => 0,
            ]);

            $workerScript = realpath(__DIR__ . '/../../../Helpers/AuctionLockContentionWorker.php');
            $this->assertFileExists($workerScript);

            // Worker 1: holds lock for 400ms (400,000 us), delay 0
            $cmd1 = sprintf('php "%s" 1 %d 400000 0 "%s"', $workerScript, $auction->id, $barrierPath);
            // Worker 2: holds lock for 0ms, starts trying after 50ms delay (50,000 us)
            $cmd2 = sprintf('php "%s" 2 %d 0 50000 "%s"', $workerScript, $auction->id, $barrierPath);

            $descriptors = [
                1 => ['pipe', 'w'],
                2 => ['pipe', 'w'],
            ];

            $proc1 = proc_open($cmd1, $descriptors, $pipes1);
            $proc2 = proc_open($cmd2, $descriptors, $pipes2);

            $this->assertIsResource($proc1);
            $this->assertIsResource($proc2);

            // Wait for both to be ready and release
            $this->releaseBarrierWhenWorkersReady($barrierPath, [1, 2]);

            $out1 = stream_get_contents($pipes1[1]);
            $out2 = stream_get_contents($pipes2[1]);
            fclose($pipes1[1]);
            fclose($pipes1[2]);
            fclose($pipes2[1]);
            fclose($pipes2[2]);
            proc_close($proc1);
            proc_close($proc2);

            $data1 = json_decode($out1, true);
            $data2 = json_decode($out2, true);

            $this->assertNotNull($data1, "Worker 1 failed to return valid JSON. Raw output: {$out1}");
            $this->assertNotNull($data2, "Worker 2 failed to return valid JSON. Raw output: {$out2}");

            $this->assertNull($data1['error'], "Worker 1 returned error: " . ($data1['error'] ?? ''));
            $this->assertNull($data2['error'], "Worker 2 returned error: " . ($data2['error'] ?? ''));

            // 1. Assert distinct independent PostgreSQL backend PIDs
            $this->assertNotNull($data1['backend_pid']);
            $this->assertNotNull($data2['backend_pid']);
            $this->assertNotEquals(
                $data1['backend_pid'],
                $data2['backend_pid'],
                'Each worker process must use an independent PostgreSQL connection.'
            );

            // 2. Assert temporal overlap (Worker 2 arrived while Worker 1 held the lock)
            $this->assertLessThan(
                $data1['t_released'],
                $data2['t_before'],
                'Worker 2 must have attempted to acquire the lock before Worker 1 released it.'
            );

            // 3. Assert lock contention and engine-enforced wait
            $this->assertGreaterThanOrEqual(
                $data1['t_released'],
                $data2['t_acquired'],
                'Worker 2 must acquire the lock only after Worker 1 has released it.'
            );

            // 4. Assert measurable lock wait duration
            $this->assertGreaterThan(
                50.0,
                $data2['wait_duration_ms'],
                'Worker 2 must have experienced measurable lock contention wait duration (>50ms).'
            );
        } finally {
            $this->cleanUpBarrierFiles($barrierPath);
            $this->cleanUpAuction($auction?->id, $product?->id, array_filter([$seller?->id]));
        }
    }

    /**
     * AC-P902-02: Stale Bid Conflict & latest_state under Concurrent HTTP Bids.
     *
     * Two independent OS worker processes send identical bid amounts concurrently
     * via real HTTP requests to the two local Laravel servers.
     * Asserts:
     * - Exactly one request succeeds (HTTP 200).
     * - Exactly one request receives HTTP 409 AUCTION_OUTBID_CONFLICT.
     * - HTTP 409 response contains complete latest_state reflecting the winner's bid.
     * - Exactly one accepted bid is persisted in auction_bids.
     * - Database highest bid and bid_count match the winner's result.
     */
    public function test_ac_p902_02_stale_bid_conflict_and_latest_state_under_concurrent_http_bids(): void
    {
        $seller = null;
        $bidder1 = null;
        $bidder2 = null;
        $product = null;
        $auction = null;
        $barrierPath = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'p902_conf_' . uniqid();

        try {
            $seller = $this->createIsolatedUser('p902_cf_seller');
            $bidder1 = $this->createIsolatedUser('p902_cf_bidder1');
            $bidder2 = $this->createIsolatedUser('p902_cf_bidder2');
            $product = $this->createIsolatedProduct($seller, 100000.00);

            $auction = Auction::create([
                'auction_code' => 'AUC-CONC-CONF-' . time(),
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
                'extended_count' => 0,
            ]);

            $token1 = $bidder1->createToken('token1')->plainTextToken;
            $token2 = $bidder2->createToken('token2')->plainTextToken;

            $workerScript = realpath(__DIR__ . '/../../../Helpers/AuctionTestHttpWorker.php');
            $this->assertFileExists($workerScript);

            // Both workers submit identical bid of 100,000 VND (valid for starting bid)
            $identicalBidAmount = 100000.00;

            // Worker 1 hits Server 1, Worker 2 hits Server 2
            $cmd1 = sprintf(
                'php "%s" 1 "%s" %d "%s" %F "%s"',
                $workerScript,
                LocalHttpServerManager::getUrl1(),
                $auction->id,
                $token1,
                $identicalBidAmount,
                $barrierPath
            );
            $cmd2 = sprintf(
                'php "%s" 2 "%s" %d "%s" %F "%s"',
                $workerScript,
                LocalHttpServerManager::getUrl2(),
                $auction->id,
                $token2,
                $identicalBidAmount,
                $barrierPath
            );

            $descriptors = [
                1 => ['pipe', 'w'],
                2 => ['pipe', 'w'],
            ];

            $proc1 = proc_open($cmd1, $descriptors, $pipes1);
            $proc2 = proc_open($cmd2, $descriptors, $pipes2);

            $this->assertIsResource($proc1);
            $this->assertIsResource($proc2);

            // Release barrier to send HTTP requests nearly simultaneously
            $this->releaseBarrierWhenWorkersReady($barrierPath, [1, 2]);

            $out1 = stream_get_contents($pipes1[1]);
            $out2 = stream_get_contents($pipes2[1]);
            fclose($pipes1[1]);
            fclose($pipes1[2]);
            fclose($pipes2[1]);
            fclose($pipes2[2]);
            proc_close($proc1);
            proc_close($proc2);

            $res1 = json_decode($out1, true);
            $res2 = json_decode($out2, true);

            $this->assertNotNull($res1, "Worker 1 output invalid. Raw: {$out1}");
            $this->assertNotNull($res2, "Worker 2 output invalid. Raw: {$out2}");

            // Verify independent connections
            $this->assertNotNull($res1['backend_pid']);
            $this->assertNotNull($res2['backend_pid']);
            $this->assertNotEquals($res1['backend_pid'], $res2['backend_pid']);

            $statuses = [$res1['http_status'], $res2['http_status']];
            $this->assertContains(200, $statuses, 'Exactly one concurrent HTTP request must succeed with 200 OK.');
            $this->assertContains(409, $statuses, 'Exactly one concurrent HTTP request must be rejected with 409 Conflict.');

            // Identify winner and conflict responses
            $winnerResult = $res1['http_status'] === 200 ? $res1 : $res2;
            $conflictResult = $res1['http_status'] === 409 ? $res1 : $res2;

            // 1. Verify winner response
            $this->assertTrue($winnerResult['response_json']['success']);
            $this->assertEquals(
                '100000.00',
                number_format((float) $winnerResult['response_json']['data']['auction']['current_highest_bid'], 2, '.', '')
            );

            // 2. Verify 409 Conflict response and latest_state contract
            $conflictJson = $conflictResult['response_json'];
            $this->assertFalse($conflictJson['success']);
            $this->assertEquals('AUCTION_OUTBID_CONFLICT', $conflictJson['error_code']);
            $this->assertNotNull($conflictJson['latest_state'], 'Conflict response must contain latest_state.');

            $latestState = $conflictJson['latest_state'];
            $this->assertEquals($auction->id, $latestState['auction_id']);
            $this->assertEquals('100000.00', $latestState['current_highest_bid']);
            $this->assertEquals('110000.00', $latestState['minimum_next_bid']);
            $this->assertEquals(1, $latestState['bid_count']);
            $this->assertArrayHasKey('auction_ends_at', $latestState);
            $this->assertArrayHasKey('extended_count', $latestState);

            // 3. Database State Reconciliation
            $freshAuction = Auction::find($auction->id);
            $this->assertEquals(100000.00, (float) $freshAuction->current_highest_bid);
            $this->assertEquals(1, $freshAuction->bid_count);

            $bidsCount = AuctionBid::where('auction_id', $auction->id)->count();
            $this->assertEquals(1, $bidsCount, 'Exactly 1 bid must be persisted in database.');
        } finally {
            $this->cleanUpBarrierFiles($barrierPath);
            $this->cleanUpAuction(
                $auction?->id,
                $product?->id,
                array_filter([$seller?->id, $bidder1?->id, $bidder2?->id])
            );
        }
    }

    /**
     * Scenario 1: Simultaneous Valid Bids with Different Amounts under Real HTTP.
     *
     * Bidder 1 submits 120,000 VND and Bidder 2 submits 140,000 VND concurrently.
     * Demonstrates that serialization guarantees consistency regardless of arrival order:
     * - If 120k processed first, 140k (140k >= 130k) also succeeds (both 200 OK).
     * - If 140k processed first, 120k (120k < 150k) receives 409 Conflict.
     * In both cases:
     * - Final highest bid is 140,000 VND.
     * - Winner is Bidder 2.
     * - State reconciles with database.
     */
    public function test_scenario_1_simultaneous_valid_bids_with_different_amounts_under_real_http(): void
    {
        $seller = null;
        $bidder1 = null;
        $bidder2 = null;
        $product = null;
        $auction = null;
        $barrierPath = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'p902_sc1_' . uniqid();

        try {
            $seller = $this->createIsolatedUser('p902_s1_seller');
            $bidder1 = $this->createIsolatedUser('p902_s1_bidder1');
            $bidder2 = $this->createIsolatedUser('p902_s1_bidder2');
            $product = $this->createIsolatedProduct($seller, 100000.00);

            $auction = Auction::create([
                'auction_code' => 'AUC-CONC-S1-' . time(),
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
                'extended_count' => 0,
            ]);

            $token1 = $bidder1->createToken('token1')->plainTextToken;
            $token2 = $bidder2->createToken('token2')->plainTextToken;

            $workerScript = realpath(__DIR__ . '/../../../Helpers/AuctionTestHttpWorker.php');

            $cmd1 = sprintf(
                'php "%s" 1 "%s" %d "%s" %F "%s"',
                $workerScript,
                LocalHttpServerManager::getUrl1(),
                $auction->id,
                $token1,
                120000.00,
                $barrierPath
            );
            $cmd2 = sprintf(
                'php "%s" 2 "%s" %d "%s" %F "%s"',
                $workerScript,
                LocalHttpServerManager::getUrl2(),
                $auction->id,
                $token2,
                140000.00,
                $barrierPath
            );

            $descriptors = [
                1 => ['pipe', 'w'],
                2 => ['pipe', 'w'],
            ];

            $proc1 = proc_open($cmd1, $descriptors, $pipes1);
            $proc2 = proc_open($cmd2, $descriptors, $pipes2);

            $this->releaseBarrierWhenWorkersReady($barrierPath, [1, 2]);

            $out1 = stream_get_contents($pipes1[1]);
            $out2 = stream_get_contents($pipes2[1]);
            fclose($pipes1[1]);
            fclose($pipes1[2]);
            fclose($pipes2[1]);
            fclose($pipes2[2]);
            proc_close($proc1);
            proc_close($proc2);

            $res1 = json_decode($out1, true);
            $res2 = json_decode($out2, true);

            $this->assertNotNull($res1);
            $this->assertNotNull($res2);

            $freshAuction = Auction::find($auction->id);

            // In all serialization orders, the final highest bid MUST be 140,000 VND
            $this->assertEquals(140000.00, (float) $freshAuction->current_highest_bid);
            $this->assertEquals($bidder2->id, $freshAuction->leading_bidder_id);

            // Verify persisted bids in database
            $persistedBids = AuctionBid::where('auction_id', $auction->id)
                ->orderBy('id', 'asc')
                ->get();

            if ($res1['http_status'] === 200 && $res2['http_status'] === 200) {
                // Lower bid was processed first, then higher bid succeeded
                $this->assertCount(2, $persistedBids);
                $this->assertEquals(2, $freshAuction->bid_count);
                $this->assertEquals(120000.00, (float) $persistedBids[0]->bid_amount);
                $this->assertEquals(140000.00, (float) $persistedBids[1]->bid_amount);
            } else {
                // Higher bid was processed first (200 OK), lower bid was rejected with 409
                $this->assertEquals(200, $res2['http_status']);
                $this->assertEquals(409, $res1['http_status']);
                $this->assertCount(1, $persistedBids);
                $this->assertEquals(1, $freshAuction->bid_count);
                $this->assertEquals(140000.00, (float) $persistedBids[0]->bid_amount);
            }
        } finally {
            $this->cleanUpBarrierFiles($barrierPath);
            $this->cleanUpAuction(
                $auction?->id,
                $product?->id,
                array_filter([$seller?->id, $bidder1?->id, $bidder2?->id])
            );
        }
    }

    /**
     * AC-P902-03: Anti-Sniping Concurrency Safety under Real HTTP Bids.
     *
     * Creates an auction with ending time within the configured anti-sniping window.
     * Two concurrent bids are submitted.
     * Asserts:
     * - Auction end time is extended according to platform rules.
     * - extended_count reflects committed extensions.
     * - Duplicate redundant extensions are prevented by row lock serialization.
     * - No lost updates occur.
     */
    public function test_ac_p902_03_anti_sniping_concurrency_safety_under_concurrent_http_bids(): void
    {
        $seller = null;
        $bidder1 = null;
        $bidder2 = null;
        $product = null;
        $auction = null;
        $barrierPath = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'p902_snip_' . uniqid();

        try {
            $platformConfig = app(PlatformConfigService::class);
            $windowSeconds = $platformConfig->antiSnipingWindowSeconds();
            $extensionSeconds = $platformConfig->antiSnipingExtensionSeconds();

            $seller = $this->createIsolatedUser('p902_sn_seller');
            $bidder1 = $this->createIsolatedUser('p902_sn_bidder1');
            $bidder2 = $this->createIsolatedUser('p902_sn_bidder2');
            $product = $this->createIsolatedProduct($seller, 100000.00);

            // Set auction to end in half of the trigger window (e.g. 15s in demo, 60s in prod)
            $remaining = (int) max(5, floor($windowSeconds / 2));
            $initialEndsAt = now()->addSeconds($remaining);

            $auction = Auction::create([
                'auction_code' => 'AUC-CONC-SNIP-' . time(),
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

            $token1 = $bidder1->createToken('token1')->plainTextToken;
            $token2 = $bidder2->createToken('token2')->plainTextToken;

            $workerScript = realpath(__DIR__ . '/../../../Helpers/AuctionTestHttpWorker.php');

            // Send bids 100,000 VND and 120,000 VND
            $cmd1 = sprintf(
                'php "%s" 1 "%s" %d "%s" %F "%s"',
                $workerScript,
                LocalHttpServerManager::getUrl1(),
                $auction->id,
                $token1,
                100000.00,
                $barrierPath
            );
            $cmd2 = sprintf(
                'php "%s" 2 "%s" %d "%s" %F "%s"',
                $workerScript,
                LocalHttpServerManager::getUrl2(),
                $auction->id,
                $token2,
                120000.00,
                $barrierPath
            );

            $descriptors = [
                1 => ['pipe', 'w'],
                2 => ['pipe', 'w'],
            ];

            $proc1 = proc_open($cmd1, $descriptors, $pipes1);
            $proc2 = proc_open($cmd2, $descriptors, $pipes2);

            $this->releaseBarrierWhenWorkersReady($barrierPath, [1, 2]);

            $out1 = stream_get_contents($pipes1[1]);
            $out2 = stream_get_contents($pipes2[1]);
            fclose($pipes1[1]);
            fclose($pipes1[2]);
            fclose($pipes2[1]);
            fclose($pipes2[2]);
            proc_close($proc1);
            proc_close($proc2);

            $res1 = json_decode($out1, true);
            $res2 = json_decode($out2, true);

            $this->assertNotNull($res1);
            $this->assertNotNull($res2);

            $freshAuction = Auction::find($auction->id);

            // 1. Assert end time extended by exactly the configured extensionSeconds (no lost updates, no duplicate extensions)
            $expectedEndsAt = $initialEndsAt->copy()->addSeconds($extensionSeconds);
            $this->assertEquals(
                $expectedEndsAt->timestamp,
                $freshAuction->auction_ends_at->timestamp,
                "auction_ends_at must equal exactly initial_ends_at + antiSnipingExtensionSeconds ({$extensionSeconds}s) from platform config."
            );

            // 2. Assert extended_count increments by exactly 1 (duplicate extensions prevented by row lock serialization)
            $this->assertEquals(
                1,
                $freshAuction->extended_count,
                'extended_count must increment by exactly 1, proving duplicate extensions are prevented.'
            );

            // 3. Assert last_extended_at is updated and valid
            $this->assertNotNull(
                $freshAuction->last_extended_at,
                'last_extended_at must be populated when anti-sniping extension triggers.'
            );

            // 4. Assert each HTTP response's triggered_anti_sniping matches the single committed extension
            $triggeredResponseCount = 0;
            if ($res1['http_status'] === 200 && ($res1['response_json']['data']['triggered_anti_sniping'] ?? false) === true) {
                $triggeredResponseCount++;
            }
            if ($res2['http_status'] === 200 && ($res2['response_json']['data']['triggered_anti_sniping'] ?? false) === true) {
                $triggeredResponseCount++;
            }
            $this->assertEquals(
                1,
                $triggeredResponseCount,
                'Exactly one HTTP bid response must report triggered_anti_sniping = true, matching the single committed extension.'
            );

            // 5. Database State Reconciliation: exactly one persisted AuctionBid has triggered_anti_sniping = true
            $persistedBids = AuctionBid::where('auction_id', $auction->id)->get();
            $this->assertEquals(
                $persistedBids->count(),
                $freshAuction->bid_count,
                'Database reconciliation: persisted bid count must match auction.bid_count.'
            );
            $antiSnipingBids = $persistedBids->where('triggered_anti_sniping', true);
            $this->assertCount(
                1,
                $antiSnipingBids,
                'Database reconciliation: exactly one persisted AuctionBid record must have triggered_anti_sniping = true.'
            );
        } finally {
            $this->cleanUpBarrierFiles($barrierPath);
            $this->cleanUpAuction(
                $auction?->id,
                $product?->id,
                array_filter([$seller?->id, $bidder1?->id, $bidder2?->id])
            );
        }
    }

    /**
     * AC-P902-04: Final Database State Consistency & Invariant Reconciliation.
     *
     * Directly queries PostgreSQL after all workers complete and asserts all domain invariants:
     * 1. auctions.current_highest_bid == MAX(auction_bids.bid_amount)
     * 2. auctions.bid_count == COUNT(auction_bids)
     * 3. auctions.leading_bidder_id == latest_bid.bidder_id
     * 4. Strict monotonicity: every bid > previous_highest_bid
     * 5. Immutable ledger enforcement (cannot update or delete bids)
     * 6. Cleanup verification
     */
    public function test_ac_p902_04_final_database_state_consistency_and_invariant_reconciliation(): void
    {
        $seller = null;
        $bidder1 = null;
        $bidder2 = null;
        $product = null;
        $auction = null;
        $barrierPath = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'p902_inv_' . uniqid();

        try {
            $seller = $this->createIsolatedUser('p902_in_seller');
            $bidder1 = $this->createIsolatedUser('p902_in_bidder1');
            $bidder2 = $this->createIsolatedUser('p902_in_bidder2');
            $product = $this->createIsolatedProduct($seller, 200000.00);

            $auction = Auction::create([
                'auction_code' => 'AUC-CONC-INV-' . time(),
                'product_id' => $product->id,
                'seller_id' => $seller->id,
                'session_id' => $this->getTestSession()->id,
                'starting_price' => 200000.00,
                'min_bid_increment' => 20000.00,
                'current_highest_bid' => 0.00,
                'bid_count' => 0,
                'watch_count' => 0,
                'status' => AuctionStatus::LIVE,
                'auction_starts_at' => now()->subHour(),
                'auction_ends_at' => now()->addHours(3),
                'extended_count' => 0,
            ]);

            $token1 = $bidder1->createToken('token1')->plainTextToken;
            $token2 = $bidder2->createToken('token2')->plainTextToken;

            $workerScript = realpath(__DIR__ . '/../../../Helpers/AuctionTestHttpWorker.php');

            $cmd1 = sprintf(
                'php "%s" 1 "%s" %d "%s" %F "%s"',
                $workerScript,
                LocalHttpServerManager::getUrl1(),
                $auction->id,
                $token1,
                220000.00,
                $barrierPath
            );
            $cmd2 = sprintf(
                'php "%s" 2 "%s" %d "%s" %F "%s"',
                $workerScript,
                LocalHttpServerManager::getUrl2(),
                $auction->id,
                $token2,
                240000.00,
                $barrierPath
            );

            $descriptors = [
                1 => ['pipe', 'w'],
                2 => ['pipe', 'w'],
            ];

            $proc1 = proc_open($cmd1, $descriptors, $pipes1);
            $proc2 = proc_open($cmd2, $descriptors, $pipes2);

            $this->releaseBarrierWhenWorkersReady($barrierPath, [1, 2]);

            $out1 = stream_get_contents($pipes1[1]);
            $out2 = stream_get_contents($pipes2[1]);
            fclose($pipes1[1]);
            fclose($pipes1[2]);
            fclose($pipes2[1]);
            fclose($pipes2[2]);
            proc_close($proc1);
            proc_close($proc2);

            // Reconcile database state
            $freshAuction = Auction::find($auction->id);
            $persistedBids = AuctionBid::where('auction_id', $auction->id)
                ->orderBy('id', 'asc')
                ->get();

            $this->assertNotEmpty($persistedBids, 'At least one bid must be persisted.');

            // Invariant 1: auctions.current_highest_bid == MAX(auction_bids.bid_amount)
            $maxBidAmount = (float) $persistedBids->max('bid_amount');
            $this->assertEquals(
                $maxBidAmount,
                (float) $freshAuction->current_highest_bid,
                'Invariant 1: current_highest_bid must equal MAX(auction_bids.bid_amount).'
            );

            // Invariant 2: auctions.bid_count == COUNT(auction_bids)
            $this->assertEquals(
                $persistedBids->count(),
                $freshAuction->bid_count,
                'Invariant 2: bid_count must equal exact COUNT(auction_bids).'
            );

            // Invariant 3: auctions.leading_bidder_id == bidder_id of latest bid
            $latestBid = $persistedBids->last();
            $this->assertEquals(
                $latestBid->bidder_id,
                $freshAuction->leading_bidder_id,
                'Invariant 3: leading_bidder_id must correspond to the latest accepted bid.'
            );

            // Invariant 4: Monotonicity - each bid amount > previous_highest_bid
            foreach ($persistedBids as $b) {
                $this->assertGreaterThan(
                    (float) $b->previous_highest_bid,
                    (float) $b->bid_amount,
                    'Invariant 4: Bid amount must be strictly greater than previous_highest_bid.'
                );
            }

            // Invariant 5: Ledger immutability check
            $firstBid = $persistedBids->first();
            $immutableExceptionCaught = false;
            try {
                $firstBid->bid_amount = 999999.00;
                $firstBid->save();
            } catch (\LogicException $e) {
                $immutableExceptionCaught = true;
            }
            $this->assertTrue($immutableExceptionCaught, 'Invariant 5: AuctionBid must be immutable against updates.');
        } finally {
            $this->cleanUpBarrierFiles($barrierPath);
            $this->cleanUpAuction(
                $auction?->id,
                $product?->id,
                array_filter([$seller?->id, $bidder1?->id, $bidder2?->id])
            );

            // Invariant 6: Cleanup verification
            if ($auction) {
                $this->assertNull(Auction::find($auction->id), 'Cleanup Verification: Auction must be deleted.');
                $this->assertEquals(
                    0,
                    AuctionBid::where('auction_id', $auction->id)->count(),
                    'Cleanup Verification: Bids must be deleted.'
                );
            }
        }
    }
}
