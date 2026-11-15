# P7-04: AUTHENTICATION FLOWS, UNIFIED USER PROFILE & ADDRESS BOOK SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P704-AUTH-USER-PROFILE`
- **Version:** `1.0.0`
- **Status:** `DONE (100% PASS)`
- **Phase:** `Phase 07 – Task P7-04`
- **Dependencies:** `P7-01, P7-02, P7-03 Completed`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
Hiện thực hóa toàn bộ luồng Khởi động/Đồng bộ, Giới thiệu (Onboarding), Xác thực tài khoản (Đăng nhập, Đăng ký tài khoản hợp nhất Buyer/Seller `BR-AC-01`, Quên/Đặt lại mật khẩu) và Trung tâm Cá nhân Hợp nhất (Hồ sơ cá nhân, Sổ địa chỉ nhận hàng, Cài đặt ứng dụng). Gói này bao gồm đúng **10 màn hình Mobile**:
- `M-AU-01`: Splash & Bootstrap Sync
- `M-AU-02`: Onboarding Walkthrough (3 slides)
- `M-AU-03`: Login Screen
- `M-AU-04`: Register Screen (Unified Buyer/Seller Account)
- `M-AU-05`: Forgot & Reset Password
- `M-PF-01`: Unified Personal Hub (Profile Summary + Order Status Badges + Seller Mode Switch)
- `M-PF-02`: Edit Profile & Avatar Upload
- `M-PF-03`: Shipping Address List
- `M-PF-04`: Add / Edit Shipping Address
- `M-PF-06`: App Settings (Seasonal Decor Toggle & Change Password)

---

## 2. Screen Specifications & UX Flows (`Đặc Tả Chi Tiết 10 Màn Hình`)

### 2.1. Authentication Screens (`M-AU-01` $\rightarrow$ `M-AU-05`)
1. **`M-AU-01: Splash Screen`:**
   - Hiển thị logo `izithrift` (phông `Wichita Vintage`) trên nền `Warm Cream`.
   - Gọi đồng thời `GET /api/v1/bootstrap` và kiểm tra token trong `SecureTokenStorage`.
   - Nếu đã đăng nhập: Gọi `GET /api/v1/profile` để tải thông tin user, sau đó điều hướng vào `/home`.
   - Nếu chưa đăng nhập: Kiểm tra cờ xem Onboarding lần đầu (`first_launch`), nếu chưa xem chuyển sang `M-AU-02`, nếu đã xem chuyển thẳng vào `/home` với tư cách Guest.
2. **`M-AU-02: Onboarding Screen`:**
   - 3 Slides tương tác minh họa:
     - Slide 1: *"Khám phá kho đồ vintage & secondhand tuyển chọn"*.
     - Slide 2: *"Đấu giá trực tiếp công bằng – Chống trả giá phút chót Anti-Sniping"*.
     - Slide 3: *"Bảo vệ người mua 100% – Tiền ký quỹ Escrow an toàn tuyệt đối"*.
   - 2 Nút hành động: `[Đăng nhập / Đăng ký]` (vào `M-AU-03`) và `[Khám phá ngay (Guest)]` (vào `/home`).
3. **`M-AU-03: Login Screen`:**
   - Trường nhập `email` và `password`. Nút ẩn/hiện mật khẩu.
   - Nút `[Đăng nhập]`: Gọi `POST /api/v1/auth/login`. Lưu Sanctum token và cập nhật `AuthViewModel`.
   - Xử lý lỗi `403 ACCOUNT_SUSPENDED`: Bật hộp thoại cảnh báo tài khoản bị tạm khóa kèm lý do từ server.
   - Lối tắt: `[Quên mật khẩu?]` sang `M-AU-05`, `[Chưa có tài khoản? Đăng ký]` sang `M-AU-04`.
4. **`M-AU-04: Register Screen`:**
   - Trường: `display_name`, `email`, `password`, `password_confirmation`.
   - Cam kết nguyên tắc `BR-AC-01`: Tài khoản hợp nhất vừa là Người mua vừa là Người bán (tự động tạo `shop_slug`).
   - Gọi `POST /api/v1/auth/register`. Khi thành công, lưu token và điều hướng vào `/home`.
5. **`M-AU-05: Forgot & Reset Password`:**
   - Bước 1: Nhập email gửi mã / token đặt lại qua `POST /api/v1/auth/forgot-password`.
   - Bước 2: Nhập token và mật khẩu mới qua `POST /api/v1/auth/reset-password`.

