# P8-05 ANTIGRAVITY IMPLEMENTATION PROMPT – USERS, SETTINGS, AUDIT LOGS & DEVELOPER TOOLS

## A. Task Identity
- **Project:** Retro Market (`izithrift`)
- **Phase:** Phase 08 – Laravel Blade Admin Dashboard Development
- **Work Package ID:** `P8-05`
- **Work Package Name:** Users, Settings, Audit Logs & Developer Tools
- **Authorization:** `APPROVED` (Sequential Execution after `P8-04` PASS)
- **Current Status:** `READY_AFTER_P8_04`
- **Dependencies:** `P8-01`..`P8-04` Completed & Verified; `PlatformConfigService`, `SystemDevToolsService::triggerJobAction()`, 4 Background Jobs (`P6-09`), and `DEC-08-02` (Conditional approval for User Role Governance and `platform_settings` Update).

## B. Context
- Users follow Unified Account (`BR-AC-01`) with 4 static `UserRole` enum values (`registered_user`, `moderator`, `support`, `admin`).
- Platform configuration is stored in the `platform_settings` table and read via `PlatformConfigService`.
- `audit_logs` is strictly append-only (`ImmutableLedgerRecord`).
- `SystemDevToolsService::triggerJobAction()` already exists to trigger the 4 idempotent background jobs (`OpenScheduledAuctionsJob`, `CloseExpiredAuctionsJob`, `ExpireUnpaidAuctionOrdersJob`, `AutoCompleteDeliveredOrdersJob`) gated by `admin` role and `DEMO_MODE=true`.

## C. Objective
Implement the final 5 canonical Admin screens (`A-US-01`, `A-US-02`, `A-ST-01`, `A-AD-01`, `A-DT-01`), completing all 21/21 Admin screens with controlled User Role Governance and `platform_settings` updates (`DEC-08-02`), immutable Audit Log exploration, and dual-gated Developer Tools (`A-DT-01`).

## D. Exact Scope
- **Screens Implemented (5 of 21 — completing 21/21):**
  1. `A-US-01`: User Management List (verify exact name & route in `PHASE_08_IMPLEMENTATION_PLAN.md`).
  2. `A-US-02`: User Detail, Account Suspension & Role Governance (`DEC-08-02`).
  3. `A-ST-01`: Platform Settings (`platform_settings` management – `DEC-08-02`).
  4. `A-AD-01`: Audit Logs Explorer (Read-Only Append-Only inspector).
  5. `A-DT-01`: Developer Tools & Manual Job Triggers (`VERIFIED` ID).

## E. Implementation Tasks
- **TASK-P805-01 (Repository Inspection for User Governance, `PlatformConfigService` & `SystemDevToolsService`):**
  - Inspect `User`, `UserPolicy`, `PlatformConfigService` (`platform_settings` schema), `AuditLog`, and `SystemDevToolsService`. If methods for updating `UserRole`/status or updating `platform_settings` do not yet exist, implement controlled methods under `DEC-08-02` with:
    - Self-protection invariants (an Admin cannot demote or suspend their own account or remove the last active `admin`),
    - `DB::transaction()` and `lockForUpdate()`,
    - Cache invalidation on `PlatformConfigService` after updating `platform_settings`,
    - Mandatory `AuditLog::create(...)` with `old_values` and `new_values` snapshots.
- **TASK-P805-02 (`A-US-01` & `A-US-02` User Management & Role/Status Governance):**
  - Implement `A-US-01` (search, filter by `UserRole` and status `ACTIVE`/`SUSPENDED`) and `A-US-02` (360° user & shop detail, `trust_score`, auction default count `WINNER_DEFAULTED`, wallet/escrow summary, plus `admin`-only forms to Suspend/Unsuspend account or change `UserRole` with mandatory reason).
- **TASK-P805-03 (`A-ST-01` Platform Settings Screen):**
  - Implement `A-ST-01` (`admin` only) displaying and updating existing keys in `platform_settings` (such as `DEC-04` fee parameters, auction anti-sniping/payment timers, seasonal decor toggle) with strict numeric/type validation and audit logging.
- **TASK-P805-04 (`A-AD-01` Immutable Audit Logs Explorer):**
  - Implement `A-AD-01` (`admin` only, strictly read-only) with filters by actor, action type, target entity, and date range, displaying structured JSON diff (`old_values` vs `new_values`) without any edit/delete capability.
- **TASK-P805-05 (`A-DT-01` Developer Tools & Manual Job Triggers):**
  - Implement `A-DT-01` strictly restricted to `UserRole::ADMIN` AND `DEMO_MODE=true`. Wire the 4 manual trigger actions exclusively through `SystemDevToolsService::triggerJobAction()` for `OpenScheduledAuctionsJob`, `CloseExpiredAuctionsJob`, `ExpireUnpaidAuctionOrdersJob`, and `AutoCompleteDeliveredOrdersJob`, recording an `AuditLog` entry on every trigger.
- **TASK-P805-06 (`P8-05` Automated Feature, Security & Invariance Tests):**
  - Create `tests/Feature/Admin/P805_UsersSettingsAuditAndDevToolsTest.php` verifying `A-US-01..02`, `A-ST-01`, `A-AD-01`, and `A-DT-01`.

## F. Acceptance Criteria
- **`AC-P805-01` (`A-US-01`, `A-US-02` & `DEC-08-02`):** `admin` can suspend/unsuspend users and update `UserRole` with mandatory reason and `audit_logs` entry; self-suspension/self-demotion is blocked; suspended user's active web session or mobile access is blocked (`403`); `support` has read-only view (if permitted by matrix) and receives `403` on mutations.
- **`AC-P805-02` (`A-ST-01` & `DEC-08-02`):** `admin` can update valid `platform_settings` entries, refreshing `PlatformConfigService` cache and logging old/new values to `audit_logs`; invalid numeric values fail validation; non-admin roles receive `403`.
- **`AC-P805-03` (`A-AD-01`):** `admin` can filter and inspect `audit_logs` records; zero routes or methods allow modifying or deleting `audit_logs`.
- **`AC-P805-04` (Developer Tools Dual-Gate Security `A-DT-01`):**
  1. When `actor == admin` AND `DEMO_MODE=true`: triggering each of the 4 jobs via `SystemDevToolsService::triggerJobAction()` succeeds, executes the exact domain job logic, and writes to `audit_logs`.
  2. When `actor != admin` (`moderator`, `support`, `registered_user`): returns **`403 Forbidden`**.
  3. When `DEMO_MODE=false`: returns **`403 Forbidden`** (or blocked action) even for `admin`.
- **`AC-P805-05` (61 Permissions & Schema Integrity):** Zero changes to the 61-permission matrix or 34-table schema.

## G. Regression, Documentation & Completion Report
- Run full Backend (`php artisan test`), DB constraints (`php artisan db:verify-constraints`), and Mobile (`flutter analyze`, `flutter test`).
- Create `docs/08_ADMIN_DEVELOPMENT/P8_05_USERS_SETTINGS_AUDIT_AND_DEVTOOLS.md` and update `MASTER_TASK_TRACKER.md` & `AI_SYNC_BRIDGE.md`.
- Output full Completion Report with AC Evidence Matrix (`AC-P805-01`..`05`), confirmation of 21/21 screens, and Handoff to **`P8-06`**.
