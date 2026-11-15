# 01. ADMIN DASHBOARD LAYOUT SHELL & RBAC NAVIGATION UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P306A-ADMIN-LAYOUT`
- **Version:** `1.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – Task P3-06 (Group 1: Admin Layout & Authentication)`
- **Screen IDs Covered:** `A-AU-01` (Admin Login) & `Admin App Layout Shell` (Applied across all `A-*` screens)
- **Compliance Ref:** `AFW-01`, `PERM-AU-01`, `BR-AC-04`, `UI-DEC-03`, `DS-DEC-01..03`, `NFR-SEC-02`, `NFR-ENV-02`

---

## Chương 1. Kiến Trúc Khung Bố Cục Quản Trị Web (`Laravel Blade Admin App Shell`)

Trang quản trị **Retro Market Admin Dashboard** (`/admin/*`) được tối ưu hóa cho màn hình Desktop (`1440px x 900px`, hỗ trợ responsive xuống `1024px`) với 3 nguyên tắc thiết kế cốt lõi:
1. **Nhận diện Thương hiệu Đồng nhất – Bề mặt Đọc Tối ưu (`UI-DEC-03`):**
   - **Left Sidebar (`260px`):** Sử dụng màu chủ đạo **`Forest Pine #294638`** với chữ sáng `#FAF5EC` và điểm nhấn `Antique Brass #C79B4B` để tạo sự kết nối thị giác trực tiếp với ứng dụng di động `izithrift`.
   - **Main Content Area (`calc(100vw - 260px)`):** Sử dụng nền **`Light Warm Ivory #FBF9F5`** và mặt thẻ **`#FFFFFF`** (viền `1px solid #D8CBB8`) để tối đa hóa độ tương phản (`13.8:1` AAA), giúp Admin, Moderator và Support Staff làm việc với bảng dữ liệu nhiều cột và đối chiếu ảnh bằng chứng mà không bị mỏi mắt.
2. **Điều hướng Lọc Động Theo Vai Trò (`Role-Aware Sidebar Menu`):**
   - Hệ thống sử dụng một Layout Blade chung (`<x-admin.layout>`), nhưng các nhóm menu bên trái tự động ẩn/hiện dựa trên vai trò thực tế của tài khoản đang đăng nhập (`Administrator`, `Moderator`, `Support Staff`) và biến môi trường `DEMO_MODE=true`.
3. **Bố cục Chuyên biệt Cho Từng Tác Vụ Quản Trị (`3 Admin Layout Archetypes`):**
   - **Archetype A – KPI Overview (`A-DB-01`):** Lưới 12 cột gồm các thẻ chỉ số thời gian thực từ PostgreSQL.
   - **Archetype B – Data Table & Filter Workspace (`A-PR-01`, `A-OR-01`, `A-PM-01`, `A-ES-01`, `A-US-01`, `A-AD-01`):** Khối thanh lọc đa điều kiện (`Filter Panel`) ở trên + Bảng dữ liệu chuẩn kế toán (`Data Table`) + Thanh phân trang (`Pagination`) ở dưới.
   - **Archetype C – Split-Pane Inspection & Decision Room (`A-MD-02` Kiểm duyệt sản phẩm & `A-DP-02` Phân xử tranh chấp):** Chia màn hình làm 2 cột ngang (**7 cột Trái** hiển thị ảnh phóng to & lịch sử bằng chứng; **5 cột Phải** ghim cố định `position: sticky` chứa bảng thông tin đối chiếu và cụm nút ra quyết định).

---

## Chương 2. Đặc Tả High-Fidelity `Admin Layout Shell` & Màn Hình `A-AU-01`

### 2.1. Khung Bố Cục Chuẩn `Admin App Layout Shell` (`resources/views/components/admin/layout.blade.php`)

