<?php

namespace App\Services\Auction;

use App\Enums\AuctionStatus;
use App\Exceptions\AuctionOutbidConflictException;
use App\Exceptions\InvalidStateTransitionException;
use App\Exceptions\SelfTransactionForbiddenException;
use App\Models\Auction;
use App\Models\AuctionBid;
use App\Models\AuctionWatch;
use App\Models\Notification;
use App\Models\User;
use App\Services\Governance\PlatformConfigService;
use Illuminate\Support\Facades\DB;

class AuctionBiddingService
{
    public function __construct(
        protected PlatformConfigService $platformConfig
    ) {}

    /**
     * Place a concurrent bid on an active auction with pessimistic row-locking (BR-AU-03 / AF-04).
     *
     * @throws SelfTransactionForbiddenException
     * @throws InvalidStateTransitionException
     * @throws AuctionOutbidConflictException
     */
    public function placeBid(User $bidder, int $auctionId, float|string $bidAmount): array
    {
        return DB::transaction(function () use ($bidder, $auctionId, $bidAmount) {
            /** @var Auction $auction */
            $auction = Auction::with('product')
                ->where('id', $auctionId)
                ->lockForUpdate()
                ->firstOrFail();

            // 1. Anti-self-bidding rule (BR-AC-02 / BR-AU-02)
            if ((int) $bidder->id === (int) $auction->seller_id) {
                throw new SelfTransactionForbiddenException(
                    'Người bán không được phép tham gia đấu giá trên sản phẩm của chính mình (BR-AC-02 / BR-AU-02).'
                );
            }

            // 2. Real-time server state & clock verification (BR-AU-01)
            $status = $auction->status instanceof AuctionStatus
                ? $auction->status->value
                : (string) $auction->status;

            if ($status !== 'LIVE' || now()->lt($auction->auction_starts_at) || now()->gte($auction->auction_ends_at)) {
                throw new InvalidStateTransitionException(
                    'Phiên đấu giá chưa mở hoặc đã kết thúc theo thời gian máy chủ (BR-AU-01).'
                );
            }

            // 3. Minimum bid increment check & 409 Conflict handling (BR-AU-02 / AF-04)
            $parsedBidAmount = round((float) $bidAmount, 2);
            $minNextBid = (float) $auction->minimumNextBidAmount();

            if ($parsedBidAmount < $minNextBid) {
                throw new AuctionOutbidConflictException(
                    'Mức giá đặt (' . number_format($parsedBidAmount, 0, ',', '.') . 'đ) phải lớn hơn hoặc bằng mức giá hợp lệ tiếp theo (' . number_format($minNextBid, 0, ',', '.') . 'đ).',
                    [
                        'auction_id' => $auction->id,
                        'current_highest_bid' => number_format((float) $auction->current_highest_bid, 2, '.', ''),
                        'minimum_next_bid' => number_format($minNextBid, 2, '.', ''),
                        'leading_bidder_id' => $auction->leading_bidder_id,
                        'bid_count' => (int) $auction->bid_count,
                        'auction_ends_at' => $auction->auction_ends_at->toIso8601String(),
                        'extended_count' => (int) $auction->extended_count,
                    ]
                );
            }

            // 4. Anti-Sniping detection & extension (BR-AU-04 / ADR-05)
            $windowSeconds = $this->platformConfig->antiSnipingWindowSeconds();
            $extensionSeconds = $this->platformConfig->antiSnipingExtensionSeconds();
            $secondsRemaining = now()->diffInSeconds($auction->auction_ends_at, false);
            $triggeredAntiSniping = false;

            if ($secondsRemaining >= 0 && $secondsRemaining <= $windowSeconds) {
                $auction->auction_ends_at = $auction->auction_ends_at->copy()->addSeconds($extensionSeconds);
                $auction->extended_count = (int) $auction->extended_count + 1;
                $auction->last_extended_at = now();
                $triggeredAntiSniping = true;
            }

            // 5. Record immutable AuctionBid
            $previousLeaderId = $auction->leading_bidder_id;
            $previousHighest = (float) $auction->current_highest_bid;

            $bid = AuctionBid::create([
                'auction_id' => $auction->id,
                'bidder_id' => $bidder->id,
                'bid_amount' => $parsedBidAmount,
                'previous_highest_bid' => $previousHighest,
                'triggered_anti_sniping' => $triggeredAntiSniping,
            ]);

            // 6. Update Auction leading state
            $auction->current_highest_bid = $parsedBidAmount;
            $auction->leading_bidder_id = $bidder->id;
            $auction->bid_count = (int) $auction->bid_count + 1;
            $auction->save();

            // 7. Auto-watch auction for the bidder
            AuctionWatch::firstOrCreate([
                'auction_id' => $auction->id,
                'user_id' => $bidder->id,
            ]);
            $watchCount = AuctionWatch::where('auction_id', $auction->id)->count();
            $auction->update(['watch_count' => $watchCount]);

            // 8. Notify previous leading bidder (AF-05)
            if ($previousLeaderId !== null && (int) $previousLeaderId !== (int) $bidder->id) {
                Notification::create([
                    'user_id' => $previousLeaderId,
                    'type' => 'AUCTION_OUTBID',
                    'title' => 'Bạn đã bị vượt giá đấu',
                    'body' => "Giá đấu của bạn trên phiên #{$auction->auction_code} ({$auction->product?->title}) đã bị vượt qua. Mức giá cao nhất hiện tại là " . number_format($parsedBidAmount, 0, ',', '.') . "đ.",
                    'target_type' => 'AUCTION',
                    'target_id' => $auction->id,
                    'deep_link_route' => "/auctions/{$auction->id}",
                    'is_read' => false,
                ]);
            }

            return [
                'auction' => $auction->fresh(['leadingBidder.profile', 'session']),
                'bid' => $bid,
                'triggered_anti_sniping' => $triggeredAntiSniping,
            ];
        });
    }
}
