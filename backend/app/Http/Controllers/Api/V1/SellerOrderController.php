<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Order\ShipOrderRequest;
use App\Http\Resources\Api\V1\OrderResource;
use App\Models\Order;
use App\Services\Order\OrderFulfillmentService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SellerOrderController extends Controller
{
    public function __construct(
        protected OrderFulfillmentService $fulfillmentService
    ) {}

    /**
     * List orders for the authenticated seller (M-SL-05).
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 12);
        $paginator = $this->fulfillmentService->listSellerOrders($request->user(), $request->all(), $perPage);

        return ApiResponse::paginated(
            $paginator,
            OrderResource::collection($paginator->items()),
            'Lấy danh sách đơn bán thành công.'
        );
    }

    /**
     * Seller marks order as preparing (M-SL-06 / PAID -> PREPARING).
     */
    public function prepare(Request $request, int $id): JsonResponse
    {
        $order = Order::findOrFail($id);
        $updatedOrder = $this->fulfillmentService->markPreparing($request->user(), $order);

        return ApiResponse::success(
            new OrderResource($updatedOrder),
            'Đã chuyển đơn hàng sang trạng thái chuẩn bị hàng.'
        );
    }

    /**
     * Seller marks order as shipped with tracking details (M-SL-07 / PREPARING -> SHIPPED).
     */
    public function ship(ShipOrderRequest $request, int $id): JsonResponse
    {
        $order = Order::findOrFail($id);
        $updatedOrder = $this->fulfillmentService->shipOrder($request->user(), $order, $request->validated());

        return ApiResponse::success(
            new OrderResource($updatedOrder),
            'Đã cập nhật vận đơn và giao hàng cho đơn vị vận chuyển.'
        );
    }

    /**
     * Seller marks order as delivered (SHIPPED -> DELIVERED) and freezes auto_complete_at.
     */
    public function deliver(Request $request, int $id): JsonResponse
    {
        $order = Order::findOrFail($id);
        $updatedOrder = $this->fulfillmentService->markDelivered($request->user(), $order);

        return ApiResponse::success(
            new OrderResource($updatedOrder),
            'Đã đánh dấu đơn hàng được giao thành công.'
        );
    }
}
