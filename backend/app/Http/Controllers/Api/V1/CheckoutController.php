<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Order\CheckoutPreviewRequest;
use App\Http\Requests\Api\V1\Order\PlaceOrderRequest;
use App\Http\Resources\Api\V1\OrderResource;
use App\Http\Resources\Api\V1\PaymentResource;
use App\Services\Order\CheckoutService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class CheckoutController extends Controller
{
    public function __construct(
        protected CheckoutService $checkoutService
    ) {}

    /**
     * Preview checkout breakdown with Buyer Protection Fee (M-OR-01 / DEC-04).
     */
    public function preview(CheckoutPreviewRequest $request): JsonResponse
    {
        $breakdown = $this->checkoutService->previewCheckout(
            $request->user(),
            $request->validated()
        );

        return ApiResponse::success($breakdown, 'Xem trước bảng tính phí đặt hàng thành công.');
    }

    /**
     * Place order with pessimistic row-locking on products (M-OR-01 / OF-02).
     */
    public function placeOrder(PlaceOrderRequest $request): JsonResponse
    {
        $result = $this->checkoutService->placeOrder(
            $request->user(),
            $request->validated()
        );

        return ApiResponse::created([
            'order' => new OrderResource($result['order']),
            'payment' => new PaymentResource($result['payment']),
            'orders' => OrderResource::collection($result['orders']),
        ], 'Đặt hàng thành công. Vui lòng thanh toán qua mã QR.');
    }
}
