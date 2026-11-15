<?php

namespace App\Exceptions;

class AuctionOutbidConflictException extends DomainException
{
    public function __construct(
        string $message = 'Mức giá đặt đã bị người mua khác vượt qua. Vui lòng cập nhật giá mới.',
        ?array $latestState = null,
        ?array $errors = null
    ) {
        parent::__construct($message, 'AUCTION_OUTBID_CONFLICT', 409, $errors, $latestState);
    }
}
