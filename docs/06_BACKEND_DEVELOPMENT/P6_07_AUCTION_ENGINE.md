# P6-07: SCHEDULED AUCTIONS, PESSIMISTIC CONCURRENT BIDDING, ANTI-SNIPING, CLOSE EARLY & RELIST SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P607-AUCTION-ENGINE`
- **Version:** `1.0.0`
- **Status:** DONE / APPROVED
- **Phase:** `Phase 06 – Task P6-07`
- **Dependencies:** `P6-04 (Products)`, `P6-05 (Order Creation & Buyer Protection Fee)`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
- **Mục tiêu:** Hiện thực hóa toàn bộ hệ thống Đấu giá theo phiên hàng ngày (`M-AC-01..05`): khám phá phiên đấu giá, theo dõi Watchlist, đặt giá thầu đồng thời với khóa bi quan `SELECT ... FOR UPDATE` (`BR-AU-03`), tự động gia hạn **Anti-Sniping** (`BR-AU-04`), chủ tiệm chốt phiên sớm (`Close Early` – `BR-AU-05`), tự động sinh đơn hàng thắng đấu giá cộng `Buyer Protection Fee` (`DEC-04`, hạn thanh toán 30 phút `BR-AU-07`), và đăng lại sản phẩm sau khi `ENDED_UNSOLD` hoặc `WINNER_DEFAULTED` (`Relist` – `DEC-02`).
- **Phạm vi:** `AuctionQueryService`, `AuctionBiddingService`, `AuctionLifecycleService` và các API `/api/v1/auctions/*`, `/api/v1/seller/products/{id}/relist`.

## 2. Source Documents (`Tài Liệu Nguồn`)
- `AUCTION_FLOW.md` (`AF-01..10`), `06_BUSINESS_RULES.md` (`BR-AC-02`, `BR-AU-01..07`), `08_ASSUMPTIONS_AND_DECISIONS.md` (`DEC-02`, `DEC-04`, `ADR-05`, `ADR-06`), `DB_02_AUCTION_SCHEMA.md`.
- Models: `AuctionSession`, `Auction`, `AuctionBid`, `AuctionWatch`, `Product`, `Order`, `OrderItem`, `Payment`, `Notification`.

## 3. Technical Design & Domain Services (`Thiết Kế Kỹ Thuật & Dịch Vụ Nghiệp Vụ`)
1. **`App\Services\Auction\AuctionQueryService`:**
   - `listAuctions(string $tab, ?int $categoryId, int $perPage, ?User $viewer)`: Hỗ trợ 4 tab trên `M-AC-01` (`live`, `ending_soon`, `upcoming` / `SCHEDULED`, `completed`).
   - `listMyAuctions(User $user, string $tab)`: Hỗ trợ 3 tab trên `M-AC-02` (`participating` kèm cờ `LEADING` / `OUTBID`, `watchlist`, `won` kèm thông tin đơn hàng thắng đấu giá và `payment_expires_at`).
   - `getAuctionRoomDetail(int $auctionId, ?User $viewer)`: Trả về chi tiết phòng đấu giá (`M-AC-03`), `server_time`, `auction_ends_at`, `current_highest_bid`, `minimum_next_bid`, `reserve_price_met` (boolean, không lộ con số `reserve_price` bí mật nếu chưa đạt), `extended_count` và 10 lượt `auction_bids` gần nhất.
