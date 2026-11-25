<?php

namespace Tests\Feature\Admin;

use App\Models\AuditLog;
use App\Models\User;
use LogicException;
use Tests\TestCase;

class P801_AdminAuditLogInvarianceTest extends TestCase
{
    /**
     * Test admin login and logout generate immutable audit logs with zero sensitive data.
     */
    public function test_login_and_logout_create_immutable_audit_logs(): void
    {
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();

        // 1. Perform Login
        $this->get('/admin/login');
        $this->post('/admin/login', [
            '_token' => csrf_token(),
            'email' => 'admin@izithrift.local',
            'password' => 'Retro@2026',
        ]);

        // Verify ADMIN_LOGIN audit log
        $loginLog = AuditLog::where('actor_id', $admin->id)
            ->where('action', 'ADMIN_LOGIN')
            ->latest('id')
            ->first();

        $this->assertNotNull($loginLog, 'ADMIN_LOGIN audit log must be recorded.');
        $this->assertEquals('User', $loginLog->target_type);
        $this->assertEquals($admin->id, $loginLog->target_id);
        $this->assertEquals('admin', $loginLog->actor_role);

        // Verify zero sensitive data is recorded
        $newValues = $loginLog->new_values ?? [];
        $this->assertArrayNotHasKey('password', $newValues);
        $this->assertArrayNotHasKey('password_hash', $newValues);
        $this->assertArrayNotHasKey('_token', $newValues);
        $this->assertArrayNotHasKey('session_id', $newValues);
        $this->assertArrayHasKey('ip', $newValues);
        $this->assertArrayHasKey('user_agent', $newValues);

        // 2. Perform Logout
        $this->post('/admin/logout', [
            '_token' => csrf_token(),
        ]);

        // Verify ADMIN_LOGOUT audit log
        $logoutLog = AuditLog::where('actor_id', $admin->id)
            ->where('action', 'ADMIN_LOGOUT')
            ->latest('id')
            ->first();

        $this->assertNotNull($logoutLog, 'ADMIN_LOGOUT audit log must be recorded.');
        $this->assertEquals('User', $logoutLog->target_type);
        $this->assertEquals($admin->id, $logoutLog->target_id);

        // 3. Test Immutability: update() is blocked by ImmutableLedgerRecord
        try {
            $loginLog->update(['action' => 'TAMPERED_ACTION']);
            $this->fail('Expected LogicException was not thrown on update() of immutable audit log.');
        } catch (LogicException $e) {
            $this->assertStringContainsString('Immutable ledger/audit record cannot be updated or deleted', $e->getMessage());
        }

        // 4. Test Immutability: delete() is blocked by ImmutableLedgerRecord
        try {
            $loginLog->delete();
            $this->fail('Expected LogicException was not thrown on delete() of immutable audit log.');
        } catch (LogicException $e) {
            $this->assertStringContainsString('Immutable ledger/audit record cannot be updated or deleted', $e->getMessage());
        }
    }
}
