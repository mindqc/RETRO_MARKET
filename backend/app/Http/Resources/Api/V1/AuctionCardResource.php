<?php

namespace App\Http\Resources\Api\V1;

use App\Enums\AuctionStatus;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AuctionCardResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $statusVal = $this->status instanceof AuctionStatus ? $this->status->value : (string) $this->status;

        return [
            'id' => $this->id,
            'auction_code' => $this->auction_code,
            'product_id' => $this->product_id,
            'seller_id' => $this->seller_id,
            'session_id' => $this->session_id,
            'starting_price' => (float) $this->starting_price,
            'min_bid_increment' => (float) $this->min_bid_increment,
            'current_highest_bid' => (float) $this->current_highest_bid,
            'bid_count' => (int) $this->bid_count,
            'watch_count' => (int) $this->watch_count,
            'status' => $statusVal,
            'auction_starts_at' => $this->auction_starts_at?->toIso8601String(),
            'auction_ends_at' => $this->auction_ends_at?->toIso8601String(),
            'extended_count' => (int) $this->extended_count,
            'product' => [
                'id' => $this->product?->id,
                'title' => $this->product?->title,
                'slug' => $this->product?->slug,
                'primary_image_url' => $this->product?->primaryImage?->image_url,
                'category_name' => $this->product?->category?->name,
                'condition' => $this->product?->condition instanceof \BackedEnum ? $this->product->condition->value : (string) $this->product?->condition,
            ],
            'seller' => [
                'id' => $this->seller?->id,
                'display_name' => $this->seller?->display_name,
                'shop_slug' => $this->seller?->sellerProfile?->shop_slug,
                'trust_score' => (float) ($this->seller?->sellerProfile?->trust_score ?? 100.00),
            ],
            'leading_bidder' => $this->leadingBidder ? [
                'id' => $this->leadingBidder->id,
                'display_name' => $this->leadingBidder->display_name,
            ] : null,
            'my_highest_bid' => isset($this->my_highest_bid) ? (float) $this->my_highest_bid : null,
            'my_bid_status' => $this->my_bid_status ?? null,
        ];
    }
}
