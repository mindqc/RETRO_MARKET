<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'conversation_id' => $this->conversation_id,
            'sender_id' => $this->sender_id,
            'sender' => $this->whenLoaded('sender', function () {
                return [
                    'id' => $this->sender->id,
                    'display_name' => $this->sender->display_name,
                    'avatar_url' => $this->sender->profile?->avatar_url,
                ];
            }),
            'message_text' => $this->message_text,
            'attached_product_id' => $this->attached_product_id,
            'attached_product' => $this->whenLoaded('attachedProduct', function () {
                return [
                    'id' => $this->attachedProduct->id,
                    'title' => $this->attachedProduct->title,
                    'price' => (float) $this->attachedProduct->price,
                    'primary_image_url' => $this->attachedProduct->primaryImage?->image_url,
                ];
            }),
            'is_read' => (bool) $this->is_read,
            'read_at' => $this->read_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
