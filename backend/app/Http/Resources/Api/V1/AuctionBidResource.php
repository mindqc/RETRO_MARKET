<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AuctionBidResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'auction_id' => $this->auction_id,
            'bidder_id' => $this->bidder_id,
            'bid_amount' => (float) $this->bid_amount,
            'previous_highest_bid' => (float) $this->previous_highest_bid,
            'triggered_anti_sniping' => (bool) $this->triggered_anti_sniping,
            'created_at' => $this->created_at?->toIso8601String(),
            'bidder' => [
                'id' => $this->bidder?->id,
                'display_name' => $this->bidder?->display_name,
                'avatar_url' => $this->bidder?->profile?->avatar_url,
            ],
        ];
    }
}
