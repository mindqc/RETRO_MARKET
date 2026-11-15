<?php

namespace App\Http\Requests\Api\V1\Engagement;

use Illuminate\Foundation\Http\FormRequest;

class SendMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'message_text' => ['required', 'string', 'min:1', 'max:2000'],
            'attached_product_id' => ['nullable', 'integer', 'exists:products,id'],
        ];
    }

    public function messages(): array
    {
        return [
            'message_text.required' => 'Nội dung tin nhắn không được để trống.',
            'message_text.min' => 'Nội dung tin nhắn phải có ít nhất 1 ký tự.',
            'message_text.max' => 'Nội dung tin nhắn không được vượt quá 2000 ký tự.',
            'attached_product_id.exists' => 'Sản phẩm đính kèm không tồn tại trong hệ thống.',
        ];
    }
}
