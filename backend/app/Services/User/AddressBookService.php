<?php

namespace App\Services\User;

use App\Exceptions\RolePermissionDeniedException;
use App\Models\User;
use App\Models\UserAddress;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class AddressBookService
{
    /**
     * List all shipping addresses of the user (M-PF-03).
     */
    public function listUserAddresses(User $user): Collection
    {
        return $user->addresses()
            ->orderByDesc('is_default')
            ->orderByDesc('id')
            ->get();
    }

    /**
     * Create a new shipping address, ensuring single-default invariant (M-PF-04).
     */
    public function createAddress(User $user, array $data): UserAddress
    {
        return DB::transaction(function () use ($user, $data) {
            $isFirstAddress = $user->addresses()->doesntExist();
            $shouldBeDefault = $isFirstAddress || ! empty($data['is_default']);

            if ($shouldBeDefault) {
                $user->addresses()->update(['is_default' => false]);
                $data['is_default'] = true;
            } else {
                $data['is_default'] = false;
            }

            return $user->addresses()->create($data);
        });
    }

    /**
     * Update an address, verifying ownership and maintaining single-default invariant.
     *
     * @throws RolePermissionDeniedException
     */
    public function updateAddress(User $user, int $addressId, array $data): UserAddress
    {
        $address = UserAddress::findOrFail($addressId);

        if ($address->user_id !== $user->id) {
            throw new RolePermissionDeniedException('Bạn không có quyền chỉnh sửa địa chỉ này.');
        }

        return DB::transaction(function () use ($user, $address, $data) {
            if (! empty($data['is_default'])) {
                $user->addresses()->where('id', '!=', $address->id)->update(['is_default' => false]);
                $data['is_default'] = true;
            } elseif (isset($data['is_default']) && ! $data['is_default'] && $address->is_default) {
                // If unsetting default, ensure another address becomes default if available
                $next = $user->addresses()->where('id', '!=', $address->id)->latest('id')->first();
                if ($next) {
                    $next->update(['is_default' => true]);
                } else {
                    $data['is_default'] = true; // Cannot unset default on sole address
                }
            }

            $address->update($data);

            return $address->fresh();
        });
    }

    /**
     * Delete an address, promoting next latest address to default if needed.
     *
     * @throws RolePermissionDeniedException
     */
    public function deleteAddress(User $user, int $addressId): void
    {
        $address = UserAddress::findOrFail($addressId);

        if ($address->user_id !== $user->id) {
            throw new RolePermissionDeniedException('Bạn không có quyền xóa địa chỉ này.');
        }

        DB::transaction(function () use ($user, $address) {
            $wasDefault = $address->is_default;
            $address->delete();

            if ($wasDefault) {
                $nextAddress = $user->addresses()->latest('id')->first();
                $nextAddress?->update(['is_default' => true]);
            }
        });
    }
}
