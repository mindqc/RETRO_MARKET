<?php

namespace App\Exceptions;

class AccountSuspendedException extends DomainException
{
    public function __construct(
        string $message = 'Tài khoản của bạn đã bị tạm khóa hoặc cấm hoạt động do vi phạm quy định cộng đồng.',
        ?array $errors = null,
        ?array $latestState = null
    ) {
        parent::__construct($message, 'ACCOUNT_SUSPENDED', 403, $errors, $latestState);
    }
}
