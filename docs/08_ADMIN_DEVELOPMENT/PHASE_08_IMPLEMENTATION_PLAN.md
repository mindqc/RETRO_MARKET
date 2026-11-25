# PHASE 08 IMPLEMENTATION PLAN – RETRO MARKET (izithrift)
## Canonical 21-Screen Source Alignment & Execution Roadmap

- **Document ID:** `DOC-P8-PLAN`
- **Repository Path:** `docs/08_ADMIN_DEVELOPMENT/PHASE_08_IMPLEMENTATION_PLAN.md`
- **Status:** `APPROVED BY PRODUCT OWNER (DEC-08-01)`
- **Git Baseline:** `4a1171ff9087fd66365342a215e615ed001ea141` on branch `main`

---

## 1. Canonical 21-Screen Master Inventory (`AC-P801-01`)

Tất cả 21 màn hình quản trị dưới đây được trích xuất trực tiếp và đối chiếu chính xác 1:1 từ:
1. `docs/02_SYSTEM_FLOWS/03_SCREEN_INVENTORY/SCREEN_INVENTORY.md` (Chương 3, Dòng 620–750).
2. `docs/02_SYSTEM_FLOWS/04_WIREFRAMES/ADMIN_WIREFRAMES.md` (Chương 1 & 2).
3. `docs/01_REQUIREMENTS_ANALYSIS/03_ACTOR_PERMISSION_MATRIX.md` (Chương 6: Master Permission Matrix).
4. `docs/03_UI_UX_DESIGN/04_ADMIN_DASHBOARD/` (`ADMIN_LAYOUT.md`, `DASHBOARD_UI.md`, `MANAGEMENT_UI.md`, `MODERATION_AND_DISPUTE_UI.md`).

| No. | Screen ID | Canonical Screen Name | Route (Laravel Blade) | Primary Actors | Permissions Assigned | Work Package | Source Reference |
| :-: | :--- | :--- | :--- | :--- | :--- | :---: | :--- |
| 1 | `A-AU-01` | **Admin Login** | `GET/POST /admin/login` | `admin`, `moderator`, `support` | `PERM-AU-01`, `PERM-AU-02` | `P8-01` | `SCREEN_INVENTORY.md` (L626)<br>`ADMIN_LAYOUT.md` (Mục 1) |
| 2 | `A-DB-01` | **Main KPI & Live Metrics Dashboard** | `GET /admin/dashboard` | `admin`, `moderator`, `support` | `PERM-AD-01` | `P8-01` | `SCREEN_INVENTORY.md` (L630)<br>`ADMIN_WIREFRAMES.md` (L15)<br>`DASHBOARD_UI.md` |
| 3 | `A-MD-01` | **Product Moderation Queue** | `GET /admin/moderation/products` | `moderator`, `admin` | `PERM-PR-06` | `P8-02` | `SCREEN_INVENTORY.md` (L634)<br>`MODERATION_AND_DISPUTE_UI.md` (Mục 2.1) |
| 4 | `A-MD-02` | **Product Inspection & Approve/Reject** | `GET/POST /admin/moderation/products/{id}` | `moderator`, `admin` | `PERM-PR-06`, `PERM-PR-07` | `P8-02` | `SCREEN_INVENTORY.md` (L638)<br>`ADMIN_WIREFRAMES.md` (L58)<br>`MODERATION_AND_DISPUTE_UI.md` |
| 5 | `A-PR-01` | **All Products Management** | `GET /admin/products` | `moderator`, `admin` | `PERM-PR-05`, `PERM-PR-08` | `P8-02` | `SCREEN_INVENTORY.md` (L642)<br>`MANAGEMENT_UI.md` (Mục 2.1) |
| 6 | `A-CT-01` | **Category & Brand Management** | `GET/POST /admin/catalog` | `admin` (CRUD), `moderator` (Read) | `PERM-PR-09` | `P8-02` | `SCREEN_INVENTORY.md` (L646)<br>`MANAGEMENT_UI.md` (Mục 2.1) |
| 7 | `A-CM-01` | **Review & Violation Report Moderation** | `GET/POST /admin/moderation/reports` | `moderator`, `admin` | `PERM-CM-04`, `PERM-CM-11` | `P8-04` | `SCREEN_INVENTORY.md` (L650)<br>`MODERATION_AND_DISPUTE_UI.md` (Mục 2.2) |
| 8 | `A-AC-01` | **Daily Auction Sessions Configuration** | `GET/POST /admin/auctions/sessions` | `admin` | `PERM-AC-08` | `P8-03` | `SCREEN_INVENTORY.md` (L654)<br>`MANAGEMENT_UI.md` (Mục 2.2) |
| 9 | `A-AC-02` | **Live & Completed Auctions Monitor** | `GET /admin/auctions` | `admin` (Full), `moderator` (Read) | `PERM-AC-01`, `PERM-AC-06` | `P8-03` | `SCREEN_INVENTORY.md` (L658)<br>`MANAGEMENT_UI.md` (Mục 2.2) |
| 10 | `A-AC-03` | **Auction Bid Inspector & Anti-Fraud Cancel** | `GET/POST /admin/auctions/{id}` | `admin` (Cancel) | `PERM-AC-09` | `P8-03` | `SCREEN_INVENTORY.md` (L662)<br>`MANAGEMENT_UI.md` (Mục 2.2) |
| 11 | `A-OR-01` | **Orders Management List** | `GET /admin/orders` | `admin` (All), `support` (Assigned) | `PERM-OR-04` | `P8-03` | `SCREEN_INVENTORY.md` (L666)<br>`MANAGEMENT_UI.md` (Mục 2.3) |
| 12 | `A-OR-02` | **Order Snapshot & Timeline Inspection** | `GET /admin/orders/{id}` | `admin`, `support` | `PERM-OR-04`, `PERM-OR-05A/B/C`, `PERM-OR-09` | `P8-03` | `SCREEN_INVENTORY.md` (L670)<br>`MANAGEMENT_UI.md` (Mục 2.3) |
| 13 | `A-PM-01` | **QR Payment Sessions Monitor** | `GET /admin/payments` | `admin` | `PERM-FN-01`, `PERM-FN-06` | `P8-03` | `SCREEN_INVENTORY.md` (L674)<br>`MANAGEMENT_UI.md` (Mục 2.3) |
| 14 | `A-ES-01` | **Immutable Escrow & Wallet Ledger Monitor** | `GET /admin/escrow` | `admin` (Strict Read-Only) | `PERM-FN-06`, `PERM-FN-07` | `P8-04` | `SCREEN_INVENTORY.md` (L678)<br>`ADMIN_WIREFRAMES.md` (L158)<br>`MANAGEMENT_UI.md` |
| 15 | `A-DP-01` | **Dispute & Complaint Queue** | `GET /admin/disputes` | `admin` (All), `support` (Assigned) | `PERM-CM-08` | `P8-04` | `SCREEN_INVENTORY.md` (L682)<br>`MODERATION_AND_DISPUTE_UI.md` (Mục 3.1) |
| 16 | `A-DP-02` | **Dispute Resolution Case Room** | `GET/POST /admin/disputes/{id}` | `support` (Evidence), `admin` (Verdict) | `PERM-CM-08`, `PERM-CM-09` | `P8-04` | `SCREEN_INVENTORY.md` (L686)<br>`ADMIN_WIREFRAMES.md` (L98)<br>`MODERATION_AND_DISPUTE_UI.md` |
| 17 | `A-US-01` | **User Management List** | `GET /admin/users` | `admin` | `PERM-US-05` | `P8-05` | `SCREEN_INVENTORY.md` (L690)<br>`MANAGEMENT_UI.md` (Mục 2.4) |
| 18 | `A-US-02` | **User Detail, Role & Fraud Inspector** | `GET/POST /admin/users/{id}` | `admin` | `PERM-US-06`, `PERM-US-07` | `P8-05` | `SCREEN_INVENTORY.md` (L694)<br>`MANAGEMENT_UI.md` (Mục 2.4) |
| 19 | `A-ST-01` | **Platform Settings (Buyer Protection Fee & Timers)** | `GET/POST /admin/settings` | `admin` | `PERM-AD-02` | `P8-05` | `SCREEN_INVENTORY.md` (L698)<br>`ADMIN_WIREFRAMES.md` (L189)<br>`MANAGEMENT_UI.md` |
| 20 | `A-AD-01` | **Admin Activity Audit Logs** | `GET /admin/audit-logs` | `admin` (Strict Read-Only) | `PERM-AD-03` | `P8-05` | `SCREEN_INVENTORY.md` (L702)<br>`MANAGEMENT_UI.md` (Mục 2.4) |
| 21 | `A-DT-01` | **Developer Tools & Manual Job Triggers** | `GET/POST /admin/dev-tools` | `admin` (`DEMO_MODE=true`) | `PERM-AD-04` | `P8-05` | `SCREEN_INVENTORY.md` (L706)<br>`ADMIN_WIREFRAMES.md` (L210)<br>`MANAGEMENT_UI.md` |

