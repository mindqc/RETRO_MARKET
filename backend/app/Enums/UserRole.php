<?php

namespace App\Enums;

enum UserRole: string
{
    case REGISTERED_USER = 'registered_user';
    case MODERATOR = 'moderator';
    case SUPPORT = 'support';
    case ADMIN = 'admin';

    public function label(): string
    {
        return match ($this) {
            self::REGISTERED_USER => 'Người dùng (Buyer/Seller)',
            self::MODERATOR => 'Kiểm duyệt viên (Moderator)',
            self::SUPPORT => 'Chuyên viên Hỗ trợ & Tranh chấp (Support Staff)',
            self::ADMIN => 'Quản trị viên Hệ thống (Administrator)',
        };
    }
}
