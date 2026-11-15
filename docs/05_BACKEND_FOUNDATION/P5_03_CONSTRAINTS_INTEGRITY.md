# 03. DATABASE CONSTRAINTS, PARTIAL INDEXES & DATA INTEGRITY SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P503-CONSTRAINTS-INTEGRITY`
- **Version:** `1.0.0`
- **Status:** `DONE / APPROVED`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Target DBMS:** `PostgreSQL 18.x`
- **Phase:** `Phase 05 – Backend Foundation & Database Implementation (Task P5-03)`
- **Compliance Ref:** `DB_01..03`, `ERD_RELATIONSHIPS.md`, `BR-AC-01..04`, `BR-PR-01..05`, `BR-AU-01..07`, `BR-OR-01..05`, `BR-FN-01..07`, `DEC-02..07`

---

## Chương 1. Danh Mục Toàn Bộ Ràng Buộc Toàn Vẹn Cấp Độ CSDL (`Complete PostgreSQL 18 CHECK Constraints Catalog`)

### 1.1. Nhóm 1: Ràng Buộc Chống Tự Giao Dịch & Phân Quyền (`Anti-Self-Transaction & RBAC Guards – BR-AC-02`)

| Tên Ràng Buộc (`Constraint Name`) | Bảng Áp Dụng | Biểu Thức SQL `CHECK` Chuẩn Xác | Quy Tắc Nghiệp Vụ Bảo Vệ |
| :--- | :--- | :--- | :--- |
| `chk_users_role` | `users` | `role IN ('registered_user', 'moderator', 'support', 'admin')` | Khóa cứng 4 vai trò trong `03_ACTOR_PERMISSION_MATRIX.md`. |
| `chk_users_status` | `users` | `status IN ('ACTIVE', 'SUSPENDED', 'BANNED')` | Khóa cứng trạng thái tài khoản (`BR-AC-04`). |
| `chk_no_self_follow` | `seller_follows` | `follower_id <> seller_id` | Cấm người bán tự bấm theo dõi tiệm của chính mình (`BR-AC-02`). |
| `chk_conversation_user_order` | `conversations` | `user_one_id < user_two_id` | Kết hợp `UNIQUE(user_one_id, user_two_id)` đảm bảo không bao giờ tạo 2 phòng chat trùng giữa 2 người. |
| `chk_auctions_no_seller_self_lead` | `auctions` | `leading_bidder_id IS NULL OR leading_bidder_id <> seller_id` | Cấm chủ sản phẩm đứng tên người dẫn đầu phiên đấu giá (`BR-AC-02`). |
| `chk_auctions_no_seller_self_win` | `auctions` | `winner_id IS NULL OR winner_id <> seller_id` | Cấm chủ sản phẩm thắng phiên đấu giá của chính mình (`BR-AC-02`). |
| `chk_orders_no_self_purchase` | `orders` | `buyer_id <> seller_id` | Cấm người bán tự đặt mua sản phẩm của chính mình (`BR-AC-02`). |
| `chk_reviews_no_self_review` | `reviews` | `reviewer_id <> seller_id` | Cấm người bán tự viết đánh giá cho chính mình (`BR-AC-02`, `BR-RV-01`). |

---

### 1.2. Nhóm 2: Ràng Buộc Sản Phẩm Đồ Secondhand & Kiểm Duyệt (`Product & Moderation Guards – BR-PR-01..04, DEC-05`)

