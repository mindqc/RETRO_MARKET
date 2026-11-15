<?php

namespace App\Enums;

enum PaymentStatus: string
{
    case UNPAID = 'UNPAID';
    case PENDING = 'PENDING';
    case PAID = 'PAID';
    case FAILED = 'FAILED';
    case EXPIRED = 'EXPIRED';
    case REFUNDED = 'REFUNDED';

    public function label(): string
    {
        return match ($this) {
            self::UNPAID => 'Chưa thanh toán',
            self::PENDING => 'Đang chờ thanh toán',
            self::PAID => 'Đã thanh toán',
            self::FAILED => 'Thanh toán thất bại',
            self::EXPIRED => 'Đã hết hạn thanh toán',
            self::REFUNDED => 'Đã hoàn tiền',
        };
    }
}
