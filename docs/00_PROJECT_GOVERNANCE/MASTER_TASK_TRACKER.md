# IZITHRIFT (RETRO MARKET) – MASTER TASK TRACKER

**Status Legend:** `PENDING` | `IN_PROGRESS` | `BLOCKED` | `REVIEW` | `DONE` | `FAILED`

## Phase 00 – Project Governance
| Task ID | Task Name | Target File / Deliverable | Dependency | Status |
| :--- | :--- | :--- | :--- | :--- |
| `GOV-01` | Project Overview & Vision | `docs/00_PROJECT_GOVERNANCE/PROJECT_OVERVIEW.md` | — | `PENDING` |
| `GOV-02` | Master Development Plan | `docs/00_PROJECT_GOVERNANCE/MASTER_DEVELOPMENT_PLAN.md` | `GOV-01` | `PENDING` |
| `GOV-03` | Master Task Tracker Setup | `docs/00_PROJECT_GOVERNANCE/MASTER_TASK_TRACKER.md` | `GOV-02` | `IN_PROGRESS` |

## Phase 01 – Project Discovery & Requirement Analysis
| Task ID | Task Name | Target File / Deliverable | Dependency | Status |
| :--- | :--- | :--- | :--- | :--- |
| `PA-01` | Project Charter | `docs/01_REQUIREMENTS_ANALYSIS/01_PROJECT_CHARTER.md` | `GOV-03` | `DONE` |
| `PA-02` | Scope and Boundaries | `docs/01_REQUIREMENTS_ANALYSIS/02_SCOPE_AND_BOUNDARIES.md` | `PA-01` | `DONE` |
| `PA-03` | Actor & Permission Matrix | `docs/01_REQUIREMENTS_ANALYSIS/03_ACTOR_PERMISSION_MATRIX.md` | `PA-02` | `DONE` |
| `PA-04` | Functional Requirements | `docs/01_REQUIREMENTS_ANALYSIS/04_FUNCTIONAL_REQUIREMENTS.md` | `PA-03` | `DONE` |
| `PA-05` | Use Case Specification | `docs/01_REQUIREMENTS_ANALYSIS/05_USE_CASE_SPECIFICATION.md` | `PA-04` | `DONE` |
| `PA-06` | Business Rules Specification | `docs/01_REQUIREMENTS_ANALYSIS/06_BUSINESS_RULES.md` | `PA-05` | `DONE` |
| `PA-07` | Non-Functional Requirements | `docs/01_REQUIREMENTS_ANALYSIS/07_NON_FUNCTIONAL_REQUIREMENTS.md` | `PA-06` | `DONE` |
| `PA-08` | Assumptions & Technical Decisions | `docs/01_REQUIREMENTS_ANALYSIS/08_ASSUMPTIONS_AND_DECISIONS.md` | `PA-07` | `DONE` |
| `PA-09` | Requirements Traceability Matrix | `docs/01_REQUIREMENTS_ANALYSIS/09_REQUIREMENTS_TRACEABILITY.md` | `PA-04`, `PA-05`, `PA-06` | `DONE` |
| `PA-10` | Phase 01 Sign-Off Checklist | `docs/01_REQUIREMENTS_ANALYSIS/10_PHASE_01_SIGN_OFF.md` | `PA-01`..`PA-09` | `DONE` |

## Phase 02 – System Flows & UX Planning
| Task ID | Task Name | Target File / Deliverable | Dependency | Status |
| :--- | :--- | :--- | :--- | :--- |
| `P2-01` | Sitemap & Information Architecture | `docs/02_SYSTEM_FLOWS/01_SITEMAP/SITEMAP.md` | `PA-10` | `DONE` |
| `P2-02` | Buyer End-to-End User Flows | `docs/02_SYSTEM_FLOWS/02_USER_FLOWS/BUYER_FLOW.md` | `P2-01` | `DONE` |
| `P2-03` | Seller End-to-End User Flows | `docs/02_SYSTEM_FLOWS/02_USER_FLOWS/SELLER_FLOW.md` | `P2-01` | `DONE` |
| `P2-04` | Auction System Flows & Sequence | `docs/02_SYSTEM_FLOWS/02_USER_FLOWS/AUCTION_FLOW.md` | `P2-01` | `DONE` |
| `P2-05` | Order, Payment & Escrow State Flows | `docs/02_SYSTEM_FLOWS/02_USER_FLOWS/ORDER_PAYMENT_FLOW.md` | `P2-01` | `DONE` |
| `P2-06` | Admin Dashboard & Moderation Flows | `docs/02_SYSTEM_FLOWS/02_USER_FLOWS/ADMIN_FLOW.md` | `P2-01` | `DONE` |
| `P2-07` | Comprehensive Screen Inventory (70 screens) | `docs/02_SYSTEM_FLOWS/03_SCREEN_INVENTORY/SCREEN_INVENTORY.md` | `P2-02`..`P2-06` | `DONE` |
| `P2-08` | Wireframes & Phase 02 Review Sign-Off | `docs/02_SYSTEM_FLOWS/04_WIREFRAMES/`, `docs/02_SYSTEM_FLOWS/05_PHASE_02_REVIEW/` | `P2-07` | `DONE` |

