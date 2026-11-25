<?php

namespace App\Services\Order;

use App\Enums\AuctionStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductStatus;
use App\Exceptions\EscrowLedgerIntegrityException;
use App\Exceptions\InvalidStateTransitionException;
use App\Models\Auction;
use App\Models\Notification;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\SellerProfile;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class OrderExpirationService
{
    /**
     * Expire overdue unpaid orders (BR-AU-07 / DEC-02 / FOR UPDATE SKIP LOCKED).
     */
    public function expireOverdueUnpaidOrders(?User $triggeredBy = null): array
    {
        $dueOrderIds = Order::where('order_status', OrderStatus::PENDING_PAYMENT)
            ->where('payment_status', PaymentStatus::UNPAID)
            ->where('payment_expires_at', '<=', now())
            ->pluck('id')
            ->toArray();

        $expiredOrderIds = [];
        $defaultedAuctionIds = [];

        foreach ($dueOrderIds as $id) {
            DB::transaction(function () use ($id, &$expiredOrderIds, &$defaultedAuctionIds) {
                /** @var Order|null $order */
                $order = Order::with(['items.product', 'auction.product'])
                    ->where('id', $id)
                    ->lock('FOR UPDATE SKIP LOCKED')
                    ->first();

                if (! $order) {
                    return;
                }

                $orderStatus = $order->order_status instanceof OrderStatus
                    ? $order->order_status->value
                    : (string) $order->order_status;

                $paymentStatus = $order->payment_status instanceof PaymentStatus
                    ? $order->payment_status->value
                    : (string) $order->payment_status;

                if ($orderStatus !== 'PENDING_PAYMENT' || $paymentStatus !== 'UNPAID' || $order->payment_expires_at->gt(now())) {
                    return;
                }

                if ($order->order_source === 'AUCTION' && $order->auction_id !== null) {
                    self::processAuctionWinnerDefault($order, 'SYSTEM', 'Quá thời hạn thanh toán tự động (BR-AU-07).');
                    $defaultedAuctionIds[] = $order->auction_id;
                } else {
                    // 1. Mark Order as CANCELLED & EXPIRED
                    $order->update([
                        'order_status' => OrderStatus::CANCELLED,
                        'payment_status' => PaymentStatus::EXPIRED,
                        'cancelled_by_role' => 'SYSTEM',
                        'cancel_reason' => 'Quá thời hạn thanh toán tự động (BR-AU-07).',
                        'cancelled_at' => now(),
                    ]);

                    // 2. Expire pending Payment records
                    Payment::where('order_id', $order->id)
                        ->where('status', PaymentStatus::PENDING)
                        ->update(['status' => PaymentStatus::EXPIRED]);

                    // FIXED_PRICE: Restore stock with sorted product IDs
                    $this->restoreFixedPriceStock($order);
                }

                $expiredOrderIds[] = $order->id;
            });
        }

        return [
            'expired_orders_count' => count($expiredOrderIds),
            'defaulted_auctions_count' => count($defaultedAuctionIds),
            'expired_order_ids' => $expiredOrderIds,
        ];
    }

    /**
     * Unified execution for Auction Winner Default (BR-AU-07 / DEC-02 / P9-03).
     *
     * @throws InvalidStateTransitionException
     * @throws EscrowLedgerIntegrityException
     */
    public static function processAuctionWinnerDefault(Order $lockedOrder, string $cancelledByRole = 'SYSTEM', ?string $reason = null): Order
    {
        // 1. Lock Payment: Lock pending payments and update status to EXPIRED
        Payment::where('order_id', $lockedOrder->id)
            ->where('status', PaymentStatus::PENDING)
            ->lockForUpdate()
            ->update(['status' => PaymentStatus::EXPIRED]);

        // 2. Lock Auction
        if (! $lockedOrder->auction_id) {
            throw new InvalidStateTransitionException('Đơn hàng đấu giá không có thông tin phiên đấu giá hợp lệ.');
        }

        /** @var Auction $auction */
        $auction = Auction::where('id', $lockedOrder->auction_id)
            ->lockForUpdate()
            ->firstOrFail();

        $auction->update(['status' => AuctionStatus::WINNER_DEFAULTED]);

        // 3. Validate OrderItem
        $items = OrderItem::where('order_id', $lockedOrder->id)->get();
        if ($items->isEmpty() || $items->count() > 1) {
            throw new InvalidStateTransitionException('Dữ liệu sản phẩm của đơn hàng đấu giá không hợp lệ.');
        }

        $item = $items->first();
        if ((int) $item->product_id !== (int) $auction->product_id) {
            throw new InvalidStateTransitionException('Sản phẩm trong đơn hàng không khớp với phiên đấu giá.');
        }

        // 4. Lock Product & restore for relisting (DEC-02)
        /** @var Product $product */
        $product = Product::where('id', $auction->product_id)
            ->lockForUpdate()
            ->firstOrFail();

        $prodStatusVal = $product->status instanceof ProductStatus
            ? $product->status->value
            : (string) $product->status;

        if ($prodStatusVal !== 'SOLD') {
            throw new InvalidStateTransitionException('Trạng thái sản phẩm đấu giá không hợp lệ để khôi phục.');
        }

        $product->update([
            'status' => ProductStatus::APPROVED,
            'available_quantity' => 1,
        ]);

        // 5. Lock Buyer SellerProfile & apply default count penalty
        /** @var SellerProfile|null $buyerProfile */
        $buyerProfile = SellerProfile::where('user_id', $lockedOrder->buyer_id)
            ->lockForUpdate()
            ->first();

        if (! $buyerProfile) {
            throw new EscrowLedgerIntegrityException('Không tìm thấy hồ sơ người bán/người mua để cập nhật số lần bỏ cọc.');
        }

        $buyerProfile->increment('auction_default_count');

        // 6. Update Order status
        $defaultReason = $cancelledByRole === 'BUYER'
            ? 'Người mua tự nguyện hủy đơn hàng đấu giá chưa thanh toán.'
            : 'Quá thời hạn thanh toán tự động (BR-AU-07).';

        $lockedOrder->update([
            'order_status' => OrderStatus::CANCELLED,
            'payment_status' => PaymentStatus::EXPIRED,
            'cancelled_by_role' => $cancelledByRole,
            'cancel_reason' => $reason ?? $defaultReason,
            'cancelled_at' => now(),
        ]);

        // 7. Send Notifications
        $buyerBody = $cancelledByRole === 'BUYER'
            ? "Đơn hàng thắng đấu giá #{$lockedOrder->order_code} đã bị hủy do bạn tự nguyện hủy. Tài khoản của bạn đã bị ghi nhận 1 lần bỏ cọc."
            : "Đơn hàng thắng đấu giá #{$lockedOrder->order_code} đã bị hủy do quá thời hạn thanh toán 30 phút. Tài khoản của bạn đã bị ghi nhận 1 lần bỏ cọc.";

        $buyerTitle = $cancelledByRole === 'BUYER'
            ? 'Bạn đã hủy đơn hàng thắng đấu giá'
            : 'Bạn đã bỏ lỡ hạn thanh toán phiên đấu giá';

        Notification::create([
            'user_id' => $lockedOrder->buyer_id,
            'type' => 'AUCTION_WINNER_DEFAULTED',
            'title' => $buyerTitle,
            'body' => $buyerBody,
            'target_type' => 'orders',
            'target_id' => $lockedOrder->id,
            'deep_link_route' => "/buyer/orders/{$lockedOrder->id}",
            'is_read' => false,
        ]);

        Notification::create([
            'user_id' => $lockedOrder->seller_id,
            'type' => 'AUCTION_WINNER_DEFAULTED',
            'title' => 'Người thắng đấu giá không hoàn tất thanh toán',
            'body' => "Người thắng phiên đấu giá #{$auction->auction_code} đã không hoàn tất thanh toán (đơn hàng #{$lockedOrder->order_code}). Sản phẩm đã được tự động mở khóa để bạn có thể đăng lại.",
            'target_type' => 'auctions',
            'target_id' => $auction->id,
            'deep_link_route' => "/seller/products/{$auction->product_id}",
            'is_read' => false,
        ]);

        return $lockedOrder->fresh(['items', 'seller.sellerProfile', 'payments']);
    }

    /**
     * Helper to restore inventory when a fixed-price order is cancelled/expired.
     */
    protected function restoreFixedPriceStock(Order $order): void
    {
        if ($order->order_source !== 'FIXED_PRICE') {
            return;
        }

        $items = $order->items ?? OrderItem::where('order_id', $order->id)->get();
        $productIds = $items->pluck('product_id')->unique()->sort()->values()->all();

        if (empty($productIds)) {
            return;
        }

        // Lock products in ascending order
        $products = Product::whereIn('id', $productIds)
            ->orderBy('id', 'asc')
            ->lockForUpdate()
            ->get()
            ->keyBy('id');

        foreach ($items as $item) {
            /** @var Product|null $product */
            $product = $products->get($item->product_id);
            if ($product) {
                $newQty = min((int) $product->total_quantity, (int) $product->available_quantity + (int) $item->quantity);
                $prodStatusVal = $product->status instanceof ProductStatus
                    ? $product->status->value
                    : (string) $product->status;

                $newStatus = ($prodStatusVal === 'SOLD')
                    ? ProductStatus::APPROVED
                    : $product->status;

                $product->update([
                    'available_quantity' => $newQty,
                    'status' => $newStatus,
                ]);
            }
        }
    }
}
