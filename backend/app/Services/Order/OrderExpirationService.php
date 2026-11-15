<?php

namespace App\Services\Order;

use App\Enums\AuctionStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductStatus;
use App\Models\Auction;
use App\Models\Notification;
use App\Models\Order;
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

                if (!$order) {
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

                // 3. Handle Auction vs Fixed-Price
                if ($order->order_source === 'AUCTION' && $order->auction_id !== null) {
                    /** @var Auction|null $auction */
                    $auction = Auction::with('product')
                        ->where('id', $order->auction_id)
                        ->lockForUpdate()
                        ->first();

                    if ($auction) {
                        $auction->update(['status' => AuctionStatus::WINNER_DEFAULTED]);

                        // Restore product for relisting (DEC-02)
                        if ($auction->product) {
                            $auction->product->update([
                                'status' => ProductStatus::APPROVED,
                                'available_quantity' => 1,
                            ]);
                        }

                        // Penalty: increment buyer's auction_default_count
                        $buyerProfile = SellerProfile::where('user_id', $order->buyer_id)
                            ->lockForUpdate()
                            ->first();

                        if ($buyerProfile) {
                            $buyerProfile->increment('auction_default_count');
                        }

                        // Send notifications
                        Notification::create([
                            'user_id' => $order->buyer_id,
                            'type' => 'AUCTION_WINNER_DEFAULTED',
                            'title' => 'Bạn đã bỏ lỡ hạn thanh toán phiên đấu giá',
                            'body' => "Đơn hàng thắng đấu giá #{$order->order_code} đã bị hủy do quá thời hạn thanh toán 30 phút. Tài khoản của bạn đã bị ghi nhận 1 lần bỏ cọc.",
                            'target_type' => 'orders',
                            'target_id' => $order->id,
                            'deep_link_route' => "/buyer/orders/{$order->id}",
                            'is_read' => false,
                        ]);

                        Notification::create([
                            'user_id' => $order->seller_id,
                            'type' => 'AUCTION_WINNER_DEFAULTED',
                            'title' => 'Người thắng đấu giá không hoàn tất thanh toán',
                            'body' => "Người thắng phiên đấu giá #{$auction->auction_code} đã không thanh toán đúng hạn. Sản phẩm đã được tự động mở khóa để bạn có thể đăng lại.",
                            'target_type' => 'auctions',
                            'target_id' => $auction->id,
                            'deep_link_route' => "/seller/products/{$auction->product_id}",
                            'is_read' => false,
                        ]);

                        $defaultedAuctionIds[] = $auction->id;
                    }
                } else {
                    // FIXED_PRICE: Restore stock
                    foreach ($order->items as $item) {
                        $product = $item->product ?? Product::find($item->product_id);
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

                $expiredOrderIds[] = $order->id;
            });
        }

        return [
            'expired_orders_count' => count($expiredOrderIds),
            'defaulted_auctions_count' => count($defaultedAuctionIds),
            'expired_order_ids' => $expiredOrderIds,
        ];
    }
}
