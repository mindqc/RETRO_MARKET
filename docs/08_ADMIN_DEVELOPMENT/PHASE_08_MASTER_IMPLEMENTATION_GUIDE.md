# PHASE 08 MASTER IMPLEMENTATION GUIDE – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P8-MASTER-GUIDE`
- **Repository Path:** `docs/08_ADMIN_DEVELOPMENT/PHASE_08_MASTER_IMPLEMENTATION_GUIDE.md`
- **Phase:** `Phase 08 – Laravel Blade Admin Dashboard Development`
- **Authorization Status:** `APPROVED – P8-01 through P8-06 (Sequential Execution)`
- **Planning Status:** `PHASE_08_PROMPT_PACKAGE_COMPLETED – READY_FOR_ANTIGRAVITY_EXECUTION`

---

## 1. Executive Summary
Phase 08 implements the back-office **Laravel Blade Admin Dashboard** for **Retro Market (`izithrift`)** across **21 canonical Admin screens** organized into **6 sequential Work Packages (`P8-01` to `P8-06`)**. The Admin Dashboard acts strictly as a presentation and orchestration layer over the existing Phase 05 PostgreSQL 18 schema (34 tables) and Phase 06 Domain Services/Policies, enforcing 3-layer RBAC, Redis 7.4 session persistence, append-only ledger invariance, and complete isolation from the Phase 07 Flutter Mobile API (`sanctum`).

## 2. Phase 08 Objectives
1. Deliver all **21 canonical Admin screens** using Laravel 13 Blade, Vite 8, and Tailwind CSS v4 under the **Warm Editorial Archive** visual direction.
2. Empower `admin`, `moderator`, and `support` actors according to the 61 permissions in `03_ACTOR_PERMISSION_MATRIX.md` with **Default Deny** enforcement.
3. Reuse existing Phase 06 Domain Services and only introduce the 4 conditionally approved service capabilities (`DEC-08-02`) if repository inspection confirms no equivalent method exists.
4. Preserve 100% of the Phase 05–07 Regression Baseline (`88/88` Backend tests PASS, `134/134` Flutter tests PASS, `0` analyze issues, Zero Ledger Drift).

## 3. Implementation Authorization & Sequential Governance
- **Authorized Work Packages:** `P8-01`, `P8-02`, `P8-03`, `P8-04`, `P8-05`, `P8-06`.
- **Mandatory Execution Mode:** Strictly sequential (`P8-01 -> P8-02 -> P8-03 -> P8-04 -> P8-05 -> P8-06`). Parallel execution is prohibited.
- **Change Control Gate:** Antigravity does not need to re-request authorization to move from `P8-0(N)` to `P8-0(N+1)` once all Acceptance Criteria and Regression Tests of `P8-0(N)` pass 100%. However, if any task requires altering Business Rules, the 34-table Database Schema, the 61-entry Permission Matrix, or API contracts, Antigravity MUST halt the affected item and escalate to the Product Owner.

## 4. Project Technical Baseline
- **Backend:** Laravel 13, PHP 8.4, Timezone `Asia/Ho_Chi_Minh`.
- **Database:** PostgreSQL 18 (34 physical tables, `NUMERIC(15,2)`, `TIMESTAMPTZ`, `JSONB`, Tier 6 `CHECK` constraints, 5-level `ProductCondition` including `NEW_WITH_TAGS`).
- **Cache / Session / Queue:** Redis 7.4 (Online/Healthy; Redis Session Runtime to be verified in `P8-01`).
- **Admin Web Stack:** Laravel Blade (`web` guard, Session-based auth), Vite 8, Tailwind CSS v4.
- **Mobile Stack (Protected Baseline):** Flutter 3.x (`52/52` screens, `134/134` tests PASS, `0` analyze issues), Laravel Sanctum (`/api/v1/*`, `88/88` Backend tests PASS, `1,043` assertions).