| Tên Ràng Buộc (`Constraint Name`) | Bảng Áp Dụng | Biểu Thức SQL `CHECK` Chuẩn Xác | Quy Tắc Nghiệp Vụ Bảo Vệ |
| :--- | :--- | :--- | :--- |
| `chk_products_condition` | `products` | `condition IN ('LIKE_NEW', 'GOOD', 'FAIR', 'VINTAGE_WORN')` | Bắt buộc chọn 1 trong 4 mức độ mới đồ cũ (`BR-PR-03`). |
| `chk_products_defect_not_empty` | `products` | `LENGTH(TRIM(defect_info)) > 0` | Cấm để trống hoặc chỉ nhập khoảng trắng ở mục khai báo vết xước (`BR-PR-03`). |
| `chk_products_listing_type` | `products` | `listing_type IN ('FIXED_PRICE', 'AUCTION')` | Phân loại hình thức bán (`BR-PR-01`). |
| `chk_products_price_positive` | `products` | `price > 0.00` | Giá bán hoặc giá khởi điểm phải dương. |
| `chk_products_total_qty` | `products` | `(listing_type = 'FIXED_PRICE' AND total_quantity >= 1) OR (listing_type = 'AUCTION' AND total_quantity = 1)` | Hàng đấu giá bắt buộc có số lượng duy nhất bằng `1` (`BR-PR-01`, `ASM-02`). |
| `chk_products_avail_qty` | `products` | `available_quantity >= 0 AND available_quantity <= total_quantity` | Chống âm kho (`Overselling`) hoặc tồn kho vượt tổng số lượng ban đầu. |
| `chk_products_verification` | `products` | `verification_level IN ('UNVERIFIED', 'EVIDENCE_PROVIDED', 'MODERATOR_REVIEWED')` | 3 mức độ xác minh kiểm duyệt (`A-MD-02`). |
| `chk_products_status` | `products` | `status IN ('DRAFT', 'PENDING_REVIEW', 'APPROVED', 'REJECTED', 'SOLD', 'HIDDEN', 'ARCHIVED')` | 7 trạng thái vòng đời sản phẩm (`M-SL-02`). |
| `chk_product_images_size` | `product_images` | `file_size_bytes IS NULL OR file_size_bytes <= 5242880` | Giới hạn kích thước ảnh `<= 5MB` (`NFR-SEC-05`). |
| `chk_mod_logs_mandatory_reason` | `product_moderation_logs` | `action NOT IN ('REJECTED', 'HIDDEN') OR LENGTH(TRIM(COALESCE(reason, ''))) > 0` | **Bắt buộc có lý do khi Moderator từ chối hoặc ẩn sản phẩm (`DEC-05`, `BR-PR-04`)**. |

---

### 1.3. Nhóm 3: Ràng Buộc Đấu Giá Theo Phiên (`Scheduled Auction Guards – BR-AU-01..07`)

| Tên Ràng Buộc (`Constraint Name`) | Bảng Áp Dụng | Biểu Thức SQL `CHECK` Chuẩn Xác | Quy Tắc Nghiệp Vụ Bảo Vệ |
| :--- | :--- | :--- | :--- |
| `chk_auction_sessions_time_order` | `auction_sessions` | `ends_at > starts_at` | Giờ đóng phiên phải sau giờ mở phiên. |
| `chk_auctions_starting_price` | `auctions` | `starting_price > 0.00` | Giá khởi điểm dương. |
| `chk_auctions_min_increment` | `auctions` | `min_bid_increment > 0.00` | Bước giá tối thiểu dương. |
| `chk_auctions_reserve_price` | `auctions` | `reserve_price IS NULL OR reserve_price >= starting_price` | Giá sàn (nếu có) không được thấp hơn giá khởi điểm. |
| `chk_auctions_current_bid` | `auctions` | `current_highest_bid = 0.00 OR current_highest_bid >= starting_price` | Giá dẫn đầu phải bằng `0` (chưa có bid) hoặc `>= starting_price`. |
| `chk_auctions_time_window` | `auctions` | `auction_ends_at > auction_starts_at` | Thời điểm kết thúc phiên phải lớn hơn thời điểm bắt đầu. |
| `chk_auctions_status` | `auctions` | `status IN ('SCHEDULED', 'LIVE', 'COMPLETED', 'ENDED_UNSOLD', 'WINNER_DEFAULTED', 'CANCELLED')` | 6 trạng thái máy trạng thái đấu giá (`DEC-02`). |
| `chk_auction_bids_amount_positive` | `auction_bids` | `bid_amount > 0.00` | Giá thầu đặt vào phải dương. |

---

### 1.4. Nhóm 4: Phương Trình Tài Chính Đơn Hàng, Sổ Cái Escrow & Ví Bất Biến (`Financial & Ledger Invariants – DEC-03, DEC-04, DEC-07, BR-FN-01..07`)