## Phase 03 – UI/UX Design System & High-Fidelity Specs
| Task ID | Task Name | Target File / Deliverable | Dependency | Status |
| :--- | :--- | :--- | :--- | :--- |
| `P3-01` | Design Direction & Visual Identity | `docs/03_UI_UX_DESIGN/01_DESIGN_DIRECTION/ (4 files)` | `P2-08` | `DONE` |
| `P3-02` | Design System, Tokens & Component Library | `docs/03_UI_UX_DESIGN/02_DESIGN_SYSTEM/ (7 files)` | `P3-01` | `DONE` |
| `P3-03` | Mobile UI Specs: Auth, Home, Discovery & Engagement | `docs/03_UI_UX_DESIGN/03_MOBILE_APP/ (Part 1)` | `P3-02` | `DONE` |
| `P3-04` | Mobile UI Specs: Product Details, Seller Profile & Personal Hub | `docs/03_UI_UX_DESIGN/03_MOBILE_APP/ (Part 2)` | `P3-02` | `DONE` |
| `P3-05` | Mobile UI Specs: Seller Center, Auction & Order Payment | `docs/03_UI_UX_DESIGN/03_MOBILE_APP/ (Part 3)` | `P3-02` | `DONE` |
| `P3-06` | Admin Dashboard Blade Layout & Full UI Specs | `docs/03_UI_UX_DESIGN/04_ADMIN_DASHBOARD/ (4 files)` | `P3-02` | `DONE` |
| `P3-07` | Interactive Prototype Scope & Review Verification | `docs/03_UI_UX_DESIGN/05_INTERACTIVE_PROTOTYPE/ (2 files)` | `P3-03`..`P3-06` | `DONE` |
| `P3-08` | Phase 03 Sign-Off & Quality Gate Review | `docs/03_UI_UX_DESIGN/06_PHASE_03_REVIEW/PHASE_03_SIGN_OFF.md` | `P3-01`..`P3-07` | `DONE` |

## Phase 04 – System Architecture, Database Design & API Specification
| Task ID | Task Name | Target File / Deliverable | Dependency | Status |
| :--- | :--- | :--- | :--- | :--- |
| `P4-01` | System Architecture & C4 Models | `docs/04_SYSTEM_ARCHITECTURE_AND_DB/01_ARCHITECTURE_DIAGRAMS/ (2 files)` | `P3-08` | `DONE` |
| `P4-02` | PostgreSQL 18 Core & Auction Database Schema | `docs/04_SYSTEM_ARCHITECTURE_AND_DB/02_DATABASE_DESIGN/DB_01_CORE_SCHEMA.md`, `DB_02_AUCTION_SCHEMA.md` | `P4-01` | `DONE` |
| `P4-03` | Order/Escrow Schema & ERD Relationships | `docs/04_SYSTEM_ARCHITECTURE_AND_DB/02_DATABASE_DESIGN/DB_03_ORDER_ESCROW_SCHEMA.md`, `ERD_RELATIONSHIPS.md` | `P4-02` | `DONE` |
| `P4-04` | REST API Guidelines, Endpoints & Scheduled Jobs | `docs/04_SYSTEM_ARCHITECTURE_AND_DB/03_API_SPECIFICATIONS/`, `04_BACKGROUND_JOBS_AND_SERVICES/` | `P4-03` | `DONE` |
| `P4-05` | Phase 04 Quality Gate Review & Sign-Off | `docs/04_SYSTEM_ARCHITECTURE_AND_DB/05_PHASE_04_REVIEW/PHASE_04_SIGN_OFF.md` | `P4-01`..`P4-04` | `DONE` |

