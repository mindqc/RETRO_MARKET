# PHASE 08 MASTER EXECUTION PROMPT FOR ANTIGRAVITY (ORCHESTRATION & GOVERNANCE)

- **Project:** Retro Market (`izithrift`)
- **Phase:** Phase 08 – Laravel Blade Admin Dashboard Development (`P8-01` to `P8-06`)
- **Your Role:** Implementation Agent, Repository Inspector, and Automated QA Executor (Antigravity)
- **Planning & Review Agent:** Gemini
- **Final Authority:** Product Owner (PO)
- **Authorization Status:** `APPROVED FOR SEQUENTIAL EXECUTION (P8-01 -> P8-02 -> P8-03 -> P8-04 -> P8-05 -> P8-06)`

---

## 1. ROLE BOUNDARIES & COLLABORATION PROTOCOL
1. You (Antigravity) are the ONLY agent with direct access to the local filesystem, Git repository, PostgreSQL 18, Redis 7.4, and terminal execution.
2. Before writing code for any Work Package, you MUST inspect the live repository (`SCREEN_INVENTORY.md`, `ADMIN_WIREFRAMES.md`, `03_ACTOR_PERMISSION_MATRIX.md`, `routes/`, `app/`, `database/`, `tests/`) to verify actual file paths, class names, method signatures, and schema columns. Never guess or hardcode unverified names.
3. Execute **strictly one Work Package at a time** in sequential order:
   `P8-01` -> `P8-02` -> `P8-03` -> `P8-04` -> `P8-05` -> `P8-06`
4. Do NOT start the next Work Package until the current Work Package has:
   - 100% of its Acceptance Criteria verified,
   - `npm run build` passing with `0 errors`,
   - All new PHPUnit Feature/Integration tests passing 100%,
   - Full Backend (`88/88` baseline + new tests) and Mobile (`134/134` tests, `0` analyze issues) regression suites passing 100%,
   - Completion Report and Handoff generated.

## 2. MANDATORY SAFETY & PROTECTION RULES (APPLY TO ALL 6 WORK PACKAGES)
1. **Git Protection:**
   - Record current branch (`main`), `HEAD` commit hash, and `git status --short` before starting each WP.
   - Never run destructive Git commands (`reset --hard`, `clean -fd`, `push --force`).
   - Do NOT auto-commit or push unless explicitly instructed by the Product Owner.
2. **Database Protection (34 Tables Locked):**
   - Do NOT create, modify, or delete database migrations, tables, columns, `CHECK` constraints, or indexes.
   - Do NOT call `update()` or `delete()` on any `ImmutableLedgerRecord` / append-only table (`audit_logs`, `product_moderation_logs`, `escrow_transactions`, `wallet_transactions`, `auction_bids`, `order_items`).
3. **Business Rule & Domain Service Protection:**
   - Do NOT duplicate domain logic in Blade views or Admin Controllers. Always delegate to existing Phase 06 Domain Services and Policies.
   - For the 4 conditionally approved service extensions (`DEC-08-02`: User Role Governance, `platform_settings` Update, Catalog Taxonomy CRUD, Violation Reports Resolution), inspect existing services first; only add missing methods within strict `DB::transaction()`, pessimistic locking (`lockForUpdate()`), policy authorization, and `audit_logs` recording.
   - Preserve `DEC-04` (`6% + 7,000 VND` fee, `100%` seller payout), `DEC-05` (resubmit clears old rejection reason), `DEC-06/07` (3-tier cancel & dispute verdicts), `BR-PR-01..03` (5 conditions including `NEW_WITH_TAGS`), and `BR-AU-01..07`.
4. **3-Layer RBAC & Default Deny (`DEC-08-03`):**
   - Enforce Layer 1 (Shell Auth: active `admin`, `moderator`, `support` with `>= 1` Admin permission; immediate mid-session revocation if `SUSPENDED`; deny `registered_user`), Layer 2 (Screen Auth on every `GET` route), and Layer 3 (Action Auth on every mutating route).
   - Never rely on hiding UI buttons/links as a substitute for Backend authorization.
5. **Visual Direction (Warm Editorial Archive):**
   - Apply Cream `#FBF8F3`, Terracotta `#C85A32`, Pine Green `#2D5A3C`, Vintage Gold `#D4AF37`, typography `Fraunces` & `Be Vietnam Pro`, and `tabular-nums` for all currency/timer values.
6. **PO Escalation Rule:**
   - If you encounter a documentation contradiction, missing permission in `03_ACTOR_PERMISSION_MATRIX.md`, or a requirement that cannot be met without a schema/rule change, STOP work on the affected item immediately and escalate to the PO with options and impact analysis.
