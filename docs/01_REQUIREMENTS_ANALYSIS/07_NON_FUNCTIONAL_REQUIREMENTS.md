# 07. NON-FUNCTIONAL REQUIREMENTS – RETRO MARKET (izithrift)

- **Document ID:** `DOC-PA06-NFR`
- **Version:** `1.1.0 (FINAL APPROVED)`
- **Status:** `DONE`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 01 – Project Discovery & Requirement Analysis`

---

## 1. Quy Ước Định Danh & Tiêu Chuẩn Đo Lường (NFR Conventions)
Mỗi yêu cầu phi chức năng trong tài liệu này được gán mã `NFR-<NHÓM>-<SỐ>` kèm theo **Tiêu chí nghiệm thu kỹ thuật (Acceptance Metric)** và **Phương pháp kiểm chứng (Verification Method)** để phục vụ trực tiếp cho Phase 13 (`Integration Testing & QA`).

---

## 2. Bảo Mật & Kiểm Soát Truy Cập (Security & Access Control – `NFR-SEC`)

| Mã NFR | Tên Yêu Cầu | Đặc Tả Kỹ Thuật & Tiêu Chí Nghiệm Thu | Phương Pháp Kiểm Chứng |
| :--- | :--- | :--- | :--- |
| `NFR-SEC-01` | Bảo mật Mật khẩu & Xác thực Token | - Mật khẩu người dùng bắt buộc băm bằng thuật toán `Bcrypt` hoặc `Argon2id` của Laravel 13; tuyệt đối không lưu plain text hoặc trả về trường `password` trong bất kỳ JSON response nào.<br>- Access Token của `Laravel Sanctum` trên ứng dụng Flutter bắt buộc lưu trong `flutter_secure_storage` (Keychain trên iOS / Keystore trên Android), không lưu dạng plain text trong `SharedPreferences`. | Kiểm tra DB bảng `users`, kiểm tra JSON Serialization trong `UserResource` và kiểm tra mã nguồn Flutter. |
| `NFR-SEC-02` | Thực thi Phân quyền RBAC & Ownership tại Backend | - 100% API endpoints thay đổi dữ liệu hoặc truy cập thông tin cá nhân/quản trị phải được bảo vệ bởi `auth:sanctum`, Middleware kiểm tra trạng thái tài khoản (`ACTIVE`) và Laravel Policies.<br>- Mọi nỗ lực gọi API trái quyền (User gọi API Admin, Support Staff gọi API giải ngân, Seller sửa sản phẩm của người khác) phải bị chặn với mã `401 Unauthorized` hoặc `403 Forbidden`. | Automated Feature Tests cho từng Role (`ACT-01`..`ACT-05`) trên các endpoints nhạy cảm. |
| `NFR-SEC-03` | Chống Giả mạo Trạng thái Tài chính & Giá từ Client | - Backend tuyệt đối không nhận các tham số nhạy cảm từ request body của Client như: `total_amount`, `buyer_protection_fee`, `payment_status`, `escrow_status`, `winner_id`.<br>- Mọi phép tính tiền và chuyển trạng thái phải được tính toán độc lập tại tầng Laravel Service dựa trên dữ liệu gốc trong PostgreSQL. | Kiểm thử truyền tham số giả mạo trong payload `POST /orders` và `POST /payments` để xác nhận Backend bỏ qua hoặc từ chối. |
| `NFR-SEC-04` | Giới hạn Tần suất Gửi Yêu cầu (Rate Limiting) | Áp dụng Laravel Rate Limiter (`ThrottleRequests`) để chống brute-force và spam:<br>- Endpoint Đăng nhập / Đăng ký: tối đa `10 requests / phút / IP`.<br>- Endpoint Đặt giá thầu (`Place Bid`): tối đa `30 requests / phút / User`.<br>- Endpoint Gửi tin nhắn Chat: tối đa `60 requests / phút / User`. | Gửi request vượt ngưỡng trong bài test để xác nhận nhận mã `429 Too Many Requests`. |
| `NFR-SEC-05` | An toàn Tải lên Tệp tin (File Upload Security) | - Chỉ chấp nhận file ảnh có MIME type hợp lệ (`image/jpeg`, `image/png`, `image/webp`) với dung lượng tối đa `5 MB / ảnh` (tối đa 5–8 ảnh / sản phẩm hoặc khiếu nại).<br>- Đổi tên file tải lên bằng chuỗi UUID ngẫu nhiên trước khi lưu vào `storage/app/public` để chống Path Traversal và ghi đè file. | Kiểm thử tải lên file `.php`, `.exe` hoặc ảnh `> 5MB` và xác nhận hệ thống từ chối với mã `422`. |

---

## 3. Tính Toàn Vẹn Dữ Liệu, Đồng Thời & Độ Tin Cậy (Data Integrity, Concurrency & Reliability – `NFR-REL`)

| Mã NFR | Tên Yêu Cầu | Đặc Tả Kỹ Thuật & Tiêu Chí Nghiệm Thu | Phương Pháp Kiểm Chứng |
| :--- | :--- | :--- | :--- |
| `NFR-REL-01` | Giao dịch Nguyên tử & Khóa dòng chống Race Condition | - Toàn bộ thao tác Đặt hàng (`Order Creation`), Đặt giá đấu giá (`Place Bid`), Chốt phiên đấu giá (`Auction Close`), Thanh toán (`Payment Success`), Giải ngân/Hoàn tiền (`Escrow Release/Refund`) bắt buộc bọc trong `DB::transaction()` kết hợp `SELECT ... FOR UPDATE` (`lockForUpdate()`).<br>- Nếu bất kỳ bước con nào lỗi, toàn bộ transaction phải rollback 100%, không để lại dữ liệu mồ côi. | Kiểm thử gửi đồng thời 2 request mua món hàng cuối cùng (`quantity = 1`) hoặc 2 lượt bid cùng mức giá tại cùng thời điểm. |
| `NFR-REL-02` | Độ chính xác Tiền tệ & Sổ cái Bất biến | - Tất cả các cột tiền tệ trong PostgreSQL 18 sử dụng kiểu `NUMERIC(15, 2)`, không có sai số dấu phẩy động.<br>- Bảng `escrow_transactions` và `wallet_transactions` tuân thủ nguyên tắc Append-Only: tổng tiền `RELEASE + REFUND + PLATFORM_FEE` của một đơn hàng luôn khớp 100% với bút toán `HOLD` ban đầu (`total_amount`). | Kiểm tra schema migration và chạy bài test đối soát tổng cân bằng sổ cái sau 3 kịch bản Mua hàng, Hủy đơn và Phân xử khiếu nại. |
| `NFR-REL-03` | Tính Lũy đẳng của Tác vụ Tự động (Idempotency) | - Mọi Scheduled Jobs của Laravel và các nút bấm trong **Developer Tools (Demo Mode)** phải đảm bảo tính lũy đẳng.<br>- Việc thực thi lặp lại cùng một Job (hoặc nhấn nút `Simulate Payment Success` / `Run Demo Job` nhiều lần) tuyệt đối không tạo ra đơn hàng thứ 2, không trừ tồn kho 2 lần và không giải ngân/hoàn tiền 2 lần. | Gọi hàm Service của Scheduled Job 3 lần liên tiếp trong Automated Test và kiểm tra số lượng bản ghi sinh ra trong DB. |
| `NFR-REL-04` | Đóng băng Dữ liệu Lịch sử (Snapshot & Soft Delete) | - Bảng `order_items` lưu snapshot độc lập; bảng `orders` lưu cứng `payment_expires_at` và `auto_complete_at`; bảng `auctions` lưu cứng `auction_ends_at`.<br>- Sử dụng `SoftDeletes` hoặc trạng thái `ARCHIVED` cho các bảng có liên kết lịch sử giao dịch (`users`, `products`, `categories`); cấm `DELETE` vật lý các bản ghi đã phát sinh đơn hàng hoặc bút toán tài chính. | Chỉnh sửa tên/giá sản phẩm hoặc đổi `platform_settings` sau khi tạo đơn và xác nhận đơn hàng cũ không bị biến đổi dữ liệu. |

---

## 4. Hiệu Năng & Khả Năng Phản Hồi (Performance & Responsiveness – `NFR-PER`)

| Mã NFR | Tên Yêu Cầu | Đặc Tả Kỹ Thuật & Tiêu Chí Nghiệm Thu | Phương Pháp Kiểm Chứng |
| :--- | :--- | :--- | :--- |
| `NFR-PER-01` | Thời gian Phản hồi API trên Môi trường Local | Trong điều kiện chạy local (PostgreSQL 18 + Laravel 13):<br>- Các API đọc dữ liệu danh sách/chi tiết (`GET /products`, `GET /auctions`): thời gian phản hồi trung bình `< 300ms`.<br>- Các API giao dịch có khóa dòng (`POST /orders`, `POST /auctions/{id}/bid`, `POST /payments/{id}/simulate-success`): thời gian phản hồi `< 500ms`. | Kiểm tra thời gian phản hồi qua Postman / Laravel Telescope / Log hoặc bài test hiệu năng cơ bản. |
| `NFR-PER-02` | Phân trang & Tối ưu Truy vấn CSDL (N+1 Prevention) | - Mọi API trả về danh sách (Sản phẩm, Đấu giá, Đơn hàng, Lịch sử bid, Tin nhắn chat, Audit logs) bắt buộc áp dụng phân trang (`Pagination`, mặc định 10–20 bản ghi/trang).<br>- Sử dụng Eager Loading (`with()`) trong Eloquent để ngăn chặn lỗi truy vấn `N+1`, và đánh Index đầy đủ cho các cột khóa ngoại, cột lọc trạng thái (`status`) và cột thời gian hết hạn (`*_expires_at`, `auto_complete_at`, `auction_ends_at`). | Kiểm tra số lượng câu lệnh SQL sinh ra trên mỗi request danh sách. |
| `NFR-PER-03` | Cơ chế HTTP Polling Có Kiểm soát cho Chat | - Tính năng Chat 1-1 sử dụng HTTP Polling chỉ kích hoạt chu kỳ lấy tin nhắn mới (ví dụ mỗi `3–5 giây`) khi người dùng đang mở trực tiếp màn hình hội thoại đó.<br>- Khi người dùng rời màn hình Chat hoặc đưa ứng dụng xuống nền (background), bộ đếm `Timer` của Polling bắt buộc phải được hủy (`dispose`) ngay lập tức để tránh rò rỉ bộ nhớ và quá tải API. | Kiểm tra vòng đời `Provider` / `State.dispose()` trong Flutter và log request trên Laravel khi thoát màn hình Chat. |

---

## 5. Trải Nghiệm Người Dùng, Giao Diện & Typography Tiếng Việt (Usability, UI Quality & Localization – `NFR-UX`)

| Mã NFR | Tên Yêu Cầu | Đặc Tả Kỹ Thuật & Tiêu Chí Nghiệm Thu | Phương Pháp Kiểm Chứng |
| :--- | :--- | :--- | :--- |
| `NFR-UX-01` | Hiển thị Chuẩn xác Tiếng Việt & Cơ chế Font Fallback (`UI-01`, `UI-02`) | - Toàn bộ văn bản tiếng Việt tĩnh trong mã nguồn phải được chuẩn hóa về **Unicode dựng sẵn (NFC)**.<br>- Áp dụng phân tầng Typography nghiêm ngặt: `Wichita Vintage` chỉ dùng cho Logo thương hiệu `izithrift` và các tiêu đề đã kiểm chứng đủ glyph; **`Fraunces`** dùng cho tiêu đề tiếng Việt động (tên sản phẩm, tên phiên đấu giá); **`Be Vietnam Pro`** dùng cho toàn bộ nội dung thân bài, nút bấm, nhãn trạng thái và giá tiền.<br>- Đảm bảo không xuất hiện ký tự ô vuông (tofu) hoặc hiện tượng chắp vá chữ cái lệch kiểu (Ransom Note effect) trên mọi nguyên âm tiếng Việt có dấu kép (`ă, â, ê, ô, ơ, ư, đ, ấ, ậ, ể, ễ, ộ, ợ, ự...`). | Kiểm thử hiển thị chuỗi tiếng Việt chuẩn trên cả Android Emulator và iOS Simulator ở Phase 03 & Phase 13 (`QA-03`). |
| `NFR-UX-02` | Độ Tương phản Thị giác & Khả năng Tách biệt Chủ đề Giáng sinh | - Đảm bảo độ tương phản rõ ràng giữa màu chữ chính (`Dark Charcoal #302D2A`) trên nền kem ấm (`Warm Cream #F4EBDD`) và chữ sáng trên nút chính (`Forest Green #294638`, `Burgundy #873A43`).<br>- Các họa tiết trang trí Giáng sinh (tất sọc đỏ trắng, cây thông, ống khói, chuông, mũ Santa) không được che khuất ảnh sản phẩm, giá bán hoặc nút bấm, và phải được quản lý qua cấu hình Theme để có thể bật/tắt sau mùa lễ mà không phải viết lại bố cục màn hình. | Rà soát UI trên các kích thước màn hình di động khác nhau và thử tắt cờ `enableSeasonalChristmasDecor`. |
| `NFR-UX-03` | Đầy đủ 4 Trạng thái Giao diện & Hộp thoại Xác nhận | - 100% màn hình có gọi API trên Flutter phải cài đặt đủ 4 trạng thái hiển thị: **Loading** (Skeleton/Spinner), **Empty** (Minh họa + thông báo khi chưa có dữ liệu), **Error** (Thông báo lỗi tiếng Việt rõ nghĩa + nút Thử lại) và **Success** (Dữ liệu hiển thị chuẩn).<br>- Mọi hành động mang tính phá hủy hoặc cam kết tài chính (Hủy đơn hàng, Đặt giá thầu, Chốt phiên đấu giá sớm, Xác nhận đã nhận hàng, Duyệt/Từ chối sản phẩm, Phân xử khiếu nại) bắt buộc hiển thị **Confirmation Dialog** trước khi gửi request. | Kiểm thử từng màn hình trong các tình huống: mạng chậm, danh sách trống, API trả lỗi 422/500 và thao tác bấm nút quan trọng. |

