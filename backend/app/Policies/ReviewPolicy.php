<?php

namespace App\Policies;

use App\Models\Order;
use App\Models\User;

class ReviewPolicy
{
    /**
     * Determine whether the user can write a review for an order.
     * Must be buyer and cannot review own products (BR-AC-02).
     */
    public function create(User $user, Order $order): bool
    {
        return $user->id === $order->buyer_id && $user->id !== $order->seller_id;
    }
}
