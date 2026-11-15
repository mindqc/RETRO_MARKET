# 01. CORE DATABASE SCHEMA SPECIFICATION (USERS, CATALOG, PRODUCTS & ENGAGEMENT) – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P402A-DB-CORE-SCHEMA`
- **Version:** `1.0.0 (COMPLETE POSTGRESQL 18 DDL SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Target DBMS:** `PostgreSQL 18.x`
- **Character Encoding & Collation:** `UTF-8 (Unicode NFC Normalized)`
- **Phase:** `Phase 04 – System Architecture, Database Design & API Specification`
- **Compliance Ref:** `BR-AC-01..04`, `BR-PR-01..05`, `DEC-04`, `DEC-05`, `ADR-01..08`, `NFR-SEC-01..05`, `NFR-REL-01..04`

---

## Chương 1. Quy Chuẩn Thiết Kế Cơ Sở Dữ Liệu PostgreSQL 18 (`Database Engineering Standards`)

Để đảm bảo tính toàn vẹn dữ liệu tuyệt đối và hiệu năng truy vấn cao cho nền tảng C2C Secondhand Marketplace **`izithrift`**, toàn bộ lược đồ cơ sở dữ liệu tuân thủ 6 nguyên tắc kỹ thuật bắt buộc:

1. **Chuẩn hóa Kiểu dữ liệu Tiền tệ (`Strict Monetary Precision` – `BR-FN-01`):**
   - Toàn bộ các cột lưu trữ giá trị tiền tệ (`price`, `wallet_balance`, `escrow_held_balance`, `starting_price`, `bid_amount`, `total_amount`...) bắt buộc sử dụng kiểu **`NUMERIC(15, 2)`** (kết hợp `CHECK (column >= 0)`). **Cấm tuyệt đối** sử dụng `FLOAT`, `REAL` hoặc `DOUBLE PRECISION` để tránh sai số dấu phẩy động.
2. **Đồng bộ Thời gian Chuẩn Máy chủ (`Server-Authoritative Timestamps` – `BR-AU-01`):**
   - Toàn bộ cột thời gian (`created_at`, `updated_at`, `auction_starts_at`, `auction_ends_at`, `payment_expires_at`, `auto_complete_at`) sử dụng kiểu **`TIMESTAMPTZ` (`TIMESTAMP WITH TIME ZONE`)** lưu theo múi giờ chuẩn của máy chủ ứng dụng.
3. **Bảo toàn Lịch sử Giao dịch (`Zero Physical Deletion on Transactional Entities` – `NFR-REL-04`):**
   - Các thực thể liên quan đến tài khoản (`users`), danh mục (`categories`, `brands`), sản phẩm đã từng phát sinh giao dịch (`products`), đơn hàng (`orders`) và sổ cái (`escrow_transactions`, `wallet_transactions`) không bao giờ xóa vật lý (`DELETE`), mà quản lý vòng đời qua cột `status` hoặc `deleted_at`.
4. **Chuẩn hóa Tiếng Việt Unicode NFC (`ADR-07`):**
   - Toàn bộ cột văn bản (`VARCHAR`, `TEXT`) lưu trữ chuỗi tiếng Việt ở dạng dựng sẵn **Unicode NFC**, kết hợp chỉ mục tìm kiếm `GIN / B-Tree` phục vụ truy vấn đa tiêu chí (`M-DS-02`).
5. **Thực thi Quy tắc Nghiệp vụ Ngay Tại Tầng CSDL (`Database-Level CHECK Constraints`):**
   - Không chỉ kiểm tra ở tầng PHP/Laravel, các quy tắc sống còn như *"Không tự theo dõi chính mình"*, *"Số lượng sản phẩm đấu giá luôn bằng 1"*, *"Sản phẩm bắt buộc có khai báo tình trạng & khuyết điểm"* được ép cứng bằng `CHECK` và `UNIQUE` constraints trên PostgreSQL.
6. **Phân tách Hồ sơ Tài khoản Hợp nhất (`Unified Account with Dual Profiles` – `BR-AC-01`):**
   - Một bản ghi duy nhất trong bảng `users` liên kết `1:1` với `user_profiles` (thông tin chung) và `seller_profiles` (chỉ số uy tín tiệm, số dư ví khả dụng và số dư đang chờ giải ngân trong Escrow).

---

## Chương 2. Danh Mục 17 Bảng Thuộc Phân Hệ Core, Catalog, Product & Engagement (`DB_01 Table Inventory`)

| STT | Tên Bảng (`Table Name`) | Nhóm Nghiệp Vụ | Khóa Chính (`PK`) | Mô Tả Vai Trò Cốt Lõi |
| :-: | :--- | :--- | :---: | :--- |
| 01 | `users` | Auth & RBAC | `id (BIGSERIAL)` | Tài khoản hợp nhất Buyer/Seller (`registered_user`) và nhân sự nội bộ (`admin`, `moderator`, `support`). |
| 02 | `personal_access_tokens` | Auth (Sanctum) | `id (BIGSERIAL)` | Lưu trữ API Token của ứng dụng Flutter Mobile; tự động thu hồi khi khóa tài khoản (`BR-AC-04`). |
| 03 | `password_reset_tokens` | Auth Recovery | `email (VARCHAR)` | Lưu mã khôi phục mật khẩu có thời hạn (`M-AU-05`). |
| 04 | `user_profiles` | User Profile | `id (BIGSERIAL)` | Hồ sơ cá nhân, ảnh đại diện, giới thiệu (`bio`), cờ bật/tắt trang trí Giáng sinh (`M-PF-02`, `M-PF-06`). |
| 05 | `seller_profiles` | Seller & Wallet | `id (BIGSERIAL)` | Hồ sơ Tiệm đồ si, `trust_score`, `average_rating`, **`wallet_balance`**, **`escrow_held_balance`** và bộ đếm gian lận. |
| 06 | `user_addresses` | Address Book | `id (BIGSERIAL)` | Sổ địa chỉ nhận hàng của người mua (`M-PF-03`, `M-PF-04`). |
| 07 | `categories` | Catalog | `id (BIGSERIAL)` | Cây danh mục sản phẩm đồ secondhand (`M-DS-01`, `A-CT-01`). |
| 08 | `brands` | Catalog | `id (BIGSERIAL)` | Danh bạ thương hiệu cổ điển / thời trang (`M-DS-01`, `A-CT-01`). |
| 09 | `products` | Product Core | `id (BIGSERIAL)` | Bảng sản phẩm trung tâm hỗ trợ cả `FIXED_PRICE` và `AUCTION`, lưu `condition`, `defect_info` và 7 trạng thái vòng đời. |
| 10 | `product_images` | Product Media | `id (BIGSERIAL)` | Hình ảnh thực tế của sản phẩm (`1..8` ảnh) và ảnh bằng chứng xác thực (`authenticity_evidence`). |
| 11 | `product_moderation_logs` | Moderation | `id (BIGSERIAL)` | Lịch sử kiểm duyệt bài đăng của Moderator/Admin kèm lý do từ chối bắt buộc (`DEC-05`, `A-MD-02`). |
| 12 | `favorites` | Engagement | `id (BIGSERIAL)` | Danh sách sản phẩm yêu thích của người dùng (`M-PF-05`). |
| 13 | `seller_follows` | Engagement | `id (BIGSERIAL)` | Danh sách theo dõi Tiệm bán (`M-US-03`, `M-PF-05`). |
| 14 | `conversations` | Chat 1-on-1 | `id (BIGSERIAL)` | Phiên trò chuyện 1-1 giữa 2 người dùng, gắn ngữ cảnh sản phẩm/đơn hàng (`M-CM-01`, `M-CM-02`). |
| 15 | `messages` | Chat 1-on-1 | `id (BIGSERIAL)` | Tin nhắn văn bản trong phòng chat phục vụ HTTP Polling (`ADR-08`). |
| 16 | `notifications` | Notifications | `id (BIGSERIAL)` | Trung tâm thông báo In-App hỗ trợ Deep-Linking (`M-NT-01`). |
| 17 | `platform_settings` | System Config | `key (VARCHAR)` | Cấu hình động: **Buyer Protection Fee (`6% + 7.000đ`)**, tham số thời gian `Production Mode` vs `Demo Mode` (`A-ST-01`). |
| 18 | `audit_logs` | Governance | `id (BIGSERIAL)` | Nhật ký kiểm toán bất biến ghi vết mọi thao tác của Admin/Moderator/Seller Early Close (`A-AD-01`). |

---

## Chương 3. Đặc Tả Chi Tiết Cấu Trúc Từng Bảng (`Detailed Table Specifications`)

### 3.1. Nhóm Xác Thực, Hồ Sơ Hợp Nhất & Sổ Địa Chỉ (`users`, `user_profiles`, `seller_profiles`, `user_addresses`)

#### Bảng 1: `users` (Tài Khoản Người Dùng & Nhân Sự Nội Bộ – `BR-AC-01`, `BR-AC-04`)

| Tên Cột (`Column`) | Kiểu Dữ Liệu (`Type`) | Ràng Buộc (`Constraints`) | Mặc Định (`Default`) | Mô Tả Chi Tiết & Quy Tắc Nghiệp Vụ |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Auto-increment | Khóa chính định danh người dùng. |
| `display_name` | `VARCHAR(100)` | `NOT NULL` | — | Tên hiển thị chung / Tên Tiệm đồ si (Unicode NFC). |
| `email` | `VARCHAR(150)` | `NOT NULL, UNIQUE` | — | Email đăng nhập duy nhất (lưu chữ thường `LOWER(email)`). |
| `phone` | `VARCHAR(20)` | `NULLABLE` | `NULL` | Số điện thoại liên hệ (10–11 chữ số). |
| `password_hash` | `VARCHAR(255)` | `NOT NULL` | — | Mật khẩu băm bằng thuật toán `Bcrypt` (`NFR-SEC-01`). |
| `role` | `VARCHAR(30)` | `NOT NULL, CHECK` | `'registered_user'` | `CHECK (role IN ('registered_user', 'moderator', 'support', 'admin'))`. |
| `status` | `VARCHAR(20)` | `NOT NULL, CHECK` | `'ACTIVE'` | `CHECK (status IN ('ACTIVE', 'SUSPENDED', 'BANNED'))` (`BR-AC-04`). |
| `status_reason` | `TEXT` | `NULLABLE` | `NULL` | Lý do Admin khóa tạm thời hoặc khóa vĩnh viễn tài khoản (`A-US-02`). |
| `suspended_until` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời hạn khóa tạm thời (nếu `status = 'SUSPENDED'`). |
| `last_login_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời điểm đăng nhập gần nhất. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm tạo tài khoản. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm cập nhật gần nhất. |

