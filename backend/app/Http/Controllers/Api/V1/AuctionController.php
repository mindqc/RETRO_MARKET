<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auction\PlaceBidRequest;
use App\Http\Requests\Api\V1\Auction\RelistAuctionRequest;
use App\Http\Resources\Api\V1\AuctionBidResource;
use App\Http\Resources\Api\V1\AuctionCardResource;
use App\Http\Resources\Api\V1\AuctionDetailResource;
use App\Http\Resources\Api\V1\OrderResource;
use App\Models\Product;
use App\Services\Auction\AuctionBiddingService;
use App\Services\Auction\AuctionLifecycleService;
use App\Services\Auction\AuctionQueryService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuctionController extends Controller
{
    public function __construct(
        protected AuctionQueryService $queryService,
        protected AuctionBiddingService $biddingService,
        protected AuctionLifecycleService $lifecycleService
    ) {}

    /**
     * List auctions for Hub tabs: live, ending_soon, upcoming, completed (M-AC-01).
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 12);
        $paginator = $this->queryService->listHubAuctions($request->all(), $request->user(), $perPage);

        return ApiResponse::paginated(
            $paginator,
            AuctionCardResource::collection($paginator->items()),
            'Lấy danh sách phiên đấu giá thành công.'
        );
    }

    /**
     * List user's personal auction tabs: participating, watchlist, won (M-AC-02).
     */
    public function mine(Request $request): JsonResponse
    {
        $tab = $request->input('tab', 'participating');
        $perPage = (int) $request->input('per_page', 12);
        $paginator = $this->queryService->listMyAuctions($request->user(), $tab, $perPage);

        return ApiResponse::paginated(
            $paginator,
            AuctionCardResource::collection($paginator->items()),
            'Lấy danh sách hoạt động đấu giá cá nhân thành công.'
        );
    }

    /**
     * Get auction room detail (M-AC-03).
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $room = $this->queryService->getAuctionRoomDetail($id, $request->user());

        $payload = [
            'auction' => new AuctionDetailResource($room['auction']),
            'server_time' => $room['server_time'],
            'minimum_next_bid' => $room['minimum_next_bid'],
            'has_reserve_price' => $room['has_reserve_price'],
            'reserve_price_met' => $room['reserve_price_met'],
            'reserve_price' => $room['reserve_price'],
            'is_owner' => $room['is_owner'],
            'is_watching' => $room['is_watching'],
            'is_leading' => $room['is_leading'],
            'recent_bids' => AuctionBidResource::collection($room['recent_bids']),
        ];

        return ApiResponse::success(
            $payload,
            'Lấy chi tiết phòng đấu giá thành công.'
        );
    }

    /**
     * List all bids of an auction with pagination.
     */
    public function bids(Request $request, int $id): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 20);
        $paginator = $this->queryService->listAuctionBids($id, $perPage);

        return ApiResponse::paginated(
            $paginator,
            AuctionBidResource::collection($paginator->items()),
            'Lấy lịch sử đặt giá thành công.'
        );
    }

    /**
     * Place a concurrent bid on an active auction (M-AC-04 / BR-AU-03).
     */
    public function placeBid(PlaceBidRequest $request, int $id): JsonResponse
    {
        $result = $this->biddingService->placeBid(
            $request->user(),
            $id,
            $request->input('bid_amount')
        );

        return ApiResponse::success(
            [
                'auction' => new AuctionDetailResource($result['auction']),
                'bid' => new AuctionBidResource($result['bid']),
                'triggered_anti_sniping' => $result['triggered_anti_sniping'],
            ],
            $result['triggered_anti_sniping']
                ? 'Đặt giá thành công! Thời gian phiên đấu giá đã được tự động gia hạn (Anti-Sniping).'
                : 'Đặt giá thành công!'
        );
    }

    /**
     * Toggle watch / unwatch an auction (M-AC-01 / Watchlist).
     */
    public function toggleWatch(Request $request, int $id): JsonResponse
    {
        $result = $this->queryService->toggleWatch($request->user(), $id);

        $msg = $result['is_watching']
            ? 'Đã thêm phiên đấu giá vào danh sách theo dõi.'
            : 'Đã hủy theo dõi phiên đấu giá.';

        return ApiResponse::success($result, $msg);
    }

    /**
     * Seller closes an auction early (M-AC-05 / BR-AU-05 / AF-06).
     */
    public function closeEarly(Request $request, int $id): JsonResponse
    {
        $result = $this->lifecycleService->closeEarlyBySeller($request->user(), $id);

        return ApiResponse::success(
            [
                'auction' => new AuctionDetailResource($result['auction']),
                'order' => new OrderResource($result['order']),
            ],
            'Chốt phiên sớm thành công. Đơn hàng cho người thắng cuộc đã được tạo.'
        );
    }

    /**
     * Seller relists a product for auction after ENDED_UNSOLD or WINNER_DEFAULTED (DEC-02 / AF-09).
     */
    public function relistProduct(RelistAuctionRequest $request, int $id): JsonResponse
    {
        $product = Product::findOrFail($id);
        $newAuction = $this->lifecycleService->relistAuctionProduct(
            $request->user(),
            $product,
            $request->validated()
        );

        return ApiResponse::created(
            new AuctionDetailResource($newAuction),
            'Đăng lại sản phẩm đấu giá thành công.'
        );
    }
}
