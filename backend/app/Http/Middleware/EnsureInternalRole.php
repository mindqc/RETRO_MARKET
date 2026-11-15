<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use App\Exceptions\RolePermissionDeniedException;
use Closure;
use Illuminate\Http\Request;

class EnsureInternalRole
{
    /**
     * Handle an incoming request.
     *
     * Verify that authenticated user has one of the required roles.
     */
    public function handle(Request $request, Closure $next, string ...$roles)
    {
        $user = $request->user();

        if (!$user) {
            throw new RolePermissionDeniedException('Yêu cầu xác thực tài khoản.');
        }

        $userRole = $user->role instanceof UserRole ? $user->role->value : (string) $user->role;

        if (!in_array($userRole, $roles, true)) {
            throw new RolePermissionDeniedException();
        }

        return $next($request);
    }
}
