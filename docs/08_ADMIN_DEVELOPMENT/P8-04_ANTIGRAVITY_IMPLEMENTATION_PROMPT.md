# P8-04 ANTIGRAVITY IMPLEMENTATION PROMPT – ESCROW LEDGER, DISPUTES & MODERATION REPORTS

## A. Task Identity
- **Project:** Retro Market (`izithrift`)
- **Phase:** Phase 08 – Laravel Blade Admin Dashboard Development
- **Work Package ID:** `P8-04`
- **Work Package Name:** Escrow Ledger, Disputes & Moderation Reports
- **Authorization:** `APPROVED` (Sequential Execution after `P8-03` PASS)
- **Current Status:** `READY_AFTER_P8_03`
- **Dependencies:** `P8-01`..`P8-03` Completed & Verified; Phase 06 `DisputeService`, Escrow/Wallet Ledger Models, and `DEC-08-02` (Conditional approval for Violation Reports Resolution).

## B. Context
- Financial integrity relies on **Zero Ledger Drift** across `escrow_transactions` and `wallet_transactions` (both guarded by `ImmutableLedgerRecord`).
- Opening a dispute (`DEC-03`, `BR-DP-02`) freezes Escrow funds (`FROZEN`).
- Phase 06 enforces strict **Separation of Duties**: `support` can assist and request additional evidence (`NEED_MORE_INFO` / `STAFF_REQUEST_NOTE`), whereas ONLY `admin` can issue final financial verdicts (`DEC-07` / `BR-FN-06`: full refund to buyer, release to seller, or partial refund) via `DisputeService` using pessimistic locking (`lockForUpdate`).
- Users submit violation reports from Mobile (`M-CM-03` -> `POST /api/v1/reports`).

## C. Objective
Implement the 4 canonical Escrow Ledger, Dispute Resolution, and Violation Report screens (`A-ES-01`, `A-DP-01`, `A-DP-02`, `A-CM-01`), enforcing append-only ledger invariance, strict `support` vs `admin` Separation of Duties on financial verdicts, and controlled Violation Report resolution (`DEC-08-02`).

## D. Exact Scope
- **Screens Implemented (4 of 21):**
  1. `A-ES-01`: Escrow Overview & Immutable Ledger Explorer (verify exact name & route in `PHASE_08_IMPLEMENTATION_PLAN.md`).
  2. `A-DP-01`: Dispute Management Queue.
  3. `A-DP-02`: Dispute Detail, 2-Way Evidence Workbench & Admin Financial Verdict Screen.
  4. `A-CM-01`: Violation / Moderation Reports Management.

## E. Implementation Tasks
- **TASK-P804-01 (Repository Inspection for Dispute, Ledger & Report Services):**
  - Inspect `DisputeService`, `DisputePolicy`, `EscrowTransaction`, `WalletTransaction`, and `Report` model/service. Verify exact method signatures for requesting more info (`support`/`admin`) and issuing financial verdicts (`admin` only). Check whether a method to resolve/dismiss `Report` records exists; if absent, implement a controlled service method under `DEC-08-02` with `DB::transaction()`, `lockForUpdate()`, validation, policy authorization, and `AuditLog::create(...)`.
- **TASK-P804-02 (`A-ES-01` Escrow Overview & Immutable Ledger Screen):**
  - Build `A-ES-01` (strictly read-only) displaying platform-wide Escrow & Wallet reconciliation summary (verifying `wallet_balance` + `escrow_held_balance` matches ledger sums = **Zero Ledger Drift**) and paginated, filterable tables for `escrow_transactions` and `wallet_transactions`.
- **TASK-P804-03 (`A-DP-01` Dispute Queue & `A-DP-02` Split-Pane Dispute Workbench):**
  - Build `A-DP-01` (filter by `OPEN`, `NEED_MORE_INFO`, `RESOLVED`, reason category) and `A-DP-02` (**Split-Pane Evidence Review** showing `BUYER_PROOF`, `SELLER_COUNTER_PROOF`, `STAFF_REQUEST_NOTE`, frozen escrow amount, and order snapshot).
  - *Strict Authorization:* Allow `support` and `admin` to post `STAFF_REQUEST_NOTE` (`NEED_MORE_INFO`). Restrict the Financial Verdict form (`DEC-07` / `BR-FN-06`) strictly to `admin` via `DisputePolicy` & `DisputeService`.
- **TASK-P804-04 (`A-CM-01` Violation / Moderation Reports Screen):**
  - Implement `A-CM-01` listing violation reports (`SCAM`, `COUNTERFEIT`, `ABUSIVE_LANGUAGE`, `SPAM`), target user/conversation context, filter by status, and action form to resolve/dismiss reports with mandatory resolution notes and `audit_logs` recording.
- **TASK-P804-05 (`P8-04` Automated Financial Verdict, Ledger Invariance & RBAC Tests):**
  - Create `tests/Feature/Admin/P804_EscrowDisputesAndReportsTest.php` testing `A-ES-01` reconciliation, `support` `403` on financial verdicts, `admin` verdict execution via `DisputeService` with Zero Ledger Drift, append-only ledger protection, and `A-CM-01` report resolution.

## F. Acceptance Criteria
- **`AC-P804-01` (`A-ES-01`):** Displays accurate ledger entries and reconciliation totals with **Zero Ledger Drift**; exposes zero update/delete endpoints on `escrow_transactions` or `wallet_transactions`.
- **`AC-P804-02` (`A-DP-01`, `A-DP-02`):** Renders frozen escrow amount and chronological buyer/seller/staff evidence items accurately.
- **`AC-P804-03` (Separation of Duties & Financial Verdicts `DEC-07`):** `support` can submit `STAFF_REQUEST_NOTE` (`NEED_MORE_INFO`) but receives **`403 Forbidden`** if attempting to submit a financial verdict. `admin` can execute verdicts through `DisputeService`, atomically updating dispute status (`RESOLVED`), order/escrow status, and append-only ledger records with Zero Ledger Drift.
- **`AC-P804-04` (`A-CM-01` & `DEC-08-02`):** Authorized staff can filter, inspect, and resolve/dismiss violation reports with a required note, recording an immutable entry in `audit_logs` and preventing duplicate resolution of closed reports.
- **`AC-P804-05` (Immutable Record Protection):** Any attempt to call `update()` or `delete()` on `EscrowTransaction`, `WalletTransaction`, or `AuditLog` is blocked by `ImmutableLedgerRecord`.

## G. Regression, Documentation & Completion Report
- Run full Backend (`php artisan test`), DB constraints (`php artisan db:verify-constraints`), and Mobile (`flutter analyze`, `flutter test`).
- Create `docs/08_ADMIN_DEVELOPMENT/P8_04_ESCROW_DISPUTES_AND_REPORTS.md` and update `MASTER_TASK_TRACKER.md` & `AI_SYNC_BRIDGE.md`.
- Output full Completion Report with AC Evidence Matrix (`AC-P804-01`..`05`), Zero Ledger Drift proof, and Handoff to **`P8-05`**.
