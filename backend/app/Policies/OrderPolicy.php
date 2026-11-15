<?php

namespace App\Policies;

use App\Models\Order;
use App\Models\User;

class OrderPolicy
{
    /**
     * Determine whether the user can view the order.
     */
    public function view(User $user, Order $order): bool
    {
        return $user->id === $order->buyer_id
            || $user->id === $order->seller_id
            || $user->isAdmin()
            || $user->isSupport();
    }

    /**
     * Determine whether the user can manage fulfillment (ship, update tracking).
     */
    public function manageFulfillment(User $user, Order $order): bool
    {
        return $user->id === $order->seller_id;
    }

    /**
     * Determine whether the user can confirm delivery (buyer only).
     */
    public function confirmDelivery(User $user, Order $order): bool
    {
        return $user->id === $order->buyer_id;
    }
}
