<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'parent_id' => $this->parent_id,
            'name' => $this->name,
            'slug' => $this->slug,
            'icon_name' => $this->icon_name,
            'description' => $this->description,
            'sort_order' => $this->sort_order,
            'approved_products_count' => (int) ($this->approved_products_count ?? 0),
            'children' => CategoryResource::collection($this->whenLoaded('children')),
        ];
    }
}
