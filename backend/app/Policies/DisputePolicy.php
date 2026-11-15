<?php

namespace App\Policies;

use App\Models\Dispute;
use App\Models\Order;
use App\Models\User;

class DisputePolicy
{
    /**
     * Determine whether the user can open a dispute on an order.
     */
    public function open(User $user, Order $order): bool
    {
        return $user->id === $order->buyer_id;
    }

    /**
     * Determine whether the user can request more information (PERM-CM-08).
     * Admin and Support staff can request evidence.
     */
    public function requestMoreInfo(User $user, Dispute $dispute): bool
    {
        return $user->isAdmin() || $user->isSupport();
    }

    /**
     * Determine whether the user can resolve verdict on a dispute (PERM-CM-09).
     * Financial dispute resolution is strictly restricted to ADMIN ONLY.
     * Support and Moderator roles are strictly forbidden.
     */
    public function resolveVerdict(User $user, Dispute $dispute): bool
    {
        return $user->isAdmin();
    }
}
