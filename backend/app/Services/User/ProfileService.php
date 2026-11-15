<?php

namespace App\Services\User;

use App\Exceptions\DomainException;
use App\Models\Order;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ProfileService
{
    /**
     * Get unified account profile summary, wallet, and order counters (M-PF-01 / NAV-DEC-02).
     */
    public function getMyProfileSummary(User $user): array
    {
        $user->loadMissing(['profile', 'sellerProfile', 'defaultAddress']);

        // Order Counters by Status
        $rawCounts = Order::query()
            ->where('buyer_id', $user->id)
            ->selectRaw('order_status, count(*) as count')
            ->groupBy('order_status')
            ->pluck('count', 'order_status')
            ->toArray();

        $disputedCount = Order::query()
            ->where('buyer_id', $user->id)
            ->where('dispute_status', '!=', 'NONE')
            ->count();

        $orderStatusCounts = [
            'pending_payment' => (int) ($rawCounts['PENDING_PAYMENT'] ?? 0),
            'paid' => (int) ($rawCounts['PAID'] ?? 0),
            'preparing' => (int) ($rawCounts['PREPARING'] ?? 0),
            'shipped' => (int) ($rawCounts['SHIPPED'] ?? 0),
            'delivered' => (int) ($rawCounts['DELIVERED'] ?? 0),
            'completed' => (int) ($rawCounts['COMPLETED'] ?? 0),
            'disputed' => $disputedCount,
        ];

        return [
            'user' => $user,
            'order_status_counts' => $orderStatusCounts,
            'favorites_count' => $user->favorites()->count(),
            'following_count' => $user->followingSellers()->count(),
        ];
    }

    /**
     * Update user profile information and optional avatar upload (M-PF-02 / NFR-SEC-05).
     */
    public function updateProfile(User $user, array $data, ?UploadedFile $avatar = null): User
    {
        // 1. Update Core User Info
        if (isset($data['display_name'])) {
            $user->display_name = trim($data['display_name']);
        }
        if (array_key_exists('phone', $data)) {
            $user->phone = $data['phone'] !== null ? trim($data['phone']) : null;
        }
        $user->save();

        // 2. Update or Create UserProfile
        $profile = $user->profile ?: UserProfile::create(['user_id' => $user->id]);

        if (array_key_exists('bio', $data)) {
            $profile->bio = $data['bio'];
        }

        if ($avatar) {
            $path = $avatar->store('avatars', 'public');
            $profile->avatar_url = Storage::disk('public')->url($path);
        }

        $profile->save();

        // 3. Update Seller Profile shop_slug if provided
        if (! empty($data['shop_slug']) && $user->sellerProfile) {
            $user->sellerProfile->update([
                'shop_slug' => Str::slug($data['shop_slug']),
            ]);
        }

        return $user->load(['profile', 'sellerProfile', 'defaultAddress']);
    }

    /**
     * Toggle seasonal decor settings (NFR-UX-02).
     */
    public function updateSettings(User $user, bool $seasonalDecorEnabled): UserProfile
    {
        $profile = $user->profile ?: UserProfile::create(['user_id' => $user->id]);
        $profile->update([
            'seasonal_decor_enabled' => $seasonalDecorEnabled,
        ]);

        return $profile->fresh();
    }

    /**
     * Change user password after verifying current password.
     *
     * @throws DomainException
     */
    public function changePassword(User $user, string $currentPassword, string $newPassword): void
    {
        if (! Hash::check($currentPassword, $user->password_hash)) {
            throw new DomainException(
                'Mật khẩu hiện tại không chính xác.',
                'INVALID_CURRENT_PASSWORD',
                422,
                ['current_password' => ['Mật khẩu hiện tại không chính xác.']]
            );
        }

        $user->update([
            'password_hash' => Hash::make($newPassword),
        ]);

        // Revoke all tokens except current session for security
        $currentTokenId = $user->currentAccessToken()?->id;
        if ($currentTokenId) {
            $user->tokens()->where('id', '!=', $currentTokenId)->delete();
        } else {
            $user->tokens()->delete();
        }
    }
}
