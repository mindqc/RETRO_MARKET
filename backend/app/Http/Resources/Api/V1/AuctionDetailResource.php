<?php

namespace App\Http\Resources\Api\V1;

use App\Enums\AuctionStatus;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AuctionDetailResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $viewer = $request->user();
        $isOwner = ($viewer !== null && (int) $viewer->id === (int) $this->seller_id);
        $isStaff = ($viewer !== null && $viewer->isInternalStaff());
        $reservePriceMet = ($this->reserve_price === null || (float) $this->current_highest_bid >= (float) $this->reserve_price);
        $revealReservePrice = $isOwner || $isStaff || $reservePriceMet;

        $statusVal = $this->status instanceof AuctionStatus ? $this->status->value : (string) $this->status;

        return [
            'id' => $this->id,
            'auction_code' => $this->auction_code,
            'product_id' => $this->product_id,
            'seller_id' => $this->seller_id,
            'session_id' => $this->session_id,
            'starting_price' => (float) $this->starting_price,
            'min_bid_increment' => (float) $this->min_bid_increment,
            'minimum_next_bid' => (float) $this->minimumNextBidAmount(),
            'current_highest_bid' => (float) $this->current_highest_bid,
            'has_reserve_price' => $this->reserve_price !== null,
            'reserve_price_met' => $reservePriceMet,
            'reserve_price' => $revealReservePrice ? (float) $this->reserve_price : null,
            'bid_count' => (int) $this->bid_count,
            'watch_count' => (int) $this->watch_count,
            'status' => $statusVal,
            'auction_starts_at' => $this->auction_starts_at?->toIso8601String(),
            'auction_ends_at' => $this->auction_ends_at?->toIso8601String(),
            'extended_count' => (int) $this->extended_count,
            'last_extended_at' => $this->last_extended_at?->toIso8601String(),
            'closed_early_by_seller' => (bool) $this->closed_early_by_seller,
            'closed_at' => $this->closed_at?->toIso8601String(),
            'server_time' => now()->toIso8601String(),
            'product' => new ProductDetailResource($this->whenLoaded('product')),
            'session' => $this->whenLoaded('session', function () {
                return [
                    'id' => $this->session->id,
                    'session_code' => $this->session->session_code,
                    'title' => $this->session->title,
                    'starts_at' => $this->session->starts_at?->toIso8601String(),
                    'ends_at' => $this->session->ends_at?->toIso8601String(),
                ];
            }),
            'seller' => [
                'id' => $this->seller?->id,
                'display_name' => $this->seller?->display_name,
                'avatar_url' => $this->seller?->profile?->avatar_url,
                'shop_slug' => $this->seller?->sellerProfile?->shop_slug,
                'trust_score' => (float) ($this->seller?->sellerProfile?->trust_score ?? 100.00),
            ],
            'leading_bidder' => $this->leadingBidder ? [
                'id' => $this->leadingBidder->id,
                'display_name' => $this->leadingBidder->display_name,
                'avatar_url' => $this->leadingBidder->profile?->avatar_url,
            ] : null,
            'winner' => $this->winner ? [
                'id' => $this->winner->id,
                'display_name' => $this->winner->display_name,
                'avatar_url' => $this->winner->profile?->avatar_url,
            ] : null,
            'order' => new OrderResource($this->whenLoaded('order')),
        ];
    }
}
