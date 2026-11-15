<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Governance\SystemDevToolsService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SystemDevToolsController extends Controller
{
    public function __construct(
        protected SystemDevToolsService $devToolsService
    ) {}

    /**
     * Trigger background job action via DevTools (A-DT-01 / ADR-05).
     */
    public function triggerJobs(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'action_key' => ['required', 'string'],
        ]);

        $summary = $this->devToolsService->triggerJobAction(
            $request->user(),
            (string) $validated['action_key']
        );

        return ApiResponse::success(
            $summary,
            'Kích hoạt tác vụ nền tự động qua DevTools thành công.'
        );
    }
}