## Phase 05 – Backend Foundation & Database Implementation
| Task ID | Task Name | Target File / Deliverable | Dependency | Status |
| :--- | :--- | :--- | :--- | :--- |
| `P5-01` | Environment Setup, Docker & Laravel Scaffolding | `docker-compose.yml`, `backend/`, `docs/05_BACKEND_FOUNDATION/P5_01_ENVIRONMENT_SETUP.md` | `P4-05` | `DONE` |
| `P5-02` | PostgreSQL 18 Migrations & DB Constraints | `backend/database/migrations/` (5 Tier Migrations, 34 tables) | `P5-01` | `DONE` |
| `P5-03` | Database Constraints, Partial Indexes & Integrity Verification | `backend/database/migrations/` (Tier 6), `db:verify-constraints`, `docs/05_BACKEND_FOUNDATION/P5_03_CONSTRAINTS_INTEGRITY.md` | `P5-02` | `DONE` |
| `P5-04` | Eloquent Models, Relationships & Casts | `backend/app/Models/` (32 models, `ImmutableLedgerRecord`), `model:verify-architecture` | `P5-03` | `DONE` |
| `P5-05` | Factories, Idempotent Seeders & Ledger Reconciliation | `backend/database/seeders/` (6 Seeders), `db:verify-seeders`, `docs/05_BACKEND_FOUNDATION/P5_05_SEEDERS_SPEC.md` | `P5-04` | `DONE` |
| `P5-06` | Database Validation, Rollback Verification & Automated PHPUnit Suite | `backend/tests/Feature/DatabaseFoundationVerificationTest.php` (12 Tests), `docs/05_BACKEND_FOUNDATION/P5_06_VALIDATION_REPORT.md` | `P5-05` | `DONE` |
| `P5-07` | Final Backend Foundation Review & Phase 05 Sign-Off | `docs/05_BACKEND_FOUNDATION/PHASE_05_SIGN_OFF.md` | `P5-01`..`P5-06` | `DONE` |

## Phase 06 – Backend Domain Services & REST API Development
| Task ID | Task Name | Target File / Deliverable | Dependency | Status |
| :--- | :--- | :--- | :--- | :--- |
| `P6-01` | Backend Architecture, ApiResponse & API Foundation | `backend/app/Support/ApiResponse.php`, `BootstrapController`, `GlobalExceptionHandler`, 20 Tests PASS | `P5-07` | `DONE` |
| `P6-02` | Authentication, Sanctum Tokens & RBAC Policies | `backend/app/Services/Auth/AuthService.php`, `AuthController`, Policies, 8 Tests PASS | `P6-01` | `DONE` |
| `P6-03` | User Profile, Address Book, Taxonomy & Home Discovery | `backend/app/Services/User/`, `CatalogService`, `SellerStorefrontService`, 8 Tests PASS | `P6-02` | `DONE` |
| `P6-04` | Product Discovery, 7-State Listings & Moderation | `backend/app/Services/Product/`, `ProductModerationService`, 8 Tests PASS | `P6-03` | `DONE` |
| `P6-05` | Cart, Checkout (DEC-04), Mock QR Escrow & 3-Tier Cancel | `backend/app/Services/Order/CartService.php`, `CheckoutService`, `PaymentSimulationService`, 8 Tests PASS | `P6-04` | `DONE` |
| `P6-06` | Order Fulfillment, 100% Escrow Release & Disputes | `backend/app/Services/Order/OrderFulfillmentService.php`, `EscrowReleaseService`, `DisputeService`, 8 Tests PASS | `P6-05` | `DONE` |
| `P6-07` | Scheduled Auctions, Pessimistic Bids & Anti-Sniping | `backend/app/Services/Auction/` (`Query`, `Bidding`, `Lifecycle`), 8 Tests PASS | `P6-06` | `DONE` |
| `P6-08` | 1-on-1 Polling Chat, Notifications, Reviews & Reports | `backend/app/Services/Communication/`, `SocialEngagementService`, `ReviewViolationReportService`, 8 Tests PASS | `P6-07` | `DONE` |
| `P6-09` | 4 Background Jobs, FOR UPDATE SKIP LOCKED & Scheduler | `backend/app/Jobs/` (4 Jobs), `routes/console.php`, `SystemDevToolsController`, 6 Tests PASS | `P6-08` | `DONE` |
| `P6-10` | E2E Integration Testing, Full Reconciliation & Sign-Off | `tests/Feature/Api/V1/Phase06EndToEndIntegrationTest.php` (4 Journeys, 88/88 Tests PASS, 0 Drift), `P6_10_INTEGRATION_AND_SIGN_OFF.md` | `P6-09` | `DONE / APPROVED` |

