# 03. SPACING AND LAYOUT SYSTEM SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P302-SPACING-LAYOUT`
- **Version:** `1.0.0`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`

---

## Chương 1. Thang Đo Khoảng Cách 4-Point (`4px Base Spacing Scale`)

Toàn bộ khoảng cách bên trong (`Padding`), khoảng cách bên ngoài (`Margin`) và khoảng cách giữa các phần tử (`Gap`) trên cả Flutter và Laravel Blade đều là bội số của **`4px`** (tuyệt đối cấm dùng các con số lẻ tùy tiện như `7px`, `13px`, `19px`):

| Token Name | Giá Trị (`px` / `dp`) | Mục Đích & Ngữ Cảnh Sử Dụng Chuẩn |
| :--- | :---: | :--- |
| `space.0` | `0px` | Không có khoảng cách. |
| `space.1` | `4px` | Khoảng cách nhỏ nhất: giữa icon và nhãn bên trong 1 Badge, hoặc giữa nhãn phụ và giá trị. |
| `space.2` | `8px` | Khoảng cách tiêu chuẩn giữa các phần tử liên quan chặt chẽ (giữa các chip bộ lọc, giữa tiêu đề thẻ và giá bán). |
| `space.3` | `12px` | Khoảng cách cột (`Grid Gutter`) giữa 2 `Product Card` trên Mobile; padding dọc của ô Input và Button vừa. |
| `space.4` | `16px` | **Lề chuẩn của trang Mobile (`Mobile Page Horizontal Margin`)**; padding bên trong của các thẻ thông tin (`Order Card`, `Inspection Slip`, `Seller Card`). |
| `space.5` | `20px` | Khoảng cách giữa các khối nội dung trong cùng một màn hình chi tiết. |
| `space.6` | `24px` | **Khoảng cách tách biệt giữa các Section lớn (`Section Spacing`)** trên Trang chủ, Chi tiết sản phẩm và Padding của `Bottom Sheet` / `Dialog`. |
| `space.8` | `32px` | Khoảng cách lề trang trên Desktop Admin (`Admin Page Margin`) và khoảng trống đầu/cuối màn hình xác thực. |
| `space.10` | `40px` | Khoảng cách phân tách các khu vực lớn trên màn hình rộng. |
| `space.12` | `48px` | **Kích thước vùng chạm tối thiểu chuẩn Accessibility (`Minimum Touch Target = 48x48px`)** và chiều cao chuẩn của Primary Button / Input Field. |

---

## Chương 2. Kiến Trúc Bố Cục Ứng Dụng Di Động (`Flutter Mobile Layout Grid & Safe Areas`)

### 2.1. Thông Số Khung Lưới Mobile (`Mobile Grid Specification`)
- **Reference Viewport:** `390px x 844px` (Hỗ trợ co giãn linh hoạt từ màn hình nhỏ `360px` đến màn hình lớn `430px`).
- **Columns:** **4 Cột (`4-Column Fluid Grid`)**.
  - Lưới sản phẩm (`M-HM-01`, `M-DS-02`, `M-AC-01`): Hiển thị **2 thẻ trên 1 hàng** (mỗi thẻ chiếm 2 cột).
  - Các thẻ thông tin chi tiết (`M-OR-01`, `M-OR-03`, `M-SL-06`): Chiếm trọn **4 cột (`100% Full Width`)**.
- **Page Horizontal Margin:** `16px` (`space.4`) cố định ở cả hai bên trái và phải.
- **Grid Gutter (Khoảng cách giữa các cột):** `12px` (`space.3`).

### 2.2. Vùng An Toàn & Chiều Cao Thanh Điều Hướng Cố Định (`Safe Area & Fixed Bars`)
- **Top Status Bar Safe Area:** Tự động lấy theo `MediaQuery.padding.top` của thiết bị.
- **Global Top App Bar Height:** `56px` (Chứa Logo/Nút Back, Thanh tìm kiếm và 3 icon `Cart`, `Chat`, `Notifications`).
- **5-Tab Bottom Navigation Bar Height (`NAV-DEC-01`):** `64px` + `MediaQuery.padding.bottom`.
- **Sticky Bottom Action Bar Height (trên `M-PR-01`, `M-AC-03`, `M-CR-01`, `M-OR-01`):** `72px` (Padding dọc `12px`, chứa nút CTA cao `48px`) + `MediaQuery.padding.bottom`.
- **Quy tắc chống che khuất nội dung cuộn:** Mọi `ScrollView` / `ListView` trên màn hình có thanh cố định dưới đáy bắt buộc thêm `bottomPadding >= 88px` để dòng nội dung cuối cùng không bao giờ bị thanh nút bấm che khuất.

---

## Chương 3. Kiến Trúc Bố Cục Trang Quản Trị Web (`Laravel Blade Admin Layout Grid`)

Khác với Mobile, giao diện Admin Dashboard được tối ưu cho màn hình máy tính để xử lý bảng dữ liệu nhiều cột, kiểm duyệt ảnh độ phân giải cao và đối soát sổ cái:

### 3.1. Khung Bố Cục Tổng Thể (`Admin App Shell`)
- **Reference Desktop Viewport:** `1440px x 900px` (Tối thiểu `1280px`).
- **Fixed Left Sidebar Width:** **`260px`** cố định bên trái (Nền `Forest Pine #294638`, hiển thị các nhóm menu theo quyền RBAC). Trên màn hình nhỏ `< 1024px`, Sidebar thu gọn thành ngăn kéo (`Collapsible Drawer`).
- **Top Admin Header Height:** **`64px`** cố định phía trên (Hiển thị Breadcrumb, Huy hiệu trạng thái `DEMO_MODE: ON/OFF` và thông tin tài khoản nội bộ đang đăng nhập).
- **Main Content Area:** Chiếm phần diện tích còn lại (`calc(100vw - 260px)`), giới hạn chiều rộng nội dung tối đa `max-width: 1440px`, lề trái/phải `32px` (`space.8`), sử dụng **Lưới 12 Cột (`12-Column CSS Grid`, Gutter `24px`)**.