| Tên Ràng Buộc (`Constraint Name`) | Bảng Áp Dụng | Biểu Thức SQL `CHECK` Chuẩn Xác | Quy Tắc Nghiệp Vụ Bảo Vệ |
| :--- | :--- | :--- | :--- |
| `chk_seller_wallet_non_negative`<br>`chk_seller_escrow_non_negative` | `seller_profiles` | `wallet_balance >= 0.00` AND `escrow_held_balance >= 0.00` | Số dư Ví khả dụng và số dư chờ giải ngân không bao giờ âm. |
| `chk_orders_shipping_zero` | `orders` | `shipping_fee = 0.00` | Không thu phí vận chuyển trên ứng dụng (`DEC-04`). |
| `chk_orders_total_equation` | `orders` | `total_amount = item_subtotal + shipping_fee + buyer_protection_fee` | **Phương trình tổng tiền thanh toán của Buyer (`DEC-04`, `BR-FN-02`)**. |
| `chk_orders_seller_net_100_percent` | `orders` | `seller_net_amount = item_subtotal` | **Cam kết Seller luôn nhận đủ 100% tiền hàng (`DEC-04`)**. |
| `chk_orders_4_state_machines` | `orders` | Kiểm tra tập giá trị hợp lệ của 4 cột `order_status`, `payment_status`, `escrow_status`, `dispute_status` | Bảo vệ 4 vòng đời trạng thái độc lập (`ADR-03`). |
| `chk_order_items_line_total` | `order_items` | `line_total = unit_price_snapshot * quantity` | Đảm bảo thành tiền từng dòng snapshot chính xác tuyệt đối. |
| `chk_escrow_accounting_balance` | `escrow_transactions` | - `HOLD`: `seller_released_amount = 0 AND buyer_refunded_amount = 0 AND platform_fee_retained = 0`<br>- `RELEASE`: `seller_released_amount = item_subtotal_amount AND buyer_refunded_amount = 0 AND platform_fee_retained = buyer_protection_fee_amount`<br>- `FULL_REFUND`: `buyer_refunded_amount = gross_amount AND seller_released_amount = 0 AND platform_fee_retained = 0`<br>- `PARTIAL_REFUND`: `buyer_refunded_amount > 0 AND seller_released_amount > 0 AND (buyer_refunded_amount + seller_released_amount = item_subtotal_amount) AND platform_fee_retained = buyer_protection_fee_amount` | **Phương trình cân bằng kế toán bất biến cho cả 4 loại bút toán Escrow (`DEC-04`, `DEC-07`, `BR-FN-06`, `BR-FN-07`)**. |
| `chk_wallet_tx_balance_math` | `wallet_transactions` | `balance_after = balance_before + amount` | Đảm bảo số dư Ví Seller trước và sau giao dịch khớp toán học 100%. |
| `chk_disputes_opened_status` | `disputes` | `opened_at_order_status IN ('SHIPPED', 'DELIVERED')` | Chỉ cho phép mở khiếu nại khi đơn đang ở `SHIPPED` hoặc `DELIVERED` (`DEC-03`). |
| `chk_reviews_rating_range` | `reviews` | `rating >= 1 AND rating <= 5 AND LENGTH(TRIM(comment)) > 0` | Điểm đánh giá từ 1 đến 5 sao kèm nhận xét không rỗng (`BR-RV-01`). |

---

## Chương 2. Các Chỉ Mục Duy Nhất Có Điều Kiện (`Partial Unique Indexes`) & Chỉ Mục Hiệu Năng (`Performance Indexes`)

### 2.1. Hai `Partial Unique Indexes` Cốt Lõi
1. **`uq_auctions_active_product` trên bảng `auctions` (`DEC-02`, `AF-09`):**
   ```sql
   CREATE UNIQUE INDEX uq_auctions_active_product
       ON auctions(product_id)
       WHERE status IN ('SCHEDULED', 'LIVE');
   ```
   - *Tác dụng:* Ngăn chặn việc tạo 2 phiên đấu giá đang hoạt động cùng lúc cho 1 sản phẩm, nhưng **cho phép Seller đăng lại (`Relist`) sản phẩm đó vào phiên mới** sau khi phiên cũ kết thúc ở trạng thái `ENDED_UNSOLD` hoặc `WINNER_DEFAULTED` (người thắng quá 30 phút không thanh toán).
2. **`uq_payments_one_paid_per_order` trên bảng `payments` (`BR-FN-03`):**
   ```sql
   CREATE UNIQUE INDEX uq_payments_one_paid_per_order
       ON payments(order_id)
       WHERE status = 'PAID';
   ```
   - *Tác dụng:* Chặn tuyệt đối lỗi thanh toán đúp (`Double-Payment`) cho cùng một đơn hàng ngay cả khi có nhiều phiên QR từng bị `FAILED` hoặc `EXPIRED` trước đó.

### 2.2. Hai `Partial Performance Indexes` Phục Vụ Background Jobs (`P4-04C`)
1. **`idx_orders_unpaid_expiry`:** Tăng tốc Job 3 (`ExpireUnpaidAuctionOrdersJob` quét đơn quá hạn 30 phút):
   ```sql
   CREATE INDEX idx_orders_unpaid_expiry
       ON orders(order_status, payment_status, payment_expires_at ASC)
       WHERE order_status = 'PENDING_PAYMENT';
   ```
2. **`idx_orders_auto_complete`:** Tăng tốc Job 4 (`AutoCompleteDeliveredOrdersJob` quét đơn đã giao quá 24 giờ và **không có tranh chấp**):
   ```sql
   CREATE INDEX idx_orders_auto_complete
       ON orders(order_status, dispute_status, auto_complete_at ASC)
       WHERE order_status = 'DELIVERED' AND dispute_status = 'NONE';
   ```

