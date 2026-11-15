<?php

namespace App\Policies;

use App\Enums\ProductStatus;
use App\Models\Product;
use App\Models\User;

class ProductPolicy
{
    /**
     * Determine whether the user can create products.
     */
    public function create(User $user): bool
    {
        return $user->isActive();
    }

    /**
     * Determine whether the user can update the product.
     * Only seller can update their product if it's in DRAFT or REJECTED status (or admin).
     */
    public function update(User $user, Product $product): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        $status = $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status;

        return $user->id === $product->seller_id && in_array($status, ['DRAFT', 'REJECTED'], true);
    }

    /**
     * Determine whether the user can delete a draft product.
     */
    public function deleteDraft(User $user, Product $product): bool
    {
        $status = $product->status instanceof ProductStatus ? $product->status->value : (string) $product->status;

        return $user->id === $product->seller_id && $status === 'DRAFT';
    }

    /**
     * Determine whether the user can moderate products.
     */
    public function moderate(User $user): bool
    {
        return $user->isAdmin() || $user->isModerator();
    }
}
