<?php

namespace App\Http\Controllers\Admin;

use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Exceptions\RolePermissionDeniedException;
use App\Http\Controllers\Controller;
use App\Models\Dispute;
use App\Models\Order;
use App\Services\Escrow\DisputeService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DisputeManagementController extends Controller
{
    public function __construct(
        protected DisputeService $disputeService
    ) {}

    /**
     * Display Dispute Management Queue (Screen A-DP-01).
     */
    public function index(Request $request): View
    {
        $query = Dispute::query()
            ->with(['order', 'buyer.profile', 'seller.sellerProfile', 'assignedSupport']);

        // Search: dispute_code, order_code, buyer, seller
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('dispute_code', 'ilike', "%{$search}%")
                    ->orWhereHas('order', fn ($oq) => $oq->where('order_code', 'ilike', "%{$search}%"))
                    ->orWhereHas('buyer', fn ($bq) => $bq->where('display_name', 'ilike', "%{$search}%")->orWhere('email', 'ilike', "%{$search}%"))
                    ->orWhereHas('seller', fn ($sq) => $sq->where('display_name', 'ilike', "%{$search}%")->orWhere('email', 'ilike', "%{$search}%"));
            });
        }

        // Status Filter
        if ($status = $request->input('status')) {
            $query->where('status', $status);
        }

        // Reason Category Filter
        if ($reasonCategory = $request->input('reason_category')) {
            $query->where('reason_category', $reasonCategory);
        }

        // Summary Statistics
        $stats = [
            'total' => Dispute::count(),
            'open' => Dispute::where('status', DisputeStatus::OPEN)->count(),
            'need_more_info' => Dispute::where('status', DisputeStatus::NEED_MORE_INFO)->count(),
            'resolved' => Dispute::where('status', DisputeStatus::RESOLVED)->count(),
            'frozen_amount' => (float) Order::where('dispute_status', '!=', DisputeStatus::NONE)
                ->where('escrow_status', EscrowStatus::HELD)
                ->sum('item_subtotal'),
        ];

        $disputes = $query->orderByDesc('id')->paginate(15)->withQueryString();

        return view('admin.disputes.index', compact('disputes', 'stats'));
    }

    /**
     * Display Split-Pane Evidence Workbench & Verdict Case Room (Screen A-DP-02).
     */
    public function show(int $id): View
    {
        $dispute = Dispute::with([
            'order.items.product.primaryImage',
            'order.shipment',
            'buyer.profile',
            'seller.sellerProfile',
            'evidences.uploader',
            'assignedSupport',
            'resolvedByAdmin',
        ])->findOrFail($id);

        return view('admin.disputes.show', compact('dispute'));
    }

    /**
     * Support & Admin request additional evidence (STAFF_REQUEST_NOTE -> NEED_MORE_INFO).
     */
    public function requestInfo(Request $request, int $id): RedirectResponse
    {
        $dispute = Dispute::findOrFail($id);

        $validated = $request->validate([
            'message_note' => 'required|string|min:5|max:1000',
        ], [
            'message_note.required' => 'Vui lòng nhập nội dung yêu cầu bổ sung bằng chứng.',
            'message_note.min' => 'Nội dung yêu cầu phải có ít nhất 5 ký tự.',
        ]);

        try {
            $this->disputeService->submitEvidenceOrResponse(
                $request->user(),
                $dispute,
                ['message_note' => $validated['message_note']]
            );

            return redirect()->route('admin.disputes.show', $dispute->id)
                ->with('success', 'Đã gửi yêu cầu bổ sung bằng chứng (STAFF_REQUEST_NOTE) thành công.');
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', $e->getMessage())
                ->withInput();
        }
    }

    /**
     * Supreme Administrator executes financial verdict (PERM-CM-09 / DEC-07 / BR-FN-06).
     * Strictly restricted to role=admin (Separation of Duties DEC-08-03).
     */
    public function verdict(Request $request, int $id): RedirectResponse
    {
        // Enforce strict Separation of Duties at controller entrypoint
        if (! $request->user()?->isAdmin()) {
            throw new RolePermissionDeniedException('Chỉ có quản trị viên tối cao (Admin) mới có thẩm quyền ra phán quyết khiếu nại tài chính (PERM-CM-09 / DEC-08-03).');
        }

        $dispute = Dispute::findOrFail($id);

        $validated = $request->validate([
            'verdict' => 'required|string|in:APPROVE_BUYER_REFUND,RELEASE_TO_SELLER,PARTIAL_REFUND',
            'partial_refund_to_buyer' => 'nullable|numeric|min:1',
            'resolution_note' => 'required|string|min:5|max:1000',
        ], [
            'verdict.required' => 'Vui lòng chọn phán quyết tài chính.',
            'verdict.in' => 'Phán quyết tài chính không hợp lệ.',
            'resolution_note.required' => 'Vui lòng nhập ghi chú phán quyết của Quản trị viên.',
            'resolution_note.min' => 'Ghi chú phán quyết phải có ít nhất 5 ký tự.',
        ]);

        try {
            $partialAmount = ! empty($validated['partial_refund_to_buyer'])
                ? (float) $validated['partial_refund_to_buyer']
                : null;

            $this->disputeService->resolveDisputeByAdmin(
                $request->user(),
                $dispute,
                $validated['verdict'],
                $partialAmount,
                $validated['resolution_note']
            );

            return redirect()->route('admin.disputes.show', $dispute->id)
                ->with('success', 'Phán quyết tài chính đã được thực thi thành công theo chuẩn DEC-07.');
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', $e->getMessage())
                ->withInput();
        }
    }
}
