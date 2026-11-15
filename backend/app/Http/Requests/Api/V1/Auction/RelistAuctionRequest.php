<?php

namespace App\Http\Requests\Api\V1\Auction;

use Illuminate\Foundation\Http\FormRequest;

class RelistAuctionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'session_id' => ['nullable', 'exists:auction_sessions,id'],
            'starting_price' => ['required', 'numeric', 'gt:0'],
            'min_bid_increment' => ['required', 'numeric', 'gt:0'],
            'reserve_price' => ['nullable', 'numeric', 'gte:starting_price'],
            'auction_starts_at' => ['nullable', 'date'],
            'auction_ends_at' => ['nullable', 'date', 'after:auction_starts_at'],
        ];
    }

    public function messages(): array
    {
        return [
            'starting_price.required' => 'Vui lòng nhập giá khởi điểm.',
            'starting_price.gt' => 'Giá khởi điểm phải lớn hơn 0.',
            'min_bid_increment.required' => 'Vui lòng nhập bước giá tối thiểu.',
            'min_bid_increment.gt' => 'Bước giá tối thiểu phải lớn hơn 0.',
            'reserve_price.gte' => 'Giá sàn (reserve price) phải lớn hơn hoặc bằng giá khởi điểm.',
            'auction_ends_at.after' => 'Thời gian kết thúc phải diễn ra sau thời gian bắt đầu.',
        ];
    }
}
