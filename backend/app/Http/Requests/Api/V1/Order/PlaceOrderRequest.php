<?php

namespace App\Http\Requests\Api\V1\Order;

use Illuminate\Foundation\Http\FormRequest;

class PlaceOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'source' => ['required', 'string', 'in:CART,BUY_NOW,cart,buy_now'],
            'product_id' => ['required_if:source,BUY_NOW,buy_now', 'nullable', 'integer', 'exists:products,id'],
            'quantity' => ['nullable', 'integer', 'min:1'],
            'seller_id' => ['nullable', 'integer', 'exists:users,id'],
            'cart_item_ids' => ['nullable', 'array'],
            'cart_item_ids.*' => ['integer', 'min:1'],
            'address_id' => ['nullable', 'integer', 'exists:user_addresses,id'],
            'shipping_address_id' => ['nullable', 'integer', 'exists:user_addresses,id'],
            'note' => ['nullable', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'source.required' => 'Vui lòng xác định nguồn mua hàng (CART hoặc BUY_NOW).',
            'source.in' => 'Nguồn mua hàng không hợp lệ (chỉ chấp nhận CART hoặc BUY_NOW).',
            'product_id.required_if' => 'Vui lòng chọn sản phẩm khi mua ngay.',
            'product_id.exists' => 'Sản phẩm đã chọn không tồn tại.',
            'quantity.min' => 'Số lượng sản phẩm phải từ 1 trở lên.',
            'address_id.exists' => 'Địa chỉ nhận hàng đã chọn không tồn tại.',
            'shipping_address_id.exists' => 'Địa chỉ nhận hàng đã chọn không tồn tại.',
        ];
    }
}
