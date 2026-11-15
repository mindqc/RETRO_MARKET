<?php

namespace App\Http\Requests\Api\V1\Product;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'category_id' => ['sometimes', 'integer', 'exists:categories,id'],
            'brand_id' => ['nullable', 'integer', 'exists:brands,id'],
            'title' => ['sometimes', 'string', 'min:5', 'max:200'],
            'description' => ['nullable', 'string', 'max:5000'],
            'condition' => ['sometimes', 'string', 'in:NEW_WITH_TAGS,LIKE_NEW,GOOD,FAIR,VINTAGE_WORN'],
            'defect_info' => ['sometimes', 'string', 'regex:/\S/'],
            'price' => ['sometimes', 'numeric', 'gt:0'],
            'total_quantity' => ['nullable', 'integer', 'min:1'],
            'submit_for_review' => ['nullable', 'boolean'],
            'images' => ['nullable', 'array', 'max:8'],
            'images.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'image_urls' => ['nullable', 'array'],
            'image_urls.*' => ['string'],
        ];
    }

    public function messages(): array
    {
        return [
            'defect_info.regex' => 'Mô tả khuyết điểm không được chỉ chứa khoảng trắng (BR-PR-03).',
            'images.*.max' => 'Dung lượng mỗi ảnh không được vượt quá 5MB (NFR-SEC-05).',
            'images.*.mimes' => 'Ảnh sản phẩm phải có định dạng jpg, jpeg, png hoặc webp.',
        ];
    }
}
