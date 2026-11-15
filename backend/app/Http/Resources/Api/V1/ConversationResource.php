<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConversationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $viewerId = $request->user()?->id;
        $otherUser = null;

        if ($viewerId !== null) {
            $target = ((int) $this->user_one_id === $viewerId) ? $this->userTwo : $this->userOne;
            if ($target) {
                $otherUser = [
                    'id' => $target->id,
                    'display_name' => $target->display_name,
                    'avatar_url' => $target->profile?->avatar_url,
                    'shop_slug' => $target->sellerProfile?->shop_slug,
                    'trust_score' => $target->sellerProfile?->trust_score,
                ];
            }
        }

        return [
            'id' => $this->id,
            'user_one_id' => $this->user_one_id,
            'user_two_id' => $this->user_two_id,
            'other_user' => $otherUser,
            'unread_count' => (int) ($this->unread_count ?? 0),
            'last_message_preview' => $this->last_message_preview,
            'last_message_at' => $this->last_message_at?->toIso8601String(),
            'blocked_by_user_id' => $this->blocked_by_user_id,
            'is_blocked' => $this->blocked_by_user_id !== null,
            'context_product' => $this->when($this->contextProduct !== null, function () {
                return [
                    'id' => $this->contextProduct->id,
                    'title' => $this->contextProduct->title,
                    'price' => (float) $this->contextProduct->price,
                    'primary_image_url' => $this->contextProduct->primaryImage?->image_url,
                ];
            }),
            'context_order' => $this->when($this->contextOrder !== null, function () {
                return [
                    'id' => $this->contextOrder->id,
                    'order_code' => $this->contextOrder->order_code,
                    'order_status' => $this->contextOrder->order_status instanceof \BackedEnum
                        ? $this->contextOrder->order_status->value
                        : (string) $this->contextOrder->order_status,
                    'total_amount' => (float) $this->contextOrder->total_amount,
                ];
            }),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
