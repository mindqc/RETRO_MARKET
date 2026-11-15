<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Profile\ChangePasswordRequest;
use App\Http\Requests\Api\V1\Profile\UpdateProfileRequest;
use App\Http\Requests\Api\V1\Profile\UpdateSettingsRequest;
use App\Http\Resources\Api\V1\AuthUserResource;
use App\Services\User\ProfileService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function __construct(
        protected ProfileService $profileService
    ) {}

    /**
     * Get unified account profile summary with order status counters (M-PF-01).
     */
    public function show(Request $request): JsonResponse
    {
        $summary = $this->profileService->getMyProfileSummary($request->user());

        return ApiResponse::success([
            'user' => new AuthUserResource($summary['user']),
            'order_status_counts' => $summary['order_status_counts'],
            'favorites_count' => $summary['favorites_count'],
            'following_count' => $summary['following_count'],
        ], 'Lấy thông tin hồ sơ thành công.');
    }

    /**
     * Update profile details and optional avatar upload (M-PF-02).
     */
    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $user = $this->profileService->updateProfile(
            $request->user(),
            $request->validated(),
            $request->file('avatar')
        );

        return ApiResponse::success(
            new AuthUserResource($user),
            'Cập nhật thông tin hồ sơ thành công.'
        );
    }

    /**
     * Toggle seasonal holiday decor settings (NFR-UX-02).
     */
    public function updateSettings(UpdateSettingsRequest $request): JsonResponse
    {
        $profile = $this->profileService->updateSettings(
            $request->user(),
            (bool) $request->input('seasonal_decor_enabled')
        );

        return ApiResponse::success([
            'seasonal_decor_enabled' => (bool) $profile->seasonal_decor_enabled,
        ], 'Cập nhật tùy chọn hiển thị thành công.');
    }

    /**
     * Change password and revoke other tokens (NFR-SEC-01).
     */
    public function changePassword(ChangePasswordRequest $request): JsonResponse
    {
        $this->profileService->changePassword(
            $request->user(),
            $request->input('current_password'),
            $request->input('password')
        );

        return ApiResponse::success(null, 'Đổi mật khẩu thành công. Các phiên đăng nhập khác đã được thu hồi.');
    }
}
