<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'optional.sanctum' => \App\Http\Middleware\OptionalSanctumAuth::class,
            'active.user' => \App\Http\Middleware\EnsureUserIsActive::class,
            'role' => \App\Http\Middleware\EnsureInternalRole::class,
            'demo.only' => \App\Http\Middleware\EnsureDemoModeEnabled::class,
            'admin.auth' => \App\Http\Middleware\EnsureAdminAuthenticated::class,
            'admin.can' => \App\Http\Middleware\EnsureAdminPermission::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request, Throwable $e) => $request->is('api/*') || $request->expectsJson(),
        );

        $exceptions->render(function (\App\Exceptions\DomainException $e, Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return $e->render($request);
            }
        });

        $exceptions->render(function (\Illuminate\Validation\ValidationException $e, Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return \App\Support\ApiResponse::error(
                    'VALIDATION_ERROR',
                    'Dữ liệu gửi lên không hợp lệ.',
                    422,
                    $e->errors()
                );
            }
        });

        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return \App\Support\ApiResponse::error(
                    'UNAUTHENTICATED',
                    'Yêu cầu đăng nhập để tiếp tục.',
                    401
                );
            }
        });

        $exceptions->render(function (\Illuminate\Auth\Access\AuthorizationException $e, Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return \App\Support\ApiResponse::error(
                    'ROLE_PERMISSION_DENIED',
                    'Bạn không có quyền thực hiện thao tác này.',
                    403
                );
            }
        });

        $exceptions->render(function (\Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException $e, Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return \App\Support\ApiResponse::error(
                    'ROLE_PERMISSION_DENIED',
                    $e->getMessage() ?: 'Bạn không có quyền thực hiện thao tác này.',
                    403
                );
            }
        });

        $exceptions->render(function (\Illuminate\Database\Eloquent\ModelNotFoundException $e, Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return \App\Support\ApiResponse::error(
                    'RESOURCE_NOT_AVAILABLE',
                    'Tài nguyên yêu cầu không tồn tại hoặc không khả dụng.',
                    404
                );
            }
        });

        $exceptions->render(function (\Symfony\Component\HttpKernel\Exception\NotFoundHttpException $e, Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return \App\Support\ApiResponse::error(
                    'RESOURCE_NOT_AVAILABLE',
                    'Tài nguyên yêu cầu không tồn tại hoặc không khả dụng.',
                    404
                );
            }
        });

        $exceptions->render(function (\Illuminate\Http\Exceptions\ThrottleRequestsException $e, Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return \App\Support\ApiResponse::error(
                    'TOO_MANY_REQUESTS',
                    'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.',
                    429
                );
            }
        });

        $exceptions->render(function (\Symfony\Component\HttpKernel\Exception\TooManyRequestsHttpException $e, Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return \App\Support\ApiResponse::error(
                    'TOO_MANY_REQUESTS',
                    'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.',
                    429
                );
            }
        });
    })->create();
