<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\WalletTransactionResource;
use App\Services\Escrow\EscrowReleaseService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SellerWalletController extends Controller
{
    public function __construct(
        protected EscrowReleaseService $escrowReleaseService
    ) {}

    /**
     * Get seller wallet summary, current balances, and ledger transaction history (M-SL-08).
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 15);
        $summary = $this->escrowReleaseService->getSellerWalletSummary($request->user(), $perPage);

        /** @var \Illuminate\Contracts\Pagination\LengthAwarePaginator $walletPaginator */
        $walletPaginator = $summary['wallet_transactions'];

        $payload = [
            'wallet_balance' => (float) $summary['wallet_balance'],
            'escrow_held_balance' => (float) $summary['escrow_held_balance'],
            'completed_orders_count' => (int) $summary['completed_orders_count'],
            'wallet_transactions' => WalletTransactionResource::collection($walletPaginator->items()),
            'pagination' => [
                'current_page' => $walletPaginator->currentPage(),
                'last_page' => $walletPaginator->lastPage(),
                'per_page' => $walletPaginator->perPage(),
                'total' => $walletPaginator->total(),
            ],
            'recent_escrow_transactions' => $summary['recent_escrow_transactions'],
        ];

        return ApiResponse::success(
            $payload,
            'Lấy thông tin ví và lịch sử số dư thành công.'
        );
    }
}
