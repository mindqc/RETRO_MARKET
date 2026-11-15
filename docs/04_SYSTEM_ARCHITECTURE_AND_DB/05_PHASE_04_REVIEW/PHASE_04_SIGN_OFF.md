# 01. PHASE 04 REVIEW & SIGN-OFF – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P405-PHASE04-SIGNOFF`
- **Version:** `1.0.0 (FINAL APPROVED & SELF-VERIFIED)`
- **Status:** `DONE`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 04 – System Architecture, Database Design & API Specification`

---

## Chương 1. Danh Mục Hồ Sơ Bàn Giao Của Phase 04 (`Phase 04 Deliverables Inventory`)

Toàn bộ **10 tài liệu kỹ thuật** thuộc thư mục `docs/04_SYSTEM_ARCHITECTURE_AND_DB/` (tương ứng với 5 gói công việc từ `P4-01` đến `P4-05`) đã được hoàn thiện đầy đủ ở phiên bản `v1.0.0` không cắt lược:

| STT | Task ID | Đường Dẫn File Tài Liệu | Mã Tài Liệu | Phạm Vi Kỹ Thuật Đã Đặc Tả | Trạng Thái |
| :-: | :---: | :--- | :--- | :--- | :---: |
| 01 | `P4-01` | `01_ARCHITECTURE_DIAGRAMS/SYSTEM_ARCHITECTURE.md` | `DOC-P401A-SYSTEM-ARCH` | Kiến trúc N-Tier (Flutter + Laravel + PostgreSQL 18 + Redis), Pessimistic Locking (`FOR UPDATE`), HTTP Polling | `DONE` ✅ |
| 02 | `P4-01` | `01_ARCHITECTURE_DIAGRAMS/C4_MODEL_DIAGRAMS.md` | `DOC-P401B-C4-MODELS` | Sơ đồ C4 Level 1 (System Context), Level 2 (Containers), Level 3 (Components) bằng Mermaid | `DONE` ✅ |
| 03 | `P4-02` | `02_DATABASE_DESIGN/DB_01_CORE_SCHEMA.md` | `DOC-P402A-DB-CORE-SCHEMA` | Đặc tả & SQL DDL cho 18 bảng Core: Auth, Unified Profiles, Catalog, Products, Moderation, Chat, Settings, Audit | `DONE` ✅ |
| 04 | `P4-02` | `02_DATABASE_DESIGN/DB_02_AUCTION_SCHEMA.md` | `DOC-P402B-DB-AUCTION-SCHEMA` | Đặc tả & SQL DDL cho 4 bảng Đấu giá (`auction_sessions`, `auctions`, `auction_bids`, `auction_watches`) + Partial Index | `DONE` ✅ |
| 05 | `P4-03` | `02_DATABASE_DESIGN/DB_03_ORDER_ESCROW_SCHEMA.md` | `DOC-P403A-DB-ORDER-ESCROW-SCHEMA` | Đặc tả & SQL DDL cho 12 bảng Giao dịch: Cart, Orders (4-state), Snapshot, Payments, Escrow, Wallet, Disputes, Reviews | `DONE` ✅ |
| 06 | `P4-03` | `02_DATABASE_DESIGN/ERD_RELATIONSHIPS.md` | `DOC-P403B-ERD-RELATIONSHIPS` | Sơ đồ `erDiagram` 30 bảng tổng thể, Ma trận `ON DELETE` Policy & Truy vết Business Rules $\leftrightarrow$ SQL Constraints | `DONE` ✅ |
| 07 | `P4-04` | `03_API_SPECIFICATIONS/REST_API_GUIDELINES.md` | `DOC-P404A-REST-API-GUIDELINES` | Chuẩn JSON Envelope (`server_time`), Sanctum Auth Guard, Từ điển `error_code` (`409 Conflict`), Rate Limiting | `DONE` ✅ |
| 08 | `P4-04` | `03_API_SPECIFICATIONS/API_ENDPOINTS_LIST.md` | `DOC-P404B-API-ENDPOINTS` | Danh mục đầy đủ REST API `/api/v1/*` (49 màn hình Mobile) & Web SSR Routes `/admin/*` (21 màn hình Admin) | `DONE` ✅ |
| 09 | `P4-04` | `04_BACKGROUND_JOBS_AND_SERVICES/CRON_JOBS_WORKERS.md` | `DOC-P404C-CRON-JOBS-WORKERS` | Đặc tả 4 Scheduled Jobs & Domain Services lũy đẳng (`FOR UPDATE SKIP LOCKED`) dùng chung cho Cron & Demo Mode | `DONE` ✅ |
| 10 | `P4-05` | `05_PHASE_04_REVIEW/PHASE_04_SIGN_OFF.md` | `DOC-P405-PHASE04-SIGNOFF` | Biên bản Kiểm tra Cổng Chất lượng & Nghiệm thu Phase 04 | `DONE` ✅ |

---

## Chương 2. Kiểm Tra Điều Kiện Qua Cổng Chất Lượng Phase 04 (`Phase 04 Exit Criteria Verification`)

- [x] **Gate 1 – Toàn vẹn Kiểu dữ liệu Tiền tệ & Thời gian (`Monetary & Temporal Precision`):**
  - 100% các cột tiền tệ trên toàn bộ 30 bảng đều dùng `NUMERIC(15, 2)` kèm ràng buộc `CHECK (>= 0)` (không dùng `FLOAT`/`DOUBLE`).
  - 100% các cột mốc thời gian dùng `TIMESTAMPTZ` đồng bộ theo giờ máy chủ, có trả về `server_time` trong mọi API JSON Envelope (`BR-AU-01`).
- [x] **Gate 2 – Bảo chứng Nghiệp vụ Cấp độ Cơ sở dữ liệu (`Database-Enforced Business Rules`):**
  - Chặn tự giao dịch (`BR-AC-02`): Có `CHECK (buyer_id <> seller_id)` trên `orders`, `CHECK (leading_bidder_id <> seller_id)` trên `auctions`, `CHECK (reviewer_id <> seller_id)` trên `reviews` và `CHECK (follower_id <> seller_id)` trên `seller_follows`.
  - Phương trình tài chính `DEC-04` & `DEC-07`: Được khóa cứng bằng `chk_orders_total_equation`, `chk_orders_seller_net_100_percent` và `chk_escrow_accounting_balance`.
  - Hỗ trợ đăng lại hàng đấu giá sau khi hết giờ/bỏ cọc (`DEC-02`): Được giải quyết bằng Partial Unique Index `uq_auctions_active_product WHERE status IN ('SCHEDULED', 'LIVE')`.
  - Chống thanh toán trùng & giải ngân trùng (`BR-FN-03`, `BR-FN-07`): Được bảo vệ bằng `uq_payments_one_paid_per_order WHERE status = 'PAID'` và khóa `UNIQUE(order_id)` trên `wallet_transactions`.
- [x] **Gate 3 – Khớp nối 100% Giữa 70 Màn Hình UI (Phase 03) và API / Routes (Phase 04):**
  - Toàn bộ 49 màn hình & modal trên ứng dụng Flutter (`M-*`) và 21 màn hình trên Laravel Blade Admin (`A-*`) đều đã có Endpoint/Route, Request Payload, Validation Rules và Response Contract tương ứng.
- [x] **Gate 4 – Sẵn sàng cho Lập trình Backend & Mobile (`Implementation Readiness`):**
  - Toàn bộ câu lệnh SQL `CREATE TABLE` và `CREATE INDEX` đã hợp lệ theo chuẩn PostgreSQL 18, sẵn sàng chuyển hóa thành Laravel Migrations, Models, Services và Controllers.

---

## Chương 3. Xác Nhận Nghiệm Thu & Mở Khóa Giai Đoạn Tiếp Theo (`Formal Phase Sign-Off`)

- **Kết luận:** **Phase 04 – System Architecture, Database Design & API Specification** đã hoàn thành 100% (5/5 Tasks – `100% DONE`).
- **Giai đoạn Mở khóa Tiếp theo:** Chính thức mở khóa giai đoạn triển khai mã nguồn thực tế (**Phase 05 / Phase 06 – Backend Environment Setup, Database Migrations, Seeders & Core API Implementation**).