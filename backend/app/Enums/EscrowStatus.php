<?php

namespace App\Enums;

enum EscrowStatus: string
{
    case NONE = 'NONE';
    case HELD = 'HELD';
    case RELEASED = 'RELEASED';
    case REFUNDED = 'REFUNDED';
    case PARTIALLY_REFUNDED = 'PARTIALLY_REFUNDED';

    public function label(): string
    {
        return match ($this) {
            self::NONE => 'Chưa phát sinh giữ tiền',
            self::HELD => 'Đang giữ tiền bảo vệ (Escrow Held)',
            self::RELEASED => 'Đã giải ngân 100% cho Người bán',
            self::REFUNDED => 'Đã hoàn tiền 100% cho Người mua',
            self::PARTIALLY_REFUNDED => 'Đã hoàn tiền một phần',
        };
    }
}
