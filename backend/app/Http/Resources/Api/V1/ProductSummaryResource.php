<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductSummaryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'product_code' => $this->product_code,
            'title' => $this->title,
            'slug' => $this->slug,
            'listing_type' => $this->listing_type,
            'condition' => $this->condition?->value ?? (string) $this->condition,
            'price' => (float) $this->price,
            'available_quantity' => (int) $this->available_quantity,
            'favorite_count' => (int) $this->favorite_count,
            'status' => $this->status?->value ?? (string) $this->status,
            'is_favorited' => (bool) ($this->is_favorited ?? false),
            'is_owner' => (bool) ($this->is_owner ?? false),
            'primary_image' => $this->primaryImage ? [
                'id' => $this->primaryImage->id,
                'image_url' => $this->primaryImage->image_url,
                'thumbnail_url' => $this->primaryImage->thumbnail_url,
            ] : null,
            'seller' => $this->whenLoaded('seller', function () {
                return [
                    'id' => $this->seller->id,
                    'display_name' => $this->seller->display_name,
                    'avatar_url' => $this->seller->profile?->avatar_url,
                    'shop_slug' => $this->seller->sellerProfile?->shop_slug,
                    'trust_score' => (float) ($this->seller->sellerProfile?->trust_score ?? 100.0),
                ];
            }),
            'category' => $this->whenLoaded('category', function () {
                return [
                    'id' => $this->category->id,
                    'name' => $this->category->name,
                    'slug' => $this->category->slug,
                ];
            }),
            'brand' => $this->whenLoaded('brand', function () {
                return $this->brand ? [
                    'id' => $this->brand->id,
                    'name' => $this->brand->name,
                    'slug' => $this->brand->slug,
                ] : null;
            }),
            'approved_at' => $this->approved_at?->toIso8601String(),
        ];
    }
}