#### Bảng 2: `user_profiles` (Hồ Sơ Cá Nhân & Tùy Chọn Giao Diện – `1:1` với `users`)

| Tên Cột (`Column`) | Kiểu Dữ Liệu (`Type`) | Ràng Buộc (`Constraints`) | Mặc Định (`Default`) | Mô Tả Chi Tiết & Quy Tắc Nghiệp Vụ |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Auto-increment | Khóa chính. |
| `user_id` | `BIGINT` | `NOT NULL, UNIQUE, FK` | — | `REFERENCES users(id) ON DELETE CASCADE`. |
| `avatar_url` | `VARCHAR(500)` | `NULLABLE` | `NULL` | Đường dẫn ảnh đại diện (`jpg/png/webp <= 5MB` – `NFR-SEC-05`). |
| `bio` | `TEXT` | `NULLABLE` | `NULL` | Đoạn giới thiệu bản thân & phong cách Tiệm đồ si (`M-PF-02`, `M-US-03`). |
| `seasonal_decor_enabled` | `BOOLEAN` | `NOT NULL` | `TRUE` | Cờ bật/tắt hiệu ứng trang trí Giáng sinh mùa vụ (`enableSeasonalChristmasDecor` – `NFR-UX-02`, `M-PF-06`). |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm tạo. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm cập nhật. |

