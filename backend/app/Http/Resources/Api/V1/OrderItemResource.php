<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'product_id' => $this->product_id,
            'product_code' => $this->product_code_snapshot,
            'title' => $this->product_title_snapshot,
            'condition' => $this->condition_snapshot,
            'defect_info' => $this->defect_info_snapshot,
            'primary_image_url' => $this->primary_image_snapshot,
            'unit_price' => (float) $this->unit_price_snapshot,
            'quantity' => (int) $this->quantity,
            'line_total' => (float) $this->line_total,
        ];
    }
}
