<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\ForgotPasswordRequest;
use App\Http\Requests\Api\V1\Auth\LoginRequest;
use App\Http\Requests\Api\V1\Auth\RegisterRequest;
use App\Http\Requests\Api\V1\Auth\ResetPasswordRequest;
use App\Http\Resources\Api\V1\AuthUserResource;
use App\Services\Auth\AuthService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(
        protected AuthService $authService
    ) {}

    /**
     * Register a new user with dual profiles and initial cart (BR-AC-01).
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $result = $this->authService->register($request->validated());

        return ApiResponse::created([
            'user' => new AuthUserResource($result['user']),
            'token' => $result['token'],
        ], 'Đăng ký tài khoản thành công.');
    }

    /**
     * Authenticate user credentials and return access token.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->authService->login(
            $request->input('email'),
            $request->input('password'),
            $request->input('device_name', 'flutter_mobile')
        );

        return ApiResponse::success([
            'user' => new AuthUserResource($result['user']),
            'token' => $result['token'],
        ], 'Đăng nhập thành công.');
    }

    /**
     * Revoke current access token.
     */
    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout($request->user());

        return ApiResponse::success(null, 'Đăng xuất thành công. Phiên làm việc đã kết thúc.');
    }

    /**
     * Issue password reset token.
     */
    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $result = $this->authService->sendResetToken($request->input('email'));

        return ApiResponse::success([
            'email' => $result['email'],
            'reset_token' => $result['token'],
        ], 'Mã khôi phục mật khẩu đã được khởi tạo thành công.');
    }

    /**
     * Reset user password using token.
     */
    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $this->authService->resetPassword(
            $request->input('email'),
            $request->input('token'),
            $request->input('password')
        );

        return ApiResponse::success(null, 'Đặt lại mật khẩu thành công. Vui lòng đăng nhập với mật khẩu mới.');
    }
}