#### Bảng 3: `seller_profiles` (Hồ Sơ Tiệm Bán, Điểm Uy Tín & Số Dư Ví Mô Phỏng – `1:1` với `users`)

| Tên Cột (`Column`) | Kiểu Dữ Liệu (`Type`) | Ràng Buộc (`Constraints`) | Mặc Định (`Default`) | Mô Tả Chi Tiết & Quy Tắc Nghiệp Vụ |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Auto-increment | Khóa chính. |
| `user_id` | `BIGINT` | `NOT NULL, UNIQUE, FK` | — | `REFERENCES users(id) ON DELETE CASCADE`. |
| `shop_slug` | `VARCHAR(120)` | `NOT NULL, UNIQUE` | — | Đường dẫn tĩnh định danh tiệm bán. |
| `trust_score` | `NUMERIC(5,2)` | `NOT NULL, CHECK` | `100.00` | Điểm tin cậy của tiệm (`CHECK (trust_score >= 0 AND trust_score <= 100)`). |
| `average_rating` | `NUMERIC(3,2)` | `NOT NULL, CHECK` | `0.00` | Điểm sao trung bình từ các đơn `COMPLETED` (`0.00` đến `5.00` – `BR-RV-01`). |
| `review_count` | `INTEGER` | `NOT NULL, CHECK` | `0` | Tổng số lượt đánh giá hợp lệ (`>= 0`). |
| `completed_orders_count` | `INTEGER` | `NOT NULL, CHECK` | `0` | Tổng số đơn bán đã hoàn tất (`>= 0`). |
| `wallet_balance` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | `0.00` | **Số dư Ví khả dụng** (Đã giải ngân 100% `item_subtotal` – `DEC-04`, `CHECK (wallet_balance >= 0)`). Chỉ được cập nhật qua `EscrowReleaseService` kèm bản ghi `wallet_transactions` (`BR-FN-07`). |
| `escrow_held_balance` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | `0.00` | Tổng tiền hàng (`item_subtotal`) của Seller hiện đang nằm chờ giải ngân trong `ESCROW_HELD` (`>= 0`). |
| `auction_default_count` | `INTEGER` | `NOT NULL, CHECK` | `0` | Số lần người dùng này thắng đấu giá nhưng bỏ cọc quá hạn 30 phút (`DEC-02`, phục vụ cảnh báo gian lận trên `A-AC-03`, `A-US-02`). |
| `dispute_lost_count` | `INTEGER` | `NOT NULL, CHECK` | `0` | Số lần người bán bị Admin xử thua khiếu nại (`APPROVE_BUYER_REFUND`). |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm khởi tạo. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm cập nhật. |

#### Bảng 4: `user_addresses` (Sổ Địa Chỉ Nhận Hàng – `M-PF-03`, `M-PF-04`)

| Tên Cột (`Column`) | Kiểu Dữ Liệu (`Type`) | Ràng Buộc (`Constraints`) | Mặc Định (`Default`) | Mô Tả Chi Tiết |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Auto-increment | Khóa chính địa chỉ. |
| `user_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES users(id) ON DELETE CASCADE`. |
| `recipient_name` | `VARCHAR(100)` | `NOT NULL` | — | Họ và tên người nhận hàng. |
| `recipient_phone` | `VARCHAR(20)` | `NOT NULL` | — | Số điện thoại người nhận. |
| `province_city` | `VARCHAR(100)` | `NOT NULL` | — | Tỉnh / Thành phố. |
| `district_ward` | `VARCHAR(150)` | `NOT NULL` | — | Quận / Huyện & Phường / Xã. |
| `street_address` | `VARCHAR(255)` | `NOT NULL` | — | Số nhà, tên đường, tòa nhà chi tiết. |
| `is_default` | `BOOLEAN` | `NOT NULL` | `FALSE` | Đánh dấu địa chỉ mặc định khi vào `M-OR-01 Checkout Preview`. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm tạo. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm cập nhật. |

