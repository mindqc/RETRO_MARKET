<?php

namespace Tests\Feature\Api\V1;

use App\Enums\AuctionStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Exceptions\SelfTransactionForbiddenException;
use App\Models\Auction;
use App\Models\AuditLog;
use App\Models\Cart;
use App\Models\Dispute;
use App\Models\SellerProfile;
use App\Models\User;
use App\Models\UserProfile;
use App\Services\Governance\UserGovernanceService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

class AuthAndRbacTest extends TestCase
{
    /**
     * 1. Test register creates User, dual profiles, and initial Cart atomically (BR-AC-01).
     */
    public function test_register_creates_user_dual_profiles_and_cart_atomically(): void
    {
        $payload = [
            'display_name' => 'Tran Thi Mai',
            'email' => 'tran.mai@izithrift.test',
            'password' => 'SecurePass@2026',
            'password_confirmation' => 'SecurePass@2026',
            'phone' => '0912345678',
            'device_name' => 'pixel_7_pro',
        ];

        try {
            $response = $this->postJson('/api/v1/auth/register', $payload);

            $response->assertStatus(201);
            $response->assertJsonStructure([
                'success',
                'message',
                'server_time',
                'data' => [
                    'user' => [
                        'id',
                        'display_name',
                        'email',
                        'phone',
                        'role',
                        'status',
                        'profile' => [
                            'id',
                            'seasonal_decor_enabled',
                        ],
                        'seller_profile' => [
                            'id',
                            'shop_slug',
                            'trust_score',
                            'wallet_balance',
                        ],
                    ],
                    'token',
                ],
            ]);

            $this->assertTrue($response->json('success'));
            $this->assertNotEmpty($response->json('data.token'));
            $this->assertEquals('tran.mai@izithrift.test', $response->json('data.user.email'));
            $this->assertEquals('registered_user', $response->json('data.user.role'));
            $this->assertEquals('ACTIVE', $response->json('data.user.status'));
            $this->assertTrue($response->json('data.user.profile.seasonal_decor_enabled'));
            $this->assertEquals(100.0, $response->json('data.user.seller_profile.trust_score'));
            $this->assertStringContainsString('tran-thi-mai-', $response->json('data.user.seller_profile.shop_slug'));
            $this->assertArrayNotHasKey('password_hash', $response->json('data.user'));

            $userId = $response->json('data.user.id');

            // Verify Atomic DB Creation across 4 tables
            $this->assertTrue(User::where('id', $userId)->exists());
            $this->assertTrue(UserProfile::where('user_id', $userId)->exists());
            $this->assertTrue(SellerProfile::where('user_id', $userId)->exists());
            $this->assertTrue(Cart::where('user_id', $userId)->exists());
        } finally {
            // Clean up test-created user
            $createdUser = User::where('email', 'tran.mai@izithrift.test')->first();
            if ($createdUser) {
                Cart::where('user_id', $createdUser->id)->delete();
                UserProfile::where('user_id', $createdUser->id)->delete();
                SellerProfile::where('user_id', $createdUser->id)->delete();
                $createdUser->tokens()->delete();
                $createdUser->delete();
            }
        }
    }

