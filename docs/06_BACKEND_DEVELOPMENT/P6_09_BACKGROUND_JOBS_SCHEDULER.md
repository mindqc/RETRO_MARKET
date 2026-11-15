# P6-09: 4 IDEMPOTENT BACKGROUND JOBS, LARAVEL SCHEDULER & DEMO MODE TRIGGERS SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P609-JOBS-SCHEDULER`
- **Version:** `1.0.0`
- **Status:** DONE / APPROVED
- **Phase:** `Phase 06 – Task P6-09`
- **Dependencies:** `P6-06 (EscrowReleaseService)`, `P6-07 (AuctionLifecycleService)`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
- **Mục tiêu:** Hiện thực hóa 4 tiến trình nền tự động (`OpenScheduledAuctionsJob`, `CloseExpiredAuctionsJob`, `ExpireUnpaidAuctionOrdersJob`, `AutoCompleteDeliveredOrdersJob`), đăng ký lịch chạy mỗi phút trong `routes/console.php`, và xây dựng `SystemDevToolsService` cho phép kích hoạt tức thì từng tiến trình trong chế độ Demo Mode (`ADR-05`, `BR-AD-01`) bằng cùng một Domain Logic.
- **Phạm vi:** 4 Queue Jobs trong `app/Jobs/`, `OrderExpirationService`, `SystemDevToolsService` và Artisan commands / Scheduler.

## 2. Source Documents (`Tài Liệu Nguồn`)
- `docs/04_SYSTEM_ARCHITECTURE_AND_DB/04_BACKGROUND_JOBS_AND_SERVICES/CRON_JOBS_WORKERS.md`, `06_BUSINESS_RULES.md` (`BR-AU-06..07`, `BR-OR-05`, `BR-FN-04`, `BR-DP-02`, `BR-AD-01..02`), `08_ASSUMPTIONS_AND_DECISIONS.md` (`DEC-02`, `DEC-04`, `ADR-05`).

## 3. Technical Design & Domain Services (`Thiết Kế Kỹ Thuật & Dịch Vụ Nghiệp Vụ`)
1. **Nguyên tắc Kiến trúc Dùng Chung (`Single Source of Truth for Cron & Demo Triggers`):**
   - Các Job class không tự viết SQL rời rạc mà ủy quyền cho 3 Domain Methods sử dụng khóa dòng **`FOR UPDATE SKIP LOCKED`**:
     1. `AuctionLifecycleService::openDueScheduledAuctions(?User $actor = null): array`
     2. `AuctionLifecycleService::closeExpiredLiveAuctions(?User $actor = null): array`
     3. `OrderExpirationService::expireOverdueUnpaidOrders(?User $actor = null): array`
     4. `EscrowReleaseService::autoCompleteDueDeliveredOrders(?User $actor = null): array`
2. **Đặc tả 4 Jobs trong `backend/app/Jobs/` (`ShouldQueue`, `ShouldBeUnique`):**
   - `OpenScheduledAuctionsJob`: Quét `auctions` có `status = 'SCHEDULED'` & `auction_starts_at <= now()` (mà `product.status = 'APPROVED'`) $\rightarrow$ Chuyển `LIVE` & gửi thông báo cho `auction_watches`.
   - `CloseExpiredAuctionsJob`: Quét `auctions` có `status = 'LIVE'` & `auction_ends_at <= now()` $\rightarrow$ Nếu có người thắng hợp lệ đạt giá sàn thì chuyển `COMPLETED` và tạo đơn hàng thắng đấu giá (cộng `buyer_protection_fee` `DEC-04`, hạn 30 phút `BR-AU-07`); nếu không có ai trả giá hoặc chưa đạt giá sàn thì chuyển `ENDED_UNSOLD`.
   - `ExpireUnpaidAuctionOrdersJob`: Quét `orders` có `order_status = 'PENDING_PAYMENT'`, `payment_status = 'UNPAID'` & `payment_expires_at <= now()` $\rightarrow$ Chuyển đơn sang `CANCELLED`, phiên QR sang `EXPIRED`. Nếu là đơn `AUCTION` (`DEC-02`), chuyển phiên sang `WINNER_DEFAULTED`, tăng `seller_profiles.auction_default_count` của người mua bỏ cọc và mở khóa sản phẩm để Seller đăng lại (`Relist`). Nếu là đơn `FIXED_PRICE`, khôi phục `available_quantity`.
   - `AutoCompleteDeliveredOrdersJob`: Quét `orders` có `order_status = 'DELIVERED'`, `payment_status = 'PAID'`, `escrow_status = 'HELD'`, **`dispute_status = 'NONE'`, `escrow_frozen_at IS NULL`** và `auto_complete_at <= now()` $\rightarrow$ Gọi `EscrowReleaseService` chuyển `COMPLETED`, giải ngân **100% `item_subtotal`** vào `wallet_balance` (`DEC-04`).
3. **`App\Services\Governance\SystemDevToolsService` (`ADR-05`, `BR-AD-01`):**
   - Cho phép chạy 1 trong 4 tác vụ trên ngay lập tức (chỉ khi `config('retromarket.demo_mode') === true`), ghi nhận số lượng bản ghi đã xử lý và lưu vết vào `audit_logs`.

