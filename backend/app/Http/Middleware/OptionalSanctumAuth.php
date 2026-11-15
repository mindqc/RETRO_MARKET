<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class OptionalSanctumAuth
{
    /**
     * Handle an incoming request.
     *
     * If request contains a Bearer token, attempt to authenticate via Sanctum guard.
     * If valid, set the authenticated user on the request.
     */
    public function handle(Request $request, Closure $next)
    {
        if ($request->bearerToken()) {
            $guard = Auth::guard('sanctum');
            if (method_exists($guard, 'forgetUser')) {
                $guard->forgetUser();
            }
            if (method_exists($guard, 'setRequest')) {
                $guard->setRequest($request);
            }

            // Also reset web session guard cache in case of testing state leakage
            if (method_exists(Auth::guard('web'), 'forgetUser')) {
                Auth::guard('web')->forgetUser();
            }

            $user = $guard->user();

            if ($user) {
                $request->setUserResolver(fn ($g = null) => $user);
            }
        }

        return $next($request);
    }
}
