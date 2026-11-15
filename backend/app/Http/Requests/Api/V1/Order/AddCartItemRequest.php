<?php

namespace App\Http\Requests\Api\V1\Order;

use Illuminate\Foundation\Http\FormRequest;

class AddCartItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'product_id' => ['required', 'integer', 'exists:products,id'],
            'quantity' => ['nullable', 'integer', 'min:1'],
        ];
    }

    public function messages(): array
    {
        return [
            'product_id.required' => 'Vui lòng chọn sản phẩm cần thêm vào giỏ hàng.',
            'product_id.exists' => 'Sản phẩm đã chọn không tồn tại.',
            'quantity.min' => 'Số lượng thêm vào giỏ hàng phải từ 1 trở lên.',
        ];
    }
}