2. **`App\Services\Auction\AuctionBiddingService` (`placeBid` – Trái tim chống Race Condition):**
   - Thực thi hoàn toàn trong `DB::transaction()`:
     1. Khóa dòng phiên đấu giá: `$auction = Auction::where('id', $auctionId)->lockForUpdate()->firstOrFail();`.
     2. **Chặn tự đặt giá (`BR-AC-02`):** Nếu `$bidder->id === $auction->seller_id`, ném `SelfTransactionForbiddenException` (`403 SELF_TRANSACTION_FORBIDDEN`).
     3. **Kiểm tra thời gian thực máy chủ (`BR-AU-01`):** Nếu `$auction->status !== 'LIVE'` hoặc `now()->greaterThanOrEqualTo($auction->auction_ends_at)`, ném `InvalidStateTransitionException` (`409`, `"Phiên đấu giá đã kết thúc hoặc chưa mở."`).
     4. **Kiểm tra bước giá hợp lệ (`BR-AU-02`):**
        - Tính `$minNextBid = $auction->minimumNextBidAmount()` (Nếu `bid_count === 0` thì bằng `starting_price`; nếu đã có bid thì bằng `current_highest_bid + min_bid_increment`).
        - Nếu `$bidAmount < $minNextBid`, ném **`AuctionOutbidConflictException`** (`409 AUCTION_OUTBID_CONFLICT`) đính kèm `latest_state` (`current_highest_bid`, `minimum_next_bid`, `leading_bidder_id`, `auction_ends_at`, `extended_count`) để Bottom Sheet `M-AC-04` cập nhật tức thì.
     5. **Kiểm tra và kích hoạt Anti-Sniping (`BR-AU-04`, `ADR-05`):**
        - Đọc `$windowSeconds` (`120s` Production / `30s` Demo Mode) và `$extensionSeconds` (`120s` Production / `30s` Demo Mode) từ `PlatformConfigService`.
        - Nếu khoảng cách từ `now()` đến `$auction->auction_ends_at` `<= $windowSeconds`: cộng thêm `$extensionSeconds` vào `$auction->auction_ends_at`, tăng `extended_count += 1`, gán `last_extended_at = now()`, và đặt `$triggeredAntiSniping = true`.
     6. Ghi bản ghi bất biến vào `auction_bids` (`previous_highest_bid = $auction->current_highest_bid`, `triggered_anti_sniping = $triggeredAntiSniping`).
     7. Cập nhật `$auction`: `current_highest_bid = $bidAmount`, `leading_bidder_id = $bidder->id`, `bid_count += 1`.
     8. Nếu có người dẫn đầu cũ (`$previousLeaderId !== null && $previousLeaderId !== $bidder->id`), tạo thông báo `AUCTION_OUTBID` trong bảng `notifications` (`AF-05`).
3. **`App\Services\Auction\AuctionLifecycleService`:**
   - `closeEarlyBySeller(User $seller, int $auctionId): array` (`BR-AU-05`, `AF-06`, `M-AC-05`):
     - Khóa dòng `Auction` (`lockForUpdate()`). Kiểm tra `$seller->id === $auction->seller_id`, `status === 'LIVE'`, `bid_count > 0`, `leading_bidder_id !== null` và `current_highest_bid >= ($auction->reserve_price ?? $auction->starting_price)`.
     - Đặt `closed_early_by_seller = true`, gọi hàm nội bộ `finalizeWinningAuction($auction)` để chuyển `status = 'COMPLETED'`, tạo đơn hàng thắng đấu giá (`order_source = 'AUCTION'`, cộng `buyer_protection_fee` theo `DEC-04`, hạn `payment_expires_at` = `+30 phút` Production / `+2 phút` Demo Mode) và ghi `AuditLogService::record(...)`.
   - `relistProductAuction(User $seller, Product $product, array $payload): Auction` (`DEC-02`, `AF-09`):
     - Kiểm tra phiên gần nhất của `$product` đang ở trạng thái `ENDED_UNSOLD` hoặc `WINNER_DEFAULTED` (và không có phiên nào đang `SCHEDULED`/`LIVE` theo Partial Index `uq_auctions_active_product`).
     - Khôi phục `$product->update(['status' => 'APPROVED', 'available_quantity' => 1])` và tạo bản ghi `Auction` mới ở trạng thái `SCHEDULED` (hoặc `LIVE` nếu phiên đang mở).
   - `cancelAuctionByAdmin(User $admin, Auction $auction, string $reason): Auction` (`PERM-AC-09`, `AF-10`).

## 4. Files to Create or Modify (`File Mã Nguồn Dự Kiến`)
- `backend/app/Services/Auction/AuctionQueryService.php`
- `backend/app/Services/Auction/AuctionBiddingService.php`
- `backend/app/Services/Auction/AuctionLifecycleService.php`
- `backend/app/Http/Controllers/Api/V1/AuctionController.php`
- `backend/app/Http/Requests/Api/V1/Auction/PlaceBidRequest.php`, `RelistAuctionRequest.php`
- `backend/app/Http/Resources/Api/V1/AuctionCardResource.php`, `AuctionDetailResource.php`, `AuctionBidResource.php`
- `backend/tests/Feature/Api/V1/AuctionEngineTest.php`