    /**
     * 2. Test login succeeds for active user and updates last_login_at.
     */
    public function test_login_succeeds_for_active_user_and_updates_last_login_at(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'buyer.linh@izithrift.local',
            'password' => 'Retro@2026',
            'device_name' => 'iphone_15_pro',
        ]);

        $response->assertStatus(200);
        $this->assertTrue($response->json('success'));
        $this->assertNotEmpty($response->json('data.token'));
        $this->assertEquals('buyer.linh@izithrift.local', $response->json('data.user.email'));
        $this->assertEquals('ACTIVE', $response->json('data.user.status'));
        $this->assertNotNull($response->json('data.user.last_login_at'));
        $this->assertArrayNotHasKey('password_hash', $response->json('data.user'));
    }

    /**
     * 3. Test login fails with invalid credentials returning 401.
     */
    public function test_login_fails_with_invalid_credentials_returning_401(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'buyer.linh@izithrift.local',
            'password' => 'WrongPassword123!',
        ]);

        $response->assertStatus(401);
        $this->assertFalse($response->json('success'));
        $this->assertEquals('INVALID_CREDENTIALS', $response->json('error_code'));
        $this->assertNotEmpty($response->json('server_time'));
    }

    /**
     * 4. Test login blocks suspended user with 403 ACCOUNT_SUSPENDED (BR-AC-04).
     */
    public function test_login_blocks_suspended_user_with_403_account_suspended(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'suspended.user@izithrift.local',
            'password' => 'Retro@2026',
        ]);

        $response->assertStatus(403);
        $this->assertFalse($response->json('success'));
        $this->assertEquals('ACCOUNT_SUSPENDED', $response->json('error_code'));
        $this->assertNotEmpty($response->json('server_time'));
    }

    /**
     * 5. Test logout revokes current access token.
     */
    public function test_logout_revokes_current_access_token(): void
    {
        $loginRes = $this->postJson('/api/v1/auth/login', [
            'email' => 'buyer.linh@izithrift.local',
            'password' => 'Retro@2026',
        ]);

        $token = $loginRes->json('data.token');
        $this->assertNotEmpty($token);

        // Call logout
        $logoutRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/v1/auth/logout');

        $logoutRes->assertStatus(200);
        $this->assertTrue($logoutRes->json('success'));

        // Reset auth singleton guards between requests
        auth()->forgetGuards();

        // Token must be invalid now -> 401
        $subsequentRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/v1/auth/logout');

        $subsequentRes->assertStatus(401);
        $this->assertFalse($subsequentRes->json('success'));
        $this->assertEquals('UNAUTHENTICATED', $subsequentRes->json('error_code'));
    }

    /**
     * 6. Test forgot and reset password flow updates password_hash and revokes tokens.
     */
    public function test_forgot_and_reset_password_flow_updates_password_hash_and_revokes_tokens(): void
    {
        $seller = User::where('email', 'gau.vintage@izithrift.local')->firstOrFail();
        $oldToken = $seller->createToken('old_pre_reset_token')->plainTextToken;

        try {
            // Request reset token
            $forgotRes = $this->postJson('/api/v1/auth/forgot-password', [
                'email' => 'gau.vintage@izithrift.local',
            ]);

            $forgotRes->assertStatus(200);
            $this->assertTrue($forgotRes->json('success'));
            $resetToken = $forgotRes->json('data.reset_token');
            $this->assertNotEmpty($resetToken);

            // Execute reset password
            $resetRes = $this->postJson('/api/v1/auth/reset-password', [
                'email' => 'gau.vintage@izithrift.local',
                'token' => $resetToken,
                'password' => 'NewSecurePassword@2026',
                'password_confirmation' => 'NewSecurePassword@2026',
            ]);

            $resetRes->assertStatus(200);
            $this->assertTrue($resetRes->json('success'));

            // Verify password_reset_tokens record deleted
            $this->assertFalse(DB::table('password_reset_tokens')->where('email', 'gau.vintage@izithrift.local')->exists());

            // Verify old token was revoked
            $this->assertNull(PersonalAccessToken::findToken($oldToken));

            // Verify login with new password succeeds
            $loginRes = $this->postJson('/api/v1/auth/login', [
                'email' => 'gau.vintage@izithrift.local',
                'password' => 'NewSecurePassword@2026',
            ]);
            $loginRes->assertStatus(200);
        } finally {
            // Restore original seeded password
            $seller->update(['password_hash' => Hash::make('Retro@2026')]);
            $seller->tokens()->delete();
        }
    }

    /**
     * 7. Test UserGovernanceService suspends user, revokes all tokens, and logs audit entry (BR-AC-04).
     */
    public function test_user_governance_service_suspends_user_and_revokes_all_tokens(): void
    {
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $targetUser = User::where('email', 'buyer.ha@izithrift.local')->firstOrFail();

        // Create 2 tokens for target user
        $t1 = $targetUser->createToken('device_1')->plainTextToken;
        $t2 = $targetUser->createToken('device_2')->plainTextToken;
        $this->assertEquals(2, $targetUser->tokens()->count());

        $governanceService = app(UserGovernanceService::class);

        try {
            $updatedUser = $governanceService->updateAccountStatus(
                actor: $admin,
                targetUser: $targetUser,
                newStatus: UserStatus::SUSPENDED,
                reason: 'Vi phạm quy định giao dịch bất thường',
                suspendedUntil: now()->addDays(7)->toIso8601String()
            );

            $this->assertEquals(UserStatus::SUSPENDED, $updatedUser->status);
            $this->assertEquals('Vi phạm quy định giao dịch bất thường', $updatedUser->status_reason);

            // All tokens must be deleted (BR-AC-04)
            $this->assertEquals(0, $targetUser->tokens()->count());
            $this->assertNull(PersonalAccessToken::findToken($t1));
            $this->assertNull(PersonalAccessToken::findToken($t2));

            // Verify immutable audit log was created
            $log = AuditLog::where('target_id', $targetUser->id)
                ->where('action', 'UPDATE_ACCOUNT_STATUS')
                ->latest('id')
                ->first();

            $this->assertNotNull($log);
            $this->assertEquals('admin', $log->actor_role);
            $this->assertEquals('Vi phạm quy định giao dịch bất thường', $log->reason);
        } finally {
            // Restore user back to ACTIVE
            $targetUser->update([
                'status' => UserStatus::ACTIVE,
                'status_reason' => null,
                'suspended_until' => null,
            ]);
            $targetUser->tokens()->delete();
        }
    }

    /**
     * 8. Test policies enforce anti-self-transaction and admin-only dispute verdict (PERM-CM-08 vs PERM-CM-09).
     */
    public function test_policies_enforce_anti_self_transaction_and_admin_only_dispute_verdict(): void
    {
        // 8.1. AuctionPolicy Anti-Self-Bidding (BR-AC-02 / BR-AU-02)
        $auction = Auction::where('status', AuctionStatus::LIVE)->firstOrFail();
        $seller = User::findOrFail($auction->seller_id);
        $buyer = User::where('id', '!=', $auction->seller_id)
            ->where('role', UserRole::REGISTERED_USER)
            ->where('status', UserStatus::ACTIVE)
            ->firstOrFail();

        // Seller bidding on own auction throws SelfTransactionForbiddenException
        try {
            Gate::forUser($seller)->authorize('placeBid', $auction);
            $this->fail('Expected SelfTransactionForbiddenException was not thrown for seller bidding on own auction.');
        } catch (SelfTransactionForbiddenException $e) {
            $this->assertEquals('SELF_TRANSACTION_FORBIDDEN', $e->getErrorCode());
            $this->assertEquals(403, $e->getHttpStatus());
        }

        // Other buyer is allowed
        $this->assertTrue(Gate::forUser($buyer)->allows('placeBid', $auction));

        // 8.2. DisputePolicy PERM-CM-08 vs PERM-CM-09
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $support = User::where('email', 'support@izithrift.local')->firstOrFail();
        $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();
        $regularUser = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();

        $dispute = new Dispute(['id' => 999]);

        // Request More Info (PERM-CM-08): Admin & Support allowed; Regular & Moderator blocked
        $this->assertTrue(Gate::forUser($admin)->allows('requestMoreInfo', $dispute));
        $this->assertTrue(Gate::forUser($support)->allows('requestMoreInfo', $dispute));
        $this->assertFalse(Gate::forUser($moderator)->allows('requestMoreInfo', $dispute));
        $this->assertFalse(Gate::forUser($regularUser)->allows('requestMoreInfo', $dispute));

        // Resolve Verdict (PERM-CM-09): ADMIN ONLY; Support & Moderator strictly blocked
        $this->assertTrue(Gate::forUser($admin)->allows('resolveVerdict', $dispute));
        $this->assertFalse(Gate::forUser($support)->allows('resolveVerdict', $dispute));
        $this->assertFalse(Gate::forUser($moderator)->allows('resolveVerdict', $dispute));
        $this->assertFalse(Gate::forUser($regularUser)->allows('resolveVerdict', $dispute));
    }
}
