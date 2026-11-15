<?php

namespace App\Enums;

enum ProductStatus: string
{
    case DRAFT = 'DRAFT';
    case PENDING_REVIEW = 'PENDING_REVIEW';
    case APPROVED = 'APPROVED';
    case REJECTED = 'REJECTED';
    case SOLD = 'SOLD';
    case HIDDEN = 'HIDDEN';
    case ARCHIVED = 'ARCHIVED';

    public function label(): string
    {
        return match ($this) {
            self::DRAFT => 'Bản nháp',
            self::PENDING_REVIEW => 'Chờ kiểm duyệt',
            self::APPROVED => 'Đã duyệt / Đang hiển thị',
            self::REJECTED => 'Bị từ chối / Cần chỉnh sửa',
            self::SOLD => 'Đã bán',
            self::HIDDEN => 'Tạm ẩn',
            self::ARCHIVED => 'Đã lưu trữ',
        };
    }
}
