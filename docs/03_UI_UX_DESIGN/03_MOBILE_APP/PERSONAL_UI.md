# 08. MOBILE PERSONAL PROFILE, ADDRESS BOOK & SETTINGS UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P303-PERSONAL-UI`
- **Version:** `1.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – Task P3-03 (Group 6B: Personal Profile & Settings)`
- **Screen IDs Covered:** `M-PF-01` (User Profile Hub), `M-PF-02` (Edit Personal & Shop Profile), `M-PF-03` (Shipping Address Book), `M-PF-04` (Add / Edit Address Form), `M-PF-06` (App Settings & Seasonal Theme Toggle)
- **Compliance Ref:** `FR-AU-03`, `FR-US-01..02`, `BR-AC-01`, `NAV-DEC-01..03`, `NFR-UX-02`, `UI-DEC-01..04`, `DS-DEC-01..03`

---

## Chương 1. Kiến Trúc Trung Tâm Cá Nhân & Quản Trị Tài Khoản Hợp Nhất (`Personal Hub Architecture`)

**Tab 5 – Cá nhân (`/profile` – `M-PF-01`)** là trung tâm điều hành dành cho vai trò **Người mua (`Buyer Context`)** và **Cài đặt Tài khoản chung (`Unified Account Settings`)**:
1. **Phân tách rõ Đơn Mua (`Tab 5`) và Đơn Bán (`Tab 4`) theo `NAV-DEC-02`:** Tại `M-PF-01`, khối lối tắt trạng thái đơn hàng được đặt tên rõ là **"Đơn Mua Của Tôi (`My Purchases`)"**, giúp người dùng không bao giờ nhầm với đơn khách đặt mua của tiệm mình (vốn nằm bên Tab 4 `Kênh Bán`).
2. **Hồ sơ Kép trong Một Form Duy Nhất (`M-PF-02`):** Vì 1 tài khoản vừa đi mua vừa mở tiệm bán hàng (`BR-AC-01`), màn hình chỉnh sửa hồ sơ `M-PF-02` cho phép cập nhật đồng thời thông tin liên hệ cá nhân và phần giới thiệu Tiệm đồ si (`Shop Bio`).
3. **Công tắc Chủ đề Mùa lễ hội Giáng sinh Thời gian thực (`Seasonal Theme Toggle` – `M-PF-06` & `NFR-UX-02`):** Tại màn hình Cài đặt `M-PF-06`, người dùng (và hội đồng chấm đồ án) có thể bật/tắt công tắc `Hiệu ứng trang trí Giáng sinh mùa vụ` để kiểm chứng kiến trúc tách lớp giao diện ngay lập tức.

---

## Chương 2. Đặc Tả High-Fidelity Từng Màn Hình (`M-PF-01..04` & `M-PF-06`)

