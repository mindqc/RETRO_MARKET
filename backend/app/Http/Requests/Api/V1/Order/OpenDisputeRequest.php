<?php

namespace App\Http\Requests\Api\V1\Order;

use Illuminate\Foundation\Http\FormRequest;

class OpenDisputeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'reason_category' => ['required', 'string', 'max:50'],
            'description' => ['required', 'string', 'min:10', 'max:2000'],
            'files' => ['nullable', 'array'],
            'files.*' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp,pdf', 'max:5120'],
            'file_urls' => ['nullable', 'array'],
            'file_urls.*' => ['string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'reason_category.required' => 'Vui lòng chọn danh mục lý do khiếu nại.',
            'description.required' => 'Vui lòng mô tả chi tiết lý do khiếu nại.',
            'description.min' => 'Mô tả khiếu nại phải có ít nhất 10 ký tự.',
            'description.max' => 'Mô tả khiếu nại không được vượt quá 2000 ký tự.',
            'files.*.mimes' => 'Tệp bằng chứng phải có định dạng jpg, jpeg, png, webp hoặc pdf.',
            'files.*.max' => 'Mỗi tệp bằng chứng không được vượt quá 5MB.',
        ];
    }
}
