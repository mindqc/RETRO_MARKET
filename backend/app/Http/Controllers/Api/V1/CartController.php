<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Order\AddCartItemRequest;
use App\Http\Requests\Api\V1\Order\UpdateCartItemRequest;
use App\Services\Order\CartService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CartController extends Controller
{
    public function __construct(
        protected CartService $cartService
    ) {}

    /**
     * Get grouped cart contents separated by store (M-CR-01).
     */
    public function index(Request $request): JsonResponse
    {
        $result = $this->cartService->getGroupedCart($request->user());

        return ApiResponse::success($result, 'Lấy danh sách giỏ hàng thành công.');
    }

    /**
     * Add product to cart (M-CR-01 / OF-01).
     */
    public function storeItem(AddCartItemRequest $request): JsonResponse
    {
        $item = $this->cartService->addItem(
            $request->user(),
            (int) $request->input('product_id'),
            (int) $request->input('quantity', 1)
        );

        return ApiResponse::created($item, 'Thêm sản phẩm vào giỏ hàng thành công.');
    }

    /**
     * Update quantity or selected status of cart item.
     */
    public function updateItem(UpdateCartItemRequest $request, int $id): JsonResponse
    {
        $item = $this->cartService->updateItem(
            $request->user(),
            $id,
            $request->validated()
        );

        return ApiResponse::success($item, 'Cập nhật món đồ trong giỏ hàng thành công.');
    }

    /**
     * Remove item from cart.
     */
    public function destroyItem(Request $request, int $id): JsonResponse
    {
        $this->cartService->removeItem($request->user(), $id);

        return ApiResponse::success(null, 'Xóa sản phẩm khỏi giỏ hàng thành công.');
    }
}
