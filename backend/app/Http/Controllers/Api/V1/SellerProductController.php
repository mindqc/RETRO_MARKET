<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Product\StoreProductRequest;
use App\Http\Requests\Api\V1\Product\UpdateProductRequest;
use App\Http\Resources\Api\V1\ProductDetailResource;
use App\Http\Resources\Api\V1\ProductSummaryResource;
use App\Models\Product;
use App\Services\Product\SellerProductService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SellerProductController extends Controller
{
    public function __construct(
        protected SellerProductService $sellerProductService
    ) {}

    /**
     * Get seller dashboard metrics and action item counters (M-SL-01).
     */
    public function dashboard(Request $request): JsonResponse
    {
        $metrics = $this->sellerProductService->getSellerDashboardMetrics($request->user());

        return ApiResponse::success(
            $metrics,
            'Lấy dữ liệu bảng điều khiển người bán thành công.'
        );
    }

    /**
     * List all seller listings (M-SL-02).
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = (int) $request->query('per_page', 12);
        $products = $this->sellerProductService->listSellerProducts(
            $request->user(),
            $request->only(['status', 'listing_type']),
            $perPage
        );

        return ApiResponse::paginated(
            $products,
            ProductSummaryResource::collection($products->items()),
            'Lấy danh sách bài đăng thành công.'
        );
    }

    /**
     * Create a new product listing (M-SL-03).
     */
    public function store(StoreProductRequest $request): JsonResponse
    {
        $product = $this->sellerProductService->createListing(
            $request->user(),
            $request->validated(),
            $request->file('images', [])
        );

        return ApiResponse::created(
            new ProductDetailResource($product),
            'Đăng bán sản phẩm thành công.'
        );
    }

    /**
     * Update product listing or resubmit rejected listing (M-SL-04).
     */
    public function update(UpdateProductRequest $request, int $id): JsonResponse
    {
        $product = Product::findOrFail($id);

        $updatedProduct = $this->sellerProductService->updateOrResubmitListing(
            $request->user(),
            $product,
            $request->validated(),
            $request->file('images', [])
        );

        return ApiResponse::success(
            new ProductDetailResource($updatedProduct),
            'Cập nhật bài đăng thành công.'
        );
    }

    /**
     * Change listing status (HIDDEN, ARCHIVED, DRAFT).
     */
    public function updateStatus(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'status' => ['required', 'string', 'in:DRAFT,HIDDEN,ARCHIVED'],
        ]);

        $product = Product::findOrFail($id);

        $updated = $this->sellerProductService->changeSellerListingStatus(
            $request->user(),
            $product,
            $request->input('status')
        );

        return ApiResponse::success(
            new ProductDetailResource($updated),
            'Cập nhật trạng thái bài đăng thành công.'
        );
    }
}
