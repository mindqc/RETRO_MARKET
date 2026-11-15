<?php

namespace App\Services\Communication;

use App\Exceptions\RolePermissionDeniedException;
use App\Models\Notification;
use App\Models\User;

class NotificationService
{
    /**
     * List user notifications with category filtering and unread count.
     */
    public function listUserNotifications(User $user, ?string $category = null, int $perPage = 15): array
    {
        $query = Notification::where('user_id', $user->id)->orderBy('id', 'desc');

        if (! empty($category)) {
            $cat = strtolower(trim($category));
            $query->where(function ($q) use ($cat) {
                $q->whereRaw('LOWER(target_type) = ?', [$cat])
                    ->orWhereRaw('LOWER(type) LIKE ?', ["%{$cat}%"]);
            });
        }

        $unreadCount = Notification::where('user_id', $user->id)
            ->where('is_read', false)
            ->count();

        return [
            'paginator' => $query->paginate($perPage),
            'unread_count' => $unreadCount,
        ];
    }

    /**
     * Mark a single notification as read.
     */
    public function markAsRead(User $user, int $notificationId): Notification
    {
        $notification = Notification::findOrFail($notificationId);

        if ((int) $notification->user_id !== $user->id) {
            throw new RolePermissionDeniedException('Bạn không có quyền truy cập thông báo này.');
        }

        if (! $notification->is_read) {
            $notification->update([
                'is_read' => true,
                'read_at' => now(),
            ]);
        }

        return $notification;
    }

    /**
     * Mark all unread notifications of the user as read.
     */
    public function markAllAsRead(User $user): int
    {
        return Notification::where('user_id', $user->id)
            ->where('is_read', false)
            ->update([
                'is_read' => true,
                'read_at' => now(),
            ]);
    }
}
