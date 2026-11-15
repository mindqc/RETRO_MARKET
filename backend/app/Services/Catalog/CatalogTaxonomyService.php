<?php

namespace App\Services\Catalog;

use App\Enums\ProductStatus;
use App\Models\Brand;
use App\Models\Category;

class CatalogTaxonomyService
{
    /**
     * Retrieve active hierarchical category tree and active brands (M-DS-01).
     */
    public function getActiveTaxonomy(): array
    {
        $categories = Category::query()
            ->whereNull('parent_id')
            ->where('is_active', true)
            ->with(['children' => function ($query) {
                $query->where('is_active', true)
                    ->withCount(['products as approved_products_count' => function ($pq) {
                        $pq->where('status', ProductStatus::APPROVED);
                    }])
                    ->orderBy('sort_order');
            }])
            ->withCount(['products as approved_products_count' => function ($query) {
                $query->where('status', ProductStatus::APPROVED);
            }])
            ->orderBy('sort_order')
            ->get();

        $brands = Brand::query()
            ->where('is_active', true)
            ->withCount(['products as approved_products_count' => function ($query) {
                $query->where('status', ProductStatus::APPROVED);
            }])
            ->orderBy('name')
            ->get();

        return [
            'categories' => $categories,
            'brands' => $brands,
        ];
    }
}
