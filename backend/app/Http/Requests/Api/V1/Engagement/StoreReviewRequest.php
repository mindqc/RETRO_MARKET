<?php

namespace App\Http\Requests\Api\V1\Engagement;

use Illuminate\Foundation\Http\FormRequest;

class StoreReviewRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['required', 'string', 'min:3', 'max:1000', 'regex:/\S/'],
        ];
    }

    public function messages(): array
    {
        return [
            'rating.required' => 'Vui lòng chọn số sao đánh giá.',
            'rating.integer' => 'Số sao đánh giá phải là số nguyên.',
            'rating.min' => 'Số sao đánh giá tối thiểu là 1.',
            'rating.max' => 'Số sao đánh giá tối đa là 5.',
            'comment.required' => 'Nội dung đánh giá không được để trống.',
            'comment.min' => 'Nội dung đánh giá phải có ít nhất 3 ký tự.',
            'comment.max' => 'Nội dung đánh giá không được vượt quá 1000 ký tự.',
            'comment.regex' => 'Nội dung đánh giá không được chỉ chứa khoảng trắng.',
        ];
    }
}
