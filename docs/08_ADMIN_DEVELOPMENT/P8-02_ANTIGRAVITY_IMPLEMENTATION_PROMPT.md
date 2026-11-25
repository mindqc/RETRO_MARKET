# P8-02 ANTIGRAVITY IMPLEMENTATION PROMPT – TAXONOMY, PRODUCTS & MODERATION QUEUE

## A. Task Identity
- **Project:** Retro Market (`izithrift`)
- **Phase:** Phase 08 – Laravel Blade Admin Dashboard Development
- **Work Package ID:** `P8-02`
- **Work Package Name:** Taxonomy, Products & Moderation Queue
- **Authorization:** `APPROVED` (Sequential Execution after `P8-01` PASS)
- **Current Status:** `READY_AFTER_P8_01`
- **Dependencies:** `P8-01` Completed & Verified; Phase 06 Product & Moderation Services; `DEC-08-02` (Conditional approval for Catalog Taxonomy CRUD).

## B. Context
- Mobile App (`P7-05`, `P7-06`, `P7-07`) consumes `/api/v1/catalog/taxonomy`, `/api/v1/products`, and Seller Channel 7-state listings (`DRAFT`, `PENDING_REVIEW`, `APPROVED`, `REJECTED`, `SOLD`, `HIDDEN`, `AUCTION_ENDED`).
- Product condition is standardized across the entire system to **5 levels** (`NEW_WITH_TAGS`, `LIKE_NEW`, `GOOD`, `FAIR`, `VINTAGE_WORN` – `BR-PR-03`).
- Under `DEC-05`, when a moderator rejects a listing, a `rejection_reason` is mandatory; when the seller edits and resubmits (`M-SL-04`), the listing returns to `PENDING_REVIEW`.
- `product_moderation_logs` and `audit_logs` are protected by `ImmutableLedgerRecord` (append-only).

## C. Objective
Implement the 4 canonical Catalog, Product Inventory, and Moderation screens (`A-MD-01`, `A-MD-02`, `A-PR-01`, `A-CT-01`), reusing existing Phase 06 Product Moderation services and introducing controlled Catalog Taxonomy CRUD (`DEC-08-02`) if not yet present, with full RBAC enforcement and append-only moderation/audit logging.

## D. Exact Scope
- **Screens Implemented (4 of 21):**
  1. `A-MD-01`: Product Moderation Queue (verify exact name & route in `PHASE_08_IMPLEMENTATION_PLAN.md`).
  2. `A-MD-02`: Product Moderation Detail / Split-Pane Evidence & Defect Inspection.
  3. `A-PR-01`: Product Management (Master Inventory across 7 statuses).
  4. `A-CT-01`: Catalog Management (Hierarchical Categories & Vintage Brands).

## E. Implementation Tasks
- **TASK-P802-01 (Repository Inspection for Product Moderation & Taxonomy Services):**
  - Inspect `app/Services/`, `app/Actions/`, `app/Policies/`, and `app/Models/` (`Product`, `Category`, `Brand`, `ProductModerationLog`). Identify existing moderation methods (`approve`, `reject`, status transitions). Check whether Category/Brand CRUD methods exist; if absent, design and implement controlled service methods under `DEC-08-02` using `DB::transaction()`, validation (unique slug, parent-child cycle prevention, no hard-delete if products attached), policy checks, and `AuditLog::create(...)`.
- **TASK-P802-02 (`A-CT-01` Catalog Management Screen & Controller):**
  - Implement `A-CT-01` displaying the recursive Category tree (root & child categories with product counts) and Vintage Brands directory. Support creating, updating, and toggling active/visibility status with validation and audit logging.
- **TASK-P802-03 (`A-MD-01` Product Moderation Queue & `A-MD-02` Split-Pane Moderation Detail):**
  - Implement `A-MD-01` queue for `PENDING_REVIEW` products with search, filters (listing type `FIXED_PRICE`/`AUCTION`, 5 `condition` levels, category, brand), and pagination. Implement `A-MD-02` featuring the **Split-Pane Evidence Review** layout and **Inspection-Slip Motif** for `defect_info` (`BR-PR-03`), image gallery inspection, previous `product_moderation_logs` history, Approve action (setting `APPROVED` + `verification_level`), and Reject action (requiring `rejection_reason` per `DEC-05`). Delegate all state changes to the existing Moderation Service so `product_moderation_logs` and `audit_logs` are written atomically.
- **TASK-P802-04 (`A-PR-01` Master Product Management Screen):**
  - Implement `A-PR-01` listing products across all 7 statuses with multi-criteria search/filtering, detail view, moderation history section, and administrative hide/unhide (`APPROVED` <-> `HIDDEN`) actions for policy violations.
- **TASK-P802-05 (`P8-02` Automated Feature & RBAC Tests):**
  - Create `tests/Feature/Admin/P802_TaxonomyProductsAndModerationTest.php` covering all 4 screens, 5 condition levels, `DEC-05` rejection/resubmission flow, `A-CT-01` CRUD, append-only log invariance, and RBAC (`moderator`/`admin` allowed; `support` and `registered_user` denied `403` on moderation/taxonomy mutations).

## F. Acceptance Criteria
- **`AC-P802-01` (`A-MD-01`, `A-MD-02`):** Displays `PENDING_REVIEW` listings, all 5 `ProductCondition` levels (`NEW_WITH_TAGS`..`VINTAGE_WORN`), images, `defect_info`, and prior `product_moderation_logs`.
- **`AC-P802-02` (Approve & Reject Rules `DEC-05`):** Approving transitions product to `APPROVED` (visible on `/api/v1/products`) and appends to `product_moderation_logs`. Rejecting without `rejection_reason` fails validation; rejecting with reason transitions to `REJECTED` and records the reason for Seller `M-SL-04`.
- **`AC-P802-03` (`A-PR-01`):** Filters accurately across all 7 product statuses, supports search & pagination, and allows authorized `admin`/`moderator` to hide violating `APPROVED` products with audit logging.
- **`AC-P802-04` (`A-CT-01` & `DEC-08-02`):** Creates and updates Categories and Brands, prevents duplicate slugs or circular parent-child hierarchies, prevents deleting categories with existing products, reflects changes on `/api/v1/catalog/taxonomy`, and records `audit_logs`.
- **`AC-P802-05` (RBAC & Append-Only Protection):** Enforces `03_ACTOR_PERMISSION_MATRIX.md` (`403` for unauthorized roles); zero `update()`/`delete()` calls on `product_moderation_logs` or `audit_logs`.

## G. Regression, Documentation & Completion Report
- Run full Backend (`php artisan test`), DB constraints (`php artisan db:verify-constraints`), and Mobile (`flutter analyze`, `flutter test`).
- Create `docs/08_ADMIN_DEVELOPMENT/P8_02_TAXONOMY_PRODUCTS_AND_MODERATION.md` and update `MASTER_TASK_TRACKER.md` & `AI_SYNC_BRIDGE.md`.
- Output full Completion Report with AC Evidence Matrix (`AC-P802-01`..`05`) and Handoff to **`P8-03`**.
