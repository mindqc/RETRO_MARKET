<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class WalletTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'wallet_tx_code' => $this->wallet_tx_code,
            'seller_id' => $this->seller_id,
            'order_id' => $this->order_id,
            'escrow_transaction_id' => $this->escrow_transaction_id,
            'entry_type' => $this->entry_type,
            'amount' => (float) $this->amount,
            'balance_before' => (float) $this->balance_before,
            'balance_after' => (float) $this->balance_after,
            'description' => $this->description,
            'created_at' => $this->created_at?->toIso8601String(),
            'order' => new OrderResource($this->whenLoaded('order')),
            'escrow_transaction' => new EscrowTransactionResource($this->whenLoaded('escrowTransaction')),
        ];
    }
}
