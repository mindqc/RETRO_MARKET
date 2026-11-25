<?php

namespace App\Http\Middleware;

use App\Support\AdminPermission;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdminPermission
{
    /**
     * Handle an incoming request checking for specific admin permission.
     */
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $user = Auth::guard('web')->user();

        if (!$user || !AdminPermission::can($user, $permission)) {
            abort(403, 'Truy cập bị từ chối. Bạn không có quyền hạn cho phân hệ này.');
        }

        return $next($request);
    }
}
