# P8-02: TAXONOMY, PRODUCTS & MODERATION QUEUE – IMPLEMENTATION SPECIFICATION & AUDIT

- **Project:** Retro Market (`izithrift`)
- **Phase:** Phase 08 – Laravel Blade Admin Dashboard Development
- **Work Package:** `P8-02`
- **Status:** `REVIEW` (100% Implemented & Verified)
- **Git Commit Baseline:** `4a1171ff9087fd66365342a215e615ed001ea141` on `main`
- **Screens Delivered (4 of 21):**
  1. `A-CT-01`: Category & Brand Management (`GET/POST /admin/catalog`)
  2. `A-MD-01`: Product Moderation Queue (`GET /admin/moderation/products`)
  3. `A-MD-02`: Product Moderation Detail – Split-Pane Evidence & Defect Inspection (`GET/POST /admin/moderation/products/{id}`)
  4. `A-PR-01`: Product Management – Master Inventory across 7 statuses (`GET /admin/products`)

---

## 1. Architectural Design & Domain Service Reuse (`DEC-08-02`)

### 1.1 Product Moderation (`ProductModerationService`)
Reused the existing Phase 06 Domain Service `App\Services\Governance\ProductModerationService`:
- `approveProduct(User $moderator, Product $product, string $verificationLevel, ?string $reason)`:
  - Updates `status` to `ProductStatus::APPROVED`, records `approved_by` and `approved_at`.
  - Atomically records immutable entry in `product_moderation_logs` (`action = 'APPROVED'`).
  - Records immutable audit log in `audit_logs` (`action = 'APPROVE_PRODUCT'`).
  - Dispatches `PRODUCT_APPROVED` notification to seller with deep link to product.
- `rejectOrHideProduct(User $moderator, Product $product, string $action, string $reason)`:
  - Validates `reason` (mandatory, >= 5 chars per `DEC-05` and `BR-PR-04`).
  - Updates `status` to `REJECTED` or `HIDDEN`, sets `rejection_reason`.
  - Atomically records immutable entry in `product_moderation_logs`.
  - Records immutable audit log in `audit_logs`.
  - Dispatches notification to seller enabling resubmission via Mobile `M-SL-04`.

### 1.2 Controlled Catalog Taxonomy CRUD (`CatalogTaxonomyService` & `DEC-08-02`)
Extended `App\Services\Catalog\CatalogTaxonomyService` with controlled mutation methods wrapped in `DB::transaction()`:
- `getAllCategoriesWithHierarchy()`: Recursive category tree with children and product counts.
- `getAllBrands()`: Complete vintage brand directory with product counts.
- `createCategory(array $data, User $actor)`: Auto-slug, parent validation, audit log.
- `updateCategory(Category $category, array $data, User $actor)`:
  - **Circular Hierarchy Guard:** Rejects setting `parent_id` to itself or any of its recursive descendants (`ValidationException`).
  - Records previous and new states in `audit_logs`.
- `toggleCategoryActive(Category $category, User $actor)`: Soft-toggle `is_active` state.
- `deleteCategory(Category $category, User $actor)`:
  - **Product Protection Guard:** Prevents deleting categories having products attached to self or children (`ValidationException`).
  - Reparents empty children to root before deleting.
- `createBrand`, `updateBrand`, `toggleBrandActive`, `deleteBrand`: Complete brand lifecycle with unique name/slug constraints and product attachment guards.

---

## 2. Screen Specifications & Route Matrix

| Screen ID | Screen Name | Route | HTTP Methods | Middleware / Permissions | Primary Components |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **`A-MD-01`** | Product Moderation Queue | `/admin/moderation/products` | `GET` | `admin.auth`, `admin.can:products.view` | Multi-filter toolbar (5 `condition` levels, `listing_type`, category, brand, search), table with thumbnails, seller info, defect summary, and direct "Thẩm định" CTA. |
| **`A-MD-02`** | Product Moderation Detail | `/admin/moderation/products/{id}` | `GET` | `admin.auth`, `admin.can:products.view` | **Split-Pane Evidence Layout**: Left pane displays photo gallery & zoomed close-ups; Right pane displays item metadata, 5-level condition badge, **Inspection-Slip Motif** (`defect_info` >= 5 chars per `BR-PR-03`), and immutable moderation history. |
| **`A-MD-02`** (Action) | Approve Product | `/admin/moderation/products/{id}/approve` | `POST` | `admin.auth`, `admin.can:products.approve` | Form with `verification_level` selector (`MODERATOR_REVIEWED`, `EXPERT_VERIFIED`), note input, CSRF protection. |
| **`A-MD-02`** (Action) | Reject Product | `/admin/moderation/products/{id}/reject` | `POST` | `admin.auth`, `admin.can:products.reject` | Form with mandatory `rejection_reason` textarea (min:5 chars per `DEC-05`), CSRF protection. |
| **`A-PR-01`** | All Products Inventory | `/admin/products` | `GET` | `admin.auth`, `admin.can:products.view` | Master Inventory table filtering across all 7 statuses (`DRAFT`, `PENDING_REVIEW`, `APPROVED`, `REJECTED`, `SOLD`, `HIDDEN`, `ARCHIVED`), condition, category, brand, and seller search. |
| **`A-PR-01`** (Action) | Administrative Hide | `/admin/products/{id}/hide` | `POST` | `admin.auth`, `admin.can:products.hide` | Chuyển bài đăng `APPROVED` sang `HIDDEN` khi phát hiện vi phạm bản quyền hoặc thông tin gian lận (`BR-PR-04`), ghi log kiểm duyệt. |
| **`A-PR-01`** (Action) | Restore Visibility | `/admin/products/{id}/unhide` | `POST` | `admin.auth`, `admin.can:products.approve` | Khôi phục bài đăng `HIDDEN` trở lại `APPROVED`. |
| **`A-CT-01`** | Category & Brand Management | `/admin/catalog` | `GET` | `admin.auth`, `admin.can:categories.view` | Tab switcher (Categories Tree vs Brands Directory), recursive tree view, product counts, sort orders, active state badges. |
| **`A-CT-01`** (Mutations) | Category/Brand CRUD | `/admin/catalog/*` | `POST/PUT/DELETE` | `admin.auth`, `admin.can:categories.manage` (Admin Only) | Modal tạo mới/chỉnh sửa danh mục & thương hiệu, toggle active, xóa an toàn với CSRF và Audit Logging. |

