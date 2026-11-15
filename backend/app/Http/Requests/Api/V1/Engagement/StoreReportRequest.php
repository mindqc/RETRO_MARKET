<?php

namespace App\Http\Requests\Api\V1\Engagement;

use Illuminate\Foundation\Http\FormRequest;

class StoreReportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'target_type' => ['required', 'string', 'in:PRODUCT,USER,CONVERSATION'],
            'target_id' => ['required', 'integer', 'min:1'],
            'reason_category' => ['required', 'string', 'max:60'],
            'description' => ['required', 'string', 'min:5', 'max:1000'],
            'block_conversation' => ['nullable', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'target_type.required' => 'Vui lòng chọn loại đối tượng báo cáo.',
            'target_type.in' => 'Loại đối tượng báo cáo không hợp lệ (hỗ trợ PRODUCT, USER, CONVERSATION).',
            'target_id.required' => 'Vui lòng cung cấp ID đối tượng cần báo cáo.',
            'target_id.min' => 'ID đối tượng không hợp lệ.',
            'reason_category.required' => 'Vui lòng chọn danh mục lý do báo cáo.',
            'description.required' => 'Vui lòng mô tả chi tiết lý do báo cáo.',
            'description.min' => 'Mô tả lý do phải có ít nhất 5 ký tự.',
            'description.max' => 'Mô tả lý do không được vượt quá 1000 ký tự.',
        ];
    }
}
