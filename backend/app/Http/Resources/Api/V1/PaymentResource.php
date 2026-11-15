<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'payment_reference' => $this->payment_reference,
            'order_id' => $this->order_id,
            'payer_id' => $this->payer_id,
            'amount' => (float) $this->amount,
            'qr_payload' => $this->qr_payload,
            'status' => $this->status?->value ?? (string) $this->status,
            'failure_reason' => $this->failure_reason,
            'expires_at' => $this->expires_at?->toIso8601String(),
            'paid_at' => $this->paid_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
