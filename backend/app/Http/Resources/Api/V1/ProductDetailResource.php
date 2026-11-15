<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductDetailResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $viewer = $request->user();
        $isOwner = $viewer && ($viewer->id === $this->seller_id);
        $isStaff = $viewer && $viewer->isInternalStaff();
        $canSeeInternalDetails = $isOwner || $isStaff;

        return [
            'id' => $this->id,
            'product_code' => $this->product_code,
            'title' => $this->title,
            'slug' => $this->slug,
            'description' => $this->description,
            'condition' => $this->condition?->value ?? (string) $this->condition,
            'defect_info' => $this->defect_info,
            'listing_type' => $this->listing_type,
            'price' => (float) $this->price,
            'total_quantity' => (int) $this->total_quantity,
            'available_quantity' => (int) $this->available_quantity,
            'verification_level' => $this->verification_level,
            'status' => $this->status?->value ?? (string) $this->status,
            'rejection_reason' => $canSeeInternalDetails ? $this->rejection_reason : null,
            'favorite_count' => (int) $this->favorite_count,
            'is_owner' => (bool) ($this->resource->is_owner ?? $isOwner),
            'is_favorited' => (bool) ($this->resource->is_favorited ?? false),
            'images' => ProductImageResource::collection($this->whenLoaded('images')),
            'seller' => $this->whenLoaded('seller', function () {
                return [
                    'id' => $this->seller->id,
                    'display_name' => $this->seller->display_name,
                    'avatar_url' => $this->seller->profile?->avatar_url,
                    'shop_slug' => $this->seller->sellerProfile?->shop_slug,
                    'trust_score' => (float) ($this->seller->sellerProfile?->trust_score ?? 100.0),
                    'average_rating' => (float) ($this->seller->sellerProfile?->average_rating ?? 0.0),
                    'completed_orders_count' => (int) ($this->seller->sellerProfile?->completed_orders_count ?? 0),
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
                    'logo_url' => $this->brand->logo_url,
                ] : null;
            }),
            'active_auction' => $this->whenLoaded('activeAuction', function () {
                return $this->activeAuction ? [
                    'id' => $this->activeAuction->id,
                    'starting_price' => (float) $this->activeAuction->starting_price,
                    'current_highest_bid' => (float) ($this->activeAuction->current_highest_bid ?? $this->activeAuction->starting_price),
                    'bid_count' => (int) $this->activeAuction->bid_count,
                    'auction_ends_at' => $this->activeAuction->auction_ends_at?->toIso8601String(),
                    'status' => $this->activeAuction->status?->value ?? (string) $this->activeAuction->status,
                ] : null;
            }),
            'moderation_logs' => $this->when($canSeeInternalDetails && $this->relationLoaded('moderationLogs'), function () {
                return $this->moderationLogs->map(fn ($log) => [
                    'id' => $log->id,
                    'action' => $log->action,
                    'previous_status' => $log->previous_status,
                    'new_status' => $log->new_status,
                    'reason' => $log->reason,
                    'created_at' => $log->created_at?->toIso8601String(),
                    'moderator' => $log->moderator ? [
                        'id' => $log->moderator->id,
                        'display_name' => $log->moderator->display_name,
                        'role' => $log->moderator->role?->value ?? (string) $log->moderator->role,
                    ] : null,
                ]);
            }),
            'approved_at' => $this->approved_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