### 2.1. Screen `M-PF-01`: User Profile Hub (Tab 5 Root – `/profile`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-PF-01` – User Profile Hub (`/profile` – Tab 5 Root) |
| **Purpose** | Trung tâm quản lý tài khoản cá nhân, lối tắt theo dõi **Đơn mua của tôi (`My Purchases`)**, Khiếu nại, Yêu thích, Sổ địa chỉ nhận hàng và Cài đặt ứng dụng (`FR-US-01`, `NAV-DEC-02`). |
| **Entry Point** | Chạm vào **Tab 5 (`Cá nhân`)** trên thanh Bottom Navigation (`NAV-DEC-01`). *(Nếu người dùng đang là `Guest`, phần thân hiển thị `CMP-GWC-01 Guest Welcome Card` theo `NAV-DEC-03`)*. |
| **Layout & Component Hierarchy (Khi đã đăng nhập `ACT-02`)** | `Scaffold (Bg #F4EBDD)`:<br>1. `TopAppBar (Height 56px, Bg #F4EBDD)`: Tiêu đề `Fraunces 20px Bold #302D2A` (*"Hồ sơ cá nhân"*) + Cụm phải `[⚙️ Cài đặt -> M-PF-06]` + `[🛒]` + `[🔔]`.<br>2. `Expanded SingleChildScrollView (Padding 16px, Gap 16px, Bottom Padding 88px)`:<br>   - **Card 1 – `UserIdentitySummaryCard (Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 16px)`:**<br>     - Hàng trên: Avatar `60x60px` (viền `2px #294638`), Tên hiển thị (`Fraunces 18px Bold #302D2A`), Email (`13px #655E57`), Huy hiệu `🛡️ Tài khoản C2C Hợp nhất` (`Bg #E3ECE7`, chữ `#294638`), nút phải `[✏️ Sửa]` ($\rightarrow$ `M-PF-02`).<br>     - Hàng dưới (`Margin Top 12px`, `Bg #E7DAC6`, `Radius 8px`, `Padding 10px 12px`, `Row SpaceBetween`):<br>       - Trái: Icon `Storefront 18px #294638` + Chữ `13px SemiBold #302D2A`: *"Muốn đăng bán đồ cũ hoặc xem Ví?"*<br>       - Phải: Nút nhỏ **`[Sang Kênh Bán ->]`** (Chuyển sang Tab 4 `/seller`).<br>   - **Card 2 – `MyPurchasesQuickEntryCard (Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 16px – NAV-DEC-02)`:**<br>     - Header: Tiêu đề `15px SemiBold #302D2A` (*"🛍️ Đơn mua của tôi"*) + Nút phải `[Xem lịch sử mua >]` ($\rightarrow$ Mở `M-OR-02`).<br>     - Lưới 5 Icon Trạng thái Đơn mua (`Padding Top 14px`, mỗi ô có badge đếm số đơn đang hoạt động):<br>       1. `[💳 Chờ trả QR]` (`PENDING_PAYMENT`)<br>       2. `[📦 Đang chuẩn bị]` (`PAID / PREPARING`)<br>       3. `[🚚 Đang giao]` (`SHIPPED`)<br>       4. `[✅ Chờ xác nhận]` (`DELIVERED` – *Nhắc xác nhận nhận hàng / giải ngân*)<br>       5. `[⭐ Đánh giá]` (`COMPLETED` chưa review).<br>   - **Card 3 – `AccountNavigationMenuCard (Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px)`:**<br>     - Danh sách các mục `ListTile (Height 54px, Divider 1px #E5D9C8)`:<br>       1. `🔨 Phiên đấu giá tham gia & Đã thắng` (Badge số phiên thắng chờ thanh toán) $\rightarrow$ Mở `M-AC-02`.<br>       2. `⚖️ Khiếu nại & Bảo vệ Escrow của tôi` (Badge số khiếu nại đang mở) $\rightarrow$ Mở `M-DP-02`.<br>       3. `♡ Món đồ yêu thích & Tiệm đang theo dõi` $\rightarrow$ Mở `M-PF-05`.<br>       4. `📍 Sổ địa chỉ nhận hàng` $\rightarrow$ Mở `M-PF-03`.<br>       5. `✏️ Chỉnh sửa hồ sơ cá nhân & Bio Tiệm` $\rightarrow$ Mở `M-PF-02`.<br>       6. `⚙️ Cài đặt ứng dụng & Giao diện mùa lễ hội` $\rightarrow$ Mở `M-PF-06`.<br>3. `BottomNavigationBar (Tab 5 'Cá nhân' Active)`. |

