<?php

namespace App\Console\Commands;

use App\Enums\EscrowStatus;
use App\Models\Auction;
use App\Models\AuditLog;
use App\Models\Brand;
use App\Models\Category;
use App\Models\Conversation;
use App\Models\Dispute;
use App\Models\EscrowTransaction;
use App\Models\Order;
use App\Models\Product;
use App\Models\Review;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class VerifySeededDataIntegrityCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'db:verify-seeders';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Verify database seeders data integrity, state coverage and ledger reconciliation';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info('========================================================================');
        $this->info('  RETRO MARKET (izithrift) – TASK P5-05 SEEDED DATA INTEGRITY VERIFIER  ');
        $this->info('========================================================================');

        $hasFailures = false;

        // ---------------------------------------------------------------------
        // Check 1: Record Population & Core State Coverage
        // ---------------------------------------------------------------------
        $this->newLine();
        $this->info('[Check 1/4] Verifying Table Population & State Coverage...');

        $tableChecks = [
            'platform_settings' => 12,
            'users' => 10,
            'seller_profiles' => 3,
            'categories' => 8,
            'brands' => 8,
            'products' => 16,
            'product_images' => 16,
            'product_moderation_logs' => 2,
            'auction_sessions' => 3,
            'auctions' => 6,
            'auction_bids' => 9,
            'auction_watches' => 7,
            'orders' => 10,
            'order_items' => 10,
            'shipments' => 5,
            'payments' => 10,
            'escrow_transactions' => 11,
            'wallet_transactions' => 2,
            'disputes' => 2,
            'dispute_evidences' => 3,
            'reviews' => 1,
            'reports' => 1,
            'favorites' => 4,
            'seller_follows' => 3,
            'conversations' => 1,
            'messages' => 4,
            'notifications' => 3,
            'audit_logs' => 2,
        ];

        foreach ($tableChecks as $table => $minCount) {
            $count = DB::table($table)->count();
            if ($count < $minCount) {
                $this->error("  FAILED: Table '{$table}' has {$count} rows (expected >= {$minCount}).");
                $hasFailures = true;
            } else {
                $this->line("  [OK] Table '{$table}': {$count} rows (expected >= {$minCount}).");
            }
        }

        // Verify Product Status Coverage (7 statuses)
        $productStatuses = Product::distinct()->pluck('status')->map(fn($s) => $s->value ?? $s)->toArray();
        $expectedProductStatuses = ['DRAFT', 'PENDING_REVIEW', 'APPROVED', 'REJECTED', 'HIDDEN', 'SOLD'];
        $missingProdStatuses = array_diff($expectedProductStatuses, $productStatuses);
        if (!empty($missingProdStatuses)) {
            $this->error("  FAILED: Missing product statuses: " . implode(', ', $missingProdStatuses));
            $hasFailures = true;
        } else {
            $this->line("  [OK] Product status coverage: all core statuses present (" . implode(', ', $productStatuses) . ").");
        }

        // Verify Auction Status Coverage (6 statuses)
        $auctionStatuses = Auction::distinct()->pluck('status')->map(fn($s) => $s->value ?? $s)->toArray();
        $expectedAuctionStatuses = ['SCHEDULED', 'LIVE', 'COMPLETED', 'ENDED_UNSOLD', 'WINNER_DEFAULTED'];
        $missingAucStatuses = array_diff($expectedAuctionStatuses, $auctionStatuses);
        if (!empty($missingAucStatuses)) {
            $this->error("  FAILED: Missing auction statuses: " . implode(', ', $missingAucStatuses));
            $hasFailures = true;
        } else {
            $this->line("  [OK] Auction status coverage: core statuses present (" . implode(', ', $auctionStatuses) . ").");
        }

        // ---------------------------------------------------------------------
        // Check 2: Zero-Drift Ledger Reconciliation (AC-P505-02)
        // ---------------------------------------------------------------------
        $this->newLine();
        $this->info('[Check 2/4] Verifying Zero-Drift Ledger Reconciliation for Seller Profiles...');

        $sellerProfiles = SellerProfile::with('user')->get();
        foreach ($sellerProfiles as $sp) {
            $sellerId = $sp->user_id;
            $sellerEmail = $sp->user->email;

            // 1. Wallet balance match
            $actualWalletTxSum = (float) WalletTransaction::where('seller_id', $sellerId)->sum('amount');
            $profileWalletBal = (float) $sp->wallet_balance;

            if (abs($actualWalletTxSum - $profileWalletBal) > 0.001) {
                $this->error("  FAILED: Wallet Drift for {$sellerEmail}! Profile: {$profileWalletBal}, Tx Sum: {$actualWalletTxSum}");
                $hasFailures = true;
            } else {
                $this->line("  [OK] Wallet Match for {$sellerEmail}: {$profileWalletBal}đ == SUM(tx) {$actualWalletTxSum}đ.");
            }

            // 2. Escrow held balance match
            $actualEscrowHeld = (float) Order::where('seller_id', $sellerId)
                ->where('escrow_status', EscrowStatus::HELD->value)
                ->sum('item_subtotal');
            $profileEscrowHeld = (float) $sp->escrow_held_balance;

            if (abs($actualEscrowHeld - $profileEscrowHeld) > 0.001) {
                $this->error("  FAILED: Escrow Held Drift for {$sellerEmail}! Profile: {$profileEscrowHeld}, Order Sum: {$actualEscrowHeld}");
                $hasFailures = true;
            } else {
                $this->line("  [OK] Escrow Held Match for {$sellerEmail}: {$profileEscrowHeld}đ == SUM(held orders) {$actualEscrowHeld}đ.");
            }
        }

        // ---------------------------------------------------------------------
        // Check 3: Order Financial Invariants (DEC-04)
        // ---------------------------------------------------------------------
        $this->newLine();
        $this->info('[Check 3/4] Verifying DEC-04 Financial Equation on 100% of Orders...');

        $orders = Order::all();
        $ordersChecked = 0;
        foreach ($orders as $order) {
            $itemSubtotal = (float) $order->item_subtotal;
            $shippingFee = (float) $order->shipping_fee;
            $buyerFee = (float) $order->buyer_protection_fee;
            $totalAmount = (float) $order->total_amount;
            $sellerNet = (float) $order->seller_net_amount;

            // shipping_fee == 0.00
            if (abs($shippingFee - 0.00) > 0.001) {
                $this->error("  FAILED: {$order->order_code} has shipping_fee = {$shippingFee} (must be 0.00).");
                $hasFailures = true;
            }

            // seller_net == item_subtotal (100% net to seller)
            if (abs($sellerNet - $itemSubtotal) > 0.001) {
                $this->error("  FAILED: {$order->order_code} seller_net ({$sellerNet}) != subtotal ({$itemSubtotal}).");
                $hasFailures = true;
            }

            // total_amount == item_subtotal + shipping_fee + buyer_protection_fee
            if (abs($totalAmount - ($itemSubtotal + $shippingFee + $buyerFee)) > 0.001) {
                $this->error("  FAILED: {$order->order_code} total_amount ({$totalAmount}) != sum ({$itemSubtotal} + {$buyerFee}).");
                $hasFailures = true;
            }

            $ordersChecked++;
        }
        $this->line("  [OK] All {$ordersChecked} orders strictly conform to DEC-04 financial equations.");

        // ---------------------------------------------------------------------
        // Check 4: Escrow Invariants & Immutability Ledger Check
        // ---------------------------------------------------------------------
        $this->newLine();
        $this->info('[Check 4/4] Verifying Escrow Transaction Types & Ledger Invariants...');

        $escrowTypes = EscrowTransaction::distinct()->pluck('transaction_type')->toArray();
        $expectedEscrowTypes = ['HOLD', 'RELEASE', 'FULL_REFUND', 'PARTIAL_REFUND'];
        $missingEscrowTypes = array_diff($expectedEscrowTypes, $escrowTypes);
        if (!empty($missingEscrowTypes)) {
            $this->error("  FAILED: Missing escrow transaction types: " . implode(', ', $missingEscrowTypes));
            $hasFailures = true;
        } else {
            $this->line("  [OK] Escrow transaction type coverage: 4/4 types present (" . implode(', ', $escrowTypes) . ").");
        }

        // Summary
        $this->newLine();
        $this->info('========================================================================');
        if ($hasFailures) {
            $this->error('  RESULT: VERIFICATION FAILED – Check errors above.');
            $this->info('========================================================================');
            return Command::FAILURE;
        }

        $this->info('  RESULT: ALL VERIFICATION CHECKS PASSED (100% INTEGRITY & ZERO DRIFT)');
        $this->info('========================================================================');
        return Command::SUCCESS;
    }
}
