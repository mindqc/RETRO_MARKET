<?php

namespace App\Services\Governance;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Exceptions\DomainException;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class UserGovernanceService
{
    public function __construct(
        protected AuditLogService $auditLogService
    ) {}

    /**
     * Update account status of a user (suspend, ban, or reactivate) with full audit trail (BR-AC-04 / BR-AD-02 / DEC-08-02).
     *
     * @throws RolePermissionDeniedException
     * @throws DomainException
     * @throws ValidationException
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

        $cleanReason = trim($reason);
        if (mb_strlen($cleanReason) < 5) {
            throw ValidationException::withMessages([
                'reason' => 'Lý do thay đổi trạng thái tài khoản phải có ít nhất 5 ký tự.',
            ]);
        }

        $statusEnum = $newStatus instanceof UserStatus ? $newStatus : UserStatus::from($newStatus);

        return DB::transaction(function () use ($actor, $targetUser, $statusEnum, $cleanReason, $suspendedUntil) {
            /** @var User $lockedUser */
            $lockedUser = User::where('id', $targetUser->id)->lockForUpdate()->firstOrFail();

            // Last active admin protection
            if ($lockedUser->isAdmin() && $statusEnum !== UserStatus::ACTIVE) {
                $activeAdminCount = User::where('role', UserRole::ADMIN)
                    ->where('status', UserStatus::ACTIVE)
                    ->count();

                if ($activeAdminCount <= 1) {
                    throw new DomainException(
                        'Không thể khóa Quản trị viên (Admin) đang hoạt động duy nhất của hệ thống.',
                        'LAST_ADMIN_PROTECTION',
                        400
                    );
                }
            }

            $oldValues = [
                'status' => $lockedUser->status instanceof UserStatus ? $lockedUser->status->value : (string) $lockedUser->status,
                'status_reason' => $lockedUser->status_reason,
                'suspended_until' => $lockedUser->suspended_until?->toIso8601String(),
            ];

            $lockedUser->update([
                'status' => $statusEnum,
                'status_reason' => $cleanReason,
                'suspended_until' => $suspendedUntil ? Carbon::parse($suspendedUntil) : null,
            ]);

            // When suspended or banned, revoke ALL active Sanctum tokens immediately (BR-AC-04)
            if ($statusEnum !== UserStatus::ACTIVE) {
                $lockedUser->tokens()->delete();
            }

            // Record immutable audit log
            $this->auditLogService->record(
                actor: $actor,
                action: 'UPDATE_ACCOUNT_STATUS',
                targetType: 'users',
                targetId: $lockedUser->id,
                reason: $cleanReason,
                oldValues: $oldValues,
                newValues: [
                    'status' => $statusEnum->value,
                    'status_reason' => $cleanReason,
                    'suspended_until' => $suspendedUntil,
                ],
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );

            return $lockedUser->fresh();
        });
    }

    /**
     * Update user role with strict invariants and audit logging (DEC-08-02).
     *
     * @throws RolePermissionDeniedException
     * @throws DomainException
     * @throws ValidationException
     */
    public function updateUserRole(
        User $actor,
        User $targetUser,
        string|UserRole $newRole,
        string $reason
    ): User {
        if (! $actor->isAdmin()) {
            throw new RolePermissionDeniedException('Chỉ Quản trị viên (Admin) mới có quyền thay đổi vai trò tài khoản.');
        }

        if ($actor->id === $targetUser->id) {
            throw new DomainException(
                'Quản trị viên không thể tự thay đổi vai trò hoặc tự hạ quyền của chính mình.',
                'SELF_MODIFICATION_FORBIDDEN',
                400
            );
        }

        $cleanReason = trim($reason);
        if (mb_strlen($cleanReason) < 5) {
            throw ValidationException::withMessages([
                'reason' => 'Lý do thay đổi vai trò người dùng phải có ít nhất 5 ký tự.',
            ]);
        }

        $roleEnum = $newRole instanceof UserRole ? $newRole : UserRole::from($newRole);

        return DB::transaction(function () use ($actor, $targetUser, $roleEnum, $cleanReason) {
            /** @var User $lockedUser */
            $lockedUser = User::where('id', $targetUser->id)->lockForUpdate()->firstOrFail();

            // Last active admin protection
            if ($lockedUser->isAdmin() && $roleEnum !== UserRole::ADMIN) {
                $activeAdminCount = User::where('role', UserRole::ADMIN)
                    ->where('status', UserStatus::ACTIVE)
                    ->count();

                if ($activeAdminCount <= 1) {
                    throw new DomainException(
                        'Không thể hạ quyền Quản trị viên (Admin) đang hoạt động duy nhất của hệ thống.',
                        'LAST_ADMIN_PROTECTION',
                        400
                    );
                }
            }

            $oldValues = [
                'role' => $lockedUser->role instanceof UserRole ? $lockedUser->role->value : (string) $lockedUser->role,
            ];

            $lockedUser->update([
                'role' => $roleEnum,
            ]);

            // Revoke tokens on role change
            $lockedUser->tokens()->delete();

            // Record immutable audit log
            $this->auditLogService->record(
                actor: $actor,
                action: 'UPDATE_USER_ROLE',
                targetType: 'users',
                targetId: $lockedUser->id,
                reason: $cleanReason,
                oldValues: $oldValues,
                newValues: [
                    'role' => $roleEnum->value,
                ],
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );

            return $lockedUser->fresh();
        });
    }
}
