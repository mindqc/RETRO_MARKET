<?php

namespace App\Http\Requests\Api\V1\Order;

use Illuminate\Foundation\Http\FormRequest;

class ShipOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'carrier_name' => ['required', 'string', 'max:80'],
            'tracking_code' => ['required', 'string', 'max:80'],
            'shipping_note' => ['nullable', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'carrier_name.required' => 'Vui lòng cung cấp tên đơn vị vận chuyển.',
            'carrier_name.max' => 'Tên đơn vị vận chuyển không được vượt quá 80 ký tự.',
            'tracking_code.required' => 'Vui lòng cung cấp mã vận đơn.',
            'tracking_code.max' => 'Mã vận đơn không được vượt quá 80 ký tự.',
            'shipping_note.max' => 'Ghi chú vận chuyển không được vượt quá 500 ký tự.',
        ];
    }
}
