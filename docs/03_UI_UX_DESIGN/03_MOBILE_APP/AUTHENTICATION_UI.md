# 02. MOBILE AUTHENTICATION UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P303-AUTH-UI`
- **Version:** `2.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – Task P3-03 (Group 2: Authentication)`
- **Screen IDs Covered:** `M-AU-01`, `M-AU-02`, `M-AU-03`, `M-AU-04`, `M-AU-05` & `CMP-GWC-01 (Guest Welcome Card)`

---

## Chương 1. Kiểm Chứng Phạm Vi Xác Thực Theo Requirements (`Scope & Verification Check`)

Đối chiếu với `04_FUNCTIONAL_REQUIREMENTS.md` (`FR-AU-01..05`), `07_NON_FUNCTIONAL_REQUIREMENTS.md` (`NFR-SEC-01..04`), `08_ASSUMPTIONS_AND_DECISIONS.md` (`DEC-01`, `ASM-04`) và `SCREEN_INVENTORY.md`:
- **Các màn hình xác thực đã phê duyệt:**
  1. `M-AU-01`: Splash & Seasonal Loader (`/splash`)
  2. `M-AU-02`: Vintage Christmas Onboarding (`/onboarding`)
  3. `M-AU-03`: Login Screen (`/login?redirect=...`)
  4. `M-AU-04`: Register Unified C2C Account (`/register`)
  5. `M-AU-05`: Password Recovery – Forgot & Reset Password (`/forgot-password`)
  6. `CMP-GWC-01`: Guest Welcome Card (Hiển thị trên Tab 4 `/seller` và Tab 5 `/profile` khi chưa đăng nhập theo `NAV-DEC-03`).
- **Lưu ý về Verification (`OTP/Email Verification`):** Theo `ASM-04` trong Phase 01, hệ thống **không bắt buộc xác thực OTP qua SMS thật khi đăng ký** để thuận tiện cho việc tạo tài khoản demo đồ án; riêng luồng khôi phục mật khẩu (`M-AU-05`) có bước nhập **Mã xác nhận khôi phục (`Reset Verification Token`)** lấy từ Mailpit/Log cục bộ.

---

## Chương 2. Đặc Tả High-Fidelity Từng Màn Hình (`M-AU-01` – `M-AU-05`)

### 2.1. Screen `M-AU-01`: Splash & Seasonal Loader

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-AU-01` – Splash & Seasonal Token Bootstrap Screen (`/splash`) |
| **Purpose** | Khởi tạo ứng dụng, kiểm tra `Sanctum Token` trong `flutter_secure_storage`, tải cấu hình `platform_settings` và điều hướng người dùng. |
| **Entry Point** | Chạm vào icon ứng dụng `izithrift` từ màn hình chính của điện thoại. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)` $\rightarrow$ `SafeArea` $\rightarrow$ `Column (SpaceBetween)`:<br>1. `Spacer()`<br>2. `CenterBrandCluster`: `[SeasonalEmblem (Conditional)]` + `[BrandWordmark 'izithrift']` + `[SubtitleTagline]`<br>3. `BottomStatusBlock (Padding bottom 32px)`: `[LoadingSpinner 20px]` hoặc `[ErrorRetryCard]`. |
| **Typography & Color Tokens** | - Nền: `color.bg.mobile.canvas` (`#F4EBDD`).<br>- Logo: `type.brand.logo` (`Wichita Vintage`, `42px`, `#294638`).<br>- Phụ đề: `type.body.medium` (`Be Vietnam Pro`, `14px Regular`, `#655E57`).<br>- Biểu tượng mùa vụ: `color.brand.accent` (`#C79B4B`). |
| **Spacing & Iconography** | - Icon `TreeEvergreen` + `Sparkle` (`48px`, `#C79B4B`) cách Logo `12px` (`space.3`).<br>- Phụ đề cách Logo `8px` (`space.2`). |
| **Main & Secondary Actions** | - Tự động chạy ngầm (`No manual click in Happy Path`).<br>- Nếu lỗi mạng: Nút Secondary **`[Thử kết nối lại]`** (`Cao 40px`). |
| **Navigation Behavior** | - Nếu mở app lần đầu (`has_seen_onboarding == false`) $\rightarrow$ `context.go('/onboarding')` (`M-AU-02`).<br>- Nếu đã mở trước đó (kể cả có Token hợp lệ hay đang là `Guest`) $\rightarrow$ `context.go('/home')` (`M-HM-01`).<br>- Nếu Token cũ đã bị thu hồi do tài khoản bị khóa (`403 Suspended` – `BR-AC-04`) $\rightarrow$ Xóa token và chuyển tới `/login?reason=suspended`. |
| **UI States (`Loading / Empty / Error / Success`)** | - **Loading:** Vòng xoay `20x20px` nét `2px` màu `#294638` kèm dòng chữ `12px #8C837A`: *"Đang mở cửa tiệm..."*<br>- **Empty:** *(Không áp dụng)*.<br>- **Error:** Khi timeout `> 10s` hoặc lỗi mạng, ẩn spinner và hiện `STATE-ERR-01` (*"Không thể kết nối tới máy chủ izithrift"*) kèm nút `[Thử lại]`.<br>- **Success:** Chuyển cảnh mượt (`FadeTransition 250ms`) sang `M-AU-02` hoặc `M-HM-01`. |

