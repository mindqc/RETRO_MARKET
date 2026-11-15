# 02. SCOPE AND BOUNDARIES – RETRO MARKET (izithrift)

- **Document ID:** `DOC-PA01-SCOPE`
- **Version:** `1.1.0 (FINAL APPROVED)`
- **Status:** `DONE`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 01 – Project Discovery & Requirement Analysis`

---

## 1. Tính Năng Trong Phạm Vi (In-Scope Features)
Hệ thống bao gồm các nhóm chức năng nằm trong phạm vi phát triển của đồ án `[CONFIRMED]`:
1. **Quyền Khách vãng lai (Guest Access) & Quản lý Tài khoản (Auth & Profile):**
   - **Guest:** Được xem Trang chủ, Tìm kiếm/Lọc sản phẩm, Xem chi tiết sản phẩm và Xem danh sách phiên đấu giá; bắt buộc chuyển hướng sang Đăng nhập khi thực hiện hành động tương tác (Mua hàng, Thêm giỏ hàng, Đặt giá thầu, Chat, Yêu thích, Đăng bán).
   - **Registered User:** Đăng ký, đăng nhập, đăng xuất, đặt lại mật khẩu, chỉnh sửa hồ sơ cá nhân, quản lý nhiều địa chỉ nhận hàng, xem hồ sơ người bán và thống kê đánh giá.
2. **Quản lý Sản phẩm & Kênh Người bán (Seller Center):** Tạo bài đăng bán hàng theo 2 phương thức (Giá cố định `Fixed Price` hoặc Đấu giá `Auction`), tải nhiều ảnh, khai báo tình trạng & lỗi sản phẩm, lưu nháp, gửi duyệt, sửa bài bị từ chối (`REJECTED`) và gửi duyệt lại (`Resubmit`), quản lý danh sách sản phẩm theo trạng thái, xem lịch sử bán hàng và sổ cái ví người bán.
3. **Kiểm duyệt Sản phẩm (Product Moderation):** Quy trình duyệt bài đăng bắt buộc (`DRAFT` $\rightarrow$ `PENDING_REVIEW` $\rightarrow$ `APPROVED` / `REJECTED`), lưu vết người duyệt, lý do từ chối/yêu cầu chỉnh sửa, thời gian và mức độ xác minh thông tin.
4. **Khám phá, Tìm kiếm & Lọc (Discovery & Search):** Trang chủ theo chủ đề Vintage Giáng sinh, tìm kiếm theo tên/thương hiệu/danh mục, lọc theo tình trạng/khoảng giá/nơi bán/loại hình bán, sắp xếp theo độ mới/giá/độ phổ biến, lưu sản phẩm yêu thích và theo dõi người bán.
5. **Giỏ hàng, Đặt hàng & Cơ chế Phí Bảo Vệ Người Mua (Cart, Checkout & Buyer Protection Fee):**
   - Thêm/xóa/cập nhật số lượng trong giỏ hàng, kiểm tra tồn kho và giá thực tế lúc thanh toán, tách đơn hàng theo từng người bán (1 seller / 1 order), lưu bản chụp (snapshot) thông tin sản phẩm vào đơn hàng.
   - **Không thu phí vận chuyển trên ứng dụng** (`shipping_fee = 0`).
   - **Tính Phí bảo vệ người mua (Buyer Protection Fee):** Thu trực tiếp từ người mua theo công thức cấu hình trên hệ thống: `buyer_protection_fee = (item_subtotal * protection_fee_rate) + protection_fixed_fee` (trong đó `protection_fee_rate` cấu hình từ `5% – 8%` và `protection_fixed_fee` cấu hình từ `5.000đ – 10.000đ`). Người bán nhận về 100% giá trị tiền hàng (`item_subtotal`) khi đơn hoàn tất.
6. **Hệ thống Đấu giá theo Phiên (Scheduled Auction System):**
   - Quản lý khung giờ đấu giá hàng ngày, Auction Hub (Sắp diễn ra, Đang diễn ra, Sắp kết thúc, Đã kết thúc, Đang tham gia, Đã thắng), đặt giá thầu với kiểm tra bước giá tối thiểu & giá sàn (reserve price), gia hạn tự động 2 phút cuối (anti-sniping), người bán chốt sớm có điều kiện.
   - Tự động xác định người thắng và tạo đơn hàng (áp dụng cùng công thức Phí bảo vệ người mua) có hạn thanh toán (mặc định 30 phút ở Production Mode / 2 phút ở Demo Mode).
   - Nếu người thắng không thanh toán đúng hạn: Đơn hàng đấu giá chuyển sang hết hạn/hủy, phiên đấu giá kết thúc không thành công và cho phép Người bán đăng lại sản phẩm vào phiên đấu giá tiếp theo (không tự động ép người trả giá cao thứ 2 mua).
7. **Thanh toán QR Mô phỏng & Sổ cái Giữ tiền (Mock QR Payment & Escrow Ledger):** Tạo phiên thanh toán kèm mã QR nội bộ chứa mã tham chiếu, trang giả lập thanh toán thành công/thất bại/hết hạn, ghi nhận bút toán giữ tiền (`ESCROW_HELD`), giải ngân 100% tiền hàng (`item_subtotal`) vào ví người bán khi người mua xác nhận nhận hàng hoặc tự động hoàn tất sau 24 giờ kể từ lúc giao hàng (`DELIVERED`).
8. **Vận chuyển & Theo dõi Đơn hàng (Shipping & Order Tracking):** Người bán xác nhận chuẩn bị hàng, nhập mã vận đơn (tracking code) thủ công, cập nhật trạng thái giao hàng (`SHIPPED` / `DELIVERED`); người mua theo dõi timeline đơn hàng và xác nhận đã nhận hàng.
9. **Giao tiếp, Đánh giá & Giải quyết Khiếu nại (Chat, Reviews & Disputes):**
   - Chat 1-1 giữa người mua và người bán gắn với sản phẩm (cơ chế Polling).
   - Đánh giá 1–5 sao kèm nhận xét (chỉ dành cho đơn đã `COMPLETED`, tối đa 1 lần/đơn).
   - **Gửi khiếu nại (Dispute):** Người mua được quyền gửi khiếu nại kèm bằng chứng ngay khi đơn hàng đang ở trạng thái **`SHIPPED`** (ví dụ: người bán không giao hàng / quá lâu không nhận được hàng) hoặc **`DELIVERED`** (hàng bị rách, hư hỏng, sai mô tả, nghi ngờ tính xác thực). Khi khiếu nại mở, hệ thống lập tức khóa tự động giải ngân Escrow chờ Admin phân xử.
10. **Quản trị Hệ thống & Chế độ Trình diễn (Admin Dashboard & Demo Mode):** Quản trị toàn bộ 14 phân hệ trên Web Laravel Blade, phân quyền RBAC (Admin, Moderator, Support Staff), lưu Audit Logs và bộ công cụ Developer Tools phục vụ chạy Demo Mode.

---

## 2. Tính Năng Ngoài Phạm Vi (Out-of-Scope Features)
Các hạng mục dưới đây **tuyệt đối không nằm trong phạm vi** của đồ án `[CONFIRMED]`:
1. **Giao dịch ngân hàng và lưu ký tài chính thật (`OUT-01`):** Không kết nối cổng thanh toán thương mại thực tế, không chuyển tiền thật qua ngân hàng và không rút tiền thật từ ví người bán.
2. **Tích hợp API hãng vận chuyển và thu phí vận chuyển trên app (`OUT-02`):** Không kết nối API GHN/GHTK/Viettel Post và không tính hay thu hộ phí vận chuyển trong đơn hàng trên nền tảng.
3. **Cam kết giám định hàng chính hãng bằng AI hoặc chuyên gia vật lý (`OUT-03`):** Không sử dụng mô hình AI Computer Vision để tự động phán đoán hàng thật/hàng giả qua ảnh, và không có kho kiểm định vật lý.
4. **Định danh điện tử pháp lý (`OUT-04`):** Không tích hợp dịch vụ eKYC CCCD/Hộ chiếu có thu phí của bên thứ ba hoặc tổng đài SMS OTP thương mại.
5. **Ứng dụng Web dành cho Người mua/Người bán (`OUT-05`):** Người mua và người bán chỉ thao tác trên ứng dụng di động Flutter (`izithrift`); giao diện Web chỉ dành riêng cho Admin, Moderator và Support Staff.
6. **Đấu giá trực tiếp qua Video Livestream (`OUT-06`):** Không bao gồm tính năng phát video trực tiếp (Livestream) trong phiên đấu giá.

---

## 3. Phạm Vi Ứng Dụng Di Động – `mobile/` (Mobile Application Scope)
- **Nền tảng & Kiến trúc:** Ứng dụng đa nền tảng (Android & iOS) viết bằng Flutter/Dart theo kiến trúc MVVM + Repository Pattern, quản lý trạng thái bằng `Provider`, điều hướng bằng `go_router` `[CONFIRMED]`.
- **Đối tượng sử dụng:** Khách vãng lai (Guest – quyền xem công khai) và Người dùng đã đăng nhập (Registered User – tích hợp cả quyền Mua và Bán) `[CONFIRMED]`.
- **Phạm vi xử lý trên Client:**
  - Hiển thị giao diện theo Design System (Vintage Editorial + Cozy Christmas), thu thập dữ liệu đầu vào, lưu trữ bảo mật token (`flutter_secure_storage`), sinh/quét mã QR mô phỏng và hiển thị đồng hồ đếm ngược `[CONFIRMED]`.
  - **Ranh giới bảo mật:** Tuyệt đối không đặt logic tính toán tài chính (như tự tính Phí bảo vệ người mua để chốt đơn), xác định người thắng đấu giá, tự chuyển trạng thái thanh toán hay tự giải ngân tiền ở phía ứng dụng Flutter `[CONFIRMED]`.

---

## 4. Phạm Vi Trang Quản Trị – `admin/` & `backend/` (Admin Dashboard Scope)
- **Công nghệ & Kiến trúc:** Ứng dụng Web responsive xây dựng bằng **Laravel Blade**, chạy chung trong cùng project Laravel 13 với Backend API, sử dụng chung tầng Models, Services, Policies và cơ sở dữ liệu PostgreSQL 18 `[CONFIRMED]`.
- **14 Module Quản trị trong phạm vi `[CONFIRMED]`:**
  1. Quản lý người dùng (User Management).
  2. Kiểm duyệt sản phẩm (Product Moderation – duyệt `APPROVED` hoặc từ chối `REJECTED` kèm lý do để người bán sửa và gửi lại).
  3. Quản lý danh mục (Category Management).
  4. Quản lý thương hiệu (Brand Management).
  5. Quản lý sản phẩm đấu giá (Auction Management).
  6. Cấu hình khung giờ phiên đấu giá (Auction Session Configuration).
  7. Quản lý đơn hàng (Order Management).
  8. Quản lý thanh toán (Payment Management).
  9. Quản lý sổ cái giữ tiền & Phí bảo vệ người mua (Escrow Ledger Management).
  10. Giải quyết khiếu nại & tranh chấp (Dispute Management – hoàn tiền cho người mua, giải ngân cho người bán, hoàn tiền một phần, yêu cầu thêm bằng chứng, từ chối khiếu nại).
  11. Kiểm duyệt đánh giá (Review Moderation).
  12. Quản lý báo cáo vi phạm người dùng/sản phẩm (User & Product Reports).
  13. Cấu hình thông số nền tảng (Platform Settings – cấu hình % và mức cố định của **Buyer Protection Fee**, thời hạn thanh toán, thời gian tự hoàn tất đơn, bước giá tối thiểu, cấu hình Demo Mode).
  14. Nhật ký hoạt động quản trị (Admin Activity / Audit Logs).
- **Module Bổ sung cho Đồ án:** Khu vực **Developer Tools (Demo Mode)** dành riêng cho Admin ở môi trường local/demo để kích hoạt thủ công các Scheduled Jobs `[CONFIRMED]`.

---

## 5. Phạm Vi Hệ Thống Backend – `backend/` (Backend Scope)
- **Cung cấp RESTful API (`/api/v1`):** Phục vụ toàn bộ nghiệp vụ cho ứng dụng di động Flutter với cấu trúc JSON chuẩn hóa, xác thực qua `Laravel Sanctum` và kiểm soát quyền hạn qua Middleware + Policies `[CONFIRMED]`.
- **Quản lý 4 Vòng đời Trạng thái Độc lập:** Kiểm soát chặt chẽ chuyển đổi trạng thái của Sản phẩm (`DRAFT`, `PENDING_REVIEW`, `APPROVED`, `REJECTED`, `SOLD`, `HIDDEN`, `ARCHIVED`), Đấu giá, Đơn hàng (`order_status`), Thanh toán (`payment_status`), Khoản giữ tiền (`escrow_status`) và Khiếu nại (`dispute_status`) `[CONFIRMED]`.
- **Xử lý Giao dịch Nguyên tử & Đồng thời:** Sử dụng Database Transactions (`DB::transaction`) và khóa dòng (`lockForUpdate`) cho các thao tác đặt giá đấu giá, tạo đơn hàng, thanh toán và ghi sổ cái tài chính `[CONFIRMED]`.
- **Tác vụ Định kỳ Tự động (Scheduled Backend Tasks):** Sử dụng Laravel Scheduler đảm bảo tính lũy đẳng (idempotent) cho 8 tác vụ tự động `[CONFIRMED]`.

---

## 6. Ranh Giới Tích Hợp Bên Ngoài (External Integration Boundaries)
| Phân hệ | Giải pháp triển khai trong phạm vi (In-Scope Boundary) | Hệ thống bên ngoài KHÔNG tích hợp (Out-of-Scope) |
| :--- | :--- | :--- |
| **Thanh toán** | **Mock Payment Gateway nội bộ** sinh mã QR theo chuẩn dữ liệu đơn hàng (gồm Tiền hàng + Phí bảo vệ người mua); có nút bấm mô phỏng thanh toán thành công `[CONFIRMED]`. | Cổng thanh toán thật (VNPay, MoMo, ZaloPay, ngân hàng thương mại). |
| **Giữ tiền & Ví** | **Internal Escrow & Wallet Ledger** lưu trữ trên bảng PostgreSQL với các bút toán bất biến (append-only) `[CONFIRMED]`. | Dịch vụ trung gian thanh toán pháp lý bên ngoài. |
| **Vận chuyển** | Không tính phí vận chuyển trên app. Người bán tự nhập mã vận đơn (tracking code) và cập nhật trạng thái giao hàng thủ công `[CONFIRMED]`. | API hãng vận chuyển (GHN, GHTK, Ahamove...). |
| **Lưu trữ File** | Lưu trữ ảnh sản phẩm, avatar và ảnh bằng chứng khiếu nại trực tiếp trên **Local Filesystem** của Laravel (`storage/app/public`) `[CONFIRMED]`. | AWS S3, Google Cloud Storage, Cloudinary, Firebase Storage. |
| **Thông báo & Chat** | Lưu thông báo trong CSDL (In-app notifications) và đồng bộ tin nhắn Chat qua cơ chế **HTTP Polling** theo chu kỳ `[CONFIRMED]`. | Firebase Cloud Messaging (FCM Push) bắt buộc ở giai đoạn đầu, Pusher trả phí. |

---

## 7. Ràng Buộc Phát Triển (Development Constraints)
1. **Môi trường mạng nội bộ:** Ứng dụng Flutter kết nối tới Laravel API qua `API_BASE_URL` cấu hình động `[CONFIRMED]`.
2. **Định dạng tiền tệ & Thời gian:** Mọi giá trị tiền tệ trong PostgreSQL bắt buộc dùng kiểu `NUMERIC(15, 2)` (đơn vị VNĐ). Mọi mốc thời gian hết hạn (`payment_expires_at`, `auto_complete_at`, `auction_ends_at`) phải được lưu cứng vào bản ghi ngay khi khởi tạo trạng thái `[CONFIRMED]`.
3. **Không dữ liệu giả trên màn hình thật:** Mọi màn hình chức năng của Flutter và Admin Blade phải đọc/ghi dữ liệu thực từ PostgreSQL thông qua API/Service và dữ liệu mẫu từ Laravel Seeders `[CONFIRMED]`.

---

## 8. Các Quyết Định Nghiệp Vụ Đã Chốt Cùng Product Owner (Confirmed Decisions)
1. **`DEC-01` (Quyền của Guest):** Guest được xem Trang chủ, Tìm kiếm/Lọc, Xem chi tiết sản phẩm và Xem danh sách Đấu giá; bắt buộc Đăng nhập khi thực hiện thao tác tương tác `[CONFIRMED]`.
2. **`DEC-02` (Chính sách quá hạn thanh toán đấu giá):** Khi người thắng không thanh toán sau thời hạn (30 phút ở Production / 2 phút ở Demo Mode), đơn hàng bị hủy do hết hạn, phiên đấu giá đóng lại và người bán được quyền đăng lại sản phẩm vào phiên tiếp theo `[CONFIRMED]`.
3. **`DEC-03` (Khung thời gian mở Khiếu nại):** Người mua được quyền gửi khiếu nại khi đơn hàng đang ở trạng thái **`SHIPPED`** hoặc **`DELIVERED`** (trước khi đơn chuyển sang `COMPLETED`) `[CONFIRMED]`.
4. **`DEC-04` (Miễn phí vận chuyển & Áp dụng Buyer Protection Fee):** Không thu phí vận chuyển trên app (`0đ`). Không thu phí hoa hồng từ người bán (người bán nhận 100% tiền hàng). Thu **Phí bảo vệ người mua (Buyer Protection Fee)** từ người mua gồm `5% – 8%` giá trị món đồ + `5.000đ – 10.000đ` phí cố định (cấu hình trong `platform_settings`, mặc định khởi tạo ở mức `6% + 7.000đ` và có thể chỉnh bởi Admin) `[CONFIRMED]`.
5. **`DEC-05` (Trạng thái kiểm duyệt sản phẩm):** Gộp việc yêu cầu chỉnh sửa vào trạng thái **`REJECTED`** kèm lý do chi tiết của Moderator để người bán sửa và bấm gửi duyệt lại (`Resubmit`) `[CONFIRMED]`.

---

## 9. Sự Phụ Thuộc Giữa Các Phân Hệ (Dependencies)
1. **Phụ thuộc Hạ tầng:** PostgreSQL 18 và Laravel 13 Foundation (Authentication, RBAC, File Upload) phải hoàn thành trước khi phát triển màn hình nghiệp vụ trên Flutter `[CONFIRMED]`.
2. **Phụ thuộc Luồng Sản phẩm:** `Product Listing` và `Product Moderation` bắt buộc hoàn thành trước `Product Discovery` `[CONFIRMED]`.
3. **Phụ thuộc Luồng Giao dịch & Đấu giá:** `Order`, `Mock Payment` và `Escrow Ledger` (Phase 09) bắt buộc hoàn thành trước `Auction System` (Phase 10) `[CONFIRMED]`.
4. **Phụ thuộc Đánh giá & Tranh chấp:** `Reviews` phụ thuộc vào đơn hàng `COMPLETED`; `Disputes` phụ thuộc vào đơn hàng đang ở trạng thái `SHIPPED` hoặc `DELIVERED` và tiền đang `ESCROW_HELD` `[CONFIRMED]`.

---

## 10. Ranh Giới MVP Ban Đầu (Initial MVP Boundary)
### Lớp 1: Core MVP (Bắt buộc hoàn thiện 100% logic & UI trước tiên)
- Xác thực tài khoản (Sanctum Token, RBAC, Guest mode) & Hồ sơ/Địa chỉ cơ bản.
- Đăng bán sản phẩm (Fixed Price & Auction) + Quy trình Admin Kiểm duyệt sản phẩm (`Product Moderation`).
- Khám phá sản phẩm, Tìm kiếm, Lọc & Xem chi tiết sản phẩm.
- Giỏ hàng (tách theo người bán), Checkout (tính Buyer Protection Fee, lưu snapshot), Quản lý vòng đời Đơn hàng & Cập nhật vận chuyển thủ công.
- Cổng thanh toán QR mô phỏng (`Mock Payment Gateway`) + Sổ cái Giữ tiền & Giải ngân (`Escrow Ledger` + Tự động hoàn tất sau 24h).
- Hệ thống Đấu giá theo phiên (`Auction Sessions`, Đặt giá có khóa dòng `lockForUpdate`, Anti-sniping 2 phút, Chốt sớm, Tự động tạo đơn cho người thắng).
- Đánh giá & Xếp hạng người bán (1–5 sao sau khi hoàn tất đơn) + Gửi khiếu nại (`SHIPPED` / `DELIVERED`) & Admin phân xử tranh chấp.
- Admin Dashboard (Laravel Blade) quản lý các nghiệp vụ trên kèm **Demo Mode / Developer Tools**.

### Lớp 2: Nhóm Nâng Cấp Trong Dự Án (Secondary In-Scope – Triển khai ngay sau khi Core MVP ổn định)
- Hệ thống Chat 1-1 giữa người mua và người bán (sử dụng cơ chế Polling).
- Yêu thích sản phẩm (`Favorites` / Wishlist) & Theo dõi người bán (`Follow Seller`).
- Hệ thống Thông báo trong ứng dụng (`In-App Notifications`).
- Điểm uy tín người bán nâng cao (`Seller Trust Score`) & Phát hiện dấu hiệu bất thường trên Admin.

---

## 11. Các Hướng Mở Rộng Tiềm Năng Trong Tương Lai (Potential Future Enhancements)
- Nâng cấp Chat và cập nhật giá đấu giá từ HTTP Polling sang **WebSockets (Laravel Reverb)**.
- Tích hợp **Push Notifications (Firebase Cloud Messaging)**.
- Tích hợp cổng thanh toán thực tế và API hãng vận chuyển thực tế.
- Ứng dụng AI hỗ trợ gợi ý sản phẩm và cảnh báo hình ảnh vi phạm sơ bộ.