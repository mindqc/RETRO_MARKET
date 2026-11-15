<?php

namespace App\Http\Requests\Api\V1\Auth;

use Illuminate\Foundation\Http\FormRequest;

class ForgotPasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'string', 'email', 'max:150'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.required' => 'Vui lòng cung cấp địa chỉ email.',
            'email.email' => 'Địa chỉ email không đúng định dạng.',
        ];
    }
}
