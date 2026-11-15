<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ProductSummaryResource;
use App\Models\Product;
use App\Services\Engagement\EngagementService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EngagementController extends Controller
{
    public function __construct(
        protected EngagementService $engagementService
    ) {}

    /**
     * Toggle favorite status for a product (M-PF-05).
     */
    public function toggleFavorite(Request $request, int $id): JsonResponse
    {
        $product = Product::findOrFail($id);
        $result = $this->engagementService->toggleFavoriteProduct($request->user(), $product);

        $message = $result['is_favorited']
            ? 'Đã thêm sản phẩm vào danh sách yêu thích.'
            : 'Đã xóa sản phẩm khỏi danh sách yêu thích.';

        return ApiResponse::success($result, $message);
    }

    /**
     * List user's favorite products (M-PF-05).
     */
    public function favorites(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 12);
        $paginator = $this->engagementService->listFavoriteProducts($request->user(), $perPage);

        return ApiResponse::paginated(
            $paginator,
            ProductSummaryResource::collection($paginator->getCollection()),
            'Lấy danh sách sản phẩm yêu thích thành công.'
        );
    }

    /**
     * Toggle follow seller (BR-AC-02).
     */
    public function toggleFollow(Request $request, int $id): JsonResponse
    {
        $result = $this->engagementService->toggleFollowSeller($request->user(), $id);

        $message = $result['is_following']
            ? 'Đã theo dõi tiệm thành công.'
            : 'Đã hủy theo dõi tiệm.';

        return ApiResponse::success($result, $message);
    }
}
