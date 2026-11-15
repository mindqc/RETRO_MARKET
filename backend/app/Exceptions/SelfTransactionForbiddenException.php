<?php

namespace App\Exceptions;

class SelfTransactionForbiddenException extends DomainException
{
    public function __construct(
        string $message = 'Không thể thực hiện giao dịch hoặc thao tác trên sản phẩm của chính mình.',
        ?array $errors = null,
        ?array $latestState = null
    ) {
        parent::__construct($message, 'SELF_TRANSACTION_FORBIDDEN', 403, $errors, $latestState);
    }
}
