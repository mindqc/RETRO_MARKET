<?php

namespace App\Services\Escrow;

use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Exceptions\EscrowLedgerIntegrityException;
use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\EscrowTransaction;
use App\Models\Notification;
use App\Models\Order;
use App\Models\Payment;
use App\Models\SellerProfile;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class MockQrPaymentService
{
    /**
     * Get payment session details (M-PM-01).
     *
     * @throws RolePermissionDeniedException
     */
    public function getPaymentSession(User $user, int $paymentId): Payment
    {
        $payment = Payment::with(['order.items', 'order.seller.sellerProfile', 'order.buyer'])->findOrFail($paymentId);

        if ($user->id !== $payment->payer_id && $user->id !== $payment->order->seller_id && ! $user->isInternalStaff()) {
            throw new RolePermissionDeniedException('Bạn không có quyền truy cập phiên thanh toán này.');
        }

        return $payment;
    }

    /**
     * Simulate QR payment success with idempotent duplicate prevention (M-PM-02 / BR-FN-03).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     * @throws EscrowLedgerIntegrityException
     */
    public function simulateSuccess(User $buyer, int $paymentId): array
    {
        $locator = Payment::select('id', 'order_id')->findOrFail($paymentId);

        return DB::transaction(function () use ($buyer, $paymentId, $locator) {
            // Lock Hierarchy: Order -> Payment -> SellerProfile
            /** @var Order $order */
            $order = Order::where('id', $locator->order_id)->lockForUpdate()->firstOrFail();

            /** @var Payment $payment */
            $payment = Payment::where('id', $paymentId)->lockForUpdate()->firstOrFail();

            if ((int) $payment->order_id !== (int) $order->id) {
                throw new InvalidStateTransitionException('Dữ liệu thanh toán không hợp lệ với đơn hàng.');
            }

            if ($payment->payer_id !== $buyer->id && ! $buyer->isInternalStaff()) {
                throw new RolePermissionDeniedException('Bạn không phải người thực hiện thanh toán cho đơn hàng này.');
            }

            $orderStatus = $order->order_status instanceof OrderStatus ? $order->order_status->value : (string) $order->order_status;
            $paymentStatus = $payment->status instanceof PaymentStatus ? $payment->status->value : (string) $payment->status;

            // BR-FN-03: Idempotent replay check (no double escrow hold)
            if ($paymentStatus === 'PAID' && in_array($orderStatus, ['PAID', 'PREPARING', 'SHIPPED', 'DELIVERED', 'COMPLETED'], true)) {
                return [
                    'order' => $order->fresh(['items', 'seller.sellerProfile', 'payments']),
                    'payment' => $payment->fresh(),
                    'idempotent_replay' => true,
                ];
            }

            if ($orderStatus !== 'PENDING_PAYMENT' || $paymentStatus !== 'PENDING') {
                throw new InvalidStateTransitionException("Không thể thanh toán đơn hàng ở trạng thái '{$orderStatus}'.");
            }

            if ($order->payment_expires_at && now()->greaterThan($order->payment_expires_at)) {
                throw new InvalidStateTransitionException('Phiên thanh toán QR đã hết hạn. Vui lòng đặt lại đơn hàng.');
            }

            // 1. Mark Payment PAID
            $payment->update([
                'status' => PaymentStatus::PAID,
                'paid_at' => now(),
            ]);

            // 2. Mark Order PAID and Escrow HELD
            $order->update([
                'order_status' => OrderStatus::PAID,
                'payment_status' => PaymentStatus::PAID,
                'escrow_status' => EscrowStatus::HELD,
                'paid_at' => now(),
            ]);

            // 3. Record Immutable Escrow HOLD Ledger Record
            $escCode = 'ESC-HOLD-' . strtoupper(Str::random(8));
            EscrowTransaction::create([
                'transaction_code' => $escCode,
                'order_id' => $order->id,
                'payment_id' => $payment->id,
                'buyer_id' => $buyer->id,
                'seller_id' => $order->seller_id,
                'transaction_type' => 'HOLD',
                'gross_amount' => (float) $order->total_amount,
                'item_subtotal_amount' => (float) $order->item_subtotal,
                'buyer_protection_fee_amount' => (float) $order->buyer_protection_fee,
                'seller_released_amount' => 0.00,
                'buyer_refunded_amount' => 0.00,
                'platform_fee_retained' => 0.00,
                'triggered_by_user_id' => $buyer->id,
                'note' => 'Giữ tiền trung gian Escrow khi người mua thanh toán QR thành công.',
            ]);

            // 4. Update Seller Profile escrow_held_balance using BCMath
            $sellerProfile = SellerProfile::where('user_id', $order->seller_id)->lockForUpdate()->first();
            if (! $sellerProfile) {
                throw new EscrowLedgerIntegrityException('Không tìm thấy hồ sơ người bán để ký quỹ Escrow.');
            }

            $sellerProfile->escrow_held_balance = bcadd(
                (string) $sellerProfile->escrow_held_balance,
                (string) $order->item_subtotal,
                2
            );
            $sellerProfile->save();

            // 5. Notify Seller
            Notification::create([
                'user_id' => $order->seller_id,
                'type' => 'ORDER_PAID',
                'title' => 'Đơn hàng mới đã được thanh toán',
                'body' => "Đơn hàng #{$order->order_code} đã thanh toán thành công qua QR Escrow. Vui lòng chuẩn bị hàng.",
                'target_type' => 'orders',
                'target_id' => $order->id,
                'deep_link_route' => "/seller/orders/{$order->id}",
                'is_read' => false,
            ]);

            return [
                'order' => $order->fresh(['items', 'seller.sellerProfile', 'payments']),
                'payment' => $payment->fresh(),
                'idempotent_replay' => false,
            ];
        });
    }

    /**
     * Simulate QR payment failure and issue new pending payment session for retry (M-PM-02).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function simulateFailure(User $buyer, int $paymentId, ?string $reason = null): array
    {
        $locator = Payment::select('id', 'order_id')->findOrFail($paymentId);

        return DB::transaction(function () use ($buyer, $paymentId, $locator, $reason) {
            // Lock Hierarchy: Order -> Payment
            /** @var Order $order */
            $order = Order::where('id', $locator->order_id)->lockForUpdate()->firstOrFail();

            /** @var Payment $payment */
            $payment = Payment::where('id', $paymentId)->lockForUpdate()->firstOrFail();

            if ((int) $payment->order_id !== (int) $order->id) {
                throw new InvalidStateTransitionException('Dữ liệu thanh toán không hợp lệ với đơn hàng.');
            }

            if ($payment->payer_id !== $buyer->id && ! $buyer->isInternalStaff()) {
                throw new RolePermissionDeniedException('Bạn không phải người thực hiện thanh toán cho đơn hàng này.');
            }

            $orderPaymentStatus = $order->payment_status instanceof PaymentStatus ? $order->payment_status->value : (string) $order->payment_status;
            if ($orderPaymentStatus === 'PAID') {
                throw new InvalidStateTransitionException('Đơn hàng đã được thanh toán thành công, không thể giả lập thất bại.');
            }

            $orderStatus = $order->order_status instanceof OrderStatus ? $order->order_status->value : (string) $order->order_status;
            if ($orderStatus === 'CANCELLED') {
                throw new InvalidStateTransitionException('Đơn hàng đã bị hủy, không thể tiếp tục thanh toán.');
            }

            // 1. Mark current payment FAILED
            $cleanReason = trim($reason ?? '') ?: 'Người dùng giả lập thanh toán QR thất bại.';
            $payment->update([
                'status' => PaymentStatus::FAILED,
                'failure_reason' => $cleanReason,
            ]);

            // 2. Automatically generate new PENDING payment session for retry
            $newPaymentRef = 'PAY-2026-' . strtoupper(Str::random(8));
            $qrPayload = "IZITHRIFT_QR|{$order->order_code}|{$order->total_amount}";

            $newPayment = Payment::create([
                'payment_reference' => $newPaymentRef,
                'order_id' => $order->id,
                'payer_id' => $buyer->id,
                'amount' => (float) $order->total_amount,
                'qr_payload' => $qrPayload,
                'status' => PaymentStatus::PENDING,
                'expires_at' => $order->payment_expires_at,
            ]);

            return [
                'failed_payment' => $payment->fresh(),
                'new_payment' => $newPayment,
                'order' => $order->fresh(['items', 'seller.sellerProfile', 'payments']),
            ];
        });
    }
}
