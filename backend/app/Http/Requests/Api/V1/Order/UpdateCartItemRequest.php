<?php

namespace App\Http\Requests\Api\V1\Order;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCartItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'quantity' => ['sometimes', 'integer', 'min:1'],
            'is_selected' => ['sometimes', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'quantity.min' => 'Số lượng sản phẩm trong giỏ phải từ 1 trở lên.',
        ];
    }
}
