<?php

namespace App\Http\Requests\Api\V1\Order;

use Illuminate\Foundation\Http\FormRequest;

class SubmitDisputeEvidenceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'message_note' => ['required_without:file', 'nullable', 'string', 'max:2000'],
            'file' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp,pdf', 'max:5120'],
            'file_url' => ['nullable', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'message_note.required_without' => 'Vui lòng nhập ghi chú hoặc tải lên tệp bằng chứng.',
            'message_note.max' => 'Ghi chú không được vượt quá 2000 ký tự.',
            'file.mimes' => 'Tệp bằng chứng phải có định dạng jpg, jpeg, png, webp hoặc pdf.',
            'file.max' => 'Tệp bằng chứng không được vượt quá 5MB.',
        ];
    }
}
