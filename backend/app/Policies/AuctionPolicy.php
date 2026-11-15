<?php

namespace App\Policies;

use App\Enums\AuctionStatus;
use App\Exceptions\SelfTransactionForbiddenException;
use App\Models\Auction;
use App\Models\User;

class AuctionPolicy
{
    /**
     * Determine whether the user can place a bid on an auction.
     * Enforces anti-self-bidding rule (BR-AC-02 / BR-AU-02).
     *
     * @throws SelfTransactionForbiddenException
     */
    public function placeBid(User $user, Auction $auction): bool
    {
        if ($user->id === $auction->seller_id) {
            throw new SelfTransactionForbiddenException('Người bán không được phép tham gia đấu giá trên sản phẩm của chính mình (BR-AC-02 / BR-AU-02).');
        }

        $status = $auction->status instanceof AuctionStatus ? $auction->status->value : (string) $auction->status;

        return $user->isActive() && in_array($status, ['LIVE', 'ACTIVE'], true);
    }

    /**
     * Determine whether the user can close an auction early.
     */
    public function closeEarly(User $user, Auction $auction): bool
    {
        return $user->id === $auction->seller_id;
    }

    /**
     * Determine whether the user can cancel an auction as admin (PERM-AC-09).
     */
    public function cancelByAdmin(User $user, Auction $auction): bool
    {
        return $user->isAdmin();
    }
}
