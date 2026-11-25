<?php

namespace App\Http\Controllers\Admin;

use App\Enums\EscrowStatus;
use App\Http\Controllers\Controller;
use App\Models\EscrowTransaction;
use App\Models\Order;
use App\Models\SellerProfile;
use App\Models\WalletTransaction;
use Illuminate\Http\Request;
use Illuminate\View\View;

class EscrowLedgerController extends Controller
{
    /**
     * Display Immutable Escrow & Wallet Ledger Explorer with Zero Drift Reconciliation (Screen A-ES-01).
     * STRICTLY READ-ONLY.
     */
    public function index(Request $request): View
    {
        // 1. Zero Ledger Drift Platform Reconciliation Totals
        $totalSellerWallet = (float) SellerProfile::sum('wallet_balance');
        $totalSellerEscrowHeld = (float) SellerProfile::sum('escrow_held_balance');
        $totalActiveOrdersHeld = (float) Order::where('escrow_status', EscrowStatus::HELD)->sum('item_subtotal');

        // Drift check between seller profile held balances and orders in HELD escrow
        $escrowDrift = abs(round($totalSellerEscrowHeld - $totalActiveOrdersHeld, 2));
        $isZeroDrift = ($escrowDrift === 0.00);

        // Platform Escrow Ledger Volume Statistics
        $ledgerStats = [
            'gross_volume' => (float) EscrowTransaction::sum('gross_amount'),
            'buyer_refunded' => (float) EscrowTransaction::sum('buyer_refunded_amount'),
            'seller_released' => (float) EscrowTransaction::sum('seller_released_amount'),
            'platform_fee_retained' => (float) EscrowTransaction::sum('platform_fee_retained'),
            'total_escrow_tx_count' => EscrowTransaction::count(),
            'total_wallet_tx_count' => WalletTransaction::count(),
            'seller_wallet_total' => $totalSellerWallet,
            'seller_escrow_held_total' => $totalSellerEscrowHeld,
            'active_orders_held_total' => $totalActiveOrdersHeld,
            'escrow_drift' => $escrowDrift,
            'is_zero_drift' => $isZeroDrift,
        ];

        // 2. Tab Navigation: escrow (default) vs wallet
        $tab = $request->input('tab', 'escrow');

        $escrowTransactions = null;
        $walletTransactions = null;

        if ($tab === 'wallet') {
            $walletQuery = WalletTransaction::query()
                ->with(['seller', 'order', 'escrowTransaction']);

            if ($entryType = $request->input('entry_type')) {
                $walletQuery->where('entry_type', $entryType);
            }

            if ($search = $request->input('search')) {
                $walletQuery->where(function ($q) use ($search) {
                    $q->where('wallet_tx_code', 'ilike', "%{$search}%")
                        ->orWhereHas('order', fn ($oq) => $oq->where('order_code', 'ilike', "%{$search}%"))
                        ->orWhereHas('seller', fn ($sq) => $sq->where('display_name', 'ilike', "%{$search}%")->orWhere('email', 'ilike', "%{$search}%"));
                });
            }

            $walletTransactions = $walletQuery->orderByDesc('id')->paginate(15)->withQueryString();
        } else {
            $escrowQuery = EscrowTransaction::query()
                ->with(['order', 'buyer', 'seller', 'payment', 'triggeredBy']);

            if ($txType = $request->input('transaction_type')) {
                $escrowQuery->where('transaction_type', $txType);
            }

            if ($search = $request->input('search')) {
                $escrowQuery->where(function ($q) use ($search) {
                    $q->where('transaction_code', 'ilike', "%{$search}%")
                        ->orWhereHas('order', fn ($oq) => $oq->where('order_code', 'ilike', "%{$search}%"))
                        ->orWhereHas('buyer', fn ($bq) => $bq->where('display_name', 'ilike', "%{$search}%")->orWhere('email', 'ilike', "%{$search}%"))
                        ->orWhereHas('seller', fn ($sq) => $sq->where('display_name', 'ilike', "%{$search}%")->orWhere('email', 'ilike', "%{$search}%"));
                });
            }

            $escrowTransactions = $escrowQuery->orderByDesc('id')->paginate(15)->withQueryString();
        }

        return view('admin.escrow.index', compact('tab', 'ledgerStats', 'escrowTransactions', 'walletTransactions'));
    }
}
