<?php

namespace Tests\Feature\Admin;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\RateLimiter;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

class P801_AdminAuthAndSessionTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        // Ensure clean rate limiter state for tests
        RateLimiter::clear('admin_login:admin@izithrift.local|127.0.0.1');
        RateLimiter::clear('admin_login:invalid@izithrift.local|127.0.0.1');
    }

    /**
     * Test admin login page renders correctly (Screen A-AU-01).
     */
    public function test_admin_login_page_renders_successfully(): void
    {
        $response = $this->get('/admin/login');

        $response->assertStatus(200);
        $response->assertSee('izithrift');
        $response->assertSee('Đăng nhập nhân sự');
        $response->assertSee('Email công vụ');
        $response->assertSee('Mật khẩu');
    }

    /**
     * Test AC-P801-07: CSRF protection returns 419 when token is missing or invalid.
     */
    public function test_login_without_csrf_token_returns_419(): void
    {
        $this->app->bind(
            \Illuminate\Foundation\Http\Middleware\PreventRequestForgery::class,
            function ($app) {
                return new class($app, $app['encrypter']) extends \Illuminate\Foundation\Http\Middleware\PreventRequestForgery {
                    protected function runningUnitTests(): bool
                    {
                        return false;
                    }
                };
            }
        );

        $response = $this->post('/admin/login', [
            'email' => 'admin@izithrift.local',
            'password' => 'Retro@2026',
        ]);

        $response->assertStatus(419);
    }

    /**
     * Test AC-P801-02: Successful authentication with session regeneration.
     */
    public function test_admin_successful_login_and_session_regeneration(): void
    {
        $this->get('/admin/login');
        $initialSessionId = session()->getId();

        $response = $this->post('/admin/login', [
            '_token' => csrf_token(),
            'email' => 'admin@izithrift.local',
            'password' => 'Retro@2026',
        ]);

        $response->assertRedirect('/admin/dashboard');
        $this->assertAuthenticatedAs(User::where('email', 'admin@izithrift.local')->first(), 'web');

        // Verify session ID has been regenerated (session fixation prevention)
        $newSessionId = session()->getId();
        $this->assertNotEmpty($newSessionId);
        $this->assertNotEquals($initialSessionId, $newSessionId);
    }

    /**
     * Test invalid password produces generic error without user enumeration.
     */
    public function test_invalid_credentials_returns_generic_error(): void
    {
        $this->get('/admin/login');

        $response = $this->from('/admin/login')->post('/admin/login', [
            '_token' => csrf_token(),
            'email' => 'admin@izithrift.local',
            'password' => 'WrongPassword!123',
        ]);

        $response->assertRedirect('/admin/login');
        $response->assertSessionHasErrors(['email' => 'Thông tin đăng nhập không chính xác.']);
        $this->assertGuest('web');
    }

    /**
     * Test non-existent user produces same generic error without enumeration.
     */
    public function test_non_existent_email_returns_generic_error(): void
    {
        $this->get('/admin/login');

        $response = $this->from('/admin/login')->post('/admin/login', [
            '_token' => csrf_token(),
            'email' => 'nonexistent@izithrift.internal',
            'password' => 'AnyPassword@123',
        ]);

        $response->assertRedirect('/admin/login');
        $response->assertSessionHasErrors(['email' => 'Thông tin đăng nhập không chính xác.']);
        $this->assertGuest('web');
    }

    /**
     * Test AC-P801-04: Login throttling triggers after 5 failed attempts.
     */
    public function test_login_throttling_triggers_after_5_failed_attempts(): void
    {
        $throttleEmail = 'admin@izithrift.local';

        for ($i = 1; $i <= 5; $i++) {
            $this->get('/admin/login');
            $response = $this->from('/admin/login')->post('/admin/login', [
                '_token' => csrf_token(),
                'email' => $throttleEmail,
                'password' => 'BadPass_' . $i,
            ]);

            $response->assertRedirect('/admin/login');
            $response->assertSessionHasErrors(['email' => 'Thông tin đăng nhập không chính xác.']);
        }

        // 6th attempt must be throttled
        $this->get('/admin/login');
        $response6 = $this->from('/admin/login')->post('/admin/login', [
            '_token' => csrf_token(),
            'email' => $throttleEmail,
            'password' => 'BadPass_6',
        ]);

        $response6->assertRedirect('/admin/login');
        $response6->assertSessionHasErrors('email');
        $errors = session('errors')->get('email');
        $this->assertTrue(
            str_contains($errors[0], 'seconds') || str_contains($errors[0], 'giây') || str_contains($errors[0], '59') || str_contains($errors[0], '60'),
            'Expected throttling message to indicate time in seconds.'
        );

        // Cleanup rate limiter
        RateLimiter::clear('admin_login:' . $throttleEmail . '|127.0.0.1');
    }

    /**
     * Test open redirect protection forces intended URLs to stay under /admin.
     */
    public function test_open_redirect_protection_blocks_external_urls(): void
    {
        $this->get('/admin/login');
        session()->put('url.intended', 'https://malicious-phishing.com/steal-creds');

        $response = $this->post('/admin/login', [
            '_token' => csrf_token(),
            'email' => 'admin@izithrift.local',
            'password' => 'Retro@2026',
        ]);

        // Must NOT redirect to external phishing site; must redirect to /admin/dashboard
        $response->assertRedirect(route('admin.dashboard'));
    }

    /**
     * Test valid internal intended URL under /admin is honored.
     */
    public function test_internal_intended_url_under_admin_is_honored(): void
    {
        $this->get('/admin/login');
        session()->put('url.intended', url('/admin/dashboard'));

        $response = $this->post('/admin/login', [
            '_token' => csrf_token(),
            'email' => 'admin@izithrift.local',
            'password' => 'Retro@2026',
        ]);

        $response->assertRedirect(url('/admin/dashboard'));
    }

    /**
     * Test AC-P801-08: Web session login/logout does NOT create or affect Sanctum tokens.
     */
    public function test_sanctum_token_isolation_from_web_session(): void
    {
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();
        $initialTokenCount = PersonalAccessToken::where('tokenable_id', $admin->id)->count();

        // Perform Web Session Login
        $this->get('/admin/login');
        $this->post('/admin/login', [
            '_token' => csrf_token(),
            'email' => 'admin@izithrift.local',
            'password' => 'Retro@2026',
        ]);

        // Verify no new Sanctum token was created
        $this->assertEquals(
            $initialTokenCount,
            PersonalAccessToken::where('tokenable_id', $admin->id)->count(),
            'Web admin login must not create Sanctum tokens.'
        );

        // Perform Web Session Logout
        $this->post('/admin/logout', ['_token' => csrf_token()]);

        // Verify tokens unchanged
        $this->assertEquals(
            $initialTokenCount,
            PersonalAccessToken::where('tokenable_id', $admin->id)->count(),
            'Web admin logout must not delete Sanctum tokens.'
        );
    }

    /**
     * Test logout terminates session and redirects to login.
     */
    public function test_logout_terminates_session(): void
    {
        $admin = User::where('email', 'admin@izithrift.local')->firstOrFail();

        $this->actingAs($admin, 'web');
        $this->assertTrue(Auth::guard('web')->check());

        $response = $this->post('/admin/logout', [
            '_token' => csrf_token(),
        ]);

        $response->assertRedirect(route('admin.login'));
        $this->assertFalse(Auth::guard('web')->check());
    }
}
