<?php

namespace App\Exceptions;

class ResourceNotAvailableException extends DomainException
{
    public function __construct(
        string $message = 'Tài nguyên yêu cầu không tồn tại hoặc không khả dụng.',
        ?array $errors = null,
        ?array $latestState = null
    ) {
        parent::__construct($message, 'RESOURCE_NOT_AVAILABLE', 404, $errors, $latestState);
    }
}
