<?php

namespace App\Http\Requests\Api\V1\Profile;

use Illuminate\Foundation\Http\FormRequest;

class UpdateSettingsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'seasonal_decor_enabled' => ['required', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'seasonal_decor_enabled.required' => 'Cài đặt giao diện trang trí mùa lễ hội không được để trống.',
            'seasonal_decor_enabled.boolean' => 'Giá trị cài đặt phải là true hoặc false.',
        ];
    }
}
