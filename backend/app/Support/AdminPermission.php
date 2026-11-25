<?php

namespace App\Support;

use App\Enums\UserRole;
use App\Models\User;

class AdminPermission
{
    /**
     * Map of permissions to roles.
     * Admin possesses all permissions.
     */
    protected static array $moderatorPermissions = [
        'dashboard.view',
        'users.view',
        'users.verify_seller',
        'users.ban',
        'users.unban',
        'categories.view',
        'products.view',
        'products.approve',
        'products.reject',
        'products.hide',
        'auctions.view',
        'auctions.cancel',
        'reports.view',
        'reports.resolve',
        'reviews.view',
        'reviews.hide',
    ];

    protected static array $supportPermissions = [
        'dashboard.view',
        'users.view',
        'orders.view',
        'orders.support_update',
        'disputes.view',
        'disputes.arbitrate',
        'reports.view',
        'reports.resolve',
    ];

    /**
     * Check if a user has a specific admin permission.
     */
    public static function can(?User $user, string $permission): bool
    {
        if (!$user || !$user->isActive()) {
            return false;
        }

        if ($user->role === UserRole::ADMIN) {
            return true;
        }

        if ($user->role === UserRole::MODERATOR) {
            return in_array($permission, static::$moderatorPermissions, true);
        }

        if ($user->role === UserRole::SUPPORT) {
            return in_array($permission, static::$supportPermissions, true);
        }

        // registered_user or any other role has strictly zero admin permissions
        return false;
    }

    /**
     * Check if user has any of the given permissions.
     */
    public static function canAny(?User $user, array $permissions): bool
    {
        foreach ($permissions as $permission) {
            if (static::can($user, $permission)) {
                return true;
            }
        }
        return false;
    }
}
