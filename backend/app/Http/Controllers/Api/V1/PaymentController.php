<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\OrderResource;
use App\Http\Resources\Api\V1\PaymentResource;
use App\Services\Escrow\MockQrPaymentService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function __construct(
        protected MockQrPaymentService $paymentService
    ) {}

    /**
     * Get payment QR session details (M-PM-01).
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $payment = $this->paymentService->getPaymentSession($request->user(), $id);

        return ApiResponse::success([
            'payment' => new PaymentResource($payment),
            'order' => new OrderResource($payment->order),
        ], 'Lấy thông tin phiên thanh toán thành công.');
    }

    /**
     * Simulate QR payment success with idempotent Escrow hold (M-PM-02 / BR-FN-03).
     */
    public function simulateSuccess(Request $request, int $id): JsonResponse
    {
        $result = $this->paymentService->simulateSuccess($request->user(), $id);

        return ApiResponse::success([
            'payment' => new PaymentResource($result['payment']),
            'order' => new OrderResource($result['order']),
            'idempotent_replay' => $result['idempotent_replay'],
        ], $result['idempotent_replay']
            ? 'Đơn hàng đã được thanh toán thành công trước đó (Phát lại lũy đẳng).'
            : 'Giả lập thanh toán QR thành công. Tiền đã được giữ an toàn trong Escrow.');
    }

    /**
     * Simulate QR payment failure and issue new retry session (M-PM-02).
     */
    public function simulateFailure(Request $request, int $id): JsonResponse
    {
        $reason = $request->input('reason');
        $result = $this->paymentService->simulateFailure($request->user(), $id, $reason);

        return ApiResponse::success([
            'failed_payment' => new PaymentResource($result['failed_payment']),
            'new_payment' => new PaymentResource($result['new_payment']),
            'order' => new OrderResource($result['order']),
        ], 'Đã ghi nhận giao dịch thanh toán thất bại. Bạn có thể quét mã QR mới để thanh toán lại.');
    }
}
