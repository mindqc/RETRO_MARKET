<?php

namespace App\Services\Engagement;

use App\Enums\OrderStatus;
use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\RolePermissionDeniedException;
use App\Exceptions\SelfTransactionForbiddenException;
use App\Models\Notification;
use App\Models\Order;
use App\Models\Review;
use App\Models\SellerProfile;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class ReviewService
{
    /**
     * Create verified order review for a completed order (BR-RV-01, BR-AC-02).
     */
    public function createVerifiedOrderReview(
        User $buyer,
        Order $order,
        int $rating,
        string $comment
    ): Review {
        return DB::transaction(function () use ($buyer, $order, $rating, $comment) {
            $lockedOrder = Order::with('items')
                ->where('id', $order->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ((int) $lockedOrder->buyer_id !== $buyer->id) {
                throw new RolePermissionDeniedException('Chỉ người mua của đơn hàng này mới có thể viết đánh giá.');
            }

            if ($buyer->id === (int) $lockedOrder->seller_id) {
                throw new SelfTransactionForbiddenException('Không thể tự đánh giá đơn hàng của chính mình (BR-AC-02).');
            }

            $statusValue = $lockedOrder->order_status instanceof OrderStatus
                ? $lockedOrder->order_status->value
                : (string) $lockedOrder->order_status;

            if ($statusValue !== OrderStatus::COMPLETED->value) {
                throw new InvalidStateTransitionException('Chỉ có thể đánh giá sau khi đơn hàng đã hoàn tất (BR-RV-01).');
            }

            if (Review::where('order_id', $lockedOrder->id)->exists()) {
                throw new InvalidStateTransitionException('Đơn hàng này đã được đánh giá trước đó.');
            }

            $productId = $lockedOrder->items->first()?->product_id;

            $review = Review::create([
                'order_id' => $lockedOrder->id,
                'product_id' => $productId,
                'reviewer_id' => $buyer->id,
                'seller_id' => $lockedOrder->seller_id,
                'rating' => $rating,
                'comment' => trim($comment),
                'status' => 'VISIBLE',
            ]);

            // Re-calculate seller average rating and review count
            $sellerProfile = SellerProfile::where('user_id', $lockedOrder->seller_id)
                ->lockForUpdate()
                ->first();

            if ($sellerProfile) {
                $visibleReviews = Review::where('seller_id', $lockedOrder->seller_id)
                    ->where('status', 'VISIBLE');

                $count = $visibleReviews->count();
                $avg = $visibleReviews->avg('rating') ?? 0;

                $sellerProfile->update([
                    'review_count' => $count,
                    'average_rating' => round($avg, 2),
                ]);
            }

            // Notify seller of verified review
            Notification::create([
                'user_id' => $lockedOrder->seller_id,
                'type' => 'NEW_REVIEW_RECEIVED',
                'title' => 'Đánh giá mới từ người mua',
                'body' => "Đơn hàng #{$lockedOrder->order_code} vừa nhận được đánh giá {$rating} sao từ khách hàng.",
                'target_type' => 'REVIEW',
                'target_id' => $review->id,
                'deep_link_route' => "/orders/{$lockedOrder->id}",
                'is_read' => false,
            ]);

            return $review->load(['reviewer.profile', 'seller.sellerProfile', 'product.primaryImage']);
        });
    }
}