### 2.2. Profile & Address Screens (`M-PF-01` $\rightarrow$ `M-PF-04`, `M-PF-06`)
6. **`M-PF-01: Unified Personal Hub`:**
   - Card Thông tin người dùng: Avatar, Tên hiển thị, Email, Huy hiệu `Trust Score` (nếu có bán hàng).
   - Lối vào Kênh Người bán (`NAV-DEC-02`): Nút `[Chuyển sang Kênh Người bán 🛍️]` điều hướng tới `M-SL-01`.
   - Hàng Huy hiệu Đơn mua (`order_status_counts`):
     - `Chờ thanh toán`, `Đã thanh toán / Chờ gửi`, `Đang giao`, `Đã nhận`, `Khiếu nại`.
   - Danh sách menu: `Đơn mua của tôi` (`M-OR-02`), `Đấu giá của tôi` (`M-AC-02`), `Sản phẩm yêu thích` (`M-PF-05`), `Sổ địa chỉ nhận hàng` (`M-PF-03`), `Cài đặt` (`M-PF-06`).
7. **`M-PF-02: Edit Profile & Avatar Upload`:**
   - Cho phép chọn ảnh avatar từ thư viện (`image_picker`), cắt ảnh vuông.
   - Cập nhật `display_name`, `phone`, `bio`, `shop_slug`.
   - Gửi request `POST /api/v1/profile` kèm `FormData` và `_method: PUT`.
8. **`M-PF-03: Address Book List`:**
   - Danh sách các địa chỉ từ `GET /api/v1/profile/addresses`.
   - Huy hiệu `[Mặc định]` trên địa chỉ chính. Nút sửa / xóa.
   - Nút nổi `[+ Thêm địa chỉ mới]` mở `M-PF-04`.
9. **`M-PF-04: Add / Edit Address`:**
   - Form nhập: `recipient_name`, `recipient_phone`, `province_city`, `district_ward`, `street_address`, công tắc `is_default`.
   - Validation số điện thoại Việt Nam chuẩn (10 số, bắt đầu bằng 03, 05, 07, 08, 09).
   - Gọi `POST /api/v1/profile/addresses` (tạo mới) hoặc `PUT /api/v1/profile/addresses/{id}` (cập nhật).
10. **`M-PF-06: App Settings`:**
    - Công tắc `Hiệu ứng Giáng sinh ấm áp (Cozy Christmas)` (`NFR-UX-02`): Gọi `PUT /api/v1/profile/settings` và cập nhật `SeasonalThemeNotifier`.
    - Đổi mật khẩu: Gọi `PUT /api/v1/profile/password` (`current_password`, `password`, `password_confirmation`).
    - Nút `[Đăng xuất]`: Gọi `POST /api/v1/auth/logout`, xóa token an toàn và đưa về trạng thái Guest.

---

## 3. Architecture & State Management (MVVM Pattern)
- **Models:** `UserModel`, `UserProfileModel`, `SellerProfileModel`, `UserAddressModel`, `BootstrapModel`.
- **Repositories:** `AuthRepository`, `ProfileRepository`, `AddressRepository`.
- **ViewModels (`ChangeNotifier`):**
  - `AuthViewModel`: Quản lý trạng thái đăng nhập, user hiện tại, xử lý token.
  - `ProfileViewModel`: Quản lý dữ liệu profile, order counts, upload avatar.
  - `AddressViewModel`: Quản lý danh sách địa chỉ, thêm/sửa/xóa địa chỉ.

---

## 4. API Endpoints Utilized
- `GET /api/v1/bootstrap`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/logout`
- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`
- `GET /api/v1/profile`
- `POST /api/v1/profile` (update profile & avatar)
- `PUT /api/v1/profile/password`
- `PUT /api/v1/profile/settings`
- `GET /api/v1/profile/addresses`
- `POST /api/v1/profile/addresses`
- `PUT /api/v1/profile/addresses/{id}`
- `DELETE /api/v1/profile/addresses/{id}`

---

## 5. Acceptance Criteria (`Tiêu Chí Nghiệm Thu P7-04`)
- [x] **AC-P704-01:** Luồng Splash, Onboarding và Đăng nhập/Đăng ký hoạt động mượt mà, lưu token an toàn.
- [x] **AC-P704-02:** Tài khoản đăng ký mới tự động kích hoạt cả vai trò Người mua và Người bán theo `BR-AC-01`.
- [x] **AC-P704-03:** Sổ địa chỉ hỗ trợ thêm, sửa, xóa, và chọn địa chỉ mặc định chính xác.
- [x] **AC-P704-04:** Chuyển đổi công tắc hiệu ứng Giáng sinh cập nhật tức thì trên giao diện và lưu lên server.
- [x] **AC-P704-05:** Viết đầy đủ Unit & Widget tests cho ViewModels và 10 màn hình trong `test/features/auth_and_profile_test.dart` đạt **100% PASS** (10/10 tests pass, tổng 45/45 tests toàn mobile suite).
