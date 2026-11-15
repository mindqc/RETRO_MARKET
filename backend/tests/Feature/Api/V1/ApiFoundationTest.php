<?php

namespace Tests\Feature\Api\V1;

use App\Exceptions\AuctionOutbidConflictException;
use App\Models\User;
use App\Services\Governance\AuditLogService;
use App\Services\Governance\PlatformConfigService;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

class ApiFoundationTest extends TestCase
{
    /**
     * 1. Test GET /api/v1/bootstrap returns standard envelope for guest.
     */
    public function test_bootstrap_endpoint_returns_standard_envelope_for_guest(): void
    {
        $response = $this->getJson('/api/v1/bootstrap');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'success',
            'message',
            'server_time',
            'data' => [
                'server_time',
                'demo_mode',
                'protection_fee_rate',
                'protection_fixed_fee',
                'shipping_fee_default',
                'seller_commission_rate',
                'auction_payment_deadline_minutes',
                'current_user',
            ],
        ]);

        $this->assertTrue($response->json('success'));
        $this->assertNull($response->json('data.current_user'));
        $this->assertEquals(0.06, $response->json('data.protection_fee_rate'));
        $this->assertEquals(7000.0, $response->json('data.protection_fixed_fee'));
        $this->assertEquals(0.0, $response->json('data.shipping_fee_default'));
        $this->assertEquals(0.0, $response->json('data.seller_commission_rate'));
        $this->assertNotEmpty($response->json('server_time'));
    }

    /**
     * 2. Test GET /api/v1/bootstrap resolves authenticated active user.
     */
    public function test_bootstrap_endpoint_resolves_authenticated_active_user(): void
    {
        $user = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $token = $user->createToken('test_active_user')->plainTextToken;

        try {
            $response = $this->withHeader('Authorization', "Bearer {$token}")
                ->getJson('/api/v1/bootstrap');

            $response->assertStatus(200);
            $this->assertTrue($response->json('success'));
            $this->assertNotNull($response->json('data.current_user'));
            $this->assertEquals($user->id, $response->json('data.current_user.id'));
            $this->assertEquals('buyer.linh@izithrift.local', $response->json('data.current_user.email'));
            $this->assertEquals('ACTIVE', $response->json('data.current_user.status'));
            $this->assertArrayNotHasKey('password_hash', $response->json('data.current_user'));
        } finally {
            $user->tokens()->delete();
        }
    }

    /**
     * 3. Test suspended user is blocked with 403 ACCOUNT_SUSPENDED and token revoked.
     */
    public function test_suspended_user_is_blocked_with_403_account_suspended_and_token_revoked(): void
    {
        $suspendedUser = User::where('email', 'suspended.user@izithrift.local')->firstOrFail();
        $token = $suspendedUser->createToken('test_suspended_token')->plainTextToken;

        // Verify token exists in database
        $tokenModel = PersonalAccessToken::findToken($token);
        $this->assertNotNull($tokenModel);

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/v1/bootstrap');

        $response->assertStatus(403);
        $this->assertFalse($response->json('success'));
        $this->assertEquals('ACCOUNT_SUSPENDED', $response->json('error_code'));
        $this->assertNotEmpty($response->json('server_time'));

        // Verify token was deleted from database per BR-AC-04
        $this->assertNull(PersonalAccessToken::findToken($token));
    }

    /**
     * 4. Test unknown API route returns standardized 404 JSON envelope.
     */
    public function test_unknown_api_route_returns_standardized_404_json_envelope(): void
    {
        $response = $this->getJson('/api/v1/non-existent-endpoint');

        $response->assertStatus(404);
        $this->assertFalse($response->json('success'));
        $this->assertEquals('RESOURCE_NOT_AVAILABLE', $response->json('error_code'));
        $this->assertNotEmpty($response->json('server_time'));
    }

    /**
     * 5. Test domain exceptions render exact error codes and latest_state.
     */
    public function test_domain_exceptions_render_exact_error_codes_and_latest_state(): void
    {
        $latestState = [
            'current_highest_bid' => 450000.00,
            'current_winner_id' => 12,
            'minimum_next_bid' => 460000.00,
        ];

        $exception = new AuctionOutbidConflictException(
            'Mức giá đặt đã bị người mua khác vượt qua. Vui lòng cập nhật giá mới.',
            $latestState
        );

        $request = Request::create('/api/v1/auctions/1/bid', 'POST');
        $response = $exception->render($request);

        $this->assertEquals(409, $response->getStatusCode());
        $payload = json_decode($response->getContent(), true);

        $this->assertFalse($payload['success']);
        $this->assertEquals('AUCTION_OUTBID_CONFLICT', $payload['error_code']);
        $this->assertEquals($latestState, $payload['latest_state']);
        $this->assertNotEmpty($payload['server_time']);
    }

    /**
     * 6. Test platform config service calculates buyer protection fee accurately (DEC-04).
     */
    public function test_platform_config_service_calculates_buyer_protection_fee_accurately(): void
    {
        $service = app(PlatformConfigService::class);
        $result = $service->calculateBuyerProtectionFee(400000);

        // 400,000 * 0.06 = 24,000 + 7,000 = 31,000 VND
        $this->assertEquals('400000.00', $result['item_subtotal']);
        $this->assertEquals('0.0600', $result['protection_fee_rate']);
        $this->assertEquals('7000.00', $result['protection_fixed_fee']);
        $this->assertEquals('31000.00', $result['buyer_protection_fee']);
        $this->assertEquals('0.00', $result['shipping_fee']);
        $this->assertEquals('431000.00', $result['total_amount']);
        $this->assertEquals('400000.00', $result['seller_net_amount']);
    }

    /**
     * 7. Test audit log service records immutable entry (BR-AD-02 / NFR-REL-04).
     */
    public function test_audit_log_service_records_immutable_entry(): void
    {
        DB::beginTransaction();
        try {
            $service = app(AuditLogService::class);
            $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();

            $log = $service->record(
                $admin,
                'SUSPEND_USER',
                'users',
                $admin->id,
                'Vi phạm chính sách nền tảng nghiêm trọng',
                ['status' => 'ACTIVE'],
                ['status' => 'SUSPENDED'],
                '127.0.0.1'
            );

            $this->assertNotNull($log->id);
            $this->assertEquals('SUSPEND_USER', $log->action);
            $this->assertEquals('admin', $log->actor_role);
            $this->assertEquals('127.0.0.1', $log->ip_address);

            // Attempt mutation - must fail
            try {
                $log->action = 'MUTATED_ACTION';
                $log->save();
                $this->fail('Expected LogicException on updating immutable audit log was not thrown.');
            } catch (\LogicException $e) {
                $this->assertStringContainsString('Immutable', $e->getMessage());
            }
        } finally {
            DB::rollBack();
        }
    }

    /**
     * 8. Test role middleware blocks unauthorized roles with 403.
     */
    public function test_role_middleware_blocks_unauthorized_roles_with_403(): void
    {
        Route::middleware(['optional.sanctum', 'role:admin,moderator'])->get('/api/v1/test-admin-route', function () {
            return ApiResponse::success(['secret' => 'admin_privileged_data']);
        });

        // 8.1. Registered User (buyer.linh) should be blocked with 403
        $buyer = User::where('email', 'buyer.linh@izithrift.local')->firstOrFail();
        $buyerToken = $buyer->createToken('buyer_role_test')->plainTextToken;

        try {
            $response = $this->withHeader('Authorization', "Bearer {$buyerToken}")
                ->getJson('/api/v1/test-admin-route');

            $response->assertStatus(403);
            $this->assertFalse($response->json('success'));
            $this->assertEquals('ROLE_PERMISSION_DENIED', $response->json('error_code'));
        } finally {
            $buyer->tokens()->delete();
        }

        // 8.2. Admin User should be allowed with 200
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $adminToken = $admin->createToken('admin_role_test')->plainTextToken;

        try {
            $response = $this->withHeader('Authorization', "Bearer {$adminToken}")
                ->getJson('/api/v1/test-admin-route');

            $response->assertStatus(200);
            $this->assertTrue($response->json('success'));
            $this->assertEquals('admin_privileged_data', $response->json('data.secret'));
        } finally {
            $admin->tokens()->delete();
        }
    }
}
