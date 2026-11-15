<?php

namespace App\Http\Requests\Api\V1\Product;

use Illuminate\Foundation\Http\FormRequest;

class StoreProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'category_id' => ['required', 'integer', 'exists:categories,id'],
            'brand_id' => ['nullable', 'integer', 'exists:brands,id'],
            'title' => ['required', 'string', 'min:5', 'max:200'],
            'description' => ['nullable', 'string', 'max:5000'],
            'condition' => ['required', 'string', 'in:NEW_WITH_TAGS,LIKE_NEW,GOOD,FAIR,VINTAGE_WORN'],
            'defect_info' => ['required', 'string', 'regex:/\S/'],
            'listing_type' => ['required', 'string', 'in:FIXED_PRICE,AUCTION'],
            'price' => ['required', 'numeric', 'gt:0'],
            'total_quantity' => ['nullable', 'integer', 'min:1'],
            'submit_for_review' => ['nullable', 'boolean'],
            'images' => ['nullable', 'array', 'max:8'],
            'images.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'image_urls' => ['nullable', 'array'],
            'image_urls.*' => ['string'],
            'session_id' => ['nullable', 'integer', 'exists:auction_sessions,id'],
            'starting_price' => ['nullable', 'numeric', 'gt:0'],
            'reserve_price' => ['nullable', 'numeric', 'gt:0'],
            'min_bid_increment' => ['nullable', 'numeric', 'gt:0'],
            'buy_now_price' => ['nullable', 'numeric', 'gt:0'],
        ];
    }

    public function messages(): array
    {
        return [
            'title.required' => 'Tiêu đề sản phẩm không được để trống.',
            'title.min' => 'Tiêu đề sản phẩm phải có ít nhất 5 ký tự.',
            'category_id.required' => 'Vui lòng chọn danh mục sản phẩm.',
            'category_id.exists' => 'Danh mục đã chọn không tồn tại.',
            'condition.required' => 'Vui lòng chọn tình trạng sản phẩm (BR-PR-03).',
            'condition.in' => 'Tình trạng sản phẩm không hợp lệ.',
            'defect_info.required' => 'Mô tả khuyết điểm là bắt buộc đối với đồ secondhand (BR-PR-03).',
            'defect_info.regex' => 'Mô tả khuyết điểm không được chỉ chứa khoảng trắng (BR-PR-03).',
            'listing_type.required' => 'Vui lòng chọn hình thức bán (Giá cố định hoặc Đấu giá).',
            'price.required' => 'Vui lòng nhập giá bán của sản phẩm.',
            'price.gt' => 'Giá bán sản phẩm phải lớn hơn 0 VND.',
            'images.max' => 'Tối đa chỉ được tải lên 8 ảnh cho mỗi sản phẩm.',
            'images.*.max' => 'Dung lượng mỗi ảnh không được vượt quá 5MB (NFR-SEC-05).',
            'images.*.mimes' => 'Ảnh sản phẩm phải có định dạng jpg, jpeg, png hoặc webp.',
        ];
    }
}
