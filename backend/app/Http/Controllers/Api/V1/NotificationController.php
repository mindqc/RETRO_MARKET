<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\NotificationResource;
use App\Services\Communication\NotificationService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function __construct(
        protected NotificationService $notificationService
    ) {}

    /**
     * List user notifications with category filter and unread counter.
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 15);
        $category = $request->query('category');
        $result = $this->notificationService->listUserNotifications($request->user(), $category, $perPage);

        $paginator = $result['paginator'];

        return response()->json([
            'success' => true,
            'message' => 'Lấy danh sách thông báo thành công.',
            'server_time' => now()->toIso8601String(),
            'data' => NotificationResource::collection($paginator->getCollection()),
            'unread_count' => $result['unread_count'],
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
                'has_more_pages' => $paginator->hasMorePages(),
                'unread_count' => $result['unread_count'],
            ],
        ]);
    }

    /**
     * Mark a single notification as read.
     */
    public function markAsRead(Request $request, int $id): JsonResponse
    {
        $notification = $this->notificationService->markAsRead($request->user(), $id);

        return ApiResponse::success(
            new NotificationResource($notification),
            'Đánh dấu thông báo đã đọc thành công.'
        );
    }

    /**
     * Mark all notifications of user as read.
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        $count = $this->notificationService->markAllAsRead($request->user());

        return ApiResponse::success(
            ['marked_count' => $count],
            'Đã đánh dấu tất cả thông báo là đã đọc.'
        );
    }
}