---

### 3.2. Nhóm Danh Mục, Sản Phẩm Đồ Secondhand & Kiểm Duyệt (`categories`, `brands`, `products`, `product_images`, `product_moderation_logs`)

#### Bảng 5 & 6: `categories` & `brands` (`M-DS-01`, `A-CT-01`)
- **`categories`:** `id (BIGSERIAL PK)`, `parent_id (BIGINT NULLABLE FK -> categories.id)`, `name (VARCHAR(100) NOT NULL)`, `slug (VARCHAR(120) NOT NULL UNIQUE)`, `icon_name (VARCHAR(60) NULLABLE)`, `description (TEXT)`, `sort_order (INTEGER DEFAULT 0)`, `is_active (BOOLEAN DEFAULT TRUE)`, `created_at`, `updated_at`.
- **`brands`:** `id (BIGSERIAL PK)`, `name (VARCHAR(100) NOT NULL UNIQUE)`, `slug (VARCHAR(120) NOT NULL UNIQUE)`, `logo_url (VARCHAR(500) NULLABLE)`, `origin_country (VARCHAR(80) NULLABLE)`, `description (TEXT)`, `is_active (BOOLEAN DEFAULT TRUE)`, `created_at`, `updated_at`.

#### Bảng 7: `products` (Bảng Sản Phẩm Trung Tâm – `BR-PR-01..05`, `DEC-05`)

