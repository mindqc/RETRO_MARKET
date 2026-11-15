# P7-10: SCHEDULED AUCTIONS, LIVE BIDDING ROOM & ANTI-SNIPING SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P710-AUCTION-EXPERIENCE`
- **Version:** `1.0.0`
- **Status:** `DONE / PO APPROVED`
- **Phase:** `Phase 07 – Task P7-10`
- **Dependencies:** `P7-01, P7-02, P7-03, P7-05, P7-06, P7-08 Completed`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
Hiện thực hóa trải nghiệm đấu giá trực tuyến đặc sắc theo phiên (`Scheduled Auctions`), phòng đấu giá trực tiếp (`Live Bidding Room`) với đồng hồ đếm ngược đồng bộ thời gian thực từ máy chủ, cơ chế tự động gia hạn giờ chống bắn tỉa phút chót (**Anti-Sniping** theo `BR-AU-04`), xử lý xung đột giá đồng thời `409 AUCTION_OUTBID_CONFLICT`, chốt phiên sớm (`BR-AU-05`), và tái đăng đấu giá khi người thắng bùng cọc (`DEC-02`). Gói này bao gồm đúng **6 màn hình Mobile**:
- `M-AC-01`: Sàn Đấu Giá Theo Phiên (`Scheduled Auction Hub` – Tab 3)
- `M-AC-02`: Đấu Giá Của Tôi (`My Participating & Won Auctions`)
- `M-AC-03`: Phòng Đấu Giá Trực Tiếp (`Live Bidding Room`)
- `M-AC-04`: Bottom Sheet Đặt Giá Thầu & Xử Lý Xung Đột 409 (`Bid Placement Sheet`)
- `M-AC-05`: Hộp Thoại Chủ Tiệm Chốt Phiên Sớm (`Seller Close Early Modal`)
- `M-AC-06`: Biểu Mẫu Tái Đăng Sản Phẩm Đấu Giá (`Seller Relist Auction Modal`)

---

## 2. Screen Specifications & UX Flows (`Đặc Tả Chi Tiết 6 Màn Hình`)

### 2.1. `M-AC-01: Scheduled Auction Hub Screen` (Tab 3 Root)
- **Hệ Thống 4 Tab Phiên Đấu Giá:**
  1. `ĐANG DIỄN RA` (`LIVE`): Các phiên đang mở trả giá, sắp xếp theo độ sôi động.
  2. `SẮP KẾT THÚC` (`ENDING_SOON`): Các phiên `LIVE` còn dưới 1 giờ, sắp xếp tăng dần theo `auction_ends_at`.
  3. `SẮP MỞ` (`UPCOMING`): Các phiên `SCHEDULED` chuẩn bị mở trong ngày. Có nút `[Nhận thông báo khi mở]` (Watchlist).
  4. `ĐÃ KẾT THÚC` (`COMPLETED`): Lưu trữ các phiên đã chốt thành công hoặc không ai mua (`ENDED_UNSOLD`).
- **Thẻ Đấu Giá (`AuctionCard`):**
  - Ảnh đại diện đồ vintage, Tiêu đề, Huy hiệu `🔴 ĐANG ĐẤU GIÁ` hoặc `⏰ SẮP MỞ`.
  - Giá khởi điểm, Mức giá cao nhất hiện tại (`current_highest_bid`), Số lượt trả giá (`bid_count`).
  - Đồng hồ đếm ngược `CountdownTimerWidget`. Nút tim theo dõi nhanh (`Toggle Watch`).

### 2.2. `M-AC-02: My Auctions Screen`
- **Hệ Thống 3 Phân Mục:**
  1. **Đang tham gia (`Participating`):**
     - Hiển thị huy hiệu xanh lá `[👑 BẠN ĐANG DẪN ĐẦU]` nếu `leading_bidder_id == currentUser.id`.
     - Hiển thị huy hiệu cam cảnh báo `[⚠️ ĐÃ BỊ VƯỢT GIÁ]` nếu có người khác trả giá cao hơn, kèm nút `[Trả giá lại ngay]`.
  2. **Đang theo dõi (`Watchlist`):** Danh sách các phiên đã bấm lưu theo dõi.
  3. **Đã thắng đấu giá (`Won Auctions`):**
     - Hiển thị các phiên thắng với mức giá chốt.
     - **Đồng hồ đếm ngược 30 phút thanh toán (`BR-AU-07` / `DEC-02`):** Cảnh báo nếu không thanh toán trong 30 phút, tài khoản sẽ bị phạt đánh dấu `WINNER_DEFAULTED` và sản phẩm sẽ được trả về cho Seller đăng lại.
     - Nút nổi bật: **`[Thanh toán đơn hàng ngay 💳]`** mở `M-PM-01`.

