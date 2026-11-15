<?php

namespace App\Services\Governance;

use App\Enums\UserStatus;
use App\Exceptions\DomainException;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\User;
use Carbon\Carbon;

class UserGovernanceService
{
    public function __construct(
        protected AuditLogService $auditLogService
    ) {}

    /**
     * Update account status of a user (suspend, ban, or reactivate) with full audit trail (BR-AC-04 / BR-AD-02).
     *
     * @throws RolePermissionDeniedException
     * @throws DomainException
     */
    public function updateAccountStatus(
        User $actor,
        User $targetUser,
        string|UserStatus $newStatus,
        string $reason,
        ?string $suspendedUntil = null
    ): User {
        if (! $actor->isAdmin()) {
            throw new RolePermissionDeniedException('Chỉ Quản trị viên (Admin) mới có quyền thay đổi trạng thái tài khoản người dùng.');
        }

        if ($actor->id === $targetUser->id) {
            throw new DomainException(
                'Quản trị viên không thể tự thay đổi trạng thái hoặc khóa tài khoản của chính mình.',
                'SELF_MODIFICATION_FORBIDDEN',
                400
            );
        }

        $statusEnum = $newStatus instanceof UserStatus ? $newStatus : UserStatus::from($newStatus);

        $oldValues = [
            'status' => $targetUser->status instanceof UserStatus ? $targetUser->status->value : (string) $targetUser->status,
            'status_reason' => $targetUser->status_reason,
            'suspended_until' => $targetUser->suspended_until?->toIso8601String(),
        ];

        $targetUser->update([
            'status' => $statusEnum,
            'status_reason' => $reason,
            'suspended_until' => $suspendedUntil ? Carbon::parse($suspendedUntil) : null,
        ]);

        // When suspended or banned, revoke ALL active Sanctum tokens immediately (BR-AC-04)
        if ($statusEnum !== UserStatus::ACTIVE) {
            $targetUser->tokens()->delete();
        }

        // Record immutable audit log
        $this->auditLogService->record(
            actor: $actor,
            action: 'UPDATE_ACCOUNT_STATUS',
            targetType: 'users',
            targetId: $targetUser->id,
            reason: $reason,
            oldValues: $oldValues,
            newValues: [
                'status' => $statusEnum->value,
                'status_reason' => $reason,
                'suspended_until' => $suspendedUntil,
            ],
            ipAddress: request()?->ip() ?? '127.0.0.1'
        );

        return $targetUser->fresh();
    }
}
