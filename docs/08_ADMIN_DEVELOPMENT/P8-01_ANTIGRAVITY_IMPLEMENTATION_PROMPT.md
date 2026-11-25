# P8-01 ANTIGRAVITY IMPLEMENTATION PROMPT – ADMIN FOUNDATION, SHELL & SESSION AUTH

## A. Task Identity
- **Project:** Retro Market (`izithrift`)
- **Phase:** Phase 08 – Laravel Blade Admin Dashboard Development
- **Work Package ID:** `P8-01`
- **Work Package Name:** Admin Foundation, Shell & Session Auth
- **Authorization:** `APPROVED` (PO Decision Log `DEC-08-01` to `DEC-08-04`)
- **Current Status:** `READY_FOR_EXECUTION`
- **Dependencies:** Phase 05–07 Baseline (`4a1171ff9087fd66365342a215e615ed001ea141`), `PHASE_08_REPOSITORY_DISCOVERY_REPORT.md`, `P8-01_PRE_IMPLEMENTATION_VERIFICATION_REPORT.md`, `P8-01_ACCEPTANCE_CRITERIA_AND_TEST_PLAN.md`.

## B. Context
- `routes/web.php` currently only contains the default welcome route; `0` Admin Web Controllers exist; `backend/node_modules/` is not yet installed.
- `config/auth.php` defines the `web` guard (`session` driver, `users` provider). `config/session.php` is configured for `redis`, while `phpunit.xml` overrides `SESSION_DRIVER=array` for standard tests.
- `bootstrap/app.php` already separates API and Web exception rendering via `$request->is('api/*') || $request->expectsJson()` — preserve this behavior without modification.
- Pre-implementation verification (`READ_ONLY_VERIFICATION_COMPLETED`) confirmed all repository prerequisites for `P8-01`.

## C. Objective
Establish the complete Laravel Blade Admin foundation (Vite 8 + Tailwind CSS v4 **Warm Editorial Archive** shell), extract and document the canonical 21-screen inventory from repository source docs, implement Session Authentication (`A-AU-01`) with Redis 7.4 runtime session verification, enforce 3-layer RBAC with Default Deny (`DEC-08-03`), implement the role-scoped Admin Dashboard screen, record immutable login/logout audit logs, and pass all `AC-P801-01`..`AC-P801-08` tests with zero regression.

## D. Exact Scope
- **Screens Implemented (2 of 21):**
  1. `A-AU-01`: Admin Login Screen.
  2. Admin Dashboard Screen (use the exact Screen ID, Name, and Route verified in `SCREEN_INVENTORY.md` & `ADMIN_WIREFRAMES.md`).
- **Features & Components:**
  - `docs/08_ADMIN_DEVELOPMENT/PHASE_08_IMPLEMENTATION_PLAN.md` (with exact 21-screen table & source references).
  - Vite 8 + Tailwind CSS v4 build (`Warm Editorial Archive` tokens: `#FBF8F3`, `#C85A32`, `#2D5A3C`, `#D4AF37`, `Fraunces`, `Be Vietnam Pro`, `tabular-nums`).
  - Master Layout (`resources/views/layouts/admin.blade.php`), Topbar (user badge, server time `Asia/Ho_Chi_Minh`, CSRF logout form), Role-aware Sidebar (links for all 21 screens gated by permissions), Flash Alert & Validation Error Bag partials.
  - Web Session Auth Controller, Login Rate Limiting, Session Regeneration, Mid-Session Suspension Revocation, and 3-Layer RBAC Middleware/Gates.
  - Role-scoped Admin Dashboard controller & view (`admin`, `moderator`, `support`).

## E. Implementation Tasks
- **TASK-P801-01 (Canonical 21-Screen Source Documentation):**
  - *Objective:* Create `docs/08_ADMIN_DEVELOPMENT/PHASE_08_IMPLEMENTATION_PLAN.md` using the exact 21 Screen IDs, Names, Routes, and Permissions extracted from `SCREEN_INVENTORY.md`, `ADMIN_WIREFRAMES.md`, and `03_ACTOR_PERMISSION_MATRIX.md`.
- **TASK-P801-02 (Frontend Dependencies & Warm Editorial Archive Theme):**
  - *Objective:* Install Node packages in `backend/` (`npm install` / `npm ci` preserving lockfile), configure Tailwind CSS v4 tokens (`#FBF8F3`, `#C85A32`, `#2D5A3C`, `#D4AF37`, `Fraunces`, `Be Vietnam Pro`, `tabular-nums`), and build assets (`npm run build`).
- **TASK-P801-03 (3-Layer RBAC Middleware & Default Deny Gate):**
  - *Objective:* Inspect `EnsureInternalRole` and existing Policies/Enums (`UserRole`). Configure Admin Shell access for active `admin`, `moderator`, and `support` users who hold at least one Admin permission (`DEC-08-03`). Implement mid-session suspension check (if an authenticated user's status in DB is `SUSPENDED`, immediately invalidate the session and deny access). Enforce Default Deny (`403`) for `registered_user` and any unauthorized screen/action.
- **TASK-P801-04 (`A-AU-01` Admin Login & Session Lifecycle):**
  - *Objective:* Implement `A-AU-01` login view and controller using `Auth::guard('web')`. Implement CSRF protection, login throttling (rate limiter with recovery after decay), `$request->session()->regenerate()` on login, safe internal-only redirect (preventing open redirects), and `$request->session()->invalidate()` + `regenerateToken()` on logout. Record immutable `AuditLog::create(...)` entries for login and logout with sensitive fields redacted.
- **TASK-P801-05 (Master Admin Shell & Role-Scoped Admin Dashboard):**
  - *Objective:* Build `layouts/admin.blade.php` and the Admin Dashboard screen. Ensure `admin` sees full platform KPIs, `moderator` sees moderation/catalog/auction metrics permitted by the matrix, and `support` sees order/dispute/report support metrics permitted by `DEC-08-03`.
- **TASK-P801-06 (Automated PHPUnit & Redis Runtime Test Suite):**
  - *Objective:* Implement and execute `P801_AdminAuthAndSessionTest.php`, `P801_AdminRbacAndDefaultDenyTest.php`, `P801_AdminAuditLogInvarianceTest.php`, and `P801_RedisSessionRuntimeTest.php`.

## F. Acceptance Criteria & G. Test Plan
Follow all 8 criteria (`AC-P801-01` to `AC-P801-08`) and the 10-case RBAC Matrix defined in `docs/08_ADMIN_DEVELOPMENT/P8-01_ACCEPTANCE_CRITERIA_AND_TEST_PLAN.md`.

## H. Database, Security, UI/UX & Regression Protection
- Zero DDL/schema changes; append-only `create()` on `audit_logs`.
- Backend baseline `88/88 PASS` (`1,043` assertions) + new `P8-01` tests = `100% PASS`.
- Mobile baseline `134/134 PASS` + `flutter analyze` `0 issues`.

## I. Completion Report & Handoff
Output a structured report with: Summary, Implemented Features, Files Created/Modified, Test Execution Logs (including independent Redis runtime log), AC Evidence Matrix (`AC-P801-01`..`08`), Git Status & `HEAD`, and Handoff readiness for **`P8-02`**.
