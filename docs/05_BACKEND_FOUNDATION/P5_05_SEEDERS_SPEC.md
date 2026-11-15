# 05. FACTORIES & IDEMPOTENT SEEDERS SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P505-SEEDERS-SPEC`
- **Version:** `1.0.0`
- **Status:** `DONE / APPROVED`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 05 – Backend Foundation & Database Implementation (Task P5-05)`
- **Compliance Ref:** `03_ACTOR_PERMISSION_MATRIX.md`, `DEC-01..07`, `BR-AC-01..04`, `BR-PR-01..05`, `BR-AU-01..07`, `BR-OR-01..05`, `BR-FN-01..07`

---

## Chương 1. Nguyên Tắc Thiết Kế Dữ Liệu Mẫu Có Chủ Đích & Lũy Đẳng (`Idempotent & Deterministic Seeding Principles`)

1. **Tính Lũy Đẳng Tuyệt Đối (`100% Idempotency`):**
   - Mọi bản ghi trong 6 Seeders đều được định danh bằng khóa tự nhiên duy nhất (`email`, `slug`, `product_code`, `session_code`, `auction_code`, `order_code`, `payment_reference`, `transaction_code`, `wallet_tx_code`, `dispute_code`).
   - Sử dụng `updateOrCreate()` / `firstOrCreate()` để việc chạy `php artisan db:seed` lần thứ 2, thứ 3 không bao giờ tạo dữ liệu rác hoặc vi phạm ràng buộc `ImmutableLedgerRecord` (`P5-04`).
2. **Tuân Thủ Nghiêm Ngặt Các Ràng Buộc PostgreSQL 18 (`P5-03 Compliance`):**
   - Toàn bộ các đơn hàng mẫu đều được tính toán chính xác theo công thức **`DEC-04`**:
     - `shipping_fee = 0.00`
     - `buyer_protection_fee = ROUND(item_subtotal * 0.06) + 7000`
     - `total_amount = item_subtotal + buyer_protection_fee`
     - `seller_net_amount = item_subtotal`
   - Đối soát tự động số dư Ví (`wallet_balance`) và số dư Escrow đang giữ (`escrow_held_balance`) của từng `SellerProfile` sau khi nạp xong các đơn hàng để khớp toán học 100% với `escrow_transactions` và `wallet_transactions`.

---

## Chương 2. Cấu Trúc 6 Seeders Chuyên Biệt (`6 Modular Seeders Architecture`)

`DatabaseSeeder.php` gọi tuần tự 6 Seeders theo đúng thứ tự phụ thuộc khóa ngoại:

| Thứ Tự | Tên Class Seeder (`backend/database/seeders/`) | Các Bảng Được Khởi Tạo Dữ Liệu |
| :---: | :--- | :--- |
| **01** | `PlatformAndUsersSeeder` | `platform_settings`, `users`, `user_profiles`, `seller_profiles`, `user_addresses`, `carts` |
| **02** | `CatalogAndProductsSeeder` | `categories`, `brands`, `products`, `product_images`, `product_moderation_logs` |
| **03** | `ScheduledAuctionsSeeder` | `auction_sessions`, `auctions`, `auction_bids`, `auction_watches` |
| **04** | `OrdersPaymentsAndEscrowSeeder` | `cart_items`, `orders`, `order_items`, `shipments`, `payments`, `escrow_transactions`, `wallet_transactions` |
| **05** | `DisputesAndReviewsSeeder` | `disputes`, `dispute_evidences`, `reviews`, `reports` |
| **06** | `EngagementChatAndAuditSeeder` | `favorites`, `seller_follows`, `conversations`, `messages`, `notifications`, `audit_logs` |

---

## Chương 3. Đặc Tả Chi Tiết Dữ Liệu Mẫu Theo Từng Phân Hệ Nghiệp Vụ (`Detailed Scenario Matrix`)

### 3.1. Seeder 1 (`PlatformAndUsersSeeder`): Danh Bạ 10 Tài Khoản Chuẩn Hóa
*(Mật khẩu mặc định chung cho toàn bộ tài khoản phục vụ kiểm thử & trình diễn: **`Retro@2026`**)*

| STT | Email Đăng Nhập | `display_name` | `role` | `status` | Vai Trò & Ngữ Cảnh Kiểm Thử Trong Dự Án |
| :-: | :--- | :--- | :---: | :---: | :--- |
| 01 | `admin@izithrift.local` | Quản Trị Viên Tối Cao | `admin` | `ACTIVE` | Toàn quyền hệ thống, duyệt giải ngân/hoàn tiền tranh chấp (`PERM-CM-09`), dùng Developer Tools (`A-DT-01`). |
| 02 | `moderator@izithrift.local` | Kiểm Duyệt Viên Minh Anh | `moderator` | `ACTIVE` | Duyệt/Từ chối sản phẩm (`A-MD-02`), xử lý báo cáo vi phạm (`A-CM-01`). |
| 03 | `support@izithrift.local` | Hỗ Trợ Viên Hoàng Nam | `support` | `ACTIVE` | Tiếp nhận khiếu nại, yêu cầu bổ sung bằng chứng (`A-DP-02`), không có quyền bấm giải ngân (`PERM-CM-08`). |
| 04 | `gau.vintage@izithrift.local` | Tiệm Đồ Si Nhà Gấu | `registered_user` | `ACTIVE` | **Chủ tiệm nổi bật #1 (`Seller A`)**: Chuyên áo khoác dạ Tweed, đồng hồ Casio cổ điển, túi da. |
| 05 | `retrolab.sg@izithrift.local` | Sài Gòn Retro Lab | `registered_user` | `ACTIVE` | **Chủ tiệm nổi bật #2 (`Seller B`)**: Chuyên máy ảnh film, đĩa than, phụ kiện thập niên 90s. |
| 06 | `tiemnhamay@izithrift.local` | Tiệm Nhỏ Trên Mây | `registered_user` | `ACTIVE` | **Chủ tiệm #3 (`Seller C`)**: Chuyên chân váy Midi, cardigan len, phụ kiện mùa Giáng sinh. |
| 07 | `buyer.linh@izithrift.local` | Nguyễn Ngọc Linh | `registered_user` | `ACTIVE` | **Người mua tích cực #1 (`Buyer 1`)**: Tham gia đặt giá thầu, mua hàng Fixed-Price, xác nhận nhận hàng & đánh giá. |
| 08 | `buyer.kiet@izithrift.local` | Trần Tuấn Kiệt | `registered_user` | `ACTIVE` | **Người mua tích cực #2 (`Buyer 2`)**: Cạnh tranh trả giá đấu giá, mở khiếu nại đơn hàng. |
| 09 | `buyer.ha@izithrift.local` | Lê Thanh Hà | `registered_user` | `ACTIVE` | **Người mua #3 (`Buyer 3`)**: Có lịch sử thắng đấu giá nhưng để quá hạn 30 phút (`auction_default_count = 1` – `DEC-02`). |
| 10 | `suspended.user@izithrift.local` | Tài Khoản Đang Tạm Khóa | `registered_user` | `SUSPENDED` | Kiểm thử chặn đăng nhập & thu hồi token tự động (`BR-AC-04`). |

---

### 3.2. Seeder 2 (`CatalogAndProductsSeeder`): Danh Mục, Thương Hiệu & 16 Sản Phẩm Đủ 7 Trạng Thái
- **Danh mục (`8 Categories`):** *Áo khoác Vintage*, *Đầm & Chân váy Cổ điển*, *Túi xách & Đồ da*, *Đồng hồ & Trang sức Cổ*, *Máy ảnh Film & Điện tử Retro*, *Đĩa than & Cassette*, *Giày & Boots Da*, *Phụ kiện Mùa Lễ Hội*.
- **Thương hiệu (`8 Brands`):** *Levi's Vintage*, *Burberrys' (Archive)*, *Casio Retro*, *Olympus Film*, *Coach Vintage*, *Seiko Automatic*, *Dr. Martens Classic*, *Handmade Archive*.
- **16 Sản phẩm (`PRD-2026-0001` $\rightarrow$ `PRD-2026-0016`) bao phủ toàn bộ 7 trạng thái vòng đời (`M-SL-02`):**
  - `PRD-2026-0001..0006` (`FIXED_PRICE`, `status = 'APPROVED'`): Đang hiển thị công khai trên Trang chủ & Tìm kiếm, đầy đủ `condition`, `defect_info` rõ ràng và 2–3 ảnh sản phẩm (`GALLERY` + `DEFECT_CLOSEUP` + `AUTHENTICITY_EVIDENCE`).
  - `PRD-2026-0007..0011` (`AUCTION`, `status = 'APPROVED'` hoặc `'SOLD'`): Gắn với 6 kịch bản phiên đấu giá bên dưới (`total_quantity = 1` – `BR-PR-01`).
  - `PRD-2026-0012` (`status = 'DRAFT'`): Bản nháp đang lưu dở của Seller A.
  - `PRD-2026-0013` (`status = 'PENDING_REVIEW'`): Đang nằm trong hàng chờ kiểm duyệt của Moderator (`A-MD-01`).
  - `PRD-2026-0014` (`status = 'REJECTED'`): Đã bị Moderator từ chối kèm `rejection_reason` rõ ràng và bản ghi trong `product_moderation_logs` (`DEC-05`, sẵn sàng để demo tính năng `Resubmit` trên `M-SL-04`).
  - `PRD-2026-0015` (`status = 'HIDDEN'`): Bị ẩn kèm lý do kiểm duyệt.
  - `PRD-2026-0016` (`status = 'SOLD'`, `available_quantity = 0`): Sản phẩm đã bán hết qua đơn hoàn tất.

---

### 3.3. Seeder 3 (`ScheduledAuctionsSeeder`): 3 Khung Giờ Phiên & 6 Phiên Đấu Giá Đủ 6 Trạng Thái
1. **`AUC-2026-0001` (`status = 'LIVE'` – Đang diễn ra sôi động):**
   - Sản phẩm: *Máy ảnh Film Olympus OM-10 kèm Lens 50mm f/1.8*.
   - Giá khởi điểm `800.000đ`, bước giá `50.000đ`, giá sàn `900.000đ`. Đã có 3 lượt trả giá trong `auction_bids` (`800k` $\rightarrow$ `850k` $\rightarrow$ `950k`), người dẫn đầu hiện tại là `Buyer 1`. Thời gian kết thúc: `NOW() + 45 phút`.
2. **`AUC-2026-0002` (`status = 'LIVE'` – Sắp kết thúc để test Anti-Sniping & Seller Close Early):**
   - Sản phẩm: *Đồng hồ Seiko 5 Automatic Mặt Xanh Thập Niên 80s*.
   - Giá khởi điểm `600.000đ`, bước giá `50.000đ`, giá hiện tại `750.000đ` (`Buyer 2` dẫn đầu), thời gian kết thúc: `NOW() + 90 giây` (Nằm ngay trong vùng nhạy cảm 2 phút cuối để test Anti-Sniping `BR-AU-04`).
3. **`AUC-2026-0003` (`status = 'SCHEDULED'` – Sắp mở):**
   - Mở vào khung giờ phiên tối (`NOW() + 2 giờ`), chưa có lượt trả giá (`current_highest_bid = 0`).
4. **`AUC-2026-0004` (`status = 'COMPLETED'` – Đã có người thắng):**
   - `Buyer 1` chiến thắng với mức giá `1.000.000đ`, đã sinh đơn hàng thắng đấu giá `ORD-2026-0002` bên dưới.
5. **`AUC-2026-0005` (`status = 'ENDED_UNSOLD'` – Kết thúc không có người mua):**
   - Sẵn sàng để Seller bấm nút **Đăng lại (`Relist` – `AF-09`)** trên `M-SL-02`.
6. **`AUC-2026-0006` (`status = 'WINNER_DEFAULTED'` – Người thắng bỏ cọc quá hạn 30 phút `DEC-02`):**
   - `Buyer 3` thắng ở mức `500.000đ` nhưng đơn `ORD-2026-0008` quá hạn 30 phút không thanh toán $\rightarrow$ Phiên chuyển sang `WINNER_DEFAULTED`, sẵn sàng để Seller đăng lại.

---

### 3.4. Seeder 4 (`OrdersPaymentsAndEscrowSeeder`): 8 Kịch Bản Đơn Hàng, Thanh Toán QR & Sổ Cái Cân Bằng Tuyệt Đối

Mỗi đơn hàng đều tuân thủ công thức **`DEC-04`** (`buyer_protection_fee = ROUND(item_subtotal * 0.06) + 7000`, `shipping_fee = 0`):

| Mã Đơn (`order_code`) | Nguồn (`source`) | `item_subtotal` | `buyer_protection_fee` | `total_amount` | 4 Trạng Thái (`Order / Payment / Escrow / Dispute`) | Bút Toán `escrow_transactions` & `wallet_transactions` |
| :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| **`ORD-2026-0001`** | `FIXED_PRICE` | `400.000đ` | `31.000đ` | `431.000đ` | `PENDING_PAYMENT` / `UNPAID` / `NONE` / `NONE` | Có phiên QR `PENDING` (Để demo bấm nút Thanh toán QR thành công trên `M-PM-01`). |
| **`ORD-2026-0002`** | `AUCTION`<br>(`AUC-0004`) | `1.000.000đ` | `67.000đ` | `1.067.000đ` | `PAID` / `PAID` / `HELD` / `NONE` | 1 bút toán `HOLD` (`1.067.000đ`). Tiền hàng `1.000.000đ` nằm trong `escrow_held_balance` của Seller A. |
| **`ORD-2026-0003`** | `FIXED_PRICE` | `350.000đ` | `28.000đ` | `378.000đ` | `PREPARING` / `PAID` / `HELD` / `NONE`<br>*(Có `cancellation_requested = true`)* | 1 bút toán `HOLD` (`378.000đ`). Để demo Seller duyệt/từ chối yêu cầu xin hủy đơn ở `PREPARING` (`DEC-06`). |
| **`ORD-2026-0004`** | `FIXED_PRICE` | `500.000đ` | `37.000đ` | `537.000đ` | `SHIPPED` / `PAID` / `HELD` / `NONE` | 1 bút toán `HOLD` (`537.000đ`) + 1 bản ghi vận đơn `shipments` (`GHN`). |
| **`ORD-2026-0005`** | `FIXED_PRICE` | `600.000đ` | `43.000đ` | `643.000đ` | `DELIVERED` / `PAID` / `HELD` / `NONE`<br>*(Đủ điều kiện tự động hoàn tất)* | 1 bút toán `HOLD` (`643.000đ`). Cột `auto_complete_at` đặt sẵn ở quá khứ (`NOW() - 5 minutes`) để test nút Auto-Complete trên `A-DT-01` hoặc Buyer bấm Đã nhận hàng. |
| **`ORD-2026-0006`** | `FIXED_PRICE` | `500.000đ` | `37.000đ` | `537.000đ` | `COMPLETED` / `PAID` / `RELEASED` / `NONE` | 1 bút toán `HOLD` + **1 bút toán `RELEASE`** (`seller_released_amount = 500.000đ`, `platform_fee_retained = 37.000đ`) + **1 bút toán `wallet_transactions` (`CREDIT +500.000đ`)**. |
| **`ORD-2026-0007`** | `FIXED_PRICE` | `300.000đ` | `25.000đ` | `325.000đ` | `CANCELLED` / `REFUNDED` / `REFUNDED` / `NONE` | Buyer hủy lúc `PAID` $\rightarrow$ 1 bút toán `HOLD` + **1 bút toán `FULL_REFUND` hoàn trả 100% `total_amount` (`325.000đ` – `DEC-07`)**. |
| **`ORD-2026-0008`** | `AUCTION`<br>(`AUC-0006`) | `500.000đ` | `37.000đ` | `537.000đ` | `CANCELLED` / `EXPIRED` / `NONE` / `NONE` | Đơn thắng đấu giá quá hạn 30 phút bị hệ thống hủy tự động (`DEC-02`). |
| **`ORD-2026-0009`** | `FIXED_PRICE` | `700.000đ` | `49.000đ` | `749.000đ` | `DELIVERED` / `PAID` / `HELD` / **`OPEN`** | Đang có khiếu nại `DSP-2026-0001` (`escrow_frozen_at != NULL`), bị khóa giải ngân tự động (`BR-DP-02`). |
| **`ORD-2026-0010`** | `FIXED_PRICE` | `800.000đ` | `55.000đ` | `855.000đ` | `COMPLETED` / `PAID` / **`PARTIALLY_REFUNDED`** / **`RESOLVED`** | Đã được Admin phân xử `DSP-2026-0002` theo hướng **`PARTIAL_REFUND`**: Hoàn cho Buyer `200.000đ`, giải ngân cho Seller `600.000đ`, nền tảng giữ phí bảo vệ `55.000đ` (`BR-FN-06`) + cộng Ví Seller `+600.000đ`. |

---

### 3.5. Seeder 5 & Seeder 6 (`DisputesAndReviewsSeeder` & `EngagementChatAndAuditSeeder`)
- **2 Hồ sơ Khiếu nại (`disputes` + `dispute_evidences`):**
  - `DSP-2026-0001` (Gắn với `ORD-2026-0009`, `status = 'OPEN'`, `opened_at_order_status = 'DELIVERED'`): Có sẵn bằng chứng của Buyer và đối chứng của Seller để Admin phân xử trực tiếp trên màn hình Split-Pane `A-DP-02`.
  - `DSP-2026-0002` (Gắn với `ORD-2026-0010`, `status = 'RESOLVED'`, `admin_verdict = 'PARTIAL_REFUND'`): Hồ sơ mẫu đã giải quyết xong.
- **Đánh giá xác thực (`reviews`):** Đánh giá 5 sao gắn với đơn hoàn tất `ORD-2026-0006` (`BR-RV-01`).
- **Báo cáo vi phạm (`reports`), Yêu thích (`favorites`), Theo dõi tiệm (`seller_follows`), Phòng Chat 1-1 (`conversations` + `messages` kèm ngữ cảnh sản phẩm), Thông báo (`notifications`) và Nhật ký kiểm toán (`audit_logs`).**

---

## Chương 4. Tiêu Chí Nghiệm Thu & Các Bước Kiểm Tra `P5-05` (`Acceptance Criteria`)

- [x] **AC-P505-01 (Idempotent Execution):** Chạy `php artisan db:seed` 2 lần liên tiếp thành công 100%, tổng số bản ghi trong cả 34 bảng giữ nguyên không đổi giữa lần chạy 1 và lần chạy 2.
- [x] **AC-P505-02 (Zero Ledger Drift Audit):** Chạy lệnh `php artisan db:verify-seeders` xác nhận:
  - Tổng `wallet_transactions.amount` của từng Seller bằng đúng `seller_profiles.wallet_balance`.
  - Tổng `orders.item_subtotal` của các đơn đang có `escrow_status = 'HELD'` của từng Seller bằng đúng `seller_profiles.escrow_held_balance`.
- [x] **AC-P505-03 (Full State Coverage):** Đủ 4 vai trò nhân sự/người dùng, 7 trạng thái sản phẩm, 6 trạng thái phiên đấu giá, 4 loại bút toán Escrow và 2 hồ sơ khiếu nại.

---

## Chương 5. Nhật Ký Nghiệm Thu Kỹ Thuật (`Verification Audit Log`)

- **Ngày Thực Thi:** `2026-11-14`
- **Lệnh Kiểm Thử:** `php artisan db:seed` (x2) & `php artisan db:verify-seeders`
- **Kết Quả:** `ALL VERIFICATION CHECKS PASSED (100% INTEGRITY & ZERO DRIFT)`
- **Thống Kê Dữ Liệu Sau 2 Lần Chạy Liên Tiếp (Không Đổi Số Bản Ghi):**
  - `users`: 10 rows (Admin, Mod, Support, 3 Sellers, 3 Buyers, 1 Suspended)
  - `platform_settings`: 12 rows
  - `seller_profiles`: 10 rows
  - `categories`: 8 rows | `brands`: 8 rows
  - `products`: 16 rows (Bao phủ 7 trạng thái vòng đời)
  - `product_images`: 48 rows | `product_moderation_logs`: 2 rows
  - `auction_sessions`: 3 rows | `auctions`: 6 rows | `auction_bids`: 9 rows | `auction_watches`: 7 rows
  - `orders`: 10 rows (100% tuân thủ DEC-04: shipping = 0, fee = 6% + 7k, seller net 100%)
  - `order_items`: 10 rows | `shipments`: 5 rows | `payments`: 10 rows
  - `escrow_transactions`: 11 rows (Bao phủ 4 loại bút toán HOLD, RELEASE, FULL_REFUND, PARTIAL_REFUND)
  - `wallet_transactions`: 2 rows (Cân bằng số dư ví Seller A 1.100.000đ)
  - `disputes`: 2 rows | `dispute_evidences`: 3 rows
  - `reviews`: 1 row | `reports`: 1 row | `favorites`: 4 rows | `seller_follows`: 3 rows
  - `conversations`: 1 row | `messages`: 4 rows | `notifications`: 3 rows | `audit_logs`: 2 rows
