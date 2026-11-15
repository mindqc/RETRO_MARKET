<?php

namespace App\Http\Middleware;

use App\Exceptions\RolePermissionDeniedException;
use Closure;
use Illuminate\Http\Request;

class EnsureDemoModeEnabled
{
    /**
     * Handle an incoming request.
     *
     * Ensure system is in demo mode.
     */
    public function handle(Request $request, Closure $next)
    {
        if (!config('retromarket.demo_mode', false)) {
            throw new RolePermissionDeniedException('Tính năng này chỉ khả dụng khi hệ thống hoạt động ở chế độ Demo Mode.');
        }

        return $next($request);
    }
}
