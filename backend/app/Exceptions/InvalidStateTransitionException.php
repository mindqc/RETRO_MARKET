<?php

namespace App\Exceptions;

class InvalidStateTransitionException extends DomainException
{
    public function __construct(
        string $message = 'Thao tác chuyển đổi trạng thái không hợp lệ với trạng thái hiện tại.',
        ?array $errors = null,
        ?array $latestState = null
    ) {
        parent::__construct($message, 'INVALID_STATE_TRANSITION', 409, $errors, $latestState);
    }
}
