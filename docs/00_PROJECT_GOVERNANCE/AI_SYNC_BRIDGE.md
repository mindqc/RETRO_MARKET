# AI SYNC BRIDGE – GEMINI (ARCHITECT/BA) <-> ANTIGRAVITY (IDE AGENT)

- **Project Codename:** `RETRO MARKET`
- **App Brand Name:** `izithrift`
- **Last Synced Phase:** `Phase 07 FULLY SIGNED OFF BY PO (P7-01..P7-12) [DONE / APPROVED]` -> `Phase 08 READY FOR DISCOVERY`
- **Status:** `ACTIVE SYNC`

---

## 1. HƯỚNG DẪN SỬ DỤNG CHO ANTIGRAVITY (SYSTEM PROTOCOL)
File này là cầu nối đồng bộ trạng thái giữa phiên thảo luận thiết kế trên **Gemini** và môi trường thực thi trong **Antigravity**:
1. **Trước khi thực hiện bất kỳ Task nào:** Antigravity phải đọc mục `2. LOCKED CONTEXT SUMMARY` và mục `3. CURRENT ASSIGNED TASK` bên dưới.
2. **Sau khi hoàn thành Task được giao:** Antigravity cập nhật trạng thái trong `docs/00_PROJECT_GOVERNANCE/MASTER_TASK_TRACKER.md` và ghi báo cáo kết quả vào mục `4. ANTIGRAVITY EXECUTION LOG & FINAL REPORT` ở cuối file này để người dùng đồng bộ ngược lại cho Gemini.

---

## 2. LOCKED CONTEXT SUMMARY (TÓM TẮT NGỮ CẢNH ĐÃ KHÓA TỪ PHASE 01 ĐẾN PHASE 05)

Toàn bộ tài liệu Phase 01 (`PA-01`..`PA-10`), Phase 02 (`P2-01`..`P2-08`), Phase 03 (`P3-01`..`P3-08`), Phase 04 (`P4-01`..`P4-05`) và Phase 05 (`P5-01`..`P5-07`) đã được phê duyệt (`DONE / APPROVED`). Các quy tắc bất biến cần ghi nhớ khi lập trình:

1. **Tech Stack & Deployment Architecture (`ADR-01`, `ADR-02`):**
   - Mobile: Flutter (`izithrift`, MVVM + Repository + Provider + `go_router` + `Dio`).
   - Backend & Admin: Laravel 13 (PHP 8.4+, REST API `/api/v1` + Admin Blade dùng chung Service Layer & Eloquent Models).
   - Database: PostgreSQL 18 (Docker local, immutable append-only ledger `NUMERIC(15, 2)`).
2. **PostgreSQL 18 Database Schema & Integrity Constraints (`P4-02`, `P4-03`, `P5-02`, `P5-03`):**
   - 34 bảng SQL hoàn chỉnh (18 Core + 4 Auction + 12 Order/Escrow/Engagement) với kiểu tiền tệ cố định `NUMERIC(15, 2)` và `CHECK (>= 0)`.
   - **Chống tự giao dịch (`BR-AC-02`):** `CHECK (buyer_id <> seller_id)` trên `orders`, `CHECK (leading_bidder_id <> seller_id)` trên `auctions`, `CHECK (reviewer_id <> seller_id)` trên `reviews`, `CHECK (follower_id <> seller_id)` trên `seller_follows`.
   - **Phương trình tài chính (`DEC-04`):** Khóa cứng bằng `chk_orders_total_equation` (`total_amount = item_subtotal + shipping_fee + buyer_protection_fee`) và `chk_orders_seller_net_100_percent` (`seller_net_amount = item_subtotal`).
   - **Chính sách hoàn tiền 100% (`DEC-07`):** Khóa cứng bằng `chk_escrow_accounting_balance` (`FULL_REFUND` hoàn trả đủ `gross_amount` = `total_amount`).
   - **Đăng lại đấu giá (`DEC-02`):** Partial Unique Index `uq_auctions_active_product ON auctions(product_id) WHERE status IN ('SCHEDULED', 'LIVE')`.
   - **Chống thanh toán & giải ngân trùng (`BR-FN-03`, `BR-FN-07`):** Partial Unique Index `uq_payments_one_paid_per_order ON payments(order_id) WHERE status = 'PAID'` và `UNIQUE(order_id)` trên `wallet_transactions`.
3. **Quản lý Concurrency & Background Workers (`ADR-05`, `ADR-06`, `P4-04`, `P5-04`):**
   - Mọi thao tác đấu giá, đặt mua, thanh toán và giải ngân Escrow bắt buộc dùng `DB::transaction()` và `SELECT ... FOR UPDATE`.
   - Scheduled Jobs quét với `FOR UPDATE SKIP LOCKED`.
   - **Dispute Freeze Guard (`DEC-03`):** Khiếu nại mở (`dispute_status <> 'NONE'` hoặc `escrow_frozen_at IS NOT NULL`) ngăn chặn tuyệt đối tiến trình tự động giải ngân sau 24h.
   - Hỗ trợ `DEMO_MODE=true` với Developer Tools (`A-DT-01`) gọi cùng Domain Services có tính lũy đẳng (idempotent).
4. **REST API Standards (`P4-04`):**
   - Base URL: `/api/v1/*`.
   - Chuẩn JSON Envelope đồng nhất (`success`, `data`, `meta.server_time`, `error`).
   - Phục vụ 49 màn hình Mobile (`M-*`) và 21 màn hình Admin Web Blade (`A-*`).

---

## 3. CURRENT ASSIGNED TASK (NHIỆM VỤ HIỆN TẠI CHO ANTIGRAVITY)
- **Target Phase:** `Phase 08 – Admin Web Dashboard (Laravel Blade)`
- **Initial Task:** `Phase 08 Discovery & Scaffolding Planning`
- **Status:** Phase 07 đã được Product Owner phê duyệt chính thức (`OFFICIAL PO SIGN-OFF`). Toàn bộ 52 màn hình Mobile, 134/134 test Mobile và 88/88 test Backend đã nghiệm thu.
- **Key Architectural Directives for Phase 08 (PO Enforced):**
  1. **Admin Web Guard:** Sử dụng Laravel Session-based `web` guard hoàn toàn độc lập với Sanctum Bearer Token của Mobile Client.
  2. **Session Storage:** Duy trì `SESSION_DRIVER=redis` (Redis 7.4-alpine qua container `retromarket_redis7` đã xác minh healthy). Không chuyển sang database session để bảo toàn 34 bảng nghiệp vụ PostgreSQL 18 theo `TECH-05`. Lưu ý kiểm tra lại Laravel Session write/read trong Phase 08 Discovery.
  3. **Database Schema:** Hệ thống đang chạy trên 34 bảng (PostgreSQL 18) đã kiểm định tại Phase 05.
  4. **Supplementary Test Backlog:** 8 API routes thiếu Direct HTTP tests và Negative tests cho Product Condition (HTTP 422) đã được ghi nhận vào backlog **Phase 10 (Testing & QA)**. Không tạo Phase 13.

---

## 4. ANTIGRAVITY EXECUTION LOG & FINAL REPORT
- **Last Executed Task:** `P5-01` – Environment Setup, Docker & Laravel 13 Scaffolding
- **Executed At:** `2026-11-14`
- **Status:** `DONE` (Infrastructure Online & Healthy — Scaffolding Complete — Ready for Task P5-02)

---

## 5. ANTIGRAVITY EXECUTION LOG – TASK P5-02
- **Last Executed Task:** `P5-02` – PostgreSQL 18 Migrations & DB Constraints
- **Executed At:** `2026-11-14`
- **Status:** `DONE` (5 Tier Migrations, 34 Business Tables Created & Verified)

---

## 6. ANTIGRAVITY EXECUTION LOG – TASK P5-03
- **Last Executed Task:** `P5-03` – Database Constraints, Partial Indexes & Integrity Verification
- **Executed At:** `2026-11-14`
- **Status:** `DONE` (Tier 6 Migration, 79 CHECK Constraints, 2 Partial Unique Indexes, db:verify-constraints PASS 100%)

---

## 7. ANTIGRAVITY EXECUTION LOG – TASK P5-04
- **Last Executed Task:** `P5-04` – Eloquent Models, Relationships & Immutability Guards
- **Executed At:** `2026-11-14`
- **Status:** `DONE` (32 Domain Models, 116 Relationships, Trait ImmutableLedgerRecord, VerifyEloquentModelsCommand PASS 100%)

---

## 8. ANTIGRAVITY EXECUTION LOG – TASK P5-05
- **Last Executed Task:** `P5-05` – Factories, Idempotent Seeders & Ledger Reconciliation
- **Executed At:** `2026-11-14`
- **Status:** `DONE` (Factories Updated, 6 Modular Seeders, db:verify-seeders PASS 100%, 0-Drift Ledger Reconciled)

---

## 9. ANTIGRAVITY EXECUTION LOG – TASK P5-06
- **Last Executed Task:** `P5-06` – Database Validation, Rollback Verification & Automated PHPUnit Suite
- **Executed At:** `2026-11-14`
- **Status:** `DONE` (PHPUnit Suite 12/12 PASSED, Rollback Invariant Verified, Zero Regressions Across All 5 Suites)

---

## 10. ANTIGRAVITY EXECUTION LOG – TASK P5-07 & PHASE 05 FINAL SIGN-OFF
- **Last Executed Task:** `P5-07` – Final Backend Foundation Review & Phase 05 Sign-Off
- **Executed At:** `2026-11-14`
- **Status:** `DONE / APPROVED` (Phase 05 100% Completed, 7/7 Documents Approved, Full Verification Run PASS)
- **Verification Summary:**
  1. **Hồ Sơ Tài Liệu Phase 05 (`docs/05_BACKEND_FOUNDATION/`):**
     - Đầy đủ 7 file tài liệu chuẩn hóa: `P5_01` -> `P5_06` + `PHASE_05_SIGN_OFF.md`.
     - Chuyển toàn bộ 7 file sang trạng thái `DONE / APPROVED`.
  2. **Chuỗi Kiểm Định Tổng Thể Cuối Cùng (`Full Foundation Verification Run`):**
     - `php artisan system:health-check`: **PASS** (8/8 Components OK: PG18, Redis 7.4, Mailpit, Storage, Demo Mode).
     - `php artisan db:verify-constraints`: **PASS** (79 Check Constraints, 2 Partial Unique Indexes, 10 Negative Invariants).
     - `php artisan model:verify-architecture`: **PASS** (32 Models, 116 Relationships, Role Helpers, 5 Immutability Guards).
     - `php artisan db:verify-seeders`: **PASS** (Zero Drift, DEC-04 Equation 10/10 Orders, 4 Escrow Types).
     - `php artisan test --filter=DatabaseFoundationVerificationTest`: **PASS** (12/12 tests, 122 assertions in 1.53s).
  3. **Khóa Sổ Phase 05:**
     - Đã đánh dấu toàn bộ 7 task `P5-01` đến `P5-07` là `DONE` trong `MASTER_TASK_TRACKER.md`.
     - Nền tảng hạ tầng backend, CSDL và ORM sẵn sàng 100% để bước sang **Phase 06 – Backend Business Logic Services, REST API (`/api/v1/*`), Scheduled Jobs & Admin Blade**.

### Phase 06 - Task P6-01 Completed (2026-11-14)
- **Task:** Backend Architecture & API Foundation (`P6-01`).
- **Artifacts:** `ApiResponse.php`, `DomainException` + 7 specialized subclasses, 4 Middlewares (`OptionalSanctumAuth`, `EnsureUserIsActive`, `EnsureInternalRole`, `EnsureDemoModeEnabled`), RateLimiters (`auth`, `transactional`, `polling`), `PlatformConfigService`, `AuditLogService`, `BootstrapController`, `GET /api/v1/health`, `GET /api/v1/bootstrap`.
- **Automated Verification:** 8/8 tests in `ApiFoundationTest` passed (60 assertions), 22/22 total tests passed (184 assertions).
- **Next Action:** Ready for Task `P6-02` (Authentication & Access Control).

### Phase 06 - Task P6-02 Completed (2026-11-14)
- **Task:** Authentication, Sanctum Tokens & RBAC Authorization Policies (`P6-02`).
- **Artifacts:** `AuthService.php`, `UserGovernanceService.php`, `RegisterRequest.php`, `LoginRequest.php`, `ForgotPasswordRequest.php`, `ResetPasswordRequest.php`, `AuthUserResource.php`, `AuthController.php`, 6 Eloquent Policies (`ProductPolicy`, `AuctionPolicy`, `OrderPolicy`, `DisputePolicy`, `ConversationPolicy`, `ReviewPolicy`).
- **Automated Verification:** 8/8 tests in `AuthAndRbacTest` passed (83 assertions), 30/30 total tests passed (267 assertions).
- **Next Action:** Ready for Task `P6-03` (User, Profile & Category Services).

### Phase 06 - Task P6-03 Completed (2026-11-14)
- **Task:** User Profile, Address Book, Catalog Taxonomy, Home Discovery & Seller Storefront (`P6-03`).
- **Artifacts:** `ProfileService.php`, `AddressBookService.php`, `CatalogTaxonomyService.php`, `HomeDiscoveryService.php`, `SellerStorefrontService.php`, `ProfileController.php`, `AddressController.php`, `CatalogController.php`, `SellerStorefrontController.php`, 5 FormRequests, 6 API Resources, 12 API Routes.
- **Automated Verification:** 8/8 tests in `UserProfileAndCatalogTest` passed (224 assertions), 38/38 total tests passed (491 assertions).
- **Next Action:** Ready for Task `P6-04` (Product & Listing Services incl. Moderation Domain).


### Phase 06 - Task P6-04 Completed (2026-11-14)
- **Task:** Product Discovery, 7-State Seller Listings, Moderation Service & Resubmit Flow (P6-04).
- **Artifacts:** ProductDiscoveryService.php, SellerProductService.php, ProductModerationService.php, ProductController.php, SellerProductController.php, ProductSearchRequest.php, StoreProductRequest.php, UpdateProductRequest.php, ProductImageResource.php, ProductDetailResource.php, 7 API Routes, ProductAndModerationTest.php.
- **Automated Verification:** 8/8 tests in ProductAndModerationTest passed (92 assertions), 46/46 total tests passed across full suite (588 assertions), db:verify-seeders passed 100% with zero drift.
- **Next Action:** Ready for Task P6-05 (Cart, Checkout, Payment Mock & Escrow Ledger).


### Phase 06 - Task P6-05 Completed (2026-11-14)
- **Task:** Shopping Cart, Checkout Preview, Mock QR Payment & 3-Tier Cancellation (P6-05).
- **Artifacts:** CartService.php, CheckoutService.php, MockQrPaymentService.php, OrderCancellationService.php, CartController.php, CheckoutController.php, PaymentController.php, BuyerOrderController.php, 6 FormRequests (AddCartItemRequest, UpdateCartItemRequest, CheckoutPreviewRequest, PlaceOrderRequest, CancelOrderRequest, RespondCancelOrderRequest), 4 API Resources (OrderItemResource, PaymentResource, EscrowTransactionResource, OrderResource), 14 API Routes, CartOrderAndPaymentTest.php.
- **Automated Verification:** 8/8 tests in CartOrderAndPaymentTest passed (100 assertions), 54/54 total tests passed across full suite (697 assertions), db:verify-seeders passed 100% with zero drift.
- **Next Action:** Ready for Task P6-06 (Escrow Release, Shipping Fulfillment, Seller Wallet & Dispute Resolution).


