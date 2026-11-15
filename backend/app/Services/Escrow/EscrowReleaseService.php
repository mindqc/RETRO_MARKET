<?php

namespace App\Services\Escrow;

use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\EscrowTransaction;
use App\Models\Notification;
use App\Models\Order;
use App\Models\Payment;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class EscrowReleaseService
{
    /**
     * Buyer confirms delivery of order, triggering release of 100% item_subtotal to seller (OF-05 / DEC-04).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function confirmDeliveryByBuyer(User $buyer, Order $order): Order
    {
        if ($order->buyer_id !== $buyer->id) {
            throw new RolePermissionDeniedException('Bạn không có quyền xác nhận nhận hàng cho đơn này.');
        }

        $orderStatus = $order->order_status instanceof OrderStatus
            ? $order->order_status->value
            : (string) $order->order_status;

        $escrowStatus = $order->escrow_status instanceof EscrowStatus
            ? $order->escrow_status->value
            : (string) $order->escrow_status;

        // Idempotency: If order is already completed and released, return immediately
        if ($orderStatus === 'COMPLETED' && $escrowStatus === 'RELEASED') {
            return $order->fresh(['items', 'seller.sellerProfile', 'shipment', 'escrowTransactions', 'walletTransaction']);
        }

        if (!in_array($orderStatus, ['SHIPPED', 'DELIVERED'])) {
            throw new InvalidStateTransitionException('Chỉ có thể xác nhận nhận hàng khi đơn đang giao (SHIPPED) hoặc đã giao (DELIVERED).');
        }

        return $this->releaseOrderEscrowToSeller(
            $order,
            $buyer,
            'Người mua xác nhận đã nhận hàng hợp lệ (OF-05).'
        );
    }

    /**
     * Release 100% item_subtotal of an order from Escrow to Seller wallet.
     * Enforces Dispute Freeze Guard (BR-DP-02), Idempotency (BR-FN-07), and DEC-04 equations.
     *
     * @throws InvalidStateTransitionException
     */
    public function releaseOrderEscrowToSeller(
        Order $order,
        ?User $triggeredBy = null,
        string $note = '',
        bool $fromAdminDisputeVerdict = false
    ): Order {
        return DB::transaction(function () use ($order, $triggeredBy, $note, $fromAdminDisputeVerdict) {
            /** @var Order $lockedOrder */
            $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->firstOrFail();

            $disputeStatus = $lockedOrder->dispute_status instanceof DisputeStatus
                ? $lockedOrder->dispute_status->value
                : (string) $lockedOrder->dispute_status;

            // Dispute Freeze Guard (BR-DP-02)
            if (!$fromAdminDisputeVerdict && ($disputeStatus !== 'NONE' || $lockedOrder->escrow_frozen_at !== null)) {
                throw new InvalidStateTransitionException('Đơn hàng đang có khiếu nại nên tiền trung gian Escrow đã bị đóng băng (BR-DP-02).');
            }

            $escrowStatus = $lockedOrder->escrow_status instanceof EscrowStatus
                ? $lockedOrder->escrow_status->value
                : (string) $lockedOrder->escrow_status;

            // Idempotency Guard (BR-FN-07): Do not release twice
            if ($escrowStatus === 'RELEASED' || WalletTransaction::where('order_id', $lockedOrder->id)->where('entry_type', 'CREDIT')->exists()) {
                $currentOrderStatus = $lockedOrder->order_status instanceof OrderStatus
                    ? $lockedOrder->order_status->value
                    : (string) $lockedOrder->order_status;

                if ($escrowStatus !== 'RELEASED' || $currentOrderStatus !== 'COMPLETED') {
                    $lockedOrder->update([
                        'order_status' => OrderStatus::COMPLETED,
                        'escrow_status' => EscrowStatus::RELEASED,
                        'completed_at' => $lockedOrder->completed_at ?? now(),
                    ]);
                }

                return $lockedOrder->fresh(['items', 'seller.sellerProfile', 'shipment', 'escrowTransactions', 'walletTransaction']);
            }

            $paymentStatus = $lockedOrder->payment_status instanceof PaymentStatus
                ? $lockedOrder->payment_status->value
                : (string) $lockedOrder->payment_status;

            if ($paymentStatus !== 'PAID' || $escrowStatus !== 'HELD') {
                throw new InvalidStateTransitionException('Đơn hàng phải ở trạng thái đã thanh toán (PAID) và tiền đang tạm giữ (HELD) mới có thể giải ngân.');
            }

            $paidPayment = Payment::where('order_id', $lockedOrder->id)
                ->where('status', PaymentStatus::PAID)
                ->first();

            // 1. Create immutable EscrowTransaction (RELEASE)
            $escrowTx = EscrowTransaction::create([
                'transaction_code' => 'ESC-REL-' . strtoupper(Str::random(10)),
                'order_id' => $lockedOrder->id,
                'payment_id' => $paidPayment?->id,
                'buyer_id' => $lockedOrder->buyer_id,
                'seller_id' => $lockedOrder->seller_id,
                'transaction_type' => 'RELEASE',
                'gross_amount' => $lockedOrder->total_amount,
                'item_subtotal_amount' => $lockedOrder->item_subtotal,
                'buyer_protection_fee_amount' => $lockedOrder->buyer_protection_fee,
                'seller_released_amount' => $lockedOrder->item_subtotal,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => $lockedOrder->buyer_protection_fee,
                'triggered_by_user_id' => $triggeredBy?->id,
                'note' => $note ?: 'Giải ngân tiền trung gian cho người bán (DEC-04 / OF-05).',
            ]);

            // 2. Lock and update SellerProfile
            /** @var SellerProfile $sellerProfile */
            $sellerProfile = SellerProfile::where('user_id', $lockedOrder->seller_id)->lockForUpdate()->firstOrFail();
            $balanceBefore = (float) $sellerProfile->wallet_balance;
            $balanceAfter = round($balanceBefore + (float) $lockedOrder->item_subtotal, 2);

            // 3. Create immutable WalletTransaction (CREDIT)
            WalletTransaction::create([
                'wallet_tx_code' => 'WTX-' . date('Y') . '-' . strtoupper(Str::random(8)),
                'seller_id' => $lockedOrder->seller_id,
                'order_id' => $lockedOrder->id,
                'escrow_transaction_id' => $escrowTx->id,
                'entry_type' => 'CREDIT',
                'amount' => $lockedOrder->item_subtotal,
                'balance_before' => $balanceBefore,
                'balance_after' => $balanceAfter,
                'description' => 'Giải ngân 100% tiền hàng từ đơn ' . $lockedOrder->order_code,
            ]);

            $sellerProfile->update([
                'wallet_balance' => $balanceAfter,
                'escrow_held_balance' => max(0.00, round((float) $sellerProfile->escrow_held_balance - (float) $lockedOrder->item_subtotal, 2)),
                'completed_orders_count' => (int) $sellerProfile->completed_orders_count + 1,
            ]);

            // 4. Update Order status
            $lockedOrder->update([
                'order_status' => OrderStatus::COMPLETED,
                'escrow_status' => EscrowStatus::RELEASED,
                'delivered_at' => $lockedOrder->delivered_at ?? now(),
                'completed_at' => now(),
            ]);

            // 5. Send notification to Seller
            Notification::create([
                'user_id' => $lockedOrder->seller_id,
                'type' => 'ESCROW_RELEASED',
                'title' => 'Tiền hàng đã được giải ngân vào ví',
                'body' => "Đơn hàng #{$lockedOrder->order_code} đã hoàn tất. Số tiền " . number_format((float) $lockedOrder->item_subtotal, 0, ',', '.') . "đ đã được cộng vào ví của bạn.",
                'target_type' => 'orders',
                'target_id' => $lockedOrder->id,
                'deep_link_route' => '/seller/wallet',
                'is_read' => false,
            ]);

            return $lockedOrder->fresh(['items', 'seller.sellerProfile', 'shipment', 'escrowTransactions', 'walletTransaction']);
        });
    }

    /**
     * Get seller wallet overview, balance summary, and immutable ledger transactions.
     */
    public function getSellerWalletSummary(User $seller, int $perPage = 15): array
    {
        $sellerProfile = SellerProfile::where('user_id', $seller->id)->first();

        $walletTransactions = WalletTransaction::where('seller_id', $seller->id)
            ->with(['order', 'escrowTransaction'])
            ->orderByDesc('created_at')
            ->paginate($perPage);

        $recentEscrowTransactions = EscrowTransaction::where('seller_id', $seller->id)
            ->orderByDesc('created_at')
            ->limit(10)
            ->get();

        return [
            'seller_profile' => $sellerProfile,
            'wallet_balance' => $sellerProfile?->wallet_balance ?? '0.00',
            'escrow_held_balance' => $sellerProfile?->escrow_held_balance ?? '0.00',
            'completed_orders_count' => $sellerProfile?->completed_orders_count ?? 0,
            'wallet_transactions' => $walletTransactions,
            'recent_escrow_transactions' => $recentEscrowTransactions,
        ];
    }

    /**
     * Batch auto-complete due delivered orders and release escrow (FOR UPDATE SKIP LOCKED / BR-OR-05 / BR-DP-02).
     */
    public function autoCompleteDueDeliveredOrders(?User $triggeredBy = null): array
    {
        $dueOrderIds = Order::where('order_status', OrderStatus::DELIVERED)
            ->where('payment_status', PaymentStatus::PAID)
            ->where('escrow_status', EscrowStatus::HELD)
            ->where('dispute_status', DisputeStatus::NONE)
            ->whereNull('escrow_frozen_at')
            ->where('auto_complete_at', '<=', now())
            ->pluck('id')
            ->toArray();

        $completedOrderIds = [];

        foreach ($dueOrderIds as $id) {
            try {
                $order = Order::where('id', $id)
                    ->where('order_status', OrderStatus::DELIVERED)
                    ->where('dispute_status', DisputeStatus::NONE)
                    ->whereNull('escrow_frozen_at')
                    ->where('auto_complete_at', '<=', now())
                    ->first();

                if ($order) {
                    $this->releaseOrderEscrowToSeller(
                        $order,
                        $triggeredBy,
                        'Tự động hoàn tất đơn hàng và giải ngân 100% tiền hàng sau thời gian quy định (BR-OR-05 / DEC-04).'
                    );
                    $completedOrderIds[] = $order->id;
                }
            } catch (\Throwable $e) {
                // If skipped or locked by concurrent transaction, continue
                continue;
            }
        }

        return [
            'auto_completed_count' => count($completedOrderIds),
            'auto_completed_order_ids' => $completedOrderIds,
        ];
    }
}
