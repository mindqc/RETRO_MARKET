<?php

namespace App\Enums;

enum AuctionStatus: string
{
    case SCHEDULED = 'SCHEDULED';
    case LIVE = 'LIVE';
    case COMPLETED = 'COMPLETED';
    case ENDED_UNSOLD = 'ENDED_UNSOLD';
    case WINNER_DEFAULTED = 'WINNER_DEFAULTED';
    case CANCELLED = 'CANCELLED';

    public function label(): string
    {
        return match ($this) {
            self::SCHEDULED => 'Sắp diễn ra',
            self::LIVE => 'Đang đấu giá trực tiếp',
            self::COMPLETED => 'Đã kết thúc / Đã có người thắng',
            self::ENDED_UNSOLD => 'Đã kết thúc / Không đạt giá sàn hoặc không có bid',
            self::WINNER_DEFAULTED => 'Người thắng bỏ cọc / Quá hạn thanh toán',
            self::CANCELLED => 'Đã hủy bởi quản trị viên hoặc người bán',
        };
    }
}
