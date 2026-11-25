<?php

namespace Tests\Feature\Admin;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Tests\TestCase;

class P801_AdminRbacAndDefaultDenyTest extends TestCase
{
    /**
     * 1. Test Admin can access dashboard (200 OK).
     */
    public function test_admin_can_access_dashboard(): void
    {
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();

        $response = $this->actingAs($admin, 'web')->get('/admin/dashboard');

        $response->assertStatus(200);
        $response->assertSee('Bảng điều khiển Vận hành');
        $response->assertSee('Tổng GMV hoàn tất');
    }

    /**
     * 2. Test Admin can access settings (200 OK).
     */
    public function test_admin_can_access_settings(): void
    {
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();

        $response = $this->actingAs($admin, 'web')->get('/admin/settings');

        $response->assertStatus(200);
        $response->assertSee('Cấu hình Nền tảng');
    }

    /**
     * 3. Test Moderator can access dashboard (200 OK).
     */
    public function test_moderator_can_access_dashboard(): void
    {
        $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();

        $response = $this->actingAs($moderator, 'web')->get('/admin/dashboard');

        $response->assertStatus(200);
        $response->assertSee('Kiểm duyệt viên');
        $response->assertSee('Sản phẩm chờ duyệt');
        // GMV / Financial metrics must NOT be visible to Moderator
        $response->assertDontSee('Tổng GMV hoàn tất');
    }

    /**
     * 4. Test Moderator can access products moderation (200 OK).
     */
    public function test_moderator_can_access_products(): void
    {
        $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();

        $response = $this->actingAs($moderator, 'web')->get('/admin/products');

        $response->assertStatus(200);
        $response->assertSee('Kho Sản phẩm');
    }

    /**
     * 5. Test Moderator is BLOCKED from settings (403 Default Deny).
     */
    public function test_moderator_is_blocked_from_settings(): void
    {
        $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();

        $response = $this->actingAs($moderator, 'web')->get('/admin/settings');

        $response->assertStatus(403);
    }

    /**
     * 6. Test Moderator is BLOCKED from orders financial escrow (403 Default Deny).
     */
    public function test_moderator_is_blocked_from_orders(): void
    {
        $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();

        $response = $this->actingAs($moderator, 'web')->get('/admin/orders');

        $response->assertStatus(403);
    }

    /**
     * 7. Test Support Staff can access dashboard (200 OK).
     */
    public function test_support_can_access_dashboard(): void
    {
        $support = User::where('email', 'support@izithrift.local')->firstOrFail();

        $response = $this->actingAs($support, 'web')->get('/admin/dashboard');

        $response->assertStatus(200);
        $response->assertSee('Khiếu nại mở cần xử lý');
        // GMV must NOT be visible to Support
        $response->assertDontSee('Tổng GMV hoàn tất');
    }

    /**
     * 8. Test Support Staff can access orders (200 OK).
     */
    public function test_support_can_access_orders(): void
    {
        $support = User::where('email', 'support@izithrift.local')->firstOrFail();

        $response = $this->actingAs($support, 'web')->get('/admin/orders');

        $response->assertStatus(200);
        $response->assertSee('Quản lý Đơn hàng & Escrow');
    }

    /**
     * 9. Test Support Staff is BLOCKED from platform settings (403 Default Deny).
     */
    public function test_support_is_blocked_from_settings(): void
    {
        $support = User::where('email', 'support@izithrift.local')->firstOrFail();

        $response = $this->actingAs($support, 'web')->get('/admin/settings');

        $response->assertStatus(403);
    }

    /**
     * 10. Test Support Staff is BLOCKED from catalog product moderation (403 Default Deny).
     */
    public function test_support_is_blocked_from_product_moderation(): void
    {
        $support = User::where('email', 'support@izithrift.local')->firstOrFail();

        $response = $this->actingAs($support, 'web')->get('/admin/products');

        $response->assertStatus(403);
    }

    /**
     * 11. Test Registered User is Default Denied from all admin routes (403).
     */
    public function test_registered_user_is_strictly_default_denied(): void
    {
        $buyer = User::where('role', UserRole::REGISTERED_USER)->firstOrFail();

        $response = $this->actingAs($buyer, 'web')->get('/admin/dashboard');

        $response->assertStatus(403);
        $this->assertFalse(Auth::guard('web')->check(), 'Session should be revoked for non-staff user.');
    }

    /**
     * 12. Test Mid-Session Suspension Revocation.
     * When an active staff member is suspended mid-session, their active session
     * must be immediately terminated on the very next request.
     */
    public function test_mid_session_suspension_revocation(): void
    {
        $moderator = User::where('email', 'moderator@izithrift.local')->firstOrFail();

        // 1. Authenticate with active status
        $this->actingAs($moderator, 'web');
        $this->get('/admin/dashboard')->assertStatus(200);

        // 2. Staff is suspended externally (e.g. by super admin)
        $moderator->update([
            'status' => UserStatus::SUSPENDED,
            'status_reason' => 'Security review triggered mid-session',
        ]);

        try {
            // 3. Next request must be rejected and session terminated
            $response = $this->get('/admin/dashboard');

            $response->assertRedirect(route('admin.login'));
            $this->assertFalse(Auth::guard('web')->check(), 'Suspended user must be logged out immediately.');
        } finally {
            // Restore status
            $moderator->update([
                'status' => UserStatus::ACTIVE,
                'status_reason' => null,
            ]);
        }
    }
}