### 3.2. Các Mẫu Bố Cục Chuyên Biệt Trên Admin (`Admin Page Archetypes`)
1. **Mẫu 1 – Dashboard Overview (`A-DB-01`):**
   - Hàng 1: 4 thẻ KPI vận hành (mỗi thẻ chiếm **3 cột** trên lưới 12 cột).
   - Hàng 2: 3 thẻ Đối soát dòng tiền Escrow & Buyer Protection Fee (mỗi thẻ chiếm **4 cột**).
   - Hàng 3: Bảng cảnh báo & Nhật ký kiểm toán gần đây (chiếm **12 cột**).
2. **Mẫu 2 – Split-Pane Inspection & Resolution (`A-MD-02` Kiểm duyệt sản phẩm & `A-DP-02` Phòng xử lý tranh chấp):**
   - **Cột Trái (Chiếm 7/12 cột):** Thư viện ảnh sản phẩm / ảnh bằng chứng khiếu nại độ phân giải cao, lịch sử kiểm duyệt (`product_moderation_logs`), timeline vận chuyển và lịch sử chat.
   - **Cột Phải (Chiếm 5/12 cột – Ghim cố định `Sticky Panel` khi cuộn):** Thông tin khai báo `defect_info`, bản chụp `order_items` và **Khung Ra Quyết Định Quản Trị** (Approve/Reject kèm lý do `DEC-05`, hoặc 3 phương án Phán quyết tài chính `DEC-07`).
3. **Mẫu 3 – Full-Width Data Table & Ledger (`A-OR-01`, `A-ES-01`, `A-AD-01`):**
   - Thanh công cụ lọc (`Filter Panel`) ở trên cùng (12 cột) + Bảng dữ liệu có thanh cuộn ngang an toàn và phân trang ở dưới (12 cột).

---

## Chương 4. Quy Chuẩn Bo Góc, Đường Viền & Đổ Bóng (`Border Radius, Stroke & Elevation`)

### 4.1. Thang Đo Bo Góc (`Border Radius Tokens`)
- `radius.xs` (`4px`): Dùng cho các nhãn nhỏ (`Tag`, `Status Badge`, `Condition Badge`) để giữ nét sắc sảo như chiếc mác vải cổ điển.
- `radius.sm` (`8px`): Dùng cho toàn bộ **Button**, **Text Field / Input**, **Dropdown**, và các ô ảnh thu nhỏ (`Thumbnail`).
- `radius.md` (`12px`): Dùng cho **`Product Card`**, **`Auction Card`**, **`Order Card`**, **`Inspection Slip`** và **`Data Table Container`** trên Admin.
- `radius.lg` (`16px`): Dùng cho **`Dialog`**, **`Modal`** và hai góc trên của **`Bottom Sheet` (`Top-Left & Top-Right = 16px`)**.
- `radius.full` (`9999px`): Dùng cho Avatar tròn, thanh tìm kiếm dạng viên thuốc (`Search Pill`) và nút cộng bước giá nhanh (`+50k`).

### 4.2. Độ Dày Đường Viền & Kiểu Viền (`Border Thickness & Styles`)
- `border.width.thin` (`1px solid`): Viền mặc định cho mọi thẻ sản phẩm, bảng biểu và hộp thông tin (`color.border.default #D8CBB8`).
- `border.width.focused` (`1.5px solid`): Viền khi ô Input đang được chọn (`#294638`) hoặc thẻ đang được tích chọn trong Giỏ hàng.
- `border.style.ticket_dashed` (`1.5px dashed #B8A892`): Đường kẻ nét đứt ngang đặc trưng dùng cho **Thẻ Vé Đấu Giá (`Auction Ticket Motif` – `UI-DEC-01`)** và **Phiếu Kiểm Định / Biên Lai Escrow (`Inspection & Receipt Slip`)**.

### 4.3. Hệ Thống Độ Nổi & Đổ Bóng Ấm (`Warm Elevation & Shadows`)
Không dùng bóng đen xám lạnh lẽo (`rgba(0,0,0,...)`), toàn bộ bóng đổ sử dụng tông nâu than ấm (`rgba(48, 45, 42, ...)`):
- `elevation.0` (`none`): Các khối phẳng phân tách bằng màu nền và viền `1px`.
- `elevation.1` (`0px 2px 6px rgba(48, 45, 42, 0.05)`): Đổ bóng cực nhẹ cho `Product Card`, `Auction Card` và `Admin Metric Card`.
- `elevation.2` (`0px 4px 12px rgba(48, 45, 42, 0.08)`): Dùng cho `Sticky Bottom Action Bar` và `Top Utility Bar` khi cuộn.
- `elevation.3` (`0px 8px 24px rgba(48, 45, 42, 0.14)`): Dùng cho `Bottom Sheet`, `Confirmation Dialog` và `Modal`.