### 2.3. `M-AC-03: Live Bidding Room Screen`
- **Đồng Hồ Đếm Ngược Trung Tâm Đồng Bộ Thời Gian Thực:**
  - Đồng bộ tuyệt đối theo `ServerTimeService.now()`.
  - **Huy hiệu Anti-Sniping Cảnh Báo (`BR-AU-04`):**
    - Khi có lượt trả giá hợp lệ trong 2 phút cuối (hoặc 30 giây trong demo mode), phiên tự động gia hạn thêm 2 phút.
    - Giao diện chớp viền vàng/đỏ Burgundy và hiển thị huy hiệu: *"Đã kích hoạt Anti-Sniping (+2 phút)"* kèm số lần đã gia hạn (`extended_count`).
- **Lịch Sử Trả Giá Thời Gian Thực (`Live Bid History`):**
  - Tự động gọi HTTP Short-Polling mỗi 3–5 giây qua `LifecyclePollingController` (chỉ khi màn hình đang hiển thị).
  - Danh sách người trả giá (ẩn một phần tên bảo mật, ví dụ: `u***9`), số tiền trả giá, thời gian trả giá. Lượt trả giá cao nhất được ghim nổi bật trên cùng.
- **Quy Tắc Chủ Tiệm (`is_owner == true`):**
  - Không được phép tự trả giá (`BR-AC-02`).
  - Hiển thị nút **`[Chốt phiên sớm]`** mở `M-AC-05`.
- **Thanh Hành Động Đặt Giá:**
  - Nút lớn: **`[🔨 ĐẶT GIÁ THẦU NGAY]`** mở Bottom Sheet `M-AC-04`.

### 2.4. `M-AC-04: Bid Placement Bottom Sheet & 409 Handler`
- **Gợi Ý Bước Giá Nhanh (`Quick Bid Chips`):**
  - Tính toán mức giá tối thiểu hợp lệ tiếp theo: $\text{min\_next\_bid} = \text{current\_highest\_bid} + \text{min\_bid\_increment}$.
  - 3 Chip chọn nhanh: `[min_next_bid]`, `[+ 1 bước giá]`, `[+ 2 bước giá]`.
  - Ô nhập số tiền tùy chọn (có validate `>= min_next_bid`).
- **Xử Lý Xung Đột Trả Giá Đồng Thời `409 AUCTION_OUTBID_CONFLICT`:**
  - Khi người dùng bấm `[Xác nhận đặt giá]`, nếu trong cùng một tích tắc có người khác vừa đặt mức giá cao hơn:
    - Backend trả về mã lỗi HTTP `409` kèm `latest_state` (`current_highest_bid`, `minimum_next_bid`, `auction_ends_at`, `extended_count`).
    - Flutter Client **không đóng Bottom Sheet**, mà lập tức cập nhật giá mới nhất và gợi ý lại bước giá mới ngay trên Sheet, kèm thông báo: *"Mức giá vừa bị người khác vượt qua! Mức giá tối thiểu mới là X đ. Bạn có muốn đặt tiếp không?"*.
    - Trải nghiệm mượt mà không làm gián đoạn cảm xúc đấu giá của người dùng.

### 2.5. `M-AC-05: Seller Close Early Modal` (`BR-AU-05`)
- Dành cho Chủ tiệm khi phiên đấu giá đã có ít nhất một lượt trả giá hợp lệ.
- Hộp thoại xác nhận chốt phiên ngay lập tức cho người đang dẫn đầu:
  - Hiển thị Người thắng dự kiến và Số tiền chốt.
  - Cảnh báo: *"Thao tác này sẽ kết thúc phiên đấu giá ngay lập tức và tạo đơn hàng cho người trả giá cao nhất."*
  - Gọi `POST /api/v1/auctions/{id}/close-early`.

### 2.6. `M-AC-06: Seller Relist Auction Modal` (`DEC-02`)
- Mở từ `M-SL-02` khi phiên đấu giá rơi vào trạng thái `ENDED_UNSOLD` (không có ai tham gia) hoặc `WINNER_DEFAULTED` (người thắng bùng cọc sau 30 phút).
- Cho phép Người bán điều chỉnh lại: Giá khởi điểm mới, Bước giá, Khung giờ phiên đấu giá mới.
- Gọi `POST /api/v1/seller/products/{id}/relist` tạo phiên đấu giá mới với trạng thái sản phẩm trở lại `APPROVED`.

---

## 3. Architecture & State Management (MVVM Pattern)
- **Models:** `AuctionCardModel`, `AuctionDetailModel`, `AuctionBidItemModel`, `OutbidConflictStateModel`.
- **Repositories:** `AuctionRepository`.
- **ViewModels (`ChangeNotifier`):**
  - `AuctionHubViewModel`: Quản lý 4 tab phiên đấu giá, tải thêm phân trang.
  - `MyAuctionsViewModel`: Quản lý danh sách đấu giá của tôi, phân loại dẫn đầu/vượt giá.
  - `LiveAuctionViewModel`: Quản lý đồng hồ đếm ngược phòng đấu giá, kích hoạt polling khi active, xử lý Anti-Sniping, submit đặt giá và xử lý lỗi `409 Conflict`.