#### High-Fidelity Visual Preview (`M-PF-01` Profile Hub & `M-PF-06` Settings):
```text
      [M-PF-01: USER PROFILE HUB]                  [M-PF-06: APP SETTINGS & THEME]
+---------------------------------------+      +---------------------------------------+
| Hồ sơ cá nhân          [⚙️] [🛒2] [🔔]|      | [<-]        Cài đặt ứng dụng          |
+---------------------------------------+      +---------------------------------------+
| +-----------------------------------+ |      | 🎨 GIAO DIỆN & CHỦ ĐỀ MÙA VỤ (NFR-UX-02)|
| | (Avt) Nguyễn Minh Đức      [✏️ Sửa]| |      | +-----------------------------------+ |
| | 60x60 minhduc@uit.edu.vn          | |      | | 🎄 Hiệu ứng Giáng sinh ấm áp [ON] | |
| |       [🛡️ Tài khoản C2C Hợp nhất] | |      | | Hiển thị Hero Banner mùa lễ hội   | |
| | +-------------------------------+ | |      | | và điểm nhấn trang trí tinh tế.   | |
| | | 🏪 Đăng bán đồ? [Kênh Bán ->] | | |      | +-----------------------------------+ |
| | +-------------------------------+ | |      |                                       |
| +-----------------------------------+ |      | 🔒 BẢO MẬT TÀI KHOẢN                  |
| +-----------------------------------+ |      | +-----------------------------------+ |
| | 🛍️ Đơn mua của tôi  [Xem tất cả >]| |      | | Đổi mật khẩu đăng nhập            | |
| |                                   | |      | | Mật khẩu hiện tại *               | |
| | (💳)    (📦1)   (🚚1)  (✅1)  (⭐) | |      | | [ ••••••••••••              [👁️] ] | |
| | Chờ trả Chuẩn bị Giao  Đã giao Đ.Giá| |      | | Mật khẩu mới (Min 8 ký tự) *      | |
| +-----------------------------------+ |      | | [ ••••••••••••              [👁️] ] | |
| +-----------------------------------+ |      | | Xác nhận mật khẩu mới *           | |
| | 🔨 Đấu giá tham gia & Đã thắng [1]| |      | | [ ••••••••••••              [👁️] ] | |
| | --------------------------------- | |      | | [ Cập nhật mật khẩu (#294638) ]   | |
| | ⚖️ Khiếu nại & Bảo vệ Escrow      | |      | +-----------------------------------+ |
| | --------------------------------- | |      |                                       |
| | ♡  Yêu thích & Tiệm theo dõi (17) | |      | ℹ️ THÔNG TIN HỆ THỐNG                 |
| | --------------------------------- | |      | • Phiên bản: izithrift v1.0.0 (EC402) |
| | 📍 Sổ địa chỉ nhận hàng (02)      | |      |                                       |
| | --------------------------------- | |      | +-----------------------------------+ |
| | ⚙️ Cài đặt & Chủ đề Giáng sinh    | |      | | [ 🚪 Đăng xuất tài khoản (#A62B2B)]| |
| +-----------------------------------+ |      | +-----------------------------------+ |
| [Trang chủ][Khám phá][Đấu giá][Bán][Tôi*]|   +---------------------------------------+
+---------------------------------------+
```

---

### 2.2. Screen `M-PF-02`: Edit Personal & Shop Profile (`/profile/edit`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-PF-02` – Edit Personal & Seller Shop Profile (`/profile/edit`) |
| **Purpose** | Cho phép người dùng cập nhật ảnh đại diện, tên hiển thị/tên tiệm, số điện thoại và đoạn giới thiệu phong cách tiệm đồ si (`bio`) (`FR-US-01`, `NFR-SEC-05`). |
| **Entry Point** | Từ `M-PF-01` (nút `[✏️ Sửa]`), `M-SL-01` (Seller Dashboard), hoặc `M-US-03` (khi tự xem tiệm của mình). |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)` $\rightarrow$ `AppBar ('Chỉnh sửa hồ sơ')` $\rightarrow$ `SingleChildScrollView (Padding 16px)`:<br>1. `AvatarPickerSection (Center)`: Khung ảnh tròn `88x88px` (viền `2px #294638`) + Nút nhỏ góc dưới phải `[📷 Đổi ảnh]` (`jpg, png, webp <= 5MB` – `NFR-SEC-05`).<br>2. `ProfileFormCard (Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 20px, Gap 16px)`:<br>   - `DisplayNameField *`: *"Tên hiển thị / Tên Tiệm đồ si"* (`2–80 ký tự`).<br>   - `EmailReadOnlyField`: Hiển thị email đăng nhập (`Disabled Bg #EAE3D9`).<br>   - `PhoneField`: *"Số điện thoại liên hệ"* (`10 chữ số`).<br>   - `BioTextArea`: *"Giới thiệu bản thân & Phong cách Tiệm đồ si (Bio)"* (`Max 300 ký tự`, có bộ đếm `124/300`).<br>3. `StickyBottomBar`: `PrimaryButton (Height 48px, Bg #294638)`: **`[Lưu thay đổi hồ sơ]`**. |

---