---

## 3. RBAC & Default Deny Enforcement (`03_ACTOR_PERMISSION_MATRIX.md`)

- **Administrator (`admin`):**
  - Full access to all 4 screens (`A-MD-01`, `A-MD-02`, `A-PR-01`, `A-CT-01`).
  - Full permission to approve, reject, hide, unhide products, and execute Category/Brand CRUD mutations (`categories.manage`).
- **Moderator (`moderator`):**
  - Access to `A-MD-01` (queue) and `A-MD-02` (detail, approve, reject).
  - Access to `A-PR-01` (master inventory, hide/unhide violating listings).
  - Access to `A-CT-01` for viewing taxonomy (`categories.view`).
  - **Default Deny (`403 Forbidden`):** Strictly blocked from mutating categories or brands (POST/PUT/DELETE `/admin/catalog/*` requires `categories.manage`).
- **Support Staff (`support`):**
  - **Default Deny (`403 Forbidden`):** Blocked from all moderation routes (`/admin/moderation/*`), product inventory (`/admin/products/*`), and catalog management (`/admin/catalog/*`).
- **Registered User (`registered_user`):**
  - **Default Deny (`403 Forbidden`):** Blocked from all admin routes; session immediately terminated by `EnsureAdminAuthenticated`.

---

## 4. Verification Evidence & Test Results

### 4.1 Feature Test Suite (`P802_TaxonomyProductsAndModerationTest.php`)
- **Total Tests:** **9 / 9 PASS (100%)**, 75 assertions, duration 0.98s.
  1. `test_moderation_queue_renders_and_filters_across_all_5_conditions` (`AC-P802-01`): Verifies `A-MD-01` renders and filters accurately across all 5 conditions (`NEW_WITH_TAGS` .. `VINTAGE_WORN`).
  2. `test_moderation_detail_split_pane_renders_defect_slip_and_history` (`AC-P802-01`): Verifies `A-MD-02` Split-Pane Evidence layout, Inspection-Slip Motif (`BR-PR-03`), and verdict desk.
  3. `test_approve_transitions_to_approved_writes_moderation_and_audit_logs` (`AC-P802-02`): Verifies approve flow, verification level assignment, immutable moderation log, and audit log.
  4. `test_reject_without_reason_fails_validation_and_with_reason_updates_product` (`AC-P802-02`): Verifies mandatory rejection reason (`DEC-05`), validation failure if empty or < 5 chars, and seller resubmission reason persistence.
  5. `test_master_inventory_filters_across_7_statuses_and_supports_hide_unhide` (`AC-P802-03`): Verifies `A-PR-01` master inventory, 7-status filtering, and administrative hide/unhide actions.
  6. `test_catalog_category_crud_with_slug_validation_and_circular_hierarchy_guard` (`AC-P802-04`): Verifies category creation, unique slug, self-loop guard, descendant-cycle guard, product deletion guard, and clean deletion.
  7. `test_brand_crud_and_public_taxonomy_synchronization` (`AC-P802-04`): Verifies brand creation, real-time sync with `/api/v1/catalog/taxonomy`, and active/inactive toggle.
  8. `test_rbac_moderator_vs_admin_vs_support_vs_registered_user` (`AC-P802-05`): Verifies RBAC permissions across all 4 roles.
  9. `test_product_moderation_log_is_strictly_append_only` (`AC-P802-05`): Verifies `update()` and `delete()` are blocked with `LogicException` via `ImmutableLedgerRecord`.

### 4.2 Full System Regression Suite
- **Vite Asset Build:** `npm run build` -> **0 errors** (CSS 68.53 kB, JS 0.02 kB).
- **PostgreSQL 18 DB Constraints:** `php artisan db:verify-constraints` -> **79 CHECK constraints active, 10/10 negative integrity tests PASS**.
- **Backend Test Suite:** `php artisan test` -> **123 / 123 PASS (100%)**, 1,232 assertions (88 baseline + 26 P8-01 + 9 P8-02).
- **Mobile Flutter Suite:**
  - `flutter analyze` -> **0 issues found** (0 errors, 0 warnings).
  - `flutter test` -> **134 / 134 PASS (100%)** across all 12 test suites.
