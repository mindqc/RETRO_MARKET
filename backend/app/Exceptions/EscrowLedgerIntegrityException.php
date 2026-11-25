<?php

namespace App\Exceptions;

use Throwable;

class EscrowLedgerIntegrityException extends DomainException
{
    public function __construct(
        string $message = 'Phát hiện mâu thuẫn hoặc thiếu hụt số dư ký quỹ Escrow.',
        string $errorCode = 'ESCROW_LEDGER_INTEGRITY_VIOLATION',
        int $httpStatus = 500,
        ?array $errors = null,
        ?array $latestState = null,
        ?Throwable $previous = null
    ) {
        parent::__construct($message, $errorCode, $httpStatus, $errors, $latestState, $previous);
    }
}