## Phase 07 – Flutter Mobile Application Development (52 Screens) [DONE / APPROVED – OFFICIAL PO SIGN-OFF]
| Task ID | Task Name | Target File / Deliverable | Dependency | Status |
| :--- | :--- | :--- | :--- | :--- |
| `P7-01` | Flutter Architecture, Project Init, EnvConfig, GoRouter 5-Tab Shell & Formatters | `mobile/`, `docs/07_MOBILE_DEVELOPMENT/P7_01_ARCHITECTURE_AND_FOUNDATION.md` | `P6-10` | `DONE` |
| `P7-02` | Design System, Warm Thrift Tokens, Christmas Decor & Shared Widgets | `mobile/lib/core/theme/`, `docs/07_MOBILE_DEVELOPMENT/P7_02_DESIGN_SYSTEM_AND_COMPONENTS.md` | `P7-01` | `DONE` |
| `P7-03` | Dio API Client, Sanctum Token Storage, ServerClockSync & Error Interceptors | `mobile/lib/core/network/`, `docs/07_MOBILE_DEVELOPMENT/P7_03_API_CLIENT_AND_STATE_CORE.md` | `P7-02` | `DONE` |
| `P7-04` | Auth Flows (M-AU-01..05), Unified Profile Hub & Address Book (M-PF-01..04, 06) | `mobile/lib/features/auth/`, `profile/`, `docs/07_MOBILE_DEVELOPMENT/P7_04_AUTH_AND_USER_PROFILE.md` | `P7-03` | `DONE` |
| `P7-05` | Home Discovery (M-HM-01..02), Category Tree & Multi-Filter Search (M-DS-01..03) | `mobile/lib/features/home/`, `catalog/`, `docs/07_MOBILE_DEVELOPMENT/P7_05_HOME_CATALOG_AND_SEARCH.md` | `P7-04` | `DONE` |
| `P7-06` | Product Detail (M-PD-01..02), Defect Zoom Viewer (M-DS-04) & Storefront (M-US-03) | `mobile/lib/features/product/`, `docs/07_MOBILE_DEVELOPMENT/P7_06_PRODUCT_DETAIL_AND_STOREFRONT.md` | `P7-05` | `DONE` |
| `P7-07` | Seller Channel Hub (M-SL-01), 7-State Listings (M-SL-02..04) & Wallet Ledger (M-SL-08) | `mobile/lib/features/seller/`, `docs/07_MOBILE_DEVELOPMENT/P7_07_SELLER_CHANNEL_LISTINGS.md` | `P7-06` | `DONE` |
| `P7-08` | Grouped Cart (M-CR-01), Checkout Preview DEC-04 (M-OR-01) & Mock QR Payment (M-PM-01..03) | `mobile/lib/features/cart/`, `docs/07_MOBILE_DEVELOPMENT/P7_08_CART_CHECKOUT_AND_PAYMENT.md` | `P7-07` | `DONE` |
| `P7-09` | Buyer/Seller Order Management (M-OR-02..05, M-SL-05..07) & Disputes (M-DP-01..03) | `mobile/lib/features/orders/`, `docs/07_MOBILE_DEVELOPMENT/P7_09_ORDER_FULFILLMENT_AND_DISPUTES.md` | `P7-07`, `P7-08` | `DONE` |
| `P7-10` | Scheduled Auction Hub, Live Bidding Room (M-AC-01..06) & Anti-Sniping BR-AU-04 | `mobile/lib/features/auctions/`, `docs/07_MOBILE_DEVELOPMENT/P7_10_AUCTION_EXPERIENCE.md` | `P7-08` | `DONE` |
| `P7-11` | 1-on-1 Polling Chat (M-CM-01..03), Notifications (M-NT-01), Favorites & Reviews (M-RV-01..02) | `mobile/lib/features/engagement/`, `docs/07_MOBILE_DEVELOPMENT/P7_11_CHAT_NOTIFICATION_AND_ENGAGEMENT.md` | `P7-09`, `P7-10` | `DONE` |
| `P7-12` | Full 52-Screen E2E Integration Verification, Widget Tests & Mobile Sign-Off | `mobile/test/`, `docs/07_MOBILE_DEVELOPMENT/P7_12_INTEGRATION_AND_MOBILE_SIGN_OFF.md` | `P7-11` | `DONE` |

