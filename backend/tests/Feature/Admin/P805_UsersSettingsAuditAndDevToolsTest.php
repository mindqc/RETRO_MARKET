<?php

namespace Tests\Feature\Admin;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\AuditLog;
use App\Models\PlatformSetting;
use App\Models\User;
use App\Services\Governance\PlatformConfigService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class P805_UsersSettingsAuditAndDevToolsTest extends TestCase
{
    use DatabaseTransactions;

    protected User $admin;
    protected User $moderator;
    protected User $support;
    protected User $buyer;
    protected User $seller;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $this->moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();
        $this->support = User::where('email', 'support@izithrift.local')->firstOrFail();

        $this->seller = User::whereHas('sellerProfile')->where('role', UserRole::REGISTERED_USER)->firstOrFail();
        $this->buyer = User::where('role', UserRole::REGISTERED_USER)->where('id', '!=', $this->seller->id)->firstOrFail();
    }

    /**
     * AC-P805-01: Admin and Staff can view users list and search/filter (Screen A-US-01).
     */
    public function test_admin_and_staff_can_view_users_list_and_search_filter(): void
    {
        $adminRes = $this->actingAs($this->admin)->get('/admin/users');
        $adminRes->assertStatus(200);
        $adminRes->assertSee('Quản lý Người dùng & Nhân sự');

        $suppRes = $this->actingAs($this->support)->get('/admin/users?role=registered_user&status=ACTIVE');
        $suppRes->assertStatus(200);

        // Regular user receives 403 Forbidden
        $userRes = $this->actingAs($this->buyer)->get('/admin/users');
        $userRes->assertStatus(403);
    }

    /**
     * AC-P805-01: Admin can view User 360° profile inspector (Screen A-US-02).
     */
    public function test_admin_can_view_user_360_profile_inspector(): void
    {
        $response = $this->actingAs($this->admin)->get("/admin/users/{$this->seller->id}");
        $response->assertStatus(200);
        $response->assertSee($this->seller->display_name);
        $response->assertSee('Hồ sơ 360°');
        $response->assertSee('Kênh Bán hàng (Seller Shop Dimension)');
    }

    /**
     * AC-P805-01: Admin can suspend and unsuspend user with audit trail (DEC-08-02).
     */
    public function test_admin_can_suspend_and_unsuspend_user_with_audit_trail(): void
    {
        // 1. Suspend target user
        $suspendRes = $this->actingAs($this->admin)->post("/admin/users/{$this->buyer->id}/status", [
            'status' => 'SUSPENDED',
            'reason' => 'Vi phạm quy chế sàn Retro Market nhiều lần.',
        ]);

        $suspendRes->assertRedirect("/admin/users/{$this->buyer->id}");
        $suspendRes->assertSessionHas('success');

        $freshBuyer = $this->buyer->fresh();
        $this->assertEquals(UserStatus::SUSPENDED, $freshBuyer->status);
        $this->assertEquals('Vi phạm quy chế sàn Retro Market nhiều lần.', $freshBuyer->status_reason);

        // Verify audit log
        $this->assertDatabaseHas('audit_logs', [
            'actor_id' => $this->admin->id,
            'action' => 'UPDATE_ACCOUNT_STATUS',
            'target_type' => 'users',
            'target_id' => $this->buyer->id,
        ]);

        // 2. Unsuspend user
        $activateRes = $this->actingAs($this->admin)->post("/admin/users/{$this->buyer->id}/status", [
            'status' => 'ACTIVE',
            'reason' => 'Người dùng đã giải trình thỏa đáng, mở khóa tài khoản.',
        ]);

        $activateRes->assertRedirect("/admin/users/{$this->buyer->id}");
        $activateRes->assertSessionHas('success');
        $this->assertEquals(UserStatus::ACTIVE, $this->buyer->fresh()->status);
    }

    /**
     * AC-P805-01: Invariant self-suspension and last active admin protection.
     */
    public function test_self_suspension_and_last_admin_protection_invariants(): void
    {
        // Admin cannot suspend themselves
        $selfRes = $this->actingAs($this->admin)->post("/admin/users/{$this->admin->id}/status", [
            'status' => 'SUSPENDED',
            'reason' => 'Admin cố gắng tự khóa tài khoản của chính mình.',
        ]);

        $selfRes->assertSessionHas('error');
        $this->assertEquals(UserStatus::ACTIVE, $this->admin->fresh()->status);
    }

    /**
     * AC-P805-01: Admin can update user role (DEC-08-02).
     */
    public function test_admin_can_update_user_role_dec08_02(): void
    {
        $response = $this->actingAs($this->admin)->post("/admin/users/{$this->buyer->id}/role", [
            'role' => 'moderator',
            'reason' => 'Bổ nhiệm người dùng làm kiểm duyệt viên danh mục.',
        ]);

        $response->assertRedirect("/admin/users/{$this->buyer->id}");
        $response->assertSessionHas('success');

        $freshBuyer = $this->buyer->fresh();
        $this->assertEquals(UserRole::MODERATOR, $freshBuyer->role);

        // Verify audit log
        $this->assertDatabaseHas('audit_logs', [
            'actor_id' => $this->admin->id,
            'action' => 'UPDATE_USER_ROLE',
            'target_type' => 'users',
            'target_id' => $this->buyer->id,
        ]);
    }

    /**
     * AC-P805-01: Invariant self-demotion is rejected.
     */
    public function test_self_demotion_invariant_is_rejected(): void
    {
        $selfRes = $this->actingAs($this->admin)->post("/admin/users/{$this->admin->id}/role", [
            'role' => 'registered_user',
            'reason' => 'Admin cố gắng tự hạ quyền của chính mình.',
        ]);

        $selfRes->assertSessionHas('error');
        $this->assertEquals(UserRole::ADMIN, $this->admin->fresh()->role);
    }

    /**
     * AC-P805-01: Support role receives 403 Forbidden on user mutations.
     */
    public function test_support_role_receives_403_on_mutations(): void
    {
        $statusRes = $this->actingAs($this->support)->post("/admin/users/{$this->buyer->id}/status", [
            'status' => 'SUSPENDED',
            'reason' => 'Support cố gắng khóa tài khoản trái thẩm quyền.',
        ]);
        $statusRes->assertStatus(403);

        $roleRes = $this->actingAs($this->support)->post("/admin/users/{$this->buyer->id}/role", [
            'role' => 'admin',
            'reason' => 'Support cố gắng thăng cấp tài khoản trái thẩm quyền.',
        ]);
        $roleRes->assertStatus(403);
    }

    /**
     * AC-P805-02: Admin can view and update platform settings (Screen A-ST-01 / DEC-08-02).
     */
    public function test_admin_can_view_and_update_platform_settings_dec08_02(): void
    {
        // 1. Admin accesses settings screen
        $viewRes = $this->actingAs($this->admin)->get('/admin/settings');
        $viewRes->assertStatus(200);
        $viewRes->assertSee('Cấu hình Nền tảng');
        $viewRes->assertSee('Biểu phí Sàn & Doanh thu');

        // 2. Non-admin roles receive 403 Forbidden
        $modRes = $this->actingAs($this->moderator)->get('/admin/settings');
        $modRes->assertStatus(403);

        $suppRes = $this->actingAs($this->support)->get('/admin/settings');
        $suppRes->assertStatus(403);

        // 3. Admin updates protection fee rate and fixed fee
        $updateRes = $this->actingAs($this->admin)->post('/admin/settings', [
            'settings' => [
                'protection_fee_rate' => '0.0700',
                'protection_fixed_fee' => '8000.00',
            ],
            'reason' => 'Điều chỉnh phí bảo vệ người mua theo phê duyệt của PO.',
        ]);

        $updateRes->assertRedirect('/admin/settings');
        $updateRes->assertSessionHas('success');

        // Verify database and cache
        $this->assertEquals('0.0700', PlatformSetting::getValue('protection_fee_rate'));
        $this->assertEquals(8000.00, (float) PlatformSetting::getValue('protection_fixed_fee'));

        /** @var PlatformConfigService $configService */
        $configService = app(PlatformConfigService::class);
        $this->assertEquals(0.07, $configService->protectionFeeRate());
        $this->assertEquals(8000.0, $configService->protectionFixedFee());

        // Verify audit log
        $this->assertDatabaseHas('audit_logs', [
            'actor_id' => $this->admin->id,
            'action' => 'UPDATE_PLATFORM_SETTING',
            'target_type' => 'platform_settings',
        ]);
    }

    /**
     * AC-P805-02: Platform settings validation rejects out-of-bounds values.
     */
    public function test_platform_settings_validation_rejects_out_of_bounds_values(): void
    {
        // protection_fee_rate out of bounds (> 0.08)
        $invalidRateRes = $this->actingAs($this->admin)->post('/admin/settings', [
            'settings' => [
                'protection_fee_rate' => '0.1500',
            ],
            'reason' => 'Cố gắng đặt tỷ lệ phí trái phép.',
        ]);
        $invalidRateRes->assertSessionHas('error');

        // protection_fixed_fee out of bounds (< 5000)
        $invalidFixedRes = $this->actingAs($this->admin)->post('/admin/settings', [
            'settings' => [
                'protection_fixed_fee' => '1000.00',
            ],
            'reason' => 'Cố gắng đặt phí cố định trái phép.',
        ]);
        $invalidFixedRes->assertSessionHas('error');
    }

    /**
     * AC-P805-03: Admin can view and filter audit logs (Screen A-AD-01, Strict Read-Only).
     */
    public function test_admin_can_view_and_filter_audit_logs_read_only(): void
    {
        // Generate an audit log
        AuditLog::create([
            'actor_id' => $this->admin->id,
            'actor_role' => 'admin',
            'action' => 'TEST_P805_INSPECTION',
            'target_type' => 'SYSTEM',
            'target_id' => null,
            'reason' => 'Kiểm tra trình tra cứu nhật ký kiểm toán.',
            'old_values' => ['sample' => 'old'],
            'new_values' => ['sample' => 'new'],
            'ip_address' => '127.0.0.1',
        ]);

        $adminRes = $this->actingAs($this->admin)->get('/admin/audit-logs');
        $adminRes->assertStatus(200);
        $adminRes->assertSee('Nhật ký Kiểm toán Hoạt động Quản trị');
        $adminRes->assertSee('TEST_P805_INSPECTION');

        // Moderator and Support receive 403 Forbidden
        $modRes = $this->actingAs($this->moderator)->get('/admin/audit-logs');
        $modRes->assertStatus(403);

        $suppRes = $this->actingAs($this->support)->get('/admin/audit-logs');
        $suppRes->assertStatus(403);
    }

    /**
     * AC-P805-04: Developer Tools Dual-Gate Security (Admin Role + DEMO_MODE=true) (Screen A-DT-01).
     */
    public function test_dual_gate_security_developer_tools_admin_with_demo_mode_true(): void
    {
        config(['retromarket.demo_mode' => true]);

        // 1. Admin accesses Developer Tools screen
        $viewRes = $this->actingAs($this->admin)->get('/admin/dev-tools');
        $viewRes->assertStatus(200);
        $viewRes->assertSee('DUAL-GATE SECURITY: DEMO MODE ACTIVE');
        $viewRes->assertSee('DEMO_MODE=true');

        // 2. Admin triggers OPEN_SCHEDULED_AUCTIONS
        $openRes = $this->actingAs($this->admin)->post('/admin/dev-tools/trigger', [
            'action_key' => 'OPEN_SCHEDULED_AUCTIONS',
        ]);
        $openRes->assertRedirect('/admin/dev-tools');
        $openRes->assertSessionHas('success');

        // 3. Admin triggers CLOSE_EXPIRED_AUCTIONS
        $closeRes = $this->actingAs($this->admin)->post('/admin/dev-tools/trigger', [
            'action_key' => 'CLOSE_EXPIRED_AUCTIONS',
        ]);
        $closeRes->assertRedirect('/admin/dev-tools');
        $closeRes->assertSessionHas('success');

        // 4. Admin triggers EXPIRE_UNPAID_ORDERS
        $unpaidRes = $this->actingAs($this->admin)->post('/admin/dev-tools/trigger', [
            'action_key' => 'EXPIRE_UNPAID_ORDERS',
        ]);
        $unpaidRes->assertRedirect('/admin/dev-tools');
        $unpaidRes->assertSessionHas('success');

        // 5. Admin triggers AUTO_COMPLETE_DELIVERED_ORDERS
        $autoCompleteRes = $this->actingAs($this->admin)->post('/admin/dev-tools/trigger', [
            'action_key' => 'AUTO_COMPLETE_DELIVERED_ORDERS',
        ]);
        $autoCompleteRes->assertRedirect('/admin/dev-tools');
        $autoCompleteRes->assertSessionHas('success');

        // 6. Admin triggers RUN_ALL_LIFECYCLE_JOBS
        $allRes = $this->actingAs($this->admin)->post('/admin/dev-tools/trigger', [
            'action_key' => 'RUN_ALL_LIFECYCLE_JOBS',
        ]);
        $allRes->assertRedirect('/admin/dev-tools');
        $allRes->assertSessionHas('success');

        // Verify Audit Log records
        $this->assertDatabaseHas('audit_logs', [
            'actor_id' => $this->admin->id,
            'action' => 'DEVTOOLS_MANUAL_JOB_TRIGGER',
        ]);
    }

    /**
     * AC-P805-04: Developer Tools Dual-Gate Security rejects non-admin roles even when DEMO_MODE=true.
     */
    public function test_dual_gate_security_developer_tools_rejects_non_admin_roles(): void
    {
        config(['retromarket.demo_mode' => true]);

        // Moderator receives 403 Forbidden
        $modGetRes = $this->actingAs($this->moderator)->get('/admin/dev-tools');
        $modGetRes->assertStatus(403);

        $modPostRes = $this->actingAs($this->moderator)->post('/admin/dev-tools/trigger', [
            'action_key' => 'OPEN_SCHEDULED_AUCTIONS',
        ]);
        $modPostRes->assertStatus(403);

        // Support receives 403 Forbidden
        $suppGetRes = $this->actingAs($this->support)->get('/admin/dev-tools');
        $suppGetRes->assertStatus(403);

        $suppPostRes = $this->actingAs($this->support)->post('/admin/dev-tools/trigger', [
            'action_key' => 'OPEN_SCHEDULED_AUCTIONS',
        ]);
        $suppPostRes->assertStatus(403);

        // Registered User receives 403 Forbidden
        $userGetRes = $this->actingAs($this->buyer)->get('/admin/dev-tools');
        $userGetRes->assertStatus(403);
    }

    /**
     * AC-P805-04: Developer Tools Dual-Gate Security rejects Admin when DEMO_MODE=false.
     */
    public function test_dual_gate_security_developer_tools_rejects_admin_when_demo_mode_false(): void
    {
        config(['retromarket.demo_mode' => false]);

        $getRes = $this->actingAs($this->admin)->get('/admin/dev-tools');
        $getRes->assertStatus(403);

        $postRes = $this->actingAs($this->admin)->post('/admin/dev-tools/trigger', [
            'action_key' => 'OPEN_SCHEDULED_AUCTIONS',
        ]);
        $postRes->assertStatus(403);
    }
}
