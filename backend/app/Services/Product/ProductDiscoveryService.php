<?php

namespace App\Services\Product;

use App\Enums\ProductStatus;
use App\Exceptions\ResourceNotAvailableException;
use App\Models\Category;
use App\Models\Product;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ProductDiscoveryService
{
    /**
     * Search and filter approved public products with multi-criteria on PostgreSQL 18 (M-DS-02 / BR-PR-02).
     */
    public function searchPublicProducts(array $filters, ?User $viewer = null, int $perPage = 12): LengthAwarePaginator
    {
        $query = Product::query()
            ->where('status', ProductStatus::APPROVED)
            ->with(['primaryImage', 'seller.sellerProfile', 'category', 'brand', 'activeAuction']);

        // 1. Text Search (title, description, product_code) - ILIKE on PostgreSQL
        if (! empty($filters['q'])) {
            $kw = '%' . trim($filters['q']) . '%';
            $query->where(function ($q) use ($kw) {
                $q->where('title', 'ILIKE', $kw)
                    ->orWhere('description', 'ILIKE', $kw)
                    ->orWhere('product_code', 'ILIKE', $kw);
            });
        }

        // 2. Category Filter (including all child categories)
        if (! empty($filters['category_id'])) {
            $catId = (int) $filters['category_id'];
            $childIds = Category::where('parent_id', $catId)->pluck('id')->toArray();
            $allCategoryIds = array_merge([$catId], $childIds);
            $query->whereIn('category_id', $allCategoryIds);
        }

        // 3. Brand Filter
        if (! empty($filters['brand_id'])) {
            $query->where('brand_id', (int) $filters['brand_id']);
        }

        // 4. Listing Type Filter (FIXED_PRICE, AUCTION)
        if (! empty($filters['listing_type'])) {
            $query->where('listing_type', strtoupper($filters['listing_type']));
        }

        // 5. Condition Filter (LIKE_NEW, GOOD, FAIR, VINTAGE_WORN)
        if (! empty($filters['condition'])) {
            $query->where('condition', $filters['condition']);
        }

        // 6. Verification Level
        if (! empty($filters['verification_level'])) {
            $query->where('verification_level', $filters['verification_level']);
        }

        // 7. Price Range Filter
        if (isset($filters['min_price']) && is_numeric($filters['min_price'])) {
            $query->where('price', '>=', (float) $filters['min_price']);
        }
        if (isset($filters['max_price']) && is_numeric($filters['max_price'])) {
            $query->where('price', '<=', (float) $filters['max_price']);
        }

        // 8. Sorting
        match ($filters['sort'] ?? 'newest') {
            'price_asc' => $query->orderBy('price', 'asc')->orderByDesc('id'),
            'price_desc' => $query->orderBy('price', 'desc')->orderByDesc('id'),
            'popular' => $query->orderByDesc('favorite_count')->orderByDesc('id'),
            default => $query->orderByDesc('approved_at')->orderByDesc('id'),
        };

        $products = $query->paginate($perPage);

        // Attach viewer flags (is_favorited, is_owner)
        if ($viewer) {
            $favoritedIds = $viewer->favorites()->pluck('product_id')->flip()->toArray();
            $products->getCollection()->each(function (Product $product) use ($favoritedIds, $viewer) {
                $product->is_favorited = isset($favoritedIds[$product->id]);
                $product->is_owner = ($product->seller_id === $viewer->id);
            });
        } else {
            $products->getCollection()->each(function (Product $product) {
                $product->is_favorited = false;
                $product->is_owner = false;
            });
        }

        return $products;
    }

    /**
     * Get detailed product information with access control on unapproved items (M-PR-01 / BR-PR-02).
     *
     * @throws ResourceNotAvailableException
     */
    public function getProductDetail(int $productId, ?User $viewer = null): array
    {
        $product = Product::query()
            ->with([
                'images' => fn ($q) => $q->orderByDesc('is_primary')->orderBy('sort_order'),
                'seller.profile',
                'seller.sellerProfile',
                'category',
                'brand',
                'activeAuction',
                'moderationLogs.moderator',
            ])
            ->find($productId);

        if (! $product) {
            throw new ResourceNotAvailableException('Sản phẩm yêu cầu không tồn tại hoặc đã bị xóa.');
        }

        $status = $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status;

        // Unapproved products (DRAFT, PENDING_REVIEW, REJECTED, HIDDEN) are only visible to owner or internal staff
        if (! in_array($status, ['APPROVED', 'SOLD'], true)) {
            $canView = $viewer && ($viewer->id === $product->seller_id || $viewer->isInternalStaff());
            if (! $canView) {
                throw new ResourceNotAvailableException('Sản phẩm này chưa được phê duyệt hoặc đang tạm ẩn.');
            }
        }

        $isOwner = $viewer ? ($viewer->id === $product->seller_id) : false;
        $isFavorited = $viewer ? $viewer->favorites()->where('product_id', $product->id)->exists() : false;
        $canViewLogs = $isOwner || ($viewer && $viewer->isInternalStaff());

        // Related Products (up to 4 approved products in the same category)
        $relatedProducts = Product::query()
            ->where('category_id', $product->category_id)
            ->where('id', '!=', $product->id)
            ->where('status', ProductStatus::APPROVED)
            ->with(['primaryImage', 'seller.sellerProfile'])
            ->latest('approved_at')
            ->limit(4)
            ->get();

        return [
            'product' => $product,
            'is_owner' => $isOwner,
            'is_favorited' => $isFavorited,
            'can_view_logs' => $canViewLogs,
            'related_products' => $relatedProducts,
        ];
    }
}