## 5. Canonical 21-Screen Inventory
*Note on Source Traceability:* Screen IDs below are mapped to the approved WP Inventory (`P8-01`..`P8-05`). Exact Screen Names and URI Routes must be bound directly from `docs/02_SYSTEM_FLOWS/03_SCREEN_INVENTORY/SCREEN_INVENTORY.md` and `docs/02_SYSTEM_FLOWS/04_WIREFRAMES/ADMIN_WIREFRAMES.md` without invention.

| # | Screen ID | Canonical Screen Name (`SCREEN_INVENTORY.md`) | Target Work Package | Primary Actors | Core Domain Scope |
| :-: | :--- | :--- | :---: | :--- | :--- |
| 1 | `A-AU-01` | Admin Login (`VERIFIED`) | `P8-01` | `admin`, `moderator`, `support` | Web Session login, CSRF, throttling, session regeneration |
| 2 | `A-DB-01` *(or exact Dashboard ID in `SCREEN_INVENTORY.md`)* | Admin Dashboard (`VERIFY_FROM_REPO_SOURCE`) | `P8-01` | `admin`, `moderator`, `support` | Role-scoped KPIs, operational queues, system overview |
| 3 | `A-MD-01` | Product Moderation Queue (`VERIFY_FROM_REPO_SOURCE`) | `P8-02` | `moderator`, `admin` | Queue of `PENDING_REVIEW` & resubmitted (`DEC-05`) listings |
| 4 | `A-MD-02` | Product Moderation Detail (`VERIFY_FROM_REPO_SOURCE`) | `P8-02` | `moderator`, `admin` | Split-pane evidence & defect inspection, Approve/Reject (`DEC-05`) |
| 5 | `A-PR-01` | Product Management (`VERIFY_FROM_REPO_SOURCE`) | `P8-02` | `moderator`, `admin` | Master catalog across 7 states, status actions, moderation history |
| 6 | `A-CT-01` | Catalog Management (`VERIFIED`) | `P8-02` | `moderator`, `admin` | Category tree & Vintage Brand taxonomy CRUD |
| 7 | `A-AC-01` | Auction Management List (`VERIFY_FROM_REPO_SOURCE`) | `P8-03` | `moderator`, `admin` | Scheduled/Live/Completed auctions monitor |
| 8 | `A-AC-02` | Auction Detail / Live Monitor (`VERIFY_FROM_REPO_SOURCE`) | `P8-03` | `moderator`, `admin` | Ticket-stub auction inspector, Anti-Sniping (`BR-AU-04`), bid trail |
| 9 | `A-AC-03` | Auction History / Defaulted Winners View (`VERIFY_FROM_REPO_SOURCE`) | `P8-03` | `moderator`, `admin` | Completed/unsold/defaulted (`WINNER_DEFAULTED`) auction records |
| 10 | `A-OR-01` | Order Management List (`VERIFY_FROM_REPO_SOURCE`) | `P8-03` | `support`, `admin` | Platform orders with 4 independent state machines |
| 11 | `A-OR-02` | Order Detail Inspector (`VERIFY_FROM_REPO_SOURCE`) | `P8-03` | `support`, `admin` | Order snapshot, `DEC-04` fee breakdown, 3-tier cancel (`DEC-06`), shipment |
| 12 | `A-PM-01` | Payment Management (`VERIFY_FROM_REPO_SOURCE`) | `P8-03` | `support`, `admin` | QR payment sessions, expiration, reconciliation |
| 13 | `A-ES-01` | Escrow Overview & Ledger (`VERIFY_FROM_REPO_SOURCE`) | `P8-04` | `admin`, `support` (Read) | Append-only `escrow_transactions` & `wallet_transactions` explorer |
| 14 | `A-DP-01` | Dispute Management Queue (`VERIFY_FROM_REPO_SOURCE`) | `P8-04` | `support`, `admin` | Queue of `OPEN` / `NEED_MORE_INFO` / `RESOLVED` disputes (`DEC-03`) |
| 15 | `A-DP-02` | Dispute Detail & Financial Verdicts (`VERIFY_FROM_REPO_SOURCE`) | `P8-04` | `support` (Assist), `admin` (Verdict) | 2-way evidence workbench & Admin financial verdict (`DEC-07`) |
| 16 | `A-CM-01` | Violation / Moderation Reports (`VERIFY_FROM_REPO_SOURCE`) | `P8-04` | `moderator`, `support`, `admin` | Community/chat violation reports & review moderation |
| 17 | `A-US-01` | User Management List (`VERIFY_FROM_REPO_SOURCE`) | `P8-05` | `admin`, `support` (Read) | Unified Buyer/Seller & internal staff directory |
| 18 | `A-US-02` | User Detail & Role Governance (`VERIFY_FROM_REPO_SOURCE`) | `P8-05` | `admin`, `support` (Read) | 360° profile, Trust Score, suspend/unsuspend, role assignment |
| 19 | `A-ST-01` | Platform Settings (`VERIFY_FROM_REPO_SOURCE`) | `P8-05` | `admin` | `platform_settings` management (`DEC-04` fees, timers, seasonal) |
| 20 | `A-AD-01` | Audit Logs Explorer (`VERIFY_FROM_REPO_SOURCE`) | `P8-05` | `admin` | Append-only `audit_logs` inspection & JSON metadata diff |
| 21 | `A-DT-01` | Developer Tools & Manual Job Triggers (`VERIFIED`) | `P8-05` | `admin` (`DEMO_MODE=true`) | Safe manual trigger for 4 idempotent background jobs |

