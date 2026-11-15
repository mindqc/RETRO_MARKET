<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Product\ProductSearchRequest;
use App\Http\Resources\Api\V1\ProductDetailResource;
use App\Http\Resources\Api\V1\ProductSummaryResource;
use App\Services\Product\ProductDiscoveryService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function __construct(
        protected ProductDiscoveryService $discoveryService
    ) {}

    /**
     * Search and filter public approved products (M-DS-02).
     */
    public function index(ProductSearchRequest $request): JsonResponse
    {
        $perPage = (int) $request->query('per_page', 12);
        $products = $this->discoveryService->searchPublicProducts(
            $request->validated(),
            $request->user(),
            $perPage
        );

        return ApiResponse::paginated(
            $products,
            ProductSummaryResource::collection($products->items()),
            'Tìm kiếm sản phẩm thành công.'
        );
    }

    /**
     * Get detailed product information (M-PR-01).
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $result = $this->discoveryService->getProductDetail($id, $request->user());

        return ApiResponse::success([
            'product' => new ProductDetailResource($result['product']),
            'is_owner' => $result['is_owner'],
            'is_favorited' => $result['is_favorited'],
            'related_products' => ProductSummaryResource::collection($result['related_products']),
        ], 'Lấy thông tin chi tiết sản phẩm thành công.');
    }
}
