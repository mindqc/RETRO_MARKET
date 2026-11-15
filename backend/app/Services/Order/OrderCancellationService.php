<?php

namespace App\Services\Order;

use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductStatus;
use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\EscrowTransaction;
use App\Models\Notification;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Product;
use App\Models\SellerProfile;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderCancellationService
{
    /**
     * Buyer initiates cancellation or cancellation request based on 3-tier rules (DEC-06 / DEC-07 / M-OR-04).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function buyerCancelOrRequest(User $buyer, Order $order, string $reason): Order
    {
        return DB::transaction(function () use ($buyer, $order, $reason) {
            /** @var Order $lockedOrder */
            $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->firstOrFail();

            if ($lockedOrder->buyer_id !== $buyer->id) {
                throw new RolePermissionDeniedException('Bạn không có quyền thao tác trên đơn hàng này.');
            }

            $status = $lockedOrder->order_status instanceof OrderStatus
                ? $lockedOrder->order_status->value
                : (string) $lockedOrder->order_status;

            $cleanReason = trim($reason);

            // Tier 1: PENDING_PAYMENT -> Immediate cancellation without refund
            if ($status === 'PENDING_PAYMENT') {
                $lockedOrder->update([
                    'order_status' => OrderStatus::CANCELLED,
                    'payment_status' => PaymentStatus::EXPIRED,
                    'cancelled_by_role' => 'BUYER',
                    'cancel_reason' => $cleanReason,
                    'cancelled_at' => now(),
                ]);

                // Expire pending payments
                Payment::where('order_id', $lockedOrder->id)
                    ->where('status', PaymentStatus::PENDING)
                    ->update(['status' => PaymentStatus::EXPIRED]);

                // Restore stock for FIXED_PRICE products
                $this->restoreFixedPriceStock($lockedOrder);

                return $lockedOrder->fresh(['items', 'seller.sellerProfile', 'payments']);
            }

            // Tier 2: PAID -> Immediate cancellation with 100% FULL_REFUND (DEC-07)
            if ($status === 'PAID') {
                $lockedOrder->update([
                    'order_status' => OrderStatus::CANCELLED,
                    'payment_status' => PaymentStatus::REFUNDED,
                    'escrow_status' => EscrowStatus::REFUNDED,
                    'cancelled_by_role' => 'BUYER',
                    'cancel_reason' => $cleanReason,
                    'cancelled_at' => now(),
                ]);

                // Record 100% FULL_REFUND Escrow Ledger Record (DEC-07 / chk_escrow_accounting_balance)
                $lastPayment = Payment::where('order_id', $lockedOrder->id)
                    ->where('status', PaymentStatus::PAID)
                    ->latest('id')
                    ->first();

                $escCode = 'ESC-REF-' . strtoupper(Str::random(8));
                EscrowTransaction::create([
                    'transaction_code' => $escCode,
                    'order_id' => $lockedOrder->id,
                    'payment_id' => $lastPayment?->id,
                    'buyer_id' => $buyer->id,
                    'seller_id' => $lockedOrder->seller_id,
                    'transaction_type' => 'FULL_REFUND',
                    'gross_amount' => (float) $lockedOrder->total_amount,
                    'item_subtotal_amount' => (float) $lockedOrder->item_subtotal,
                    'buyer_protection_fee_amount' => (float) $lockedOrder->buyer_protection_fee,
                    'seller_released_amount' => 0.00,
                    'buyer_refunded_amount' => (float) $lockedOrder->total_amount,
                    'platform_fee_retained' => 0.00,
                    'triggered_by_user_id' => $buyer->id,
                    'note' => 'Hoàn tiền 100% do người mua hủy đơn ở trạng thái PAID (DEC-07).',
                ]);

                // Deduct escrow_held_balance from seller profile
                $sellerProfile = SellerProfile::where('user_id', $lockedOrder->seller_id)->lockForUpdate()->first();
                if ($sellerProfile) {
                    $sellerProfile->escrow_held_balance = max(
                        0.00,
                        round((float) $sellerProfile->escrow_held_balance - (float) $lockedOrder->item_subtotal, 2)
                    );
                    $sellerProfile->save();
                }

                // Restore stock for FIXED_PRICE products
                $this->restoreFixedPriceStock($lockedOrder);

                // Notify Seller
                Notification::create([
                    'user_id' => $lockedOrder->seller_id,
                    'type' => 'ORDER_CANCELLED',
                    'title' => 'Đơn hàng đã bị hủy bởi người mua',
                    'body' => "Đơn hàng #{$lockedOrder->order_code} đã bị hủy bởi người mua trước khi đóng gói. Tiền đã được hoàn lại 100%.",
                    'target_type' => 'orders',
                    'target_id' => $lockedOrder->id,
                    'deep_link_route' => "/seller/orders/{$lockedOrder->id}",
                    'is_read' => false,
                ]);

                return $lockedOrder->fresh(['items', 'seller.sellerProfile', 'payments']);
            }

            // Tier 3: PREPARING -> Requires seller approval (DEC-06)
            if ($status === 'PREPARING') {
                $lockedOrder->update([
                    'cancellation_requested' => true,
                    'cancellation_request_reason' => $cleanReason,
                ]);

                // Notify Seller about cancellation request
                Notification::create([
                    'user_id' => $lockedOrder->seller_id,
                    'type' => 'ORDER_CANCEL_REQUESTED',
                    'title' => 'Người mua yêu cầu hủy đơn hàng',
                    'body' => "Người mua yêu cầu hủy đơn #{$lockedOrder->order_code} với lý do: {$cleanReason}. Vui lòng phản hồi yêu cầu.",
                    'target_type' => 'orders',
                    'target_id' => $lockedOrder->id,
                    'deep_link_route' => "/seller/orders/{$lockedOrder->id}",
                    'is_read' => false,
                ]);

                return $lockedOrder->fresh(['items', 'seller.sellerProfile', 'payments']);
            }

            // Other statuses: SHIPPED, DELIVERED, COMPLETED, CANCELLED, REFUNDED -> Cannot cancel
            throw new InvalidStateTransitionException('Không thể hủy đơn hàng khi đơn đã được giao cho đơn vị vận chuyển hoặc đã kết thúc (BR-OR-04).');
        });
    }

    /**
     * Buyer withdraws pending cancellation request in PREPARING status (UX-CHECK-02).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function buyerWithdrawCancelRequest(User $buyer, Order $order): Order
    {
        return DB::transaction(function () use ($buyer, $order) {
            /** @var Order $lockedOrder */
            $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->firstOrFail();

            if ($lockedOrder->buyer_id !== $buyer->id) {
                throw new RolePermissionDeniedException('Bạn không có quyền thao tác trên đơn hàng này.');
            }

            $status = $lockedOrder->order_status instanceof OrderStatus
                ? $lockedOrder->order_status->value
                : (string) $lockedOrder->order_status;

            if ($status !== 'PREPARING' || ! $lockedOrder->cancellation_requested) {
                throw new InvalidStateTransitionException('Không tìm thấy yêu cầu hủy đơn đang chờ xử lý để rút lại.');
            }

            $lockedOrder->update([
                'cancellation_requested' => false,
                'cancellation_request_reason' => null,
            ]);

            return $lockedOrder->fresh(['items', 'seller.sellerProfile', 'payments']);
        });
    }

    /**
     * Seller responds to buyer's cancellation request (APPROVE or REJECT) (DEC-06 / M-SL-06).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function sellerRespondCancelRequest(User $seller, Order $order, string $decision, ?string $note = null): Order
    {
        return DB::transaction(function () use ($seller, $order, $decision, $note) {
            /** @var Order $lockedOrder */
            $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->firstOrFail();

            if ($lockedOrder->seller_id !== $seller->id) {
                throw new RolePermissionDeniedException('Bạn không có quyền phản hồi yêu cầu hủy đơn này.');
            }

            $status = $lockedOrder->order_status instanceof OrderStatus
                ? $lockedOrder->order_status->value
                : (string) $lockedOrder->order_status;

            if ($status !== 'PREPARING' || ! $lockedOrder->cancellation_requested) {
                throw new InvalidStateTransitionException('Đơn hàng không có yêu cầu hủy nào đang chờ người bán phản hồi.');
            }

            $upperDecision = strtoupper($decision);

            if ($upperDecision === 'APPROVE') {
                $cancelNote = $lockedOrder->cancellation_request_reason . ($note ? " (Người bán duyệt: {$note})" : '');

                $lockedOrder->update([
                    'order_status' => OrderStatus::CANCELLED,
                    'payment_status' => PaymentStatus::REFUNDED,
                    'escrow_status' => EscrowStatus::REFUNDED,
                    'cancellation_requested' => false,
                    'cancelled_by_role' => 'BUYER',
                    'cancel_reason' => $cancelNote,
                    'cancelled_at' => now(),
                ]);

                // Record 100% FULL_REFUND Escrow Ledger Record (DEC-07)
                $lastPayment = Payment::where('order_id', $lockedOrder->id)
                    ->where('status', PaymentStatus::PAID)
                    ->latest('id')
                    ->first();

                $escCode = 'ESC-REF-' . strtoupper(Str::random(8));
                EscrowTransaction::create([
                    'transaction_code' => $escCode,
                    'order_id' => $lockedOrder->id,
                    'payment_id' => $lastPayment?->id,
                    'buyer_id' => $lockedOrder->buyer_id,
                    'seller_id' => $lockedOrder->seller_id,
                    'transaction_type' => 'FULL_REFUND',
                    'gross_amount' => (float) $lockedOrder->total_amount,
                    'item_subtotal_amount' => (float) $lockedOrder->item_subtotal,
                    'buyer_protection_fee_amount' => (float) $lockedOrder->buyer_protection_fee,
                    'seller_released_amount' => 0.00,
                    'buyer_refunded_amount' => (float) $lockedOrder->total_amount,
                    'platform_fee_retained' => 0.00,
                    'triggered_by_user_id' => $seller->id,
                    'note' => 'Người bán đồng ý yêu cầu hủy đơn hàng ở bước PREPARING (DEC-06 / DEC-07).',
                ]);

                // Deduct escrow_held_balance from seller profile
                $sellerProfile = SellerProfile::where('user_id', $lockedOrder->seller_id)->lockForUpdate()->first();
                if ($sellerProfile) {
                    $sellerProfile->escrow_held_balance = max(
                        0.00,
                        round((float) $sellerProfile->escrow_held_balance - (float) $lockedOrder->item_subtotal, 2)
                    );
                    $sellerProfile->save();
                }

                // Restore stock for FIXED_PRICE products
                $this->restoreFixedPriceStock($lockedOrder);

                // Notify Buyer
                Notification::create([
                    'user_id' => $lockedOrder->buyer_id,
                    'type' => 'ORDER_CANCEL_APPROVED',
                    'title' => 'Yêu cầu hủy đơn được chấp thuận',
                    'body' => "Người bán đã đồng ý yêu cầu hủy đơn #{$lockedOrder->order_code}. Toàn bộ số tiền đã được hoàn trả 100%.",
                    'target_type' => 'orders',
                    'target_id' => $lockedOrder->id,
                    'deep_link_route' => "/orders/{$lockedOrder->id}",
                    'is_read' => false,
                ]);
            } else {
                // Decision is REJECT
                $lockedOrder->update([
                    'cancellation_requested' => false,
                ]);

                // Notify Buyer
                Notification::create([
                    'user_id' => $lockedOrder->buyer_id,
                    'type' => 'ORDER_CANCEL_REJECTED',
                    'title' => 'Yêu cầu hủy đơn bị từ chối',
                    'body' => "Người bán đã từ chối yêu cầu hủy đơn #{$lockedOrder->order_code}" . ($note ? ": {$note}" : '') . '. Đơn hàng tiếp tục được chuẩn bị đóng gói.',
                    'target_type' => 'orders',
                    'target_id' => $lockedOrder->id,
                    'deep_link_route' => "/orders/{$lockedOrder->id}",
                    'is_read' => false,
                ]);
            }

            return $lockedOrder->fresh(['items', 'seller.sellerProfile', 'payments']);
        });
    }

    /**
     * Helper to restore inventory when an order is cancelled.
     */
    protected function restoreFixedPriceStock(Order $order): void
    {
        if ($order->order_source !== 'FIXED_PRICE') {
            return;
        }

        foreach ($order->items as $item) {
            /** @var Product|null $product */
            $product = Product::where('id', $item->product_id)->lockForUpdate()->first();
            if ($product) {
                $product->available_quantity += $item->quantity;
                $status = $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status;
                if ($status === 'SOLD' && $product->available_quantity > 0) {
                    $product->status = ProductStatus::APPROVED;
                }
                $product->save();
            }
        }
    }
}
