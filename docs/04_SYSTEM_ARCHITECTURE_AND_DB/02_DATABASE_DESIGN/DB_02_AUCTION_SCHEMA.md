# 02. SCHEDULED AUCTION & CONCURRENT BIDDING DATABASE SCHEMA – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P402B-DB-AUCTION-SCHEMA`
- **Version:** `1.0.0 (COMPLETE POSTGRESQL 18 DDL SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Target DBMS:** `PostgreSQL 18.x`
- **Phase:** `Phase 04 – System Architecture, Database Design & API Specification`
- **Compliance Ref:** `AF-01..10`, `FR-AC-01..06`, `BR-AC-02`, `BR-AU-01..07`, `DEC-02`, `ADR-05`, `ADR-06`, `NFR-REL-01`

---

## Chương 1. Kiến Trúc Lưu Trữ Đấu Giá Theo Phiên & Khóa Dòng Chống Xung Đột (`Auction Storage & Concurrency Architecture`)

Phân hệ Đấu giá theo phiên hàng ngày (`Scheduled Auction System`) được thiết kế trên 4 bảng chuyên biệt (`auction_sessions`, `auctions`, `auction_bids`, `auction_watches`) nhằm giải quyết triệt để 4 yêu cầu kỹ thuật cốt lõi:

1. **Hỗ trợ Đăng lại Sản phẩm sau khi Hết giờ hoặc Bỏ cọc (`Relisting Support via Partial Unique Index` – `DEC-02`, `AF-09`):**
   - Một sản phẩm (`product_id`) nếu kết thúc phiên mà không có người mua (`ENDED_UNSOLD`) hoặc người thắng bỏ cọc quá hạn 30 phút (`WINNER_DEFAULTED`) thì Seller được quyền đăng lại vào một phiên đấu giá mới (`AF-09`).
   - Do đó, thay vì đặt `UNIQUE(product_id)` cứng nhắc trên toàn bảng `auctions` (sẽ chặn việc tạo phiên mới khi đăng lại), hệ thống sử dụng **Partial Unique Index của PostgreSQL 18**:
     `CREATE UNIQUE INDEX uq_auctions_active_product ON auctions(product_id) WHERE status IN ('SCHEDULED', 'LIVE');`
     Điều này vừa đảm bảo **tại một thời điểm một sản phẩm chỉ có tối đa 1 phiên đang hoạt động**, vừa lưu giữ trọn vẹn lịch sử các phiên cũ (`ENDED_UNSOLD`, `WINNER_DEFAULTED`, `CANCELLED`).
2. **Tối ưu Hóa Khóa Dòng Bi Quan (`Row-Level Locking Optimization` – `BR-AU-03`, `ADR-06`):**
   - Trên bảng `auctions`, các cột `current_highest_bid`, `leading_bidder_id`, `bid_count`, `auction_ends_at` và `extended_count` được lưu trực tiếp trên dòng bản ghi phiên đấu giá.
   - Khi thực thi `SELECT * FROM auctions WHERE id = :id FOR UPDATE`, PostgreSQL khóa duy nhất dòng phiên đấu giá đó trong vài mili-giây để kiểm tra bước giá, ghi bản ghi mới vào `auction_bids`, cập nhật người dẫn đầu mới và cộng giờ Anti-Sniping (`BR-AU-04`) trong cùng một Transaction nguyên tử.
3. **Sổ Lịch Sử Đặt Giá Bất Biến (`Append-Only Bid History` – `BR-AU-02`):**
   - Bảng `auction_bids` là bảng chỉ ghi thêm (`INSERT ONLY`). Mọi lượt trả giá đã hợp lệ không bao giờ được phép sửa hoặc xóa (`NFR-REL-04`).
4. **Ràng buộc Giá Sàn và Bước Giá Ngay Từ Tầng CSDL (`Bid & Reserve Price Constraints`):**
   - Ràng buộc `CHECK` đảm bảo `starting_price > 0`, `min_bid_increment > 0`, và nếu có cài đặt `reserve_price` thì bắt buộc `reserve_price >= starting_price`.

---

## Chương 2. Đặc Tả Chi Tiết 4 Bảng Đấu Giá (`Detailed Auction Tables Specification`)

### 2.1. Bảng 1: `auction_sessions` (Khung Giờ Phiên Đấu Giá Hàng Ngày – `A-AC-01`, `AF-01`)

| Tên Cột (`Column`) | Kiểu Dữ Liệu (`Type`) | Ràng Buộc (`Constraints`) | Mặc Định (`Default`) | Mô Tả Chi Tiết & Quy Tắc Nghiệp Vụ |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Auto-increment | Khóa chính khung giờ phiên đấu giá. |
| `session_code` | `VARCHAR(40)` | `NOT NULL, UNIQUE` | — | Mã phiên (ví dụ: `SES-20261114-EVENING`). |
| `title` | `VARCHAR(120)` | `NOT NULL` | — | Tên hiển thị của phiên (ví dụ: *Phiên Tối 20:00 – 22:00*, *Phiên Đặc Biệt Giáng Sinh*). |
| `starts_at` | `TIMESTAMPTZ` | `NOT NULL` | — | Thời điểm bắt đầu mở phiên đấu giá chuẩn máy chủ (`BR-AU-01`). |
| `ends_at` | `TIMESTAMPTZ` | `NOT NULL, CHECK` | — | Thời điểm kết thúc gốc của khung giờ phiên (`CHECK (ends_at > starts_at)`). |
| `default_min_increment` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | `20000.00` | Bước giá tối thiểu gợi ý mặc định cho phiên (`> 0`). |
| `status` | `VARCHAR(20)` | `NOT NULL, CHECK` | `'ACTIVE'` | `CHECK (status IN ('ACTIVE', 'INACTIVE', 'CLOSED'))`. |
| `created_by` | `BIGINT` | `NULLABLE, FK` | `NULL` | `REFERENCES users(id) ON DELETE SET NULL` (Admin tạo phiên). |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm tạo. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm cập nhật. |

---

### 2.2. Bảng 2: `auctions` (Phiên Đấu Giá Của Từng Sản Phẩm – `M-AC-01..05`, `AF-01..10`)

| Tên Cột (`Column`) | Kiểu Dữ Liệu (`Type`) | Ràng Buộc (`Constraints`) | Mặc Định (`Default`) | Mô Tả Chi Tiết & Quy Tắc Nghiệp Vụ |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Auto-increment | Khóa chính phiên đấu giá (Target của `SELECT ... FOR UPDATE`). |
| `auction_code` | `VARCHAR(30)` | `NOT NULL, UNIQUE` | — | Mã hiển thị trên UI (ví dụ: `AUC-2026-0108`). |
| `product_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES products(id) ON DELETE RESTRICT`. |
| `seller_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES users(id) ON DELETE RESTRICT` (Chủ sở hữu sản phẩm – dùng để chặn tự đặt giá `BR-AC-02`). |
| `session_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES auction_sessions(id) ON DELETE RESTRICT`. |
| `starting_price` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | — | Giá khởi điểm (`CHECK (starting_price > 0.00)`). |
| `min_bid_increment` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | — | Bước giá tối thiểu (`CHECK (min_bid_increment > 0.00)`). |
| `reserve_price` | `NUMERIC(15,2)` | `NULLABLE, CHECK` | `NULL` | Giá sàn kỳ vọng tùy chọn (`CHECK (reserve_price IS NULL OR reserve_price >= starting_price)`). |
| `current_highest_bid` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | `0.00` | Giá cao nhất hiện tại (`0.00` khi chưa có ai bid; `>= starting_price` khi đã có bid). |
| `leading_bidder_id` | `BIGINT` | `NULLABLE, FK` | `NULL` | `REFERENCES users(id) ON DELETE SET NULL` (Người đang dẫn đầu hiện tại). |
| `winner_id` | `BIGINT` | `NULLABLE, FK` | `NULL` | `REFERENCES users(id) ON DELETE SET NULL` (Người chiến thắng chính thức khi phiên `COMPLETED`). |
| `bid_count` | `INTEGER` | `NOT NULL, CHECK` | `0` | Tổng số lượt đặt giá hợp lệ (`>= 0`). |
| `watch_count` | `INTEGER` | `NOT NULL, CHECK` | `0` | Số người dùng đang theo dõi phiên đấu giá (`>= 0`). |
| `auction_starts_at` | `TIMESTAMPTZ` | `NOT NULL` | — | Thời điểm mở nhận giá thầu (`BR-AU-01`). |
| `auction_ends_at` | `TIMESTAMPTZ` | `NOT NULL, CHECK` | — | Thời điểm đóng phiên thực tế (sẽ được cộng thêm `+2 phút` / `+30s Demo` mỗi khi kích hoạt **Anti-Sniping** `BR-AU-04`). |
| `extended_count` | `INTEGER` | `NOT NULL, CHECK` | `0` | Số lần phiên đấu giá đã được gia hạn tự động Anti-Sniping (`>= 0`). |
| `last_extended_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời điểm gần nhất kích hoạt Anti-Sniping. |
| `closed_early_by_seller` | `BOOLEAN` | `NOT NULL` | `FALSE` | Đánh dấu `TRUE` nếu Seller chủ động bấm **Chốt phiên sớm (`Close Early`)** (`BR-AU-05`, `AF-06`). |
| `status` | `VARCHAR(25)` | `NOT NULL, CHECK` | `'SCHEDULED'` | **6 Trạng thái máy trạng thái đấu giá (`P2-04`):** `CHECK (status IN ('SCHEDULED', 'LIVE', 'COMPLETED', 'ENDED_UNSOLD', 'WINNER_DEFAULTED', 'CANCELLED'))`. |
| `cancel_reason` | `TEXT` | `NULLABLE` | `NULL` | Lý do Admin hủy phiên bất thường/gian lận (`PERM-AC-09`, `AF-10`). |
| `closed_at` | `TIMESTAMPTZ` | `NULLABLE` | `NULL` | Thời điểm phiên chính thức đóng lại. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm tạo bản ghi. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm cập nhật. |

