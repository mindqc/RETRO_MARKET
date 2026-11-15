<?php

namespace App\Http\Requests\Api\V1\Auth;

use Illuminate\Foundation\Http\FormRequest;

class ResetPasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'string', 'email', 'max:150'],
            'token' => ['required', 'string'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.required' => 'Vui lòng cung cấp địa chỉ email.',
            'token.required' => 'Mã xác thực khôi phục mật khẩu không được để trống.',
            'password.required' => 'Mật khẩu mới không được để trống.',
            'password.min' => 'Mật khẩu mới phải có tối thiểu 8 ký tự.',
            'password.confirmed' => 'Mật khẩu xác nhận không trùng khớp.',
        ];
    }
}
