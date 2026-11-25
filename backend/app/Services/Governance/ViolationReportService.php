<?php

namespace App\Services\Governance;

use App\Enums\UserRole;
use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\AuditLog;
use App\Models\Conversation;
use App\Models\Report;
use App\Models\User;
use App\Support\AdminPermission;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ViolationReportService
{
    /**
     * Submit a violation report and optionally block the conversation.
     */
    public function submitReport(User $reporter, array $data): Report
    {
        return DB::transaction(function () use ($reporter, $data) {
            $report = Report::create([
                'reporter_id' => $reporter->id,
                'target_type' => $data['target_type'],
                'target_id' => (int) $data['target_id'],
                'reason_category' => $data['reason_category'],
                'description' => trim($data['description']),
                'status' => 'PENDING',
            ]);

            $blockRequested = filter_var($data['block_conversation'] ?? false, FILTER_VALIDATE_BOOLEAN);

            if ($blockRequested && strtoupper((string) $data['target_type']) === 'CONVERSATION') {
                $conversation = Conversation::find($data['target_id']);
                if (
                    $conversation
                    && (
                        (int) $conversation->user_one_id === $reporter->id
                        || (int) $conversation->user_two_id === $reporter->id
                    )
                ) {
                    $conversation->update([
                        'blocked_by_user_id' => $reporter->id,
                    ]);
                }
            }

            return $report;
        });
    }

    /**
     * Resolve or dismiss a violation report with mandatory note (DEC-08-02 / PERM-CM-04 / PERM-CM-11).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     * @throws ValidationException
     */
    public function resolveReport(User $staff, int $reportId, string $resolutionNote, string $status = 'RESOLVED_ACTION_TAKEN'): Report
    {
        if (!AdminPermission::can($staff, 'reports.resolve')) {
            throw new RolePermissionDeniedException('Bạn không có quyền xử lý báo cáo vi phạm.');
        }

        $cleanNote = trim($resolutionNote);
        if (mb_strlen($cleanNote) < 5) {
            throw ValidationException::withMessages([
                'resolution_note' => 'Ghi chú xử lý báo cáo phải có ít nhất 5 ký tự.',
            ]);
        }

        if (!in_array($status, ['RESOLVED_ACTION_TAKEN', 'DISMISSED'], true)) {
            throw ValidationException::withMessages([
                'status' => 'Trạng thái xử lý không hợp lệ.',
            ]);
        }

        return DB::transaction(function () use ($staff, $reportId, $cleanNote, $status) {
            /** @var Report $report */
            $report = Report::where('id', $reportId)->lockForUpdate()->firstOrFail();

            if ($report->status !== 'PENDING') {
                throw new InvalidStateTransitionException('Báo cáo này đã được xử lý trước đó, không thể xử lý lại.');
            }

            $oldStatus = $report->status;

            $report->update([
                'status' => $status,
                'resolution_note' => $cleanNote,
                'handled_by' => $staff->id,
                'handled_at' => now(),
            ]);

            $actorRole = $staff->role instanceof UserRole ? $staff->role->value : (string) $staff->role;

            // Record immutable audit log
            AuditLog::create([
                'actor_id' => $staff->id,
                'actor_role' => $actorRole,
                'action' => 'REPORT_RESOLVED',
                'target_type' => 'REPORT',
                'target_id' => $report->id,
                'reason' => $cleanNote,
                'old_values' => ['status' => $oldStatus],
                'new_values' => [
                    'status' => $status,
                    'resolution_note' => $cleanNote,
                    'handled_by' => $staff->id,
                    'handled_at' => now()->toIso8601String(),
                ],
                'ip_address' => request()?->ip() ?? '127.0.0.1',
            ]);

            return $report->fresh(['reporter', 'handler']);
        });
    }
}
