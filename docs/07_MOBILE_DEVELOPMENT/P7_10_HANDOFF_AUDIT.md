# P7-10: AUCTION EXPERIENCE AUDIT & HANDOFF REPORT

- **Document ID:** `AUDIT-P710-AUCTION-EXPERIENCE`
- **Date:** `2026-11-15`
- **Target Task:** `Phase 07 – Task P7-10`
- **Status:** `REVIEW / READY FOR PO APPROVAL`
- **Scope:** Scheduled Auction Hub (`M-AC-01`), My Auctions (`M-AC-02`), Live Bidding Room & Anti-Sniping (`M-AC-03`), 409 Conflict Bid Sheet (`M-AC-04`), Close Early (`M-AC-05`), Relist (`M-AC-06`).

---

## 1. Executive Summary & Verification Metrics

| Verification Category | Status | Metrics / Evidences |
| :--- | :--- | :--- |
| **Static Analysis (`flutter analyze`)** | **PASSED** | `0 errors, 0 warnings, 0 hints` across entire codebase |
| **P7-10 Test Suite (`test/features/auctions_test.dart`)** | **PASSED** | `10/10 tests passed` (100% PASS) |
| **Full Mobile Test Suite (`flutter test`)** | **PASSED** | `111/111 tests passed` (100% PASS across all 11 test suites) |
| **Backend Test Suite (`php artisan test`)** | **PASSED** | `88/88 tests passed` (1,043 assertions, 0 failures) |
| **Anti-Sniping Engine (`BR-AU-04`)** | **VERIFIED** | +2 minutes extension triggered and alert badge displayed |
| **409 Conflict Retention (`M-AC-04`)** | **VERIFIED** | Sheet retained, latest state merged, quick chips adapted |
| **Owner Restrictions (`BR-AC-02`)** | **VERIFIED** | Bidding CTA hidden for host; close early (`M-AC-05`) provided |
| **Won 30-min Payment Deadline (`BR-AU-07`)** | **VERIFIED** | Default warning & direct payment CTA provided |

---

## 2. Deliverable Manifest

### 2.1. Models (`mobile/lib/features/auctions/models/`)
1. `auction_bid_item_model.dart`: Models individual bids with masked name, avatar, `is_mine`, `is_leading`, `triggered_anti_sniping`.
2. `outbid_conflict_state_model.dart`: Standardizes `latest_state` payload from 409 `AUCTION_OUTBID_CONFLICT`.
3. `auction_card_model.dart`: Card model for hub and personal tabs with status, leading/outbid flags, countdown timestamps.
4. `auction_detail_model.dart`: Full room detail model with product images, reserve price condition, winner, and recent bids.
5. `models.dart`: Barrel export file.

### 2.2. Repository (`mobile/lib/features/auctions/repositories/`)
- `auction_repository.dart`: Fully integrated with 8 backend API endpoints:
  - `GET /api/v1/auctions` (`tab: live, ending_soon, upcoming, completed`)
  - `GET /api/v1/auctions/mine` (`tab: participating, watchlist, won`)
  - `GET /api/v1/auctions/{id}`
  - `GET /api/v1/auctions/{id}/bids`
  - `POST /api/v1/auctions/{id}/bids`
  - `POST /api/v1/auctions/{id}/watch`
  - `POST /api/v1/auctions/{id}/close-early`
  - `POST /api/v1/seller/products/{id}/relist`
  - Synchronizes device clock with backend `server_time` via `ServerTimeService`.

### 2.3. ViewModels (`mobile/lib/features/auctions/viewmodels/`)
- `auction_hub_view_model.dart`: Controls 4 hub tabs, pagination, and optimistic watch status toggle.
- `my_auctions_view_model.dart`: Controls 3 personal tabs (`participating`, `watchlist`, `won`), leading/outbid counts.
- `live_auction_view_model.dart`: Short polling (3s) with `LifecyclePollingController` (background paused/foreground resumed), Anti-Sniping detection, concurrent bid placement with 409 Conflict retention, close-early, and relisting.
- `viewmodels.dart`: Barrel export file.

