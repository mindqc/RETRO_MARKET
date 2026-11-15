<?php

namespace App\Services\Governance;

use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\User;
use App\Services\Auction\AuctionLifecycleService;
use App\Services\Escrow\EscrowReleaseService;
use App\Services\Order\OrderExpirationService;

class SystemDevToolsService
{
    public function __construct(
        protected AuctionLifecycleService $auctionLifecycleService,
        protected OrderExpirationService $orderExpirationService,
        protected EscrowReleaseService $escrowReleaseService,
        protected AuditLogService $auditLogService
    ) {}

    /**
     * Trigger a background job action manually in Demo Mode (ADR-05 / BR-AD-01).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function triggerJobAction(User $admin, string $actionKey): array
    {
        if (!config('retromarket.demo_mode', false)) {
            throw new InvalidStateTransitionException('Công cụ System DevTools chỉ khả dụng khi hệ thống chạy ở chế độ DEMO_MODE=true (ADR-05).');
        }

        if (!$admin->isAdmin()) {
            throw new RolePermissionDeniedException('Chỉ quản trị viên cấp cao (Admin) mới có quyền kích hoạt DevTools.');
        }

        $summary = match ($actionKey) {
            'OPEN_SCHEDULED_AUCTIONS' => [
                'action' => $actionKey,
                'result' => $this->auctionLifecycleService->openDueScheduledAuctions($admin),
            ],
            'CLOSE_EXPIRED_AUCTIONS' => [
                'action' => $actionKey,
                'result' => $this->auctionLifecycleService->closeExpiredLiveAuctions($admin),
            ],
            'EXPIRE_UNPAID_ORDERS' => [
                'action' => $actionKey,
                'result' => $this->orderExpirationService->expireOverdueUnpaidOrders($admin),
            ],
            'AUTO_COMPLETE_DELIVERED_ORDERS' => [
                'action' => $actionKey,
                'result' => $this->escrowReleaseService->autoCompleteDueDeliveredOrders($admin),
            ],
            'RUN_ALL_LIFECYCLE_JOBS' => [
                'action' => $actionKey,
                'result' => [
                    'open_scheduled' => $this->auctionLifecycleService->openDueScheduledAuctions($admin),
                    'close_expired' => $this->auctionLifecycleService->closeExpiredLiveAuctions($admin),
                    'expire_unpaid' => $this->orderExpirationService->expireOverdueUnpaidOrders($admin),
                    'auto_complete' => $this->escrowReleaseService->autoCompleteDueDeliveredOrders($admin),
                ],
            ],
            default => throw new InvalidStateTransitionException("Mã tác vụ DevTools không hợp lệ: {$actionKey}"),
        };

        $this->auditLogService->record(
            $admin,
            'DEVTOOLS_MANUAL_JOB_TRIGGER',
            'SYSTEM',
            null,
            "Manual trigger: {$actionKey}",
            null,
            $summary
        );

        return $summary;
    }
}
