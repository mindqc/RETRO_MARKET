<?php

namespace App\Services\Catalog;

use App\Enums\AuctionStatus;
use App\Enums\ProductStatus;
use App\Enums\UserStatus;
use App\Models\Auction;
use App\Models\Category;
use App\Models\Product;
use App\Models\SellerProfile;
use App\Models\User;

class HomeDiscoveryService
{
    /**
     * Build aggregated home discovery feed for mobile app (M-HM-01).
     * Enforces BR-PR-02 (only APPROVED products) and eager loading to prevent N+1.
     */
    public function getHomeFeed(?User $viewer = null): array
    {
        // 1. Featured Categories (root categories)
        $categories = Category::query()
            ->whereNull('parent_id')
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->limit(8)
            ->get();

        // 2. Ongoing Live Auctions
        $liveAuctions = Auction::query()
            ->where('status', AuctionStatus::LIVE)
            ->where('auction_ends_at', '>', now())
            ->with(['product.primaryImage', 'seller.sellerProfile'])
            ->orderBy('auction_ends_at', 'asc')
            ->limit(6)
            ->get();

        // 3. Featured Trusted Sellers
        $featuredSellers = SellerProfile::query()
            ->whereHas('user', function ($query) {
                $query->where('status', UserStatus::ACTIVE);
            })
            ->with(['user.profile'])
            ->orderByDesc('trust_score')
            ->orderByDesc('completed_orders_count')
            ->limit(5)
            ->get();

        // 4. Latest Approved Fixed-Price In-Stock Products (Buy-Now ready)
        $latestProducts = Product::query()
            ->where('status', ProductStatus::APPROVED)
            ->where('listing_type', 'FIXED_PRICE')
            ->where('available_quantity', '>', 0)
            ->with(['primaryImage', 'seller.profile', 'seller.sellerProfile', 'category', 'brand'])
            ->latest('approved_at')
            ->latest('id')
            ->limit(20)
            ->get();

        // Attach viewer context (is_favorited, is_owner)
        if ($viewer) {
            $favoritedIds = $viewer->favorites()->pluck('product_id')->flip()->toArray();

            $latestProducts->each(function (Product $product) use ($favoritedIds, $viewer) {
                $product->is_favorited = isset($favoritedIds[$product->id]);
                $product->is_owner = ($product->seller_id === $viewer->id);
            });
        } else {
            $latestProducts->each(function (Product $product) {
                $product->is_favorited = false;
                $product->is_owner = false;
            });
        }

        return [
            'categories' => $categories,
            'live_auctions' => $liveAuctions,
            'featured_sellers' => $featuredSellers,
            'latest_products' => $latestProducts,
        ];
    }
}
