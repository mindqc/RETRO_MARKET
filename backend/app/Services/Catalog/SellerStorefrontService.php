<?php

namespace App\Services\Catalog;

use App\Enums\ProductStatus;
use App\Enums\UserStatus;
use App\Exceptions\ResourceNotAvailableException;
use App\Models\Product;
use App\Models\Review;
use App\Models\SellerFollow;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class SellerStorefrontService
{
    /**
     * Get public storefront details and approved products by tab (M-US-03 / BR-PR-02).
     *
     * @throws ResourceNotAvailableException
     */
    public function getPublicStorefront(int $sellerId, ?User $viewer = null, string $tab = 'approved', int $perPage = 12): array
    {
        $seller = User::query()
            ->where('id', $sellerId)
            ->where('status', UserStatus::ACTIVE)
            ->with(['profile', 'sellerProfile'])
            ->first();

        if (! $seller || ! $seller->sellerProfile) {
            throw new ResourceNotAvailableException('Người bán không tồn tại hoặc tài khoản đã bị khóa.');
        }

        $followersCount = SellerFollow::where('seller_id', $sellerId)->count();
        $isFollowing = $viewer ? SellerFollow::where('follower_id', $viewer->id)->where('seller_id', $sellerId)->exists() : false;
        $isOwner = $viewer ? ($viewer->id === $seller->id) : false;

        $productQuery = Product::query()
            ->where('seller_id', $sellerId)
            ->with(['primaryImage', 'category', 'brand']);

        // Strict BR-PR-02: Never expose DRAFT, PENDING_REVIEW, REJECTED, or HIDDEN products to public storefront
        match (strtolower($tab)) {
            'auction' => $productQuery->where('status', ProductStatus::APPROVED)->where('listing_type', 'AUCTION'),
            'sold' => $productQuery->where('status', ProductStatus::SOLD),
            'fixed_price' => $productQuery->where('status', ProductStatus::APPROVED)->where('listing_type', 'FIXED_PRICE'),
            default => $productQuery->where('status', ProductStatus::APPROVED),
        };

        $products = $productQuery->latest('id')->paginate($perPage);

        if ($viewer) {
            $favoritedIds = $viewer->favorites()->pluck('product_id')->flip()->toArray();
            $products->getCollection()->each(function (Product $product) use ($favoritedIds, $viewer) {
                $product->is_favorited = isset($favoritedIds[$product->id]);
                $product->is_owner = ($product->seller_id === $viewer->id);
            });
        }

        return [
            'seller' => $seller,
            'followers_count' => $followersCount,
            'is_following' => $isFollowing,
            'is_owner' => $isOwner,
            'products' => $products,
        ];
    }

    /**
     * Get verified buyer reviews for seller storefront (M-US-03 / BR-RV-01).
     */
    public function getSellerVerifiedReviews(int $sellerId, ?int $rating = null, int $perPage = 10): LengthAwarePaginator
    {
        $query = Review::query()
            ->where('seller_id', $sellerId)
            ->where('status', 'VISIBLE')
            ->with(['reviewer.profile', 'product.primaryImage']);

        if ($rating !== null && $rating >= 1 && $rating <= 5) {
            $query->where('rating', $rating);
        }

        return $query->latest('id')->paginate($perPage);
    }
}
