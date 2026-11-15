# 06. DATABASE VALIDATION, VERIFICATION & AUTOMATED TEST SUITE REPORT – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P506-VALIDATION-REPORT`
- **Version:** `1.0.0`
- **Status:** `DONE / APPROVED`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Target DBMS:** `PostgreSQL 18.x`
- **Phase:** `Phase 05 – Backend Foundation & Database Implementation (Task P5-06)`
- **Compliance Ref:** `DB_01..03`, `ERD_RELATIONSHIPS.md`, `P5_01..P5_05`, `NFR-REL-01..04`, `NFR-PER-01..03`

---

## Chương 1. Chiến Lược Kiểm Thử & Xác Thực Cơ Sở Dữ Liệu Thực Tế (`PostgreSQL 18 Native Verification Strategy`)

Khác với các dự án thông thường dùng SQLite `:memory:` khi chạy PHPUnit (vốn bỏ qua hoàn toàn các tính năng nâng cao của PostgreSQL), hệ thống kiểm thử của **Retro Market (`izithrift`)** bắt buộc chạy trực tiếp trên **PostgreSQL 18 (`retromarket_postgres18`)** để kiểm chứng trung thực 100% các cơ chế bảo vệ dữ liệu:

1. **Kiểm thử Vòng đời Migration (`Migration Lifecycle & Rollback Test`):**
   - Đảm bảo `migrate:fresh` $\rightarrow$ `migrate:rollback --step=6` $\rightarrow$ `migrate` thực thi hoàn hảo, khi rollback tới bước cuối thì `information_schema.tables` chỉ còn duy nhất bảng hệ thống `migrations`.
2. **Kiểm thử Toàn vẹn Tham chiếu Khóa ngoại (`Referential Integrity Policy Test`):**
   - Chứng minh `ON DELETE RESTRICT` chặn đứng lệnh xóa vật lý `DELETE FROM users` hoặc `DELETE FROM orders` khi đã có giao dịch.
   - Chứng minh `ON DELETE CASCADE` tự động xóa sạch dữ liệu phụ thuộc khi xóa bản ghi cha chưa phát sinh giao dịch.
3. **Kiểm thử Chống Lỗi `N+1 Query` Trên Các Luồng Nặng (`Eager Loading & Query Count Audit`):**
   - Sử dụng `DB::enableQueryLog()` để xác nhận việc tải danh sách sản phẩm kèm `seller`, `category`, `brand`, `primaryImage` hoặc tải chi tiết đơn hàng kèm `buyer`, `seller`, `items`, `shipment`, `escrowTransactions`, `dispute` chỉ tốn số lượng query cố định, không bị lặp `N+1`.
4. **Kiểm thử Kế hoạch Truy vấn Chỉ mục (`PostgreSQL Index Usage Audit`):**
   - Kiểm tra sự hiện diện và khả năng sử dụng các chỉ mục cốt lõi (`uq_auctions_active_product`, `uq_payments_one_paid_per_order`, `idx_orders_unpaid_expiry`, `idx_orders_auto_complete`, `idx_messages_polling`).

---

## Chương 2. Ma Trận 12 Bài Kiểm Thử Tự Động Trong `DatabaseFoundationVerificationTest.php`