### 2.3. Screen `M-PF-03` (Shipping Address Book) & `M-PF-04` (Add / Edit Address Form)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen IDs & Names** | - `M-PF-03`: Shipping Address Book List (`/profile/addresses`)<br>- `M-PF-04`: Add / Edit Shipping Address Form (`/profile/addresses/form`) |
| **Purpose** | Quản lý danh sách địa chỉ nhận hàng phục vụ đặt đơn Giá cố định (`M-OR-01`) và đơn thắng Đấu giá (`M-OR-03`) (`FR-US-02`). |
| **Layout `M-PF-03` (Address List)** | - `ListView.separated (Padding 16px, Gap 12px)`: Mỗi thẻ `AddressCard (Bg #FAF5EC, Border 1.5px #294638 nếu là địa chỉ mặc định / 1px #D8CBB8 nếu là địa chỉ phụ, Radius 12px, Padding 16px)`:<br>  - Hàng 1: Tên người nhận (`15px SemiBold #302D2A`) \| SĐT (`14px #655E57 tabular-nums`) + Huy hiệu **`[Mặc định]`** (`Bg #E3ECE7`, chữ `#294638`).<br>  - Hàng 2: Địa chỉ chi tiết, Phường/Xã, Quận/Huyện, Tỉnh/Thành phố (`14px Regular #302D2A`).<br>  - Hàng 3 (Chân thẻ): Nút `[Đặt làm mặc định]` + `[✏️ Sửa]` ($\rightarrow$ `M-PF-04`) + `[🗑️ Xóa]` (Hiện `Confirmation Dialog` trước khi xóa).<br>- `StickyBottomBar`: Nút `PrimaryButton`: **`[+ Thêm địa chỉ nhận hàng mới]`** ($\rightarrow$ `M-PF-04`). |
| **Layout `M-PF-04` (Address Form)** | - Form Card (`Bg #FAF5EC, Padding 20px, Gap 16px`):<br>  1. `Họ và tên người nhận *` (`recipient_name`).<br>  2. `Số điện thoại người nhận *` (`recipient_phone` – Validation 10 chữ số bắt đầu bằng `0`).<br>  3. `Tỉnh / Thành phố *` (`province_city` – Dropdown/Search Selector).<br>  4. `Quận / Huyện & Phường / Xã *` (`district_ward`).<br>  5. `Số nhà, tên đường, tòa nhà *` (`street_address`).<br>  6. `SwitchTile`: *"Đặt làm địa chỉ nhận hàng mặc định (`is_default`)"*.<br>- Nút Primary: **`[Lưu địa chỉ nhận hàng]`** (Nếu người dùng mở `M-PF-04` từ màn hình Checkout `M-OR-01`, sau khi lưu xong tự động `pop` trả địa chỉ mới về ngay cho `M-OR-01`). |

---

### 2.4. Screen `M-PF-06`: App Settings, Password Change & Seasonal Theme Toggle (`/profile/settings`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-PF-06` – App Settings & Seasonal Christmas Theme Toggle (`/profile/settings`) |
| **Purpose** | Cho phép bật/tắt lớp trang trí Giáng sinh mùa vụ (`enableSeasonalChristmasDecor` – `NFR-UX-02`), đổi mật khẩu tài khoản và đăng xuất an toàn (`FR-AU-03`). |
| **Entry Point** | Từ `M-PF-01` nhấn icon `[⚙️]` hoặc mục *"Cài đặt ứng dụng"*. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)` $\rightarrow$ `AppBar ('Cài đặt ứng dụng')` $\rightarrow$ `SingleChildScrollView (Padding 16px, Gap 20px)`:<br>1. **Khối 1 – `SeasonalThemeControlCard (Bg #FAF5EC, Border 1px #C79B4B, Radius 12px, Padding 16px – NFR-UX-02)`:**<br>   - Header: Icon `TreeEvergreen 22px #294638` + Tiêu đề `15px SemiBold #302D2A` (*"Hiệu ứng trang trí Giáng sinh mùa vụ"*) + Công tắc `Switch` (`Active #294638`).<br>   - Mô tả `13px Regular #655E57`: *"Bật hoặc tắt lớp trang trí lễ hội Giáng sinh (Hero Banner mùa vụ, biểu tượng cành thông & ngôi sao) trên toàn ứng dụng mà không làm thay đổi cấu trúc giao diện."*<br>2. **Khối 2 – `ChangePasswordCard (Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 16px)`:**<br>   - 3 ô Input (`Mật khẩu hiện tại *`, `Mật khẩu mới *`, `Xác nhận mật khẩu mới *`) + Nút Secondary **`[Cập nhật mật khẩu]`** (`PUT /users/password`).<br>3. **Khối 3 – `LogoutActionCard`:**<br>   - Nút `Destructive Outlined Button (Height 48px, Full-width, Bg #FCE8E8, Border 1.5px #A62B2B, Text #A62B2B)`: **`[🚪 Đăng xuất khỏi tài khoản]`**.<br>   - Khi nhấn: Hiển thị `Mandatory Confirmation Dialog (CMP-OVL-01)` $\rightarrow$ Gọi `POST /auth/logout`, xóa sạch `Sanctum Token` trong `flutter_secure_storage` và đưa về `/home` dưới quyền `Guest`. |