## Phase 07 to Phase 14 (Summary Placeholders – Expand per Phase)
| Phase | Task ID Range | Core Deliverables | Target Directory | Dependency | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Phase 06** | `P6-01` .. `P6-10` | Domain Services, Policies, FormRequests, 74 API Endpoints (/api/v1/*), 4 Jobs, 88 Tests | `backend/` | `P5-07` | `DONE / APPROVED (100%)` |
| **Phase 07** | `P7-01` .. `P7-12` | Flutter Mobile App (52 Screens), MVVM, Provider/Riverpod, GoRouter, Dio (134/134 Tests PASS) | `mobile/` | `P6-10` | `DONE / APPROVED (OFFICIAL PO SIGN-OFF)` |
| **Phase 08** | `P8-01` .. `P8-06` | Admin Web Dashboard (21 Screens, Laravel Blade, Redis 7.4 Session Auth, 3-Tier RBAC, Immutable Audit Logs, PG18 34 Tables) | `backend/` | `P7-12` | `REVIEW (100% COMPLETE & VERIFIED: P8-01..P8-06 PASS)` |
| **Phase 09** | `P9-01` .. `P9-06` (`TR-01` .. `TR-08`) | Advanced Concurrency, Order Cancellation Matrix (P9-03 TECHNICAL ACCEPTANCE: ACCEPTED BY PO; 23/23 PASS), High-Concurrency Auctions | `backend/`, `mobile/`, `admin/` | `P8-06` | `IN PROGRESS (P9-03 TECHNICAL ACCEPTED; CLOSURE PENDING PO DECISION)` |
| **Phase 10** | `AU-01` .. `AU-08` | Auction Sessions, Anti-Sniping, Closing + Supplementary Test Backlog (8 Direct HTTP routes & Condition 422 Negative Tests) | `backend/`, `mobile/`, `admin/` | `TR-08` | `PENDING` |
| **Phase 11** | `CM-01` .. `CM-05` | Polling Chat, Rating & Review, Seller Trust Score, Disputes & Escrow Lock, Notifications | `backend/`, `mobile/`, `admin/` | `AU-08` | `PENDING` |
| **Phase 12** | `AD-01` .. `AD-10` | Admin Dashboard Completion, Developer Tools (Demo Mode Triggers), Audit Logs, Reports | `backend/`, `admin/` | `CM-05` | `PENDING` |
| **Phase 13** | `QA-01` .. `QA-06` | Unit/Feature Tests, Time-Travel Tests, Scenarios A/B/C, Edge Cases, Vietnamese Font QA | `docs/07_TESTING/` | `AD-10` | `PENDING` |
| **Phase 14** | `FN-01` .. `FN-05` | Demo Seeders, UI Polish, Env Check, Final Handover Docs & Presentation Script | `docs/08_DEPLOYMENT/`, `README.md` | `QA-06` | `PENDING` |

---

## Phase 10 – Supplementary Test Backlog (Ghi Nhận Từ Phase 07 PO Sign-Off Readiness)
Căn cứ quyết định phê chuẩn chính thức của Product Owner theo tài liệu `PHASE_07_FINAL_PO_SIGNOFF_READINESS.md`, các hạng mục sau được đưa vào backlog kiểm thử bổ sung của **Phase 10 (Testing & QA)**:
1. **8 API Endpoints Cần Bổ Sung Direct HTTP Feature Tests (Ưu tiên theo thứ tự):**
   - *Ưu tiên 1 (Orders & Disputes):*
     - `GET /api/v1/orders/purchases` (`BuyerOrderController@index`)
     - `GET /api/v1/orders/{id}` (`BuyerOrderController@show`)
     - `GET /api/v1/disputes` (`DisputeController@index`)
     - `GET /api/v1/disputes/{id}` (`DisputeController@show`)
   - *Ưu tiên 2 (Seller Channel):*
     - `GET /api/v1/seller/orders` (`SellerOrderController@index`)
     - `POST /api/v1/seller/products/{id}` (`SellerProductController@update` - multipart form-data fallback)
   - *Ưu tiên 3 (Auctions & System):*
     - `GET /api/v1/auctions/{id}/bids` (`AuctionController@bids`)
     - `GET /api/v1/health` (`BootstrapController@health`)
2. **Negative Tests Cho Product Condition (Validation HTTP 422 - BR-PR-03):**
   - Kiểm tra các giá trị không hợp lệ: `POOR`, `DAMAGED`, `VINTAGE` (không có `_WORN`), `UNKNOWN_CONDITION`, chuỗi rỗng `""`.
   - Khẳng định trả về HTTP `422 Unprocessable Content` kèm thông điệp `"Tình trạng sản phẩm không hợp lệ."`.
3. **Phạm vi kiểm soát:** Không tạo thêm Phase 13 mới; giữ nguyên roadmap và 34 tables trong PostgreSQL 18.
