<?php

namespace App\Enums;

enum OrderStatus: string
{
    case PENDING_PAYMENT = 'PENDING_PAYMENT';
    case PAID = 'PAID';
    case PREPARING = 'PREPARING';
    case SHIPPED = 'SHIPPED';
    case DELIVERED = 'DELIVERED';
    case COMPLETED = 'COMPLETED';
    case CANCELLED = 'CANCELLED';
    case REFUNDED = 'REFUNDED';

    public function label(): string
    {
        return match ($this) {
            self::PENDING_PAYMENT => 'Chờ thanh toán',
            self::PAID => 'Đã thanh toán / Chờ chuẩn bị',
            self::PREPARING => 'Người bán đang chuẩn bị hàng',
            self::SHIPPED => 'Đang giao hàng',
            self::DELIVERED => 'Đã giao hàng thành công',
            self::COMPLETED => 'Đơn hàng hoàn tất',
            self::CANCELLED => 'Đã hủy đơn',
            self::REFUNDED => 'Đã hoàn tiền',
        };
    }
}
