<?php

namespace App\Http\Requests\Api\V1\Engagement;

use Illuminate\Foundation\Http\FormRequest;

class StartConversationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'recipient_id' => ['required', 'integer', 'exists:users,id'],
            'context_product_id' => ['nullable', 'integer', 'exists:products,id'],
            'context_order_id' => ['nullable', 'integer', 'exists:orders,id'],
            'initial_message' => ['nullable', 'string', 'max:2000'],
        ];
    }

    public function messages(): array
    {
        return [
            'recipient_id.required' => 'Vui lòng chỉ định người nhận tin nhắn.',
            'recipient_id.integer' => 'ID người nhận không hợp lệ.',
            'recipient_id.exists' => 'Người nhận không tồn tại trong hệ thống.',
            'context_product_id.exists' => 'Sản phẩm ngữ cảnh không tồn tại.',
            'context_order_id.exists' => 'Đơn hàng ngữ cảnh không tồn tại.',
            'initial_message.max' => 'Tin nhắn mở đầu không được vượt quá 2000 ký tự.',
        ];
    }
}
