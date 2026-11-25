<?php

namespace App\Services\Auction;

use App\Enums\AuctionStatus;
use App\Enums\DisputeStatus;
use App\Enums\EscrowStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\ProductStatus;
use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\RolePermissionDeniedException;
use App\Models\Auction;
use App\Models\AuctionSession;
use App\Models\Notification;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\User;
use App\Models\UserAddress;
use App\Services\Governance\AuditLogService;
use App\Services\Governance\PlatformConfigService;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AuctionLifecycleService
{
    public function __construct(
        protected PlatformConfigService $platformConfig,
        protected AuditLogService $auditLogService
    ) {}

    /**
     * Seller closes an auction early for the leading bidder (BR-AU-05 / AF-06 / M-AC-05).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function closeEarlyBySeller(User $seller, int $auctionId): array
    {
        return DB::transaction(function () use ($seller, $auctionId) {
            /** @var Auction $auction */
            $auction = Auction::with(['product.primaryImage'])
                ->where('id', $auctionId)
                ->lockForUpdate()
                ->firstOrFail();

            if ((int) $auction->seller_id !== (int) $seller->id) {
                throw new RolePermissionDeniedException('Bạn không phải chủ tiệm của phiên đấu giá này.');
            }

            $status = $auction->status instanceof AuctionStatus
                ? $auction->status->value
                : (string) $auction->status;

            // Rule BR-AU-05: Must be LIVE, not expired, have bids, and highest bid >= reserve_price (or starting_price)
            $isLive = ($status === 'LIVE' && now()->lt($auction->auction_ends_at));
            $hasBids = ((int) $auction->bid_count > 0 && $auction->leading_bidder_id !== null);
            $targetFloor = (float) ($auction->reserve_price ?? $auction->starting_price);
            $reserveMet = ((float) $auction->current_highest_bid >= $targetFloor);

            if (!$isLive || !$hasBids || !$reserveMet) {
                throw new InvalidStateTransitionException(
                    'Không thể chốt phiên sớm: Phiên phải đang LIVE, có ít nhất 1 lượt đặt giá và giá hiện tại phải đạt mức giá sàn/giá khởi điểm (BR-AU-05).'
                );
            }

            $auction->closed_early_by_seller = true;
            $auction->save();

            $result = $this->finalizeAuctionWithWinner($auction, $seller);

            $this->auditLogService->record(
                $seller,
                'AUCTION_CLOSED_EARLY',
                'auctions',
                $auction->id,
                'Chủ sản phẩm chốt phiên đấu giá sớm cho người dẫn đầu hợp lệ (BR-AU-05).',
                null,
                [
                    'winner_id' => $auction->winner_id,
                    'winning_price' => $auction->current_highest_bid,
                    'order_id' => $result['order']->id,
                ]
            );

            return $result;
        });
    }

    /**
     * Finalize an auction when a valid winner is determined (Idempotent order & payment generation).
     */
    public function finalizeAuctionWithWinner(Auction $auction, ?User $actor = null): array
    {
        return DB::transaction(function () use ($auction) {
            // Idempotency: Return existing order if already generated
            $existingOrder = Order::where('auction_id', $auction->id)->first();
            if ($existingOrder) {
                return [
                    'auction' => $auction,
                    'order' => $existingOrder,
                ];
            }

            $winnerId = $auction->leading_bidder_id;

            // 1. Mark Auction as COMPLETED
            $auction->status = AuctionStatus::COMPLETED;
            $auction->winner_id = $winnerId;
            $auction->closed_at = now();
            $auction->save();

            // 2. Mark Product as SOLD
            if ($auction->product) {
                $auction->product->update([
                    'status' => ProductStatus::SOLD,
                    'available_quantity' => 0,
                ]);
            }

            // 3. Calculate Buyer Protection Fee (DEC-04)
            $feeCalc = $this->platformConfig->calculateBuyerProtectionFee($auction->current_highest_bid);

            // 4. Resolve shipping address snapshot (OQ-P6-02)
            $winnerAddress = UserAddress::where('user_id', $winnerId)
                ->orderByDesc('is_default')
                ->orderByDesc('id')
                ->first();

            $addressSnapshot = $winnerAddress ? [
                'recipient_name' => $winnerAddress->recipient_name,
                'phone' => $winnerAddress->recipient_phone,
                'province_city' => $winnerAddress->province_city,
                'district_ward' => $winnerAddress->district_ward,
                'street_address' => $winnerAddress->street_address,
            ] : [
                'recipient_name' => $auction->winner?->display_name ?? 'Người thắng đấu giá',
                'phone' => '0900000000',
                'province_city' => 'Chưa cập nhật',
                'district_ward' => 'Chưa cập nhật',
                'street_address' => 'Địa chỉ sẽ được cập nhật khi thanh toán',
            ];

            // 5. Calculate payment deadline (BR-AU-07: 30 minutes in Production, 2 minutes in Demo Mode)
            $paymentExpiresAt = now()->addMinutes($this->platformConfig->auctionWinnerPaymentDeadlineMinutes());

            // 6. Create Order
            $order = Order::create([
                'order_code' => 'ORD-AUC-' . strtoupper(Str::random(8)),
                'buyer_id' => $winnerId,
                'seller_id' => $auction->seller_id,
                'order_source' => 'AUCTION',
                'auction_id' => $auction->id,
                'item_subtotal' => $feeCalc['item_subtotal'],
                'shipping_fee' => 0.00,
                'protection_fee_rate_applied' => $feeCalc['protection_fee_rate'],
                'protection_fixed_fee_applied' => $feeCalc['protection_fixed_fee'],
                'buyer_protection_fee' => $feeCalc['buyer_protection_fee'],
                'total_amount' => $feeCalc['total_amount'],
                'seller_net_amount' => $feeCalc['seller_net_amount'],
                'shipping_address_snapshot' => $addressSnapshot,
                'order_status' => OrderStatus::PENDING_PAYMENT,
                'payment_status' => PaymentStatus::UNPAID,
                'escrow_status' => EscrowStatus::NONE,
                'dispute_status' => DisputeStatus::NONE,
                'payment_expires_at' => $paymentExpiresAt,
            ]);

            // 7. Create OrderItem snapshot
            $product = $auction->product;
            $conditionVal = $product?->condition instanceof \BackedEnum
                ? $product->condition->value
                : (string) ($product?->condition ?? 'GOOD');

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => $auction->product_id,
                'product_code_snapshot' => $product?->product_code ?? 'PRD-AUC',
                'product_title_snapshot' => $product?->title ?? 'Sản phẩm thắng đấu giá',
                'unit_price_snapshot' => $auction->current_highest_bid,
                'quantity' => 1,
                'line_total' => $auction->current_highest_bid,
                'condition_snapshot' => $conditionVal,
                'defect_info_snapshot' => $product?->defect_info ?? 'Không có lỗi',
                'primary_image_snapshot' => $product?->primaryImage?->image_url ?? 'https://izithrift.local/storage/placeholder.jpg',
            ]);

            // 8. Create mock Payment record
            Payment::create([
                'payment_reference' => 'REF-AUC-' . strtoupper(Str::random(10)),
                'order_id' => $order->id,
                'payer_id' => $winnerId,
                'amount' => $order->total_amount,
                'qr_payload' => 'vietqr://' . $order->order_code,
                'status' => PaymentStatus::PENDING,
                'expires_at' => $paymentExpiresAt,
            ]);

            // 9. Send notifications
            Notification::create([
                'user_id' => $winnerId,
                'type' => 'AUCTION_WON',
                'title' => 'Chúc mừng! Bạn đã thắng phiên đấu giá',
                'body' => "Bạn đã thắng phiên #{$auction->auction_code} với mức giá " . number_format((float) $auction->current_highest_bid, 0, ',', '.') . "đ. Vui lòng hoàn tất thanh toán trước khi hết hạn.",
                'target_type' => 'orders',
                'target_id' => $order->id,
                'deep_link_route' => "/buyer/orders/{$order->id}",
                'is_read' => false,
            ]);

            Notification::create([
                'user_id' => $auction->seller_id,
                'type' => 'AUCTION_COMPLETED',
                'title' => 'Phiên đấu giá của bạn đã có người thắng',
                'body' => "Phiên đấu giá #{$auction->auction_code} đã hoàn tất với mức giá " . number_format((float) $auction->current_highest_bid, 0, ',', '.') . "đ. Đơn hàng đang chờ người mua thanh toán.",
                'target_type' => 'orders',
                'target_id' => $order->id,
                'deep_link_route' => "/seller/orders/{$order->id}",
                'is_read' => false,
            ]);

            return [
                'auction' => $auction->fresh(),
                'order' => $order->fresh(['items', 'payments']),
            ];
        });
    }

    /**
     * Seller relists an auction product after ENDED_UNSOLD or WINNER_DEFAULTED (DEC-02 / AF-09).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function relistAuctionProduct(User $seller, Product $product, array $data): Auction
    {
        return DB::transaction(function () use ($seller, $product, $data) {
            /** @var Product $lockedProduct */
            $lockedProduct = Product::where('id', $product->id)->lockForUpdate()->firstOrFail();

            if ((int) $lockedProduct->seller_id !== (int) $seller->id) {
                throw new RolePermissionDeniedException('Bạn không phải chủ sở hữu của sản phẩm này.');
            }

            $listingType = (string) $lockedProduct->listing_type;

            if ($listingType !== 'AUCTION') {
                throw new InvalidStateTransitionException('Chỉ có thể tạo phiên đấu giá cho sản phẩm loại AUCTION.');
            }

            // Check if there is an active/scheduled auction for this product (uq_auctions_active_product guard)
            $activeExists = Auction::where('product_id', $lockedProduct->id)
                ->whereIn('status', [AuctionStatus::SCHEDULED, AuctionStatus::LIVE])
                ->exists();

            if ($activeExists) {
                throw new InvalidStateTransitionException(
                    'Sản phẩm này đang có một phiên đấu giá đang diễn ra hoặc đã lên lịch (DEC-02).'
                );
            }

            // Verify previous auction ended unsuccessfully
            $latestAuction = Auction::where('product_id', $lockedProduct->id)->orderByDesc('id')->first();
            if ($latestAuction) {
                $latestStatus = $latestAuction->status instanceof AuctionStatus
                    ? $latestAuction->status->value
                    : (string) $latestAuction->status;

                if (!in_array($latestStatus, ['ENDED_UNSOLD', 'WINNER_DEFAULTED', 'CANCELLED'], true)) {
                    throw new InvalidStateTransitionException(
                        'Chỉ có thể đăng lại đấu giá sau khi phiên trước đó kết thúc không người mua (ENDED_UNSOLD), người thắng bỏ cọc (WINNER_DEFAULTED) hoặc đã hủy (DEC-02).'
                    );
                }
            }

            // Target session
            if (!empty($data['session_id'])) {
                $session = AuctionSession::findOrFail($data['session_id']);
            } else {
                $session = AuctionSession::where('status', 'ACTIVE')->latest('id')->first()
                    ?? AuctionSession::latest('id')->first();
            }

            $startingPrice = round((float) $data['starting_price'], 2);

            // Restore Product status
            $lockedProduct->update([
                'status' => ProductStatus::APPROVED,
                'available_quantity' => 1,
                'total_quantity' => 1,
                'price' => $startingPrice,
            ]);

            // Determine schedule
            $startsAt = !empty($data['auction_starts_at'])
                ? Carbon::parse($data['auction_starts_at'])
                : ($session?->starts_at ?? now());

            $endsAt = !empty($data['auction_ends_at'])
                ? Carbon::parse($data['auction_ends_at'])
                : ($session?->ends_at ?? now()->addHours(24));

            $newStatus = (now()->gte($startsAt) && now()->lt($endsAt))
                ? AuctionStatus::LIVE
                : AuctionStatus::SCHEDULED;

            $minIncrement = !empty($data['min_bid_increment'])
                ? round((float) $data['min_bid_increment'], 2)
                : ((float) ($session?->default_min_increment ?? 10000.00));

            $reservePrice = !empty($data['reserve_price'])
                ? round((float) $data['reserve_price'], 2)
                : null;

            $newAuction = Auction::create([
                'auction_code' => 'AUC-' . date('Y') . '-' . strtoupper(Str::random(6)),
                'product_id' => $lockedProduct->id,
                'seller_id' => $seller->id,
                'session_id' => $session?->id,
                'starting_price' => $startingPrice,
                'min_bid_increment' => $minIncrement,
                'reserve_price' => $reservePrice,
                'current_highest_bid' => 0.00,
                'bid_count' => 0,
                'watch_count' => 0,
                'status' => $newStatus,
                'auction_starts_at' => $startsAt,
                'auction_ends_at' => $endsAt,
            ]);

            $this->auditLogService->record(
                $seller,
                'AUCTION_RELISTED',
                'auctions',
                $newAuction->id,
                'Đăng lại sản phẩm sau khi phiên trước kết thúc không thành công (DEC-02).',
                null,
                [
                    'auction_id' => $newAuction->id,
                    'product_id' => $lockedProduct->id,
                    'starting_price' => $startingPrice,
                ]
            );

            return $newAuction->fresh(['product.primaryImage', 'session', 'seller.sellerProfile']);
        });
    }

    /**
     * Batch process scheduled auctions that have reached auction_starts_at (FOR UPDATE SKIP LOCKED).
     */
    public function openDueScheduledAuctions(?User $triggeredBy = null): array
    {
        $dueAuctionIds = Auction::where('status', AuctionStatus::SCHEDULED)
            ->where('auction_starts_at', '<=', now())
            ->pluck('id')
            ->toArray();

        $openedIds = [];

        foreach ($dueAuctionIds as $id) {
            DB::transaction(function () use ($id, &$openedIds) {
                /** @var Auction|null $auction */
                $auction = Auction::with('product')
                    ->where('id', $id)
                    ->lock('FOR UPDATE SKIP LOCKED')
                    ->first();

                if (!$auction) {
                    return;
                }

                $status = $auction->status instanceof AuctionStatus
                    ? $auction->status->value
                    : (string) $auction->status;

                if ($status !== 'SCHEDULED' || $auction->auction_starts_at->gt(now())) {
                    return;
                }

                $productStatus = $auction->product?->status instanceof ProductStatus
                    ? $auction->product->status->value
                    : (string) ($auction->product?->status ?? '');

                if ($productStatus !== 'APPROVED') {
                    return;
                }

                $auction->update(['status' => AuctionStatus::LIVE]);
                $openedIds[] = $auction->id;

                // Notify all watchers
                $watcherIds = DB::table('auction_watches')
                    ->where('auction_id', $auction->id)
                    ->pluck('user_id');

                foreach ($watcherIds as $watcherId) {
                    Notification::create([
                        'user_id' => $watcherId,
                        'type' => 'AUCTION_STARTED',
                        'title' => 'Phiên đấu giá đã bắt đầu!',
                        'body' => "Phiên đấu giá #{$auction->auction_code} cho sản phẩm '{$auction->product->title}' vừa chính thức mở thầu.",
                        'target_type' => 'auctions',
                        'target_id' => $auction->id,
                        'deep_link_route' => "/auctions/{$auction->id}",
                        'is_read' => false,
                    ]);
                }
            });
        }

        return [
            'opened_count' => count($openedIds),
            'opened_auction_ids' => $openedIds,
        ];
    }

    /**
     * Batch close live auctions that have reached auction_ends_at (FOR UPDATE SKIP LOCKED).
     */
    public function closeExpiredLiveAuctions(?User $triggeredBy = null): array
    {
        $expiredAuctionIds = Auction::where('status', AuctionStatus::LIVE)
            ->where('auction_ends_at', '<=', now())
            ->pluck('id')
            ->toArray();

        $completedIds = [];
        $unsoldIds = [];

        foreach ($expiredAuctionIds as $id) {
            DB::transaction(function () use ($id, $triggeredBy, &$completedIds, &$unsoldIds) {
                /** @var Auction|null $auction */
                $auction = Auction::with(['product.primaryImage', 'winner', 'seller'])
                    ->where('id', $id)
                    ->lock('FOR UPDATE SKIP LOCKED')
                    ->first();

                if (!$auction) {
                    return;
                }

                $status = $auction->status instanceof AuctionStatus
                    ? $auction->status->value
                    : (string) $auction->status;

                if ($status !== 'LIVE' || $auction->auction_ends_at->gt(now())) {
                    return;
                }

                $hasWinner = ((int) $auction->bid_count > 0
                    && $auction->leading_bidder_id !== null
                    && (float) $auction->current_highest_bid >= (float) ($auction->reserve_price ?? $auction->starting_price));

                if ($hasWinner) {
                    $this->finalizeAuctionWithWinner($auction, $triggeredBy);
                    $completedIds[] = $auction->id;
                } else {
                    $auction->update([
                        'status' => AuctionStatus::ENDED_UNSOLD,
                        'closed_at' => now(),
                    ]);

                    if ($auction->product) {
                        $auction->product->update([
                            'status' => ProductStatus::APPROVED,
                            'available_quantity' => 1,
                        ]);
                    }

                    $unsoldIds[] = $auction->id;

                    Notification::create([
                        'user_id' => $auction->seller_id,
                        'type' => 'AUCTION_ENDED_UNSOLD',
                        'title' => 'Phiên đấu giá đã kết thúc',
                        'body' => "Phiên đấu giá #{$auction->auction_code} đã kết thúc nhưng không có người thắng hợp lệ. Bạn có thể đăng lại sản phẩm này.",
                        'target_type' => 'auctions',
                        'target_id' => $auction->id,
                        'deep_link_route' => "/seller/products/{$auction->product_id}",
                        'is_read' => false,
                    ]);
                }
            });
        }

        return [
            'completed_count' => count($completedIds),
            'unsold_count' => count($unsoldIds),
            'completed_auction_ids' => $completedIds,
            'unsold_auction_ids' => $unsoldIds,
        ];
    }

    /**
     * Administrative Anti-Fraud Cancel for LIVE or SCHEDULED auction (PERM-AC-09).
     *
     * @throws RolePermissionDeniedException
     * @throws InvalidStateTransitionException
     */
    public function cancelAuctionByAdmin(User $admin, int $auctionId, string $reason): Auction
    {
        if (! $admin->isAdmin() && ! $admin->isModerator()) {
            throw new RolePermissionDeniedException('Chỉ Quản trị viên hoặc Kiểm duyệt viên mới có quyền hủy phiên đấu giá.');
        }

        return DB::transaction(function () use ($admin, $auctionId, $reason) {
            /** @var Auction $auction */
            $auction = Auction::with(['product'])
                ->where('id', $auctionId)
                ->lockForUpdate()
                ->firstOrFail();

            if (! in_array($auction->status, [AuctionStatus::SCHEDULED, AuctionStatus::LIVE], true)) {
                throw new InvalidStateTransitionException('Chỉ có thể hủy phiên đấu giá đang diễn ra (LIVE) hoặc sắp mở (SCHEDULED).');
            }

            $oldStatus = $auction->status->value;

            $auction->update([
                'status' => AuctionStatus::CANCELLED,
                'cancel_reason' => $reason,
                'closed_at' => now(),
            ]);

            // Restore product to APPROVED so it's not permanently stuck
            if ($auction->product) {
                $auction->product->update([
                    'status' => ProductStatus::APPROVED,
                    'available_quantity' => 1,
                ]);
            }

            // Record immutable audit log
            $this->auditLogService->record(
                actor: $admin,
                action: 'AUCTION_CANCELLED',
                targetType: 'auctions',
                targetId: $auction->id,
                reason: $reason,
                oldValues: ['status' => $oldStatus],
                newValues: ['status' => 'CANCELLED', 'closed_at' => now()->toIso8601String()],
                ipAddress: request()?->ip() ?? '127.0.0.1'
            );

            // Notify Seller
            Notification::create([
                'user_id' => $auction->seller_id,
                'type' => 'AUCTION_CANCELLED',
                'title' => 'Phiên đấu giá bị hủy bởi quản trị',
                'body' => "Phiên đấu giá #{$auction->auction_code} đã bị quản trị viên hủy với lý do: {$reason}.",
                'target_type' => 'auctions',
                'target_id' => $auction->id,
                'deep_link_route' => "/seller/products/{$auction->product_id}",
                'is_read' => false,
            ]);

            return $auction->fresh();
        });
    }
}
