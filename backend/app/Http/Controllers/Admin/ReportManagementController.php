<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Report;
use App\Services\Governance\ViolationReportService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ReportManagementController extends Controller
{
    public function __construct(
        protected ViolationReportService $reportService
    ) {}

    /**
     * Display Violation / Moderation Reports Management (Screen A-CM-01).
     */
    public function index(Request $request): View
    {
        $query = Report::query()
            ->with(['reporter', 'handler']);

        // Search: description, reporter name/email, target_id
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('description', 'ilike', "%{$search}%")
                    ->orWhere('target_id', 'ilike', "%{$search}%")
                    ->orWhereHas('reporter', fn ($rq) => $rq->where('display_name', 'ilike', "%{$search}%")->orWhere('email', 'ilike', "%{$search}%"));
            });
        }

        // Status filter
        if ($status = $request->input('status')) {
            $query->where('status', $status);
        }

        // Target type filter
        if ($targetType = $request->input('target_type')) {
            $query->where('target_type', $targetType);
        }

        // Reason category filter
        if ($reasonCategory = $request->input('reason_category')) {
            $query->where('reason_category', $reasonCategory);
        }

        // Summary Statistics
        $stats = [
            'total' => Report::count(),
            'pending' => Report::where('status', 'PENDING')->count(),
            'resolved' => Report::where('status', 'RESOLVED_ACTION_TAKEN')->count(),
            'dismissed' => Report::where('status', 'DISMISSED')->count(),
        ];

        $reports = $query->orderByDesc('id')->paginate(15)->withQueryString();

        return view('admin.reports.index', compact('reports', 'stats'));
    }

    /**
     * Resolve or dismiss a violation report with mandatory note (DEC-08-02 / PERM-CM-04 / PERM-CM-11).
     */
    public function resolve(Request $request, int $id): RedirectResponse
    {
        $validated = $request->validate([
            'status' => 'required|string|in:RESOLVED_ACTION_TAKEN,DISMISSED',
            'resolution_note' => 'required|string|min:5|max:1000',
        ], [
            'status.required' => 'Vui lòng chọn quyết định xử lý báo cáo.',
            'status.in' => 'Quyết định xử lý không hợp lệ.',
            'resolution_note.required' => 'Vui lòng nhập ghi chú xử lý báo cáo (bắt buộc).',
            'resolution_note.min' => 'Ghi chú xử lý phải có ít nhất 5 ký tự.',
        ]);

        try {
            $this->reportService->resolveReport(
                $request->user(),
                $id,
                $validated['resolution_note'],
                $validated['status']
            );

            $actionText = ($validated['status'] === 'RESOLVED_ACTION_TAKEN') ? 'xử lý xử phạt' : 'bác bỏ (dismissed)';

            return redirect()->route('admin.moderation.reports.index')
                ->with('success', "Báo cáo #{$id} đã được {$actionText} thành công.");
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', $e->getMessage())
                ->withInput();
        }
    }
}
