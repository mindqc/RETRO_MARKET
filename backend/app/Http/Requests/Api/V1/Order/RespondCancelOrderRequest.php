<?php

namespace App\Http\Requests\Api\V1\Order;

use Illuminate\Foundation\Http\FormRequest;

class RespondCancelOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'decision' => ['required', 'string', 'in:APPROVE,REJECT,approve,reject'],
            'note' => ['nullable', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'decision.required' => 'Vui lòng chọn quyết định phản hồi (APPROVE hoặc REJECT).',
            'decision.in' => 'Quyết định phản hồi không hợp lệ.',
            'note.max' => 'Ghi chú không được vượt quá 500 ký tự.',
        ];
    }
}