#### High-Fidelity Visual Preview (`M-AU-01` & `M-AU-02`):
```text
      [M-AU-01: SPLASH SCREEN]                       [M-AU-02: ONBOARDING SCREEN]
+-----------------------------------+          +-----------------------------------+
| 09:41                  WiFi 100%  |          | 09:41                  WiFi 100%  |
|                                   |          |                        [Bỏ qua >] |
|                                   |          | +-------------------------------+ |
|                                   |          | |   (Card Surface: #FAF5EC)     | |
|                                   |          | |       Border: 1px #D8CBB8     | |
|             ✨ 🎄 ✨              |          | |                               | |
|            (#C79B4B)              |          | |      [Minh họa Kính lúp &     | |
|                                   |          | |       Phiếu Kiểm Định Đồ Si]  | |
|           izithrift               |          | |                               | |
|   (Wichita Vintage 42px #294638)  |          | |  Săn Đồ Si Tuyển Chọn –       | |
|                                   |          | |  Minh Bạch Từng Vết Xước      | |
|   Tiệm Đồ Si Tuyển Chọn &         |          | |  (Fraunces 24px Bold #302D2A) | |
|     Đấu Giá Theo Phiên            |          | |                               | |
|  (Be Vietnam Pro 14px #655E57)    |          | |  Mọi món đồ đều được kiểm     | |
|                                   |          | |  duyệt ảnh và khai báo rõ     | |
|                                   |          | |  khuyết điểm trước khi bán.   | |
|                                   |          | +-------------------------------+ |
|                                   |          |           (━━━)  (•)  (•)         |
|              ( ↻ )                |          | +-------------------------------+ |
|       Đang mở cửa tiệm...         |          | | [Khám phá ngay (Guest) #294638]| |
|                                   |          | +-------------------------------+ |
|                                   |          | | [Đăng nhập / Đăng ký #FAF5EC] | |
|         [Home Indicator]          |          | +-------------------------------+ |
+-----------------------------------+          +-----------------------------------+
```

---

