<?php

namespace App\Services\Governance;

use App\Models\Conversation;
use App\Models\Report;
use App\Models\User;
use Illuminate\Support\Facades\DB;

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
}