## 5. API Endpoints (`Danh Sách Endpoints`)
- `GET /api/v1/auctions`, `GET /api/v1/auctions/mine`, `GET /api/v1/auctions/{id}`, `GET /api/v1/auctions/{id}/bids`
- `POST /api/v1/auctions/{id}/bids` (`auth:sanctum`, `active.user`, `throttle:transactional`)
- `POST /api/v1/auctions/{id}/watch` (`auth:sanctum`, `active.user`)
- `POST /api/v1/auctions/{id}/close-early` (`auth:sanctum`, `active.user`)
- `POST /api/v1/seller/products/{id}/relist` (`auth:sanctum`, `active.user`)

## 6. Business Rules, Validation & Authorization
- **Business Rules:** `BR-AC-02` (Chặn Seller tự bid), `BR-AU-01..07` (Server time, bước giá, khóa dòng `lockForUpdate()`, Anti-Sniping, Close Early, hạn thanh toán 30 phút), `DEC-02` (Relist sau khi bỏ cọc), `DEC-04` (Cộng Buyer Protection Fee vào đơn thắng đấu giá).

## 7. Test Cases & Acceptance Criteria (`Tiêu Chí Nghiệm Thu`)
1. `test_seller_cannot_bid_on_own_auction_403_self_transaction_forbidden`
2. `test_valid_bid_updates_highest_bid_and_notifies_previous_leading_bidder`
3. `test_underbid_or_race_condition_returns_409_auction_outbid_conflict_with_latest_state`
4. `test_bid_within_final_sensitivity_window_triggers_anti_sniping_extension`
5. `test_seller_close_early_succeeds_when_reserve_met_and_creates_winning_order_with_protection_fee`
6. `test_seller_can_relist_product_after_ended_unsold_or_winner_defaulted`
- **Acceptance Criteria:** 100% bài test trong `AuctionEngineTest.php` đạt `PASS`.

## 8. Risks & Mitigation
- **Rủi ro:** Người thắng đấu giá chưa có địa chỉ mặc định trong `user_addresses` tại thời điểm phiên tự động đóng (`OQ-P6-02`).
- **Giảm thiểu:** Sử dụng địa chỉ mặc định nếu có, hoặc tạo snapshot placeholder hợp lệ và cho phép người thắng chọn địa chỉ khi vào thanh toán đơn `PENDING_PAYMENT`.

## 9. Implementation & Automated Test Verification (`Kết Quả Thực Thi`)
- **Status:** DONE / APPROVED
- **Domain Services Implemented:**
  1. `App\Services\Auction\AuctionQueryService`: `listHubAuctions` (tabs: live, ending_soon, upcoming, completed), `listMyAuctions` (participating, watchlist, won), `getAuctionRoomDetail` (hides reserve_price from buyers until met), `listAuctionBids`, `toggleWatch`.
  2. `App\Services\Auction\AuctionBiddingService`: `placeBid` (Pessimistic `lockForUpdate()`, anti-self-bidding `403 SELF_TRANSACTION_FORBIDDEN`, real-time server clock `BR-AU-01`, minimum next bid check returning `409 AUCTION_OUTBID_CONFLICT` with `latest_state`, Anti-Sniping time extension `BR-AU-04`, notification `AUCTION_OUTBID` for previous leader `AF-05`).
  3. `App\Services\Auction\AuctionLifecycleService`: `closeEarlyBySeller` (checks reserve floor `BR-AU-05`), `finalizeAuctionWithWinner` (generates `Order` + `DEC-04` Buyer Protection Fee + 30m deadline), `relistAuctionProduct` (`DEC-02` / `AF-09`).
- **FormRequests & Resources Created:** `PlaceBidRequest`, `RelistAuctionRequest`, `AuctionBidResource`, `AuctionCardResource`, `AuctionDetailResource`, `AuctionController`. 8 routes registered in `api.php`.
- **Automated Verification:**
  - `AuctionEngineTest.php`: **8/8 tests PASS** (66 assertions).
  - Full PHPUnit Test Suite: **70/70 tests PASS** (841 assertions, 0 errors, 0 failures).
  - Seeders Reconciliation (`db:verify-seeders`): **100% integrity, ZERO ledger drift**.
