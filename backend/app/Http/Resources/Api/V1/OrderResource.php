<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'order_code' => $this->order_code,
            'buyer_id' => $this->buyer_id,
            'seller_id' => $this->seller_id,
            'order_source' => $this->order_source,
            'auction_id' => $this->auction_id,
            'item_subtotal' => (float) $this->item_subtotal,
            'shipping_fee' => (float) $this->shipping_fee,
            'protection_fee_rate_applied' => (float) $this->protection_fee_rate_applied,
            'protection_fixed_fee_applied' => (float) $this->protection_fixed_fee_applied,
            'buyer_protection_fee' => (float) $this->buyer_protection_fee,
            'total_amount' => (float) $this->total_amount,
            'seller_net_amount' => (float) $this->seller_net_amount,
            'shipping_address_snapshot' => $this->shipping_address_snapshot,
            'order_status' => $this->order_status?->value ?? (string) $this->order_status,
            'payment_status' => $this->payment_status?->value ?? (string) $this->payment_status,
            'escrow_status' => $this->escrow_status?->value ?? (string) $this->escrow_status,
            'dispute_status' => $this->dispute_status?->value ?? (string) $this->dispute_status,
            'cancellation_requested' => (bool) $this->cancellation_requested,
            'cancellation_request_reason' => $this->cancellation_request_reason,
            'cancelled_by_role' => $this->cancelled_by_role,
            'cancel_reason' => $this->cancel_reason,
            'payment_expires_at' => $this->payment_expires_at?->toIso8601String(),
            'paid_at' => $this->paid_at?->toIso8601String(),
            'preparing_at' => $this->preparing_at?->toIso8601String(),
            'shipped_at' => $this->shipped_at?->toIso8601String(),
            'delivered_at' => $this->delivered_at?->toIso8601String(),
            'auto_complete_at' => $this->auto_complete_at?->toIso8601String(),
            'completed_at' => $this->completed_at?->toIso8601String(),
            'cancelled_at' => $this->cancelled_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'items' => OrderItemResource::collection($this->whenLoaded('items')),
            'seller' => $this->whenLoaded('seller', function () {
                return [
                    'id' => $this->seller->id,
                    'display_name' => $this->seller->display_name,
                    'avatar_url' => $this->seller->profile?->avatar_url,
                    'shop_slug' => $this->seller->sellerProfile?->shop_slug,
                    'trust_score' => (float) ($this->seller->sellerProfile?->trust_score ?? 100.0),
                ];
            }),
            'buyer' => $this->whenLoaded('buyer', function () {
                return [
                    'id' => $this->buyer->id,
                    'display_name' => $this->buyer->display_name,
                    'avatar_url' => $this->buyer->profile?->avatar_url,
                ];
            }),
            'latest_payment' => $this->whenLoaded('payments', function () {
                $p = $this->payments->last();

                return $p ? new PaymentResource($p) : null;
            }),
        ];
    }
}
