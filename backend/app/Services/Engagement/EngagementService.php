<?php

namespace App\Services\Engagement;

use App\Exceptions\SelfTransactionForbiddenException;
use App\Models\Favorite;
use App\Models\Product;
use App\Models\SellerFollow;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class EngagementService
{
    /**
     * Toggle favorite status for a product and update product's favorite_count.
     */
    public function toggleFavoriteProduct(User $user, Product $product): array
    {
        return DB::transaction(function () use ($user, $product) {
            $favorite = Favorite::where('user_id', $user->id)
                ->where('product_id', $product->id)
                ->first();

            if ($favorite) {
                $favorite->delete();
                $isFavorited = false;
            } else {
                Favorite::create([
                    'user_id' => $user->id,
                    'product_id' => $product->id,
                ]);
                $isFavorited = true;
            }

            $count = Favorite::where('product_id', $product->id)->count();
            $product->update(['favorite_count' => $count]);

            return [
                'is_favorited' => $isFavorited,
                'favorite_count' => $count,
            ];
        });
    }

    /**
     * List user favorite products with eager loaded relationships.
     */
    public function listFavoriteProducts(User $user, int $perPage = 12): LengthAwarePaginator
    {
        return Product::whereIn('id', Favorite::where('user_id', $user->id)->select('product_id'))
            ->with([
                'primaryImage',
                'seller.sellerProfile',
                'category',
                'brand',
            ])
            ->orderBy('id', 'desc')
            ->paginate($perPage);
    }

    /**
     * Toggle following a seller and prevent self-following (BR-AC-02).
     */
    public function toggleFollowSeller(User $follower, int $sellerId): array
    {
        if ($follower->id === $sellerId) {
            throw new SelfTransactionForbiddenException('Không thể tự theo dõi chính mình (BR-AC-02).');
        }

        $seller = User::findOrFail($sellerId);

        return DB::transaction(function () use ($follower, $seller) {
            $follow = SellerFollow::where('follower_id', $follower->id)
                ->where('seller_id', $seller->id)
                ->first();

            if ($follow) {
                $follow->delete();
                $isFollowing = false;
            } else {
                SellerFollow::create([
                    'follower_id' => $follower->id,
                    'seller_id' => $seller->id,
                ]);
                $isFollowing = true;
            }

            $followersCount = SellerFollow::where('seller_id', $seller->id)->count();

            return [
                'is_following' => $isFollowing,
                'followers_count' => $followersCount,
            ];
        });
    }
}
