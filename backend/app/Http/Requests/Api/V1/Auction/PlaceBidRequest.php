<?php

namespace App\Http\Requests\Api\V1\Auction;

use Illuminate\Foundation\Http\FormRequest;

class PlaceBidRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'bid_amount' => ['required', 'numeric', 'gt:0'],
        ];
    }

    public function messages(): array
    {
        return [
            'bid_amount.required' => 'Vui lòng nhập số tiền muốn đặt giá.',
            'bid_amount.numeric' => 'Số tiền đặt giá phải là một con số hợp lệ.',
            'bid_amount.gt' => 'Số tiền đặt giá phải lớn hơn 0.',
        ];
    }
}
