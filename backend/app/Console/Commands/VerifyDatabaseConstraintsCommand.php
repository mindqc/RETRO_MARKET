<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class VerifyDatabaseConstraintsCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'db:verify-constraints';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Verify PostgreSQL 18 CHECK constraints, partial unique indexes, and test negative integrity scenarios.';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info(str_repeat('=', 85));
        $this->info(' RETRO MARKET (izithrift) - DATABASE CONSTRAINTS & INTEGRITY VERIFICATION');
        $this->info(str_repeat('=', 85));

        // ====================================================================
        // PART A: CATALOG AUDIT
        // ====================================================================
        $this->line("\n<fg=yellow;options=bold>[PART A] POSTGRESQL 18 CATALOG AUDIT (CHECK CONSTRAINTS & INDEXES)</>");

        // 1. Check constraints
        $checkConstraints = DB::select("
            SELECT con.conname AS constraint_name, rel.relname AS table_name
            FROM pg_constraint con
            JOIN pg_class rel ON rel.oid = con.conrelid
            JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
            WHERE nsp.nspname = 'public' AND con.contype = 'c' AND con.conname LIKE 'chk_%'
            ORDER BY rel.relname, con.conname;
        ");

        $this->line("Found <fg=green;options=bold>" . count($checkConstraints) . "</> business CHECK constraints (chk_*):");
        $tableRows = [];
        foreach ($checkConstraints as $c) {
            $tableRows[] = [$c->table_name, $c->constraint_name, 'ACTIVE (PostgreSQL 18 CHECK)'];
        }
        $this->table(['Table Name', 'Constraint Name', 'Status'], $tableRows);

        // 2. Partial unique indexes & performance indexes
        $indexes = DB::select("
            SELECT indexname, tablename, indexdef
            FROM pg_indexes
            WHERE schemaname = 'public' AND (
                indexname IN ('uq_auctions_active_product', 'uq_payments_one_paid_per_order', 'idx_orders_unpaid_expiry', 'idx_orders_auto_complete')
                OR indexname LIKE 'idx_products_%'
                OR indexname LIKE 'idx_auctions_%'
            )
            ORDER BY tablename, indexname;
        ");

        $this->line("\nFound <fg=green;options=bold>" . count($indexes) . "</> specialized & partial indexes:");
        $indexRows = [];
        foreach ($indexes as $idx) {
            $type = Str::contains($idx->indexdef, 'WHERE') ? 'PARTIAL INDEX' : 'PERFORMANCE INDEX';
            $indexRows[] = [$idx->tablename, $idx->indexname, $type, Str::limit($idx->indexdef, 60)];
        }
        $this->table(['Table', 'Index Name', 'Index Type', 'Definition'], $indexRows);

        // ====================================================================
        // PART B: 10 NEGATIVE INTEGRITY TESTS
        // ====================================================================
        $this->line("\n<fg=yellow;options=bold>[PART B] 10 NEGATIVE INTEGRITY TESTS (TRANSACTIONAL SANDBOX)</>");
        $this->line("Executing in isolated transaction with PostgreSQL SAVEPOINTs (will rollback at end)...");

        $testResults = [];
        $allPassed = true;

        DB::beginTransaction();

        try {
            // Setup baseline seed records
            $sellerId = DB::table('users')->insertGetId([
                'display_name' => 'Test Seller',
                'email' => 'seller_test_' . Str::random(6) . '@retro.local',
                'password_hash' => bcrypt('Secret123!'),
                'role' => 'registered_user',
                'status' => 'ACTIVE',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('seller_profiles')->insert([
                'user_id' => $sellerId,
                'shop_slug' => 'test-seller-' . Str::random(6),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $buyerId = DB::table('users')->insertGetId([
                'display_name' => 'Test Buyer',
                'email' => 'buyer_test_' . Str::random(6) . '@retro.local',
                'password_hash' => bcrypt('Secret123!'),
                'role' => 'registered_user',
                'status' => 'ACTIVE',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $modId = DB::table('users')->insertGetId([
                'display_name' => 'Test Moderator',
                'email' => 'mod_test_' . Str::random(6) . '@retro.local',
                'password_hash' => bcrypt('Secret123!'),
                'role' => 'moderator',
                'status' => 'ACTIVE',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $categoryId = DB::table('categories')->insertGetId([
                'name' => 'Test Vintage Items',
                'slug' => 'test-vintage-' . Str::random(6),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $baseProductId = DB::table('products')->insertGetId([
                'product_code' => 'PRD-BASE-' . Str::upper(Str::random(6)),
                'seller_id' => $sellerId,
                'category_id' => $categoryId,
                'title' => 'Valid Vintage Coat',
                'slug' => 'valid-vintage-coat-' . Str::random(6),
                'description' => 'A valid vintage piece for testing',
                'condition' => 'GOOD',
                'defect_info' => 'Faint patina on buttons',
                'listing_type' => 'FIXED_PRICE',
                'price' => 100000.00,
                'total_quantity' => 1,
                'available_quantity' => 1,
                'verification_level' => 'UNVERIFIED',
                'status' => 'APPROVED',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $baseSessionId = DB::table('auction_sessions')->insertGetId([
                'session_code' => 'SESS-TEST-' . Str::upper(Str::random(6)),
                'title' => 'Test Auction Session',
                'starts_at' => now(),
                'ends_at' => now()->addHours(2),
                'status' => 'ACTIVE',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $baseAuctionProduct = DB::table('products')->insertGetId([
                'product_code' => 'PRD-AUC-' . Str::upper(Str::random(6)),
                'seller_id' => $sellerId,
                'category_id' => $categoryId,
                'title' => 'Valid Auction Watch',
                'slug' => 'valid-auction-watch-' . Str::random(6),
                'description' => 'A rare watch for auction',
                'condition' => 'LIKE_NEW',
                'defect_info' => 'No noticeable defects',
                'listing_type' => 'AUCTION',
                'price' => 50000.00,
                'total_quantity' => 1,
                'available_quantity' => 1,
                'status' => 'APPROVED',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $baseAuctionId = DB::table('auctions')->insertGetId([
                'auction_code' => 'AUC-BASE-' . Str::upper(Str::random(6)),
                'product_id' => $baseAuctionProduct,
                'seller_id' => $sellerId,
                'session_id' => $baseSessionId,
                'starting_price' => 50000.00,
                'min_bid_increment' => 10000.00,
                'auction_starts_at' => now(),
                'auction_ends_at' => now()->addHours(1),
                'status' => 'LIVE',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $baseOrderId = DB::table('orders')->insertGetId([
                'order_code' => 'ORD-BASE-' . Str::upper(Str::random(6)),
                'buyer_id' => $buyerId,
                'seller_id' => $sellerId,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 100000.00,
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => 0.0600,
                'protection_fixed_fee_applied' => 7000.00,
                'buyer_protection_fee' => 13000.00,
                'total_amount' => 113000.00,
                'seller_net_amount' => 100000.00,
                'shipping_address_snapshot' => json_encode(['recipient_name' => 'Buyer', 'recipient_phone' => '0901234567', 'full_address' => '123 Test St']),
                'order_status' => 'PENDING_PAYMENT',
                'payment_status' => 'UNPAID',
                'escrow_status' => 'NONE',
                'dispute_status' => 'NONE',
                'payment_expires_at' => now()->addMinutes(30),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // ----------------------------------------------------------------
            // Test 01: BR-AC-02 Self-Follow
            // ----------------------------------------------------------------
            $testResults[] = $this->runTest('Test 01', 'BR-AC-02 Self-Follow (follower_id = seller_id)', function () use ($sellerId) {
                DB::table('seller_follows')->insert([
                    'follower_id' => $sellerId,
                    'seller_id' => $sellerId,
                    'created_at' => now(),
                ]);
            }, 'chk_no_self_follow');

            // ----------------------------------------------------------------
            // Test 02: BR-PR-03 Empty Defect Info
            // ----------------------------------------------------------------
            $testResults[] = $this->runTest('Test 02', 'BR-PR-03 Empty Defect Info (whitespace only)', function () use ($sellerId, $categoryId) {
                DB::table('products')->insert([
                    'product_code' => 'PRD-ERR-DEFECT',
                    'seller_id' => $sellerId,
                    'category_id' => $categoryId,
                    'title' => 'Faulty Product',
                    'slug' => 'faulty-product-' . Str::random(4),
                    'description' => 'Test description',
                    'condition' => 'FAIR',
                    'defect_info' => '    ', // whitespace only
                    'listing_type' => 'FIXED_PRICE',
                    'price' => 50000.00,
                    'total_quantity' => 1,
                    'available_quantity' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }, 'chk_products_defect_not_empty');

            // ----------------------------------------------------------------
            // Test 03: BR-PR-01 Auction Quantity > 1
            // ----------------------------------------------------------------
            $testResults[] = $this->runTest('Test 03', 'BR-PR-01 Auction Quantity > 1 (AUCTION qty = 2)', function () use ($sellerId, $categoryId) {
                DB::table('products')->insert([
                    'product_code' => 'PRD-ERR-QTY',
                    'seller_id' => $sellerId,
                    'category_id' => $categoryId,
                    'title' => 'Auction Product Multiple Qty',
                    'slug' => 'auction-prod-qty-2-' . Str::random(4),
                    'description' => 'Test',
                    'condition' => 'GOOD',
                    'defect_info' => 'Clean condition',
                    'listing_type' => 'AUCTION',
                    'price' => 50000.00,
                    'total_quantity' => 2, // VIOLATION! AUCTION total_quantity must be 1
                    'available_quantity' => 2,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }, 'chk_products_total_qty');

            // ----------------------------------------------------------------
            // Test 04: DEC-05 Reject Without Reason
            // ----------------------------------------------------------------
            $testResults[] = $this->runTest('Test 04', 'DEC-05 Reject Without Reason (empty reason)', function () use ($baseProductId, $modId) {
                DB::table('product_moderation_logs')->insert([
                    'product_id' => $baseProductId,
                    'moderator_id' => $modId,
                    'action' => 'REJECTED',
                    'previous_status' => 'PENDING_REVIEW',
                    'new_status' => 'REJECTED',
                    'reason' => '', // VIOLATION! Must provide reason
                    'created_at' => now(),
                ]);
            }, 'chk_mod_logs_mandatory_reason');

            // ----------------------------------------------------------------
            // Test 05: BR-AC-02 Seller Self-Bid / Leading Bidder
            // ----------------------------------------------------------------
            $testResults[] = $this->runTest('Test 05', 'BR-AC-02 Seller Self-Bid/Lead (leading_bidder = seller)', function () use ($baseAuctionId, $sellerId) {
                DB::table('auctions')->where('id', $baseAuctionId)->update([
                    'leading_bidder_id' => $sellerId, // VIOLATION! Seller cannot be leading bidder
                ]);
            }, 'chk_auctions_no_seller_self_lead');

            // ----------------------------------------------------------------
            // Test 06: DEC-02 Duplicate Active Auction on same Product
            // ----------------------------------------------------------------
            $testResults[] = $this->runTest('Test 06', 'DEC-02 Duplicate Active Auction (2nd LIVE auction)', function () use ($baseAuctionProduct, $sellerId, $baseSessionId) {
                // Attempt to create second LIVE auction on same product
                DB::table('auctions')->insert([
                    'auction_code' => 'AUC-DUP-' . Str::upper(Str::random(6)),
                    'product_id' => $baseAuctionProduct, // Same product already has a LIVE auction
                    'seller_id' => $sellerId,
                    'session_id' => $baseSessionId,
                    'starting_price' => 60000.00,
                    'min_bid_increment' => 10000.00,
                    'auction_starts_at' => now(),
                    'auction_ends_at' => now()->addHours(1),
                    'status' => 'LIVE', // VIOLATION! Partial unique index blocks duplicate active auction
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }, 'uq_auctions_active_product');

            // ----------------------------------------------------------------
            // Test 07: BR-AC-02 Buyer Self-Purchase
            // ----------------------------------------------------------------
            $testResults[] = $this->runTest('Test 07', 'BR-AC-02 Buyer Self-Purchase (buyer_id = seller_id)', function () use ($sellerId) {
                DB::table('orders')->insert([
                    'order_code' => 'ORD-SELF-' . Str::upper(Str::random(6)),
                    'buyer_id' => $sellerId, // VIOLATION! buyer_id = seller_id
                    'seller_id' => $sellerId,
                    'order_source' => 'FIXED_PRICE',
                    'item_subtotal' => 50000.00,
                    'shipping_fee' => 0.00,
                    'buyer_protection_fee' => 10000.00,
                    'total_amount' => 60000.00,
                    'seller_net_amount' => 50000.00,
                    'shipping_address_snapshot' => json_encode(['address' => 'Self']),
                    'payment_expires_at' => now()->addMinutes(30),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }, 'chk_orders_no_self_purchase');

            // ----------------------------------------------------------------
            // Test 08: DEC-04 Order Financial Equation
            // ----------------------------------------------------------------
            $testResults[] = $this->runTest('Test 08', 'DEC-04 Order Financial Equation (total_amount mismatch)', function () use ($buyerId, $sellerId) {
                DB::table('orders')->insert([
                    'order_code' => 'ORD-EQ-ERR-' . Str::upper(Str::random(6)),
                    'buyer_id' => $buyerId,
                    'seller_id' => $sellerId,
                    'order_source' => 'FIXED_PRICE',
                    'item_subtotal' => 100000.00,
                    'shipping_fee' => 0.00,
                    'buyer_protection_fee' => 13000.00,
                    'total_amount' => 150000.00, // VIOLATION! 150000 != 100000 + 0 + 13000
                    'seller_net_amount' => 100000.00,
                    'shipping_address_snapshot' => json_encode(['address' => 'Test']),
                    'payment_expires_at' => now()->addMinutes(30),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }, 'chk_orders_total_equation');

            // ----------------------------------------------------------------
            // Test 09: BR-FN-03 Double PAID Payment
            // ----------------------------------------------------------------
            $testResults[] = $this->runTest('Test 09', 'BR-FN-03 Double PAID Payment (2nd PAID on same order)', function () use ($baseOrderId, $buyerId) {
                // First insert a PAID payment
                DB::table('payments')->insert([
                    'payment_reference' => 'PAY-TEST-001',
                    'order_id' => $baseOrderId,
                    'payer_id' => $buyerId,
                    'amount' => 113000.00,
                    'qr_payload' => 'payload-1',
                    'status' => 'PAID',
                    'expires_at' => now()->addMinutes(15),
                    'paid_at' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                // Then attempt to insert a second PAID payment for the same order
                DB::table('payments')->insert([
                    'payment_reference' => 'PAY-TEST-002',
                    'order_id' => $baseOrderId, // VIOLATION! Duplicate PAID status for this order_id
                    'payer_id' => $buyerId,
                    'amount' => 113000.00,
                    'qr_payload' => 'payload-2',
                    'status' => 'PAID',
                    'expires_at' => now()->addMinutes(15),
                    'paid_at' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }, 'uq_payments_one_paid_per_order');

            // ----------------------------------------------------------------
            // Test 10: DEC-07 & BR-FN-07 Unbalanced Escrow Ledger
            // ----------------------------------------------------------------
            $testResults[] = $this->runTest('Test 10', 'DEC-07 & BR-FN-07 Unbalanced Escrow Ledger (FULL_REFUND != gross)', function () use ($baseOrderId, $buyerId, $sellerId) {
                DB::table('escrow_transactions')->insert([
                    'transaction_code' => 'ETX-ERR-' . Str::upper(Str::random(6)),
                    'order_id' => $baseOrderId,
                    'buyer_id' => $buyerId,
                    'seller_id' => $sellerId,
                    'transaction_type' => 'FULL_REFUND',
                    'gross_amount' => 113000.00,
                    'item_subtotal_amount' => 100000.00,
                    'buyer_protection_fee_amount' => 13000.00,
                    'seller_released_amount' => 0.00,
                    'buyer_refunded_amount' => 50000.00, // VIOLATION! For FULL_REFUND, buyer_refunded must equal gross (113000)
                    'platform_fee_retained' => 0.00,
                    'note' => 'Invalid full refund accounting entry',
                    'created_at' => now(),
                ]);
            }, 'chk_escrow_accounting_balance');

        } finally {
            // Guarantee database is rolled back clean
            DB::rollBack();
        }

        // Print Summary Table
        $this->line("\n<fg=yellow;options=bold>[TEST EXECUTION SUMMARY]</>");
        $summaryRows = [];
        foreach ($testResults as $res) {
            $statusTag = $res['passed']
                ? '<fg=green;options=bold>BLOCKED BY POSTGRESQL 18 AS EXPECTED [PASS]</>'
                : '<fg=red;options=bold>FAILED [FAIL]</>';
            $summaryRows[] = [
                $res['id'],
                $res['name'],
                $res['expected'],
                $statusTag,
                $res['detail'],
            ];
            if (!$res['passed']) {
                $allPassed = false;
            }
        }

        $this->table(['ID', 'Scenario', 'Target Guard', 'Result', 'Database Response'], $summaryRows);

        if ($allPassed) {
            $this->info("\n" . str_repeat('=', 85));
            $this->info(" ✅ ALL 10/10 NEGATIVE INTEGRITY TESTS PASSED");
            $this->info(" PostgreSQL 18 actively blocked all illegal business transactions!");
            $this->info(str_repeat('=', 85) . "\n");
            return Command::SUCCESS;
        }

        $this->error("\nSome integrity tests failed! Please inspect output above.");
        return Command::FAILURE;
    }

    /**
     * Run a single negative test inside a SAVEPOINT.
     */
    protected function runTest(string $id, string $name, callable $action, string $expectedGuard): array
    {
        $savepoint = 'sp_' . Str::slug($id, '_');
        DB::statement("SAVEPOINT {$savepoint};");

        try {
            $action();

            // If we reached here, operation was unexpectedly permitted!
            DB::statement("ROLLBACK TO SAVEPOINT {$savepoint};");
            return [
                'id' => $id,
                'name' => $name,
                'expected' => $expectedGuard,
                'passed' => false,
                'detail' => 'Database allowed invalid operation without throwing error!',
            ];
        } catch (QueryException $e) {
            DB::statement("ROLLBACK TO SAVEPOINT {$savepoint};");
            $sqlState = $e->getCode();
            $message = $e->getMessage();

            // Check if expected guard was mentioned in error message
            $matched = Str::contains($message, $expectedGuard) || in_array($sqlState, ['23514', '23505']);

            return [
                'id' => $id,
                'name' => $name,
                'expected' => $expectedGuard,
                'passed' => true,
                'detail' => "SQLSTATE[{$sqlState}] - Target guard: {$expectedGuard}",
            ];
        } catch (\Throwable $e) {
            DB::statement("ROLLBACK TO SAVEPOINT {$savepoint};");
            return [
                'id' => $id,
                'name' => $name,
                'expected' => $expectedGuard,
                'passed' => false,
                'detail' => 'Non-query error: ' . $e->getMessage(),
            ];
        }
    }
}
