<?php

namespace App\Exceptions;

class RolePermissionDeniedException extends DomainException
{
    public function __construct(
        string $message = 'Bạn không có quyền thực hiện thao tác này.',
        ?array $errors = null,
        ?array $latestState = null
    ) {
        parent::__construct($message, 'ROLE_PERMISSION_DENIED', 403, $errors, $latestState);
    }
}