## 6. Six Work Package Breakdown & Dependencies
- **`P8-01` (Foundation, Shell & Session Auth):** `A-AU-01` + Admin Dashboard (`2` screens). Prerequisite for all subsequent WPs.
- **`P8-02` (Taxonomy, Products & Moderation Queue):** `A-MD-01`, `A-MD-02`, `A-PR-01`, `A-CT-01` (`4` screens). Depends on `P8-01`.
- **`P8-03` (Auctions, Orders & Payments):** `A-AC-01`, `A-AC-02`, `A-AC-03`, `A-OR-01`, `A-OR-02`, `A-PM-01` (`6` screens). Depends on `P8-01`, `P8-02`.
- **`P8-04` (Escrow Ledger, Disputes & Moderation Reports):** `A-ES-01`, `A-DP-01`, `A-DP-02`, `A-CM-01` (`4` screens). Depends on `P8-01`, `P8-03`.
- **`P8-05` (Users, Settings, Audit Logs & Developer Tools):** `A-US-01`, `A-US-02`, `A-ST-01`, `A-AD-01`, `A-DT-01` (`5` screens). Depends on `P8-01`..`P8-04`.
- **`P8-06` (Web E2E Integration Suite & Sign-off):** Cross-module E2E verification across all `21` screens, security/RBAC/ledger audit, and final sign-off documentation. Depends on `P8-01`..`P8-05`.

## 7. Design System (Warm Editorial Archive) & Protection Rules
- **Palette:** Cream `#FBF8F3`, Terracotta `#C85A32`, Pine Green `#2D5A3C`, Vintage Gold `#D4AF37`.
- **Typography:** `Fraunces` (headings), `Be Vietnam Pro` (dense back-office tables/forms with Vietnamese glyph support), `font-variant-numeric: tabular-nums` on all prices, ledger balances, and timers.
- **Patterns:** Split-pane evidence review (`A-MD-02`, `A-DP-02`), inspection-slip motif for `defect_info`, ticket-stub motif for auctions (`A-AC-02`).
- **Zero DDL Changes:** 34 tables, migrations, constraints, and indexes are locked.
- **Append-Only Ledger Protection:** `audit_logs`, `product_moderation_logs`, `escrow_transactions`, `wallet_transactions`, `auction_bids`, and `order_items` are strictly immutable (`create()` only; never `update()` or `delete()`).
