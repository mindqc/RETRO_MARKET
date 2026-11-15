<?php

namespace App\Http\Requests\Api\V1\Profile;

use Illuminate\Foundation\Http\FormRequest;

class UpdateAddressRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'recipient_name' => ['sometimes', 'string', 'min:2', 'max:100'],
            'recipient_phone' => ['sometimes', 'string', 'regex:/^[0-9]{10,11}$/'],
            'province_city' => ['sometimes', 'string', 'max:100'],
            'district_ward' => ['sometimes', 'string', 'max:100'],
            'street_address' => ['sometimes', 'string', 'max:255'],
            'is_default' => ['nullable', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'recipient_phone.regex' => 'Số điện thoại phải gồm 10 đến 11 chữ số.',
        ];
    }
}
