<?php

namespace App\Http\Requests\Api\V1\Product;

use Illuminate\Foundation\Http\FormRequest;

class ProductSearchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'q' => ['nullable', 'string', 'max:150'],
            'category_id' => ['nullable', 'integer', 'exists:categories,id'],
            'brand_id' => ['nullable', 'integer', 'exists:brands,id'],
            'listing_type' => ['nullable', 'string', 'in:FIXED_PRICE,AUCTION,fixed_price,auction'],
            'condition' => ['nullable', 'string', 'in:NEW_WITH_TAGS,LIKE_NEW,GOOD,FAIR,VINTAGE_WORN'],
            'verification_level' => ['nullable', 'string'],
            'min_price' => ['nullable', 'numeric', 'min:0'],
            'max_price' => ['nullable', 'numeric', 'gte:min_price'],
            'sort' => ['nullable', 'string', 'in:newest,price_asc,price_desc,popular'],
        ];
    }

    public function messages(): array
    {
        return [
            'min_price.min' => 'Giá tối thiểu không được là số âm.',
            'max_price.gte' => 'Khoảng giá không hợp lệ: Giá tối đa phải lớn hơn hoặc bằng giá tối thiểu.',
        ];
    }
}
