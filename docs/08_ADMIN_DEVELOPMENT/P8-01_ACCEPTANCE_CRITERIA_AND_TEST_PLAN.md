# P8-01 ACCEPTANCE CRITERIA AND TEST PLAN – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P801-AC-TEST-PLAN`
- **Target Work Package:** `Phase 08 – Task P8-01: Admin Foundation, Shell & Session Auth`
- **Repository Path:** `docs/08_ADMIN_DEVELOPMENT/P8-01_ACCEPTANCE_CRITERIA_AND_TEST_PLAN.md`
- **Status:** `APPROVED FOR P8-01 EXECUTION`

---

## 1. Standardized Acceptance Criteria (`AC-P801-01` to `AC-P801-08`)

- **`AC-P801-01` (Canonical 21-Screen Source Alignment – `Document Validation`):**
  - `docs/08_ADMIN_DEVELOPMENT/PHASE_08_IMPLEMENTATION_PLAN.md` documents all 21 Admin screens extracted directly from `SCREEN_INVENTORY.md` and `ADMIN_WIREFRAMES.md` with exact `Screen ID`, `Screen Name`, `Route`, `Actor`, `Permissions`, `Work Package`, and `Source Reference`.
- **`AC-P801-02` (Web Session Auth, `password_hash` Compatibility & Session Regeneration – `PHPUnit`):**
  - Valid `admin`, `moderator`, `support` (`ACTIVE`) credentials authenticate via `Auth::guard('web')`, call `$request->session()->regenerate()` (changing Session ID), and redirect to the Admin Dashboard.
  - Invalid credentials fail generically without account enumeration.
  - Logout calls `Auth::guard('web')->logout()`, `$request->session()->invalidate()`, and `$request->session()->regenerateToken()`.
- **`AC-P801-03` (Redis 7.4 Session Runtime Verification – `Runtime Verification & Integration`):**
  - Independent runtime test with `session.driver = redis` against live Redis 7.4 verifies that login writes session data to Redis, subsequent requests read it back, and logout/invalidation removes the session key from Redis without calling `FLUSHDB` or `FLUSHALL`.
- **`AC-P801-04` (CSRF Protection & Login Throttling – `PHPUnit`):**
  - With CSRF middleware explicitly active in test, `POST` login/logout without a valid `_token` returns HTTP `419`.
  - Repeated failed login attempts trigger rate limiting (`429` or throttle error) and recover after the decay period elapses.
- **`AC-P801-05` (3-Layer RBAC, Mid-Session Suspension & Default Deny – `PHPUnit`):**
  - Enforces `03_ACTOR_PERMISSION_MATRIX.md` and `DEC-08-03` across `admin`, `moderator`, `support`, and `registered_user`.
  - Denies `registered_user` (`403`) and `SUSPENDED` accounts. If an active session's user becomes `SUSPENDED` mid-session, the next request immediately invalidates the session and denies access.
  - Dashboard renders role-scoped metrics (`support` sees only permitted support metrics and receives `403` on admin/moderator routes). Default Deny (`403`) applies to any undefined or ungranted permission.
- **`AC-P801-06` (Audit Logging, Redaction & Immutability – `PHPUnit`):**
  - Login and logout create append-only records in `audit_logs` with zero sensitive fields (`password`, `password_hash`, `_token`, session token). Calling `update()` or `delete()` on `AuditLog` is blocked by `ImmutableLedgerRecord`.
- **`AC-P801-07` (Web/Sanctum Isolation – `Integration`):**
  - Admin web login/logout does not revoke Sanctum personal access tokens; unauthenticated `/admin/*` returns `302` HTML redirect while `/api/v1/*` returns `401` JSON Envelope.
- **`AC-P801-08` (Security & Full Regression Baseline – `Regression Suite`):**
  - Blocks external `url.intended` open redirects; sets `HttpOnly` session cookies; preserves `88/88` Backend tests (`1,043` assertions), `db:verify-constraints`, `134/134` Flutter tests, and `0` Flutter analyze issues.

## 2. Proposed Test File Structure for `P8-01`
- `backend/tests/Feature/Admin/P801_AdminAuthAndSessionTest.php`
- `backend/tests/Feature/Admin/P801_AdminRbacAndDefaultDenyTest.php`
- `backend/tests/Feature/Admin/P801_AdminAuditLogInvarianceTest.php`
- `backend/tests/Feature/Admin/P801_RedisSessionRuntimeTest.php`
