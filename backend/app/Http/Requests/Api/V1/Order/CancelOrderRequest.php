<?php

namespace App\Http\Requests\Api\V1\Order;

use Illuminate\Foundation\Http\FormRequest;

class CancelOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'reason' => ['required', 'string', 'min:3', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'reason.required' => 'Vui lòng nhập lý do hủy đơn hàng.',
            'reason.min' => 'Lý do hủy đơn phải có ít nhất 3 ký tự.',
            'reason.max' => 'Lý do hủy đơn không được vượt quá 500 ký tự.',
        ];
    }
}