| Mã Test (`Test Case`) | Tên Phương Thức Kiểm Thử (`PHPUnit Method`) | Nội Dung Kiểm Chứng Trên PostgreSQL 18 | Kỳ Vọng (`Expected Assertion`) | Kết Quả Thực Tế |
| :---: | :--- | :--- | :--- | :---: |
| **`TC-P506-01`** | `test_all_34_domain_tables_and_column_types_exist` | Kiểm tra sự tồn tại của đủ 34 bảng, kiểu `numeric(15,2)` cho cột tiền tệ, `timestamp with time zone` cho cột thời gian và `jsonb` cho snapshot/audit. | `PASS` (34/34 bảng khớp 100%). | **PASSED** |
| **`TC-P506-02`** | `test_platform_settings_and_seeded_actors_exist` | Kiểm tra 12 khóa `platform_settings` và 10 tài khoản mẫu (`admin`, `moderator`, `support`, sellers, buyers, `SUSPENDED` user). | `PASS` (Đọc đúng `protection_fee_rate = 0.06` & `protection_fixed_fee = 7000`). | **PASSED** |
| **`TC-P506-03`** | `test_idempotent_seeder_execution_produces_zero_duplicates` | Đếm tổng số bản ghi của các bảng trước và sau khi gọi lại `$this->seed(\Database\Seeders\DatabaseSeeder::class)`. | `PASS` (Số lượng bản ghi và số dư Ví/Escrow giữ nguyên tuyệt đối). | **PASSED** |
| **`TC-P506-04`** | `test_database_check_constraints_block_self_transactions` | Thử vi phạm `BR-AC-02` (Tự mua hàng, Tự theo dõi, Tự dẫn đầu đấu giá, Tự đánh giá). | `PASS` (PostgreSQL 18 ném `QueryException` cho cả 4 hành vi). | **PASSED** |
| **`TC-P506-05`** | `test_product_and_moderation_check_constraints` | Thử tạo sản phẩm rỗng `defect_info`, hàng `AUCTION` có `total_quantity = 2`, hoặc log `REJECTED` rỗng `reason` (`DEC-05`). | `PASS` (Bị chặn bởi `chk_products_*` và `chk_mod_logs_mandatory_reason`). | **PASSED** |
| **`TC-P506-06`** | `test_partial_unique_index_allows_relist_but_blocks_dual_live_auctions` | Kiểm tra `uq_auctions_active_product`: Chặn 2 phiên `LIVE` cùng `product_id`, nhưng cho phép tạo phiên mới khi phiên cũ là `ENDED_UNSOLD` / `WINNER_DEFAULTED` (`DEC-02`). | `PASS` | **PASSED** |
| **`TC-P506-07`** | `test_order_financial_equation_and_single_paid_payment_index` | Kiểm tra `chk_orders_total_equation`, `chk_orders_seller_net_100_percent` (`DEC-04`) và `uq_payments_one_paid_per_order` (`BR-FN-03`). | `PASS` | **PASSED** |
| **`TC-P506-08`** | `test_escrow_and_wallet_ledger_accounting_invariants` | Kiểm tra cân bằng sổ cái `escrow_transactions` (`HOLD`, `RELEASE`, `FULL_REFUND`, `PARTIAL_REFUND`) và đối soát `seller_profiles.wallet_balance` / `escrow_held_balance`. | `PASS` (`Zero Ledger Drift`). | **PASSED** |
| **`TC-P506-09`** | `test_immutable_ledger_models_prevent_update_and_delete` | Gọi `$model->update(...)` và `$model->delete()` trên `EscrowTransaction`, `WalletTransaction`, `AuctionBid`, `OrderItem`, `ProductModerationLog`, `AuditLog`. | `PASS` (Ném `LogicException` ngay lập tức). | **PASSED** |
| **`TC-P506-10`** | `test_foreign_key_on_delete_restrict_protects_transactional_history` | Thử xóa vật lý (`DELETE`) một `users` hoặc `orders` đã phát sinh giao dịch. | `PASS` (PostgreSQL 18 chặn xóa nhờ `ON DELETE RESTRICT`). | **PASSED** |
| **`TC-P506-11`** | `test_pessimistic_locking_select_for_update_works_on_auctions_and_orders` | Thực thi `Auction::where('id', ...)->lockForUpdate()->first()` và `Order::where('id', ...)->lockForUpdate()->first()` trong `DB::transaction()`. | `PASS` (Sinh đúng câu lệnh `FOR UPDATE` trên PostgreSQL 18). | **PASSED** |
| **`TC-P506-12`** | `test_eager_loading_relationships_without_n_plus_one_queries` | Tải danh sách `Product::with(...)` và `Order::with(...)`, đo số lượng câu lệnh SQL trong `DB::getQueryLog()`. | `PASS` (Không phát sinh lỗi `N+1` hay lỗi thiếu cột FK). | **PASSED** |

