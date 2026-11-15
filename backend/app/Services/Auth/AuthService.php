<?php

namespace App\Services\Auth;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Exceptions\AccountSuspendedException;
use App\Exceptions\DomainException;
use App\Models\Cart;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\UserProfile;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthService
{
    /**
     * Register a new user account with dual profiles and cart atomically (BR-AC-01).
     *
     * @param  array{
     *     display_name: string,
     *     email: string,
     *     password: string,
     *     phone?: string|null,
     *     avatar_url?: string|null,
     *     bio?: string|null,
     *     device_name?: string|null
     * }  $data
     * @return array{user: User, token: string}
     */
    public function register(array $data): array
    {
        return DB::transaction(function () use ($data) {
            $email = strtolower(trim($data['email']));

            // 1. Create Core User
            $user = User::create([
                'display_name' => trim($data['display_name']),
                'email' => $email,
                'phone' => isset($data['phone']) ? trim($data['phone']) : null,
                'password_hash' => Hash::make($data['password']),
                'role' => UserRole::REGISTERED_USER,
                'status' => UserStatus::ACTIVE,
                'last_login_at' => now(),
            ]);

            // 2. Create UserProfile
            UserProfile::create([
                'user_id' => $user->id,
                'avatar_url' => $data['avatar_url'] ?? null,
                'bio' => $data['bio'] ?? null,
                'seasonal_decor_enabled' => true,
            ]);

            // 3. Create SellerProfile with Unique shop_slug
            $baseSlug = Str::slug($data['display_name']) ?: 'shop';
            $shopSlug = $baseSlug . '-' . $user->id;

            SellerProfile::create([
                'user_id' => $user->id,
                'shop_slug' => $shopSlug,
                'trust_score' => 100.00,
                'average_rating' => 0.00,
                'wallet_balance' => 0.00,
                'escrow_held_balance' => 0.00,
                'review_count' => 0,
                'completed_orders_count' => 0,
                'auction_default_count' => 0,
                'dispute_lost_count' => 0,
            ]);

            // 4. Create Cart
            Cart::create([
                'user_id' => $user->id,
            ]);

            // 5. Issue Initial Sanctum Token
            $deviceName = $data['device_name'] ?? 'flutter_mobile';
            $token = $user->createToken($deviceName)->plainTextToken;

            return [
                'user' => $user->load(['profile', 'sellerProfile']),
                'token' => $token,
            ];
        });
    }

    /**
     * Authenticate user credentials and issue a new Sanctum token.
     * Enforces BR-AC-04: Block login and throw 403 if account is suspended/banned.
     *
     * @return array{user: User, token: string}
     *
     * @throws DomainException
     * @throws AccountSuspendedException
     */
    public function login(string $email, string $password, string $deviceName = 'flutter_mobile'): array
    {
        $normalizedEmail = strtolower(trim($email));
        $user = User::whereRaw('LOWER(email) = ?', [$normalizedEmail])->first();

        if (! $user || ! Hash::check($password, $user->password_hash)) {
            throw new DomainException(
                'Email hoặc mật khẩu không chính xác.',
                'INVALID_CREDENTIALS',
                401
            );
        }

        $userStatus = $user->status instanceof UserStatus ? $user->status->value : (string) $user->status;
        if ($userStatus !== UserStatus::ACTIVE->value && $userStatus !== 'ACTIVE') {
            $reason = $user->status_reason ?: 'Tài khoản của bạn đã bị tạm khóa hoặc cấm hoạt động do vi phạm quy định cộng đồng.';
            throw new AccountSuspendedException($reason);
        }

        $user->update([
            'last_login_at' => now(),
        ]);

        $token = $user->createToken($deviceName)->plainTextToken;

        return [
            'user' => $user->load(['profile', 'sellerProfile']),
            'token' => $token,
        ];
    }

    /**
     * Revoke current access token (logout).
     */
    public function logout(User $user): void
    {
        $user->currentAccessToken()?->delete();
        if (app()->bound('auth')) {
            auth()->forgetGuards();
        }
    }

    /**
     * Generate password reset token and store in password_reset_tokens table.
     *
     * @return array{email: string, token: string}
     */
    public function sendResetToken(string $email): array
    {
        $normalizedEmail = strtolower(trim($email));
        $user = User::whereRaw('LOWER(email) = ?', [$normalizedEmail])->first();

        if (! $user) {
            throw new DomainException(
                'Không tìm thấy tài khoản với địa chỉ email này.',
                'RESOURCE_NOT_AVAILABLE',
                404
            );
        }

        $rawToken = Str::random(64);

        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $normalizedEmail],
            [
                'token' => Hash::make($rawToken),
                'created_at' => now(),
            ]
        );

        return [
            'email' => $normalizedEmail,
            'token' => $rawToken,
        ];
    }

    /**
     * Reset password using token, update password_hash, and revoke all existing tokens.
     */
    public function resetPassword(string $email, string $token, string $newPassword): void
    {
        $normalizedEmail = strtolower(trim($email));
        $record = DB::table('password_reset_tokens')->where('email', $normalizedEmail)->first();

        if (! $record) {
            throw new DomainException(
                'Mã khôi phục mật khẩu không tồn tại hoặc đã được sử dụng.',
                'INVALID_RESET_TOKEN',
                400
            );
        }

        if (! Hash::check($token, $record->token)) {
            throw new DomainException(
                'Mã khôi phục mật khẩu không chính xác.',
                'INVALID_RESET_TOKEN',
                400
            );
        }

        $createdAt = Carbon::parse($record->created_at);
        if ($createdAt->diffInMinutes(now()) > 60) {
            DB::table('password_reset_tokens')->where('email', $normalizedEmail)->delete();
            throw new DomainException(
                'Mã khôi phục mật khẩu đã hết hạn. Vui lòng yêu cầu mã mới.',
                'RESET_TOKEN_EXPIRED',
                400
            );
        }

        $user = User::whereRaw('LOWER(email) = ?', [$normalizedEmail])->first();
        if (! $user) {
            throw new DomainException(
                'Không tìm thấy tài khoản với địa chỉ email này.',
                'RESOURCE_NOT_AVAILABLE',
                404
            );
        }

        DB::transaction(function () use ($user, $normalizedEmail, $newPassword) {
            $user->update([
                'password_hash' => Hash::make($newPassword),
            ]);

            DB::table('password_reset_tokens')->where('email', $normalizedEmail)->delete();

            // Revoke all existing tokens for security
            $user->tokens()->delete();
        });
    }
}
