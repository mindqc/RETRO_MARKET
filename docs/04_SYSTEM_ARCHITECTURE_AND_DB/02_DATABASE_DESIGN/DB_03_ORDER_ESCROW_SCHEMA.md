# 03. ORDER, MOCK QR PAYMENT, IMMUTABLE ESCROW LEDGER & DISPUTE DATABASE SCHEMA – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P403A-DB-ORDER-ESCROW-SCHEMA`
- **Version:** `1.0.0 (COMPLETE POSTGRESQL 18 DDL SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Target DBMS:** `PostgreSQL 18.x`
- **Phase:** `Phase 04 – System Architecture, Database Design & API Specification`
- **Compliance Ref:** `OF-01..10`, `FR-CR-01`, `FR-OR-01..06`, `FR-PM-01..02`, `FR-ES-01..04`, `FR-DP-01..03`, `FR-RV-01`, `BR-OR-01..05`, `BR-FN-01..07`, `BR-DP-01..02`, `BR-RV-01`, `DEC-02..07`, `ADR-03..06`

---

## Chương 1. Kiến Trúc Lưu Trữ Giao Dịch, 4 Máy Trạng Thái Độc Lập & Sổ Cái Bất Biến (`Transactional & Financial Ledger Architecture`)

Phân hệ Giỏ hàng, Đơn hàng, Thanh toán QR mô phỏng, Sổ cái trung gian Escrow, Khiếu nại và Đánh giá là trái tim tài chính của **Retro Market (`izithrift`)**. Toàn bộ 11 bảng trong tài liệu này được thiết kế với 6 cơ chế bảo vệ cấp độ cơ sở dữ liệu (`Database-Enforced Guarantees`):

1. **Thực thi 4 Vòng đời Trạng thái Độc lập trên Bảng `orders` (`ADR-03`):**
   - Mỗi dòng đơn hàng duy trì đồng thời 4 cột trạng thái tách biệt: `order_status` (7 trạng thái vận hành), `payment_status` (4 trạng thái thanh toán), `escrow_status` (5 trạng thái giữ/giải ngân/hoàn tiền) và `dispute_status` (4 trạng thái tranh chấp).
2. **Ràng buộc Phương trình Tài chính Bất biến Ngay Tại Tầng SQL (`Financial Equation Constraint – DEC-04 & BR-FN-02`):**
   - Bảng `orders` áp dụng `CHECK Constraint` trực tiếp trên PostgreSQL 18:
     - `shipping_fee = 0.00` (Miễn thu phí vận chuyển trên ứng dụng).
     - `total_amount = item_subtotal + shipping_fee + buyer_protection_fee`.
     - `seller_net_amount = item_subtotal` (Người bán luôn nhận đủ **100% `item_subtotal`** khi đơn hoàn tất).
3. **Bản Chụp Đơn Hàng Bất Biến (`Frozen Order Snapshot – BR-OR-02`):**
   - Bảng `order_items` lưu cứng `product_title_snapshot`, `unit_price_snapshot`, `condition_snapshot`, `defect_info_snapshot` và `primary_image_snapshot` tại đúng mili-giây tạo đơn; bảng `orders` lưu cứng `shipping_address_snapshot (JSONB)` để mọi thay đổi hồ sơ sau đó không bao giờ làm sai lệch bằng chứng giao dịch.
4. **Sổ Cái Kế Toán Chỉ Ghi Thêm (`Append-Only Immutable Ledgers – BR-FN-07`):**
   - Hai bảng `escrow_transactions` và `wallet_transactions` là sổ cái bất biến (`INSERT ONLY`). Mọi bút toán `HOLD`, `RELEASE`, `REFUND`, `PARTIAL_REFUND` đều kiểm tra cân bằng tổng tiền (`amount_total = seller_released_amount + buyer_refunded_amount + platform_fee_retained`).
5. **Khóa Giải Ngân Tự Động Khi Có Khiếu Nại (`Dispute Freeze Guard – DEC-03 & BR-DP-02`):**
   - Cho phép mở khiếu nại khi đơn ở trạng thái `SHIPPED` hoặc `DELIVERED`. Ngay khi bản ghi `disputes` được tạo (`status = 'OPEN'`), cột `orders.dispute_status` chuyển sang `'OPEN'` và `orders.escrow_frozen_at` được ghi nhận, chặn đứng tiến trình `AutoCompleteDeliveredOrdersJob`.
6. **Chống Đánh Giá Ảo (`Verified Completed-Order Review Guard – BR-RV-01`):**
   - Bảng `reviews` đặt khóa `UNIQUE(order_id)` để mỗi đơn hàng đã `COMPLETED` chỉ được phép tạo tối đa 1 đánh giá xác thực từ chính `buyer_id` của đơn đó.

---

## Chương 2. Danh Mục 11 Bảng Thuộc Phân Hệ Order, Payment, Escrow, Dispute & Review (`DB_03 Table Inventory`)

| STT | Tên Bảng (`Table Name`) | Nhóm Nghiệp Vụ | Khóa Chính (`PK`) | Mô Tả Vai Trò Cốt Lõi |
| :-: | :--- | :--- | :---: | :--- |
| 19 | `carts` | Cart | `id (BIGSERIAL)` | Giỏ hàng của từng người dùng (`1:1` với `users`). |
| 20 | `cart_items` | Cart | `id (BIGSERIAL)` | Các sản phẩm `FIXED_PRICE` được lưu trong giỏ, gom nhóm theo `seller_id` trên UI (`M-CR-01`). |
| 21 | `orders` | Order Core | `id (BIGSERIAL)` | Đơn hàng trung tâm (Fixed-Price & Auction Winner), lưu 4 trạng thái độc lập, công thức phí `DEC-04` và mốc `auto_complete_at`. |
| 22 | `order_items` | Order Snapshot | `id (BIGSERIAL)` | Bản chụp sản phẩm bất biến tại thời điểm tạo đơn (`BR-OR-02`). |
| 23 | `shipments` | Fulfillment | `id (BIGSERIAL)` | Thông tin vận chuyển thủ công do Seller cập nhật (`carrier_name`, `tracking_code` – `M-SL-07`). |
| 24 | `payments` | Mock QR Payment | `id (BIGSERIAL)` | Phiên thanh toán QR mô phỏng kèm mã tham chiếu `payment_reference` và hạn `expires_at` (`M-PM-01`). |
| 25 | `escrow_transactions` | Escrow Ledger | `id (BIGSERIAL)` | Sổ cái giữ tiền, giải ngân và hoàn tiền trung gian bất biến (`A-ES-01`, `M-SL-08`). |
| 26 | `wallet_transactions` | Seller Wallet | `id (BIGSERIAL)` | Sổ cái biến động số dư Ví Người bán (`CREDIT` 100% `item_subtotal` khi giải ngân). |
| 27 | `disputes` | Dispute Core | `id (BIGSERIAL)` | Hồ sơ khiếu nại & tranh chấp đơn hàng (`OPEN`, `NEED_MORE_INFO`, `RESOLVED`) và phán quyết tài chính của Admin (`A-DP-02`). |
| 28 | `dispute_evidences` | Dispute Media | `id (BIGSERIAL)` | Hình ảnh bằng chứng của Buyer, giải trình đối chứng của Seller và yêu cầu bổ sung của Support Staff. |
| 29 | `reviews` | Trust & Rating | `id (BIGSERIAL)` | Đánh giá `1–5 sao` xác thực từ các đơn hàng đã `COMPLETED` (`M-RV-01`, `M-US-03`). |
| 30 | `reports` | Moderation | `id (BIGSERIAL)` | Báo cáo vi phạm cộng đồng (`PRODUCT`, `USER`, `CONVERSATION` – `M-CM-03`, `A-CM-01`). |

---

## Chương 3. Đặc Tả Chi Tiết Cấu Trúc Từng Bảng (`Detailed Table Specifications`)

### 3.1. Nhóm Giỏ Hàng & Đơn Hàng 4 Trạng Thái (`carts`, `cart_items`, `orders`, `order_items`, `shipments`)

#### Bảng 19 & 20: `carts` & `cart_items` (`M-CR-01` – `BF-04`)
- **`carts`:** `id (BIGSERIAL PK)`, `user_id (BIGINT NOT NULL UNIQUE FK -> users.id ON DELETE CASCADE)`, `created_at`, `updated_at`.
- **`cart_items`:** `id (BIGSERIAL PK)`, `cart_id (BIGINT NOT NULL FK -> carts.id ON DELETE CASCADE)`, `product_id (BIGINT NOT NULL FK -> products.id ON DELETE CASCADE)`, `seller_id (BIGINT NOT NULL FK -> users.id ON DELETE CASCADE)`, `quantity (INTEGER NOT NULL DEFAULT 1 CHECK (quantity >= 1))`, `is_selected (BOOLEAN NOT NULL DEFAULT TRUE)`, `created_at`, `updated_at`. Ràng buộc: `UNIQUE (cart_id, product_id)`.

#### Bảng 21: `orders` (Bảng Đơn Hàng Trung Tâm – `ADR-03`, `DEC-02..07`, `BR-OR-01..05`)

| Tên Cột (`Column`) | Kiểu Dữ Liệu (`Type`) | Ràng Buộc (`Constraints`) | Mặc Định (`Default`) | Mô Tả Chi Tiết & Quy Tắc Nghiệp Vụ |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Auto-increment | Khóa chính đơn hàng (Target của `SELECT ... FOR UPDATE`). |
| `order_code` | `VARCHAR(30)` | `NOT NULL, UNIQUE` | — | Mã đơn hàng hiển thị trên UI (ví dụ: `ORD-2026-0891`). |
| `buyer_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES users(id) ON DELETE RESTRICT` (Người mua). |
| `seller_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES users(id) ON DELETE RESTRICT` (Người bán – **1 Seller duy nhất trên mỗi đơn hàng** `BR-OR-01`; `CHECK (buyer_id <> seller_id)` `BR-AC-02`). |
| `order_source` | `VARCHAR(20)` | `NOT NULL, CHECK` | `'FIXED_PRICE'` | Nguồn tạo đơn: `CHECK (order_source IN ('FIXED_PRICE', 'AUCTION'))`. |
| `auction_id` | `BIGINT` | `NULLABLE, UNIQUE, FK` | `NULL` | `REFERENCES auctions(id) ON DELETE RESTRICT` (Liên kết `1:1` nếu là đơn thắng đấu giá `AF-07`). |
| `item_subtotal` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | — | Tổng tiền hàng gốc (`CHECK (item_subtotal > 0.00)`). |
| `shipping_fee` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | `0.00` | Phí vận chuyển trên ứng dụng (`CHECK (shipping_fee = 0.00)` – `DEC-04`). |
| `protection_fee_rate_applied` | `NUMERIC(5,4)` | `NOT NULL, CHECK` | `0.0600` | Tỷ lệ % Phí bảo vệ người mua áp dụng lúc đặt đơn (`0.0500` đến `0.0800`). |
| `protection_fixed_fee_applied` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | `7000.00` | Phí bảo vệ cố định áp dụng lúc đặt đơn (`5000.00` đến `10000.00`). |
| `buyer_protection_fee` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | — | **Phí bảo vệ người mua (`DEC-04`):** `ROUND(item_subtotal * rate) + fixed_fee` (`>= 0`). |
| `total_amount` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | — | **Tổng thanh toán của Buyer:** `CHECK (total_amount = item_subtotal + shipping_fee + buyer_protection_fee)`. |
| `seller_net_amount` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | — | **Số tiền Seller thực nhận (100% tiền hàng):** `CHECK (seller_net_amount = item_subtotal)`. |
| `shipping_address_snapshot` | `JSONB` | `NOT NULL` | — | Bản chụp địa chỉ người nhận lúc đặt đơn (`{recipient_name, recipient_phone, full_address}`). |
| `order_status` | `VARCHAR(25)` | `NOT NULL, CHECK` | `'PENDING_PAYMENT'` | **Trạng thái Đơn hàng (7 trạng thái):** `CHECK (order_status IN ('PENDING_PAYMENT', 'PAID', 'PREPARING', 'SHIPPED', 'DELIVERED', 'COMPLETED', 'CANCELLED', 'REFUNDED'))`. |
| `payment_status` | `VARCHAR(25)` | `NOT NULL, CHECK` | `'UNPAID'` | **Trạng thái Thanh toán:** `CHECK (payment_status IN ('UNPAID', 'PAID', 'FAILED', 'EXPIRED', 'REFUNDED'))`. |
| `escrow_status` | `VARCHAR(25)` | `NOT NULL, CHECK` | `'NONE'` | **Trạng thái Sổ cái Escrow:** `CHECK (escrow_status IN ('NONE', 'HELD', 'RELEASED', 'REFUNDED', 'PARTIALLY_REFUNDED'))`. |
| `dispute_status` | `VARCHAR(25)` | `NOT NULL, CHECK` | `'NONE'` | **Trạng thái Khiếu nại:** `CHECK (dispute_status IN ('NONE', 'OPEN', 'NEED_MORE_INFO', 'RESOLVED'))`. |
| `cancellation_requested` | `BOOLEAN` | `NOT NULL` | `FALSE` | Đánh dấu `TRUE` khi Buyer gửi yêu cầu xin hủy lúc đơn đang ở `PREPARING` (`DEC-06`). |
| `cancellation_request_reason` | `TEXT` | `NULLABLE` | `NULL` | Lý do Buyer xin hủy đơn ở `PREPARING`. |
| `cancelled_by_role` | `VARCHAR(20)` | `NULLABLE` | `NULL` | `'BUYER'`, `'SELLER'`, `'SYSTEM'`, `'ADMIN'`. |
| `cancel_reason` | `TEXT` | `NULLABLE` | `NULL` | Lý do hủy đơn chính thức. |
| `payment_expires_at` | `TIMESTAMPTZ` | `NOT NULL` | — | Hạn chót thanh toán QR (30 phút cho đơn thắng đấu giá, 2 phút ở Demo Mode – `BR-AU-07`). |
| `paid_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời điểm thanh toán QR thành công & giữ tiền `ESCROW_HELD`. |
| `preparing_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời điểm Seller bấm xác nhận chuẩn bị hàng. |
| `shipped_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời điểm Seller nhập mã vận đơn chuyển sang `SHIPPED`. |
| `delivered_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời điểm cập nhật `DELIVERED`. |
| `auto_complete_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | **Mốc thời gian đóng băng (`BR-OR-05`):** Tính cố định một lần tại thời điểm `delivered_at` (`+24h` Production / `+2m` Demo Mode) phục vụ Job tự động hoàn tất. |
| `escrow_frozen_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời điểm khóa giải ngân do phát sinh Khiếu nại (`BR-DP-02`). |
| `completed_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời điểm đơn hàng hoàn tất & giải ngân. |
| `cancelled_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời điểm đơn hàng bị hủy. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm tạo đơn. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm cập nhật gần nhất. |

#### Bảng 22: `order_items` (Bản Chụp Sản Phẩm Bất Biến – `BR-OR-02`)
- **Cột:** `id (BIGSERIAL PK)`, `order_id (BIGINT NOT NULL FK -> orders.id ON DELETE CASCADE)`, `product_id (BIGINT NOT NULL FK -> products.id ON DELETE RESTRICT)`, `product_code_snapshot (VARCHAR(30) NOT NULL)`, `product_title_snapshot (VARCHAR(150) NOT NULL)`, `condition_snapshot (VARCHAR(25) NOT NULL)`, `defect_info_snapshot (TEXT NOT NULL)`, `primary_image_snapshot (VARCHAR(500) NOT NULL)`, `unit_price_snapshot (NUMERIC(15,2) NOT NULL CHECK (unit_price_snapshot > 0))`, `quantity (INTEGER NOT NULL DEFAULT 1 CHECK (quantity >= 1))`, `line_total (NUMERIC(15,2) NOT NULL CHECK (line_total = unit_price_snapshot * quantity))`, `created_at`.

#### Bảng 23: `shipments` (Vận Đơn & Theo Dõi Giao Hàng Thủ Công – `M-SL-07`, `SF-10`)
- **Cột:** `id (BIGSERIAL PK)`, `order_id (BIGINT NOT NULL UNIQUE FK -> orders.id ON DELETE CASCADE)`, `carrier_name (VARCHAR(80) NOT NULL)` (GHN, GHTK, Viettel Post...), `tracking_code (VARCHAR(80) NOT NULL)`, `shipping_note (TEXT NULLABLE)`, `status (VARCHAR(25) NOT NULL DEFAULT 'SHIPPED' CHECK (status IN ('SHIPPED', 'DELIVERED')))`, `shipped_at (TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP)`, `delivered_at (TIMESTAMPTZ NULLABLE)`, `updated_by (BIGINT NOT NULL FK -> users.id)`, `created_at`, `updated_at`.

---

### 3.2. Nhóm Thanh Toán QR Mô Phỏng & Sổ Cái Bất Biến (`payments`, `escrow_transactions`, `wallet_transactions`)

#### Bảng 24: `payments` (Phiên Thanh Toán QR Mô Phỏng – `M-PM-01`, `A-PM-01`)
- **Cột:** `id (BIGSERIAL PK)`, `payment_reference (VARCHAR(50) NOT NULL UNIQUE)`, `order_id (BIGINT NOT NULL FK -> orders.id ON DELETE RESTRICT)`, `payer_id (BIGINT NOT NULL FK -> users.id ON DELETE RESTRICT)`, `amount (NUMERIC(15,2) NOT NULL CHECK (amount > 0))`, `qr_payload (TEXT NOT NULL)`, `status (VARCHAR(25) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'EXPIRED')))`, `failure_reason (VARCHAR(255) NULLABLE)`, `expires_at (TIMESTAMPTZ NOT NULL)`, `paid_at (TIMESTAMPTZ NULLABLE)`, `created_at`, `updated_at`.
- **Partial Unique Index chống Double-Payment (`BR-FN-03`):**
  `CREATE UNIQUE INDEX uq_payments_one_paid_per_order ON payments(order_id) WHERE status = 'PAID';`

#### Bảng 25: `escrow_transactions` (Sổ Cái Giữ Tiền, Giải Ngân & Hoàn Tiền Bất Biến – `BR-FN-04..07`, `DEC-04`, `DEC-07`)

| Tên Cột (`Column`) | Kiểu Dữ Liệu (`Type`) | Ràng Buộc (`Constraints`) | Mặc Định (`Default`) | Mô Tả Chi Tiết & Quy Tắc Cân Bằng Kế Toán |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Auto-increment | Khóa chính bút toán sổ cái Escrow (Append-Only). |
| `transaction_code` | `VARCHAR(40)` | `NOT NULL, UNIQUE` | — | Mã bút toán (ví dụ: `ETX-2026-0104`). |
| `order_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES orders(id) ON DELETE RESTRICT`. |
| `payment_id` | `BIGINT` | `NULLABLE, FK` | `NULL` | `REFERENCES payments(id) ON DELETE RESTRICT`. |
| `buyer_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES users(id) ON DELETE RESTRICT`. |
| `seller_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES users(id) ON DELETE RESTRICT`. |
| `transaction_type` | `VARCHAR(30)` | `NOT NULL, CHECK` | — | `CHECK (transaction_type IN ('HOLD', 'RELEASE', 'FULL_REFUND', 'PARTIAL_REFUND'))`. |
| `gross_amount` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | — | Tổng số tiền giao dịch (`= orders.total_amount`, `> 0`). |
| `item_subtotal_amount` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | — | Phần tiền hàng gốc (`= orders.item_subtotal`, `> 0`). |
| `buyer_protection_fee_amount` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | — | Phần phí bảo vệ người mua (`= orders.buyer_protection_fee`, `>= 0`). |
| `seller_released_amount` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | `0.00` | Số tiền giải ngân vào Ví Seller (`= item_subtotal` khi `RELEASE`; `= item_subtotal - buyer_refunded_amount` khi `PARTIAL_REFUND`; `= 0` khi `HOLD` hoặc `FULL_REFUND`). |
| `buyer_refunded_amount` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | `0.00` | Số tiền hoàn trả cho Buyer (`= gross_amount (100% total_amount)` khi `FULL_REFUND` theo `DEC-07`; `= X` khi `PARTIAL_REFUND` theo `BR-FN-06`; `= 0` khi `HOLD` hoặc `RELEASE`). |
| `platform_fee_retained` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | `0.00` | Số tiền phí bảo vệ nền tảng giữ lại (`= buyer_protection_fee_amount` khi `RELEASE` hoặc `PARTIAL_REFUND`; `= 0` khi `FULL_REFUND`). |
| `triggered_by_user_id` | `BIGINT` | `NULLABLE, FK` | `NULL` | `REFERENCES users(id) ON DELETE SET NULL` (`NULL` nếu do Scheduled Job tự động). |
| `note` | `TEXT` | `NOT NULL` | — | Diễn giải bút toán kế toán. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm ghi sổ vĩnh viễn. |

#### Bảng 26: `wallet_transactions` (Sổ Cái Biến Động Ví Người Bán – `M-SL-08`, `A-ES-01`)
- **Cột:** `id (BIGSERIAL PK)`, `wallet_tx_code (VARCHAR(40) NOT NULL UNIQUE)`, `seller_id (BIGINT NOT NULL FK -> users.id ON DELETE RESTRICT)`, `order_id (BIGINT NOT NULL UNIQUE FK -> orders.id ON DELETE RESTRICT)` *(Đảm bảo 1 đơn hàng chỉ được cộng tiền vào Ví Seller tối đa 1 lần duy nhất)*, `escrow_transaction_id (BIGINT NOT NULL UNIQUE FK -> escrow_transactions.id ON DELETE RESTRICT)`, `entry_type (VARCHAR(20) NOT NULL DEFAULT 'CREDIT' CHECK (entry_type IN ('CREDIT')))`, `amount (NUMERIC(15,2) NOT NULL CHECK (amount > 0))`, `balance_before (NUMERIC(15,2) NOT NULL CHECK (balance_before >= 0))`, `balance_after (NUMERIC(15,2) NOT NULL CHECK (balance_after = balance_before + amount))`, `description (VARCHAR(255) NOT NULL)`, `created_at (TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP)`.

---

### 3.3. Nhóm Khiếu Nại, Đánh Giá Xác Thực & Báo Cáo Vi Phạm (`disputes`, `dispute_evidences`, `reviews`, `reports`)

#### Bảng 27: `disputes` (Hồ Sơ Khiếu Nại & Phán Quyết Tài Chính – `M-DP-01..03`, `A-DP-01..02`, `DEC-03`, `DEC-07`)

| Tên Cột (`Column`) | Kiểu Dữ Liệu (`Type`) | Ràng Buộc (`Constraints`) | Mặc Định (`Default`) | Mô Tả Chi Tiết & Quy Tắc Nghiệp Vụ |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Auto-increment | Khóa chính hồ sơ khiếu nại. |
| `dispute_code` | `VARCHAR(30)` | `NOT NULL, UNIQUE` | — | Mã khiếu nại (ví dụ: `DSP-2026-0042`). |
| `order_id` | `BIGINT` | `NOT NULL, UNIQUE, FK` | — | `REFERENCES orders(id) ON DELETE RESTRICT` (Mỗi đơn hàng tối đa 1 hồ sơ tranh chấp). |
| `buyer_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES users(id) ON DELETE RESTRICT`. |
| `seller_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES users(id) ON DELETE RESTRICT`. |
| `opened_at_order_status` | `VARCHAR(25)` | `NOT NULL, CHECK` | — | **Trạng thái đơn lúc mở khiếu nại (`DEC-03`):** `CHECK (opened_at_order_status IN ('SHIPPED', 'DELIVERED'))`. |
| `reason_category` | `VARCHAR(50)` | `NOT NULL` | — | Nhóm lý do (*Hàng rách/sai mô tả*, *Không nhận được hàng*, *Sai kích cỡ/thương hiệu*). |
| `buyer_description` | `TEXT` | `NOT NULL` | — | Mô tả chi tiết khiếu nại từ Buyer. |
| `seller_response` | `TEXT` | `NULLABLE` | `NULL` | Giải trình đối chứng từ Seller (`SF-11`). |
| `assigned_support_id` | `BIGINT` | `NULLABLE, FK` | `NULL` | `REFERENCES users(id) ON DELETE SET NULL` (Support Staff được phân công thu thập bằng chứng `PERM-CM-08`). |
| `status` | `VARCHAR(25)` | `NOT NULL, CHECK` | `'OPEN'` | `CHECK (status IN ('OPEN', 'NEED_MORE_INFO', 'RESOLVED'))`. |
| `admin_verdict` | `VARCHAR(30)` | `NULLABLE, CHECK` | `NULL` | **3 Phán quyết tài chính của Admin (`DEC-07`, `BR-FN-06`):** `CHECK (admin_verdict IS NULL OR admin_verdict IN ('APPROVE_BUYER_REFUND', 'RELEASE_TO_SELLER', 'PARTIAL_REFUND'))`. |
| `partial_refund_to_buyer` | `NUMERIC(15,2)` | `NULLABLE, CHECK` | `NULL` | Số tiền hoàn một phần cho Buyer (Chỉ có giá trị `> 0` khi `admin_verdict = 'PARTIAL_REFUND'`). |
| `resolution_note` | `TEXT` | `NULLABLE` | `NULL` | Ghi chú phán quyết bắt buộc của Administrator (`A-DP-02`). |
| `resolved_by_admin_id` | `BIGINT` | `NULLABLE, FK` | `NULL` | `REFERENCES users(id) ON DELETE SET NULL` (Chỉ Administrator mới có quyền ghi cột này – `PERM-CM-09`). |
| `resolved_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời điểm hoàn tất phán quyết. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm mở khiếu nại & khóa giải ngân. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm cập nhật. |

