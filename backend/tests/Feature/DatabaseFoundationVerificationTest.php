<?php

namespace Tests\Feature;

use App\Enums\AuctionStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\ProductStatus;
use App\Models\Auction;
use App\Models\AuctionBid;
use App\Models\AuditLog;
use App\Models\Category;
use App\Models\EscrowTransaction;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\PlatformSetting;
use App\Models\Product;
use App\Models\ProductModerationLog;
use App\Models\User;
use App\Models\WalletTransaction;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DatabaseFoundationVerificationTest extends TestCase
{
    /**
     * Helper to execute a callback within an isolated transaction and assert a DB constraint violation.
     */
    protected function assertThrowsConstraintViolation(callable $callback, string $expectedConstraint): void
    {
        DB::beginTransaction();
        try {
            $callback();
            $this->fail("Expected QueryException with constraint [{$expectedConstraint}] was not thrown.");
        } catch (QueryException $e) {
            DB::rollBack();
            $this->assertStringContainsString($expectedConstraint, $e->getMessage());
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * TC-P506-01: Verify all 34 domain tables and core column types exist in PostgreSQL 18.
     */
    public function test_all_34_domain_tables_and_column_types_exist(): void
    {
        $expectedTables = [
            'users', 'personal_access_tokens', 'password_reset_tokens', 'user_profiles',
            'seller_profiles', 'user_addresses', 'categories', 'brands', 'platform_settings',
            'audit_logs', 'products', 'product_images', 'product_moderation_logs',
            'auction_sessions', 'auctions', 'auction_bids', 'auction_watches', 'carts',
            'cart_items', 'orders', 'order_items', 'shipments', 'payments', 'escrow_transactions',
            'wallet_transactions', 'disputes', 'dispute_evidences', 'reviews', 'reports',
            'favorites', 'seller_follows', 'conversations', 'messages', 'notifications',
        ];

        $tablesInDb = collect(DB::select("
            SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'
        "))->pluck('table_name')->toArray();

        foreach ($expectedTables as $table) {
            $this->assertContains($table, $tablesInDb, "Table '{$table}' must exist in PostgreSQL 18 public schema.");
        }

        // Verify PostgreSQL 18 column types: NUMERIC(15,2), TIMESTAMPTZ, JSONB
        $ordersColumns = collect(DB::select("
            SELECT column_name, data_type, udt_name 
            FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'orders'
        "))->keyBy('column_name');

        $this->assertEquals('numeric', $ordersColumns['total_amount']->data_type);
        $this->assertEquals('timestamp with time zone', $ordersColumns['created_at']->data_type);
        $this->assertEquals('jsonb', $ordersColumns['shipping_address_snapshot']->data_type);
    }

    /**
     * TC-P506-02: Verify 12 platform settings and 10 standardized actors exist.
     */
    public function test_platform_settings_and_seeded_actors_exist(): void
    {
        // 12 Platform Settings
        $this->assertEquals(12, PlatformSetting::count());
        $this->assertEquals(0.06, (float) PlatformSetting::getValue('protection_fee_rate'));
        $this->assertEquals(7000.00, (float) PlatformSetting::getValue('protection_fixed_fee'));
        $this->assertEquals(0.00, (float) PlatformSetting::getValue('shipping_fee_default'));
        $this->assertEquals(0.00, (float) PlatformSetting::getValue('seller_commission_rate'));

        // 10 Standardized Users
        $this->assertEquals(10, User::count());

        $admin = User::where('email', 'admin@izithrift.local')->first();
        $this->assertNotNull($admin);
        $this->assertTrue($admin->isAdmin());

        $moderator = User::where('email', 'moderator@izithrift.local')->first();
        $this->assertNotNull($moderator);
        $this->assertTrue($moderator->isModerator());

        $support = User::where('email', 'support@izithrift.local')->first();
        $this->assertNotNull($support);
        $this->assertTrue($support->isSupport());

        $sellerA = User::where('email', 'gau.vintage@izithrift.local')->first();
        $this->assertNotNull($sellerA);
        $this->assertNotNull($sellerA->sellerProfile);

        $suspended = User::where('email', 'suspended.user@izithrift.local')->first();
        $this->assertNotNull($suspended);
        $this->assertFalse($suspended->isActive());
    }

    /**
     * TC-P506-03: Verify idempotent seeder execution produces zero duplicates.
     */
    public function test_idempotent_seeder_execution_produces_zero_duplicates(): void
    {
        $tables = [
            'users', 'seller_profiles', 'categories', 'brands', 'products',
            'product_images', 'auction_sessions', 'auctions', 'auction_bids',
            'orders', 'order_items', 'shipments', 'payments', 'escrow_transactions',
            'wallet_transactions', 'disputes', 'reviews',
        ];

        $countsBefore = [];
        foreach ($tables as $t) {
            $countsBefore[$t] = DB::table($t)->count();
        }

        // Re-run database seeder
        $this->seed(DatabaseSeeder::class);

        foreach ($tables as $t) {
            $countAfter = DB::table($t)->count();
            $this->assertEquals(
                $countsBefore[$t],
                $countAfter,
                "Table '{$t}' count changed after re-seeding (expected zero duplicate records)."
            );
        }
    }

    /**
     * TC-P506-04: Verify database CHECK constraints block self-transactions (BR-AC-02).
     */
    public function test_database_check_constraints_block_self_transactions(): void
    {
        $sellerA = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();

        // 1. Block Self-Purchase on orders (buyer_id == seller_id)
        $this->assertThrowsConstraintViolation(function () use ($sellerA) {
            DB::table('orders')->insert([
                'order_code' => 'ORD-ERR-SELF-BUY',
                'buyer_id' => $sellerA->id,
                'seller_id' => $sellerA->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 100000.00,
                'shipping_fee' => 0.00,
                'buyer_protection_fee' => 13000.00,
                'total_amount' => 113000.00,
                'seller_net_amount' => 100000.00,
                'shipping_address_snapshot' => json_encode(['address' => 'test']),
                'order_status' => 'PENDING_PAYMENT',
                'payment_status' => 'UNPAID',
                'escrow_status' => 'NONE',
                'dispute_status' => 'NONE',
                'payment_expires_at' => now()->addMinutes(30),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }, 'chk_orders_no_self_purchase');

        // 2. Block Self-Lead on auctions (leading_bidder_id == seller_id)
        $prd = Product::where('seller_id', $sellerA->id)->firstOrFail();
        $session = DB::table('auction_sessions')->first();
        $this->assertThrowsConstraintViolation(function () use ($prd, $sellerA, $session) {
            DB::table('auctions')->insert([
                'auction_code' => 'AUC-ERR-SELF-LEAD',
                'product_id' => $prd->id,
                'seller_id' => $sellerA->id,
                'session_id' => $session->id,
                'starting_price' => 100000.00,
                'min_bid_increment' => 10000.00,
                'current_highest_bid' => 100000.00,
                'leading_bidder_id' => $sellerA->id, // Violates constraint
                'auction_starts_at' => now(),
                'auction_ends_at' => now()->addHours(1),
                'status' => 'LIVE',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }, 'chk_auctions_no_seller_self_lead');

        // 3. Block Self-Review on reviews (reviewer_id == seller_id)
        $order = Order::where('seller_id', $sellerA->id)->firstOrFail();
        $this->assertThrowsConstraintViolation(function () use ($order, $prd, $sellerA) {
            DB::table('reviews')->insert([
                'order_id' => $order->id,
                'product_id' => $prd->id,
                'reviewer_id' => $sellerA->id, // Violates constraint
                'seller_id' => $sellerA->id,
                'rating' => 5,
                'comment' => 'Self review is illegal',
                'status' => 'VISIBLE',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }, 'chk_reviews_no_self_review');

        // 4. Block Self-Follow on seller_follows (follower_id == seller_id)
        $this->assertThrowsConstraintViolation(function () use ($sellerA) {
            DB::table('seller_follows')->insert([
                'follower_id' => $sellerA->id,
                'seller_id' => $sellerA->id, // Violates constraint
                'created_at' => now(),
            ]);
        }, 'chk_no_self_follow');
    }

    /**
     * TC-P506-05: Verify product & moderation check constraints.
     */
    public function test_product_and_moderation_check_constraints(): void
    {
        $sellerA = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $cat = Category::firstOrFail();

        // 1. Block empty defect_info on products
        $this->assertThrowsConstraintViolation(function () use ($sellerA, $cat) {
            DB::table('products')->insert([
                'product_code' => 'PRD-ERR-DEFECT',
                'seller_id' => $sellerA->id,
                'category_id' => $cat->id,
                'title' => 'Test Product',
                'slug' => 'test-product-defect-err',
                'description' => 'Test description',
                'condition' => 'GOOD',
                'defect_info' => '   ', // Blank
                'listing_type' => 'FIXED_PRICE',
                'price' => 100000.00,
                'total_quantity' => 1,
                'available_quantity' => 1,
                'status' => 'APPROVED',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }, 'chk_products_defect_not_empty');

        // 2. Block AUCTION listing with total_quantity != 1 (BR-PR-01)
        $this->assertThrowsConstraintViolation(function () use ($sellerA, $cat) {
            DB::table('products')->insert([
                'product_code' => 'PRD-ERR-AUC-QTY',
                'seller_id' => $sellerA->id,
                'category_id' => $cat->id,
                'title' => 'Test Auction Product',
                'slug' => 'test-auction-product-qty-err',
                'description' => 'Test description',
                'condition' => 'GOOD',
                'defect_info' => 'Không lỗi',
                'listing_type' => 'AUCTION',
                'price' => 100000.00,
                'total_quantity' => 2, // Must be 1 for auction
                'available_quantity' => 2,
                'status' => 'APPROVED',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }, 'chk_products_total_qty');

        // 3. Block REJECTED moderation log with empty reason (DEC-05)
        $prd1 = Product::where('product_code', 'PRD-2026-0001')->firstOrFail();
        $mod = User::where('role', 'moderator')->firstOrFail();
        $this->assertThrowsConstraintViolation(function () use ($prd1, $mod) {
            DB::table('product_moderation_logs')->insert([
                'product_id' => $prd1->id,
                'moderator_id' => $mod->id,
                'action' => 'REJECTED',
                'previous_status' => 'PENDING_REVIEW',
                'new_status' => 'REJECTED',
                'reason' => null, // Must not be null or blank
                'created_at' => now(),
            ]);
        }, 'chk_mod_logs_mandatory_reason');
    }

    /**
     * TC-P506-06: Verify partial unique index allows relist but blocks dual live auctions (DEC-02).
     */
    public function test_partial_unique_index_allows_relist_but_blocks_dual_live_auctions(): void
    {
        $sellerB = User::where('email', 'retrolab.sg@izithrift.local')->firstOrFail();
        $prd7 = Product::where('product_code', 'PRD-2026-0007')->firstOrFail(); // Has LIVE auction AUC-2026-0001
        $session = DB::table('auction_sessions')->first();

        // 1. Dual LIVE auction for same product must be blocked by uq_auctions_active_product
        $this->assertThrowsConstraintViolation(function () use ($prd7, $sellerB, $session) {
            DB::table('auctions')->insert([
                'auction_code' => 'AUC-ERR-DUAL-LIVE',
                'product_id' => $prd7->id,
                'seller_id' => $sellerB->id,
                'session_id' => $session->id,
                'starting_price' => 500000.00,
                'min_bid_increment' => 50000.00,
                'current_highest_bid' => 0.00,
                'auction_starts_at' => now(),
                'auction_ends_at' => now()->addHours(1),
                'status' => 'LIVE',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }, 'uq_auctions_active_product');

        // 2. Relist allowed when existing auction is ENDED_UNSOLD (AUC-2026-0005 with PRD-2026-0011)
        $prd11 = Product::where('product_code', 'PRD-2026-0011')->firstOrFail();
        $sellerC = User::where('email', 'tiemnhamay@izithrift.local')->firstOrFail();

        DB::beginTransaction();
        try {
            $relisted = DB::table('auctions')->insert([
                'auction_code' => 'AUC-TEST-RELIST-SUCCESS',
                'product_id' => $prd11->id,
                'seller_id' => $sellerC->id,
                'session_id' => $session->id,
                'starting_price' => 300000.00,
                'min_bid_increment' => 30000.00,
                'current_highest_bid' => 0.00,
                'auction_starts_at' => now()->addHours(2),
                'auction_ends_at' => now()->addHours(5),
                'status' => 'SCHEDULED', // Valid new scheduled auction for unsold item
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            $this->assertTrue($relisted, 'Relisting unsold auction product must succeed.');
        } finally {
            DB::rollBack();
        }
    }

    /**
     * TC-P506-07: Verify order financial equation & single paid payment index (DEC-04 & BR-FN-03).
     */
    public function test_order_financial_equation_and_single_paid_payment_index(): void
    {
        $sellerA = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $buyer1 = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();

        // 1. Block order with broken financial equation (total_amount != subtotal + shipping + fee)
        $this->assertThrowsConstraintViolation(function () use ($buyer1, $sellerA) {
            DB::table('orders')->insert([
                'order_code' => 'ORD-ERR-EQUATION',
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 500000.00,
                'shipping_fee' => 0.00,
                'buyer_protection_fee' => 37000.00,
                'total_amount' => 999999.00, // Invalid total
                'seller_net_amount' => 500000.00,
                'shipping_address_snapshot' => json_encode(['address' => 'test']),
                'order_status' => 'PENDING_PAYMENT',
                'payment_status' => 'UNPAID',
                'escrow_status' => 'NONE',
                'dispute_status' => 'NONE',
                'payment_expires_at' => now()->addMinutes(30),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }, 'chk_orders_total_equation');

        // 2. Block order where seller_net_amount != item_subtotal
        $this->assertThrowsConstraintViolation(function () use ($buyer1, $sellerA) {
            DB::table('orders')->insert([
                'order_code' => 'ORD-ERR-SELLER-NET',
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'order_source' => 'FIXED_PRICE',
                'item_subtotal' => 500000.00,
                'shipping_fee' => 0.00,
                'buyer_protection_fee' => 37000.00,
                'total_amount' => 537000.00,
                'seller_net_amount' => 450000.00, // Invalid net
                'shipping_address_snapshot' => json_encode(['address' => 'test']),
                'order_status' => 'PENDING_PAYMENT',
                'payment_status' => 'UNPAID',
                'escrow_status' => 'NONE',
                'dispute_status' => 'NONE',
                'payment_expires_at' => now()->addMinutes(30),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }, 'chk_orders_seller_net_100_percent');

        // 3. Block dual PAID payments on same order (uq_payments_one_paid_per_order)
        $ord6 = Order::where('order_code', 'ORD-2026-0006')->firstOrFail(); // Already has PAY-2026-0006 PAID
        $this->assertThrowsConstraintViolation(function () use ($ord6, $buyer1) {
            DB::table('payments')->insert([
                'payment_reference' => 'PAY-ERR-DUAL-PAID',
                'order_id' => $ord6->id,
                'payer_id' => $buyer1->id,
                'amount' => 537000.00,
                'qr_payload' => 'PAYLOAD-DUAL-TEST',
                'status' => 'PAID', // Violates partial unique index
                'expires_at' => now()->subDays(5),
                'paid_at' => now()->subDays(5),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }, 'uq_payments_one_paid_per_order');
    }

    /**
     * TC-P506-08: Verify escrow & wallet ledger accounting invariants and zero drift.
     */
    public function test_escrow_and_wallet_ledger_accounting_invariants(): void
    {
        $ord1 = Order::where('order_code', 'ORD-2026-0001')->firstOrFail();
        $buyer1 = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $sellerA = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();

        // 1. Block invalid escrow balance accounting (HOLD with non-zero released amount)
        $this->assertThrowsConstraintViolation(function () use ($ord1, $buyer1, $sellerA) {
            DB::table('escrow_transactions')->insert([
                'transaction_code' => 'ETX-ERR-HOLD-INVALID',
                'order_id' => $ord1->id,
                'buyer_id' => $buyer1->id,
                'seller_id' => $sellerA->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 431000.00,
                'item_subtotal_amount' => 400000.00,
                'buyer_protection_fee_amount' => 31000.00,
                'seller_released_amount' => 100000.00, // Invalid for HOLD
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'note' => 'Invalid HOLD test',
                'created_at' => now(),
            ]);
        }, 'chk_escrow_accounting_balance');

        // 2. Zero-Drift Ledger Audit on all 3 Sellers
        $sellers = User::whereHas('sellerProfile')->get();
        foreach ($sellers as $seller) {
            $sp = $seller->sellerProfile;

            // Wallet reconciliation
            $actualWalletTx = (float) WalletTransaction::where('seller_id', $seller->id)->sum('amount');
            $this->assertEquals((float) $sp->wallet_balance, $actualWalletTx, "Wallet balance drift on seller {$seller->email}");

            // Escrow held reconciliation
            $actualHeld = (float) Order::where('seller_id', $seller->id)
                ->where('escrow_status', EscrowStatus::HELD->value)
                ->sum('item_subtotal');
            $this->assertEquals((float) $sp->escrow_held_balance, $actualHeld, "Escrow held drift on seller {$seller->email}");
        }
    }

    /**
     * TC-P506-09: Verify immutable ledger models prevent update and delete.
     */
    public function test_immutable_ledger_models_prevent_update_and_delete(): void
    {
        // 1. EscrowTransaction
        $etx = EscrowTransaction::firstOrFail();
        try {
            $etx->update(['note' => 'Unauthorized update']);
            $this->fail('Expected LogicException on EscrowTransaction::update()');
        } catch (\LogicException $e) {
            $this->assertStringContainsString('Immutable ledger/audit record cannot be updated or deleted', $e->getMessage());
        }
        try {
            $etx->delete();
            $this->fail('Expected LogicException on EscrowTransaction::delete()');
        } catch (\LogicException $e) {
            $this->assertStringContainsString('Immutable ledger/audit record cannot be updated or deleted', $e->getMessage());
        }

        // 2. WalletTransaction
        $wtx = WalletTransaction::firstOrFail();
        try {
            $wtx->update(['description' => 'Unauthorized update']);
            $this->fail('Expected LogicException on WalletTransaction::update()');
        } catch (\LogicException $e) {
            $this->assertStringContainsString('Immutable ledger/audit record cannot be updated or deleted', $e->getMessage());
        }

        // 3. AuctionBid
        $bid = AuctionBid::firstOrFail();
        try {
            $bid->delete();
            $this->fail('Expected LogicException on AuctionBid::delete()');
        } catch (\LogicException $e) {
            $this->assertStringContainsString('Immutable ledger/audit record cannot be updated or deleted', $e->getMessage());
        }

        // 4. OrderItem
        $item = OrderItem::firstOrFail();
        try {
            $item->delete();
            $this->fail('Expected LogicException on OrderItem::delete()');
        } catch (\LogicException $e) {
            $this->assertStringContainsString('Immutable ledger/audit record cannot be updated or deleted', $e->getMessage());
        }

        // 5. ProductModerationLog
        $modLog = ProductModerationLog::firstOrFail();
        try {
            $modLog->update(['reason' => 'Unauthorized update']);
            $this->fail('Expected LogicException on ProductModerationLog::update()');
        } catch (\LogicException $e) {
            $this->assertStringContainsString('Immutable ledger/audit record cannot be updated or deleted', $e->getMessage());
        }

        // 6. AuditLog
        $audit = AuditLog::firstOrFail();
        try {
            $audit->delete();
            $this->fail('Expected LogicException on AuditLog::delete()');
        } catch (\LogicException $e) {
            $this->assertStringContainsString('Immutable ledger/audit record cannot be updated or deleted', $e->getMessage());
        }
    }

    /**
     * TC-P506-10: Verify foreign key ON DELETE RESTRICT protects transactional history.
     */
    public function test_foreign_key_on_delete_restrict_protects_transactional_history(): void
    {
        $buyer1 = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();

        // 1. Block deleting user who has existing orders
        $this->assertThrowsConstraintViolation(function () use ($buyer1) {
            DB::table('users')->where('id', $buyer1->id)->delete();
        }, 'foreign key constraint');

        // 2. Block deleting order which has payments / escrow records
        $ord6 = Order::where('order_code', 'ORD-2026-0006')->firstOrFail();
        $this->assertThrowsConstraintViolation(function () use ($ord6) {
            DB::table('orders')->where('id', $ord6->id)->delete();
        }, 'foreign key constraint');
    }

    /**
     * TC-P506-11: Verify pessimistic locking SELECT ... FOR UPDATE works on auctions and orders.
     */
    public function test_pessimistic_locking_select_for_update_works_on_auctions_and_orders(): void
    {
        DB::beginTransaction();

        DB::enableQueryLog();

        $auction = Auction::where('status', AuctionStatus::LIVE->value)
            ->lockForUpdate()
            ->first();
        $this->assertNotNull($auction);

        $order = Order::where('order_status', OrderStatus::PAID->value)
            ->lockForUpdate()
            ->first();
        $this->assertNotNull($order);

        $queries = DB::getQueryLog();
        DB::disableQueryLog();
        DB::rollBack();

        $auctionQuery = $queries[0]['query'] ?? '';
        $orderQuery = $queries[1]['query'] ?? '';

        $this->assertStringContainsStringIgnoringCase('for update', $auctionQuery, 'Auction lock query must include FOR UPDATE');
        $this->assertStringContainsStringIgnoringCase('for update', $orderQuery, 'Order lock query must include FOR UPDATE');
    }

    /**
     * TC-P506-12: Verify eager loading relationships without N+1 queries.
     */
    public function test_eager_loading_relationships_without_n_plus_one_queries(): void
    {
        DB::enableQueryLog();

        // 1. Fetching products with full relationships
        $products = Product::with(['seller.sellerProfile', 'category', 'brand', 'images'])
            ->where('status', ProductStatus::APPROVED->value)
            ->get();
        $this->assertGreaterThan(0, $products->count());

        $productQueriesCount = count(DB::getQueryLog());
        // Expected: 1 products + 1 users + 1 seller_profiles + 1 categories + 1 brands + 1 product_images = 6 queries
        $this->assertLessThanOrEqual(6, $productQueriesCount, 'Product eager loading must not produce N+1 query loop.');

        DB::flushQueryLog();

        // 2. Fetching orders with full relationships
        $orders = Order::with(['buyer', 'seller', 'items', 'shipment', 'payments', 'escrowTransactions', 'dispute'])
            ->get();
        $this->assertGreaterThanOrEqual(10, $orders->count());

        $orderQueriesCount = count(DB::getQueryLog());
        // Expected: 1 orders + 1 buyers + 1 sellers + 1 items + 1 shipments + 1 payments + 1 escrow + 1 disputes = 8 queries
        $this->assertLessThanOrEqual(8, $orderQueriesCount, 'Order eager loading must not produce N+1 query loop.');

        DB::disableQueryLog();
    }
}
