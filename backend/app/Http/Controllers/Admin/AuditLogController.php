<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AuditLogController extends Controller
{
    /**
     * Display Audit Logs Explorer (Screen A-AD-01).
     * Strictly Read-Only: Zero mutating endpoints.
     */
    public function index(Request $request): View
    {
        if (!$request->user()?->isAdmin()) {
            abort(403, 'Chỉ Quản trị viên (Admin) mới có quyền tra cứu nhật ký kiểm toán hệ thống.');
        }

        $query = AuditLog::query()->with('actor');

        // Filter: action
        if ($action = $request->input('action')) {
            $query->where('action', $action);
        }

        // Filter: target_type
        if ($targetType = $request->input('target_type')) {
            $query->where('target_type', $targetType);
        }

        // Filter: actor_id
        if ($actorId = $request->input('actor_id')) {
            $query->where('actor_id', $actorId);
        }

        // Filter: date range
        if ($dateFrom = $request->input('date_from')) {
            $query->whereDate('created_at', '>=', $dateFrom);
        }
        if ($dateTo = $request->input('date_to')) {
            $query->whereDate('created_at', '<=', $dateTo);
        }

        // Search: reason or target_id
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('reason', 'ilike', "%{$search}%")
                    ->orWhere('target_id', 'ilike', "%{$search}%")
                    ->orWhereHas('actor', fn ($aq) => $aq->where('display_name', 'ilike', "%{$search}%")->orWhere('email', 'ilike', "%{$search}%"));
            });
        }

        // Stats
        $stats = [
            'total' => AuditLog::count(),
            'today' => AuditLog::whereDate('created_at', today())->count(),
            'actors_count' => AuditLog::distinct('actor_id')->count('actor_id'),
            'actions_count' => AuditLog::distinct('action')->count('action'),
        ];

        // Unique action types for dropdown filter
        $availableActions = AuditLog::distinct()->pluck('action')->sort()->values();
        $availableTargetTypes = AuditLog::distinct()->pluck('target_type')->sort()->values();

        $auditLogs = $query->orderByDesc('id')->paginate(20)->withQueryString();

        return view('admin.audit_logs.index', compact(
            'auditLogs',
            'stats',
            'availableActions',
            'availableTargetTypes'
        ));
    }
}
