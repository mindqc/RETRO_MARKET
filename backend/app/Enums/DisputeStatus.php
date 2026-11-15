<?php

namespace App\Enums;

enum DisputeStatus: string
{
    case NONE = 'NONE';
    case OPEN = 'OPEN';
    case NEED_MORE_INFO = 'NEED_MORE_INFO';
    case RESOLVED = 'RESOLVED';

    public function label(): string
    {
        return match ($this) {
            self::NONE => 'Không có khiếu nại',
            self::OPEN => 'Đang mở khiếu nại (Đã khóa giải ngân)',
            self::NEED_MORE_INFO => 'Yêu cầu bổ sung thêm bằng chứng',
            self::RESOLVED => 'Đã phân xử xong',
        };
    }
}
