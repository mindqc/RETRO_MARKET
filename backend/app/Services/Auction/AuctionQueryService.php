<?php

namespace App\Services\Auction;

use App\Enums\AuctionStatus;
use App\Models\Auction;
use App\Models\AuctionBid;
use App\Models\AuctionWatch;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class AuctionQueryService
{
    /**
     * List auctions for Auction Hub (M-AC-01) supporting tabs: live, ending_soon, upcoming, completed.
     */
    public function listHubAuctions(array $filters = [], ?User $viewer = null, int $perPage = 12): LengthAwarePaginator
    {
        $tab = strtolower(trim($filters['tab'] ?? 'live'));

        $query = Auction::query()
            ->with([
                'product.primaryImage',
                'product.category',
                'seller.sellerProfile',
                'session',
                'leadingBidder.profile',
            ]);

        // Tab filters
        match ($tab) {
            'ending_soon' => $query->where('status', AuctionStatus::LIVE)
                ->orderBy('auction_ends_at', 'asc'),
            'upcoming' => $query->where('status', AuctionStatus::SCHEDULED)
                ->orderBy('auction_starts_at', 'asc'),
            'completed' => $query->whereIn('status', [
                AuctionStatus::COMPLETED,
                AuctionStatus::ENDED_UNSOLD,
                AuctionStatus::WINNER_DEFAULTED,
            ])->orderByDesc('closed_at')->orderByDesc('id'),
            default => $query->where('status', AuctionStatus::LIVE)
                ->orderBy('auction_ends_at', 'asc'),
        };

        // Filter by category_id
        if (!empty($filters['category_id'])) {
            $catId = (int) $filters['category_id'];
            $query->whereHas('product', function ($q) use ($catId) {
                $q->where('category_id', $catId);
            });
        }

        // Filter by session_id
        if (!empty($filters['session_id'])) {
            $query->where('session_id', (int) $filters['session_id']);
        }

        // Filter by search query
        if (!empty($filters['q'])) {
            $keyword = trim($filters['q']);
            $query->where(function ($sub) use ($keyword) {
                $sub->where('auction_code', 'ilike', "%{$keyword}%")
                    ->orWhereHas('product', function ($prodQuery) use ($keyword) {
                        $prodQuery->where('title', 'ilike', "%{$keyword}%");
                    });
            });
        }

        return $query->paginate($perPage);
    }

    /**
     * List user's personal auction activities (M-AC-02): participating, watchlist, won.
     */
    public function listMyAuctions(User $user, string $tab = 'participating', int $perPage = 12): LengthAwarePaginator
    {
        $tab = strtolower(trim($tab));

        if ($tab === 'watchlist') {
            return Auction::whereHas('watches', function ($q) use ($user) {
                $q->where('user_id', $user->id);
            })
            ->with([
                'product.primaryImage',
                'product.category',
                'seller.sellerProfile',
                'session',
                'leadingBidder.profile',
            ])
            ->orderBy('auction_ends_at', 'asc')
            ->paginate($perPage);
        }

        if ($tab === 'won') {
            return Auction::where('winner_id', $user->id)
                ->with([
                    'product.primaryImage',
                    'product.category',
                    'seller.sellerProfile',
                    'session',
                    'order.payments',
                ])
                ->orderByDesc('closed_at')
                ->paginate($perPage);
        }

        // Default: participating
        $paginator = Auction::whereHas('bids', function ($q) use ($user) {
            $q->where('bidder_id', $user->id);
        })
        ->with([
            'product.primaryImage',
            'product.category',
            'seller.sellerProfile',
            'session',
            'leadingBidder.profile',
        ])
        ->orderBy('auction_ends_at', 'asc')
        ->paginate($perPage);

        // Decorate with user's highest bid and leading status
        $paginator->getCollection()->transform(function (Auction $auction) use ($user) {
            $myHighestBid = AuctionBid::where('auction_id', $auction->id)
                ->where('bidder_id', $user->id)
                ->max('bid_amount');

            $isLeading = ((int) $auction->leading_bidder_id === (int) $user->id);

            $auction->my_highest_bid = $myHighestBid;
            $auction->my_bid_status = $isLeading ? 'LEADING' : 'OUTBID';

            return $auction;
        });

        return $paginator;
    }

    /**
     * Get comprehensive room detail for an auction (M-AC-03).
     * Strictly hides secret reserve_price if viewer is buyer and reserve not yet met.
     */
    public function getAuctionRoomDetail(int $auctionId, ?User $viewer = null): array
    {
        /** @var Auction $auction */
        $auction = Auction::with([
            'product.images',
            'product.category',
            'product.brand',
            'seller.profile',
            'seller.sellerProfile',
            'session',
            'leadingBidder.profile',
            'winner.profile',
            'order.payments',
        ])->findOrFail($auctionId);

        $isOwner = ($viewer !== null && (int) $viewer->id === (int) $auction->seller_id);
        $isStaff = ($viewer !== null && $viewer->isInternalStaff());
        $isWatching = ($viewer !== null && AuctionWatch::where('auction_id', $auction->id)->where('user_id', $viewer->id)->exists());
        $isLeading = ($viewer !== null && (int) $viewer->id === (int) $auction->leading_bidder_id);

        $reservePriceMet = ($auction->reserve_price === null || (float) $auction->current_highest_bid >= (float) $auction->reserve_price);
        $minimumNextBid = $auction->minimumNextBidAmount();

        // Privacy: Only seller or internal staff see the secret reserve_price before it is met
        $revealReservePrice = $isOwner || $isStaff || $reservePriceMet;

        $recentBids = AuctionBid::where('auction_id', $auction->id)
            ->with('bidder.profile')
            ->orderByDesc('id')
            ->limit(10)
            ->get();

        return [
            'auction' => $auction,
            'server_time' => now()->toIso8601String(),
            'minimum_next_bid' => (float) $minimumNextBid,
            'has_reserve_price' => $auction->reserve_price !== null,
            'reserve_price_met' => $reservePriceMet,
            'reserve_price' => $revealReservePrice ? (float) $auction->reserve_price : null,
            'is_owner' => $isOwner,
            'is_watching' => $isWatching,
            'is_leading' => $isLeading,
            'recent_bids' => $recentBids,
        ];
    }

    /**
     * List all bids of an auction with pagination.
     */
    public function listAuctionBids(int $auctionId, int $perPage = 20): LengthAwarePaginator
    {
        return AuctionBid::where('auction_id', $auctionId)
            ->with('bidder.profile')
            ->orderByDesc('id')
            ->paginate($perPage);
    }

    /**
     * Toggle watch / unwatch an auction (M-AC-01 / Watchlist).
     */
    public function toggleWatch(User $user, int $auctionId): array
    {
        return DB::transaction(function () use ($user, $auctionId) {
            $watch = AuctionWatch::where('auction_id', $auctionId)
                ->where('user_id', $user->id)
                ->first();

            $isWatching = false;
            if ($watch) {
                $watch->delete();
            } else {
                AuctionWatch::create([
                    'auction_id' => $auctionId,
                    'user_id' => $user->id,
                ]);
                $isWatching = true;
            }

            $watchCount = AuctionWatch::where('auction_id', $auctionId)->count();
            Auction::where('id', $auctionId)->update(['watch_count' => $watchCount]);

            return [
                'is_watching' => $isWatching,
                'watch_count' => $watchCount,
            ];
        });
    }
}
