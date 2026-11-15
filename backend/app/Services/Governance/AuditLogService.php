<?php

namespace App\Services\Governance;

use App\Enums\UserRole;
use App\Models\AuditLog;
use App\Models\User;

class AuditLogService
{
    /**
     * Record an immutable audit log entry (BR-AD-02 / NFR-REL-04).
     */
    public function record(
        ?User $actor,
        string $action,
        string $targetType,
        ?int $targetId = null,
        ?string $reason = null,
        ?array $oldValues = null,
        ?array $newValues = null,
        ?string $ipAddress = null
    ): AuditLog {
        $actorRole = 'system';
        if ($actor) {
            $actorRole = $actor->role instanceof UserRole ? $actor->role->value : (string) $actor->role;
        }

        return AuditLog::create([
            'actor_id' => $actor?->id,
            'actor_role' => $actorRole,
            'action' => $action,
            'target_type' => $targetType,
            'target_id' => $targetId,
            'reason' => $reason,
            'old_values' => $oldValues,
            'new_values' => $newValues,
            'ip_address' => $ipAddress,
        ]);
    }
}