---

## Chương 3. Tiêu Chí Nghiệm Thu `P5-06` (`Acceptance Criteria`)

- [x] **AC-P506-01:** Chu trình `migrate:fresh --seed` $\rightarrow$ `migrate:rollback --step=6` $\rightarrow$ `migrate --seed` chạy sạch 100% không lỗi.
- [x] **AC-P506-02:** Cả 4 lệnh Artisan kiểm định (`system:health-check`, `db:verify-constraints`, `model:verify-architecture`, `db:verify-seeders`) đều báo `PASS`.
- [x] **AC-P506-03:** Chạy `php artisan test --filter=DatabaseFoundationVerificationTest` đạt **12/12 tests PASSED (100% assertions passed)** trên PostgreSQL 18.

---

## Chương 4. Nhật Ký Nghiệm Thu Thực Tế (`Automated Test Execution Output`)

- **Ngày Thực Thi:** `2026-11-14`
- **Môi Trường:** Host PHP `8.4.27`, Laravel `13.42.0`, PostgreSQL `18.7` (Docker `retromarket_postgres18`), Redis `7.4` (Docker `retromarket_redis7`).
- **Cấu Hình PHPUnit:** `backend/phpunit.xml` đã bỏ SQLite in-memory, kết nối trực tiếp PostgreSQL 18 `pgsql` (`retromarket_db`).

### 4.1. Kết Quả Chạy PHPUnit Suite (`php artisan test --filter=DatabaseFoundationVerificationTest --testdox`):
```text
PHPUnit 12.5.44 by Sebastian Bergmann and contributors.
Runtime: PHP 8.4.27
Configuration: D:\Duc\Tài liệu học tập (real)\Năm 4\EC402\Báo cáo thực hành\Source Code\RETRO_MARKET\backend\phpunit.xml
Time: 00:01.756, Memory: 52.00 MB

Database Foundation Verification (Tests\Feature\DatabaseFoundationVerification)
 ✔ All 34 domain tables and column types exist
 ✔ Platform settings and seeded actors exist
 ✔ Idempotent seeder execution produces zero duplicates
 ✔ Database check constraints block self transactions
 ✔ Product and moderation check constraints
 ✔ Partial unique index allows relist but blocks dual live auctions
 ✔ Order financial equation and single paid payment index
 ✔ Escrow and wallet ledger accounting invariants
 ✔ Immutable ledger models prevent update and delete
 ✔ Foreign key on delete restrict protects transactional history
 ✔ Pessimistic locking select for update works on auctions and orders
 ✔ Eager loading relationships without n plus one queries

OK (12 tests, 122 assertions)
```

### 4.2. Kết Quả Kiểm Thử Vòng Đời Migration & Rollback:
- `php artisan migrate:rollback --step=6`: Rollback thành công 6/6 tiers, database dọn sạch 34 bảng nghiệp vụ, chỉ còn bảng `migrations`.
- `php artisan migrate:fresh --seed`: Dựng lại hoàn chỉnh 34 bảng, 79 `CHECK` constraints, 2 Partial Unique Indexes, 17 performance indexes và nạp đủ 6 class seeders.

### 4.3. Kết Quả 4 Lệnh Kiểm Định Toàn Diện Hệ Thống:
1. `php artisan system:health-check`: **PASS** (PostgreSQL 18.7, Redis 7.4, PHP 8.4, Laravel 13, Storage disk).
2. `php artisan db:verify-constraints`: **PASS** (79 check constraints, 2 partial unique indexes, 10/10 negative tests).
3. `php artisan model:verify-architecture`: **PASS** (32 Eloquent models, 116 relationships, 5/5 immutability guards).
4. `php artisan db:verify-seeders`: **PASS** (28 table minimums, full state coverage, zero ledger drift, DEC-04 equations).