| Tên Cột (`Column`) | Kiểu Dữ Liệu (`Type`) | Ràng Buộc (`Constraints`) | Mặc Định (`Default`) | Mô Tả Chi Tiết & Quy Tắc Nghiệp Vụ |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Auto-increment | Khóa chính sản phẩm (hỗ trợ `SELECT ... FOR UPDATE` khi đặt hàng `OF-02`). |
| `product_code` | `VARCHAR(30)` | `NOT NULL, UNIQUE` | — | Mã hiển thị trên UI (ví dụ: `PRD-2026-0204`). |
| `seller_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES users(id) ON DELETE RESTRICT` (Người đăng bán). |
| `category_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES categories(id) ON DELETE RESTRICT`. |
| `brand_id` | `BIGINT` | `NULLABLE, FK` | `NULL` | `REFERENCES brands(id) ON DELETE SET NULL`. |
| `title` | `VARCHAR(150)` | `NOT NULL` | — | Tên sản phẩm tiếng Việt (Unicode NFC). |
| `slug` | `VARCHAR(180)` | `NOT NULL, UNIQUE` | — | Slug đường dẫn thân thiện. |
| `description` | `TEXT` | `NOT NULL` | — | Mô tả chi tiết chất liệu, số đo và câu chuyện món đồ. |
| `condition` | `VARCHAR(25)` | `NOT NULL, CHECK` | — | **Độ mới bắt buộc (`BR-PR-03`):** `CHECK (condition IN ('LIKE_NEW', 'GOOD', 'FAIR', 'VINTAGE_WORN'))`. |
| `defect_info` | `TEXT` | `NOT NULL, CHECK` | — | **Mô tả vết xước / khuyết điểm bắt buộc (`BR-PR-03`):** `CHECK (LENGTH(TRIM(defect_info)) > 0)`. |
| `listing_type` | `VARCHAR(20)` | `NOT NULL, CHECK` | `'FIXED_PRICE'` | **Phương thức bán (`BR-PR-01`):** `CHECK (listing_type IN ('FIXED_PRICE', 'AUCTION'))`. |
| `price` | `NUMERIC(15,2)` | `NULLABLE, CHECK` | `NULL` | Giá bán cố định (Bắt buộc `> 0` khi `listing_type = 'FIXED_PRICE'`; bằng `starting_price` khi `AUCTION`). |
| `total_quantity` | `INTEGER` | `NOT NULL, CHECK` | `1` | Tổng số lượng ban đầu (`>= 1`; nếu `listing_type = 'AUCTION'` bắt buộc `= 1`). |
| `available_quantity` | `INTEGER` | `NOT NULL, CHECK` | `1` | Số lượng tồn kho khả dụng hiện tại (`CHECK (available_quantity >= 0 AND available_quantity <= total_quantity)`). |
| `verification_level` | `VARCHAR(30)` | `NOT NULL, CHECK` | `'UNVERIFIED'` | Mức độ xác minh do Moderator gán (`A-MD-02`): `CHECK (verification_level IN ('UNVERIFIED', 'EVIDENCE_PROVIDED', 'MODERATOR_REVIEWED'))`. |
| `status` | `VARCHAR(25)` | `NOT NULL, CHECK` | `'DRAFT'` | **7 Trạng thái vòng đời (`M-SL-02`):** `CHECK (status IN ('DRAFT', 'PENDING_REVIEW', 'APPROVED', 'REJECTED', 'SOLD', 'HIDDEN', 'ARCHIVED'))`. |
| `rejection_reason` | `TEXT` | `NULLABLE` | `NULL` | Lý do từ chối gần nhất của Moderator để ghim trên `M-SL-04` & `M-SL-03` (`DEC-05`). |
| `favorite_count` | `INTEGER` | `NOT NULL, CHECK` | `0` | Bộ đếm số người lưu yêu thích (`>= 0`, phục vụ sắp xếp `sort=popular`). |
| `approved_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời điểm được Moderator duyệt lên kệ. |
| `approved_by` | `BIGINT` | `NULLABLE, FK` | `NULL` | `REFERENCES users(id) ON DELETE SET NULL`. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm tạo. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm cập nhật. |

#### Bảng 8: `product_images` (Hình Ảnh Sản Phẩm & Bằng Chứng Xác Thực – `M-PR-01`, `M-PR-02`)
- **Cột:** `id (BIGSERIAL PK)`, `product_id (BIGINT NOT NULL FK -> products.id ON DELETE CASCADE)`, `image_url (VARCHAR(500) NOT NULL)`, `image_type (VARCHAR(30) NOT NULL DEFAULT 'GALLERY' CHECK (image_type IN ('GALLERY', 'DEFECT_CLOSEUP', 'AUTHENTICITY_EVIDENCE')))`, ` is_primary (BOOLEAN NOT NULL DEFAULT FALSE)`, `sort_order (SMALLINT NOT NULL DEFAULT 0)`, `file_size_bytes (INTEGER CHECK (file_size_bytes <= 5242880))` (`<= 5MB` theo `NFR-SEC-05`), `created_at`.

#### Bảng 9: `product_moderation_logs` (Lịch Sử Kiểm Duyệt Bài Đăng – `BR-PR-04`, `DEC-05`)
- **Cột:** `id (BIGSERIAL PK)`, `product_id (BIGINT NOT NULL FK -> products.id ON DELETE CASCADE)`, `moderator_id (BIGINT NOT NULL FK -> users.id)`, `action (VARCHAR(25) NOT NULL CHECK (action IN ('SUBMITTED', 'APPROVED', 'REJECTED', 'HIDDEN', 'UNHIDDEN')))`, `previous_status (VARCHAR(25) NOT NULL)`, `new_status (VARCHAR(25) NOT NULL)`, `verification_level_assigned (VARCHAR(30) NULLABLE)`, **`reason (TEXT NULLABLE)`** *(Ràng buộc `CHECK`: nếu `action IN ('REJECTED', 'HIDDEN')` thì `LENGTH(TRIM(COALESCE(reason, ''))) > 0`)*, `created_at (TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP)`.

---

### 3.3. Nhóm Tương Tác, Chat 1-1, Thông Báo, Cấu Hình & Kiểm Toán (`favorites`, `seller_follows`, `conversations`, `messages`, `notifications`, `platform_settings`, `audit_logs`)

1. **`favorites` (`M-PF-05`):**
   - `id (BIGSERIAL PK)`, `user_id (BIGINT NOT NULL FK -> users.id)`, `product_id (BIGINT NOT NULL FK -> products.id)`, `created_at`.
   - Ràng buộc: `UNIQUE (user_id, product_id)`.
2. **`seller_follows` (`M-US-03`, `M-PF-05`):**
   - `id (BIGSERIAL PK)`, `follower_id (BIGINT NOT NULL FK -> users.id)`, `seller_id (BIGINT NOT NULL FK -> users.id)`, `created_at`.
   - Ràng buộc: `UNIQUE (follower_id, seller_id)` và **`CHECK (follower_id <> seller_id)`** (Chặn tự theo dõi chính mình – `BR-AC-02`).
3. **`conversations` (`M-CM-01`, `M-CM-02`):**
   - `id (BIGSERIAL PK)`, `user_one_id (BIGINT NOT NULL FK -> users.id)`, `user_two_id (BIGINT NOT NULL FK -> users.id)`, `context_product_id (BIGINT NULLABLE FK -> products.id)`, `context_order_id (BIGINT NULLABLE)`, `last_message_preview (VARCHAR(255) NULLABLE)`, `last_message_at (TIMESTAMPTZ NULLABLE)`, `blocked_by_user_id (BIGINT NULLABLE FK -> users.id)`, `created_at`, `updated_at`.
   - Ràng buộc: `CHECK (user_one_id < user_two_id)` kết hợp `UNIQUE (user_one_id, user_two_id)` để đảm bảo giữa 2 người dùng chỉ tồn tại duy nhất 1 phòng chat 1-1.
4. **`messages` (`M-CM-02` – HTTP Polling `ADR-08`):**
   - `id (BIGSERIAL PK)`, `conversation_id (BIGINT NOT NULL FK -> conversations.id ON DELETE CASCADE)`, `sender_id (BIGINT NOT NULL FK -> users.id)`, `message_text (TEXT NOT NULL CHECK (LENGTH(TRIM(message_text)) > 0))`, `attached_product_id (BIGINT NULLABLE FK -> products.id)`, `is_read (BOOLEAN NOT NULL DEFAULT FALSE)`, `read_at (TIMESTAMPTZ NULLABLE)`, `created_at (TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP)`.
5. **`notifications` (`M-NT-01`):**
   - `id (BIGSERIAL PK)`, `user_id (BIGINT NOT NULL FK -> users.id ON DELETE CASCADE)`, `type (VARCHAR(40) NOT NULL)`, `title (VARCHAR(180) NOT NULL)`, `body (TEXT NOT NULL)`, `target_type (VARCHAR(40) NULLABLE)` (`'PRODUCT'`, `'AUCTION'`, `'ORDER'`, `'DISPUTE'`), `target_id (BIGINT NULLABLE)`, `deep_link_route (VARCHAR(255) NULLABLE)`, `is_read (BOOLEAN NOT NULL DEFAULT FALSE)`, `read_at (TIMESTAMPTZ NULLABLE)`, `created_at`.
6. **`platform_settings` (`A-ST-01` – `DEC-04`, `ADR-05`):**
   - `key (VARCHAR(80) PRIMARY KEY)`, `value (VARCHAR(255) NOT NULL)`, `value_type (VARCHAR(20) NOT NULL CHECK (value_type IN ('DECIMAL', 'INTEGER', 'BOOLEAN', 'STRING')))`, `description (TEXT NOT NULL)`, `updated_by (BIGINT NULLABLE FK -> users.id)`, `updated_at`.
7. **`audit_logs` (`A-AD-01` – `BR-AD-02`):**
   - `id (BIGSERIAL PK)`, `actor_id (BIGINT NULLABLE FK -> users.id)`, `actor_role (VARCHAR(30) NOT NULL)`, `action (VARCHAR(80) NOT NULL)`, `target_type (VARCHAR(50) NOT NULL)`, `target_id (BIGINT NULLABLE)`, `reason (TEXT NULLABLE)`, `old_values (JSONB NULLABLE)`, `new_values (JSONB NULLABLE)`, `ip_address (VARCHAR(45) NULLABLE)`, `created_at (TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP)`.

---

## Chương 4. Mã Lệnh Khởi Tạo SQL Chuẩn PostgreSQL 18 (`Complete SQL DDL Script – DB_01`)

```sql
-- ============================================================================
-- RETRO MARKET (izithrift) - DB_01: CORE, CATALOG, PRODUCT & ENGAGEMENT SCHEMA
-- Target DBMS: PostgreSQL 18.x | Encoding: UTF-8
-- ============================================================================

