<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;
use Illuminate\Pagination\LengthAwarePaginator;

class ApiResponse
{
    /**
     * Return a standardized success JSON response (200 OK).
     */
    public static function success(mixed $data = null, string $message = 'Thao tác thành công.', int $status = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'server_time' => now()->toIso8601String(),
            'data' => $data,
        ], $status);
    }

    /**
     * Return a standardized created JSON response (201 Created).
     */
    public static function created(mixed $data = null, string $message = 'Khởi tạo dữ liệu thành công.'): JsonResponse
    {
        return self::success($data, $message, 201);
    }

    /**
     * Return a standardized paginated JSON response.
     */
    public static function paginated(
        LengthAwarePaginator $paginator,
        mixed $transformedItems = null,
        string $message = 'Lấy danh sách thành công.',
        int $status = 200
    ): JsonResponse {
        return response()->json([
            'success' => true,
            'message' => $message,
            'server_time' => now()->toIso8601String(),
            'data' => $transformedItems ?? $paginator->items(),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
                'has_more_pages' => $paginator->hasMorePages(),
            ],
        ], $status);
    }

    /**
     * Return a standardized error JSON response (4xx / 5xx).
     */
    public static function error(
        string $errorCode,
        string $message,
        int $status = 400,
        ?array $errors = null,
        ?array $latestState = null
    ): JsonResponse {
        $payload = [
            'success' => false,
            'error_code' => $errorCode,
            'message' => $message,
            'server_time' => now()->toIso8601String(),
        ];

        if ($errors !== null) {
            $payload['errors'] = $errors;
        }

        if ($latestState !== null) {
            $payload['latest_state'] = $latestState;
        }

        return response()->json($payload, $status);
    }
}