#### Bảng 28: `dispute_evidences` (Bằng Chứng Hình Ảnh & Yêu Cầu Bổ Sung – `M-DP-03`, `A-DP-02`)
- **Cột:** `id (BIGSERIAL PK)`, `dispute_id (BIGINT NOT NULL FK -> disputes.id ON DELETE CASCADE)`, `uploader_id (BIGINT NOT NULL FK -> users.id)`, `uploader_role (VARCHAR(25) NOT NULL CHECK (uploader_role IN ('BUYER', 'SELLER', 'SUPPORT', 'ADMIN')))`, `evidence_type (VARCHAR(30) NOT NULL CHECK (evidence_type IN ('BUYER_PROOF', 'SELLER_COUNTER_PROOF', 'STAFF_REQUEST_NOTE')))`, `file_url (VARCHAR(500) NULLABLE)`, `message_note (TEXT NULLABLE)`, `created_at (TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP)`.

#### Bảng 29: `reviews` (Đánh Giá 1–5 Sao Xác Thực Từ Đơn Hoàn Tất – `M-RV-01`, `M-US-03`, `BR-RV-01`)
- **Cột:** `id (BIGSERIAL PK)`, `order_id (BIGINT NOT NULL UNIQUE FK -> orders.id ON DELETE RESTRICT)`, `product_id (BIGINT NOT NULL FK -> products.id ON DELETE RESTRICT)`, `reviewer_id (BIGINT NOT NULL FK -> users.id ON DELETE RESTRICT)`, `seller_id (BIGINT NOT NULL FK -> users.id ON DELETE RESTRICT)`, `rating (SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5))`, `comment (TEXT NOT NULL CHECK (LENGTH(TRIM(comment)) > 0))`, `status (VARCHAR(20) NOT NULL DEFAULT 'VISIBLE' CHECK (status IN ('VISIBLE', 'HIDDEN')))`, `hidden_reason (TEXT NULLABLE)`, `hidden_by (BIGINT NULLABLE FK -> users.id)`, `created_at`, `updated_at`.
- **Ràng buộc:** `CHECK (reviewer_id <> seller_id)`.

