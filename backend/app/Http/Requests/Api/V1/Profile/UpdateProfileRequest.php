<?php

namespace App\Http\Requests\Api\V1\Profile;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $sellerProfileId = $this->user()?->sellerProfile?->id;

        return [
            'display_name' => ['sometimes', 'string', 'min:2', 'max:100'],
            'phone' => ['nullable', 'string', 'regex:/^[0-9]{10,11}$/'],
            'bio' => ['nullable', 'string', 'max:1000'],
            'shop_slug' => [
                'nullable',
                'string',
                'max:100',
                'alpha_dash',
                Rule::unique('seller_profiles', 'shop_slug')->ignore($sellerProfileId),
            ],
            'avatar' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ];
    }

    public function messages(): array
    {
        return [
            'display_name.min' => 'Tên hiển thị phải có độ dài từ 2 ký tự trở lên.',
            'phone.regex' => 'Số điện thoại phải gồm 10 đến 11 chữ số.',
            'avatar.max' => 'Dung lượng ảnh đại diện không được vượt quá 5MB (NFR-SEC-05).',
            'avatar.mimes' => 'Ảnh đại diện phải có định dạng jpg, jpeg, png hoặc webp.',
            'shop_slug.unique' => 'Đường dẫn định danh tiệm đồ si (shop_slug) này đã được sử dụng.',
        ];
    }
}