### 2.2. Screen `M-AU-02`: Vintage Christmas Onboarding Screen

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-AU-02` – Vintage Christmas Onboarding (`/onboarding`) |
| **Purpose** | Giới thiệu 3 trụ cột niềm tin của `izithrift` (Kiểm duyệt đồ si minh bạch, Đấu giá theo phiên có Anti-sniping, Giữ tiền bảo vệ Escrow) và cho phép chọn vào chế độ `Guest` (`DEC-01`) hoặc Đăng nhập. |
| **Entry Point** | Tự động chuyển từ `M-AU-01` khi mở ứng dụng lần đầu tiên. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)` $\rightarrow$ `SafeArea` $\rightarrow$ `Padding (16px)`:<br>1. `TopRow (Height 48px)`: `AlignRight` $\rightarrow$ `TertiaryButton [Bỏ qua ->]`<br>2. `Expanded`: `PageView.builder (3 Editorial Cards, Radius 16px, Bg #FAF5EC, Border 1px #D8CBB8, Padding 24px)`<br>3. `PageIndicatorRow (Height 24px)`: 3 dots (`Active: 24x6px #294638`, `Inactive: 6x6px #D8CBB8`)<br>4. `BottomActionColumn (Gap 12px)`: `PrimaryButton (48px)` + `SecondaryOutlinedButton (48px)`. |
| **Typography & Color Tokens** | - Tiêu đề Slide: `type.display.hero` (`Fraunces 24px Bold #302D2A`).<br>- Nội dung Slide: `type.body.medium` (`Be Vietnam Pro 14px Regular #655E57`, `lineHeight 20px`).<br>- Nút chính: `Bg #294638`, chữ `#FAF5EC` (`15px SemiBold`).<br>- Nút phụ: `Bg #FAF5EC`, viền `1.5px solid #294638`, chữ `#294638`. |
| **Main & Secondary Actions** | - **Main Action:** **`[Khám phá Tiệm ngay (Chế độ Khách)]`** $\rightarrow$ Ghi `has_seen_onboarding = true` và mở `/home`.<br>- **Secondary Actions:** **`[Đăng nhập / Tạo tài khoản]`** ($\rightarrow$ `/login`) hoặc **`[Bỏ qua ->]`** ($\rightarrow$ `/home`). |
| **UI States** | - **Default:** Vuốt ngang mượt giữa 3 slide.<br>- **Seasonal Toggle (`NFR-UX-02`):** Slide 1 hiển thị điểm nhấn trang trí Giáng sinh nhẹ nếu cờ mùa vụ bật. |

---

### 2.3. Screen `M-AU-03`: Login Screen (with Contextual Redirect Guard)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-AU-03` – Login Screen (`/login?redirect=...`) |
| **Purpose** | Xác thực người dùng bằng Email & Mật khẩu, cấp `Sanctum Token` và tự động đưa người dùng quay lại đúng màn hình đang thao tác dở (`DEC-01`). |
| **Entry Point** | Từ `M-AU-02`, từ `Guest Welcome Card` (Tab 4/Tab 5), hoặc bị chuyển hướng tự động từ `Auth Guard` khi `Guest` nhấn *Thêm vào giỏ / Mua ngay / Đặt giá thầu / Yêu thích / Chat*. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)` $\rightarrow$ `AppBar (56px)` $\rightarrow$ `SingleChildScrollView (Padding 16px)`:<br>1. `ContextualRedirectBanner` *(chỉ hiển thị khi có query param `redirect`)*<br>2. `AuthErrorAlertBanner` *(chỉ hiển thị khi gặp lỗi `401`, `403`, `429`)*<br>3. `BrandGreetingHeader (Padding vertical 20px)`<br>4. `LoginFormCard (Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 20px)`:<br>   - `EmailTextField (CMP-FRM-01, 48px)`<br>   - `SizedBox(height: 16)`<br>   - `PasswordTextField (CMP-FRM-01, 48px, Show/Hide Toggle)`<br>   - `AlignRight`: `TertiaryButton [Quên mật khẩu?]`<br>   - `SizedBox(height: 20)`<br>   - `PrimaryButton [Đăng nhập vào Tiệm] (48px, Full-width)`<br>5. `BottomRegisterSwitchRow (Padding top 24px)`. |
| **Typography & Color Tokens** | - Tiêu đề chào mừng: `type.heading.h1` (`Fraunces 24px Bold #302D2A`).<br>- Banner ngữ cảnh: Nền `#F7EFE0`, viền `#E8C28E`, chữ `#6B4F1D` (`13px Medium`).<br>- Nhãn Input: `14px SemiBold #302D2A`; Chữ trong Input: `16px Regular #302D2A`. |
| **Main & Secondary Actions** | - **Main Action:** **`[Đăng nhập vào Tiệm]`** (`POST /api/v1/auth/login`).<br>- **Secondary Actions:** `[Quên mật khẩu?]` ($\rightarrow$ `M-AU-05`), `[Đăng ký tài khoản mới]` ($\rightarrow$ `M-AU-04`), `[Tiếp tục với tư cách Khách]` ($\rightarrow$ `/home`). |
| **Navigation Behavior** | - Đăng nhập thành công (`200 OK`): Lưu token vào `flutter_secure_storage`, tải thông tin user và gọi `context.go(redirectUri ?? '/home')`. |
| **UI States (`Loading / Error / Success`)** | - **Loading:** Nút chính hiện vòng xoay `20px` + chữ *"Đang đăng nhập..."*, khóa 2 ô input.<br>- **Validation Error (`422`):** Báo đỏ `#A62B2B` dưới ô trống hoặc email sai định dạng.<br>- **Auth Failed (`401`):** Hiện hộp cảnh báo đỏ đầu form: *"Email hoặc mật khẩu không chính xác."*<br>- **Suspended Account (`403` – `BR-AC-04`):** Hiện hộp cảnh báo `#7A1F1F`: *"Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên."*<br>- **Rate Limited (`429` – `NFR-SEC-04`):** Khóa nút đăng nhập kèm đếm ngược 60 giây. |