#### Bảng 30: `reports` (Báo Cáo Vi Phạm Cộng Đồng – `M-CM-03`, `A-CM-01`)
- **Cột:** `id (BIGSERIAL PK)`, `reporter_id (BIGINT NOT NULL FK -> users.id ON DELETE CASCADE)`, `target_type (VARCHAR(25) NOT NULL CHECK (target_type IN ('PRODUCT', 'USER', 'CONVERSATION')))`, `target_id (BIGINT NOT NULL)`, `reason_category (VARCHAR(60) NOT NULL)`, `description (TEXT NOT NULL)`, `status (VARCHAR(25) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'RESOLVED_ACTION_TAKEN', 'DISMISSED')))`, `resolution_note (TEXT NULLABLE)`, `handled_by (BIGINT NULLABLE FK -> users.id)`, `handled_at (TIMESTAMPTZ NULLABLE)`, `created_at`, `updated_at`.

---

## Chương 4. Mã Lệnh Khởi Tạo SQL Chuẩn PostgreSQL 18 (`Complete SQL DDL Script – DB_03`)

```sql
-- ============================================================================
-- RETRO MARKET (izithrift) - DB_03: ORDER, PAYMENT, ESCROW LEDGER & DISPUTES
-- Target DBMS: PostgreSQL 18.x | Financial Precision: NUMERIC(15,2)
-- ============================================================================

-- 19. CARTS (1:1 with users)
CREATE TABLE carts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 20. CART ITEMS (Grouped by Seller on UI - BR-OR-01)
CREATE TABLE cart_items (
    id BIGSERIAL PRIMARY KEY,
    cart_id BIGINT NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    seller_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1
        CONSTRAINT chk_cart_items_qty CHECK (quantity >= 1),
    is_selected BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cart_items_product UNIQUE (cart_id, product_id)
);

CREATE INDEX idx_cart_items_cart_seller ON cart_items(cart_id, seller_id);

-- 21. ORDERS (4 Independent State Lifecycles & Buyer Protection Fee - ADR-03 & DEC-04)
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    order_code VARCHAR(30) NOT NULL UNIQUE,
    buyer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    seller_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    order_source VARCHAR(20) NOT NULL DEFAULT 'FIXED_PRICE'
        CONSTRAINT chk_orders_source CHECK (order_source IN ('FIXED_PRICE', 'AUCTION')),
    auction_id BIGINT NULL UNIQUE REFERENCES auctions(id) ON DELETE RESTRICT,
    item_subtotal NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_orders_subtotal_pos CHECK (item_subtotal > 0.00),
    shipping_fee NUMERIC(15, 2) NOT NULL DEFAULT 0.00
        CONSTRAINT chk_orders_shipping_zero CHECK (shipping_fee = 0.00),
    protection_fee_rate_applied NUMERIC(5, 4) NOT NULL DEFAULT 0.0600
        CONSTRAINT chk_orders_fee_rate CHECK (protection_fee_rate_applied >= 0.0000 AND protection_fee_rate_applied <= 0.2000),
    protection_fixed_fee_applied NUMERIC(15, 2) NOT NULL DEFAULT 7000.00
        CONSTRAINT chk_orders_fixed_fee CHECK (protection_fixed_fee_applied >= 0.00),
    buyer_protection_fee NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_orders_protection_fee_non_neg CHECK (buyer_protection_fee >= 0.00),
    total_amount NUMERIC(15, 2) NOT NULL,
    seller_net_amount NUMERIC(15, 2) NOT NULL,
    shipping_address_snapshot JSONB NOT NULL,
    order_status VARCHAR(25) NOT NULL DEFAULT 'PENDING_PAYMENT'
        CONSTRAINT chk_orders_order_status CHECK (
            order_status IN ('PENDING_PAYMENT', 'PAID', 'PREPARING', 'SHIPPED', 'DELIVERED', 'COMPLETED', 'CANCELLED', 'REFUNDED')
        ),
    payment_status VARCHAR(25) NOT NULL DEFAULT 'UNPAID'
        CONSTRAINT chk_orders_payment_status CHECK (
            payment_status IN ('UNPAID', 'PAID', 'FAILED', 'EXPIRED', 'REFUNDED')
        ),
    escrow_status VARCHAR(25) NOT NULL DEFAULT 'NONE'
        CONSTRAINT chk_orders_escrow_status CHECK (
            escrow_status IN ('NONE', 'HELD', 'RELEASED', 'REFUNDED', 'PARTIALLY_REFUNDED')
        ),
    dispute_status VARCHAR(25) NOT NULL DEFAULT 'NONE'
        CONSTRAINT chk_orders_dispute_status CHECK (
            dispute_status IN ('NONE', 'OPEN', 'NEED_MORE_INFO', 'RESOLVED')
        ),
    cancellation_requested BOOLEAN NOT NULL DEFAULT FALSE,
    cancellation_request_reason TEXT NULL,
    cancelled_by_role VARCHAR(20) NULL,
    cancel_reason TEXT NULL,
    payment_expires_at TIMESTAMPTZ NOT NULL,
    paid_at TIMESTAMPTZ NULL,
    preparing_at TIMESTAMPTZ NULL,
    shipped_at TIMESTAMPTZ NULL,
    delivered_at TIMESTAMPTZ NULL,
    auto_complete_at TIMESTAMPTZ NULL,
    escrow_frozen_at TIMESTAMPTZ NULL,
    completed_at TIMESTAMPTZ NULL,
    cancelled_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Enforce BR-AC-02: Buyer cannot buy from themselves
    CONSTRAINT chk_orders_no_self_purchase CHECK (buyer_id <> seller_id),
    -- Enforce DEC-04 & BR-FN-02: Financial Equation Invariants
    CONSTRAINT chk_orders_total_equation CHECK (total_amount = item_subtotal + shipping_fee + buyer_protection_fee),
    CONSTRAINT chk_orders_seller_net_100_percent CHECK (seller_net_amount = item_subtotal)
);

CREATE INDEX idx_orders_buyer_status ON orders(buyer_id, order_status, created_at DESC);
CREATE INDEX idx_orders_seller_status ON orders(seller_id, order_status, created_at DESC);
CREATE INDEX idx_orders_unpaid_expiry ON orders(order_status, payment_status, payment_expires_at ASC)
    WHERE order_status = 'PENDING_PAYMENT';
CREATE INDEX idx_orders_auto_complete ON orders(order_status, dispute_status, auto_complete_at ASC)
    WHERE order_status = 'DELIVERED' AND dispute_status = 'NONE';

-- 22. ORDER ITEMS (Immutable Snapshot at Order Creation - BR-OR-02)
CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    product_code_snapshot VARCHAR(30) NOT NULL,
    product_title_snapshot VARCHAR(150) NOT NULL,
    condition_snapshot VARCHAR(25) NOT NULL,
    defect_info_snapshot TEXT NOT NULL,
    primary_image_snapshot VARCHAR(500) NOT NULL,
    unit_price_snapshot NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_order_items_price_pos CHECK (unit_price_snapshot > 0.00),
    quantity INTEGER NOT NULL DEFAULT 1
        CONSTRAINT chk_order_items_qty_pos CHECK (quantity >= 1),
    line_total NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_order_items_line_total CHECK (line_total = unit_price_snapshot * quantity)
);

CREATE INDEX idx_order_items_order ON order_items(order_id);

-- 23. SHIPMENTS (Manual Tracking & Delivery Timestamps - M-SL-07)
CREATE TABLE shipments (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    carrier_name VARCHAR(80) NOT NULL,
    tracking_code VARCHAR(80) NOT NULL,
    shipping_note TEXT NULL,
    status VARCHAR(25) NOT NULL DEFAULT 'SHIPPED'
        CONSTRAINT chk_shipments_status CHECK (status IN ('SHIPPED', 'DELIVERED')),
    shipped_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMPTZ NULL,
    updated_by BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 24. PAYMENTS (Mock QR Payment Sessions - BR-FN-03)
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    payment_reference VARCHAR(50) NOT NULL UNIQUE,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    payer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    amount NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_payments_amount_pos CHECK (amount > 0.00),
    qr_payload TEXT NOT NULL,
    status VARCHAR(25) NOT NULL DEFAULT 'PENDING'
        CONSTRAINT chk_payments_status CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'EXPIRED')),
    failure_reason VARCHAR(255) NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    paid_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Prevent Double-Payment on the same Order
CREATE UNIQUE INDEX uq_payments_one_paid_per_order
    ON payments(order_id)
    WHERE status = 'PAID';

-- 25. ESCROW TRANSACTIONS (Immutable Append-Only Escrow Ledger - BR-FN-04..07 & DEC-07)
CREATE TABLE escrow_transactions (
    id BIGSERIAL PRIMARY KEY,
    transaction_code VARCHAR(40) NOT NULL UNIQUE,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    payment_id BIGINT NULL REFERENCES payments(id) ON DELETE RESTRICT,
    buyer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    seller_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    transaction_type VARCHAR(30) NOT NULL
        CONSTRAINT chk_escrow_tx_type CHECK (
            transaction_type IN ('HOLD', 'RELEASE', 'FULL_REFUND', 'PARTIAL_REFUND')
        ),
    gross_amount NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_escrow_gross_pos CHECK (gross_amount > 0.00),
    item_subtotal_amount NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_escrow_subtotal_pos CHECK (item_subtotal_amount > 0.00),
    buyer_protection_fee_amount NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_escrow_fee_non_neg CHECK (buyer_protection_fee_amount >= 0.00),
    seller_released_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00
        CONSTRAINT chk_escrow_seller_rel_non_neg CHECK (seller_released_amount >= 0.00),
    buyer_refunded_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00
        CONSTRAINT chk_escrow_buyer_ref_non_neg CHECK (buyer_refunded_amount >= 0.00),
    platform_fee_retained NUMERIC(15, 2) NOT NULL DEFAULT 0.00
        CONSTRAINT chk_escrow_plat_fee_non_neg CHECK (platform_fee_retained >= 0.00),
    triggered_by_user_id BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    note TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Ledger Balance Invariant per Transaction Type (DEC-04, DEC-07, BR-FN-06)
    CONSTRAINT chk_escrow_accounting_balance CHECK (
        (transaction_type = 'HOLD' AND seller_released_amount = 0.00 AND buyer_refunded_amount = 0.00 AND platform_fee_retained = 0.00) OR
        (transaction_type = 'RELEASE' AND seller_released_amount = item_subtotal_amount AND buyer_refunded_amount = 0.00 AND platform_fee_retained = buyer_protection_fee_amount) OR
        (transaction_type = 'FULL_REFUND' AND buyer_refunded_amount = gross_amount AND seller_released_amount = 0.00 AND platform_fee_retained = 0.00) OR
        (transaction_type = 'PARTIAL_REFUND' AND buyer_refunded_amount > 0.00 AND seller_released_amount > 0.00 AND (buyer_refunded_amount + seller_released_amount = item_subtotal_amount) AND platform_fee_retained = buyer_protection_fee_amount)
    )
);

CREATE INDEX idx_escrow_tx_order ON escrow_transactions(order_id, created_at ASC);

-- 26. WALLET TRANSACTIONS (Immutable Seller Wallet Ledger - M-SL-08)
CREATE TABLE wallet_transactions (
    id BIGSERIAL PRIMARY KEY,
    wallet_tx_code VARCHAR(40) NOT NULL UNIQUE,
    seller_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    order_id BIGINT NOT NULL UNIQUE REFERENCES orders(id) ON DELETE RESTRICT,
    escrow_transaction_id BIGINT NOT NULL UNIQUE REFERENCES escrow_transactions(id) ON DELETE RESTRICT,
    entry_type VARCHAR(20) NOT NULL DEFAULT 'CREDIT'
        CONSTRAINT chk_wallet_tx_entry_type CHECK (entry_type IN ('CREDIT')),
    amount NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_wallet_tx_amount_pos CHECK (amount > 0.00),
    balance_before NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_wallet_tx_bal_before CHECK (balance_before >= 0.00),
    balance_after NUMERIC(15, 2) NOT NULL,
    description VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_wallet_tx_balance_math CHECK (balance_after = balance_before + amount)
);

CREATE INDEX idx_wallet_tx_seller_time ON wallet_transactions(seller_id, created_at DESC);

-- 27. DISPUTES (Order Complaint & Financial Verdict - DEC-03 & DEC-07)
CREATE TABLE disputes (
    id BIGSERIAL PRIMARY KEY,
    dispute_code VARCHAR(30) NOT NULL UNIQUE,
    order_id BIGINT NOT NULL UNIQUE REFERENCES orders(id) ON DELETE RESTRICT,
    buyer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    seller_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    opened_at_order_status VARCHAR(25) NOT NULL
        CONSTRAINT chk_disputes_opened_status CHECK (opened_at_order_status IN ('SHIPPED', 'DELIVERED')),
    reason_category VARCHAR(50) NOT NULL,
    buyer_description TEXT NOT NULL,
    seller_response TEXT NULL,
    assigned_support_id BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(25) NOT NULL DEFAULT 'OPEN'
        CONSTRAINT chk_disputes_status CHECK (status IN ('OPEN', 'NEED_MORE_INFO', 'RESOLVED')),
    admin_verdict VARCHAR(30) NULL
        CONSTRAINT chk_disputes_verdict CHECK (
            admin_verdict IS NULL OR admin_verdict IN ('APPROVE_BUYER_REFUND', 'RELEASE_TO_SELLER', 'PARTIAL_REFUND')
        ),
    partial_refund_to_buyer NUMERIC(15, 2) NULL
        CONSTRAINT chk_disputes_partial_amount CHECK (partial_refund_to_buyer IS NULL OR partial_refund_to_buyer > 0.00),
    resolution_note TEXT NULL,
    resolved_by_admin_id BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    resolved_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_disputes_status_assigned ON disputes(status, assigned_support_id, created_at DESC);

-- 28. DISPUTE EVIDENCES
CREATE TABLE dispute_evidences (
    id BIGSERIAL PRIMARY KEY,
    dispute_id BIGINT NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,
    uploader_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    uploader_role VARCHAR(25) NOT NULL
        CONSTRAINT chk_dispute_ev_role CHECK (uploader_role IN ('BUYER', 'SELLER', 'SUPPORT', 'ADMIN')),
    evidence_type VARCHAR(30) NOT NULL
        CONSTRAINT chk_dispute_ev_type CHECK (evidence_type IN ('BUYER_PROOF', 'SELLER_COUNTER_PROOF', 'STAFF_REQUEST_NOTE')),
    file_url VARCHAR(500) NULL,
    message_note TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 29. REVIEWS (Verified Completed-Order Seller Reviews - BR-RV-01)
CREATE TABLE reviews (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL UNIQUE REFERENCES orders(id) ON DELETE RESTRICT,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    reviewer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    seller_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    rating SMALLINT NOT NULL
        CONSTRAINT chk_reviews_rating_range CHECK (rating >= 1 AND rating <= 5),
    comment TEXT NOT NULL
        CONSTRAINT chk_reviews_comment_not_empty CHECK (LENGTH(TRIM(comment)) > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'VISIBLE'
        CONSTRAINT chk_reviews_status CHECK (status IN ('VISIBLE', 'HIDDEN')),
    hidden_reason TEXT NULL,
    hidden_by BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_reviews_no_self_review CHECK (reviewer_id <> seller_id)
);

CREATE INDEX idx_reviews_seller_visible ON reviews(seller_id, status, created_at DESC);

-- 30. VIOLATION REPORTS (M-CM-03 & A-CM-01)
CREATE TABLE reports (
    id BIGSERIAL PRIMARY KEY,
    reporter_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(25) NOT NULL
        CONSTRAINT chk_reports_target_type CHECK (target_type IN ('PRODUCT', 'USER', 'CONVERSATION')),
    target_id BIGINT NOT NULL,
    reason_category VARCHAR(60) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(25) NOT NULL DEFAULT 'PENDING'
        CONSTRAINT chk_reports_status CHECK (status IN ('PENDING', 'RESOLVED_ACTION_TAKEN', 'DISMISSED')),
    resolution_note TEXT NULL,
    handled_by BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    handled_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reports_status_type ON reports(status, target_type, created_at DESC);
```