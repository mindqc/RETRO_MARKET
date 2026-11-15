<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\RolePermissionDeniedException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Order\CancelOrderRequest;
use App\Http\Requests\Api\V1\Order\RespondCancelOrderRequest;
use App\Http\Resources\Api\V1\OrderResource;
use App\Models\Order;
use App\Services\Escrow\EscrowReleaseService;
use App\Services\Order\OrderCancellationService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BuyerOrderController extends Controller
{
    public function __construct(
        protected OrderCancellationService $cancellationService,
        protected EscrowReleaseService $escrowReleaseService
    ) {}

    /**
     * List current buyer purchases (M-OR-03).
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = (int) $request->query('per_page', 10);
        $status = $request->query('status');

        $query = Order::query()
            ->where('buyer_id', $request->user()->id)
            ->with(['items', 'seller.sellerProfile', 'payments'])
            ->latest('id');

        if (! empty($status)) {
            $query->where('order_status', strtoupper($status));
        }

        $orders = $query->paginate($perPage);

        return ApiResponse::paginated(
            $orders,
            OrderResource::collection($orders->items()),
            'Lấy danh sách đơn mua thành công.'
        );
    }

    /**
     * Get detailed order information (M-OR-04).
     *
     * @throws RolePermissionDeniedException
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $order = Order::with(['items', 'seller.sellerProfile', 'buyer', 'payments'])->findOrFail($id);
        $user = $request->user();

        if ($user->id !== $order->buyer_id && $user->id !== $order->seller_id && ! $user->isInternalStaff()) {
            throw new RolePermissionDeniedException('Bạn không có quyền xem thông tin đơn hàng này.');
        }

        return ApiResponse::success(
            new OrderResource($order),
            'Lấy thông tin chi tiết đơn hàng thành công.'
        );
    }

    /**
     * Cancel order or request cancellation (M-OR-04 / DEC-06).
     */
    public function cancel(CancelOrderRequest $request, int $id): JsonResponse
    {
        $order = Order::findOrFail($id);
        $cancelledOrder = $this->cancellationService->buyerCancelOrRequest(
            $request->user(),
            $order,
            $request->input('reason')
        );

        $msg = $cancelledOrder->cancellation_requested
            ? 'Đã gửi yêu cầu hủy đơn hàng đến người bán.'
            : 'Hủy đơn hàng thành công.';

        return ApiResponse::success(
            new OrderResource($cancelledOrder),
            $msg
        );
    }

    /**
     * Buyer withdraws pending cancellation request in PREPARING status (UX-CHECK-02).
     */
    public function withdrawCancelRequest(Request $request, int $id): JsonResponse
    {
        $order = Order::findOrFail($id);
        $updatedOrder = $this->cancellationService->buyerWithdrawCancelRequest(
            $request->user(),
            $order
        );

        return ApiResponse::success(
            new OrderResource($updatedOrder),
            'Đã rút lại yêu cầu hủy đơn hàng thành công.'
        );
    }

    /**
     * Seller responds to buyer cancellation request (M-SL-06 / DEC-06 / DEC-07).
     */
    public function sellerRespondCancel(RespondCancelOrderRequest $request, int $id): JsonResponse
    {
        $order = Order::findOrFail($id);
        $updatedOrder = $this->cancellationService->sellerRespondCancelRequest(
            $request->user(),
            $order,
            $request->input('decision'),
            $request->input('note')
        );

        $isApproved = strtoupper($request->input('decision')) === 'APPROVE';
        $msg = $isApproved
            ? 'Đã chấp thuận yêu cầu hủy đơn hàng. Tiền đã được hoàn lại 100% cho người mua.'
            : 'Đã từ chối yêu cầu hủy đơn hàng. Tiếp tục chuẩn bị đóng gói sản phẩm.';

        return ApiResponse::success(
            new OrderResource($updatedOrder),
            $msg
        );
    }

    /**
     * Buyer confirms delivery of order, releasing 100% item_subtotal to seller (OF-05 / DEC-04).
     */
    public function confirmDelivery(Request $request, int $id): JsonResponse
    {
        $order = Order::findOrFail($id);
        $completedOrder = $this->escrowReleaseService->confirmDeliveryByBuyer(
            $request->user(),
            $order
        );

        return ApiResponse::success(
            new OrderResource($completedOrder),
            'Xác nhận nhận hàng thành công. Tiền hàng đã được giải ngân cho người bán.'
        );
    }
}