---

## 4. API Endpoints Utilized
- `GET /api/v1/auctions` (với `tab: live, ending_soon, upcoming, completed`)
- `GET /api/v1/auctions/mine` (với `tab: participating, watchlist, won`)
- `GET /api/v1/auctions/{id}`
- `GET /api/v1/auctions/{id}/bids`
- `POST /api/v1/auctions/{id}/bids`
- `POST /api/v1/auctions/{id}/watch`
- `POST /api/v1/auctions/{id}/close-early`
- `POST /api/v1/seller/products/{id}/relist`

---

## 5. Acceptance Criteria (`Tiêu Chí Nghiệm Thu P7-10`)
- [x] **AC-P710-01:** Sàn đấu giá hiển thị đúng 4 tab và đồng hồ đếm ngược đồng bộ `server_time`.
- [x] **AC-P710-02:** Phòng đấu giá hiển thị huy hiệu Anti-Sniping `+2 phút` khi có giá mới ở phút chót (`BR-AU-04`).
- [x] **AC-P710-03:** Bottom Sheet đặt giá xử lý lỗi `409 AUCTION_OUTBID_CONFLICT` mượt mà, tự cập nhật `latest_state` trực tiếp.
- [x] **AC-P710-04:** Chủ tiệm chốt phiên sớm (`close-early`) và tái đăng (`relist`) thành công khi người thắng bỏ cọc.
- [x] **AC-P710-05:** Viết đầy đủ Unit & Widget tests cho ViewModels và 6 màn hình trong `test/features/auctions_test.dart` đạt **100% PASS** (10/10 test cases pass).

---

## 6. Implementation Deliverables
1. **Models (`mobile/lib/features/auctions/models/`):**
   - `auction_bid_item_model.dart`: Parsed `id`, `auction_id`, `bidder_id`, `bid_amount`, `triggered_anti_sniping`, `bidder`, `is_mine`, `is_leading`.
   - `outbid_conflict_state_model.dart`: Parsed `latest_state` envelope from 409 conflict.
   - `auction_card_model.dart`: Parsed cards for hub tabs and personal auction tabs with `isLeading`, `isOutbid`, `isLive`, `isCompleted`.
   - `auction_detail_model.dart`: Room detail with product, seller, leading bidder, reserve price, anti-sniping status, recent bids.
2. **Repository (`mobile/lib/features/auctions/repositories/`):**
   - `auction_repository.dart`: Integrated with 8 backend endpoints, syncs `ServerTimeService`, handles 409 conflict payload.
3. **ViewModels (`mobile/lib/features/auctions/viewmodels/`):**
   - `auction_hub_view_model.dart`: 4 Hub tabs (`live`, `ending_soon`, `upcoming`, `completed`), optimistic watch toggle, pagination.
   - `my_auctions_view_model.dart`: 3 Personal tabs (`participating`, `watchlist`, `won`), leading/outbid categorization.
   - `live_auction_view_model.dart`: Real-time short polling (3s) with `LifecyclePollingController` paused on background, Anti-sniping detection, concurrent bid placement with 409 conflict retention, close-early (`BR-AU-05`), relist (`DEC-02`).
4. **Screens & Modals (`mobile/lib/features/auctions/screens/`):**
   - `M-AC-01`: `scheduled_auction_hub_screen.dart` (Tab 3 Root in navigation shell).
   - `M-AC-02`: `my_auctions_screen.dart` (Leading/Outbid badges, 30-min payment deadline alert, payment CTA).
   - `M-AC-03`: `live_bidding_room_screen.dart` (Central synchronized countdown, Anti-sniping flash alert, Live bid history, Owner restrictions).
   - `M-AC-04`: `bid_placement_bottom_sheet.dart` (Quick bid chips, 409 conflict retention banner).
   - `M-AC-05`: `seller_close_early_modal.dart` (Projected winner, winning bid confirmation).
   - `M-AC-06`: `seller_relist_auction_modal.dart` (Relist unsold/defaulted product).
5. **Router Integration (`mobile/lib/core/router/`):**
   - Tab 3 wired to `ScheduledAuctionHubScreen`.
   - `/auctions/mine` registered for `MyAuctionsScreen`.
   - `/auctions/:id` registered for `LiveBiddingRoomScreen`.
6. **Automated Verification:**
   - `test/features/auctions_test.dart`: 10/10 PASS.
   - Full mobile suite: 111/111 PASS (`flutter test`).
   - Static analysis: 0 issues (`flutter analyze`).
   - Full backend suite: 88/88 PASS (`php artisan test`).
