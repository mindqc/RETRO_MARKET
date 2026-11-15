<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Engagement\StoreReviewRequest;
use App\Http\Resources\Api\V1\ReviewResource;
use App\Models\Order;
use App\Services\Engagement\ReviewService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class ReviewController extends Controller
{
    public function __construct(
        protected ReviewService $reviewService
    ) {}

    /**
     * Submit verified order review (BR-RV-01).
     */
    public function store(StoreReviewRequest $request, int $id): JsonResponse
    {
        $order = Order::findOrFail($id);

        $review = $this->reviewService->createVerifiedOrderReview(
            $request->user(),
            $order,
            (int) $request->input('rating'),
            (string) $request->input('comment')
        );

        return ApiResponse::created(
            new ReviewResource($review),
            'Đánh giá đơn hàng thành công.'
        );
    }
}
