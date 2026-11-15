<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Http\Controllers\Controller;
use App\Services\Governance\PlatformConfigService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class BootstrapController extends Controller
{
    /**
     * System health check endpoint.
     */
    public function health(): JsonResponse
    {
        $dbStatus = 'connected';
        try {
            DB::connection()->getPdo();
        } catch (\Throwable $e) {
            $dbStatus = 'disconnected: '.$e->getMessage();
        }

        $redisStatus = 'connected';
        try {
            Redis::ping();
        } catch (\Throwable $e) {
            $redisStatus = 'disconnected: '.$e->getMessage();
        }

        return ApiResponse::success([
            'status' => 'healthy',
            'database' => $dbStatus,
            'redis' => $redisStatus,
        ], 'Hệ thống hoạt động bình thường.');
    }

    /**
     * Application bootstrap endpoint for mobile/web client initialization (M-AU-01).
     */
    public function bootstrap(Request $request, PlatformConfigService $configService): JsonResponse
    {
        $user = $request->user();

        $currentUser = null;
        if ($user) {
            $currentUser = [
                'id' => $user->id,
                'email' => $user->email,
                'display_name' => $user->display_name,
                'role' => $user->role instanceof UserRole ? $user->role->value : (string) $user->role,
                'status' => $user->status instanceof UserStatus ? $user->status->value : (string) $user->status,
            ];
        }

        $config = $configService->getPublicBootstrapConfig();
        $config['current_user'] = $currentUser;

        return ApiResponse::success($config, 'Khởi tạo ứng dụng thành công.');
    }
}
