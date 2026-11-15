<?php

namespace App\Http\Middleware;

use App\Enums\UserStatus;
use App\Exceptions\AccountSuspendedException;
use Closure;
use Illuminate\Http\Request;

class EnsureUserIsActive
{
    /**
     * Handle an incoming request.
     *
     * Check if authenticated user is ACTIVE. If SUSPENDED or BANNED, revoke token and throw 403.
     */
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        if ($user) {
            $status = $user->status instanceof UserStatus ? $user->status->value : (string) $user->status;
            if ($status !== 'ACTIVE' && $status !== UserStatus::ACTIVE->value) {
                $user->currentAccessToken()?->delete();
                throw new AccountSuspendedException();
            }
        }

        return $next($request);
    }
}
