<?php

namespace App\Exceptions;

use App\Support\ApiResponse;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DomainException extends Exception
{
    protected string $errorCode;
    protected int $httpStatus;
    protected ?array $errors;
    protected ?array $latestState;

    public function __construct(
        string $message = 'Đã xảy ra lỗi nghiệp vụ.',
        string $errorCode = 'DOMAIN_ERROR',
        int $httpStatus = 400,
        ?array $errors = null,
        ?array $latestState = null,
        ?\Throwable $previous = null
    ) {
        parent::__construct($message, $httpStatus, $previous);
        $this->errorCode = $errorCode;
        $this->httpStatus = $httpStatus;
        $this->errors = $errors;
        $this->latestState = $latestState;
    }

    public function getErrorCode(): string
    {
        return $this->errorCode;
    }

    public function getHttpStatus(): int
    {
        return $this->httpStatus;
    }

    public function getErrors(): ?array
    {
        return $this->errors;
    }

    public function getLatestState(): ?array
    {
        return $this->latestState;
    }

    /**
     * Render the exception into an HTTP JSON response.
     */
    public function render(Request $request): JsonResponse
    {
        return ApiResponse::error(
            $this->errorCode,
            $this->getMessage(),
            $this->httpStatus,
            $this->errors,
            $this->latestState
        );
    }
}
