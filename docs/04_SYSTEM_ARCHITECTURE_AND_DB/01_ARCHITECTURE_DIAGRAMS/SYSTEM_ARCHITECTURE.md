# 01. SYSTEM ARCHITECTURE SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P401A-SYSTEM-ARCH`
- **Version:** `1.0.0`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 04 – System Architecture, Database Design & API Specification`
- **Compliance Ref:** `ADR-01..08`, `NFR-PER-01..03`, `NFR-SEC-01..05`, `NFR-REL-01..04`

---

## Chương 1. Tầm Nhìn Kiến Trúc Tổng Thể (`Architecture Vision`)

Kiến trúc hệ thống của **Retro Market (`izithrift`)** được thiết kế theo mô hình **Client-Server đa lớp (N-Tier Architecture)**, tập trung giải quyết 3 bài toán đặc thù của một nền tảng C2C Secondhand Marketplace có tích hợp Đấu giá và Escrow:
1. **Toàn vẹn Tài chính Tuyệt đối (`Strict Financial Integrity`):** Mọi giao dịch thay đổi số dư ví, tiền giữ trong Escrow, và kết quả trả giá thầu (Bids) đều phải tuân thủ tính chất ACID của cơ sở dữ liệu quan hệ (RDBMS).
2. **Kiểm soát Xung đột Đồng thời (`Concurrency Control`):** Đảm bảo không bao giờ xảy ra tình trạng bán lố hàng (`Overselling`) hoặc ghi nhận trùng lặp mức giá khi có hàng chục người cùng nhấn nút Mua/Đặt giá tại cùng một mili-giây.
3. **Phân tách Rõ Rệt Frontend (`Separation of Concerns`):** Giao diện người dùng phổ thông (Mobile App) được tách biệt hoàn toàn qua REST API, trong khi Giao diện Quản trị (Admin Dashboard) được render trực tiếp tại Server (Server-Side Rendering) để tối ưu tốc độ phát triển và quản lý phân quyền nội bộ an toàn.

---

## Chương 2. Lựa Chọn Công Nghệ (`Technology Stack`)

| Phân Lớp (`Layer`) | Công Nghệ Lựa Chọn | Phiên Bản Dự Kiến | Lý Do Lựa Chọn & Vai Trò Trong Hệ Thống |
| :--- | :--- | :---: | :--- |
| **Mobile Client** | **Flutter** | `3.x` | Xây dựng ứng dụng đa nền tảng (iOS/Android) từ một codebase. Xử lý UI High-Fidelity, quản lý trạng thái (`State Management` - BLoC/Riverpod), gọi REST API bằng `Dio`, và xử lý HTTP Polling cho Chat/Đấu giá (`ADR-08`). |
| **Admin Web Client** | **Laravel Blade** | N/A | Server-Side Rendering (SSR). Giao tiếp trực tiếp với nội bộ hệ thống Laravel, không cần qua REST API. Sử dụng Bootstrap/TailwindCSS để dàn trang Bảng dữ liệu và Split-Pane nhanh chóng (`ADR-02`). |
| **Backend / API** | **PHP / Laravel** | `11.x` / `13.x` | Cung cấp RESTful API chuẩn hóa cho Mobile. Quản lý Authentication (Sanctum), Phân quyền (`Gate/Policy`), Routing, Business Logic Services, và Background Jobs. |
| **Database (RDBMS)** | **PostgreSQL** | `18.x` | Trái tim của hệ thống. Đảm bảo toàn vẹn dữ liệu chuẩn ACID, hỗ trợ tính năng Khóa dòng (`Row-Level Locking`) ưu việt, và kiểu dữ liệu `JSONB` cho Audit Logs/Snapshot. |
| **Cache & Queue** | **Redis** | `7.x` | Lưu trữ Rate Limit, Cache cấu hình hệ thống (`platform_settings`), và làm Message Broker cho Laravel Horizon xử lý các tiến trình nền (Background Jobs). |
| **File Storage** | **Local Disk / S3** | N/A | Lưu trữ ảnh sản phẩm, ảnh bằng chứng khiếu nại (giới hạn $\le 5\text{MB}$/ảnh) (`NFR-SEC-05`). |

---

## Chương 3. Cơ Chế Xử Lý Xung Đột & Toàn Vẹn Dữ Liệu (`Concurrency & Data Integrity Mechanisms`)

Để đáp ứng yêu cầu khắc nghiệt của đồ án (`RSK-01`), hệ thống áp dụng cơ chế **Pessimistic Locking (Khóa bi quan)** tại tầng Database thông qua hàm `lockForUpdate()` của Laravel (tương đương lệnh `SELECT ... FOR UPDATE` trong PostgreSQL).

### 3.1. Kịch Bản 1: Chống Race Condition Khi Đặt Giá Thầu (`Auction Bidding`)
- Khi người mua A và B cùng gửi API `POST /auctions/10/bids` với mức giá `900.000đ` tại cùng 1 thời điểm.
- **Xử lý:** Transaction của người đến trước (A) sẽ khóa dòng bản ghi `id = 10` trong bảng `auctions`. Transaction của B phải chờ. Sau khi A ghi giá `900.000đ` thành công và nhả khóa, Transaction của B sẽ đọc lại giá mới nhất, nhận thấy `900.000đ` không còn hợp lệ (nhỏ hơn bước giá mới) nên sẽ tự động Rollback và trả về lỗi `409 Conflict`. Hệ thống hoàn toàn không phụ thuộc vào tốc độ xử lý của RAM/PHP.

### 3.2. Kịch Bản 2: Chống Overselling Khi Đặt Mua Giá Cố Định (`Fixed-Price Checkout`)
- Khi người mua A và B cùng bấm thanh toán mua 1 chiếc túi duy nhất (`available_quantity = 1`).
- **Xử lý:** `SELECT * FROM products WHERE id = X FOR UPDATE`. Người đến sau sẽ đọc thấy `available_quantity = 0` và tự động Rollback giao dịch đặt hàng, trả mã `409 Conflict`.

### 3.3. Kịch Bản 3: Chống Double-Payment & Giải Ngân Trùng (`Idempotent Escrow`)
- Do giao diện Thanh toán QR và nút Admin là mô phỏng, người dùng có thể bấm đúp (Double-click) hoặc gửi nhiều request mạng cùng lúc.
- **Xử lý tính lũy đẳng (`Idempotency`):** Trong `EscrowService` và `PaymentService`, hệ thống luôn khóa dòng `orders` trước khi sinh bút toán. Nếu kiểm tra thấy `payment_status` đã là `PAID` hoặc `escrow_status` đã là `RELEASED`, hệ thống sẽ lập tức thoát vòng lặp mà không sinh ra dòng bút toán thứ hai, đảm bảo phương trình kế toán bất biến (`BR-FN-07`).

---

## Chương 4. Kiến Trúc Đồng Bộ Thời Gian Thực (`Real-Time Synchronization`)

Tuân thủ `ADR-08` và `NFR-PER-03`, nhằm tối ưu hóa tài nguyên server mô phỏng đồ án mà vẫn đảm bảo trải nghiệm tức thì:
- **Tính năng Chat 1-1 (`M-CM-02`):** Dùng cơ chế **Controlled HTTP Short-Polling**. Ứng dụng Flutter sẽ tự động gọi API `GET /messages?after_id=...` mỗi `3–5 giây` KHI VÀ CHỈ KHI màn hình Chat đang mở (`AppLifecycleState.resumed`). Ngay khi người dùng thoát màn hình hoặc ẩn app, Timer sẽ bị hủy (`dispose`) để không gây nghẽn Server.
- **Trạng thái Đấu giá (`M-AC-03`):** Khi ở màn hình phòng đấu giá, Mobile App sẽ gọi API làm mới (`Refresh`) giá cao nhất và mốc `auction_ends_at` mỗi `5 giây`. Nếu phát hiện có người vượt giá hoặc mốc thời gian bị đẩy lùi do Anti-Sniping, UI sẽ tự động cập nhật.

---

## Chương 5. Chiến Lược Xử Lý Tác Vụ Nền (`Background Jobs & Scheduler`)

Hệ thống Laravel Scheduler (Cron) kết hợp Redis Worker sẽ đóng vai trò như một tác nhân tự động (`ACT-06`) để thực thi các nghiệp vụ phụ thuộc thời gian:
1. `OpenScheduledAuctionsJob`: Chạy mỗi phút. Tìm các phiên `SCHEDULED` có giờ mở $\le$ hiện tại $\rightarrow$ Chuyển sang `LIVE`.
2. `CloseExpiredAuctionsJob`: Chạy mỗi phút. Tìm các phiên `LIVE` hết giờ $\rightarrow$ Đóng phiên & Sinh đơn hàng cho người thắng.
3. `ExpireUnpaidAuctionOrdersJob`: Chạy mỗi phút. Tìm các đơn đấu giá `UNPAID` quá hạn 30 phút $\rightarrow$ Hủy đơn (`CANCELLED`) & Chuyển phiên sang `WINNER_DEFAULTED`.
4. `AutoCompleteDeliveredOrdersJob`: Chạy mỗi phút. Quét đơn `DELIVERED` quá hạn 24 giờ, không có `DISPUTE` $\rightarrow$ Chuyển `COMPLETED` & Giải ngân `ESCROW_RELEASED`.

*(Trong quá trình bảo vệ đồ án, toàn bộ 4 Jobs này có thể được kích hoạt bằng tay thông qua nút bấm lũy đẳng trên Admin Developer Tools `A-DT-01`).*