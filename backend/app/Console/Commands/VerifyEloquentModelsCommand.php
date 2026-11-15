<?php

namespace App\Console\Commands;

use App\Enums\ProductCondition;
use App\Enums\ProductStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Auction;
use App\Models\AuctionBid;
use App\Models\AuctionSession;
use App\Models\AuctionWatch;
use App\Models\AuditLog;
use App\Models\Brand;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Category;
use App\Models\Conversation;
use App\Models\Dispute;
use App\Models\DisputeEvidence;
use App\Models\EscrowTransaction;
use App\Models\Favorite;
use App\Models\Message;
use App\Models\Notification;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\PlatformSetting;
use App\Models\Product;
use App\Models\ProductImage;
use App\Models\ProductModerationLog;
use App\Models\Report;
use App\Models\Review;
use App\Models\SellerFollow;
use App\Models\SellerProfile;
use App\Models\Shipment;
use App\Models\User;
use App\Models\UserAddress;
use App\Models\UserProfile;
use App\Models\WalletTransaction;
use Illuminate\Console\Command;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use LogicException;

class VerifyEloquentModelsCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'model:verify-architecture';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Verify 32 Eloquent Domain Models, table mappings, relationship foreign keys, and immutability guards.';

    /**
     * The complete map of 32 models and their relationship methods.
     *
     * @var array<class-string, array<string>>
     */
    protected array $modelRelationMap = [
        User::class => [
            'profile', 'sellerProfile', 'addresses', 'cart', 'products',
            'auctionsAsSeller', 'auctionBids', 'auctionWatches', 'buyerOrders',
            'sellerOrders', 'walletTransactions', 'favorites', 'followingSellers',
            'followers', 'notifications', 'reviewsWritten', 'reviewsReceived',
        ],
        UserProfile::class => ['user'],
        SellerProfile::class => ['user'],
        UserAddress::class => ['user'],
        Category::class => ['parent', 'children', 'products'],
        Brand::class => ['products'],
        Product::class => [
            'seller', 'category', 'brand', 'approver', 'images', 'primaryImage',
            'moderationLogs', 'auctions', 'activeAuction', 'favorites', 'orderItems', 'reviews',
        ],
        ProductImage::class => ['product'],
        ProductModerationLog::class => ['product', 'moderator'],
        PlatformSetting::class => ['updater'],
        AuditLog::class => ['actor'],
        AuctionSession::class => ['creator', 'auctions'],
        Auction::class => [
            'product', 'seller', 'session', 'leadingBidder', 'winner',
            'bids', 'watches', 'order',
        ],
        AuctionBid::class => ['auction', 'bidder'],
        AuctionWatch::class => ['auction', 'user'],
        Cart::class => ['user', 'items'],
        CartItem::class => ['cart', 'product', 'seller'],
        Order::class => [
            'buyer', 'seller', 'auction', 'items', 'shipment', 'payments',
            'paidPayment', 'escrowTransactions', 'walletTransaction', 'dispute', 'review',
        ],
        OrderItem::class => ['order', 'product'],
        Shipment::class => ['order', 'updater'],
        Payment::class => ['order', 'payer', 'escrowTransactions'],
        EscrowTransaction::class => [
            'order', 'payment', 'buyer', 'seller', 'triggeredBy', 'walletTransaction',
        ],
        WalletTransaction::class => ['seller', 'order', 'escrowTransaction'],
        Dispute::class => [
            'order', 'buyer', 'seller', 'assignedSupport', 'resolvedByAdmin', 'evidences',
        ],
        DisputeEvidence::class => ['dispute', 'uploader'],
        Review::class => ['order', 'product', 'reviewer', 'seller', 'hiddenByUser'],
        Report::class => ['reporter', 'handler'],
        Favorite::class => ['user', 'product'],
        SellerFollow::class => ['follower', 'seller'],
        Conversation::class => [
            'userOne', 'userTwo', 'contextProduct', 'contextOrder', 'blockedByUser', 'messages',
        ],
        Message::class => ['conversation', 'sender', 'attachedProduct'],
        Notification::class => ['user'],
    ];

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info(str_repeat('=', 85));
        $this->info(' RETRO MARKET (izithrift) - ELOQUENT ARCHITECTURE & INTEGRITY VERIFICATION');
        $this->info(str_repeat('=', 85));

        $allPassed = true;

        // --------------------------------------------------------------------
        // CHECK 1: MODEL INSTANTIATION & SCHEMA COLUMN MAPPING
        // --------------------------------------------------------------------
        $this->line("\n<fg=yellow;options=bold>[CHECK 1] 32 ELOQUENT MODELS SCHEMA & FILLABLE MAPPING</>");
        $check1Rows = [];
        $modelCount = 0;

        foreach ($this->modelRelationMap as $modelClass => $relations) {
            $modelCount++;
            $instance = new $modelClass();
            $table = $instance->getTable();
            $columns = Schema::getColumnListing($table);
            $fillable = $instance->getFillable();

            $missingInDb = array_diff($fillable, $columns);
            $hasValidTable = Schema::hasTable($table);

            $status = ($hasValidTable && empty($missingInDb))
                ? '<fg=green;options=bold>PASS</>'
                : '<fg=red;options=bold>FAIL</>';

            if (! $hasValidTable || ! empty($missingInDb)) {
                $allPassed = false;
            }

            $check1Rows[] = [
                $modelCount,
                class_basename($modelClass),
                $table,
                count($fillable) . ' fields',
                empty($missingInDb) ? 'All columns exist' : 'Missing: ' . implode(',', $missingInDb),
                $status,
            ];
        }

        $this->table(['#', 'Model Class', 'Table', 'Fillable Count', 'Schema Match', 'Result'], $check1Rows);
        $this->info("Verified {$modelCount}/32 models mapped to PostgreSQL 18 schema.");

        // --------------------------------------------------------------------
        // CHECK 2: RELATIONSHIP SIGNATURES & FOREIGN KEY VERIFICATION
        // --------------------------------------------------------------------
        $this->line("\n<fg=yellow;options=bold>[CHECK 2] RELATIONSHIP SIGNATURES & FOREIGN KEY AUDIT</>");
        $totalRelations = 0;
        $invalidRelations = [];

        foreach ($this->modelRelationMap as $modelClass => $relations) {
            $instance = new $modelClass();

            foreach ($relations as $relationMethod) {
                $totalRelations++;

                if (! method_exists($instance, $relationMethod)) {
                    $invalidRelations[] = [class_basename($modelClass), $relationMethod, 'Method does not exist'];
                    $allPassed = false;
                    continue;
                }

                $relation = $instance->$relationMethod();

                if (! $relation instanceof Relation) {
                    $invalidRelations[] = [class_basename($modelClass), $relationMethod, 'Not an Eloquent Relation'];
                    $allPassed = false;
                    continue;
                }

                $foreignKey = $relation->getForeignKeyName();

                if ($relation instanceof BelongsTo) {
                    $localTable = $relation->getParent()->getTable();
                    if (! Schema::hasColumn($localTable, $foreignKey)) {
                        $invalidRelations[] = [class_basename($modelClass), $relationMethod, "Column {$foreignKey} missing in {$localTable}"];
                        $allPassed = false;
                    }
                } elseif ($relation instanceof HasOne || $relation instanceof HasMany) {
                    $relatedTable = $relation->getRelated()->getTable();
                    if (! Schema::hasColumn($relatedTable, $foreignKey)) {
                        $invalidRelations[] = [class_basename($modelClass), $relationMethod, "Column {$foreignKey} missing in {$relatedTable}"];
                        $allPassed = false;
                    }
                }
            }
        }

        if (empty($invalidRelations)) {
            $this->info("Verified {$totalRelations} relationship methods across all 32 models. <fg=green;options=bold>ALL PASS</>.");
        } else {
            $this->error('Found invalid relationships:');
            $this->table(['Model', 'Method', 'Issue'], $invalidRelations);
        }

        // --------------------------------------------------------------------
        // CHECK 3: AUTH PASSWORD NAME, CASTS & PLATFORM SETTING HELPER
        // --------------------------------------------------------------------
        $this->line("\n<fg=yellow;options=bold>[CHECK 3] AUTH CONFIG, CONVENIENCE HELPERS & PLATFORM SETTINGS</>");
        $check3Results = [];

        // 3a. User Auth Password Name
        $user = new User();
        $authPwdName = $user->getAuthPasswordName();
        $pwdPassed = ($authPwdName === 'password_hash');
        $check3Results[] = [
            'User::getAuthPasswordName()',
            'password_hash',
            $authPwdName,
            $pwdPassed ? '<fg=green;options=bold>PASS</>' : '<fg=red;options=bold>FAIL</>',
        ];

        // 3b. User Role Helpers
        $adminUser = new User(['role' => UserRole::ADMIN, 'status' => UserStatus::ACTIVE]);
        $rolePassed = $adminUser->isAdmin() && $adminUser->isInternalStaff() && $adminUser->isActive() && ! $adminUser->isModerator();
        $check3Results[] = [
            'User role helpers (isAdmin, isActive, isInternalStaff)',
            'true for ADMIN/ACTIVE',
            $rolePassed ? 'true' : 'false',
            $rolePassed ? '<fg=green;options=bold>PASS</>' : '<fg=red;options=bold>FAIL</>',
        ];

        // 3c. PlatformSetting::getValue('protection_fee_rate')
        $feeRate = PlatformSetting::getValue('protection_fee_rate');
        $feeRatePassed = ((float) $feeRate === 0.06);
        $check3Results[] = [
            'PlatformSetting::getValue("protection_fee_rate")',
            '0.06 (DECIMAL)',
            (string) $feeRate,
            $feeRatePassed ? '<fg=green;options=bold>PASS</>' : '<fg=red;options=bold>FAIL</>',
        ];

        // 3d. PlatformSetting::getValue integer cast
        $deadline = PlatformSetting::getValue('auction_payment_window_production_sec');
        $deadlinePassed = ($deadline === 1800);
        $check3Results[] = [
            'PlatformSetting::getValue("auction_payment_window_production_sec")',
            '1800 (INTEGER)',
            (string) $deadline,
            $deadlinePassed ? '<fg=green;options=bold>PASS</>' : '<fg=red;options=bold>FAIL</>',
        ];

        // 3e. Conversation::normalizeParticipants
        $normalized = Conversation::normalizeParticipants(42, 10);
        $normPassed = ($normalized === [10, 42]);
        $check3Results[] = [
            'Conversation::normalizeParticipants(42, 10)',
            '[10, 42]',
            json_encode($normalized),
            $normPassed ? '<fg=green;options=bold>PASS</>' : '<fg=red;options=bold>FAIL</>',
        ];

        $this->table(['Check', 'Expected', 'Actual', 'Result'], $check3Results);

        foreach ($check3Results as $r) {
            if (Str::contains($r[3], 'FAIL')) {
                $allPassed = false;
            }
        }

        // --------------------------------------------------------------------
        // CHECK 4: IMMUTABLE LEDGER RECORD GUARDS (UPDATING & DELETING)
        // --------------------------------------------------------------------
        $this->line("\n<fg=yellow;options=bold>[CHECK 4] IMMUTABLE LEDGER RECORD GUARDS (LOGIC EXCEPTION ON MUTATION)</>");
        $check4Results = [];

        DB::beginTransaction();
        try {
            // Seed a temp audit log
            $auditLog = AuditLog::create([
                'actor_id' => null,
                'actor_role' => 'admin',
                'action' => 'TEST_ACTION',
                'target_type' => 'SYSTEM',
                'target_id' => 1,
                'reason' => 'Testing immutability',
                'old_values' => ['status' => 'OLD'],
                'new_values' => ['status' => 'NEW'],
                'ip_address' => '127.0.0.1',
            ]);

            // Test 4a: Update on AuditLog
            $auditUpdateBlocked = false;
            try {
                $auditLog->update(['action' => 'MUTATED_ACTION']);
            } catch (LogicException $e) {
                $auditUpdateBlocked = Str::contains($e->getMessage(), 'Immutable ledger');
            }
            $check4Results[] = [
                'AuditLog->update()',
                'LogicException (Immutable record)',
                $auditUpdateBlocked ? '<fg=green;options=bold>BLOCKED [PASS]</>' : '<fg=red;options=bold>ALLOWED [FAIL]</>',
            ];

            // Test 4b: Delete on AuditLog
            $auditDeleteBlocked = false;
            try {
                $auditLog->delete();
            } catch (LogicException $e) {
                $auditDeleteBlocked = Str::contains($e->getMessage(), 'Immutable ledger');
            }
            $check4Results[] = [
                'AuditLog->delete()',
                'LogicException (Immutable record)',
                $auditDeleteBlocked ? '<fg=green;options=bold>BLOCKED [PASS]</>' : '<fg=red;options=bold>ALLOWED [FAIL]</>',
            ];

            // Setup valid prerequisite records for EscrowTransaction
            $seller = User::create([
                'display_name' => 'Seller',
                'email' => 'seller_imm_' . Str::random(5) . '@retro.local',
                'password_hash' => bcrypt('password'),
                'role' => UserRole::REGISTERED_USER,
                'status' => UserStatus::ACTIVE,
            ]);

            $buyer = User::create([
                'display_name' => 'Buyer',
                'email' => 'buyer_imm_' . Str::random(5) . '@retro.local',
                'password_hash' => bcrypt('password'),
                'role' => UserRole::REGISTERED_USER,
                'status' => UserStatus::ACTIVE,
            ]);

            $order = Order::create([
                'order_code' => 'ORD-IMM-' . Str::upper(Str::random(6)),
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
                'shipping_address_snapshot' => ['address' => 'Hanoi'],
                'payment_expires_at' => now()->addMinutes(30),
            ]);

            $escrowTx = EscrowTransaction::create([
                'transaction_code' => 'ETX-IMM-' . Str::upper(Str::random(6)),
                'order_id' => $order->id,
                'buyer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'transaction_type' => 'HOLD',
                'gross_amount' => 113000.00,
                'item_subtotal_amount' => 100000.00,
                'buyer_protection_fee_amount' => 13000.00,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'note' => 'Hold payment',
            ]);

            // Test 4c: Update on EscrowTransaction
            $escrowUpdateBlocked = false;
            try {
                $escrowTx->update(['note' => 'HACKED_NOTE']);
            } catch (LogicException $e) {
                $escrowUpdateBlocked = Str::contains($e->getMessage(), 'Immutable ledger');
            }
            $check4Results[] = [
                'EscrowTransaction->update()',
                'LogicException (Immutable record)',
                $escrowUpdateBlocked ? '<fg=green;options=bold>BLOCKED [PASS]</>' : '<fg=red;options=bold>ALLOWED [FAIL]</>',
            ];

            // Test 4d: Delete on EscrowTransaction
            $escrowDeleteBlocked = false;
            try {
                $escrowTx->delete();
            } catch (LogicException $e) {
                $escrowDeleteBlocked = Str::contains($e->getMessage(), 'Immutable ledger');
            }
            $check4Results[] = [
                'EscrowTransaction->delete()',
                'LogicException (Immutable record)',
                $escrowDeleteBlocked ? '<fg=green;options=bold>BLOCKED [PASS]</>' : '<fg=red;options=bold>ALLOWED [FAIL]</>',
            ];

            // Test 4e: ProductModerationLog Update
            $category = Category::create([
                'name' => 'Imm Cat',
                'slug' => 'imm-cat-' . Str::random(5),
            ]);

            $product = Product::create([
                'product_code' => 'PRD-IMM-' . Str::upper(Str::random(5)),
                'seller_id' => $seller->id,
                'category_id' => $category->id,
                'title' => 'Imm Product',
                'slug' => 'imm-product-' . Str::random(5),
                'description' => 'Test',
                'condition' => ProductCondition::GOOD,
                'defect_info' => 'Wear and tear',
                'listing_type' => 'FIXED_PRICE',
                'price' => 50000.00,
                'total_quantity' => 1,
                'available_quantity' => 1,
                'status' => ProductStatus::APPROVED,
            ]);

            $modLog = ProductModerationLog::create([
                'product_id' => $product->id,
                'moderator_id' => $seller->id,
                'action' => 'APPROVED',
                'previous_status' => 'PENDING_REVIEW',
                'new_status' => 'APPROVED',
                'reason' => 'Looks authentic',
            ]);

            $modUpdateBlocked = false;
            try {
                $modLog->update(['reason' => 'Mutated reason']);
            } catch (LogicException $e) {
                $modUpdateBlocked = Str::contains($e->getMessage(), 'Immutable ledger');
            }
            $check4Results[] = [
                'ProductModerationLog->update()',
                'LogicException (Immutable record)',
                $modUpdateBlocked ? '<fg=green;options=bold>BLOCKED [PASS]</>' : '<fg=red;options=bold>ALLOWED [FAIL]</>',
            ];

        } finally {
            DB::rollBack();
        }

        $this->table(['Operation Attempted', 'Expected Behavior', 'Result'], $check4Results);

        foreach ($check4Results as $r) {
            if (Str::contains($r[2], 'FAIL')) {
                $allPassed = false;
            }
        }

        // Final verdict
        if ($allPassed) {
            $this->info("\n" . str_repeat('=', 85));
            $this->info(' ✅ ALL 4 ARCHITECTURAL CHECKS PASSED');
            $this->info(' 32 Eloquent Models fully verified with PostgreSQL 18 & Immutability Trait!');
            $this->info(str_repeat('=', 85) . "\n");
            return Command::SUCCESS;
        }

        $this->error("\nSome architectural checks failed! Review the tables above.");
        return Command::FAILURE;
    }
}
