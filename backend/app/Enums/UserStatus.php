<?php

namespace App\Enums;

enum UserStatus: string
{
    case ACTIVE = 'ACTIVE';
    case SUSPENDED = 'SUSPENDED';
    case BANNED = 'BANNED';

    public function label(): string
    {
        return match ($this) {
            self::ACTIVE => 'Đang hoạt động',
            self::SUSPENDED => 'Tạm đình chỉ',
            self::BANNED => 'Bị khóa vĩnh viễn',
        };
    }
}