### Phase 06 - Task P6-06 Completed (2026-11-14)
- **Task:** Order Fulfillment, 100% Escrow Release, Seller Wallet Ledger & Dispute Resolution (P6-06).
- **Artifacts:** OrderFulfillmentService.php, EscrowReleaseService.php, DisputeService.php, SellerOrderController.php, SellerWalletController.php, DisputeController.php, ShipOrderRequest.php, OpenDisputeRequest.php, SubmitDisputeEvidenceRequest.php, ShipmentResource.php, WalletTransactionResource.php, DisputeEvidenceResource.php, DisputeResource.php, EscrowShippingAndDisputeTest.php, 10 API routes.
- **Automated Verification:** 8/8 tests in EscrowShippingAndDisputeTest passed (78 assertions), 62/62 total tests passed across full suite (775 assertions), db:verify-seeders passed 100% with zero drift.
- **Next Action:** Ready for Task P6-07 (Auction Domain Services).


### Phase 06 - Task P6-07 Completed (2026-11-14)
- **Task:** Scheduled Auctions, Pessimistic Concurrent Bidding, Anti-Sniping, Close Early & Relist Services (P6-07).
- **Artifacts:** AuctionQueryService.php, AuctionBiddingService.php, AuctionLifecycleService.php, AuctionController.php, PlaceBidRequest.php, RelistAuctionRequest.php, AuctionBidResource.php, AuctionCardResource.php, AuctionDetailResource.php, AuctionEngineTest.php, 8 API Routes.
- **Automated Verification:** 8/8 tests in AuctionEngineTest passed (66 assertions), 70/70 total tests passed across full suite (841 assertions), db:verify-seeders passed 100% with zero drift.
- **Next Action:** Ready for Task P6-08 (Chat, Notification, Review & Engagement Services).


### Phase 06 - Task P6-08 Completed (2026-11-14)
- **Task:** 1-on-1 Chat Polling, Notifications, Verified Reviews, Engagement & Violation Reports (P6-08).
- **Artifacts:** ConversationChatService.php, NotificationService.php, ReviewService.php, EngagementService.php, ViolationReportService.php, ConversationController.php, NotificationController.php, ReviewController.php, EngagementController.php, ReportController.php, 4 FormRequests (StartConversationRequest, SendMessageRequest, StoreReviewRequest, StoreReportRequest), 4 API Resources (ConversationResource, MessageResource, NotificationResource, ReportResource), 12 API Routes, ChatNotificationAndEngagementTest.php.
- **Automated Verification:** 8/8 tests in ChatNotificationAndEngagementTest passed (62 assertions), 78/78 total tests passed across full suite (903 assertions), db:verify-seeders passed 100% with zero drift.
- **Next Action:** Ready for Task P6-09 (Background Jobs & Scheduler).


### Phase 06 - Task P6-09 Completed (2026-11-14)
- **Task:** 4 Idempotent Background Jobs, FOR UPDATE SKIP LOCKED, Laravel Scheduler & Demo Mode Triggers (P6-09).
- **Artifacts:** OrderExpirationService.php, SystemDevToolsService.php, SystemDevToolsController.php, 4 Queue Jobs (OpenScheduledAuctionsJob, CloseExpiredAuctionsJob, ExpireUnpaidAuctionOrdersJob, AutoCompleteDeliveredOrdersJob), routes/console.php, BackgroundJobsAndSchedulerTest.php, DevTools API Route.
- **Automated Verification:** 6/6 tests in BackgroundJobsAndSchedulerTest passed (47 assertions), 84/84 total tests passed across full suite (950 assertions), db:verify-seeders passed 100% with zero drift.
- **Next Action:** Ready for Task P6-10 (Full Backend Integration Testing, Security Audit & Phase 06 Sign-Off).


### Phase 06 - Task P6-10 & Full Phase 06 Sign-Off Completed (2026-11-14)
- **Task:** End-to-End Integration Testing, Full Ledger Reconciliation & Phase 06 Sign-Off (P6-10).
- **Artifacts:**
  - `backend/tests/Feature/Api/V1/Phase06EndToEndIntegrationTest.php` (4 full lifecycle journeys: Fixed-price listing to review, Auction bidding to relist, Dispute freeze to admin refund, and Full DB & Ledger reconciliation audit).
  - `docs/06_BACKEND_DEVELOPMENT/P6_10_INTEGRATION_AND_SIGN_OFF.md` (Approved specification & sign-off matrix).
  - All 11 documents in `docs/06_BACKEND_DEVELOPMENT/` updated to `DONE / APPROVED`.
  - `docs/00_PROJECT_GOVERNANCE/MASTER_TASK_TRACKER.md` updated with full Phase 06 tasks breakdown marked `DONE / APPROVED (100%)`.
- **Automated Verification:**
  - `php artisan system:health-check`: PASS (PHP 8.4.27, Laravel 13.42, PostgreSQL 18.7, Redis 7.4, Timezone Asia/Ho_Chi_Minh).
  - `php artisan db:verify-constraints`: PASS (79 business CHECK constraints active, 10/10 Negative Integrity Tests blocked by PostgreSQL 18).
  - `php artisan model:verify-architecture`: PASS (32 models mapped, 116 relationship methods, 5 immutable ledger guards).
  - `php artisan db:verify-seeders`: PASS (100% Integrity, Zero Ledger Drift across all Seller Profiles, DEC-04 equations valid).
  - `php artisan route:list --path=api/v1`: 74 REST API endpoints registered and verified.
  - `php artisan test`: 88/88 tests PASSED (1,040 assertions, 0 errors, 0 failures across all 11 suites).
- **Milestone Reached:** Backend Phase 06 is 100% COMPLETED and SIGNED OFF.
- **Next Action:** Ready for Phase 07 (Flutter Mobile App Development) or Phase 08 (Admin Blade Dashboard) upon user instruction.


### Phase 07 - Initialization & Environment Audit (2026-11-14)
- **Task:** Environment Readiness Audit & Phase 07 Documentation Setup (P7 Initialization).
- **Environment Status:**
  - Flutter SDK & Dart SDK: NOT detected in system PATH or standard folders. Need Flutter SDK 3.x installation before code execution.
  - Workspace directory `mobile/` verified clean and empty (0 files). Strictly no code generated yet.
- **Backend API Contract Verification:**
  - 74 RESTful API endpoints active under `/api/v1/*`.
  - Currency fields formatted as `(float)` / `NUMERIC(15,2)` in JSON responses (parsed in Dart via `SafeDecimalParser.toDouble`).
  - Timestamps serialized in ISO-8601 UTC/Asia/Ho_Chi_Minh (`TIMESTAMPTZ`), synchronized with device time via `ServerTimeService`.
  - Paginated responses standardized with `meta: { current_page, per_page, total, last_page, has_more_pages }`.
- **Artifacts:** Complete 13 specification documents in `docs/07_MOBILE_DEVELOPMENT/`:
  - `PHASE_07_IMPLEMENTATION_PLAN.md` (Mapping all 52 screens across 12 WBS packages, dependency graph, contract matrix).
  - `P7_01_ARCHITECTURE_AND_FOUNDATION.md` through `P7_12_INTEGRATION_AND_MOBILE_SIGN_OFF.md`.
- **Governance:** `MASTER_TASK_TRACKER.md` updated with 12 Phase 07 packages in `PLANNED / WAITING FOR PO APPROVAL`.
- **Next Action:** STOPPED. Awaiting PO approval and Flutter SDK installation before executing Task P7-01.


### Phase 07 - Task P7-01 Completed (2026-11-14)
- **Task:** Flutter Architecture, Project Foundation, 5-Tab Routing Shell & Core Utilities (P7-01).
- **Artifacts:**
  - `mobile/pubspec.yaml` (Flutter 3.50.0, Riverpod 2.6.1, GoRouter 14.8.1, Dio 5.11.1, SecureStorage 9.2.4, Intl 0.20.3, Shimmer, ImagePicker, CachedNetworkImage).
  - `mobile/lib/main.dart` & `mobile/lib/app.dart` (IzithriftApp wrapped in ProviderScope with MaterialApp.router).
  - `mobile/lib/core/config/env_config.dart` (Smart platform detection: 10.0.2.2 for Android emulator, 127.0.0.1 for desktop/web/iOS).
  - `mobile/lib/core/constants/api_endpoints.dart` (74 API endpoints mapped to constants).
  - `mobile/lib/core/utils/safe_json_parser.dart` (Safe casting for PostgreSQL 18 numeric, timestamp and boolean types).
  - `mobile/lib/core/utils/vnd_formatter.dart` (Standard and compact VNĐ currency formatting).
  - `mobile/lib/core/router/app_routes.dart` & `app_router.dart` (StatefulShellRoute for 5-Tab Navigation).
  - `mobile/lib/core/widgets/main_navigation_shell.dart` (5-Tab NavigationBar with warm vintage styling).
  - `mobile/test/core/foundation_test.dart` (Unit and widget test suite).
  - `docs/07_MOBILE_DEVELOPMENT/P7_01_ARCHITECTURE_AND_FOUNDATION.md` (Updated status to DONE).
- **Automated Verification:**
  - `flutter analyze`: No issues found! (0 errors, 0 warnings).
  - `flutter test`: 5/5 tests passed (100% PASS).
- **Next Action:** Ready for Task P7-02 (Design System Tokens, Seasonal Overlay & Shared UI Components).