---

## Chương 3. Tiêu Chí Nghiệm Thu & Các Bước Kiểm Tra `P5-03` (`Acceptance Criteria`)

- [x] **AC-P503-01 (Constraint Presence):** Truy vấn `pg_constraint` (loại `c` - Check Constraint) và `pg_indexes` xác nhận toàn bộ các `chk_*`, `uq_auctions_active_product`, `uq_payments_one_paid_per_order` đã được đăng ký trong PostgreSQL 18.
- [x] **AC-P503-02 (Rollback Safety):** Lệnh `php artisan migrate:rollback --step=1` gỡ bỏ sạch các constraint/index của `Tier 6` và `php artisan migrate` gắn lại thành công 0 lỗi.
- [x] **AC-P503-03 (Negative Integrity Test Suite):** Chạy lệnh `php artisan db:verify-constraints` thực hiện 10 kịch bản cố tình vi phạm quy tắc nghiệp vụ (Self-buy, Self-bid, Self-follow, Empty defect_info, Auction qty > 1, Reject without reason, Wrong order total equation, Unbalanced escrow ledger, Duplicate active auction, Duplicate PAID payment) và xác nhận **PostgreSQL 18 chặn đứng cả 10/10 kịch bản (`SQLSTATE[23514]` Check violation / `SQLSTATE[23505]` Unique violation)**.

---

## Chương 4. Bảng Kết Quả Thực Thi Kiểm Thử Âm Tính (`Negative Integrity Test Execution Log`)

Thực thi tự động bằng lệnh `php artisan db:verify-constraints` trên PostgreSQL 18 vào ngày `2026-11-14`:

| Mã Test | Kịch Bản Kiểm Thử Âm Tính | Ràng Buộc Mục Tiêu | Kết Quả Thực Tế | Phản Hồi Từ PostgreSQL 18 |
| :---: | :--- | :--- | :---: | :--- |
| **Test 01** | `BR-AC-02` Self-Follow (`follower_id = seller_id`) | `chk_no_self_follow` | **PASS** | `SQLSTATE[23514]` - Target guard: `chk_no_self_follow` |
| **Test 02** | `BR-PR-03` Empty Defect Info (Khoảng trắng) | `chk_products_defect_not_empty` | **PASS** | `SQLSTATE[23514]` - Target guard: `chk_products_defect_not_empty` |
| **Test 03** | `BR-PR-01` Auction Quantity > 1 (`AUCTION qty = 2`) | `chk_products_total_qty` | **PASS** | `SQLSTATE[23514]` - Target guard: `chk_products_total_qty` |
| **Test 04** | `DEC-05` Reject Without Reason (Lý do rỗng) | `chk_mod_logs_mandatory_reason` | **PASS** | `SQLSTATE[23514]` - Target guard: `chk_mod_logs_mandatory_reason` |
| **Test 05** | `BR-AC-02` Seller Self-Bid/Lead (`leading_bidder = seller`) | `chk_auctions_no_seller_self_lead` | **PASS** | `SQLSTATE[23514]` - Target guard: `chk_auctions_no_seller_self_lead` |
| **Test 06** | `DEC-02` Duplicate Active Auction (2nd `LIVE` auction) | `uq_auctions_active_product` | **PASS** | `SQLSTATE[23505]` - Target guard: `uq_auctions_active_product` |
| **Test 07** | `BR-AC-02` Buyer Self-Purchase (`buyer_id = seller_id`) | `chk_orders_no_self_purchase` | **PASS** | `SQLSTATE[23514]` - Target guard: `chk_orders_no_self_purchase` |
| **Test 08** | `DEC-04` Order Financial Equation (Sai lệch tổng tiền) | `chk_orders_total_equation` | **PASS** | `SQLSTATE[23514]` - Target guard: `chk_orders_total_equation` |
| **Test 09** | `BR-FN-03` Double PAID Payment (2nd `PAID` cùng đơn) | `uq_payments_one_paid_per_order` | **PASS** | `SQLSTATE[23505]` - Target guard: `uq_payments_one_paid_per_order` |
| **Test 10** | `DEC-07 & BR-FN-07` Unbalanced Escrow Ledger (`FULL_REFUND <> gross`) | `chk_escrow_accounting_balance` | **PASS** | `SQLSTATE[23514]` - Target guard: `chk_escrow_accounting_balance` |

> **Kết Luận Nghiệm Thu:** Toàn bộ 10/10 kịch bản vi phạm đều bị chặn đứng triệt để ngay tại tầng Database Engine PostgreSQL 18. Gói công việc `P5-03` đạt chất lượng nghiệm thu tối đa và đảm bảo an toàn tuyệt đối cho tầng ứng dụng.
