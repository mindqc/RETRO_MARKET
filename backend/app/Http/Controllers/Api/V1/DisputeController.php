<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\RolePermissionDeniedException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Order\OpenDisputeRequest;
use App\Http\Requests\Api\V1\Order\SubmitDisputeEvidenceRequest;
use App\Http\Resources\Api\V1\DisputeEvidenceResource;
use App\Http\Resources\Api\V1\DisputeResource;
use App\Models\Dispute;
use App\Models\Order;
use App\Services\Escrow\DisputeService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DisputeController extends Controller
{
    public function __construct(
        protected DisputeService $disputeService
    ) {}

    /**
     * List disputes for the authenticated user or all for internal staff.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $perPage = (int) $request->input('per_page', 15);
        $status = $request->input('status');

        $query = Dispute::with(['order', 'buyer.profile', 'seller.sellerProfile', 'evidences.uploader']);

        if (!$user->isInternalStaff()) {
            $query->where(function ($sub) use ($user) {
                $sub->where('buyer_id', $user->id)
                    ->orWhere('seller_id', $user->id);
            });
        }

        if (!empty($status)) {
            $query->where('status', strtoupper($status));
        }

        $paginator = $query->orderByDesc('created_at')->paginate($perPage);

        return ApiResponse::paginated(
            $paginator,
            DisputeResource::collection($paginator->items()),
            'Lấy danh sách khiếu nại thành công.'
        );
    }

    /**
     * Show detailed dispute information.
     *
     * @throws RolePermissionDeniedException
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $dispute = Dispute::with(['order', 'buyer.profile', 'seller.sellerProfile', 'evidences.uploader'])->findOrFail($id);
        $user = $request->user();

        if ($user->id !== $dispute->buyer_id && $user->id !== $dispute->seller_id && !$user->isInternalStaff()) {
            throw new RolePermissionDeniedException('Bạn không có quyền xem thông tin phiên khiếu nại này.');
        }

        return ApiResponse::success(
            new DisputeResource($dispute),
            'Lấy thông tin chi tiết khiếu nại thành công.'
        );
    }

    /**
     * Buyer opens a dispute on an order (POST /api/v1/orders/{id}/disputes).
     */
    public function store(OpenDisputeRequest $request, int $id): JsonResponse
    {
        $order = Order::findOrFail($id);
        $uploadedFiles = $request->file('files', []);
        if (!is_array($uploadedFiles)) {
            $uploadedFiles = [$uploadedFiles];
        }

        $dispute = $this->disputeService->openDispute(
            $request->user(),
            $order,
            $request->validated(),
            $uploadedFiles
        );

        return ApiResponse::created(
            new DisputeResource($dispute),
            'Mở khiếu nại đơn hàng thành công. Tiền trung gian đã được tạm khóa để bảo vệ hai bên.'
        );
    }

    /**
     * Submit additional counter-evidence or response note on a dispute (POST /api/v1/disputes/{id}/evidences).
     */
    public function storeEvidence(SubmitDisputeEvidenceRequest $request, int $id): JsonResponse
    {
        $dispute = Dispute::findOrFail($id);
        $evidence = $this->disputeService->submitEvidenceOrResponse(
            $request->user(),
            $dispute,
            $request->validated(),
            $request->file('file')
        );

        return ApiResponse::created(
            new DisputeEvidenceResource($evidence),
            'Nộp bằng chứng hoặc phản hồi cho phiên khiếu nại thành công.'
        );
    }

    /**
     * Supreme Administrator executes financial verdict on a dispute (POST /api/v1/admin/disputes/{id}/resolve).
     */
    public function resolve(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'verdict' => ['required', 'string', 'in:APPROVE_BUYER_REFUND,RELEASE_TO_SELLER,PARTIAL_REFUND'],
            'partial_refund_to_buyer' => ['nullable', 'numeric', 'min:0.01'],
            'resolution_note' => ['required', 'string', 'min:5', 'max:2000'],
        ]);

        $dispute = Dispute::findOrFail($id);
        $resolvedDispute = $this->disputeService->resolveDisputeByAdmin(
            $request->user(),
            $dispute,
            $request->input('verdict'),
            $request->filled('partial_refund_to_buyer') ? (float) $request->input('partial_refund_to_buyer') : null,
            $request->input('resolution_note')
        );

        return ApiResponse::success(
            new DisputeResource($resolvedDispute),
            'Đã phân xử khiếu nại và thực thi bút toán tài chính thành công.'
        );
    }
}
