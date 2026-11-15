<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EscrowTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'transaction_code' => $this->transaction_code,
            'order_id' => $this->order_id,
            'payment_id' => $this->payment_id,
            'buyer_id' => $this->buyer_id,
            'seller_id' => $this->seller_id,
            'transaction_type' => $this->transaction_type,
            'gross_amount' => (float) $this->gross_amount,
            'item_subtotal_amount' => (float) $this->item_subtotal_amount,
            'buyer_protection_fee_amount' => (float) $this->buyer_protection_fee_amount,
            'seller_released_amount' => (float) $this->seller_released_amount,
            'buyer_refunded_amount' => (float) $this->buyer_refunded_amount,
            'platform_fee_retained' => (float) $this->platform_fee_retained,
            'note' => $this->note,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