### Phase 07 - Task P7-02 Completed (2026-11-14)
- **Task:** Design System Tokens, Warm Thrift Theme, Seasonal Holiday Decor Overlay & Shared UI Components (P7-02).
- **Artifacts:**
  - `mobile/lib/core/theme/app_colors.dart` (Warm Thrift Palette: backgroundCream #FBF8F3, surfaceCard #FFFFFF, surfaceWarm #F4EFE6, primaryTerracotta #C85A32, secondaryPineGreen #2D5A3C, accentVintageGold #D4AF37, christmasBerryRed #B22222, textCharcoal #231F20).
  - `mobile/lib/core/theme/design_tokens.dart` (Spacings, radii, border widths, elevation shadows).
  - `mobile/lib/core/theme/app_typography.dart` (TextStyles with `FontFeature.tabularFigures()` for currency and countdown digits).
  - `mobile/lib/core/theme/retro_theme.dart` (Material 3 ThemeData with warm editorial archive aesthetic).
  - `mobile/lib/core/theme/seasonal_decor_provider.dart` (Riverpod `seasonalDecorProvider` with SharedPreferences persistence for NFR-UX-02).
  - `mobile/lib/core/widgets/seasonal_decor_overlay.dart` (60fps festive garland overlay with `IgnorePointer(ignoring: true)`).
  - `mobile/lib/core/widgets/condition_badge.dart` (Vietnamese condition tags: LIKE_NEW, GOOD, FAIR, VINTAGE_WORN, NEW_WITH_TAGS).
  - `mobile/lib/core/widgets/verification_badge.dart` (HIGH_VALUE_VERIFIED, MODERATOR_REVIEWED, BASIC_CHECKED).
  - `mobile/lib/core/widgets/status_pill_badge.dart` (Standardized pills across 7 Product, 6 Auction, and 4 Order states).
  - `mobile/lib/core/widgets/price_breakdown_card.dart` (DEC-04 Buyer Protection Fee calculation, 100% Escrow guarantee, optional seller net receipt).
  - `mobile/lib/core/widgets/server_countdown_timer.dart` (Anti-Sniping <= 120s alert, extendedCount chip, tabular numbers).
  - `mobile/lib/core/widgets/defect_authenticity_box.dart` (BR-PR-03 secondhand defect disclosure and DEC-05 rejection alert).
  - `mobile/lib/core/widgets/retro_product_card.dart` & `retro_auction_card.dart` (BR-AC-02 seller ownership awareness).
  - `mobile/lib/core/widgets/state_feedback_views.dart` (RetroShimmerBox, RetroEmptyStateView, RetroErrorRetryView).
  - `mobile/lib/app.dart` (Applied RetroTheme.lightTheme and SeasonalDecorOverlay builder).
  - `mobile/test/core/design_system_components_test.dart` & `theme_and_components_test.dart` (8 widget & unit tests).
  - `docs/07_MOBILE_DEVELOPMENT/P7_02_DESIGN_SYSTEM_AND_COMPONENTS.md` (Updated status to DONE).
- **Automated Verification:**
  - `flutter analyze`: No issues found! (0 errors, 0 warnings).
  - `flutter test`: 21/21 total tests passed (100% PASS across foundation_test and design_system_components_test).
- **Next Action:** Ready for Task P7-03 (Dio API Client, Sanctum Token Storage, ServerClockSync & Error Interceptors).


### Phase 07 - Task P7-03 Completed (2026-11-14)
- **Task:** Dio API Client, 4 Dedicated Interceptors, Secure Token Storage, Server Clock Sync & Lifecycle Polling (P7-03).
- **Mandatory Technical Adjustments Delivered:**
  1. `LifecyclePollingController`: Concurrency lock (`_isPollingInProgress`) preventing overlapping network requests; auto pause on background (`paused`/`inactive`/`hidden`), auto resume on foreground (`resumed`), clean timer disposal.
  2. `AuthBearerInterceptor`: `optional.sanctum` compatibility (`DEC-01`). Attaches Bearer token to all endpoints (including `/bootstrap`, `/home`, `/products`, `/auctions`) to identify `current_user`, `is_favorited`, `is_owner`. Strictly omits token only on the 4 guest auth endpoints (`/auth/login`, `/auth/register`, `/auth/forgot-password`, `/auth/reset-password`).
  3. `ServerClockSyncInterceptor`: Listens and syncs `server_time` on BOTH HTTP 2xx responses AND HTTP 4xx/5xx error payloads (crucial for `409 AUCTION_OUTBID_CONFLICT` after Anti-Sniping deadline extensions).
- **Artifacts:**
  - `mobile/lib/core/error/error_code_enum.dart` (14 standardized backend error codes).
  - `mobile/lib/core/error/api_exception.dart` (Structured exception containing statusCode, errorCodeEnum, fieldErrors, latestState, serverTime, firstErrorFor).
  - `mobile/lib/core/services/secure_token_storage.dart` (Hardware-backed encrypted storage with `inMemory()` mode and `sessionAlerts` broadcast stream for 401/403).
  - `mobile/lib/core/services/server_time_service.dart` (authoritative server clock synchronization, `now()`, offset duration per BR-AU-01).
  - `mobile/lib/core/services/lifecycle_polling_controller.dart` (WidgetsBindingObserver lifecycle-aware polling engine).
  - `mobile/lib/core/network/interceptors/auth_bearer_interceptor.dart`.
  - `mobile/lib/core/network/interceptors/server_clock_sync_interceptor.dart`.
  - `mobile/lib/core/network/interceptors/api_envelope_error_interceptor.dart`.
  - `mobile/lib/core/network/interceptors/logging_interceptor.dart`.
  - `mobile/lib/core/network/api_envelope.dart` (`ApiEnvelope<T>`, `PaginatedResponse<T>`, `PaginationMeta`).
  - `mobile/lib/core/network/dio_client.dart` (Configured Dio instance with 10s connect / 15s receive timeouts, standard headers, 4-interceptor chain, multipart PUT support).
  - `mobile/lib/core/state/view_state.dart` (Generic 5-state UI container: initial, loading, success, empty, error).
  - `mobile/lib/core/state/base_view_model.dart` (BaseViewModel with `runCatching` and safe disposal).
  - `mobile/test/core/api_client_and_state_test.dart` (14 comprehensive unit/integration test scenarios).
  - `docs/07_MOBILE_DEVELOPMENT/P7_03_API_CLIENT_AND_STATE_CORE.md` (Updated with 3 mandatory adjustments, status DONE).
- **Automated Verification:**
  - `flutter analyze`: No issues found! (0 errors, 0 warnings).
  - `flutter test`: 35/35 total tests passed (100% PASS across `foundation_test`, `design_system_components_test`, and `api_client_and_state_test`).
- **Next Action:** Ready for Task P7-04 (Auth Flows M-AU-01..05, Unified Profile Hub & Address Book M-PF-01..04, 06).


### Phase 07 - Task P7-04 Completed (2026-11-14)
- **Task:** Authentication Flows (M-AU-01..05), Unified User Profile & Address Book (M-PF-01..04, 06) (P7-04).
- **Artifacts:**
  - `mobile/lib/features/auth/models/bootstrap_model.dart` (Parses GET /api/v1/bootstrap).
  - `mobile/lib/features/auth/models/user_model.dart` (`UserModel`, `UserProfileModel`, `SellerProfileModel` with `SafeJsonParser.toDouble` and `toBool`).
  - `mobile/lib/features/profile/models/profile_summary_model.dart` (Full account summary, `order_status_counts`, favorites & following counters).
  - `mobile/lib/features/profile/models/user_address_model.dart` (Delivery address with `fullAddress` getter).
  - `mobile/lib/features/auth/repositories/auth_repository.dart` (6 auth endpoints: bootstrap, login, register, logout, forgotPassword, resetPassword).
  - `mobile/lib/features/profile/repositories/profile_repository.dart` (4 endpoints: show profile, update profile with <= 5MB avatar NFR-SEC-05, seasonal settings NFR-UX-02, change password).
  - `mobile/lib/features/profile/repositories/address_repository.dart` (4 CRUD address endpoints).
  - `mobile/lib/features/auth/viewmodels/auth_view_model.dart` (Global auth state, onboarding flag, session alert listening for 401/403 BR-AC-04).
  - `mobile/lib/features/profile/viewmodels/profile_view_model.dart` (Profile summary, avatar update, instant seasonal decor sync).
  - `mobile/lib/features/profile/viewmodels/address_view_model.dart` (Address list management with single default invariant).
  - 10 Mobile Screens:
    - `mobile/lib/features/auth/screens/splash_screen.dart` (`M-AU-01`)
    - `mobile/lib/features/auth/screens/onboarding_screen.dart` (`M-AU-02`)
    - `mobile/lib/features/auth/screens/login_screen.dart` (`M-AU-03` with 403 ACCOUNT_SUSPENDED dialog)
    - `mobile/lib/features/auth/screens/register_screen.dart` (`M-AU-04` with BR-AC-01 unified Buyer/Seller callout)
    - `mobile/lib/features/auth/screens/forgot_reset_password_screen.dart` (`M-AU-05`)
    - `mobile/lib/features/profile/screens/unified_personal_hub_screen.dart` (`M-PF-01` with NAV-DEC-02 Seller Mode switch)
    - `mobile/lib/features/profile/screens/edit_profile_screen.dart` (`M-PF-02`)
    - `mobile/lib/features/profile/screens/address_list_screen.dart` (`M-PF-03`)
    - `mobile/lib/features/profile/screens/add_edit_address_screen.dart` (`M-PF-04` with VN phone regex)
    - `mobile/lib/features/profile/screens/app_settings_screen.dart` (`M-PF-06`)
  - `mobile/lib/core/router/app_routes.dart` & `mobile/lib/core/router/app_router.dart` (Registered all 10 screens).
  - `mobile/test/features/auth_and_profile_test.dart` (10 comprehensive widget & unit tests).
  - `docs/07_MOBILE_DEVELOPMENT/P7_04_AUTH_AND_USER_PROFILE.md` (Updated status to DONE).
- **Automated Verification:**
  - `flutter analyze`: No issues found! (0 errors, 0 warnings).
  - `flutter test`: 45/45 total tests passed (100% PASS across full mobile test suite).
- **Next Action:** Ready for Task P7-05 (Home Discovery M-HM-01..02, Category Tree & Multi-Filter Search M-DS-01..03).


### Phase 07 - Task P7-05 Completed & PO Signed Off (2026-11-15)
- **Task:** Home Discovery Feed (M-HM-01..02), Category Taxonomy (M-DS-01) & Multi-Criteria Search/Filter (M-DS-02..03) (P7-05).
- **PO Decision & Alignment:**
  - Standardized Condition to 5 levels across DB constraint, Backend Enum, and Mobile UI (`NEW_WITH_TAGS`, `LIKE_NEW`, `GOOD`, `FAIR`, `VINTAGE_WORN`).
  - Approved unified `HomeCatalogRepository` architecture.
  - Aligned API sorting parameter to `sort: newest | price_asc | price_desc | popular`.
  - Deferred SharedPreferences local search history to P7-12 (Polish & Final Review).
- **Automated Verification:**
  - `flutter analyze`: No issues found! (0 errors, 0 warnings).
  - `flutter test`: 57/57 total tests passed (100% PASS).
  - Backend tests: 88/88 passed (100% PASS).
- **Current Active Task:** `P7-07` (Seller Channel Hub M-SL-01, 7-State Listings M-SL-02..04 & Wallet Ledger M-SL-08) [IN PROGRESS].

### Phase 07 - Task P7-06 Completed & PO Signed Off (2026-11-15)
- **Task:** Product Detail (M-PD-01..02), Defect Zoom Viewer (M-DS-04) & Public Seller Storefront (M-US-03) (P7-06) [DONE].
- **Artifacts:**
  - `backend/database/migrations/2026_11_15_000001_update_products_condition_check_constraint.php` (DB constraint updated to 5 condition levels).
  - `mobile/lib/features/catalog/models/product_image_model.dart` (Photo model with `defect_note` and `image_type`).
  - `mobile/lib/features/catalog/models/product_detail_model.dart` (Full detail model with 5 Condition levels, DEC-04 price computation, seller snapshot, auction info, `is_owner`, `is_favorited`).
  - `mobile/lib/features/catalog/models/review_item_model.dart` (Verified purchase reviews model).
  - `mobile/lib/features/catalog/models/seller_public_profile_model.dart` (Seller public storefront with Trust Score, ratings, 4 tabs).
  - `mobile/lib/features/catalog/repositories/home_catalog_repository.dart` (Expanded with `fetchProductDetail`, `addToCart`).
  - `mobile/lib/features/catalog/repositories/seller_storefront_repository.dart` (`fetchSellerStorefront`, `toggleFollowSeller`, `fetchSellerReviews`).
  - `mobile/lib/features/catalog/viewmodels/product_detail_view_model.dart` (State management, favorite toggle, add-to-cart, BR-AC-02 self-purchase check).
  - `mobile/lib/features/catalog/viewmodels/seller_storefront_view_model.dart` (Storefront state, 4-tab filtering, follow toggle).
  - 4 Mobile Screens & Dialogs:
    - `mobile/lib/features/catalog/screens/product_detail_screen.dart` (`M-PD-01`: Image carousel, zoom trigger, PriceBreakdownCard DEC-04, defect box, seller micro-card, BR-AC-02 bottom action bar).
    - `mobile/lib/features/catalog/screens/defect_verification_modal.dart` (`M-PD-02`: Secondhand defect report, 5-tier condition guide, evidence closeup gallery).
    - `mobile/lib/features/catalog/screens/full_screen_zoom_viewer.dart` (`M-DS-04`: InteractiveViewer with pinch-to-zoom 400%, photo counter, thumbnail switcher, defect notes).
    - `mobile/lib/features/catalog/screens/public_seller_storefront_screen.dart` (`M-US-03`: Header with Trust Score, follow button, 4 tabs: Đang bán, Đấu giá, Đã bán, Đánh giá).
  - `mobile/lib/core/router/app_router.dart` (Registered `/products/:id` and `/sellers/:id`).
  - `mobile/test/features/product_and_storefront_test.dart` (7 unit and widget tests covering models, M-PD-01, M-PD-02, M-DS-04, M-US-03, BR-AC-02, DEC-01 guest prompts).
- **Automated Verification:**
  - `flutter analyze`: No issues found! (0 errors, 0 warnings).
  - `flutter test`: 64/64 total tests passed (100% PASS).
  - Backend tests: 88/88 passed (100% PASS).
- **Next Action:** Task P7-07 completed and moved to `REVIEW`. Awaiting PO verification and sign-off before proceeding to P7-08 (Cart & Checkout).

### Phase 07 - Task P7-07 Implementation Completed & Ready for Review (2026-11-15)
- **Task:** Seller Channel Hub (M-SL-01), 7-State Listings Manager (M-SL-02), Create/Edit Listing (M-SL-03..04) & Wallet Ledger (M-SL-08) (P7-07) [`DONE / PO APPROVED`].
- **Artifacts:**
  - **Models (`mobile/lib/features/seller/models/`):**
    - `seller_dashboard_model.dart`: Parses metrics, shop profile, balances (`wallet_balance`, `escrow_held_balance`), and action item counters.
    - `seller_product_item_model.dart`: Standardized model for 7 product statuses, 5 condition levels, `canRelist` flag (DEC-02), and `rejectionReason` (DEC-05).
    - `seller_product_form_payload.dart`: Validates payload enforcing `BR-PR-01` (Auction quantity locked to 1), `BR-PR-03` (Mandatory defect info >= 5 non-whitespace chars, 5 conditions), and `NFR-SEC-03` (max 10 images).
    - `wallet_transaction_model.dart`: Immutable append-only ledger transaction record (`CREDIT`/`DEBIT`, `amount`, `balance_after`, `wallet_tx_code`, `created_at`).
    - `seller_wallet_overview_model.dart`: Overview model combining wallet balance, escrow held funds, and transaction history.
  - **Repository (`mobile/lib/features/seller/repositories/`):**
    - `seller_channel_repository.dart`: Unified repository implementing `fetchDashboard`, `fetchSellerProducts`, `createProduct`, `updateAndResubmitProduct`, `updateProductStatus`, `relistAuctionProduct`, `fetchWalletLedger`.
  - **ViewModels (`mobile/lib/features/seller/viewmodels/`):**
    - `seller_hub_view_model.dart`: Hub dashboard metrics and wallet ledger data provider.
    - `seller_listings_view_model.dart`: 7-tab listings state with optimistic UI toggle (`APPROVED` <-> `HIDDEN`), draft deletion, and relist actions.
    - `seller_product_form_view_model.dart`: Form state management enforcing `BR-PR-01`, `BR-PR-03`, and clearing rejection reason upon resubmission (`DEC-05`).
  - **Screens (`mobile/lib/features/seller/screens/`):**
    - `seller_hub_screen.dart` (`M-SL-01`): Shop header, Seller Wallet Card (Forest green gradient), action counters grid, prominent `[+ ĐĂNG BÁN SẢN PHẨM MỚI]` CTA, and quick management links.
    - `seller_listings_screen.dart` (`M-SL-02`): 7-state horizontal TabBar, product cards with ConditionBadge, contextual action buttons (`[Xem lý do & Gửi duyệt lại]`, `[Ẩn bài/Hiện lại]`, `[Tái đăng đấu giá]`, `[Xóa nháp]`).
    - `create_listing_screen.dart` (`M-SL-03`): Fixed Price vs Auction toggle (locks quantity = 1 for auction), image selector, 5-tier condition choice chips, mandatory `defect_info` validation, `[Lưu bản nháp]` & `[Gửi phê duyệt ngay]`.
    - `edit_resubmit_listing_screen.dart` (`M-SL-04`): Displays pinned Burgundy Rejection Banner (`DEC-05`) with moderator feedback, pre-fills data, and `[Gửi duyệt lại (Resubmit)]` action clearing rejection reason and transitioning status to `PENDING_REVIEW`.
    - `seller_wallet_ledger_screen.dart` (`M-SL-08`): Wallet & escrow held balance summary, immutable ledger note, and chronological list of credit/debit transactions.
  - **Routing (`mobile/lib/core/router/`):**
    - `app_routes.dart` & `app_router.dart`: Registered `/seller`, `/seller/listings`, `/seller/create`, `/seller/listings/:id/edit`, `/seller/wallet`.
  - **Automated Test Suite (`mobile/test/features/seller_channel_test.dart`):**
    - 12 comprehensive unit and widget tests covering models, BR-PR-01, BR-PR-03, DEC-05, optimistic UI, M-SL-01, M-SL-02, M-SL-03, M-SL-04, M-SL-08 (100% PASS).
- **Automated Verification:**
  - `flutter analyze`: No issues found! (0 errors, 0 warnings across entire mobile app).
  - `flutter test`: 76/76 total tests passed (100% PASS across all core and feature tests).
  - `php artisan test`: 88/88 backend tests passed (100% PASS, 1043 assertions).
- **Current Status:** `P7-07` and `P7-08` marked `DONE / PO APPROVED`. Task `P7-09` (Buyer Orders M-OR-02..05, Seller Fulfillment M-SL-05..07, 3-Tier Cancellation DEC-06 & Dispute Resolution M-DP-01..03) is `IN PROGRESS`.

### Phase 07 - Task P7-08 Completed & PO Signed Off (2026-11-15)
- **Task:** Grouped Shopping Cart (M-CR-01), Checkout Preview DEC-04 (M-OR-01) & Mock QR Escrow Payment (M-PM-01..03) (P7-08) [`DONE / PO APPROVED`].
- **Artifacts:**
  - **Models (`mobile/lib/features/cart/models/`):**
    - `cart_item_model.dart`: Parses cart items with product code, image, 5-tier condition badge, price, stock limits, selection state, and item subtotal.
    - `cart_seller_group_model.dart`: Standardized model for store groups (`BR-OR-01`) with store name, seller id, trust score, items list, and group selection toggles.
    - `cart_model.dart`: Cart model containing `sellerGroups[]`, item counters, total amount calculations, and selection aggregations.
    - `checkout_preview_model.dart`: Standardized models for `CheckoutOrderGroupPreviewModel` and `CheckoutPreviewModel`, enforcing `DEC-04` ($6\% + 7.000đ$, $0đ$ shipping, $100\%$ net seller payout).
    - `payment_session_model.dart`: Model for Mock QR Payment Sessions, VietQR details, transfer content (`IZITHRIFT {order_code}`), countdown expiration, and Escrow hold state.
  - **Repository (`mobile/lib/features/cart/repositories/`):**
    - `cart_checkout_repository.dart`: Unified repository implementing `fetchCart`, `addToCart`, `updateCartItemQuantity`, `removeCartItem`, `previewCheckout`, `placeOrder`, `fetchPaymentStatus`, `simulatePaymentSuccess`, `simulatePaymentFailure`.
  - **ViewModels (`mobile/lib/features/cart/viewmodels/`):**
    - `cart_view_model.dart`: Manages grouped cart state, optimistic quantity updates bound to `availableQuantity`, store-level checkbox selection (`toggleSellerGroupSelection`), and select all.
    - `checkout_view_model.dart`: Manages checkout preview from `POST /api/v1/checkout/preview`, address selection, order note, and order submission creating payment session.
    - `payment_view_model.dart`: Manages QR code payment session, countdown timer sync, and simulation triggers (`simulateSuccess`, `simulateFailure`).
  - **Screens (`mobile/lib/features/cart/screens/`):**
    - `shopping_cart_screen.dart` (`M-CR-01`): Displays cart grouped per seller store (`BR-OR-01`), store-level checkboxes, item quantity stepper, empty state feedback (`RetroEmptyStateView`), and sticky bottom checkout summary bar.
    - `checkout_screen.dart` (`M-OR-01`): Displays delivery address card, grouped items per seller, order note input, transparent `PriceBreakdownCard` enforcing `DEC-04`, Escrow protection trust note, and `[Đặt hàng & Thanh toán QR]` CTA.
    - `mock_qr_payment_screen.dart` (`M-PM-01`): Displays VietQR frame with simulated payment info, payment code, bank account details, transfer content with copy-to-clipboard, `ServerCountdownTimer` synced with server clock (`BR-AU-01`), and Demo Mode simulation buttons (`[✅ Mô phỏng Thanh toán Thành công]`, `[❌ Mô phỏng Thanh toán Thất bại]`).
    - `payment_success_screen.dart` (`M-PM-02`): Confirms buyer payment succeeded, displays order code, paid amount, `order_status: PAID`, `escrow_status: HELD` (`BR-FN-03`), Escrow protection explanation, and navigation buttons.
    - `payment_failure_screen.dart` (`M-PM-03`): Displays payment failure or expiration details, failure reason banner, and retry CTA (`[Thử thanh toán lại / Tạo mã mới]`) / return home button.
  - **Routing (`mobile/lib/core/router/`):**
    - `app_routes.dart` & `app_router.dart`: Added `AppRoutes.cart`, `AppRoutes.checkout`, `AppRoutes.paymentQr`, `AppRoutes.paymentSuccess`, `AppRoutes.paymentFailure`.
  - **Automated Test Suite (`mobile/test/features/cart_and_checkout_test.dart`):**
    - 10 comprehensive unit and widget tests covering SafeJsonParser, DEC-04 fee calculations, `CartViewModel` selection logic, `ShoppingCartScreen` (`M-CR-01`), `CheckoutScreen` (`M-OR-01`), `MockQrPaymentScreen` (`M-PM-01`), `PaymentSuccessScreen` (`M-PM-02`), and `PaymentFailureScreen` (`M-PM-03`) (100% PASS).
- **Automated Verification:**
  - `flutter analyze`: No issues found! (0 errors, 0 warnings across entire mobile app).
  - `flutter test`: 86/86 total tests passed (100% PASS across all core and feature test suites).
  - `php artisan test`: 88/88 backend tests passed (100% PASS, 1043 assertions).
- **Next Action:** Task P7-08 signed off. Completed execution of Task P7-09 (Buyer Orders M-OR-02..05, Seller Fulfillment M-SL-05..07, 3-Tier Cancellation DEC-06 & Dispute Resolution M-DP-01..03) [`DONE / PO APPROVED`]. Proceeding with execution of Task P7-10 (Auction Experience M-AC-01..06).

### Phase 07 - Task P7-09 Completed & PO Signed Off (2026-11-15)
- **Task:** Buyer Orders (M-OR-02..05), Seller Fulfillment (M-SL-05..07), 3-Tier Cancellation DEC-06 & Dispute Resolution (M-DP-01..03) (P7-09) [`DONE / PO APPROVED`].
- **Artifacts:**
  - **Models (`mobile/lib/features/orders/models/`):**
    - `order_item_snapshot_model.dart`: Immutable product snapshot (product title, code, unit price, quantity, line total, condition, defect info, primary image).
    - `shipment_model.dart`: Standardized `ShipmentModel` and `ShipmentTimelineEventModel` capturing carriers (GHN, GHTK, Viettel Post, J&T), tracking codes, shipping notes, milestone status, and timestamps.
    - `order_model.dart`: Comprehensive domain model governing the 4 independent state machines (`order_status`, `payment_status`, `escrow_status`, `dispute_status`), transparent financial equation (`DEC-04`), immutable shipping address snapshot, 3-tier cancellation controls (`DEC-06` / `DEC-07`), timestamps (`autoCompleteAt`, `paymentExpiresAt`), auxiliary IDs, and helper `buildFullLifecycleTimeline()`.
    - `dispute_evidence_model.dart`: Multi-role counter-evidence item (`BUYER_PROOF`, `SELLER_COUNTER_PROOF`, `STAFF_REQUEST_NOTE`) with uploader role, message note, and up to 5 attachments (`BR-DP-02`).
    - `dispute_model.dart`: Dispute case domain model managing frozen escrow funds, reason categories, admin verdict (`FULL_REFUND_TO_BUYER`, `RELEASE_TO_SELLER`, `PARTIAL_REFUND`), refund amounts, and 2-way counter-evidence list.
  - **Repository (`mobile/lib/features/orders/repositories/`):**
    - `order_fulfillment_repository.dart`: Unified repository implementing `fetchMyPurchases`, `fetchOrderDetail`, `cancelOrder`, `withdrawCancelRequest`, `confirmDeliveryAndReleaseEscrow`, `fetchSellerOrders`, `markOrderPreparing`, `shipOrder`, `markOrderDelivered`, `respondToCancelRequest`, `fetchDisputes`, `fetchDisputeDetail`, `openDispute`, and `submitDisputeEvidence`.
  - **ViewModels (`mobile/lib/features/orders/viewmodels/`):**
    - `buyer_order_view_model.dart`: Manages 9 status tabs, order detail, 3-tier cancellation actions (`submitCancelOrder`), withdraw cancel request (`withdrawCancelRequest`), and 100% Escrow release (`confirmDelivery`).
    - `seller_order_view_model.dart`: Manages 7 seller tabs, seller order detail, pipeline operations (`markPreparing`, `shipOrder`, `markDelivered`), and urgent cancellation response (`respondCancelRequest`).
    - `dispute_view_model.dart`: Manages opening dispute with description >= 10 chars validation and max 5 attachments constraint, fetching dispute case detail, and submitting counter-evidence.
  - **Screens & Modals (`mobile/lib/features/orders/screens/`):**
    - `my_purchases_screen.dart` (`M-OR-02`): 9 status tabs (`ALL`, `PENDING_PAYMENT`, `PAID`, `PREPARING`, `SHIPPED`, `DELIVERED`, `COMPLETED`, `CANCELLED`, `DISPUTED`), snapshot cards, and contextual action buttons.
    - `purchase_order_detail_screen.dart` (`M-OR-03`): Displays 4 independent state machines card, item snapshots, recipient address snapshot, auto-complete countdown timer (`ServerCountdownTimer`), transparent `PriceBreakdownCard` (`DEC-04`), and bottom action bar with `[Đã nhận được hàng & Hài lòng]` (`confirmDeliveryDialog`).
    - `order_cancellation_dialog.dart` (`M-OR-04`): Modal dialog dynamically adapting to 3 tiers of cancellation: Level 1 (`PENDING_PAYMENT` instant cancel), Level 2 (`PAID` automatic 100% refund), Level 3 (`PREPARING` approval request to seller).
    - `shipment_tracking_screen.dart` (`M-OR-05`): Displays carrier, tracking code, and visual milestone lifecycle timeline (`buildFullLifecycleTimeline`).
    - `seller_orders_screen.dart` (`M-SL-05`): 7 seller pipeline tabs (`ALL`, `PAID`, `PREPARING`, `SHIPPED`, `DELIVERED`, `CANCEL_REQUESTED`, `COMPLETED`), urgent cancellation alerts, and quick actions.
    - `seller_order_detail_screen.dart` (`M-SL-06`): Displays 4 state machines header, urgent cancellation response card with `[Đồng ý hủy & Hoàn tiền]` (`APPROVE`) and `[Từ chối hủy]` (`REJECT`), customer address card, and pipeline CTA bar (`[Bắt đầu chuẩn bị]`, `[Giao hàng cho vận chuyển]`, `[Xác nhận đã giao hàng]`).
    - `ship_order_form_modal.dart` (`M-SL-07`): Modal Bottom Sheet for selecting carrier, entering tracking code, adding shipping notes, and submitting shipment.
    - `open_dispute_screen.dart` (`M-DP-01`): Dispute opening form with reason category dropdown, minimum 10 characters description validation, up to 5 photos attachments constraint (`BR-DP-02`), and Escrow freeze warning notice.
    - `dispute_detail_screen.dart` (`M-DP-02`): Displays dispute status, Escrow frozen amount banner, official admin verdict banner (`FULL_REFUND_TO_BUYER`, `RELEASE_TO_SELLER`, `PARTIAL_REFUND`), and 2-way counter-evidence chronological thread.
    - `submit_counter_evidence_screen.dart` (`M-DP-03`): Submit counter-evidence form with role selector (`SELLER_COUNTER_PROOF`, `BUYER_PROOF`), message note, and up to 5 photo attachments.
  - **Routing (`mobile/lib/core/router/`):**
    - `app_routes.dart` & `app_router.dart`: Registered `/orders/purchases`, `/orders/:id`, `/orders/:id/tracking`, `/seller/orders`, `/seller/orders/:id`, `/orders/:id/dispute/create`, `/disputes/:id`, `/disputes/:id/evidence`.
  - **Automated Test Suite (`mobile/test/features/orders_and_disputes_test.dart`):**
    - 15 comprehensive unit and widget tests covering SafeJsonParser, 4 state machines, 3-tier cancellation dialog, Escrow release, seller fulfillment pipeline, carrier validation, timeline rendering, dispute validation (>= 10 chars, max 5 photos), and counter-evidence history (100% PASS).
- **Automated Verification:**
  - `flutter analyze`: No issues found! (0 errors, 0 warnings across entire mobile app).
  - `flutter test`: 101/101 total tests passed (100% PASS across all core and feature test suites).
  - `php artisan test`: 88/88 backend tests passed (100% PASS, 1043 assertions).
- **Current Status:** `P7-09` completed and marked `DONE / PO APPROVED`. Task `P7-10` is `COMPLETED / READY FOR USER REVIEW`.

### Phase 07 - Task P7-10 Completed & Ready for Review (2026-11-15)
- **Task:** Scheduled Auction Hub (M-AC-01), My Auctions (M-AC-02), Live Bidding Room & Anti-Sniping (M-AC-03), 409 Conflict Bid Sheet (M-AC-04), Close Early (M-AC-05) & Relist (M-AC-06) (P7-10) [`REVIEW`].
- **Artifacts:**
  - **Models (`mobile/lib/features/auctions/models/`):**
    - `auction_bid_item_model.dart`: Parses bid ID, auction ID, bidder ID, bid amount, previous highest bid, anti-sniping trigger flag, masked bidder name (`u***9`), avatar URL, `is_mine`, and `is_leading`.
    - `outbid_conflict_state_model.dart`: Captures 409 `AUCTION_OUTBID_CONFLICT` envelope `latest_state` (`current_highest_bid`, `minimum_next_bid`, `leading_bidder_id`, `bid_count`, `auction_ends_at`, `extended_count`).
    - `auction_card_model.dart`: Hub and personal cards with product, seller trust score, countdown timestamps, leading/outbid flags, and copyWith.
    - `auction_detail_model.dart`: Complete room detail containing product details, image gallery, condition, authenticity guarantee, reserve price status (hidden/revealed/met), winner and payment deadline (`payment_deadline_at`), and recent bids.
  - **Repository (`mobile/lib/features/auctions/repositories/`):**
    - `auction_repository.dart`: Fully integrated with 8 backend endpoints (`/api/v1/auctions`, `/api/v1/auctions/mine`, `/api/v1/auctions/{id}`, `/api/v1/auctions/{id}/bids`, `/api/v1/auctions/{id}/watch`, `/api/v1/auctions/{id}/close-early`, `/api/v1/seller/products/{id}/relist`), synchronizes authoritative `ServerTimeService`, and passes 409 `latestState` to ViewModels.
  - **ViewModels (`mobile/lib/features/auctions/viewmodels/`):**
    - `auction_hub_view_model.dart`: Manages 4 hub tabs (`live`, `ending_soon`, `upcoming`, `completed`), optimistic watch toggle, and pagination.
    - `my_auctions_view_model.dart`: Manages 3 personal auction tabs (`participating`, `watchlist`, `won`), calculates `leadingCount` and `outbidCount`.
    - `live_auction_view_model.dart`: Manages real-time short polling (3s) using `LifecyclePollingController` (paused on background, resumed on foreground), Anti-Sniping detection (`BR-AU-04`), concurrent bid placement with 409 Conflict state retention and seamless sheet update, seller close early (`BR-AU-05`), and seller relist (`DEC-02`).
  - **Screens & Modals (`mobile/lib/features/auctions/screens/`):**
    - `scheduled_auction_hub_screen.dart` (`M-AC-01`): Tab 3 root of 5-tab shell, featuring 4 tabs, auction cards with synchronized countdown, and quick watch toggle.
    - `my_auctions_screen.dart` (`M-AC-02`): 3 tabs (`participating`, `watchlist`, `won`), `👑 BẠN ĐANG DẪN ĐẦU` and `⚠️ ĐÃ BỊ VƯỢT GIÁ` badges, `[Trả giá lại ngay]` CTA, and Won tab with 30-minute payment countdown alert (`BR-AU-07`) and `[Thanh toán đơn hàng ngay 💳]` CTA.
    - `live_bidding_room_screen.dart` (`M-AC-03`): Central synchronized server countdown (`ServerCountdownTimer`), sticky Anti-Sniping warning alert (`⚡ Đã kích hoạt Anti-Sniping (+2 phút) • Gia hạn lần #X`), condition badge, reserve price disclosure, real-time live bid history list with `👑 Dẫn đầu` and `Tôi` badges, owner restrictions (`BR-AC-02`), and `[Chốt phiên sớm]` / `[🔨 ĐẶT GIÁ THẦU NGAY]` action bar.
    - `bid_placement_bottom_sheet.dart` (`M-AC-04`): Quick bid chips (`min_next_bid`, `+1 bước`, `+2 bước`), custom input validation, and graceful 409 `AUCTION_OUTBID_CONFLICT` retention (sheet does not close, retains latest state, adapts chips immediately).
    - `seller_close_early_modal.dart` (`M-AC-05`): Confirmation dialog for seller to close auction early for highest bidder (`BR-AU-05`).
    - `seller_relist_auction_modal.dart` (`M-AC-06`): Modal bottom sheet for seller to relist unsold (`ENDED_UNSOLD`) or defaulted (`WINNER_DEFAULTED`) product with updated starting price, min increment, and duration.
  - **Routing (`mobile/lib/core/router/`):**
    - `app_routes.dart` & `app_router.dart`: Wired Tab 3 to `ScheduledAuctionHubScreen`, registered `AppRoutes.myAuctions` (`/auctions/mine`), and `AppRoutes.auctionRoom` (`/auctions/:id`).
  - **Automated Test Suite (`mobile/test/features/auctions_test.dart`):**
    - 10 comprehensive unit and widget tests covering SafeJsonParser, OutbidConflictStateModel, AuctionHubViewModel, MyAuctionsViewModel, LiveAuctionViewModel Anti-Sniping & 409 Conflict handling, ScheduledAuctionHubScreen 4 tabs, MyAuctionsScreen leading/outbid/won countdown, LiveBiddingRoomScreen countdown & owner restrictions, BidPlacementBottomSheet 409 retention, SellerCloseEarlyModal, and SellerRelistAuctionModal (100% PASS).
- **Automated Verification:**
  - `flutter analyze`: No issues found! (0 errors, 0 warnings across entire mobile app).
  - `flutter test`: 111/111 total tests passed (100% PASS across all core and feature test suites).
  - `php artisan test`: 88/88 backend tests passed (100% PASS, 1043 assertions).
- **Current Status:** `P7-10` completed and marked `DONE / PO APPROVED`. Task `P7-11` is `COMPLETED / READY FOR USER REVIEW`.

### Phase 07 - Task P7-11 Completed & Approved (2026-11-15)
- **Task:** 1-on-1 Chat Polling (M-CM-01..03), Deep-Link Notifications (M-NT-01), Saved Favorites & Followed Shops (M-PF-05) & Verified Reviews (M-RV-01..02) (P7-11) [`DONE`].
- **Artifacts:**
  - **Models (`mobile/lib/features/engagement/models/`):**
    - `chat_context_card_model.dart`: Pinned product or order context summary with ID, title, price/total amount, and order status.
    - `message_model.dart`: Parses message ID, conversation ID, sender ID, content, attached product, read status, `isMine` detection via `currentUserId`.
    - `conversation_model.dart`: Inbox item parsing partner name, avatar, trust score, unread count, last message preview, timestamp, `is_blocked` flag, and pinned context card.
    - `notification_item_model.dart`: Category normalization (`ORDER`, `AUCTION`, `SYSTEM`), title, body, deep-link route, formatted time, and read status.
    - `violation_report_payload.dart`: Encapsulates violation report payload (`target_type`, `target_id`, `reason_category`, `description`, `block_conversation`).
    - `saved_engagement_overview_model.dart`: Aggregates favorited products and followed shops.
    - `seller_reviews_summary_model.dart`: Aggregates seller average rating, total reviews, star distribution map (1..5 stars), and review items list.
  - **Repository (`mobile/lib/features/engagement/repositories/`):**
    - `communication_engagement_repository.dart`: Integrated with 13 backend endpoints (`/api/v1/conversations`, `/api/v1/conversations/{id}/messages`, `/api/v1/reports`, `/api/v1/notifications`, `/api/v1/notifications/{id}/read`, `/api/v1/notifications/read-all`, `/api/v1/profile/favorites`, `/api/v1/products/{id}/favorite`, `/api/v1/sellers/{id}/follow`, `/api/v1/orders/{id}/reviews`, `/api/v1/sellers/{id}/reviews`).
  - **ViewModels (`mobile/lib/features/engagement/viewmodels/`):**
    - `chat_view_model.dart`: Manages inbox and active chat room, controlled HTTP Short-Polling (3s) with `?after_id=` (`ADR-08, NFR-PER-03`), pauses polling on background or when conversation is blocked, handles message sending, and submits violation report with room lock.
    - `notification_view_model.dart`: Manages 4 category tabs (`ALL`, `ORDER`, `AUCTION`, `SYSTEM`), optimistic single mark-as-read, optimistic mark-all-read, and deep-link route dispatching (`AC-P711-02`).
    - `engagement_and_review_view_model.dart`: Manages `EngagementViewModel` (optimistic favorite toggling on products and follow toggling on shops) and `ReviewViewModel` (validates 1..5 stars rating and comment length >= 5 chars according to `BR-RV-01`, and manages seller reviews list with star filter).
  - **Screens & Modals (`mobile/lib/features/engagement/screens/`):**
    - `conversation_inbox_screen.dart` (`M-CM-01`): Tab 4 root of 5-tab shell (`/messages`), avatar, partner name, last message snippet, timestamp, red unread counter badge, and product thumbnail.
    - `chat_room_screen.dart` (`M-CM-02`): Pinned context card at top (product thumbnail, title, price, "Xem đồ" CTA or order code, status, total, "Xem đơn" CTA), 3-dots popup menu (Report & Block, View Shop), chat bubbles (Pine Green / right for me, Soft Beige / left for partner), and bottom input bar (locked with banner when blocked).
    - `report_and_block_modal.dart` (`M-CM-03`): Modal bottom sheet with violation category radios, detailed explanation textarea (>= 10 chars), block toggle switch, and submit button.
    - `notification_center_screen.dart` (`M-NT-01`): Category filter chips, mark all read CTA, notification items with icon per category, unread dot, and deep-link navigation on tap.
    - `saved_favorites_and_shops_screen.dart` (`M-PF-05`): Tab 1 Favorite Products (2-column `RetroProductCard` grid with instant heart toggle) and Tab 2 Followed Shops (shop card with Trust Score, active listings count, and unfollow button).
    - `submit_verified_review_screen.dart` (`M-RV-01`): Accessible for completed orders (`BR-RV-01`), 1 to 5 interactive stars, comment textarea (min 5 chars), verified purchase pledge guarantee notice, and submit button.
    - `seller_reviews_list_screen.dart` (`M-RV-02`): Aggregated average rating (e.g. ⭐ 4.9/5.0), star distribution progress bars (5 down to 1), star rating filter chips, and verified buyer review items.
  - **Routing (`mobile/lib/core/router/`):**
    - `app_routes.dart` & `app_router.dart`: Wired Branch 4 to `ConversationInboxScreen`, registered `AppRoutes.chatRoom` (`/messages/:id`), `AppRoutes.notifications` (`/notifications`), `AppRoutes.favorites` (`/profile/favorites`), `AppRoutes.orderReview` (`/orders/:id/review`), `AppRoutes.sellerReviews` (`/sellers/:id/reviews`).
  - **Automated Test Suite (`mobile/test/features/chat_and_engagement_test.dart`):**
    - 17 comprehensive unit and widget tests covering SafeJsonParser, ConversationModel, MessageModel, NotificationItemModel, SellerReviewsSummaryModel, ChatViewModel polling with `?after_id=`, NotificationViewModel tab filtering and deep-link routing, EngagementViewModel optimistic toggles, ReviewViewModel validation (1..5 stars, >= 5 chars), and full widget tests for all 7 screens & modals (100% PASS).
- **Automated Verification:**
  - `flutter analyze`: No issues found! (0 errors, 0 warnings across entire mobile app).
  - `flutter test`: 128/128 total tests passed (100% PASS across all core and feature test suites).
  - `php artisan test`: 88/88 backend tests passed (100% PASS, 1043 assertions).
- **Current Status:** `P7-11` completed and marked `DONE / PO APPROVED`. Task `P7-12` (Final Integration Gate & Mobile Sign-Off) is `DONE / 100% VERIFIED & PO APPROVED`.

### Phase 07 - Task P7-12 Completed & Phase 07 Sign-Off (2026-11-15)
- **Task:** Final 52-Screen Integration, Search History Polish, E2E Test Suite & Phase 07 Sign-Off (P7-12) [`DONE / 100% VERIFIED`].
- **Artifacts:**
  - **Search History Polish (P7-05 Deferred Item):**
    - `mobile/lib/features/catalog/viewmodels/catalog_search_view_model.dart`: Integrated `SharedPreferences` persistence for recent search keywords (`recent_search_keywords`), capped at 10 items, deduplicated, with load, add, remove, and clear operations.
    - `mobile/lib/features/catalog/screens/product_search_screen.dart`: Wired recent search chips with delete action and "Xóa tất cả" quick clear.
  - **5-Tab Navigation Shell & Routing Integration:**
    - `mobile/lib/core/router/app_router.dart`: All 5 shell branches wired to functional screens (Tab 1: `HomeScreen`, Tab 2: `CategoryTaxonomyScreen`, Tab 3: `ScheduledAuctionHubScreen`, Tab 4: `ConversationInboxScreen`, Tab 5: `UnifiedPersonalHubScreen`).
    - Removed legacy stub views; verified all 52 mobile screens registered in `AppRoutes` and navigable via GoRouter.
  - **E2E Integration Test Suite (`mobile/test/features/phase_07_e2e_integration_signoff_test.dart`):**
    - 6 end-to-end integration scenarios verifying:
      1. 5-Tab Shell seamless switching + SeasonalDecorOverlay Christmas toggle.
      2. SharedPreferences search history load, chip search, and clear operations.
      3. E2E Checkout Preview (DEC-04) -> QR Escrow Hold -> Confirm Delivery 100% seller net payout.
      4. Seller views DEC-05 rejection reason banner & inspects immutable Append-Only Wallet Ledger.
      5. Live Bidding Room Anti-Sniping (+2 min extension) & 409 Outbid Conflict state retention on BidPlacementBottomSheet.
      6. 1-on-1 Chat Room with pinned context + Polling, Notification Center deep-link, and Verified Review submission (BR-RV-01).
- **Automated Verification:**
  - `flutter analyze`: **0 issues found** (0 errors, 0 warnings across entire Flutter app).
  - `flutter test`: **134/134 tests passed** (100% PASS across all 12 core and feature test suites).
  - `php artisan test`: **88/88 tests passed** (100% PASS, 1043 assertions).
- **Phase 07 Final Sign-Off:**
  - **Total Screens Delivered:** 52/52 screens.
  - **Total Automated Tests:** 134 Mobile tests + 88 Backend tests = 222 tests (100% PASS).
  - **Phase 07 Status:** `DONE / APPROVED (OFFICIAL PO SIGN-OFF)`. Toàn bộ 52 màn hình hoàn tất, 100% kiểm định vượt qua.

### Official PO Sign-Off: Phase 07 Completed & Handoff to Phase 08 (2026-11-15)
- **Decision:** Product Owner CHÍNH THỨC PHÊ DUYỆT HOÀN THÀNH PHASE 07 – Flutter Mobile Application (P7-01..P7-12).
- **Evidence Base:** Nghiệm thu kỹ thuật căn cứ trên `docs/07_MOBILE_DEVELOPMENT/PHASE_07_FINAL_PO_SIGNOFF_READINESS.md` và `docs/07_MOBILE_DEVELOPMENT/PHASE_07_SUPPLEMENTARY_AUDIT_REPORT.md`.
- **Database Schema Sync:** PO cho phép đồng bộ `docs/04_SYSTEM_ARCHITECTURE_AND_DB/02_DATABASE_DESIGN/DB_01_CORE_SCHEMA.md` dòng 331 từ 4 bậc lên 5 bậc Product Condition (`NEW_WITH_TAGS`, `LIKE_NEW`, `GOOD`, `FAIR`, `VINTAGE_WORN`) khớp với PostgreSQL 18 hiện hành. Không tạo migration mới và không sửa mã nguồn.
- **Phase 10 Backlog:** Ghi nhận 8 API routes cần Direct HTTP test và Negative tests cho Product Condition (HTTP 422) vào Phase 10 (Testing & QA). Ưu tiên các endpoint đơn hàng, khiếu nại và seller.
- **Handoff Status:** Phase 07 `DONE / APPROVED (OFFICIAL PO SIGN-OFF)`. Phase 08 `READY FOR DISCOVERY`.
- **Admin Tech Guidelines:** Admin Web sử dụng Session-based `web` guard với `SESSION_DRIVER=redis` (Redis 7.4), bảo toàn 34 bảng nghiệp vụ PostgreSQL 18 theo `TECH-05`.


---

## TASK P8-01 EXECUTION LOG & VERIFICATION REPORT
- **Task ID:** `P8-01: Admin Foundation, Master Shell, Web Session Auth, Redis 7.4 Runtime Verification & 3-Tier RBAC`
- **Execution Mode:** END-TO-END IMPLEMENTATION & VERIFICATION
- **Executed At:** `2026-11-16`
- **Current Status:** `REVIEW` (Awaiting PO Inspection and Sign-Off)
- **Baseline Git Commit:** `4a1171ff9087fd66365342a215e615ed001ea141` (`main`)

### 1. Scope & Acceptance Criteria Delivery
- **AC-P801-01 (Canonical 21-Screen Master Inventory):** Authored `docs/08_ADMIN_DEVELOPMENT/PHASE_08_IMPLEMENTATION_PLAN.md` mapping all 21 canonical Admin screens across 6 Work Packages (`P8-01`..`P8-06`), actors, route names, 61 granular permissions, and source references.
- **AC-P801-02 (Web Session Auth & Shell):** Created `EnsureAdminAuthenticated` middleware, `AdminAuthController` (`showLoginForm`, `login`, `logout`), and login view `A-AU-01` (`/admin/login`). Enforces session regeneration on login, generic error messaging preventing user enumeration, and open redirect protection strictly bounding redirects within `/admin/*`.
- **AC-P801-03 (Redis 7.4 Runtime Verification):** Validated live container `retromarket_redis7` (Redis 7.4-alpine on port 6379). Implemented `P801_RedisSessionRuntimeTest.php` verifying connection ping, session storage, key prefixing, TTL, and key deletion without executing `FLUSHDB` or `FLUSHALL`.
- **AC-P801-04 (Brute-force Throttling):** Enforced 5 login attempts per minute per `email|ip` via Laravel RateLimiter. Verified 6th attempt triggers 429/validation throttle error with decay seconds, and successful login clears rate limit.
- **AC-P801-05 (3-Tier RBAC & Default Deny):** Created `AdminPermission` helper and `EnsureAdminPermission` middleware. Enforced Default Deny:
  - Admin: Full system access across all screens.
  - Moderator: Catalog, Products, Categories, Reports, Reviews, Auctions. Blocked from Orders/Escrow & Settings (403).
  - Support: Orders, Escrow, Disputes, Reports. Blocked from Product Moderation & Settings (403).
  - Registered User: Strictly denied from all admin routes (403), terminating session immediately.
  - Mid-Session Suspension Revocation: External status change (`ACTIVE` -> `SUSPENDED`) immediately invalidates active web session on next request.
- **AC-P801-06 (Immutable Audit Logging):** `ADMIN_LOGIN` and `ADMIN_LOGOUT` events logged via `AuditLog::create()` with zero sensitive data (`password`, `password_hash`, `_token`, session IDs excluded). Verified immutability via `ImmutableLedgerRecord` trait (`update()` and `delete()` blocked with `LogicException`).
- **AC-P801-07 (CSRF Protection):** Verified CSRF enforcement with HTTP 419 (Page Expired) on missing/invalid token.
- **AC-P801-08 (Sanctum Token Isolation):** Verified Web Admin session login/logout does not create, touch, or delete Mobile API personal access tokens in `personal_access_tokens`.

### 2. UI & Frontend Asset Compilation
- **Tailwind CSS v4 Design Tokens:** Configured Warm Editorial Archive palette (`#FBF8F3`, `#C85A32`, `#2D5A3C`, `#D4AF37`, `Fraunces`, `Be Vietnam Pro`, `tabular-nums`).
- **Vite Build:** `cd backend; npm run build` compiled assets in 150ms with 0 errors.
- **Screens Delivered:**
  - `A-AU-01`: Admin Staff Login (`resources/views/admin/auth/login.blade.php`).
  - `A-DB-01`: Executive Operational Dashboard (`resources/views/admin/dashboard.blade.php`) with role-scoped metrics for Admin, Moderator, and Support.
  - Master Shell Layout: `resources/views/layouts/admin.blade.php` and role-aware partials (`topbar`, `sidebar`, `alerts`, `errors`).

### 3. Automated Test Verification Results
- **Backend P8-01 Feature Test Suite (`backend/tests/Feature/Admin/`):** **26/26 PASS** (112 assertions, 0 failures, 2.7s):
  - `P801_AdminAuthAndSessionTest`: 10/10 PASS
  - `P801_AdminRbacAndDefaultDenyTest`: 12/12 PASS
  - `P801_AdminAuditLogInvarianceTest`: 1/1 PASS
  - `P801_RedisSessionRuntimeTest`: 3/3 PASS
- **PostgreSQL 18 Integrity Constraints:** `php artisan db:verify-constraints` -> **79 CHECK constraints active, 10/10 negative integrity scenarios PASS**.
- **Full Backend Regression:** `php artisan test` -> **114/114 PASS** (1,157 assertions, 0 failures across all API and Admin suites).
- **Mobile Regression:**
  - `flutter analyze`: **0 issues found** (0 errors, 0 warnings).
  - `flutter test`: **134/134 PASS** (100% across all 12 mobile test suites).


---

## TASK P8-02 EXECUTION LOG & VERIFICATION REPORT
- **Task ID:** `P8-02: Taxonomy, Products & Moderation Queue`
- **Execution Mode:** END-TO-END IMPLEMENTATION & VERIFICATION
- **Executed At:** `2026-11-16`
- **Current Status:** `REVIEW` (Awaiting PO Inspection and Sign-Off)
- **Baseline Git Commit:** `4a1171ff9087fd66365342a215e615ed001ea141` (`main`)

### 1. Scope & Acceptance Criteria Delivery
- **AC-P802-01 (Moderation Queue & Split-Pane Evidence Detail):**
  - Delivered `A-MD-01` (`/admin/moderation/products`): Hàng đợi `PENDING_REVIEW` với đầy đủ bộ lọc tìm kiếm, loại hình bán (`FIXED_PRICE`/`AUCTION`), đủ 5 mức `ProductCondition` (`NEW_WITH_TAGS`, `LIKE_NEW`, `GOOD`, `FAIR`, `VINTAGE_WORN` – `BR-PR-03`), danh mục, thương hiệu, và phân trang.
  - Delivered `A-MD-02` (`/admin/moderation/products/{id}`): Giao diện **Split-Pane Evidence Review** và **Inspection-Slip Motif** hiển thị thư viện ảnh, thông tin người bán, huy hiệu 5 mức độ mới, phiếu mô tả khuyết điểm (`defect_info` >= 5 ký tự) và nhật ký thẩm định bất biến.
- **AC-P802-02 (Approve & Reject Rules DEC-05):**
  - Tái sử dụng `ProductModerationService::approveProduct()` cập nhật trạng thái `APPROVED`, gán `verification_level`, ghi log vào `product_moderation_logs` và `audit_logs`, gửi thông báo đến Seller.
  - Tái sử dụng `ProductModerationService::rejectOrHideProduct()` bắt buộc nhập `reason` (>= 5 ký tự theo `DEC-05` và `BR-PR-04`), chuyển sang `REJECTED`, lưu lý do để hiển thị trên màn hình di động `M-SL-04` giúp Seller sửa bài.
- **AC-P802-03 (Master Inventory A-PR-01):**
  - Delivered `A-PR-01` (`/admin/products`): Quản lý kho hàng toàn diện qua 7 trạng thái (`DRAFT`, `PENDING_REVIEW`, `APPROVED`, `REJECTED`, `SOLD`, `HIDDEN`, `ARCHIVED`).
  - Hỗ trợ cưỡng chế tạm ẩn (`HIDDEN`) bài đăng vi phạm và khôi phục hiển thị (`APPROVED`) kèm lý do và ghi `audit_logs`.
- **AC-P802-04 (Catalog Taxonomy CRUD DEC-08-02):**
  - Mở rộng `CatalogTaxonomyService`: CRUD Category và Brand có kiểm soát trong `DB::transaction()`.
  - Chống trùng `slug`, chặn vòng lặp phả hệ cha-con (Circular Hierarchy Guard: không cho phép danh mục làm cha của chính nó hoặc của danh mục con cháu).
  - Chặn xóa danh mục/thương hiệu đang có sản phẩm liên kết (`ValidationException`).
  - Đồng bộ thời gian thực với Mobile API `/api/v1/catalog/taxonomy` và ghi `audit_logs`.
- **AC-P802-05 (RBAC & Append-Only Protection):**
  - Moderator & Admin được phép truy cập `A-MD-01`, `A-MD-02`, `A-PR-01`, `A-CT-01` (xem).
  - Moderator bị chặn `403` khi cố gắng thực hiện các thao tác thêm/sửa/xóa danh mục hoặc thương hiệu (`categories.manage` là quyền của riêng Admin).
  - Support & Registered User bị chặn `403` trên toàn bộ các route kiểm duyệt và danh mục.
  - `ProductModerationLog` được bảo vệ bằng `ImmutableLedgerRecord`: ném `LogicException` khi gọi `update()` hoặc `delete()`.

### 2. UI & Frontend Asset Compilation
- **Vite Build:** `cd backend; npm run build` biên dịch 68.53 kB CSS trong 239ms với 0 lỗi.
- **Master Sidebar:** Bổ sung liên kết trực tiếp tới "Hàng đợi Kiểm duyệt", "Quản lý Sản phẩm", và "Phân loại & Danh mục".

### 3. Automated Test Verification Results
- **Backend P8-02 Feature Test Suite (`backend/tests/Feature/Admin/P802_TaxonomyProductsAndModerationTest.php`):** **9/9 PASS (100%)** (75 assertions, 0.98s).
- **Backend Admin Tests (`P801_` + `P802_`):** **35/35 PASS (100%)** (187 assertions).
- **PostgreSQL 18 DB Integrity Constraints:** `php artisan db:verify-constraints` -> **79 CHECK constraints active, 10/10 negative scenarios PASS**.
- **Full Backend Regression:** `php artisan test` -> **123/123 PASS (100%)** (1,232 assertions, 0 failures across all API and Admin suites).
- **Mobile Regression:**
  - `flutter analyze`: **0 issues found** (0 errors, 0 warnings).
  - `flutter test`: **134/134 PASS (100%)** across all 12 mobile test suites.

---

## TASK P8-04 EXECUTION LOG & VERIFICATION REPORT
- **Task ID:** `P8-04: Immutable Escrow Ledger, Dispute Workbench DEC-07 & Violation Reports`
- **Execution Mode:** END-TO-END IMPLEMENTATION & VERIFICATION
- **Executed At:** `2026-11-16`
- **Current Status:** `REVIEW` (Awaiting PO Inspection and Sign-Off)
- **Baseline Git Commit:** `4a1171ff9087fd66365342a215e615ed001ea141` (`main`)

### 1. Scope & Acceptance Criteria Delivery
- **AC-P804-01 (`A-ES-01` Escrow Overview & Immutable Ledger Explorer):**
  - Delivered `A-ES-01` (`/admin/escrow`): Giao diện tra cứu sổ cái bất biến (Immutable Ledger Explorer) dành riêng cho Supreme Admin (`escrow.view`).
  - **Bảng Đối soát Cân bằng Tài chính Sổ cái (Zero Ledger Drift Audit Panel):**
    - Kiểm tra thời gian thực giữa tổng tiền hàng đang giữ trong các đơn hàng `escrow_status = HELD` (`Order::where('escrow_status', 'HELD')->sum('item_subtotal')`) và tổng số dư Escrow tạm giữ trên hồ sơ Người bán (`SellerProfile::sum('escrow_held_balance')`).
    - Hiển thị huy hiệu xanh `✓ ZERO LEDGER DRIFT [PASS]` khi độ lệch đối soát = 0 đ (xác nhận 0.00 đ).
  - **Tab 1: Sổ cái Ký quỹ (Escrow Transactions):** Hiển thị chi tiết giao dịch ký quỹ bất biến (`transaction_code`, liên kết đơn hàng `#ORD-...`, người mua, người bán, loại giao dịch `HOLD` / `RELEASE` / `FULL_REFUND` / `PARTIAL_REFUND`, tổng tiền ký quỹ, tiền hàng giải ngân người bán, tiền hoàn người mua, phí bảo vệ sàn giữ lại, thời gian và ghi chú).
  - **Tab 2: Biến động Ví Người bán (Wallet Transactions):** Hiển thị chi tiết các bút toán tăng/giảm ví (`wallet_tx_code`, tên shop, mã đơn hàng, loại bút toán `CREDIT` / `DEBIT`, số tiền, số dư trước, số dư sau, diễn giải và thời gian).
  - Tìm kiếm đa trường theo mã giao dịch ví, mã giao dịch ký quỹ, mã đơn hàng, tên/email người mua và người bán.
  - Phân quyền: Moderator và Support bị chặn `403 Forbidden` khi cố truy cập `/admin/escrow`.
- **AC-P804-02 (`A-DP-01` Dispute Management Queue):**
  - Delivered `A-DP-01` (`/admin/disputes`): Hàng đợi xử lý tranh chấp khiếu nại dành cho Support Staff và Supreme Admin (`disputes.view`).
  - 5 thẻ thống kê động: Tổng số khiếu nại, Đang mở (`OPEN`), Chờ bổ sung bằng chứng (`NEED_MORE_INFO`), Đã phân xử xong (`RESOLVED`), và Tổng tiền Escrow đang bị đóng băng (`frozen_amount`).
  - Bộ lọc độc lập theo trạng thái khiếu nại (`status`), nhóm lý do vi phạm (`reason_category`), và tìm kiếm theo mã khiếu nại, mã đơn hàng, người mua, người bán.
  - Phân quyền: Moderator bị chặn `403 Forbidden`.
- **AC-P804-03 (`A-DP-02` Dispute Detail & 2-Way Evidence Workbench):**
  - Delivered `A-DP-02` (`/admin/disputes/{id}`): Bàn làm việc phân xử tranh chấp đối chứng 2 chiều:
    - **Banner Cảnh báo Đóng băng Ký quỹ (`BR-DP-02`):** Hiển thị số tiền ký quỹ đang bị đóng băng và tiến trình tự động giải ngân bị khóa.
    - **Bảng điều khiển 4 Máy Trạng thái:** `order_status`, `payment_status`, `escrow_status`, `dispute_status`.
    - **Snapshot Đơn hàng & Sản phẩm:** Giữ nguyên dữ liệu đóng băng tại thời điểm đặt hàng.
    - **Dòng thời gian Bằng chứng Đối chứng 2 chiều:** Hiển thị bằng chứng của người mua (`BUYER_PROOF`), phản hồi đối chứng của người bán (`SELLER_COUNTER_PROOF`), và yêu cầu của nhân viên sàn (`STAFF_REQUEST_NOTE`) kèm liên kết tập tin đính kèm.
    - **Yêu cầu Bổ sung Bằng chứng:** Support Staff và Admin có thể gửi ghi chú yêu cầu bổ sung chứng cứ (`POST /admin/disputes/{id}/request-info`), chuyển trạng thái khiếu nại sang `NEED_MORE_INFO` và tạo bản ghi bằng chứng loại `STAFF_REQUEST_NOTE`.
- **AC-P804-04 (Tách biệt Thẩm quyền DEC-08-03 / P6-02 & Phán quyết Tài chính DEC-07 / BR-FN-06):**
  - **Tách biệt Thẩm quyền (Separation of Duties):** Support Staff và Moderator tuyệt đối KHÔNG có thẩm quyền ra phán quyết tài chính. Thao tác `POST /admin/disputes/{id}/verdict` từ vai trò Support hoặc Moderator bị chặn cứng bằng **HTTP 403 Forbidden**. Giao diện `A-DP-02` hiển thị thông báo nghiệp vụ rõ ràng khi người dùng không phải Supreme Admin.
  - **Thực thi Phán quyết Tài chính (Supreme Admin):**
    1. `APPROVE_BUYER_REFUND` (`DEC-07` / `BR-FN-06`): Hủy đơn hàng, hoàn trả 100% tiền thanh toán, tạo bản ghi `FULL_REFUND` trong `escrow_transactions`, giảm `escrow_held_balance` của người bán, tăng `dispute_lost_count` của người bán, ghi nhật ký `AuditLog` bất biến.
    2. `RELEASE_TO_SELLER` (`DEC-04` / `BR-FN-07`): Hoàn tất đơn hàng, giải ngân ký quỹ, cộng tiền ví người bán qua `WalletTransaction` (`CREDIT`), tạo bản ghi `RELEASE` trong `escrow_transactions`, ghi nhật ký `AuditLog` bất biến.
    3. `PARTIAL_REFUND`: Phân chia hoàn tiền người mua và giải ngân người bán theo thỏa thuận.
- **AC-P804-05 (`A-CM-01` Violation / Moderation Reports Management):**
  - Delivered `A-CM-01` (`/admin/moderation/reports`): Quản lý báo cáo sai phạm từ cộng đồng dành cho Admin, Moderator và Support Staff (`reports.view`, `reports.resolve`).
  - 4 thẻ thống kê: Tổng số báo cáo, Đang chờ xử lý (`PENDING`), Đã xử phạt (`RESOLVED_ACTION_TAKEN`), Đã bác bỏ (`DISMISSED`).
  - Bộ lọc theo trạng thái, đối tượng vi phạm (`PRODUCT`, `USER`, `CONVERSATION`), lý do vi phạm (`reason_category`), và tìm kiếm.
  - Bảng báo cáo hiển thị người báo cáo, đối tượng vi phạm (kèm liên kết đến màn hình chi tiết kiểm duyệt sản phẩm `admin.moderation.products.show`), lý do, nội dung, người xử lý, ghi chú phân xử.
  - **Modal Xử lý Báo cáo:** Nhân viên lựa chọn quyết định (`RESOLVED_ACTION_TAKEN` hoặc `DISMISSED`) và bắt buộc nhập ghi chú xử lý (tối thiểu 5 ký tự, tối đa 1000 ký tự).
  - Tích hợp `ViolationReportService::resolveReport()`: Cập nhật trạng thái báo cáo, ghi nhận người xử lý (`handled_by`), thời điểm (`handled_at`), và ghi nhật ký `AuditLog` bất biến với action `REPORT_RESOLVED`. Chặn tuyệt đối việc xử lý lại báo cáo đã đóng.
- **AC-P804-06 (Bảo vệ Tính Bất biến Sổ cái Append-Only):**
  - Toàn bộ các model `EscrowTransaction`, `WalletTransaction`, và `AuditLog` được bảo vệ bằng trait `ImmutableLedgerRecord`.
  - Mọi thao tác gọi `update()` hoặc `delete()` đều ném ngoại lệ `LogicException` ('Immutable ledger/audit record cannot be updated or deleted').

### 2. UI & Frontend Asset Compilation
- **Vite Build:** `cd backend; npm run build` biên dịch 73.28 kB CSS trong 193ms với 0 lỗi.
- **Master Sidebar:** Bổ sung liên kết "Báo cáo Vi phạm" (`admin.moderation.reports.index`), "Sổ cái Ký quỹ (Escrow)" (`admin.escrow.index`), và cập nhật "Tranh chấp & Khiếu nại" (`admin.disputes.index`). Footer hiển thị `Retro Market Admin v1.0 • P8-04`.

### 3. Automated Test Verification Results
- **Backend P8-04 Feature Test Suite (`backend/tests/Feature/Admin/P804_EscrowDisputesAndReportsTest.php`):** **15/15 PASS (100%)** (77 assertions, 1.33s).
- **Backend Admin Tests (`P801_` + `P802_` + `P803_` + `P804_`):** **65/65 PASS (100%)** (425 assertions, 0 errors, 0 failures, 6.56s).
- **PostgreSQL 18 DB Integrity Constraints:** `php artisan db:verify-constraints` -> **79 CHECK constraints active, 10/10 negative scenarios PASS (100%)**.
- **Full Backend Regression:** `php artisan test` -> **147/147 PASS (100%)** (1,394 assertions, 0 failures across all API, Foundation, and Admin suites).
- **Mobile Regression:**
  - `flutter analyze`: **0 issues found** (0 errors, 0 warnings).
  - `flutter test`: **134/134 PASS (100%)** across all 12 mobile test suites.

---

## TASK P8-03 EXECUTION LOG & VERIFICATION REPORT
- **Task ID:** `P8-03: Auctions Monitor, 4-State Orders Inspector & Payments Management`
- **Execution Mode:** END-TO-END IMPLEMENTATION & VERIFICATION
- **Executed At:** `2026-11-16`
- **Current Status:** `REVIEW` (Awaiting PO Inspection and Sign-Off)
- **Baseline Git Commit:** `4a1171ff9087fd66365342a215e615ed001ea141` (`main`)

### 1. Scope & Acceptance Criteria Delivery
- **AC-P803-01 (`A-AC-01`, `A-AC-02`, `A-AC-03` Auctions Monitor & Ticket-Stub Motif):**
  - Delivered `A-AC-01` & `A-AC-03` (`/admin/auctions`): Quản lý các phiên đấu giá trực tiếp, sắp diễn ra, lịch sử đã đóng, và lọc người thắng bỏ cọc (`WINNER_DEFAULTED`). Thống kê số lượng phiên theo trạng thái, tìm kiếm đa trường và phân trang.
  - Delivered `A-AC-02` (`/admin/auctions/{id}`): Giao diện **Ticket-Stub Motif** (`IZITHRIFT OFFICIAL AUCTION VOUCHER`, viền perforated edge nét đứt, lot voucher header). Hiển thị chi tiết giá khởi điểm, bước giá tối thiểu, giá sàn reserve (và cờ báo đã đạt sàn hay chưa), giá cao nhất hiện tại, thông tin leading bidder.
  - **Cơ chế Chống Bắn Tỉa Anti-Sniping (`BR-AU-04`):** Hiển thị `extended_count` (+2 phút mỗi lần bid trong 2 phút cuối) và thời điểm gia hạn gần nhất.
  - **Hạn Thanh toán Người thắng 30 phút (`BR-AU-07` / `DEC-02`):** Hiển thị cảnh báo và trạng thái đơn hàng khi người thắng bỏ cọc.
  - **Nhật ký Đặt giá Bất biến (Immutable Bid Trail):** Hiển thị toàn bộ lịch sử bid (`auction_bids`), thời gian, người đặt giá, mức giá, cờ kích hoạt anti-sniping.
  - **Can thiệp Hành chính (Cancel Auction):** Moderator/Admin có quyền hủy phiên (`POST /admin/auctions/{id}/cancel` gọi `AuctionLifecycleService::cancelAuctionByAdmin()`), bắt buộc nhập lý do (>= 5 ký tự), hoàn trả sản phẩm về `APPROVED`, ghi nhật ký kiểm toán bất biến `AUCTION_CANCELLED` và gửi thông báo cho người bán.
- **AC-P803-02 (`A-OR-01`, `A-OR-02` Orders Management & 360° Inspector):**
  - Delivered `A-OR-01` (`/admin/orders`): Hiển thị và lọc độc lập theo **4 Máy Trạng thái Độc lập** (`order_status`, `payment_status`, `escrow_status`, `dispute_status`). Tìm kiếm theo mã đơn, người mua, người bán.
  - Delivered `A-OR-02` (`/admin/orders/{id}`): Bảng điều khiển soi 360° đơn hàng:
    - Hồ sơ 360° Khách mua và Người bán (kèm số dư Escrow đang giữ của shop).
    - Snapshot địa chỉ giao hàng của người mua.
    - Bảng sản phẩm đóng băng bất biến (`order_items` snapshots: tiêu đề, mã sp, tình trạng, thông tin lỗi, đơn giá, số lượng, thành tiền).
    - Tiến trình vận chuyển (`Shipment`: đơn vị vận chuyển, mã vận đơn, ghi chú, mốc thời gian giao hàng).
    - Trạng thái hủy đơn 3 cấp độ (`DEC-06` / `DEC-07`).
- **AC-P803-03 (Minh bạch Tài chính & Biểu phí DEC-04):**
  - Màn hình `A-OR-02` hiển thị chính xác công thức toán tài chính server-calculated theo `DEC-04`:
    - `item_subtotal`: Tiền hàng
    - `shipping_fee`: 0 đ
    - `buyer_protection_fee`: `(item_subtotal * 6%) + 7.000 đ`
    - `total_amount`: Tổng tiền người mua trả (`item_subtotal + buyer_protection_fee`)
    - `seller_net_amount`: 100% tiền hàng (0% chiết khấu người bán)
    - Định dạng số monospace `tabular-nums font-mono`.
- **AC-P803-04 (`A-PM-01` Payment Management):**
  - Delivered `A-PM-01` (`/admin/payments`): Giám sát các phiên thanh toán Mock QR (`payments`), mã tham chiếu `payment_reference`, liên kết đơn hàng `#ORD-...`, người nộp, số tiền, nội dung chuyển khoản chuẩn hóa `qr_payload`, trạng thái (`PENDING`, `PAID`, `EXPIRED`, `FAILED`), hạn QR và thời điểm khớp lệnh.
- **AC-P803-05 (RBAC Matrix & Immutable Ledger Protection):**
  - Admin: Toàn quyền truy cập cả 6 màn hình.
  - Moderator: Truy cập Đấu giá (`A-AC-01..03`), bị chặn `403` tuyệt đối tại Đơn hàng (`A-OR-01..02`) và Thanh toán (`A-PM-01`).
  - Support: Truy cập Đơn hàng (`A-OR-01..02`), bị chặn `403` tuyệt đối tại Đấu giá (`A-AC-01..03`) và Thanh toán (`A-PM-01`).
  - Registered User: Bị chặn `403` trên toàn bộ các route admin.
  - Bảo vệ Immutability: Mọi lệnh gọi `update()` hoặc `delete()` trên `AuctionBid` và `OrderItem` đều kích hoạt trait `ImmutableLedgerRecord` và ném `LogicException`.

### 2. UI & Frontend Asset Compilation
- **Vite Build:** `cd backend; npm run build` biên dịch 71.90 kB CSS trong 189ms với 0 lỗi.
- **Master Sidebar:** Cập nhật liên kết theo vai trò cho "Quản lý Đấu giá", "Đơn hàng & Escrow", và "Giao dịch Thanh toán" (Footer hiển thị `Retro Market Admin v1.0 • P8-03`).

### 3. Automated Test Verification Results
- **Backend P8-03 Feature Test Suite (`backend/tests/Feature/Admin/P803_AuctionsOrdersAndPaymentsTest.php`):** **9/9 PASS (100%)** (91 assertions, 2.16s).
- **Backend Admin Tests (`P801_` + `P802_` + `P803_`):** **50/50 PASS (100%)** (348 assertions, 0 errors, 0 failures).
- **PostgreSQL 18 DB Integrity Constraints:** `php artisan db:verify-constraints` -> **79 CHECK constraints active, 10/10 negative scenarios PASS (100%)**.
- **Full Backend Regression:** `php artisan test` -> **132/132 PASS (100%)** (1,319 assertions, 0 failures across all API, Foundation, and Admin suites).
- **Mobile Regression:**
  - `flutter analyze`: **0 issues found** (0 errors, 0 warnings).
  - `flutter test`: **134/134 PASS (100%)** across all 12 mobile test suites.

---

## TASK P8-04 EXECUTION LOG & VERIFICATION REPORT
- **Task ID:** `P8-04: Immutable Escrow Ledger, Dispute Workbench DEC-07 & Violation Reports`
- **Execution Mode:** END-TO-END IMPLEMENTATION & VERIFICATION
- **Executed At:** `2026-11-16`
- **Current Status:** `REVIEW` (Awaiting PO Inspection and Sign-Off)
- **Baseline Git Commit:** `4a1171ff9087fd66365342a215e615ed001ea141` (`main`)

### 1. Scope & Acceptance Criteria Delivery
- **AC-P804-01 (`A-ES-01` Escrow Overview & Immutable Ledger Explorer):**
  - Delivered `A-ES-01` (`/admin/escrow`): Giao diện tra cứu sổ cái bất biến (Immutable Ledger Explorer) dành riêng cho Supreme Admin (`escrow.view`).
  - **Bảng Đối soát Cân bằng Tài chính Sổ cái (Zero Ledger Drift Audit Panel):**
    - Kiểm tra thời gian thực giữa tổng tiền hàng đang giữ trong các đơn hàng `escrow_status = HELD` (`Order::where('escrow_status', 'HELD')->sum('item_subtotal')`) và tổng số dư Escrow tạm giữ trên hồ sơ Người bán (`SellerProfile::sum('escrow_held_balance')`).
    - Hiển thị huy hiệu xanh `✓ ZERO LEDGER DRIFT [PASS]` khi độ lệch đối soát = 0 đ (xác nhận 0.00 đ).
  - **Tab 1: Sổ cái Ký quỹ (Escrow Transactions):** Hiển thị chi tiết giao dịch ký quỹ bất biến (`transaction_code`, liên kết đơn hàng `#ORD-...`, người mua, người bán, loại giao dịch `HOLD` / `RELEASE` / `FULL_REFUND` / `PARTIAL_REFUND`, tổng tiền ký quỹ, tiền hàng giải ngân người bán, tiền hoàn người mua, phí bảo vệ sàn giữ lại, thời gian và ghi chú).
  - **Tab 2: Biến động Ví Người bán (Wallet Transactions):** Hiển thị chi tiết các bút toán tăng/giảm ví (`wallet_tx_code`, tên shop, mã đơn hàng, loại bút toán `CREDIT` / `DEBIT`, số tiền, số dư trước, số dư sau, diễn giải và thời gian).
  - Tìm kiếm đa trường theo mã giao dịch ví, mã giao dịch ký quỹ, mã đơn hàng, tên/email người mua và người bán.
  - Phân quyền: Moderator và Support bị chặn `403 Forbidden` khi cố truy cập `/admin/escrow`.
- **AC-P804-02 (`A-DP-01` Dispute Management Queue):**
  - Delivered `A-DP-01` (`/admin/disputes`): Hàng đợi xử lý tranh chấp khiếu nại dành cho Support Staff và Supreme Admin (`disputes.view`).
  - 5 thẻ thống kê động: Tổng số khiếu nại, Đang mở (`OPEN`), Chờ bổ sung bằng chứng (`NEED_MORE_INFO`), Đã phân xử xong (`RESOLVED`), và Tổng tiền Escrow đang bị đóng băng (`frozen_amount`).
  - Bộ lọc độc lập theo trạng thái khiếu nại (`status`), nhóm lý do vi phạm (`reason_category`), và tìm kiếm theo mã khiếu nại, mã đơn hàng, người mua, người bán.
  - Phân quyền: Moderator bị chặn `403 Forbidden`.
- **AC-P804-03 (`A-DP-02` Dispute Detail & 2-Way Evidence Workbench):**
  - Delivered `A-DP-02` (`/admin/disputes/{id}`): Bàn làm việc phân xử tranh chấp đối chứng 2 chiều:
    - **Banner Cảnh báo Đóng băng Ký quỹ (`BR-DP-02`):** Hiển thị số tiền ký quỹ đang bị đóng băng và tiến trình tự động giải ngân bị khóa.
    - **Bảng điều khiển 4 Máy Trạng thái:** `order_status`, `payment_status`, `escrow_status`, `dispute_status`.
    - **Snapshot Đơn hàng & Sản phẩm:** Giữ nguyên dữ liệu đóng băng tại thời điểm đặt hàng.
    - **Dòng thời gian Bằng chứng Đối chứng 2 chiều:** Hiển thị bằng chứng của người mua (`BUYER_PROOF`), phản hồi đối chứng của người bán (`SELLER_COUNTER_PROOF`), và yêu cầu của nhân viên sàn (`STAFF_REQUEST_NOTE`) kèm liên kết tập tin đính kèm.
    - **Yêu cầu Bổ sung Bằng chứng:** Support Staff và Admin có thể gửi ghi chú yêu cầu bổ sung chứng cứ (`POST /admin/disputes/{id}/request-info`), chuyển trạng thái khiếu nại sang `NEED_MORE_INFO` và tạo bản ghi bằng chứng loại `STAFF_REQUEST_NOTE`.
- **AC-P804-04 (Tách biệt Thẩm quyền DEC-08-03 / P6-02 & Phán quyết Tài chính DEC-07 / BR-FN-06):**
  - **Tách biệt Thẩm quyền (Separation of Duties):** Support Staff và Moderator tuyệt đối KHÔNG có thẩm quyền ra phán quyết tài chính. Thao tác `POST /admin/disputes/{id}/verdict` từ vai trò Support hoặc Moderator bị chặn cứng bằng **HTTP 403 Forbidden**. Giao diện `A-DP-02` hiển thị thông báo nghiệp vụ rõ ràng khi người dùng không phải Supreme Admin.
  - **Thực thi Phán quyết Tài chính (Supreme Admin):**
    1. `APPROVE_BUYER_REFUND` (`DEC-07` / `BR-FN-06`): Hủy đơn hàng, hoàn trả 100% tiền thanh toán, tạo bản ghi `FULL_REFUND` trong `escrow_transactions`, giảm `escrow_held_balance` của người bán, tăng `dispute_lost_count` của người bán, ghi nhật ký `AuditLog` bất biến.
    2. `RELEASE_TO_SELLER` (`DEC-04` / `BR-FN-07`): Hoàn tất đơn hàng, giải ngân ký quỹ, cộng tiền ví người bán qua `WalletTransaction` (`CREDIT`), tạo bản ghi `RELEASE` trong `escrow_transactions`, ghi nhật ký `AuditLog` bất biến.
    3. `PARTIAL_REFUND`: Phân chia hoàn tiền người mua và giải ngân người bán theo thỏa thuận.
- **AC-P804-05 (`A-CM-01` Violation / Moderation Reports Management):**
  - Delivered `A-CM-01` (`/admin/moderation/reports`): Quản lý báo cáo sai phạm từ cộng đồng dành cho Admin, Moderator và Support Staff (`reports.view`, `reports.resolve`).
  - 4 thẻ thống kê: Tổng số báo cáo, Đang chờ xử lý (`PENDING`), Đã xử phạt (`RESOLVED_ACTION_TAKEN`), Đã bác bỏ (`DISMISSED`).
  - Bộ lọc theo trạng thái, đối tượng vi phạm (`PRODUCT`, `USER`, `CONVERSATION`), lý do vi phạm (`reason_category`), và tìm kiếm.
  - Bảng báo cáo hiển thị người báo cáo, đối tượng vi phạm (kèm liên kết đến màn hình chi tiết kiểm duyệt sản phẩm `admin.moderation.products.show`), lý do, nội dung, người xử lý, ghi chú phân xử.
  - **Modal Xử lý Báo cáo:** Nhân viên lựa chọn quyết định (`RESOLVED_ACTION_TAKEN` hoặc `DISMISSED`) và bắt buộc nhập ghi chú xử lý (tối thiểu 5 ký tự, tối đa 1000 ký tự).
  - Tích hợp `ViolationReportService::resolveReport()`: Cập nhật trạng thái báo cáo, ghi nhận người xử lý (`handled_by`), thời điểm (`handled_at`), và ghi nhật ký `AuditLog` bất biến với action `REPORT_RESOLVED`. Chặn tuyệt đối việc xử lý lại báo cáo đã đóng.
- **AC-P804-06 (Bảo vệ Tính Bất biến Sổ cái Append-Only):**
  - Toàn bộ các model `EscrowTransaction`, `WalletTransaction`, và `AuditLog` được bảo vệ bằng trait `ImmutableLedgerRecord`.
  - Mọi thao tác gọi `update()` hoặc `delete()` đều ném ngoại lệ `LogicException` ('Immutable ledger/audit record cannot be updated or deleted').

### 2. UI & Frontend Asset Compilation
- **Vite Build:** `cd backend; npm run build` biên dịch 73.28 kB CSS trong 193ms với 0 lỗi.
- **Master Sidebar:** Bổ sung liên kết "Báo cáo Vi phạm" (`admin.moderation.reports.index`), "Sổ cái Ký quỹ (Escrow)" (`admin.escrow.index`), và cập nhật "Tranh chấp & Khiếu nại" (`admin.disputes.index`). Footer hiển thị `Retro Market Admin v1.0 • P8-04`.

### 3. Automated Test Verification Results
- **Backend P8-04 Feature Test Suite (`backend/tests/Feature/Admin/P804_EscrowDisputesAndReportsTest.php`):** **15/15 PASS (100%)** (77 assertions, 1.33s).
- **Backend Admin Tests (`P801_` + `P802_` + `P803_` + `P804_`):** **65/65 PASS (100%)** (425 assertions, 0 errors, 0 failures, 6.56s).
- **PostgreSQL 18 DB Integrity Constraints:** `php artisan db:verify-constraints` -> **79 CHECK constraints active, 10/10 negative scenarios PASS (100%)**.
- **Full Backend Regression:** `php artisan test` -> **147/147 PASS (100%)** (1,394 assertions, 0 failures across all API, Foundation, and Admin suites).
- **Mobile Regression:**
  - `flutter analyze`: **0 issues found** (0 errors, 0 warnings).
  - `flutter test`: **134/134 PASS (100%)** across all 12 mobile test suites.


---

## TASK P8-05 EXECUTION LOG & VERIFICATION REPORT
- **Task ID:** `P8-05: Users & Role Governance, Platform Settings, Audit Logs & Developer Tools`
- **Execution Mode:** END-TO-END IMPLEMENTATION & VERIFICATION
- **Executed At:** `2026-11-16`
- **Current Status:** `REVIEW` (Awaiting PO Inspection and Sign-Off)
- **Baseline Git Commit:** `4a1171ff9087fd66365342a215e615ed001ea141` (`main`)

### 1. Scope & Acceptance Criteria Delivery
- **AC-P805-01 (`A-US-01` User Management Directory):**
  - Delivered `A-US-01` (`/admin/users`): Danh mục quản lý người dùng đa chiều dành cho Admin và Support Staff (`users.view`). Moderator bị chặn bằng `HTTP 403 Forbidden`.
  - 4 thẻ thống kê: Tổng số người dùng, Đang hoạt động (`ACTIVE`), Bị tạm khóa (`SUSPENDED`), và Tài khoản nội bộ sàn (`STAFF`).
  - Bộ lọc kết hợp theo vai trò (`role`: `registered_user`, `moderator`, `support_staff`, `admin`), trạng thái (`status`: `ACTIVE`, `SUSPENDED`), và tìm kiếm từ khóa theo tên hiển thị, email hoặc số điện thoại.
  - Phân trang 15 bản ghi/trang kèm huy hiệu màu chuẩn Vintage cho từng vai trò và trạng thái.
- **AC-P805-02 (`A-US-02` User Detail, 360° Inspector & Role/Status Governance):**
  - Delivered `A-US-02` (`/admin/users/{id}`): Bàn làm việc kiểm tra người dùng 360 độ và quản trị tài khoản:
    - **Thông tin Tài khoản:** Monogram avatar, tên hiển thị, email, SĐT, ngày đăng ký, vai trò hiện tại, trạng thái, lý do thay đổi trạng thái gần nhất.
    - **Hồ sơ Người bán (Seller Metrics):** Tên cửa hàng, bio, điểm uy tín (Trust Score), số đơn hàng đã bán, tổng doanh thu, số dư ký quỹ đang giữ (`escrow_held_balance`).
    - **Lịch sử Người mua (Buyer Metrics):** Tổng đơn đã mua, đơn hoàn tất, đơn đã hủy, khiếu nại phát sinh.
    - **Chỉ số Rủi ro & Gian lận (Fraud & Default Indicators):** Đấu giá đã thắng, số lần bùng kèo đấu giá (`WINNER_DEFAULTED`), số lần thua khiếu nại (`dispute_lost_count`), chỉ số rủi ro tính toán (`fraud_risk_score`) kèm nhãn cảnh báo.
    - **Quản trị Trạng thái (`POST /admin/users/{id}/status`):** Khóa/Mở khóa tài khoản có bắt buộc nhập lý do (>= 5 ký tự), thu hồi toàn bộ token đăng nhập Sanctum khi khóa, ghi `audit_logs` bất biến.
    - **Quản trị Vai trò (`POST /admin/users/{id}/role`):** Nâng cấp/hạ cấp vai trò (`registered_user`, `support_staff`, `moderator`, `admin`) có bắt buộc nhập lý do (>= 5 ký tự), thu hồi toàn bộ token Sanctum, ghi `audit_logs` bất biến.
    - **Quy tắc Bất biến Tự bảo vệ:** Admin không thể tự khóa tài khoản của chính mình; Admin không thể tự đổi/hạ vai trò của chính mình; Không thể khóa hoặc hạ vai trò của Quản trị viên duy nhất còn lại trên hệ thống (`422 Unprocessable Entity`).
    - **Tách biệt Thẩm quyền:** Nhân viên Hỗ trợ (Support Staff) chỉ có quyền xem thông tin hồ sơ; mọi hành động thay đổi trạng thái hoặc vai trò đều bị ẩn trên giao diện và chặn `403 Forbidden` ở backend.
- **AC-P805-03 (`A-ST-01` Platform Settings & Bounds Validation):**
  - Delivered `A-ST-01` (`/admin/settings`): Giao diện cấu hình tham số nền tảng dành riêng cho Supreme Admin (`settings.manage`). Support và Moderator bị chặn `403 Forbidden`.
  - Cấu hình 3 nhóm tham số vận hành:
    1. **Cơ cấu Phí Giao dịch (`DEC-04`):** Phí bảo vệ người mua (5% - 8%), Phí cố định (5,000 - 10,000 đ), Phí vận chuyển (0 đ), Hoa hồng người bán (0%).
    2. **Bộ đếm Thời gian Vận hành:** Thời gian chờ thanh toán (`payment_window_hours`), Thời gian tự động hoàn tất giao hàng (`auto_complete_days`), Cửa sổ kích hoạt chống bắn tỉa (`anti_sniping_trigger_seconds`), Thời gian gia hạn chống bắn tỉa (`anti_sniping_extend_seconds`), Thời lượng phiên đấu giá mặc định (`auction_default_duration_hours`).
    3. **Tùy biến Giao diện Theo mùa:** Bật/tắt trang trí giao diện (`seasonal_decor_enabled`), Chủ đề mùa lễ hội (`christmas`, `tet_holiday`, `none`).
  - Kiểm định ràng buộc an toàn: Chặn các giá trị tỷ lệ phí ngoài khoảng [0.05, 0.08] hoặc thời gian âm.
  - Xóa cache tự động: Kích hoạt `$configService->clearCache($key)` ngay lập tức trên Redis/Cache.
  - Ghi vết bất biến `audit_logs` với action `PLATFORM_SETTING_UPDATED` lưu trữ giá trị cũ (`old_value`) và giá trị mới (`new_value`).
- **AC-P805-04 (`A-AD-01` Activity Audit Logs Explorer - Strictly Read-Only):**
  - Delivered `A-AD-01` (`/admin/audit-logs`): Tra cứu nhật ký kiểm toán hệ thống dành riêng cho Supreme Admin (`audit_logs.view`). Moderator và Support bị chặn `403 Forbidden`.
  - Cam kết Tuyệt đối Read-Only: Không cung cấp bất kỳ API hoặc nút bấm chỉnh sửa/xóa nào; các bản ghi `AuditLog` được bảo vệ bằng trait `ImmutableLedgerRecord` chống gọi `update()` và `delete()`.
  - Bộ lọc đa tiêu chí: Lọc theo người thực hiện (`actor_id`), nhóm hành động (`action`), loại thực thể mục tiêu (`target_type`), khoảng thời gian từ ngày - đến ngày, và tìm kiếm theo địa chỉ IP / ID mục tiêu / lý do.
  - Modal JSON Diff: Xem chi tiết thay đổi `old_values` vs `new_values` định dạng JSON rõ ràng.
- **AC-P805-05 (`A-DT-01` Developer Tools & Dual-Gate Security):**
  - Delivered `A-DT-01` (`/admin/dev-tools`): Bộ công cụ nhà phát triển để kích hoạt thủ công các background jobs.
  - Cơ chế Bảo mật Dual-Gate (2 Lớp Khóa):
    - Cổng 1: Người dùng phải có vai trò `admin` (`auth()->user()->isAdmin()`).
    - Cổng 2: Biến môi trường phải bật chế độ demo `DEMO_MODE=true` (`config('retromarket.demo_mode') === true`).
    - Nếu thiếu một trong hai điều kiện, hệ thống từ chối bằng **HTTP 403 Forbidden**. Trên môi trường sản xuất (`DEMO_MODE=false`), liên kết Developer Tools hoàn toàn biến mất khỏi thanh điều hướng Sidebar.
  - Hỗ trợ kích hoạt trực tiếp 4 Scheduled Background Jobs cốt lõi qua `SystemDevToolsService::triggerJobAction()`:
    1. `OpenScheduledAuctionsJob`: Mở các phiên đấu giá đã đến giờ bắt đầu.
    2. `CloseExpiredAuctionsJob`: Đóng các phiên đấu giá đã hết hạn, xác định người thắng hoặc đánh dấu không có người mua.
    3. `ExpireUnpaidAuctionOrdersJob`: Hủy đơn đấu giá quá hạn thanh toán (`24h`), phạt đánh dấu người thắng bùng kèo (`WINNER_DEFAULTED`).
    4. `AutoCompleteDeliveredOrdersJob`: Tự động hoàn tất đơn hàng giao thành công quá thời hạn khiếu nại (`3 ngày`), giải ngân tiền ký quỹ cho người bán.
    5. `RUN_ALL_LIFECYCLE_JOBS`: Kích hoạt tuần tự cả 4 jobs trong một lượt.
  - Ghi nhận `audit_logs` với hành động `DEVTOOLS_MANUAL_JOB_TRIGGER` ghi rõ loại job và số lượng bản ghi đã xử lý.

### 2. UI & Frontend Asset Compilation
- **Vite Build:** `cd backend; npm run build` biên dịch 74.61 kB CSS trong 192ms với 0 lỗi.
- **Master Sidebar:** Bổ sung liên kết "Quản lý Người dùng" (`admin.users.index`), "Cấu hình Nền tảng" (`admin.settings.index`), "Nhật ký Kiểm toán" (`admin.audit_logs.index`), và "Developer Tools" (`admin.dev_tools.index` - điều kiện `isAdmin() && DEMO_MODE`). Footer cập nhật hiển thị `Retro Market Admin v1.0 • P8-05`.

### 3. Automated Test Verification Results
- **Backend P8-05 Feature Test Suite (`backend/tests/Feature/Admin/P805_UsersSettingsAuditAndDevToolsTest.php`):** **13/13 PASS (100%)** (75 assertions, 1.48s).
- **Backend Admin Tests (`P801_` + `P802_` + `P803_` + `P804_` + `P805_`):** **78/78 PASS (100%)** (500 assertions, 0 errors, 0 failures, 7.21s).
- **PostgreSQL 18 DB Integrity Constraints:** `php artisan db:verify-constraints` -> **79 CHECK constraints active, 10/10 negative scenarios PASS (100%)**.
- **Full Backend Regression:** `php artisan test` -> **160/160 PASS (100%)** (1,473 assertions, 0 failures across all API, Foundation, and Admin suites).
- **Mobile Regression:**
  - `flutter analyze`: **0 issues found** (0 errors, 0 warnings).
  - `flutter test`: **134/134 PASS (100%)** across all 12 mobile test suites.
- **Tổng số màn hình Admin hoàn tất:** **21/21 màn hình** (P8-01: 2, P8-02: 4, P8-03: 6, P8-04: 4, P8-05: 5).


### Phase 08 - Task P8-06 Completed (2026-11-16)
- **Task:** Web E2E Integration Suite, 21-Screen Verification & Phase 08 Sign-off (`P8-06`).
- **Artifacts:**
  - `backend/tests/Feature/Admin/P806_Phase08EndToEndIntegrationTest.php` (Complete E2E cross-platform integration suite).
  - `docs/08_ADMIN_DEVELOPMENT/P8_06_WEB_INTEGRATION_E2E_AND_SIGN_OFF.md` (P8-06 Implementation & Verification Report).
  - `docs/08_ADMIN_DEVELOPMENT/PHASE_08_FINAL_AUDIT_REPORT.md` (Full Phase 08 Final Audit Report).
  - `docs/08_ADMIN_DEVELOPMENT/PHASE_08_HANDOFF_TO_PHASE_09.md` (Phase 08 to Phase 09 Handoff Specification).
- **Core Verification & Invariants Validated:**
  - **AC-P806-01 (21/21 Canonical Screen Coverage):** All 21 Admin screens (`A-LG-01` to `A-DT-01`) verified with exact Screen IDs, routes, controllers, Blade views, and passing feature tests.
  - **AC-P806-02 (Cross-Platform E2E Integration):** All 4 cross-platform flows verified:
    - Flow 1: Moderation & Resubmit Lifecycle (`DEC-05`): Mobile Create -> Admin Reject -> Mobile Resubmit -> Admin Approve -> Public Search.
    - Flow 2: Order, Escrow & Dispute Verdict Lifecycle with Zero Ledger Drift (`DEC-03`, `DEC-04`, `DEC-07`, `AC-P806-03`): Order Paid & Held -> Mobile Dispute -> Admin Evidence Request -> Supreme Admin Verdict (`APPROVE_BUYER_REFUND`).
    - Flow 3: Auction Lifecycle & DevTools Trigger (`A-DT-01`, `BR-AU-04`, `BR-AU-07`): Dual-gate security + manual execution + audit logging.
    - Flow 4: User Suspension & Cross-Guard Isolation: Immediate Sanctum token revocation (`tokens()->delete()`) + session lockout (`403 Account Suspended`).
  - **AC-P806-03 (Zero Ledger Drift & Immutability):**
    - Mathematical reconciliation confirms **0.00đ ledger drift** across all active sellers and held orders.
    - Strict append-only immutability verified on all 6 ledger and audit models (`update()` and `delete()` throw `LogicException`).
  - **AC-P806-04 (61-Permission RBAC & Security Verification):** Complete role matrix (`admin`, `moderator`, `support`, `registered_user`), Redis 7.4 Session Runtime, CSRF, and login rate limiting (5 attempts/min) verified 100%.
  - **AC-P806-05 (100% Full-System Regression Baseline):**
    - Backend Full Test Suite (`php artisan test`): **166/166 PASS (100%)** (1,599 assertions, 0 failures across all API, Foundation, and Admin suites).
    - Backend Admin Tests (`php artisan test --filter=Admin`): **84/84 PASS (100%)** (628 assertions).
    - Redis 7.4 Session Runtime (`P801_RedisSessionRuntimeTest`): **3/3 PASS (100%)** (13 assertions).
    - PostgreSQL 18 Constraints (`php artisan db:verify-constraints`): **10/10 PASS (100%)**, 79 active check constraints.
    - Seeded Data Integrity & Ledger Drift (`php artisan db:verify-seeders`): **100% PASS**, zero drift.
    - Production Vite Build (`npm run build`): **74.61 kB CSS compiled in 197ms, 0 errors**.
    - Mobile Flutter Analyze (`flutter analyze`): **0 issues found** (0 errors, 0 warnings).
    - Mobile Flutter Tests (`flutter test`): **134/134 PASS (100%)** across all 12 mobile test suites.
- **Phase 08 Status:** **REVIEW (100% COMPLETE & VERIFIED: P8-01..P8-06 PASS)**. Ready for PO Final Sign-off.

---

### Phase 09 - Task P9-03 Technical Implementation Accepted by PO (2026-11-17)
- **Task:** Work Package P9-03 – Order Cancellation Matrix (`P9-03`).
- **PO Decision:** `PO ACCEPTED – TECHNICAL IMPLEMENTATION` (Decision dated 2026-11-17 15:05+07:00).
- **Work Package Closure:** `PENDING SEPARATE PO CLOSURE DECISION`.
- **Approved Implementation Scope (Exactly 8 Files):**
  1. `backend/app/Exceptions/EscrowLedgerIntegrityException.php` (CREATE)
  2. `backend/app/Http/Requests/Api/V1/Order/SellerCancelOrderRequest.php` (CREATE)
  3. `backend/app/Services/Escrow/MockQrPaymentService.php` (MODIFY)
  4. `backend/app/Services/Order/OrderCancellationService.php` (MODIFY)
  5. `backend/app/Services/Order/OrderExpirationService.php` (MODIFY)
  6. `backend/app/Http/Controllers/Api/V1/SellerOrderController.php` (MODIFY)
  7. `backend/routes/api.php` (MODIFY)
  8. `backend/tests/Feature/Api/V1/OrderCancellationMatrixTest.php` (CREATE)
- **Core Technical Verifications & Audited Invariants:**
  - **Reconciled Inventory:** 22 original scenarios, 21 approved executable business scenarios, 1 excluded business capability (Scenario #08), 23 executable PHPUnit test methods.
  - **Scenario #08 Functional Status:** Excluded business capability per `P9-03-DEC-01` (Option A). Direct seller cancellation at `PREPARING` with open buyer cancellation request is rejected with HTTP 409 `INVALID_STATE_TRANSITION` and zero state mutation.
  - **Test Suite Verification:**
    - `OrderCancellationMatrixTest.php`: **23/23 PASS (100%)** (160 assertions, duration: ~4.35s).
    - `CartOrderAndPaymentTest.php`: **8/8 PASS (100%)** (100 assertions).
    - `EscrowShippingAndDisputeTest.php`: **8/8 PASS (100%)** (78 assertions).
    - `AuctionEngineTest.php`: **8/8 PASS (100%)** (66 assertions).
  - **Concurrency & Lock Hierarchy:** Verified monotonic lock hierarchy ($\text{Order} \rightarrow \text{Payment} \rightarrow \text{Auction} \rightarrow \text{Product (ASC)} \rightarrow \text{SellerProfile}$) with direct `pg_blocking_pids()` evidence between independent OS worker processes in Tests #20B & #22. No concrete deadlock cycle identified in audited paths.
  - **External Scheduler Defect:** 1 failure in `backend/tests/Feature/Api/V1/BackgroundJobsAndSchedulerTest.php` (5/6 pass) due to an idempotency bug in `AuctionLifecycleService::finalizeAuctionWithWinner()` on seeded `Auction 1` (`AUC-2026-0001`). Confirmed outside P9-03 scope and logged for separate tracking.
- **Git State:** Baseline commit `4a1171ff9087fd66365342a215e615ed001ea141` preserved with dirty working tree intact (zero commits, resets, or cleans).