---

### 2.3. Bảng 3: `auction_bids` (Lịch Sử Trả Giá Vĩnh Viễn – `M-AC-03`, `M-AC-04`, `BR-AU-02..03`)

| Tên Cột (`Column`) | Kiểu Dữ Liệu (`Type`) | Ràng Buộc (`Constraints`) | Mặc Định (`Default`) | Mô Tả Chi Tiết & Quy Tắc Nghiệp Vụ |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Auto-increment | Khóa chính lượt trả giá. |
| `auction_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES auctions(id) ON DELETE CASCADE`. |
| `bidder_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES users(id) ON DELETE RESTRICT` (Người đặt giá – phải khác `auction.seller_id`). |
| `bid_amount` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | — | Số tiền đặt giá (`CHECK (bid_amount > 0.00)`). |
| `previous_highest_bid` | `NUMERIC(15,2)` | `NOT NULL, CHECK` | `0.00` | Giá cao nhất ngay trước lượt trả giá này (phục vụ kiểm toán). |
| `triggered_anti_sniping` | `BOOLEAN` | `NOT NULL` | `FALSE` | Đánh dấu `TRUE` nếu lượt trả giá này nằm trong 2 phút cuối và đã kích hoạt gia hạn Anti-Sniping (`AF-04`). |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm đặt giá chính xác đến mili-giây trên máy chủ. |