### 2.4. Screens & Modals (`mobile/lib/features/auctions/screens/`)
- `M-AC-01`: `scheduled_auction_hub_screen.dart` (Tab 3 Root).
- `M-AC-02`: `my_auctions_screen.dart` (Leading/outbid status, 30-min payment countdown warning, payment CTA).
- `M-AC-03`: `live_bidding_room_screen.dart` (Synchronized server countdown, Anti-sniping alert, live bid history, owner restrictions).
- `M-AC-04`: `bid_placement_bottom_sheet.dart` (Quick chips, custom input, 409 conflict retention).
- `M-AC-05`: `seller_close_early_modal.dart` (Early close confirmation dialog).
- `M-AC-06`: `seller_relist_auction_modal.dart` (Modal bottom sheet for relisting unsold/defaulted products).
- `screens.dart`: Barrel export file.

### 2.5. Routing (`mobile/lib/core/router/`)
- `app_routes.dart`: Added `AppRoutes.myAuctions` (`/auctions/mine`).
- `app_router.dart`: Wired Tab 3 to `ScheduledAuctionHubScreen`, registered `/auctions/mine` and `/auctions/:id`.

---

## 3. Automated Test Breakdown (`test/features/auctions_test.dart`)

1. **Test 1:** `Auction models parse JSON correctly and calculate getters` -> **PASS**
2. **Test 2:** `AuctionHubViewModel manages 4 tabs and optimistic watch toggle` -> **PASS**
3. **Test 3:** `MyAuctionsViewModel calculates leadingCount and outbidCount` -> **PASS**
4. **Test 4:** `LiveAuctionViewModel detects Anti-Sniping and handles 409 Outbid Conflict retention` -> **PASS**
5. **Test 5:** `ScheduledAuctionHubScreen renders 4 tabs, cards and triggers watch` -> **PASS**
6. **Test 6:** `MyAuctionsScreen shows leading badge, outbid CTA, and Won payment 30-min countdown` -> **PASS**
7. **Test 7:** `LiveBiddingRoomScreen displays server countdown, anti-sniping alert, and owner restrictions` -> **PASS**
8. **Test 8:** `BidPlacementBottomSheet renders quick chips and adapts seamlessly on 409 Conflict` -> **PASS**
9. **Test 9:** `SellerCloseEarlyModal confirms early closure` -> **PASS**
10. **Test 10:** `SellerRelistAuctionModal validates and submits relisting` -> **PASS**

---

## 4. Acceptance Criteria Verification

- [x] **AC-P710-01:** Sàn đấu giá hiển thị đúng 4 tab và đồng hồ đếm ngược đồng bộ `server_time`.
- [x] **AC-P710-02:** Phòng đấu giá hiển thị huy hiệu Anti-Sniping `+2 phút` khi có giá mới ở phút chót (`BR-AU-04`).
- [x] **AC-P710-03:** Bottom Sheet đặt giá xử lý lỗi `409 AUCTION_OUTBID_CONFLICT` mượt mà, tự cập nhật `latest_state` trực tiếp.
- [x] **AC-P710-04:** Chủ tiệm chốt phiên sớm (`close-early`) và tái đăng (`relist`) thành công khi người thắng bỏ cọc.
- [x] **AC-P710-05:** Viết đầy đủ Unit & Widget tests cho ViewModels và 6 màn hình trong `test/features/auctions_test.dart` đạt **100% PASS** (10/10 test cases pass).

---

## 5. Next Steps
- Waiting for Product Owner approval for Task `P7-10`.
- Upon approval, mark `P7-10` as `DONE` in `MASTER_TASK_TRACKER.md`.
- Next task in sequence: **`P7-11` (1-on-1 Polling Chat M-CM-01..03, Notifications M-NT-01, Favorites & Reviews M-RV-01..02)**.
