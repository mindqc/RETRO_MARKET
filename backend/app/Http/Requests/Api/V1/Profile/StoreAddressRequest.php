<?php

namespace App\Http\Requests\Api\V1\Profile;

use Illuminate\Foundation\Http\FormRequest;

class StoreAddressRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'recipient_name' => ['required', 'string', 'min:2', 'max:100'],
            'recipient_phone' => ['required', 'string', 'regex:/^[0-9]{10,11}$/'],
            'province_city' => ['required', 'string', 'max:100'],
            'district_ward' => ['required', 'string', 'max:100'],
            'street_address' => ['required', 'string', 'max:255'],
            'is_default' => ['nullable', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'recipient_name.required' => 'Họ và tên người nhận không được để trống.',
            'recipient_phone.required' => 'Số điện thoại người nhận không được để trống.',
            'recipient_phone.regex' => 'Số điện thoại phải gồm 10 đến 11 chữ số.',
            'province_city.required' => 'Tỉnh/Thành phố không được để trống.',
            'district_ward.required' => 'Quận/Huyện hoặc Phường/Xã không được để trống.',
            'street_address.required' => 'Địa chỉ cụ thể không được để trống.',
        ];
    }
}
