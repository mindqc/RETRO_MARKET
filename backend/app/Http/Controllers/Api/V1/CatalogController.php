<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\BrandResource;
use App\Http\Resources\Api\V1\CategoryResource;
use App\Http\Resources\Api\V1\ProductSummaryResource;
use App\Services\Catalog\CatalogTaxonomyService;
use App\Services\Catalog\HomeDiscoveryService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    /**
     * Home feed discovery endpoint (M-HM-01).
     */
    public function home(Request $request, HomeDiscoveryService $homeService): JsonResponse
    {
        $feed = $homeService->getHomeFeed($request->user());

        return ApiResponse::success([
            'categories' => CategoryResource::collection($feed['categories']),
            'live_auctions' => $feed['live_auctions'],
            'featured_sellers' => $feed['featured_sellers'],
            'latest_products' => ProductSummaryResource::collection($feed['latest_products']),
        ], 'Lấy dữ liệu trang chủ thành công.');
    }

    /**
     * Active categories and brands taxonomy endpoint (M-DS-01).
     */
    public function taxonomy(CatalogTaxonomyService $taxonomyService): JsonResponse
    {
        $taxonomy = $taxonomyService->getActiveTaxonomy();

        return ApiResponse::success([
            'categories' => CategoryResource::collection($taxonomy['categories']),
            'brands' => BrandResource::collection($taxonomy['brands']),
        ], 'Lấy danh mục và thương hiệu thành công.');
    }
}
