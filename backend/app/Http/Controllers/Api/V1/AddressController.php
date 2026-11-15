<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Profile\StoreAddressRequest;
use App\Http\Requests\Api\V1\Profile\UpdateAddressRequest;
use App\Http\Resources\Api\V1\UserAddressResource;
use App\Services\User\AddressBookService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AddressController extends Controller
{
    public function __construct(
        protected AddressBookService $addressBookService
    ) {}

    /**
     * List user shipping addresses (M-PF-03).
     */
    public function index(Request $request): JsonResponse
    {
        $addresses = $this->addressBookService->listUserAddresses($request->user());

        return ApiResponse::success(
            UserAddressResource::collection($addresses),
            'Lấy danh sách địa chỉ nhận hàng thành công.'
        );
    }

    /**
     * Store new shipping address (M-PF-04).
     */
    public function store(StoreAddressRequest $request): JsonResponse
    {
        $address = $this->addressBookService->createAddress(
            $request->user(),
            $request->validated()
        );

        return ApiResponse::created(
            new UserAddressResource($address),
            'Thêm địa chỉ nhận hàng thành công.'
        );
    }

    /**
     * Update shipping address (M-PF-04).
     */
    public function update(UpdateAddressRequest $request, int $id): JsonResponse
    {
        $address = $this->addressBookService->updateAddress(
            $request->user(),
            $id,
            $request->validated()
        );

        return ApiResponse::success(
            new UserAddressResource($address),
            'Cập nhật địa chỉ nhận hàng thành công.'
        );
    }

    /**
     * Delete shipping address.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $this->addressBookService->deleteAddress($request->user(), $id);

        return ApiResponse::success(null, 'Xóa địa chỉ nhận hàng thành công.');
    }
}
