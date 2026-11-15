<?php

namespace App\Services\Governance;

use App\Enums\ProductStatus;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\Notification;
use App\Models\Product;
use App\Models\ProductModerationLog;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ProductModerationService
{
    public function __construct(
        protected AuditLogService $auditLogService
    ) {}

    /**
     * Approve product listing by moderator or admin (DEC-05).
     *
     * @throws RolePermissionDeniedException
     */
    public function approveProduct(
        User $moderator,
        Product $product,
        string $verificationLevel = 'MODERATOR_REVIEWED',
        ?string $reason = null
    ): Product {
        if (! $moderator->isModerator() && ! $moderator->isAdmin()) {
            throw new RolePermissionDeniedException('Chỉ Kiểm duyệt viên hoặc Quản trị viên mới có quyền duyệt sản phẩm.');
        }

        return DB::transaction(function () use ($moderator, $product, $verificationLevel, $reason) {
            $oldStatus = $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status;

            $product->update([
                'status' => ProductStatus::APPROVED,
                'verification_level' => $verificationLevel,
                'rejection_reason' => null,
                'approved_at' => now(),
                'approved_by' => $moderator->id,
            ]);

            // Record immutable moderation log
            ProductModerationLog::create([
                'product_id' => $product->id,
                'moderator_id' => $moderator->id,
                'action' => 'APPROVED',
                'previous_status' => $oldStatus,
                'new_status' => 'APPROVED',
                'verification_level_assigned' => $verificationLevel,
                'reason' => $reason ?: 'Sản phẩm đã được kiểm duyệt đạt chuẩn chất lượng.',
            ]);

            // Record audit log
            $this->auditLogService->record(
                actor: $moderator,
                action: 'APPROVE_PRODUCT',
                targetType: 'products',
                targetId: $product->id,
                reason: $reason,
                oldValues: ['status' => $oldStatus],
                newValues: ['status' => 'APPROVED', 'verification_level' => $verificationLevel],
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );

            // Notify Seller
            Notification::create([
                'user_id' => $product->seller_id,
                'type' => 'PRODUCT_APPROVED',
                'title' => 'Bài đăng đã được duyệt',
                'body' => "Sản phẩm '{$product->title}' của bạn đã được duyệt và đang hiển thị công khai trên ứng dụng.",
                'target_type' => 'products',
                'target_id' => $product->id,
                'deep_link_route' => "/products/{$product->id}",
                'is_read' => false,
            ]);

            return $product->fresh();
        });
    }

    /**
     * Reject or hide product listing with mandatory reason (DEC-05 / BR-PR-04).
     *
     * @throws RolePermissionDeniedException
     * @throws ValidationException
     */
    public function rejectOrHideProduct(
        User $moderator,
        Product $product,
        string $action,
        string $reason
    ): Product {
        if (! $moderator->isModerator() && ! $moderator->isAdmin()) {
            throw new RolePermissionDeniedException('Chỉ Kiểm duyệt viên hoặc Quản trị viên mới có quyền kiểm duyệt sản phẩm.');
        }

        $cleanReason = trim($reason);
        if ($cleanReason === '') {
            throw ValidationException::withMessages([
                'reason' => ['Bắt buộc phải nhập lý do khi từ chối hoặc ẩn sản phẩm (DEC-05).'],
            ]);
        }

        $targetStatus = match (strtoupper($action)) {
            'REJECTED' => ProductStatus::REJECTED,
            'HIDDEN' => ProductStatus::HIDDEN,
            default => ProductStatus::REJECTED,
        };

        return DB::transaction(function () use ($moderator, $product, $targetStatus, $cleanReason) {
            $oldStatus = $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status;

            $product->update([
                'status' => $targetStatus,
                'rejection_reason' => $cleanReason,
            ]);

            // Record immutable moderation log
            ProductModerationLog::create([
                'product_id' => $product->id,
                'moderator_id' => $moderator->id,
                'action' => $targetStatus->value,
                'previous_status' => $oldStatus,
                'new_status' => $targetStatus->value,
                'reason' => $cleanReason,
            ]);

            // Record audit log
            $this->auditLogService->record(
                actor: $moderator,
                action: $targetStatus->value . '_PRODUCT',
                targetType: 'products',
                targetId: $product->id,
                reason: $cleanReason,
                oldValues: ['status' => $oldStatus],
                newValues: ['status' => $targetStatus->value, 'rejection_reason' => $cleanReason],
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );

            // Notify Seller
            Notification::create([
                'user_id' => $product->seller_id,
                'type' => 'PRODUCT_' . $targetStatus->value,
                'title' => ($targetStatus === ProductStatus::REJECTED ? 'Bài đăng bị từ chối duyệt' : 'Bài đăng bị tạm ẩn'),
                'body' => "Sản phẩm '{$product->title}' của bạn đã bị " . ($targetStatus === ProductStatus::REJECTED ? 'từ chối' : 'tạm ẩn') . " với lý do: {$cleanReason}. Bạn có thể chỉnh sửa và gửi duyệt lại.",
                'target_type' => 'products',
                'target_id' => $product->id,
                'deep_link_route' => "/seller/products/{$product->id}",
                'is_read' => false,
            ]);

            return $product->fresh();
        });
    }
}