---

## 2. Six Work Package Sequential Architecture

```
P8-01: Foundation, Shell & Session Auth (2 screens: A-AU-01, A-DB-01)
  │
  ├──> P8-02: Taxonomy, Products & Moderation Queue (4 screens: A-MD-01, A-MD-02, A-PR-01, A-CT-01)
  │      │
  │      └──> P8-03: Auctions, Orders & Payments (6 screens: A-AC-01..03, A-OR-01..02, A-PM-01)
  │             │
  │             └──> P8-04: Escrow Ledger, Disputes & Reports (4 screens: A-ES-01, A-DP-01..02, A-CM-01)
  │                    │
  │                    └──> P8-05: Users, Settings, Audit Logs & DevTools (5 screens: A-US-01..02, A-ST-01, A-AD-01, A-DT-01)
  │                           │
  └───────────────────────────┴───> P8-06: E2E Integration Suite & Sign-off (All 21 screens verified)
```

---

## 3. Core Architectural Enforcements (DEC-08-01 to DEC-08-04)

1. **`DEC-08-01` (21-Screen Canonical Scope):** Phê duyệt tuyệt đối 21 màn hình theo đặc tả gốc. Không tự gộp hoặc lược bớt.
2. **`DEC-08-02` (Conditional Service Extension):** Chỉ mở rộng 4 Domain Services (`UserGovernanceService`, `PlatformConfigService`, `CatalogTaxonomyService`, `ViolationReportService`) khi không tìm thấy method tương đương.
3. **`DEC-08-03` (3-Layer RBAC & Default Deny):**
   - **Layer 1 (Shell Gate):** Chặn toàn diện `registered_user` và tài khoản `SUSPENDED`/`BANNED` (`403 Forbidden`).
   - **Mid-Session Revocation:** Nếu tài khoản bị chuyển sang `SUSPENDED` giữa phiên, ngay request kế tiếp session bị hủy và đẩy về trang đăng nhập.
   - **Layer 2 & 3 (Screen & Action Gate):** Mọi route và action đều kiểm tra quyền hạn chi tiết theo 61 permissions, áp dụng Default Deny (`403`) cho mọi quyền không xác định.
4. **`DEC-08-04` (Ledger Invariance):** Bảng `audit_logs`, `escrow_transactions`, `wallet_transactions` là append-only bất biến, chặn hoàn toàn `update()` và `delete()`.