---

### 2.4. Screen `M-AU-04`: Register Unified C2C Account Screen

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-AU-04` – Register Unified Account (`/register`) |
| **Purpose** | Đăng ký tài khoản hợp nhất cho phép đồng thời thực hiện cả vai trò Buyer và Seller (`BR-AC-01`, `FR-AU-01`). |
| **Entry Point** | Từ `M-AU-03` (Login) hoặc từ nút `[Đăng ký tài khoản mới]` trên `Guest Welcome Card`. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)` $\rightarrow$ `AppBar (56px: 'Tạo tài khoản mới')` $\rightarrow$ `SingleChildScrollView (Padding 16px)`:<br>1. `UnifiedAccountInfoBadge (Bg #E3ECE7, Border 1px #9ACBB0, Radius 8px, Padding 12px)`<br>2. `RegisterFormCard (Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 20px, Gap 16px)`:<br>   - `DisplayNameField *` (Tên hiển thị & Tên Tiệm)<br>   - `EmailField *`<br>   - `PhoneField` (Tùy chọn, 10 chữ số)<br>   - `PasswordField *` (Min 8 ký tự)<br>   - `PasswordConfirmField *`<br>   - `PrimaryButton [Hoàn tất Đăng ký & Vào Tiệm] (48px)`<br>3. `FooterLoginLink`. |
| **Typography & Color Tokens** | - Hộp thông báo hợp nhất: Icon `Storefront` + `ShoppingBag` (`20px #294638`), chữ `13px SemiBold #294638`.<br>- Nút chính: `color.brand.primary` (`#294638`). |
| **Main & Secondary Actions** | - **Main Action:** **`[Hoàn tất Đăng ký & Vào Tiệm]`** (`POST /api/v1/auth/register`).<br>- **Secondary Action:** `[Đã có tài khoản? Đăng nhập]` ($\rightarrow$ `M-AU-03`). |
| **UI States (`Loading / Error / Success`)** | - **Loading:** Nút chính hiển thị spinner *"Đang khởi tạo tài khoản..."*.<br>- **Error `422`:** Hiển thị lỗi cụ thể dưới từng trường (ví dụ: *"Email này đã được sử dụng"*, *"Mật khẩu xác nhận không khớp"*).<br>- **Success (`201 Created`):** Hiển thị Toast xanh `#236343` (*"Chào mừng bạn đến với izithrift!"*) và điều hướng về `redirectUri` hoặc `/home`. |

