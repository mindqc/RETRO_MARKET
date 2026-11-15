<?php

namespace App\Enums;

enum ProductCondition: string
{
    case NEW_WITH_TAGS = 'NEW_WITH_TAGS';
    case LIKE_NEW = 'LIKE_NEW';
    case GOOD = 'GOOD';
    case FAIR = 'FAIR';
    case VINTAGE_WORN = 'VINTAGE_WORN';

    public function label(): string
    {
        return match ($this) {
            self::NEW_WITH_TAGS => 'Mới nguyên tem / Chưa qua sử dụng',
            self::LIKE_NEW => 'Như mới (95% - 99%)',
            self::GOOD => 'Tốt (Có dấu hiệu sử dụng nhẹ)',
            self::FAIR => 'Trung bình (Có khuyết điểm rõ)',
            self::VINTAGE_WORN => 'Vintage sờn rách tự nhiên (Đặc thù)',
        };
    }
}