| Thành Phần Khung | Kích Thước & Vị Trí | Design Tokens & Styling Chi Tiết | Hành Vi Tương Tác & Phân Quyền (`RBAC`) |
| :--- | :--- | :--- | :--- |
| **Fixed Left Sidebar** | Rộng `260px`, Cao `100vh`, Cố định bên trái (`position: fixed; left: 0; top: 0`). | - Nền: `color.bg.admin.sidebar` (`#294638`).<br>- Viền phải: `1px solid #1E352A`.<br>- Brand Header (`Cao 64px`): Logo `izithrift` (`Wichita Vintage 24px #FAF5EC`) + Huy hiệu nhỏ `ADMIN` (`Bg #C79B4B`, chữ `10px Bold #302D2A`).<br>- Tên nhóm Menu: `11px SemiBold #9ACBB0` viết hoa (`letter-spacing: +0.6px`), padding `16px 16px 6px`.<br>- Mục Menu (`Cao 42px`, `Margin 2px 12px`, `Radius 8px`):<br>  - `Default`: Icon `18px #E3ECE7` + Chữ `Be Vietnam Pro 14px Medium #FAF5EC`.<br>  - `Hover`: Nền `rgba(250, 245, 236, 0.08)`.<br>  - `Active`: Nền `#1E352A`, viền trái dày `3px solid #C79B4B`, icon Fill `#C79B4B`, chữ `14px SemiBold #FAF5EC`. | **Quy tắc Ẩn/Hiện Menu Theo Role:**<br>- **Nhóm 1 (Dashboard):** Hiện cho cả 3 vai trò.<br>- **Nhóm 2 (Kiểm duyệt & Danh mục):** Hiện cho `Admin` & `Moderator`; **ẩn hoàn toàn** với `Support Staff`.<br>- **Nhóm 3 (Quản lý Đấu giá):** Hiện đầy đủ cho `Admin`; `Moderator` chỉ thấy mục Giám sát; **ẩn hoàn toàn** với `Support Staff`.<br>- **Nhóm 4 (Đơn hàng, Thanh toán, Escrow & Khiếu nại):** `Admin` thấy cả 4 mục; `Support Staff` **chỉ thấy** `Đơn hàng (Assigned)` và `Khiếu nại (Assigned)`; `Moderator` bị ẩn toàn bộ nhóm này.<br>- **Nhóm 5 (Người dùng, Cấu hình, Audit Logs):** **Chỉ hiện cho `Administrator` (`ACT-05`)**.<br>- **Nhóm 6 (Developer Tools):** **Chỉ hiện cho `Administrator` KHI `DEMO_MODE == true`** (`NFR-ENV-02`). |
| **Sticky Top Admin Header** | Cao `64px`, Rộng `calc(100vw - 260px)`, Cố định đỉnh vùng nội dung. | - Nền: `#FFFFFF`, viền đáy `1px solid #D8CBB8`.<br>- **Trái:** Nút thu gọn Sidebar (trên Tablet `< 1024px`) + **Breadcrumb điều hướng** (`13px #655E57`, mục cuối `SemiBold #302D2A`: `Admin / Kiểm duyệt / Hàng chờ duyệt`).<br>- **Phải:**<br>  1. **Huy hiệu Môi trường (`Environment Pill`):** Nếu `DEMO_MODE == true` hiện pill vàng `#FDECC8` viền `#C79B4B` chữ `11px Bold #7A4B0E`: `🧪 DEMO MODE: ON`; nếu `false` hiện pill xanh `#E3ECE7` chữ `#294638`: `PRODUCTION`.<br>  2. **Thẻ Nhân sự Đăng nhập:** Avatar `34x34px` + Tên nhân sự (`13px SemiBold #302D2A`) + Huy hiệu Vai trò (`ADMINISTRATOR` `#294638` / `MODERATOR` `#28557A` / `SUPPORT STAFF` `#8C5A1B`) + Nút `[🚪 Đăng xuất]`. | Nhấn `[🚪 Đăng xuất]` gọi `POST /admin/logout`, hủy Session và chuyển về `A-AU-01 (/admin/login)`. |
| **Main Content Workspace** | `Margin-left: 260px`, `Padding: 24px 32px`, `Max-width: 1440px`. | - Nền: `color.bg.admin.canvas` (`#FBF9F5`).<br>- Khu vực hiển thị `Flash Alert Banner` (Thông báo thành công/lỗi sau khi submit form Blade) ngay phía trên tiêu đề trang. | Chứa nội dung của từng màn hình `A-DB-01` đến `A-DT-01`. |

---