-- 1. USERS TABLE
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    display_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20) NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(30) NOT NULL DEFAULT 'registered_user'
        CONSTRAINT chk_users_role CHECK (role IN ('registered_user', 'moderator', 'support', 'admin')),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'BANNED')),
    status_reason TEXT NULL,
    suspended_until TIMESTAMPTZ NULL,
    last_login_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_role_status ON users(role, status);

-- 2. PERSONAL ACCESS TOKENS (Laravel Sanctum)
CREATE TABLE personal_access_tokens (
    id BIGSERIAL PRIMARY KEY,
    tokenable_type VARCHAR(100) NOT NULL,
    tokenable_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    token VARCHAR(64) NOT NULL UNIQUE,
    abilities TEXT NULL,
    last_used_at TIMESTAMPTZ NULL,
    expires_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pat_tokenable ON personal_access_tokens(tokenable_type, tokenable_id);

-- 3. PASSWORD RESET TOKENS
CREATE TABLE password_reset_tokens (
    email VARCHAR(150) PRIMARY KEY,
    token VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. USER PROFILES (1:1 with users)
CREATE TABLE user_profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    avatar_url VARCHAR(500) NULL,
    bio TEXT NULL,
    seasonal_decor_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5. SELLER PROFILES (1:1 with users - Unified C2C Account BR-AC-01)
CREATE TABLE seller_profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    shop_slug VARCHAR(120) NOT NULL UNIQUE,
    trust_score NUMERIC(5, 2) NOT NULL DEFAULT 100.00
        CONSTRAINT chk_seller_trust_score CHECK (trust_score >= 0.00 AND trust_score <= 100.00),
    average_rating NUMERIC(3, 2) NOT NULL DEFAULT 0.00
        CONSTRAINT chk_seller_avg_rating CHECK (average_rating >= 0.00 AND average_rating <= 5.00),
    review_count INTEGER NOT NULL DEFAULT 0
        CONSTRAINT chk_seller_review_count CHECK (review_count >= 0),
    completed_orders_count INTEGER NOT NULL DEFAULT 0
        CONSTRAINT chk_seller_completed_orders CHECK (completed_orders_count >= 0),
    wallet_balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00
        CONSTRAINT chk_seller_wallet_non_negative CHECK (wallet_balance >= 0.00),
    escrow_held_balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00
        CONSTRAINT chk_seller_escrow_non_negative CHECK (escrow_held_balance >= 0.00),
    auction_default_count INTEGER NOT NULL DEFAULT 0
        CONSTRAINT chk_seller_auction_default CHECK (auction_default_count >= 0),
    dispute_lost_count INTEGER NOT NULL DEFAULT 0
        CONSTRAINT chk_seller_dispute_lost CHECK (dispute_lost_count >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 6. USER ADDRESSES
CREATE TABLE user_addresses (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_name VARCHAR(100) NOT NULL,
    recipient_phone VARCHAR(20) NOT NULL,
    province_city VARCHAR(100) NOT NULL,
    district_ward VARCHAR(150) NOT NULL,
    street_address VARCHAR(255) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_addresses_user_default ON user_addresses(user_id, is_default DESC);

-- 7. CATEGORIES
CREATE TABLE categories (
    id BIGSERIAL PRIMARY KEY,
    parent_id BIGINT NULL REFERENCES categories(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(120) NOT NULL UNIQUE,
    icon_name VARCHAR(60) NULL,
    description TEXT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 8. BRANDS
CREATE TABLE brands (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(120) NOT NULL UNIQUE,
    logo_url VARCHAR(500) NULL,
    origin_country VARCHAR(80) NULL,
    description TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 9. PRODUCTS (Core Secondhand Listing Table - BR-PR-01..05)
CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    product_code VARCHAR(30) NOT NULL UNIQUE,
    seller_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    category_id BIGINT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    brand_id BIGINT NULL REFERENCES brands(id) ON DELETE SET NULL,
    title VARCHAR(150) NOT NULL,
    slug VARCHAR(180) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    condition VARCHAR(25) NOT NULL
        CONSTRAINT chk_products_condition CHECK (condition IN ('NEW_WITH_TAGS', 'LIKE_NEW', 'GOOD', 'FAIR', 'VINTAGE_WORN')),
    defect_info TEXT NOT NULL
        CONSTRAINT chk_products_defect_not_empty CHECK (LENGTH(TRIM(defect_info)) > 0),
    listing_type VARCHAR(20) NOT NULL DEFAULT 'FIXED_PRICE'
        CONSTRAINT chk_products_listing_type CHECK (listing_type IN ('FIXED_PRICE', 'AUCTION')),
    price NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_products_price_positive CHECK (price > 0.00),
    total_quantity INTEGER NOT NULL DEFAULT 1
        CONSTRAINT chk_products_total_qty CHECK (
            (listing_type = 'FIXED_PRICE' AND total_quantity >= 1) OR
            (listing_type = 'AUCTION' AND total_quantity = 1)
        ),
    available_quantity INTEGER NOT NULL DEFAULT 1
        CONSTRAINT chk_products_avail_qty CHECK (available_quantity >= 0 AND available_quantity <= total_quantity),
    verification_level VARCHAR(30) NOT NULL DEFAULT 'UNVERIFIED'
        CONSTRAINT chk_products_verification CHECK (verification_level IN ('UNVERIFIED', 'EVIDENCE_PROVIDED', 'MODERATOR_REVIEWED')),
    status VARCHAR(25) NOT NULL DEFAULT 'DRAFT'
        CONSTRAINT chk_products_status CHECK (status IN ('DRAFT', 'PENDING_REVIEW', 'APPROVED', 'REJECTED', 'SOLD', 'HIDDEN', 'ARCHIVED')),
    rejection_reason TEXT NULL,
    favorite_count INTEGER NOT NULL DEFAULT 0
        CONSTRAINT chk_products_fav_non_negative CHECK (favorite_count >= 0),
    approved_at TIMESTAMPTZ NULL,
    approved_by BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_public_discovery ON products(status, listing_type, category_id, condition, price, created_at DESC);
CREATE INDEX idx_products_seller_status ON products(seller_id, status, updated_at DESC);

-- 10. PRODUCT IMAGES
CREATE TABLE product_images (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    image_type VARCHAR(30) NOT NULL DEFAULT 'GALLERY'
        CONSTRAINT chk_product_images_type CHECK (image_type IN ('GALLERY', 'DEFECT_CLOSEUP', 'AUTHENTICITY_EVIDENCE')),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order SMALLINT NOT NULL DEFAULT 0,
    file_size_bytes INTEGER NULL
        CONSTRAINT chk_product_images_size CHECK (file_size_bytes IS NULL OR file_size_bytes <= 5242880),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_product_images_product_sort ON product_images(product_id, is_primary DESC, sort_order ASC);

-- 11. PRODUCT MODERATION LOGS (DEC-05 & BR-PR-04)
CREATE TABLE product_moderation_logs (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    moderator_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    action VARCHAR(25) NOT NULL
        CONSTRAINT chk_mod_logs_action CHECK (action IN ('SUBMITTED', 'APPROVED', 'REJECTED', 'HIDDEN', 'UNHIDDEN')),
    previous_status VARCHAR(25) NOT NULL,
    new_status VARCHAR(25) NOT NULL,
    verification_level_assigned VARCHAR(30) NULL,
    reason TEXT NULL
        CONSTRAINT chk_mod_logs_mandatory_reason CHECK (
            action NOT IN ('REJECTED', 'HIDDEN') OR LENGTH(TRIM(COALESCE(reason, ''))) > 0
        ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_mod_logs_product_time ON product_moderation_logs(product_id, created_at DESC);

-- 12. FAVORITES
CREATE TABLE favorites (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_favorites_user_product UNIQUE (user_id, product_id)
);

-- 13. SELLER FOLLOWS (BR-AC-02: Prevent Self-Follow)
CREATE TABLE seller_follows (
    id BIGSERIAL PRIMARY KEY,
    follower_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    seller_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_seller_follows UNIQUE (follower_id, seller_id),
    CONSTRAINT chk_no_self_follow CHECK (follower_id <> seller_id)
);

-- 14. CONVERSATIONS (1-on-1 Chat - M-CM-01)
CREATE TABLE conversations (
    id BIGSERIAL PRIMARY KEY,
    user_one_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_two_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    context_product_id BIGINT NULL REFERENCES products(id) ON DELETE SET NULL,
    context_order_id BIGINT NULL,
    last_message_preview VARCHAR(255) NULL,
    last_message_at TIMESTAMPTZ NULL,
    blocked_by_user_id BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_conversation_user_order CHECK (user_one_id < user_two_id),
    CONSTRAINT uq_conversation_pair UNIQUE (user_one_id, user_two_id)
);

CREATE INDEX idx_conversations_user_one ON conversations(user_one_id, last_message_at DESC);
CREATE INDEX idx_conversations_user_two ON conversations(user_two_id, last_message_at DESC);

-- 15. MESSAGES (Controlled HTTP Polling - ADR-08 & NFR-PER-03)
CREATE TABLE messages (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_text TEXT NOT NULL
        CONSTRAINT chk_messages_not_empty CHECK (LENGTH(TRIM(message_text)) > 0),
    attached_product_id BIGINT NULL REFERENCES products(id) ON DELETE SET NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_messages_polling ON messages(conversation_id, id ASC);

-- 16. NOTIFICATIONS (In-App Deep-Linked Alerts - M-NT-01)
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(40) NOT NULL,
    title VARCHAR(180) NOT NULL,
    body TEXT NOT NULL,
    target_type VARCHAR(40) NULL,
    target_id BIGINT NULL,
    deep_link_route VARCHAR(255) NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read, created_at DESC);

-- 17. PLATFORM SETTINGS (Buyer Protection Fee & Demo Mode Timers - DEC-04 & ADR-05)
CREATE TABLE platform_settings (
    key VARCHAR(80) PRIMARY KEY,
    value VARCHAR(255) NOT NULL,
    value_type VARCHAR(20) NOT NULL
        CONSTRAINT chk_settings_type CHECK (value_type IN ('DECIMAL', 'INTEGER', 'BOOLEAN', 'STRING')),
    description TEXT NOT NULL,
    updated_by BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Seed Default Platform Settings (DEC-04 & ADR-05)
INSERT INTO platform_settings (key, value, value_type, description) VALUES
('protection_fee_rate', '0.06', 'DECIMAL', 'Tỷ lệ % Phí bảo vệ người mua (Mặc định 6%, cho phép 5%-8% theo DEC-04)'),
('protection_fixed_fee', '7000', 'DECIMAL', 'Phí bảo vệ cố định VNĐ trên mỗi đơn hàng (Mặc định 7.000đ, cho phép 5k-10k theo DEC-04)'),
('shipping_fee_default', '0', 'DECIMAL', 'Phí vận chuyển thu trên ứng dụng (Cố định 0 VNĐ theo DEC-04)'),
('seller_commission_rate', '0', 'DECIMAL', 'Hoa hồng thu từ người bán (Cố định 0% - Seller nhận đủ 100% tiền hàng theo DEC-04)'),
('auction_winner_payment_deadline_minutes', '30', 'INTEGER', 'Thời hạn thanh toán đơn thắng đấu giá ở Production Mode (30 phút - BR-AU-07)'),
('demo_auction_winner_payment_deadline_minutes', '2', 'INTEGER', 'Thời hạn thanh toán đơn thắng đấu giá ở Demo Mode (2 phút - ADR-05)'),
('order_auto_complete_hours', '24', 'INTEGER', 'Thời gian tự động hoàn tất đơn sau khi DELIVERED ở Production Mode (24 giờ - BR-OR-05)'),
('demo_order_auto_complete_minutes', '2', 'INTEGER', 'Thời gian tự động hoàn tất đơn sau khi DELIVERED ở Demo Mode (2 phút - ADR-05)'),
('auction_anti_sniping_window_seconds', '120', 'INTEGER', 'Vùng nhạy cảm cuối phiên kích hoạt Anti-Sniping ở Production Mode (120 giây - BR-AU-04)'),
('auction_anti_sniping_extension_seconds', '120', 'INTEGER', 'Thời gian cộng thêm mỗi lần Anti-Sniping ở Production Mode (+120 giây)'),
('demo_auction_anti_sniping_window_seconds', '30', 'INTEGER', 'Vùng nhạy cảm Anti-Sniping ở Demo Mode (30 giây - ADR-05)'),
('demo_auction_anti_sniping_extension_seconds', '30', 'INTEGER', 'Thời gian cộng thêm Anti-Sniping ở Demo Mode (+30 giây)');

-- 18. AUDIT LOGS (Immutable Administrative & Security Trail - BR-AD-02)
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    actor_id BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    actor_role VARCHAR(30) NOT NULL,
    action VARCHAR(80) NOT NULL,
    target_type VARCHAR(50) NOT NULL,
    target_id BIGINT NULL,
    reason TEXT NULL,
    old_values JSONB NULL,
    new_values JSONB NULL,
    ip_address VARCHAR(45) NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_target ON audit_logs(target_type, target_id, created_at DESC);
CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_id, created_at DESC);
```