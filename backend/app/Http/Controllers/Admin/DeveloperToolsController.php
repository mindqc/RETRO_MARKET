<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Services\Governance\PlatformConfigService;
use App\Services\Governance\SystemDevToolsService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DeveloperToolsController extends Controller
{
    public function __construct(
        protected SystemDevToolsService $devToolsService,
        protected PlatformConfigService $configService
    ) {}

    /**
     * Check Dual-Gate Security (Admin Role + DEMO_MODE=true).
     */
    protected function ensureDualGate(Request $request): void
    {
        if (!config('retromarket.demo_mode', false)) {
            abort(403, 'Công cụ Developer Tools chỉ khả dụng khi hệ thống chạy ở chế độ DEMO_MODE=true (ADR-05).');
        }

        if (!$request->user()?->isAdmin()) {
            abort(403, 'Chỉ Quản trị viên cấp cao (Admin) mới có quyền truy cập và thao tác trên Developer Tools.');
        }
    }

    /**
     * Display Developer Tools & Manual Job Triggers (Screen A-DT-01).
     */
    public function index(Request $request): View
    {
        $this->ensureDualGate($request);

        $jobs = [
            'OPEN_SCHEDULED_AUCTIONS' => [
                'name' => '1. Open Scheduled Auctions Job',
                'description' => 'Quét các phiên đấu giá SCHEDULED có starts_at <= hiện tại để chuyển sang LIVE.',
                'target' => 'OpenScheduledAuctionsJob / AuctionLifecycleService',
                'badge' => 'Auctions',
            ],
            'CLOSE_EXPIRED_AUCTIONS' => [
                'name' => '2. Close Expired Auctions Job',
                'description' => 'Quét các phiên đấu giá LIVE có ends_at <= hiện tại để chuyển sang COMPLETED (hoặc NO_BIDS) và tạo đơn hàng cho người thắng.',
                'target' => 'CloseExpiredAuctionsJob / AuctionLifecycleService',
                'badge' => 'Auctions',
            ],
            'EXPIRE_UNPAID_ORDERS' => [
                'name' => '3. Expire Unpaid Auction Orders Job',
                'description' => 'Hủy đơn hàng đấu giá quá hạn thanh toán (2 phút Demo / 30 phút Prod), đánh dấu WINNER_DEFAULTED và áp dụng chế tài.',
                'target' => 'ExpireUnpaidAuctionOrdersJob / OrderExpirationService',
                'badge' => 'Orders',
            ],
            'AUTO_COMPLETE_DELIVERED_ORDERS' => [
                'name' => '4. Auto Complete Delivered Orders Job',
                'description' => 'Quét các đơn hàng DELIVERED quá hạn giải ngân (2 phút Demo / 24h Prod) không có tranh chấp để chuyển sang COMPLETED và giải ngân ký quỹ.',
                'target' => 'AutoCompleteDeliveredOrdersJob / EscrowReleaseService',
                'badge' => 'Escrow',
            ],
            'RUN_ALL_LIFECYCLE_JOBS' => [
                'name' => '⚡ Chạy Toàn bộ 4 Chu trình Vòng đời (Run All Lifecycle Jobs)',
                'description' => 'Thực thi tuần tự cả 4 tác vụ trên trong một lệnh duy nhất theo đúng luồng nghiệp vụ end-to-end.',
                'target' => 'SystemDevToolsService::RUN_ALL_LIFECYCLE_JOBS',
                'badge' => 'Batch Orchestration',
            ],
        ];

        $demoTimers = [
            'demo_mode' => config('retromarket.demo_mode', false),
            'auction_payment_demo' => $this->configService->get('auction_payment_window_demo_sec', 120),
            'auction_payment_prod' => $this->configService->get('auction_payment_window_production_sec', 1800),
            'auto_complete_demo' => $this->configService->get('auto_complete_window_demo_sec', 120),
            'auto_complete_prod' => $this->configService->get('auto_complete_window_production_sec', 86400),
            'anti_sniping_demo' => $this->configService->get('anti_sniping_trigger_window_demo_sec', 30),
            'anti_sniping_prod' => $this->configService->get('anti_sniping_trigger_window_production_sec', 120),
        ];

        // Recent manual triggers
        $recentTriggers = AuditLog::where('action', 'DEVTOOLS_MANUAL_JOB_TRIGGER')
            ->with('actor')
            ->orderByDesc('id')
            ->limit(8)
            ->get();

        return view('admin.dev_tools.index', compact('jobs', 'demoTimers', 'recentTriggers'));
    }

    /**
     * Trigger a background job manually (Admin only in DEMO_MODE=true).
     */
    public function trigger(Request $request): RedirectResponse
    {
        $this->ensureDualGate($request);

        $validated = $request->validate([
            'action_key' => 'required|string|in:OPEN_SCHEDULED_AUCTIONS,CLOSE_EXPIRED_AUCTIONS,EXPIRE_UNPAID_ORDERS,AUTO_COMPLETE_DELIVERED_ORDERS,RUN_ALL_LIFECYCLE_JOBS',
        ]);

        try {
            $result = $this->devToolsService->triggerJobAction(
                $request->user(),
                $validated['action_key']
            );

            return redirect()->route('admin.dev_tools.index')
                ->with('success', "Đã kích hoạt thủ công tác vụ [{$validated['action_key']}] thành công. Kết quả đã được ghi vào Audit Logs.")
                ->with('job_result', $result);
        } catch (\Exception $e) {
            return redirect()->route('admin.dev_tools.index')
                ->with('error', $e->getMessage());
        }
    }
}
