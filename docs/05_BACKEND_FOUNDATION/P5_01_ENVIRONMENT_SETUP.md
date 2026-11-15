# 01. ENVIRONMENT SETUP & LARAVEL INITIALIZATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P501-ENV-SETUP`
- **Version:** `1.0.0`
- **Status:** `DONE / APPROVED`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 05 – Backend Foundation & Database Implementation (Task P5-01)`
- **Compliance Ref:** `SYSTEM_ARCHITECTURE.md`, `C4_MODEL_DIAGRAMS.md`, `ADR-01..08`, `NFR-ENV-01..02`

---

## Chương 1. Kiến Trúc Môi Trường Phát Triển & Ma Trận Tương Thích (`Runtime Compatibility Matrix`)

| Thành Phần Hạ Tầng | Phiên Bản Chuẩn | Container / Package Name | Cổng Giao Tiếp (`Port`) | Vai Trò & Ràng Buộc Kỹ Thuật |
| :--- | :---: | :--- | :---: | :--- |
| **PHP Runtime** | `PHP 8.3+` (`8.4-FPM`) | `php:8.4-fpm-alpine` (hoặc Local PHP 8.3/8.4) | `9000` / `8000` | Bắt buộc bật extensions: `pdo_pgsql`, `pgsql`, `redis`, `bcmath`, `gd`, `intl`, `mbstring`, `zip`. (`bcmath` dùng để tính toán chính xác tiền tệ `NUMERIC(15,2)`). |
| **Backend Framework** | `Laravel 13.x` | `laravel/framework: ^13.0` | `8000` | Phục vụ đồng thời REST API (`/api/v1/*` qua `laravel/sanctum`) và Admin Dashboard (`/admin/*` qua Laravel Blade SSR). |
| **Primary Database** | `PostgreSQL 18.x` | `postgres:18-alpine` | `5432` | CSDL quan hệ chuẩn ACID, lưu trữ đúng 30 bảng nghiệp vụ với bộ mã `UTF8` và múi giờ `Asia/Ho_Chi_Minh`. |
| **Cache & Queue Broker** | `Redis 7.4.x` | `redis:7.4-alpine` | `6379` | Lưu trữ Session, Cache `platform_settings`, Rate Limiting và hàng đợi Background Jobs (`TECH-05`). |
| **Local SMTP Server** | `Mailpit` | `axllent/mailpit:latest` | `1025` (SMTP)<br>`8025` (Web UI) | Bắt và hiển thị email khôi phục mật khẩu (`M-AU-05`) ở môi trường phát triển cục bộ (`ASM-04`). |

---

## Chương 2. Cấu Hình Docker Compose (`docker-compose.yml`)

File `docker-compose.yml` đặt tại thư mục gốc của dự án (`RETRO_MARKET/docker-compose.yml`) cung cấp lập tức PostgreSQL 18, Redis 7.4 và Mailpit có gắn Healthcheck tự động:

```yaml
services:
  postgres:
    image: postgres:18-alpine
    container_name: retromarket_postgres18
    restart: unless-stopped
    environment:
      POSTGRES_DB: retromarket_db
      POSTGRES_USER: retromarket_user
      POSTGRES_PASSWORD: retromarket_secret_2026
      TZ: Asia/Ho_Chi_Minh
      PGTZ: Asia/Ho_Chi_Minh
    ports:
      - "5432:5432"
    volumes:
      - pg18_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U retromarket_user -d retromarket_db"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7.4-alpine
    container_name: retromarket_redis7
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes"]
    ports:
      - "6379:6379"
    volumes:
      - redis7_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  mailpit:
    image: axllent/mailpit:latest
    container_name: retromarket_mailpit
    restart: unless-stopped
    ports:
      - "1025:1025"
      - "8025:8025"

volumes:
  pg18_data:
  redis7_data:
```

---

## Chương 3. Cấu Trúc Thư Mục Chuẩn Hóa Của Backend Laravel (`backend/` Directory Architecture)

Để đảm bảo phân tách rõ ràng giữa REST API cho Flutter (`izithrift`), Web SSR cho Admin Dashboard và các Domain Services có tính lũy đẳng dùng chung cho cả Cron Jobs lẫn Developer Tools (`ADR-02`, `ADR-05`), thư mục `backend/` được tổ chức như sau:

```text
RETRO_MARKET/
├── docs/                                  # Toàn bộ hồ sơ thiết kế Phase 00 -> Phase 05
├── docker-compose.yml                     # Hạ tầng PostgreSQL 18 + Redis 7.4 + Mailpit
└── backend/                               # Mã nguồn Laravel 13 Backend Application
    ├── app/
    │   ├── Actions/                       # Các tác vụ nguyên tử đơn lẻ (Single-Action Classes)
    │   ├── Console/
    │   │   └── Commands/
    │   │       └── SystemHealthCheckCommand.php  # Lệnh kiểm tra kết nối PG18, Redis & Cấu hình
    │   ├── Enums/                         # PHP 8.3+ Backed Enums cho 4 State Machines & Roles
    │   │   ├── UserRole.php
    │   │   ├── UserStatus.php
    │   │   ├── ProductCondition.php
    │   │   ├── ProductStatus.php
    │   │   ├── AuctionStatus.php
    │   │   ├── OrderStatus.php
    │   │   ├── PaymentStatus.php
    │   │   ├── EscrowStatus.php
    │   │   └── DisputeStatus.php
    │   ├── Exceptions/                    # Xử lý mã lỗi Domain (409 Conflict, 403 Self-Transaction...)
    │   ├── Http/
    │   │   ├── Controllers/
    │   │   │   ├── Api/V1/                # Controllers phục vụ Flutter Mobile App (/api/v1/*)
    │   │   │   └── Admin/                 # Controllers phục vụ Laravel Blade Admin (/admin/*)
    │   │   ├── Middleware/
    │   │   │   ├── EnsureUserIsActive.php         # Kiểm tra users.status == ACTIVE (BR-AC-04)
    │   │   │   ├── EnsureInternalRole.php         # Kiểm tra RBAC Admin/Moderator/Support
    │   │   │   └── EnsureDemoModeEnabled.php      # Bảo vệ /admin/dev-tools (NFR-ENV-02)
    │   │   ├── Requests/
    │   │   │   ├── Api/V1/                # FormRequest validation cho Mobile API
    │   │   │   └── Admin/                 # FormRequest validation cho Admin Web
    │   │   └── Resources/
    │   │       └── Api/V1/                # JSON Resources chuẩn hóa kèm server_time
    │   ├── Jobs/                          # 4 Scheduled Background Jobs (P4-04C)
    │   ├── Models/                        # 30 Eloquent Models tương ứng 30 bảng PostgreSQL 18
    │   ├── Policies/                      # Thực thi 61 quyền trong 03_ACTOR_PERMISSION_MATRIX.md
    │   ├── Services/                      # Trái tim nghiệp vụ (Dùng chung cho API, Admin & Jobs)
    │   │   ├── Auction/
    │   │   │   ├── AuctionBiddingService.php      # Xử lý đặt giá lockForUpdate() & Anti-Sniping
    │   │   │   └── AuctionLifecycleService.php    # Mở/Đóng phiên & Tạo đơn thắng đấu giá
    │   │   ├── Order/
    │   │   │   ├── CheckoutService.php            # Tính Buyer Protection Fee & Tạo đơn Snapshot
    │   │   │   ├── OrderCancellationService.php   # Hủy đơn 3 cấp (DEC-06) & Hoàn 100% (DEC-07)
    │   │   │   └── OrderExpirationService.php     # Hủy đơn quá hạn 30 phút (DEC-02)
    │   │   ├── Escrow/
    │   │   │   ├── MockQrPaymentService.php       # Giữ tiền ESCROW_HELD lũy đẳng (BR-FN-03)
    │   │   │   └── EscrowReleaseService.php       # Giải ngân 100% item_subtotal & Phân xử Dispute
    │   │   └── Governance/
    │   │       ├── ProductModerationService.php   # Duyệt/Từ chối sản phẩm (DEC-05)
    │   │       └── AuditLogService.php            # Ghi vết audit_logs bất biến (BR-AD-02)
    │   └── Support/
    │       └── ApiResponse.php            # Helper sinh JSON Envelope chuẩn kèm server_time
    ├── bootstrap/
    │   └── app.php                        # Đăng ký API routes, Admin routes, Middleware & Exceptions
    ├── config/
    │   └── retromarket.php                # Cấu hình đặc thù (DEMO_MODE, Upload limits <= 5MB)
    ├── database/
    │   ├── factories/
    │   ├── migrations/                    # 30 bảng PostgreSQL 18 + Constraints (P5-02 & P5-03)
    │   └── seeders/                       # Dữ liệu mẫu có chủ đích (P5-05)
    ├── resources/
    │   └── views/
    │       └── admin/                     # Giao diện Laravel Blade Admin Dashboard (Phase 03 P3-06)
    └── routes/
        ├── api.php                        # Định tuyến /api/v1/*
        ├── web.php                        # Định tuyến /admin/*
        └── console.php                    # Định tuyến Laravel Scheduler mỗi phút
```

---

## Chương 4. Quy Chuẩn Biến Môi Trường (`.env` & `config/retromarket.php`)

Các thông số bắt buộc trong `backend/.env` và `backend/.env.example`:

```ini
APP_NAME="Retro Market (izithrift)"
APP_ENV=local
APP_DEBUG=true
APP_TIMEZONE=Asia/Ho_Chi_Minh
APP_URL=http://localhost:8000
APP_LOCALE=vi
APP_FALLBACK_LOCALE=en

# Chế độ trình diễn bảo vệ đồ án (ADR-05 & NFR-ENV-02)
DEMO_MODE=true

# Kết nối PostgreSQL 18 (TECH-01 & TECH-03)
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=retromarket_db
DB_USERNAME=retromarket_user
DB_PASSWORD=retromarket_secret_2026
DB_CHARSET=utf8

# Chuyển toàn bộ Session, Cache & Queue sang Redis 7.4 để giữ sạch 30 bảng PG18 (TECH-05)
SESSION_DRIVER=redis
CACHE_STORE=redis
QUEUE_CONNECTION=redis

REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# Cấu hình Mailpit cục bộ phục vụ Reset Password (ASM-04)
MAIL_MAILER=smtp
MAIL_HOST=127.0.0.1
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="no-reply@izithrift.local"
MAIL_FROM_NAME="${APP_NAME}"

# Giới hạn Upload <= 5MB (NFR-SEC-05)
FILESYSTEM_DISK=public
RETRO_MAX_UPLOAD_KB=5120
```

---

## Chương 5. Tiêu Chí Nghiệm Thu & Các Bước Kiểm Tra `P5-01` (`Acceptance Criteria & Verification Steps`)

- [x] **AC-P501-01 (PHP & Extensions):** Phiên bản PHP đạt `>= 8.3` (thực tế `PHP 8.4.27`), các extension `pdo_pgsql`, `bcmath`, `intl`, `gd`, `mbstring`, `zip` đã được kích hoạt.
- [x] **AC-P501-02 (PostgreSQL 18 Connection):** Laravel kết nối thành công tới PostgreSQL 18 (thực tế `PostgreSQL 18.7 on x86_64-pc-linux-musl`), encoding `UTF8` và `SHOW TIMEZONE` trả về `+07:00`.
- [x] **AC-P501-03 (Redis 7 Connection):** Laravel Cache/Queue kết nối thành công tới Redis 7.4 qua driver `predis` (`Cache::store('redis')->put/get/forget` hoạt động hoàn hảo).
- [x] **AC-P501-04 (Architecture Scaffolding):** Cây thư mục `Enums`, `Services`, `Policies`, `Support/ApiResponse.php`, `config/retromarket.php` và lệnh `php artisan system:health-check` hoạt động hoàn hảo, trả về trạng thái `ALL SYSTEMS GO (PASS)`.

---

## Chương 6. Kết Quả Kiểm Tra Thực Tế Lệnh `php artisan system:health-check`

```text
===============================================================================
 IZITHRIFT (RETRO MARKET) - SYSTEM HEALTH CHECK - TASK P5-01
===============================================================================
+------------------------+-----------------------------------------------------------------------------------------+--------+
| Component              | Detail                                                                                  | Status |
+------------------------+-----------------------------------------------------------------------------------------+--------+
| PHP Runtime            | PHP 8.4.27 | Laravel 13.42.0                                                            | OK     |
| PHP Extensions         | pdo_pgsql, pgsql, bcmath, gd, intl, mbstring, zip                                       | OK     |
| App Timezone           | Asia/Ho_Chi_Minh                                                                        | OK     |
| Demo Mode              | ENABLED (true)                                                                          | OK     |
| PostgreSQL 18          | PostgreSQL 18.7 on x86_64-pc-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit | OK     |
| PG Encoding / Timezone | Encoding: UTF8 | TimeZone: +07:00                                                       | OK     |
| Redis 7.4 (Predis)     | Cache Put/Get/Delete Verified (Connection OK)                                           | OK     |
| Public Storage         | Disk: public | Read/Write Verified                                                      | OK     |
+------------------------+-----------------------------------------------------------------------------------------+--------+

✅ ALL SYSTEMS GO (PASS): Toàn bộ hạ tầng PostgreSQL 18, Redis 7.4, PHP 8.4 & Laravel 13 đã sẵn sàng cho Task P5-02!
```