## 4. Files to Create or Modify (`File Mã Nguồn Dự Kiến`)
- `backend/app/Services/Order/OrderExpirationService.php`
- `backend/app/Services/Governance/SystemDevToolsService.php`
- `backend/app/Jobs/OpenScheduledAuctionsJob.php`
- `backend/app/Jobs/CloseExpiredAuctionsJob.php`
- `backend/app/Jobs/ExpireUnpaidAuctionOrdersJob.php`
- `backend/app/Jobs/AutoCompleteDeliveredOrdersJob.php`
- `backend/routes/console.php`
- `backend/tests/Feature/Api/V1/BackgroundJobsAndSchedulerTest.php`

## 5. API / Console Triggers
- Laravel Scheduler (`routes/console.php`): Đăng ký cả 4 Jobs với `->everyMinute()->withoutOverlapping()`.
- Artisan / Service Trigger: `SystemDevToolsService::triggerAction(User $admin, string $actionKey)` (phục vụ màn hình `A-DT-01` ở Phase 08 và kiểm thử tự động).

## 6. Business Rules & Idempotency Requirements
- **Idempotency (`BR-AD-01`):** Gọi liên tiếp 3 lần cùng một Job hoặc `SystemDevToolsService` tại cùng một thời điểm: lần 1 xử lý $N$ bản ghi tới hạn, lần 2 và lần 3 xử lý `0` bản ghi, tuyệt đối không sinh trùng đơn hàng hay giải ngân trùng.

## 7. Test Cases & Acceptance Criteria (`Tiêu Chí Nghiệm Thu`)
1. `test_open_scheduled_auctions_job_transitions_due_auctions_to_live_idempotently`
2. `test_close_expired_auctions_job_creates_winning_order_or_marks_ended_unsold`
3. `test_expire_unpaid_orders_job_marks_auction_winner_defaulted_and_increments_default_count`
4. `test_auto_complete_delivered_orders_job_releases_escrow_but_strictly_skips_disputed_orders`
5. `test_running_all_four_jobs_twice_in_a_row_is_100_percent_idempotent`
- **Acceptance Criteria:** 100% bài test trong `BackgroundJobsAndSchedulerTest.php` đạt `PASS`.

## 8. Risks & Mitigation
- **Rủi ro:** Hai tiến trình Cron và Manual Trigger chạy chồng lấn lên nhau.
- **Giảm thiểu:** Kết hợp `FOR UPDATE SKIP LOCKED` tại tầng SQL PostgreSQL 18 và kiểm tra trạng thái hiện tại trước khi ghi sổ cái.

## 9. Implementation & Automated Test Verification (`Kết Quả Thực Thi`)
- **Status:** DONE / APPROVED
- **Domain Methods Implemented with `FOR UPDATE SKIP LOCKED`:**
  1. `AuctionLifecycleService::openDueScheduledAuctions`: Tự động mở các phiên `SCHEDULED` tới hạn sang `LIVE`, gửi thông báo `AUCTION_STARTED` cho watchers.
  2. `AuctionLifecycleService::closeExpiredLiveAuctions`: Tự động chốt phiên `LIVE` hết hạn: nếu có người thắng hợp lệ thì sinh `Order` thắng đấu giá cộng `buyer_protection_fee` (`DEC-04`, hạn 30 phút `BR-AU-07`); nếu không có ai trả giá thì chuyển `ENDED_UNSOLD` và khôi phục sản phẩm sang `APPROVED`.
  3. `OrderExpirationService::expireOverdueUnpaidOrders`: Tự động hủy đơn quá hạn thanh toán (`CANCELLED`, `EXPIRED`), phạt tăng `auction_default_count` của người mua bỏ cọc, khôi phục sản phẩm đấu giá để `Relist` (`DEC-02`), và khôi phục số lượng cho đơn hàng thường.
  4. `EscrowReleaseService::autoCompleteDueDeliveredOrders`: Tự động hoàn tất đơn `DELIVERED` tới hạn và giải ngân 100% `item_subtotal` vào ví seller, bảo vệ nghiêm ngặt chống giải ngân khi đơn có khiếu nại (`dispute_status <> 'NONE'` hoặc `escrow_frozen_at IS NOT NULL` – `BR-DP-02`), đảm bảo tính lũy đẳng 100%.
- **Queue Jobs & Scheduler Configured:**
  - 4 Queue Jobs: `OpenScheduledAuctionsJob`, `CloseExpiredAuctionsJob`, `ExpireUnpaidAuctionOrdersJob`, `AutoCompleteDeliveredOrdersJob` (`ShouldQueue`, `ShouldBeUnique`, `$tries = 3`, `$backoff = [5, 15, 30]`, `uniqueFor = 55`).
  - Đăng ký lịch trình `->everyMinute()->withoutOverlapping()` trong `routes/console.php`.
- **System DevTools (Demo Mode ADR-05):**
  - `SystemDevToolsService::triggerJobAction`: Cho phép Admin kích hoạt tức thì từng Job hoặc cả 4 Jobs trong `DEMO_MODE=true`, ghi `AuditLog` với `action = 'DEVTOOLS_MANUAL_JOB_TRIGGER'`.
  - `SystemDevToolsController` và route `POST /api/v1/system/dev-tools/trigger-jobs` (`role:admin`, `demo.only`).
- **Automated Verification:**
  - `BackgroundJobsAndSchedulerTest.php`: **6/6 tests PASS** (47 assertions).
  - Full PHPUnit Test Suite: **84/84 tests PASS (100%)** (950 assertions, 0 errors, 0 failures).
  - Seeders Reconciliation (`db:verify-seeders`): **100% integrity, ZERO ledger drift**.
