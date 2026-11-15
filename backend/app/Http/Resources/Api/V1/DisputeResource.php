<?php

namespace App\Http\Resources\Api\V1;

use App\Enums\DisputeStatus;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DisputeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'dispute_code' => $this->dispute_code,
            'order_id' => $this->order_id,
            'buyer_id' => $this->buyer_id,
            'seller_id' => $this->seller_id,
            'opened_at_order_status' => $this->opened_at_order_status,
            'reason_category' => $this->reason_category,
            'buyer_description' => $this->buyer_description,
            'seller_response' => $this->seller_response,
            'assigned_support_id' => $this->assigned_support_id,
            'status' => $this->status instanceof DisputeStatus ? $this->status->value : (string) $this->status,
            'admin_verdict' => $this->admin_verdict,
            'partial_refund_to_buyer' => $this->partial_refund_to_buyer !== null ? (float) $this->partial_refund_to_buyer : null,
            'resolution_note' => $this->resolution_note,
            'resolved_by_admin_id' => $this->resolved_by_admin_id,
            'resolved_at' => $this->resolved_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
            'evidences' => DisputeEvidenceResource::collection($this->whenLoaded('evidences')),
            'order' => new OrderResource($this->whenLoaded('order')),
        ];
    }
}
