<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Engagement\StoreReportRequest;
use App\Http\Resources\Api\V1\ReportResource;
use App\Services\Governance\ViolationReportService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class ReportController extends Controller
{
    public function __construct(
        protected ViolationReportService $reportService
    ) {}

    /**
     * Submit a violation report (M-CM-03, A-CM-01).
     */
    public function store(StoreReportRequest $request): JsonResponse
    {
        $report = $this->reportService->submitReport(
            $request->user(),
            $request->validated()
        );

        return ApiResponse::created(
            new ReportResource($report),
            'Gửi báo cáo vi phạm thành công.'
        );
    }
}