### 2.2. Screen `A-AU-01`: Admin Portal Login Screen (`GET/POST /admin/login` – `AFW-01`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `A-AU-01` – Internal Administration Login (`/admin/login`) |
| **Purpose** | Xác thực nhân sự quản trị nội bộ (`Administrator`, `Moderator`, `Support Staff`) và chặn tuyệt đối tài khoản người dùng phổ thông (`Regular User` – `PERM-AU-01`). |
| **Layout & Visual Structure** | - Nền toàn trang: `color.bg.mobile.canvas` (`#F4EBDD`) với dải trang trí trên cùng màu `#294638` (`Cao 6px`).<br>- **Thẻ Đăng nhập Trung tâm (`Width 420px`, Căn giữa màn hình, `Bg #FFFFFF`, `Border 1px #D8CBB8`, `Radius 12px`, `Padding 32px`, `Elevation 2`):**<br>  - Header: Logo `izithrift` (`Wichita Vintage 32px #294638`) + Huy hiệu `INTERNAL ADMIN PORTAL` (`11px Bold #873A43`).<br>  - Tiêu đề: `Fraunces 22px Bold #302D2A` (*"Đăng nhập Hệ thống Quản trị"*).<br>  - Input 1: `Email quản trị *` (`Height 44px`, `Radius 8px`, `Border 1px #D8CBB8`).<br>  - Input 2: `Mật khẩu *` (`Height 44px`, nút hiện/ẩn mật khẩu).<br>  - Checkbox: `Ghi nhớ phiên đăng nhập`.<br>  - Nút Primary (`Height 46px`, `Full-width`, `Bg #294638`, `Text #FAF5EC`): **`[Đăng nhập Quản trị]`**. |
| **Security & Error States** | - **Regular User Attempt (`403`):** Nếu người dùng nhập đúng tài khoản mua/bán thường nhưng không có role nội bộ, hiển thị hộp báo lỗi đỏ (`Bg #FCE8E8`, viền `#A62B2B`, chữ `#A62B2B`): *"Tài khoản của bạn không có quyền truy cập Cổng Quản Trị."*<br>- **Account Suspended (`BR-AC-04`):** *"Tài khoản nội bộ này đang bị tạm khóa."* |

#### High-Fidelity Visual Preview (`Admin App Shell` & `A-AU-01`):
```text
+---------------------------------------------------------------------------------------------------+
| 🎄 izithrift [ADMIN] | Admin > Kiểm duyệt > Hàng chờ duyệt        | [🧪 DEMO MODE: ON] | 👤 Admin  |
+----------------------+----------------------------------------------------------------------------+
| [SIDEBAR: #294638]   | [MAIN WORKSPACE: #FBF9F5 | Padding: 24px 32px]                             |
|                      |                                                                            |
| 📊 TỔNG QUAN         |  Page Title (Fraunces 24px Bold #302D2A)                                   |
|  • Dashboard KPI     |  [Khung Filter Panel: #FFFFFF | Border 1px #D8CBB8 | Radius 12px]          |
|                      |  +----------------------------------------------------------------------+  |
| 🛡️ KIỂM DUYỆT & SP   |  | [Từ khóa...] [Danh mục v] [Trạng thái v] [Lọc] [Đặt lại]            |  |
|  • Hàng chờ duyệt *  |  +----------------------------------------------------------------------+  |
|  • Quản lý Sản phẩm  |                                                                            |
|  • Danh mục & Hãng   |  [Khung Data Table / Split-Pane Inspection: #FFFFFF | Radius 12px]         |
|  • Báo cáo & Review  |  +----------------------------------------------------------------------+  |
|                      |  | Header Table (#F4EBDD)                                               |  |
| 🔨 QUẢN LÝ ĐẤU GIÁ   |  | -------------------------------------------------------------------- |  |
|  • Khung giờ Phiên   |  | Data Rows (Height 52px, Hover #FBF9F5, Tabular Numerals)             |  |
|  • Giám sát Đấu giá  |  |                                                                      |  |
|                      |  +----------------------------------------------------------------------+  |
| 💳 GIAO DỊCH & TIỀN  |  | Pagination: Hiển thị 1–20 / 142 bản ghi              [< 1 2 3 >]   |  |
|  • Quản lý Đơn hàng  |  +----------------------------------------------------------------------+  |
|  • Phiên Thanh toán  |                                                                            |
|  • Sổ cái Escrow     |                                                                            |
|  • Xử lý Khiếu nại   |                                                                            |
|                      |                                                                            |
| ⚙️ HỆ THỐNG (ADMIN)  |                                                                            |
|  • Người dùng & Role |                                                                            |
|  • Cấu hình Phí/Giờ  |                                                                            |
|  • Nhật ký Kiểm toán |                                                                            |
|                      |                                                                            |
| 🧪 DEVELOPER TOOLS   |                                                                            |
|  • Demo Job Triggers |                                                                            |
+----------------------+----------------------------------------------------------------------------+
```