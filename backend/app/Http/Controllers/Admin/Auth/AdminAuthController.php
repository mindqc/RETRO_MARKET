<?php

namespace App\Http\Controllers\Admin\Auth;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class AdminAuthController extends Controller
{
    /**
     * Show the admin login form (Screen A-AU-01).
     */
    public function showLoginForm(): View|RedirectResponse
    {
        if (Auth::guard('web')->check() && Auth::guard('web')->user()?->isInternalStaff()) {
            return redirect()->route('admin.dashboard');
        }

        return view('admin.auth.login');
    }

    /**
     * Handle an admin login request.
     */
    public function login(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ]);

        $throttleKey = Str::transliterate(Str::lower($credentials['email']) . '|' . $request->ip());

        if (RateLimiter::tooManyAttempts($throttleKey, 5)) {
            $seconds = RateLimiter::availableIn($throttleKey);
            throw ValidationException::withMessages([
                'email' => __('auth.throttle', [
                    'seconds' => $seconds,
                    'minutes' => ceil($seconds / 60),
                ]),
            ]);
        }

        if (!Auth::guard('web')->attempt(['email' => $credentials['email'], 'password' => $credentials['password']], $request->boolean('remember'))) {
            RateLimiter::hit($throttleKey, 60);

            throw ValidationException::withMessages([
                'email' => 'Thông tin đăng nhập không chính xác.',
            ]);
        }

        RateLimiter::clear($throttleKey);

        /** @var \App\Models\User $user */
        $user = Auth::guard('web')->user();

        // Enforce active status and internal staff role
        if (!$user->isActive() || !$user->isInternalStaff()) {
            Auth::guard('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            throw ValidationException::withMessages([
                'email' => 'Tài khoản không có quyền truy cập hoặc đã bị vô hiệu hóa.',
            ]);
        }

        // Session fixation protection
        $request->session()->regenerate();

        // Update last login timestamp
        $user->update(['last_login_at' => now()]);

        // Immutable Audit Log
        AuditLog::create([
            'actor_id' => $user->id,
            'actor_role' => $user->role->value,
            'action' => 'ADMIN_LOGIN',
            'target_type' => 'User',
            'target_id' => $user->id,
            'reason' => 'Successful admin authentication',
            'old_values' => null,
            'new_values' => [
                'ip' => $request->ip(),
                'user_agent' => substr((string) $request->userAgent(), 0, 255),
            ],
            'ip_address' => $request->ip(),
        ]);

        // Open redirect protection: strictly stay within /admin
        $intended = $request->session()->pull('url.intended', route('admin.dashboard'));
        $adminPrefix = url('/admin');

        if (!is_string($intended) || !str_starts_with($intended, $adminPrefix)) {
            $intended = route('admin.dashboard');
        }

        return redirect()->to($intended);
    }

    /**
     * Terminate the admin session.
     */
    public function logout(Request $request): RedirectResponse
    {
        $user = Auth::guard('web')->user();

        if ($user) {
            AuditLog::create([
                'actor_id' => $user->id,
                'actor_role' => $user->role->value,
                'action' => 'ADMIN_LOGOUT',
                'target_type' => 'User',
                'target_id' => $user->id,
                'reason' => 'Admin session terminated',
                'old_values' => null,
                'new_values' => [
                    'ip' => $request->ip(),
                ],
                'ip_address' => $request->ip(),
            ]);
        }

        Auth::guard('web')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login')->with('success', 'Đã đăng xuất thành công.');
    }
}
