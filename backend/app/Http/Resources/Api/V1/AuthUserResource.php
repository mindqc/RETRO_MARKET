<?php

namespace App\Http\Resources\Api\V1;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AuthUserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     * Whitelist safe attributes, completely omitting password_hash (NFR-SEC-01).
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'display_name' => $this->display_name,
            'email' => $this->email,
            'phone' => $this->phone,
            'role' => $this->role instanceof UserRole ? $this->role->value : (string) $this->role,
            'status' => $this->status instanceof UserStatus ? $this->status->value : (string) $this->status,
            'status_reason' => $this->status_reason,
            'suspended_until' => $this->suspended_until?->toIso8601String(),
            'last_login_at' => $this->last_login_at?->toIso8601String(),
            'profile' => $this->whenLoaded('profile', function () {
                return [
                    'id' => $this->profile?->id,
                    'avatar_url' => $this->profile?->avatar_url,
                    'bio' => $this->profile?->bio,
                    'seasonal_decor_enabled' => (bool) $this->profile?->seasonal_decor_enabled,
                ];
            }),
            'seller_profile' => $this->whenLoaded('sellerProfile', function () {
                return [
                    'id' => $this->sellerProfile?->id,
                    'shop_slug' => $this->sellerProfile?->shop_slug,
                    'trust_score' => (float) $this->sellerProfile?->trust_score,
                    'average_rating' => (float) $this->sellerProfile?->average_rating,
                    'review_count' => (int) $this->sellerProfile?->review_count,
                    'completed_orders_count' => (int) $this->sellerProfile?->completed_orders_count,
                    'wallet_balance' => (float) $this->sellerProfile?->wallet_balance,
                    'escrow_held_balance' => (float) $this->sellerProfile?->escrow_held_balance,
                ];
            }),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
