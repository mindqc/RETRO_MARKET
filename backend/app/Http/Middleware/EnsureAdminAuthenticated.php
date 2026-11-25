<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdminAuthenticated
{
    /**
     * Handle an incoming web admin request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (!Auth::guard('web')->check()) {
            if ($request->expectsJson()) {
                abort(401, 'Unauthenticated.');
            }
            return redirect()->guest(route('admin.login'))->withErrors([
                'email' => 'Vui lòng đăng nhập để tiếp tục.',
            ]);
        }

        $user = Auth::guard('web')->user()->fresh();

        // Mid-session suspension or status invalidation check
        if (!$user || !$user->isActive()) {
            Auth::guard('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            if ($request->expectsJson()) {
                abort(403, 'Tài khoản quản trị đã bị tạm đình chỉ hoặc vô hiệu hóa.');
            }

            return redirect()->route('admin.login')->withErrors([
                'email' => 'Tài khoản quản trị đã bị tạm đình chỉ hoặc vô hiệu hóa.',
            ]);
        }

        // Default Deny for non-internal users (e.g. registered_user)
        if (!$user->isInternalStaff()) {
            Auth::guard('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            abort(403, 'Truy cập bị từ chối. Chỉ nhân sự nội bộ mới có quyền truy cập trang quản trị.');
        }

        return $next($request);
    }
}
