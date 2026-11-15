<?php

namespace App\Services\Order;

use App\Enums\DisputeStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\Notification;
use App\Models\Order;
use App\Models\Shipment;
use App\Models\User;
use App\Services\Governance\PlatformConfigService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class OrderFulfillmentService
{
    public function __construct(
        protected PlatformConfigService $platformConfigService
    ) {}

    /**
     * List orders where user is the seller with optional status filter.
     */
    public function listSellerOrders(User $seller, array $filters = [], int $perPage = 12): LengthAwarePaginator
    {
        $query = Order::where('seller_id', $seller->id)
            ->with(['items.product.primaryImage', 'buyer.profile', 'shipment', 'dispute']);

        if (!empty($filters['status'])) {
            $status = strtoupper(trim($filters['status']));
            if ($status === 'DISPUTED') {
                $query->where('dispute_status', '!=', DisputeStatus::NONE);
            } else {
                $query->where('order_status', $status);
            }
        }

        if (!empty($filters['q'])) {
            $q = trim($filters['q']);
            $query->where(function ($sub) use ($q) {
                $sub->where('order_code', 'ilike', "%{$q}%")
                    ->orWhereHas('items', function ($itemSub) use ($q) {
                        $itemSub->where('product_title_snapshot', 'ilike', "%{$q}%");
                    });
            });
        }

        return $query->orderByDesc('created_at')->paginate($perPage);
    }

    /**
     * Seller marks order as preparing (PAID -> PREPARING).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function markPreparing(User $seller, Order $order): Order
    {
        return DB::transaction(function () use ($seller, $order) {
            /** @var Order $lockedOrder */
            $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->firstOrFail();

            if ($lockedOrder->seller_id !== $seller->id) {
                throw new RolePermissionDeniedException('Bạn không có quyền xử lý đơn hàng này.');
            }

            $orderStatus = $lockedOrder->order_status instanceof OrderStatus
                ? $lockedOrder->order_status->value
                : (string) $lockedOrder->order_status;

            $paymentStatus = $lockedOrder->payment_status instanceof PaymentStatus
                ? $lockedOrder->payment_status->value
                : (string) $lockedOrder->payment_status;

            if ($orderStatus !== 'PAID' || $paymentStatus !== 'PAID') {
                throw new InvalidStateTransitionException('Chỉ có thể chuẩn bị hàng cho đơn đã thanh toán (PAID).');
            }

            $lockedOrder->update([
                'order_status' => OrderStatus::PREPARING,
                'preparing_at' => now(),
            ]);

            Notification::create([
                'user_id' => $lockedOrder->buyer_id,
                'type' => 'ORDER_PREPARING',
                'title' => 'Người bán đang chuẩn bị đơn hàng',
                'body' => "Đơn hàng #{$lockedOrder->order_code} đang được người bán đóng gói cẩn thận.",
                'target_type' => 'orders',
                'target_id' => $lockedOrder->id,
                'deep_link_route' => "/buyer/orders/{$lockedOrder->id}",
                'is_read' => false,
            ]);

            return $lockedOrder->fresh(['items', 'buyer.profile', 'shipment']);
        });
    }

    /**
     * Seller ships order and provides shipment tracking info (PREPARING -> SHIPPED).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function shipOrder(User $seller, Order $order, array $shipmentData): Order
    {
        return DB::transaction(function () use ($seller, $order, $shipmentData) {
            /** @var Order $lockedOrder */
            $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->firstOrFail();

            if ($lockedOrder->seller_id !== $seller->id) {
                throw new RolePermissionDeniedException('Bạn không có quyền xử lý đơn hàng này.');
            }

            $orderStatus = $lockedOrder->order_status instanceof OrderStatus
                ? $lockedOrder->order_status->value
                : (string) $lockedOrder->order_status;

            if ($orderStatus !== 'PREPARING') {
                throw new InvalidStateTransitionException('Chỉ có thể giao vận đơn hàng đang ở trạng thái chuẩn bị hàng (PREPARING).');
            }

            if ($lockedOrder->cancellation_requested) {
                throw new InvalidStateTransitionException('Đơn hàng đang có yêu cầu hủy từ người mua. Vui lòng phản hồi yêu cầu hủy trước khi giao vận.');
            }

            $carrierName = trim($shipmentData['carrier_name'] ?? 'Giao Hàng Nhanh');
            $trackingCode = trim($shipmentData['tracking_code'] ?? 'TRK-' . strtoupper(substr(md5((string) time()), 0, 10)));
            $shippingNote = isset($shipmentData['shipping_note']) ? trim($shipmentData['shipping_note']) : null;

            $shipment = Shipment::updateOrCreate(
                ['order_id' => $lockedOrder->id],
                [
                    'carrier_name' => $carrierName,
                    'tracking_code' => $trackingCode,
                    'shipping_note' => $shippingNote,
                    'status' => 'SHIPPED',
                    'shipped_at' => now(),
                    'updated_by' => $seller->id,
                ]
            );

            $lockedOrder->update([
                'order_status' => OrderStatus::SHIPPED,
                'shipped_at' => now(),
            ]);

            Notification::create([
                'user_id' => $lockedOrder->buyer_id,
                'type' => 'ORDER_SHIPPED',
                'title' => 'Đơn hàng đã được giao cho đơn vị vận chuyển',
                'body' => "Đơn hàng #{$lockedOrder->order_code} đã được gửi qua {$carrierName} (Mã vận đơn: {$trackingCode}).",
                'target_type' => 'orders',
                'target_id' => $lockedOrder->id,
                'deep_link_route' => "/buyer/orders/{$lockedOrder->id}",
                'is_read' => false,
            ]);

            return $lockedOrder->fresh(['items', 'buyer.profile', 'shipment']);
        });
    }

    /**
     * Seller marks order as delivered and freezes auto_complete_at timestamp (BR-OR-05 / ADR-05).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function markDelivered(User $seller, Order $order): Order
    {
        return DB::transaction(function () use ($seller, $order) {
            /** @var Order $lockedOrder */
            $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->firstOrFail();

            if ($lockedOrder->seller_id !== $seller->id) {
                throw new RolePermissionDeniedException('Bạn không có quyền xử lý đơn hàng này.');
            }

            $orderStatus = $lockedOrder->order_status instanceof OrderStatus
                ? $lockedOrder->order_status->value
                : (string) $lockedOrder->order_status;

            if ($orderStatus !== 'SHIPPED') {
                throw new InvalidStateTransitionException('Chỉ có thể đánh dấu đã giao cho đơn hàng đang ở trạng thái SHIPPED.');
            }

            $shipment = Shipment::where('order_id', $lockedOrder->id)->first();
            if ($shipment) {
                $shipment->update([
                    'status' => 'DELIVERED',
                    'delivered_at' => now(),
                    'updated_by' => $seller->id,
                ]);
            } else {
                Shipment::create([
                    'order_id' => $lockedOrder->id,
                    'carrier_name' => 'Giao hàng trực tiếp',
                    'tracking_code' => 'LOCAL-DIRECT',
                    'status' => 'DELIVERED',
                    'delivered_at' => now(),
                    'updated_by' => $seller->id,
                ]);
            }

            $durationSeconds = $this->platformConfigService->orderAutoCompleteDurationSeconds();
            $autoCompleteAt = now()->addSeconds($durationSeconds);

            $lockedOrder->update([
                'order_status' => OrderStatus::DELIVERED,
                'delivered_at' => now(),
                'auto_complete_at' => $autoCompleteAt,
            ]);

            Notification::create([
                'user_id' => $lockedOrder->buyer_id,
                'type' => 'ORDER_DELIVERED',
                'title' => 'Đơn hàng đã được giao thành công',
                'body' => "Đơn hàng #{$lockedOrder->order_code} đã được giao tới bạn. Vui lòng kiểm tra và xác nhận nhận hàng.",
                'target_type' => 'orders',
                'target_id' => $lockedOrder->id,
                'deep_link_route' => "/buyer/orders/{$lockedOrder->id}",
                'is_read' => false,
            ]);

            return $lockedOrder->fresh(['items', 'buyer.profile', 'shipment']);
        });
    }
}
