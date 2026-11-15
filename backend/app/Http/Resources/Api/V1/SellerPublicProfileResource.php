<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SellerPublicProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'display_name' => $this->display_name,
            'avatar_url' => $this->profile?->avatar_url,
            'bio' => $this->profile?->bio,
            'shop_slug' => $this->sellerProfile?->shop_slug,
            'trust_score' => (float) ($this->sellerProfile?->trust_score ?? 100.00),
            'average_rating' => (float) ($this->sellerProfile?->average_rating ?? 0.00),
            'review_count' => (int) ($this->sellerProfile?->review_count ?? 0),
            'completed_orders_count' => (int) ($this->sellerProfile?->completed_orders_count ?? 0),
            'seasonal_decor_enabled' => (bool) ($this->profile?->seasonal_decor_enabled ?? false),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