---

## 6. Kiến Trúc, Khả Năng Bảo Trì & Vận Hành Local/Demo (Maintainability, Portability & Demoability – `NFR-MNT`, `NFR-ENV`)

| Mã NFR | Tên Yêu Cầu | Đặc Tả Kỹ Thuật & Tiêu Chí Nghiệm Thu | Phương Pháp Kiểm Chứng |
| :--- | :--- | :--- | :--- |
| `NFR-MNT-01` | Tuân thủ Kiến trúc Phân lớp & Tái sử dụng Logic | - **Flutter:** Tuân thủ cấu trúc Feature-based kết hợp `MVVM + Repository Pattern` (`UI Screen/Widget` $\rightarrow$ `Provider` $\rightarrow$ `Repository` $\rightarrow$ `Dio API Service`). Không gọi trực tiếp `Dio` bên trong file giao diện Widget.<br>- **Laravel 13:** Tuân thủ kiến trúc `Controller` mỏng $\rightarrow$ `Form Request` $\rightarrow$ `Service Class` $\rightarrow$ `Eloquent Model`. Giao diện Admin Blade và REST API `/api/v1` bắt buộc gọi chung các `Service Class` nghiệp vụ, tuyệt đối không nhân bản logic ở 2 nơi. | Rà soát cấu trúc thư mục và chạy `flutter analyze` (0 errors) cùng kiểm tra kiến trúc `app/Services/` trên Laravel. |
| `NFR-MNT-02` | Chuẩn hóa Định dạng JSON API Response | Mọi phản hồi từ `/api/v1` (cả thành công lẫn thất bại) phải tuân thủ một cấu trúc JSON đồng nhất gồm: `success` (`boolean`), `message` (`string`), `data` (`object/array/null`), `meta` (thông tin phân trang nếu có) và `errors` (chi tiết lỗi validation nếu có). | Kiểm tra cấu trúc phản hồi của các API endpoints qua bộ Feature Tests. |
| `NFR-ENV-01` | Khả năng Di chuyển & Cấu hình Mạng Động (`Zero Hardcoded Localhost`) | - Toàn bộ dự án vận hành độc lập 100% trên môi trường Local thông qua **Docker Compose** (PostgreSQL 18) và Laravel Local Server mà không cần tài khoản dịch vụ đám mây trả phí.<br>- Ứng dụng Flutter kết nối tới Backend thông qua biến cấu hình `API_BASE_URL` (hỗ trợ đổi linh hoạt giữa `http://10.0.2.2:8000/api/v1` cho Android Emulator, `http://127.0.0.1:8000/api/v1` cho iOS Simulator và IP LAN `192.168.x.x` cho điện thoại thật); tuyệt đối không hardcode `localhost` rải rác trong code. | Chạy thử ứng dụng trên Android Emulator kết nối tới Laravel API và tải thành công hình ảnh sản phẩm từ Local Storage. |
| `NFR-ENV-02` | Dữ liệu Mẫu Phong phú & Chế độ Trình diễn Chủ động (Seeder & Demo Mode) | - Lệnh `php artisan migrate:fresh --seed` phải khởi tạo thành công toàn bộ 29 bảng kèm bộ dữ liệu mẫu thực tế (10–20 Users, 3+ Admins/Mods, 30+ Products ở đủ trạng thái, các phiên đấu giá đang chạy/đã đóng, đơn hàng, bút toán Escrow, đánh giá, tin nhắn và khiếu nại).<br>- Hỗ trợ cờ `DEMO_MODE=true` cho phép rút ngắn các mốc thời gian chờ (xuống 2 phút / 30 giây) và cung cấp trang **Developer Tools** trên Admin để kích hoạt tức thì các Scheduled Jobs phục vụ bảo vệ đồ án. | Chạy lệnh `migrate:fresh --seed` trên môi trường sạch và kiểm thử toàn bộ nút bấm trong Developer Tools. |