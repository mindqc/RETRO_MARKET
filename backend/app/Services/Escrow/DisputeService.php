<?php

namespace App\Services\Escrow;

use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\Dispute;
use App\Models\DisputeEvidence;
use App\Models\EscrowTransaction;
use App\Models\Notification;
use App\Models\Order;
use App\Models\Payment;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\WalletTransaction;
use App\Services\Governance\AuditLogService;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class DisputeService
{
    public function __construct(
        protected EscrowReleaseService $escrowReleaseService,
        protected AuditLogService $auditLogService
    ) {}

    /**
     * Buyer opens a formal dispute on an order (DEC-03 / OF-08 / BR-DP-01).
     * Automatically freezes auto-release of Escrow (BR-DP-02).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function openDispute(User $buyer, Order $order, array $data, array $uploadedFiles = []): Dispute
    {
        return DB::transaction(function () use ($buyer, $order, $data, $uploadedFiles) {
            /** @var Order $lockedOrder */
            $lockedOrder = Order::where('id', $order->id)->lockForUpdate()->firstOrFail();

            if ($lockedOrder->buyer_id !== $buyer->id) {
                throw new RolePermissionDeniedException('Bạn không có quyền mở khiếu nại cho đơn hàng này.');
            }

            $orderStatus = $lockedOrder->order_status instanceof OrderStatus
                ? $lockedOrder->order_status->value
                : (string) $lockedOrder->order_status;

            $escrowStatus = $lockedOrder->escrow_status instanceof EscrowStatus
                ? $lockedOrder->escrow_status->value
                : (string) $lockedOrder->escrow_status;

            $disputeStatus = $lockedOrder->dispute_status instanceof DisputeStatus
                ? $lockedOrder->dispute_status->value
                : (string) $lockedOrder->dispute_status;

            // Rule DEC-03 & BR-DP-01: Dispute only allowed when order is SHIPPED or DELIVERED, escrow is HELD, and no active dispute
            if (!in_array($orderStatus, ['SHIPPED', 'DELIVERED']) || $escrowStatus !== 'HELD' || $disputeStatus !== 'NONE') {
                throw new InvalidStateTransitionException('Chỉ có thể khiếu nại khi đơn hàng đang giao (SHIPPED) hoặc đã giao (DELIVERED), tiền đang tạm giữ và chưa có khiếu nại nào (DEC-03).');
            }

            $disputeCode = 'DSP-' . date('Y') . '-' . strtoupper(Str::random(6));

            $dispute = Dispute::create([
                'dispute_code' => $disputeCode,
                'order_id' => $lockedOrder->id,
                'buyer_id' => $buyer->id,
                'seller_id' => $lockedOrder->seller_id,
                'opened_at_order_status' => $orderStatus,
                'reason_category' => trim($data['reason_category'] ?? 'ITEM_NOT_AS_DESCRIBED'),
                'buyer_description' => trim($data['description'] ?? ''),
                'status' => DisputeStatus::OPEN,
            ]);

            // Save evidences if files were uploaded or URLs provided
            $hasFiles = false;
            if (!empty($uploadedFiles)) {
                foreach ($uploadedFiles as $file) {
                    if ($file instanceof UploadedFile) {
                        $path = $file->store("disputes/{$dispute->id}", 'public');
                        DisputeEvidence::create([
                            'dispute_id' => $dispute->id,
                            'uploader_id' => $buyer->id,
                            'uploader_role' => 'BUYER',
                            'evidence_type' => 'BUYER_PROOF',
                            'file_url' => Storage::url($path),
                            'message_note' => trim($data['description'] ?? ''),
                        ]);
                        $hasFiles = true;
                    }
                }
            }

            if (!empty($data['file_urls']) && is_array($data['file_urls'])) {
                foreach ($data['file_urls'] as $url) {
                    DisputeEvidence::create([
                        'dispute_id' => $dispute->id,
                        'uploader_id' => $buyer->id,
                        'uploader_role' => 'BUYER',
                        'evidence_type' => 'BUYER_PROOF',
                        'file_url' => trim($url),
                        'message_note' => trim($data['description'] ?? ''),
                    ]);
                    $hasFiles = true;
                }
            }

            if (!$hasFiles) {
                DisputeEvidence::create([
                    'dispute_id' => $dispute->id,
                    'uploader_id' => $buyer->id,
                    'uploader_role' => 'BUYER',
                    'evidence_type' => 'BUYER_PROOF',
                    'file_url' => null,
                    'message_note' => trim($data['description'] ?? ''),
                ]);
            }

            // Freeze Escrow Release (BR-DP-02 / DEC-03)
            $lockedOrder->update([
                'dispute_status' => DisputeStatus::OPEN,
                'escrow_frozen_at' => now(),
            ]);

            // Send notification to Seller
            Notification::create([
                'user_id' => $lockedOrder->seller_id,
                'type' => 'DISPUTE_OPENED',
                'title' => 'Đơn hàng có khiếu nại mới',
                'body' => "Người mua đã mở khiếu nại cho đơn hàng #{$lockedOrder->order_code}. Tiền trung gian đã được tạm khóa để xác minh.",
                'target_type' => 'disputes',
                'target_id' => $dispute->id,
                'deep_link_route' => "/seller/disputes/{$dispute->id}",
                'is_read' => false,
            ]);

            return $dispute->fresh(['order', 'buyer.profile', 'seller.sellerProfile', 'evidences']);
        });
    }

    /**
     * Submit additional counter-evidence or response note from Buyer, Seller, or Support (SF-11 / PERM-CM-08).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function submitEvidenceOrResponse(
        User $actor,
        Dispute $dispute,
        array $data,
        ?UploadedFile $file = null
    ): DisputeEvidence {
        return DB::transaction(function () use ($actor, $dispute, $data, $file) {
            /** @var Dispute $lockedDispute */
            $lockedDispute = Dispute::where('id', $dispute->id)->lockForUpdate()->firstOrFail();

            $isBuyer = ($actor->id === $lockedDispute->buyer_id);
            $isSeller = ($actor->id === $lockedDispute->seller_id);
            $isSupport = $actor->isSupport();
            $isAdmin = $actor->isAdmin();

            if (!$isBuyer && !$isSeller && !$isSupport && !$isAdmin) {
                throw new RolePermissionDeniedException('Bạn không có quyền tham gia vào phiên khiếu nại này.');
            }

            $currentStatus = $lockedDispute->status instanceof DisputeStatus
                ? $lockedDispute->status->value
                : (string) $lockedDispute->status;

            if ($currentStatus === 'RESOLVED') {
                throw new InvalidStateTransitionException('Khiếu nại này đã được phân xử xong (RESOLVED), không thể nộp thêm bằng chứng.');
            }

            $uploaderRole = 'BUYER';
            $evidenceType = 'BUYER_PROOF';
            $messageNote = trim($data['message_note'] ?? $data['description'] ?? '');

            if ($isSeller) {
                $uploaderRole = 'SELLER';
                $evidenceType = 'SELLER_COUNTER_PROOF';
                $lockedDispute->seller_response = $messageNote;
                // If it was waiting for info, return to OPEN
                if ($currentStatus === 'NEED_MORE_INFO') {
                    $lockedDispute->status = DisputeStatus::OPEN;
                }
                $lockedDispute->save();
            } elseif ($isSupport || $isAdmin) {
                $uploaderRole = $isAdmin ? 'ADMIN' : 'SUPPORT';
                $evidenceType = 'STAFF_REQUEST_NOTE';
                $lockedDispute->status = DisputeStatus::NEED_MORE_INFO;
                $lockedDispute->assigned_support_id = $actor->id;
                $lockedDispute->save();
            } else { // Buyer
                $uploaderRole = 'BUYER';
                $evidenceType = 'BUYER_PROOF';
                if ($currentStatus === 'NEED_MORE_INFO') {
                    $lockedDispute->status = DisputeStatus::OPEN;
                    $lockedDispute->save();
                }
            }

            $fileUrl = null;
            if ($file) {
                $path = $file->store("disputes/{$lockedDispute->id}", 'public');
                $fileUrl = Storage::url($path);
            } elseif (!empty($data['file_url'])) {
                $fileUrl = trim($data['file_url']);
            }

            return DisputeEvidence::create([
                'dispute_id' => $lockedDispute->id,
                'uploader_id' => $actor->id,
                'uploader_role' => $uploaderRole,
                'evidence_type' => $evidenceType,
                'file_url' => $fileUrl,
                'message_note' => $messageNote ?: 'Bổ sung tài liệu chứng minh cho phiên khiếu nại.',
            ]);
        });
    }

    /**
     * Supreme Administrator executes financial verdict on a dispute (PERM-CM-09 / DEC-07 / BR-FN-06).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     * @throws ValidationException
     */
    public function resolveDisputeByAdmin(
        User $admin,
        Dispute $dispute,
        string $verdict,
        ?float $partialRefundToBuyer = null,
        string $resolutionNote = ''
    ): Dispute {
        // PERM-CM-09: Financial dispute resolution strictly restricted to Admin role
        if (!$admin->isAdmin()) {
            throw new RolePermissionDeniedException('Chỉ có quản trị viên tối cao (Admin) mới có thẩm quyền ra phán quyết khiếu nại tài chính (PERM-CM-09).');
        }

        $validVerdicts = ['APPROVE_BUYER_REFUND', 'RELEASE_TO_SELLER', 'PARTIAL_REFUND'];
        if (!in_array($verdict, $validVerdicts, true)) {
            throw ValidationException::withMessages([
                'verdict' => 'Phán quyết không hợp lệ. Phải là một trong: ' . implode(', ', $validVerdicts),
            ]);
        }

        return DB::transaction(function () use ($admin, $dispute, $verdict, $partialRefundToBuyer, $resolutionNote) {
            /** @var Dispute $lockedDispute */
            $lockedDispute = Dispute::where('id', $dispute->id)->lockForUpdate()->firstOrFail();

            /** @var Order $lockedOrder */
            $lockedOrder = Order::where('id', $lockedDispute->order_id)->lockForUpdate()->firstOrFail();

            /** @var SellerProfile $sellerProfile */
            $sellerProfile = SellerProfile::where('user_id', $lockedOrder->seller_id)->lockForUpdate()->firstOrFail();

            $disputeStatus = $lockedDispute->status instanceof DisputeStatus
                ? $lockedDispute->status->value
                : (string) $lockedDispute->status;

            $escrowStatus = $lockedOrder->escrow_status instanceof EscrowStatus
                ? $lockedOrder->escrow_status->value
                : (string) $lockedOrder->escrow_status;

            if ($disputeStatus === 'RESOLVED' || $escrowStatus !== 'HELD') {
                throw new InvalidStateTransitionException('Khiếu nại đã giải quyết xong hoặc tiền Escrow không còn ở trạng thái HELD.');
            }

            $cleanNote = trim($resolutionNote);
            $paidPayment = Payment::where('order_id', $lockedOrder->id)
                ->where('status', PaymentStatus::PAID)
                ->first();

            // 1. Phán quyết 1: APPROVE_BUYER_REFUND (DEC-07)
            if ($verdict === 'APPROVE_BUYER_REFUND') {
                // Record FULL_REFUND in escrow_transactions
                EscrowTransaction::create([
                    'transaction_code' => 'ESC-REF-' . strtoupper(Str::random(10)),
                    'order_id' => $lockedOrder->id,
                    'payment_id' => $paidPayment?->id,
                    'buyer_id' => $lockedOrder->buyer_id,
                    'seller_id' => $lockedOrder->seller_id,
                    'transaction_type' => 'FULL_REFUND',
                    'gross_amount' => $lockedOrder->total_amount,
                    'item_subtotal_amount' => $lockedOrder->item_subtotal,
                    'buyer_protection_fee_amount' => $lockedOrder->buyer_protection_fee,
                    'seller_released_amount' => 0.00,
                    'buyer_refunded_amount' => $lockedOrder->total_amount,
                    'platform_fee_retained' => 0.00,
                    'triggered_by_user_id' => $admin->id,
                    'note' => $cleanNote ?: 'Admin phê duyệt hoàn tiền 100% cho người mua theo phán quyết khiếu nại (DEC-07).',
                ]);

                // Update seller profile (deduct escrow held balance and increment dispute lost count)
                $sellerProfile->update([
                    'escrow_held_balance' => max(0.00, round((float) $sellerProfile->escrow_held_balance - (float) $lockedOrder->item_subtotal, 2)),
                    'dispute_lost_count' => (int) $sellerProfile->dispute_lost_count + 1,
                ]);

                // Update Order status
                $lockedOrder->update([
                    'order_status' => OrderStatus::CANCELLED,
                    'payment_status' => PaymentStatus::REFUNDED,
                    'escrow_status' => EscrowStatus::REFUNDED,
                    'dispute_status' => DisputeStatus::RESOLVED,
                    'cancelled_by_role' => 'ADMIN',
                    'cancel_reason' => $cleanNote,
                    'cancelled_at' => now(),
                ]);
            }

            // 2. Phán quyết 2: RELEASE_TO_SELLER (DEC-04)
            if ($verdict === 'RELEASE_TO_SELLER') {
                $lockedOrder->update([
                    'escrow_frozen_at' => null,
                    'dispute_status' => DisputeStatus::RESOLVED,
                ]);

                // Delegate to EscrowReleaseService with fromAdminDisputeVerdict = true
                $this->escrowReleaseService->releaseOrderEscrowToSeller(
                    $lockedOrder,
                    $admin,
                    $cleanNote ?: 'Admin bác bỏ khiếu nại và giải ngân tiền cho người bán (DEC-04).',
                    true
                );
            }

            // 3. Phán quyết 3: PARTIAL_REFUND (BR-FN-06)
            if ($verdict === 'PARTIAL_REFUND') {
                $itemSubtotal = (float) $lockedOrder->item_subtotal;
                if ($partialRefundToBuyer === null || $partialRefundToBuyer <= 0 || $partialRefundToBuyer >= $itemSubtotal) {
                    throw ValidationException::withMessages([
                        'partial_refund_to_buyer' => 'Số tiền hoàn một phần phải lớn hơn 0 và nhỏ hơn tổng tiền hàng ' . number_format($itemSubtotal, 0, ',', '.') . 'đ (BR-FN-06).',
                    ]);
                }

                $refundAmount = round((float) $partialRefundToBuyer, 2);
                $sellerReleased = round($itemSubtotal - $refundAmount, 2);

                // Create PARTIAL_REFUND escrow transaction
                $escrowTx = EscrowTransaction::create([
                    'transaction_code' => 'ESC-PART-' . strtoupper(Str::random(10)),
                    'order_id' => $lockedOrder->id,
                    'payment_id' => $paidPayment?->id,
                    'buyer_id' => $lockedOrder->buyer_id,
                    'seller_id' => $lockedOrder->seller_id,
                    'transaction_type' => 'PARTIAL_REFUND',
                    'gross_amount' => $lockedOrder->total_amount,
                    'item_subtotal_amount' => $lockedOrder->item_subtotal,
                    'buyer_protection_fee_amount' => $lockedOrder->buyer_protection_fee,
                    'seller_released_amount' => $sellerReleased,
                    'buyer_refunded_amount' => $refundAmount,
                    'platform_fee_retained' => $lockedOrder->buyer_protection_fee,
                    'triggered_by_user_id' => $admin->id,
                    'note' => $cleanNote ?: 'Admin phân xử hoàn tiền một phần (BR-FN-06).',
                ]);

                // Credit remaining item subtotal to seller wallet
                $balanceBefore = (float) $sellerProfile->wallet_balance;
                $balanceAfter = round($balanceBefore + $sellerReleased, 2);

                WalletTransaction::create([
                    'wallet_tx_code' => 'WTX-' . date('Y') . '-' . strtoupper(Str::random(8)),
                    'seller_id' => $lockedOrder->seller_id,
                    'order_id' => $lockedOrder->id,
                    'escrow_transaction_id' => $escrowTx->id,
                    'entry_type' => 'CREDIT',
                    'amount' => $sellerReleased,
                    'balance_before' => $balanceBefore,
                    'balance_after' => $balanceAfter,
                    'description' => 'Giải ngân phần tiền hàng sau khi hòa giải khiếu nại đơn ' . $lockedOrder->order_code,
                ]);

                $sellerProfile->update([
                    'wallet_balance' => $balanceAfter,
                    'escrow_held_balance' => max(0.00, round((float) $sellerProfile->escrow_held_balance - (float) $lockedOrder->item_subtotal, 2)),
                    'completed_orders_count' => (int) $sellerProfile->completed_orders_count + 1,
                ]);

                $lockedOrder->update([
                    'order_status' => OrderStatus::COMPLETED,
                    'escrow_status' => EscrowStatus::PARTIALLY_REFUNDED,
                    'dispute_status' => DisputeStatus::RESOLVED,
                    'completed_at' => now(),
                ]);
            }

            // Update Dispute record
            $lockedDispute->update([
                'status' => DisputeStatus::RESOLVED,
                'admin_verdict' => $verdict,
                'partial_refund_to_buyer' => $verdict === 'PARTIAL_REFUND' ? $partialRefundToBuyer : null,
                'resolution_note' => $cleanNote,
                'resolved_by_admin_id' => $admin->id,
                'resolved_at' => now(),
            ]);

            // Immutable Audit Log
            $this->auditLogService->record(
                $admin,
                'DISPUTE_RESOLVED',
                'disputes',
                $lockedDispute->id,
                $cleanNote,
                ['status' => $disputeStatus],
                [
                    'status' => 'RESOLVED',
                    'verdict' => $verdict,
                    'partial_refund_to_buyer' => $partialRefundToBuyer,
                ]
            );

            // Notify Buyer & Seller
            Notification::create([
                'user_id' => $lockedOrder->buyer_id,
                'type' => 'DISPUTE_RESOLVED',
                'title' => 'Khiếu nại đã có phán quyết từ Admin',
                'body' => "Khiếu nại cho đơn hàng #{$lockedOrder->order_code} đã được Admin phân xử: {$verdict}.",
                'target_type' => 'disputes',
                'target_id' => $lockedDispute->id,
                'deep_link_route' => "/buyer/disputes/{$lockedDispute->id}",
                'is_read' => false,
            ]);

            Notification::create([
                'user_id' => $lockedOrder->seller_id,
                'type' => 'DISPUTE_RESOLVED',
                'title' => 'Khiếu nại đã có phán quyết từ Admin',
                'body' => "Khiếu nại cho đơn hàng #{$lockedOrder->order_code} đã được Admin phân xử: {$verdict}.",
                'target_type' => 'disputes',
                'target_id' => $lockedDispute->id,
                'deep_link_route' => "/seller/disputes/{$lockedDispute->id}",
                'is_read' => false,
            ]);

            return $lockedDispute->fresh(['order', 'buyer.profile', 'seller.sellerProfile', 'evidences', 'resolvedByAdmin']);
        });
    }
}
