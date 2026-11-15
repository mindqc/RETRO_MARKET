<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ProductSummaryResource;
use App\Http\Resources\Api\V1\ReviewResource;
use App\Http\Resources\Api\V1\SellerPublicProfileResource;
use App\Services\Catalog\SellerStorefrontService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SellerStorefrontController extends Controller
{
    public function __construct(
        protected SellerStorefrontService $sellerService
    ) {}

    /**
     * Get seller public storefront details and products (M-US-03).
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $tab = $request->query('tab', 'approved');
        $perPage = (int) $request->query('per_page', 12);

        $result = $this->sellerService->getPublicStorefront(
            $id,
            $request->user(),
            $tab,
            $perPage
        );

        $paginator = $result['products'];

        return ApiResponse::success([
            'seller' => new SellerPublicProfileResource($result['seller']),
            'followers_count' => $result['followers_count'],
            'is_following' => $result['is_following'],
            'is_owner' => $result['is_owner'],
            'products' => ProductSummaryResource::collection($paginator->items()),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
                'has_more_pages' => $paginator->hasMorePages(),
            ],
        ], 'Lấy thông tin tiệm thành công.');
    }

    /**
     * Get verified buyer reviews for seller storefront (M-US-03).
     */
    public function reviews(Request $request, int $id): JsonResponse
    {
        $rating = $request->query('rating') !== null ? (int) $request->query('rating') : null;
        $perPage = (int) $request->query('per_page', 10);

        $reviews = $this->sellerService->getSellerVerifiedReviews($id, $rating, $perPage);

        return ApiResponse::paginated(
            $reviews,
            ReviewResource::collection($reviews->items()),
            'Lấy danh sách đánh giá thành công.'
        );
    }
}
