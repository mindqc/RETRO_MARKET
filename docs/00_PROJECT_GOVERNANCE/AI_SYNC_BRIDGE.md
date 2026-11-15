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