---

### 2.4. Bảng 4: `auction_watches` (Danh Sách Theo Dõi Phiên Đấu Giá – `M-AC-02 Watchlist`, `AF-02`)

| Tên Cột (`Column`) | Kiểu Dữ Liệu (`Type`) | Ràng Buộc (`Constraints`) | Mặc Định (`Default`) | Mô Tả Chi Tiết |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Auto-increment | Khóa chính. |
| `auction_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES auctions(id) ON DELETE CASCADE`. |
| `user_id` | `BIGINT` | `NOT NULL, FK` | — | `REFERENCES users(id) ON DELETE CASCADE`. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Thời điểm bấm theo dõi phiên (`UNIQUE (auction_id, user_id)`). |

---

## Chương 3. Mã Lệnh Khởi Tạo SQL Chuẩn PostgreSQL 18 (`Complete SQL DDL Script – DB_02`)

```sql
-- ============================================================================
-- RETRO MARKET (izithrift) - DB_02: SCHEDULED AUCTION & BIDDING SCHEMA
-- Target DBMS: PostgreSQL 18.x | Concurrency: Pessimistic Row-Level Locking
-- ============================================================================

-- 1. AUCTION SESSIONS (Daily Configured Time Slots - A-AC-01)
CREATE TABLE auction_sessions (
    id BIGSERIAL PRIMARY KEY,
    session_code VARCHAR(40) NOT NULL UNIQUE,
    title VARCHAR(120) NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL
        CONSTRAINT chk_auction_sessions_time_order CHECK (ends_at > starts_at),
    default_min_increment NUMERIC(15, 2) NOT NULL DEFAULT 20000.00
        CONSTRAINT chk_auction_sessions_min_inc CHECK (default_min_increment > 0.00),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CONSTRAINT chk_auction_sessions_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'CLOSED')),
    created_by BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_auction_sessions_window ON auction_sessions(status, starts_at ASC, ends_at ASC);

-- 2. AUCTIONS (Individual Item Auction Lifecycle - AF-01..10)
CREATE TABLE auctions (
    id BIGSERIAL PRIMARY KEY,
    auction_code VARCHAR(30) NOT NULL UNIQUE,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    seller_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    session_id BIGINT NOT NULL REFERENCES auction_sessions(id) ON DELETE RESTRICT,
    starting_price NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_auctions_starting_price CHECK (starting_price > 0.00),
    min_bid_increment NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_auctions_min_increment CHECK (min_bid_increment > 0.00),
    reserve_price NUMERIC(15, 2) NULL
        CONSTRAINT chk_auctions_reserve_price CHECK (reserve_price IS NULL OR reserve_price >= starting_price),
    current_highest_bid NUMERIC(15, 2) NOT NULL DEFAULT 0.00
        CONSTRAINT chk_auctions_current_bid CHECK (
            current_highest_bid = 0.00 OR current_highest_bid >= starting_price
        ),
    leading_bidder_id BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    winner_id BIGINT NULL REFERENCES users(id) ON DELETE SET NULL,
    bid_count INTEGER NOT NULL DEFAULT 0
        CONSTRAINT chk_auctions_bid_count CHECK (bid_count >= 0),
    watch_count INTEGER NOT NULL DEFAULT 0
        CONSTRAINT chk_auctions_watch_count CHECK (watch_count >= 0),
    auction_starts_at TIMESTAMPTZ NOT NULL,
    auction_ends_at TIMESTAMPTZ NOT NULL
        CONSTRAINT chk_auctions_time_window CHECK (auction_ends_at > auction_starts_at),
    extended_count INTEGER NOT NULL DEFAULT 0
        CONSTRAINT chk_auctions_extended_count CHECK (extended_count >= 0),
    last_extended_at TIMESTAMPTZ NULL,
    closed_early_by_seller BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(25) NOT NULL DEFAULT 'SCHEDULED'
        CONSTRAINT chk_auctions_status CHECK (
            status IN ('SCHEDULED', 'LIVE', 'COMPLETED', 'ENDED_UNSOLD', 'WINNER_DEFAULTED', 'CANCELLED')
        ),
    cancel_reason TEXT NULL,
    closed_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_auctions_no_seller_self_lead CHECK (leading_bidder_id IS NULL OR leading_bidder_id <> seller_id),
    CONSTRAINT chk_auctions_no_seller_self_win CHECK (winner_id IS NULL OR winner_id <> seller_id)
);

-- Partial Unique Index: A product can only have ONE active (SCHEDULED or LIVE) auction at a time,
-- while allowing Seller to Relist after ENDED_UNSOLD or WINNER_DEFAULTED (DEC-02 & AF-09).
CREATE UNIQUE INDEX uq_auctions_active_product
    ON auctions(product_id)
    WHERE status IN ('SCHEDULED', 'LIVE');

-- Performance Indexes for Auction Hub Tabs & Scheduler Jobs
CREATE INDEX idx_auctions_status_ends_at ON auctions(status, auction_ends_at ASC);
CREATE INDEX idx_auctions_status_starts_at ON auctions(status, auction_starts_at ASC);
CREATE INDEX idx_auctions_leading_bidder ON auctions(leading_bidder_id, status);
CREATE INDEX idx_auctions_winner ON auctions(winner_id, status);

-- 3. AUCTION BIDS (Append-Only Permanent Bid History - BR-AU-02)
CREATE TABLE auction_bids (
    id BIGSERIAL PRIMARY KEY,
    auction_id BIGINT NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    bidder_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    bid_amount NUMERIC(15, 2) NOT NULL
        CONSTRAINT chk_auction_bids_amount_positive CHECK (bid_amount > 0.00),
    previous_highest_bid NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    triggered_anti_sniping BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_auction_bids_auction_amount ON auction_bids(auction_id, bid_amount DESC, created_at ASC);
CREATE INDEX idx_auction_bids_bidder_history ON auction_bids(bidder_id, created_at DESC);

-- 4. AUCTION WATCHES (Watchlist - M-AC-02)
CREATE TABLE auction_watches (
    id BIGSERIAL PRIMARY KEY,
    auction_id BIGINT NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_auction_watches_user UNIQUE (auction_id, user_id)
);

CREATE INDEX idx_auction_watches_user ON auction_watches(user_id, created_at DESC);
```