#### High-Fidelity Visual Preview (`M-AU-03` Login & `M-AU-04` Register):
```text
      [M-AU-03: LOGIN SCREEN]                        [M-AU-04: REGISTER SCREEN]
+-----------------------------------+          +-----------------------------------+
| [<-]        Đăng nhập        [X]  |          | [<-]     Tạo tài khoản mới        |
+-----------------------------------+          +-----------------------------------+
| +-------------------------------+ |          | +-------------------------------+ |
| | 🔒 Đăng nhập để tiếp tục      | |          | | 🏪🛍️ 1 Tài khoản duy nhất cho | |
| |    [Đặt giá thầu] (DEC-01)    | |          | | cả Mua sắm & Mở tiệm (BR-AC-01)| |
| +-------------------------------+ |          | +-------------------------------+ |
|     Chào mừng trở lại tiệm        |          | +-------------------------------+ |
|   (Fraunces 24px Bold #302D2A)    |          | | Tên hiển thị / Tên Tiệm *     | |
| +-------------------------------+ |          | | [ Nguyễn Minh Đức           ] | |
| | Email đăng nhập *             | |          | | Email đăng nhập *             | |
| | [✉️ minhduc@uit.edu.vn      ] | |          | | [ minhduc@uit.edu.vn        ] | |
| |                               | |          | | Số điện thoại (Tùy chọn)      | |
| | Mật khẩu *                    | |          | | [ 0901234567                ] | |
| | [🔒 ••••••••••••       [👁️] ] | |          | | Mật khẩu (Tối thiểu 8 ký tự)* | |
| |              [Quên mật khẩu?] | |          | | [ ••••••••••••         [👁️] ] | |
| | +---------------------------+ | |          | | Nhập lại mật khẩu *           | |
| | |  [ ĐĂNG NHẬP VÀO TIỆM ]   | | |          | | [ ••••••••••••         [👁️] ] | |
| | +---------------------------+ | |          | | +---------------------------+ | |
| +-------------------------------+ |          | | | [ HOÀN TẤT ĐĂNG KÝ ]      | | |
|   Chưa có tài khoản? [Đăng ký ->] |          | | +---------------------------+ | |
+-----------------------------------+          +-----------------------------------+
```

---

### 2.5. Screen `M-AU-05`: Password Recovery (Forgot & Reset Password)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-AU-05` – Forgot & Reset Password (`/forgot-password`) |
| **Purpose** | Cho phép người dùng yêu cầu mã khôi phục mật khẩu và đặt lại mật khẩu mới (`FR-AU-04`, `ASM-04`). |
| **Entry Point** | Nhấn `[Quên mật khẩu?]` từ màn hình `M-AU-03 (Login)`. |
| **Layout & 2-Step State Structure** | `Scaffold (Bg #F4EBDD)` $\rightarrow$ `AppBar ('Khôi phục mật khẩu')` $\rightarrow$ `Padding (16px)`:<br>- **Step 1 Card (`State: RequestEmail`):** Nhập `email` $\rightarrow$ Nhấn **`[Gửi mã khôi phục]`** (`POST /auth/forgot-password`).<br>- **Step 2 Card (`State: VerifyAndReset` – Mở ra sau khi Step 1 thành công):**<br>  - Banner thông báo xanh (`#E3F2EA` / `#236343`): *"Mã khôi phục đã được gửi tới email của bạn (Hiệu lực 15 phút)."*<br>  - Input 1: `Mã xác nhận khôi phục (Reset Token) *` (`JetBrains Mono 15px`).<br>  - Input 2: `Mật khẩu mới *` (Min 8 ký tự).<br>  - Input 3: `Xác nhận mật khẩu mới *`.<br>  - Nút Primary: **`[Đặt lại mật khẩu mới]`** (`POST /auth/reset-password`). |
| **UI States (`Loading / Error / Success`)** | - **Error `422`:** *"Mã khôi phục không hợp lệ hoặc đã hết hạn"* hoặc *"Không tìm thấy tài khoản với email này"*.<br>- **Success:** Hiện Dialog/Toast xác nhận đổi mật khẩu thành công và điều hướng về `M-AU-03 (Login)`. |