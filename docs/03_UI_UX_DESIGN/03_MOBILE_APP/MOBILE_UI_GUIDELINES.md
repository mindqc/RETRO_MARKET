# 01. MOBILE UI FOUNDATION & PRODUCT CARD SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P303-MOBILE-GUIDELINES`
- **Version:** `1.0.0 (HIGH-FIDELITY CORE FOUNDATION)`
- **Status:** `READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – Task P3-03 (Group 1: Mobile UI Foundation)`
- **Compliance Ref:** `UI-DEC-01..04`, `DS-DEC-01..03`, `NAV-DEC-01..03`, `ADR-07`

---

## Chương 1. Khung Kiến Trúc Màn Hình Di Động Chuẩn (`Mobile Viewport, Safe Area & App Shell`)

### 1.1. Thông Số Kỹ Thuật Khung Nhìn (`Viewport & Responsive Rules`)
- **Thiết bị tham chiếu chuẩn (`Primary Design Frame`):** `390px x 844px` (Tỷ lệ 19.5:9).
- **Dải co giãn hỗ trợ (`Responsive Breakpoints`):**
  - **Compact Mobile (`360px – 375px`):** Lề trang giữ nguyên `16px` (`space.4`), chiều rộng mỗi `Product Card` trên lưới 2 cột tự động co về `(Viewport - 32 - 12) / 2` (`152px – 159.5px`).
  - **Standard Mobile (`390px – 430px`):** Chiều rộng mỗi `Product Card` từ `173px – 193px`.
- **Quản lý Vùng An Toàn (`Safe Area Insets`):**
  - **Top Safe Area (`44px – 54px`):** Nền đồng màu với thanh `Top App Bar` ngay bên dưới (`#F4EBDD` cho các màn hình Mua sắm/Cá nhân; `#294638` cho Kênh Bán theo `UI-DEC-02`).
  - **Bottom Safe Area (`34px` cho Home Indicator):** Nền đồng màu với thanh `Bottom Navigation Bar` (`#FAF5EC`) hoặc `Sticky Bottom Action Bar` (`#FFFDF9`).
  - **Scroll Content Safe Padding:** Mọi danh sách cuộn (`CustomScrollView` / `ListView`) bắt buộc có `padding.bottom = 88px` để phần tử cuối cùng không bao giờ bị thanh điều hướng che khuất.

---

### 1.2. Đặc Tả High-Fidelity Cho Khung Điều Hướng Toàn Cục (`Global App Bar & 5-Tab Bottom Navigation – NAV-DEC-01`)

#### A. Global Top Utility Bar (`CMP-NAV-01A` – Cao `56px`)
- **Surface & Border:** Nền `color.bg.mobile.canvas` (`#F4EBDD`), viền đáy `1px solid color.divider.hairline` (`#E5D9C8`). Khi người dùng cuộn trang xuống `> 8px`, bật bóng đổ ấm `elevation.2` (`0px 4px 12px rgba(48, 45, 42, 0.08)`).
- **Cấu trúc 3 vùng ngang (`Padding trái/phải = 16px`):**
  1. **Vùng Trái (Brand / Back):**
     - Trên màn hình gốc (`M-HM-01`): Icon `TreeEvergreen` (`18px #294638`, chỉ hiển thị khi `enableSeasonalChristmasDecor == true` – `NFR-UX-02`) + Chữ **`izithrift`** (`type.brand.logo`: `Wichita Vintage 24px #294638`).
     - Trên màn hình con (`Push Screen`): Nút `IconButton` `[<-]` (`ArrowLeft 24px #302D2A`, khung chạm `48x48px`).
  2. **Vùng Giữa (Search Trigger / Screen Title):**
     - Trên `M-HM-01`, `M-DS-02`: Hộp kích hoạt tìm kiếm (`Cao 38px`, nền `#FAF5EC`, viền `1px solid #D8CBB8`, `radius.full = 9999px`, padding ngang `12px`, icon `MagnifyingGlass 18px #655E57`, chữ `Be Vietnam Pro 13px #8C837A`).
     - Trên màn hình chức năng: Tiêu đề trang (`type.heading.h3`: `Fraunces 18px SemiBold #302D2A`, tối đa 1 dòng `ellipsis`).
  3. **Vùng Phải (Global Utility Icons):**
     - Cụm 3 nút `IconButton` (`Icon 22px #302D2A`, vùng chạm tối thiểu `40x48px` mỗi nút):
       - **Giỏ hàng (`ShoppingBag` $\rightarrow$ `/cart`):** Gắn badge tròn (`Min-width 16px, Cao 16px`, nền `#873A43`, chữ `#FAF5EC 10px Bold tabular-nums`).
       - **Tin nhắn (`ChatCircleDots` $\rightarrow$ `/chat`):** Badge đếm số cuộc trò chuyện chưa đọc (`M-CM-01`).
       - **Thông báo (`Bell` $\rightarrow$ `/notifications`):** Badge đếm thông báo chưa đọc (`M-NT-01`).

#### B. 5-Tab Bottom Navigation Bar (`CMP-NAV-01B` – Cao `64px` + Bottom Safe Area)
- **Surface & Border:** Nền `color.surface.mobile.card` (`#FAF5EC`), viền trên `1px solid color.border.default` (`#D8CBB8`).
- **Chi tiết 5 Tab (`Mỗi Tab rộng 20% = 78px trên màn hình 390px`):**

| Thứ tự | Nhãn Tiếng Việt | Icon (`Phosphor Icons`) | Trạng Thái `Inactive` | Trạng Thái `Active` (Đang chọn) |
| :---: | :--- | :--- | :--- | :--- |
| **Tab 1** | `Trang chủ` | `House` | Outline `22px #655E57` + Chữ `11px Regular #655E57` | Pill nền `#E3ECE7` (`48x28px`, `radius.full`) + Icon Fill `#294638` + Chữ `11px SemiBold #294638` |
| **Tab 2** | `Khám phá` | `Compass` | Outline `22px #655E57` + Chữ `11px Regular #655E57` | Pill nền `#E3ECE7` + Icon Fill `#294638` + Chữ `11px SemiBold #294638` |
| **Tab 3** | `Đấu giá` | `Gavel` | Outline `22px #655E57` + Chữ `11px Regular #655E57` | Pill nền `#F4E5E7` + Icon Fill **`#873A43`** + Chữ `11px SemiBold #873A43` *(Nhấn mạnh Sàn Đấu Giá)* |
| **Tab 4** | `Kênh Bán` | `Storefront` | Outline `22px #655E57` + Chữ `11px Regular #655E57` | Pill nền `#E3ECE7` + Icon Fill `#294638` + Chữ `11px SemiBold #294638` |
| **Tab 5** | `Cá nhân` | `UserCircle` | Outline `22px #655E57` + Chữ `11px Regular #655E57` | Pill nền `#E3ECE7` + Icon Fill `#294638` + Chữ `11px SemiBold #294638` |

---

## Chương 2. Đặc Tả High-Fidelity Component Trọng Tâm: `CMP-COM-01 Product Card` (4 Variants)

Tuân thủ yêu cầu Mục 7 của `P3-03`, `Product Card` được thiết kế tinh gọn, **cấm nhồi nhét quá 2 badge trên ảnh** để không che khuất món đồ secondhand, đồng thời phân biệt rõ 4 biến thể:

### 2.1. Cấu Trúc Kích Thước & Quy Tắc Xử Lý Text Dài Trên `Product Card`
- **Chiều rộng thẻ (trên lưới 2 cột màn hình `390px`):** `173px` (`(390 - 16*2 - 12) / 2`).
- **Khung Ảnh (`Image Container`):** Tỷ lệ cố định **`4:5`** (`173px x 216px`), bo góc trên `12px`, nền chờ `#E7DAC6`, `BoxFit.cover`.
- **Quy tắc chống vỡ khung do tên tiếng Việt dài:**
  - Tên sản phẩm bắt buộc cố định chiều cao **2 dòng (`height = 40px`, `fontSize = 14px`, `lineHeight = 20px`, `maxLines = 2`, `overflow = TextOverflow.ellipsis`)**. Dù tên sản phẩm chỉ có 1 dòng ngắn hay 3 dòng dài thì chiều cao tổng thể của 2 thẻ nằm cạnh nhau trên cùng một hàng luôn bằng nhau tuyệt đối (`Total Card Height = 318px`).
- **Quy tắc tối giản Badge trên ảnh (`Anti-Clutter Rule`):**
  - Góc trên trái (`Top-Left`, cách lề `8px`): Chỉ đặt **1 Badge duy nhất** (Với hàng Giá cố định là `Condition Badge`; với hàng Đấu giá là `LIVE / Upcoming Badge`).
  - Góc trên phải (`Top-Right`, cách lề `8px`): Nút `Favorite Heart` tròn (`32x32px` hiển thị, vùng chạm mở rộng `44x44px`, nền mờ `rgba(250, 245, 236, 0.85)`, icon `18px #302D2A` khi chưa lưu / `Fill #873A43` khi đã lưu).

---

### 2.2. Bản Vẽ High-Fidelity & Thông Số Token Cho 4 Variants Của `Product Card`

```text
   [VARIANT 1: FIXED-PRICE PRODUCT]                  [VARIANT 2: AUCTION PRODUCT (TICKET STUB)]
+--------------------------------------+          +--------------------------------------+
| [Good (#E3EFF3/#2B5B6C)]        (♡)  |          | [🔴 LIVE (#873A43/#FAF5EC)]     (♡)  |
|                                      |          |                                      |
|         [ ẢNH SẢN PHẨM 4:5 ]         |          |         [ ẢNH SẢN PHẨM 4:5 ]         |
|           (173px x 216px)            |          |           (173px x 192px)            |
|        Màu gốc trung thực 100%       |          +--------------------------------------+
|                                      |          | ⏳ 04:12:08 (#FAF5EC) | 🔥 09 bids    | <-- Dải đếm ngược (Cao 24px, Bg #873A43)
+--------------------------------------+          +--------------------------------------+
| Áo Khoác Dạ Tweed Cổ Điển Mùa...     |          | Đồng Hồ Cơ Seiko 5 Mặt Vuông...      |
| (Be Vietnam Pro 14px SemiBold #302D2A|          | (Be Vietnam Pro 14px SemiBold #302D2A|
|  Cố định cao 2 dòng = 40px)          |          o - - - - - - - - - - - - - - - - - - -o <-- Rãnh vé nét đứt (#B8A892)
|                                      |          | Giá hiện tại: 850.000đ (#873A43 Bold)|
| 450.000đ  (16px Bold #294638 Tabular)|          | 🏪 Retro Watch  | Tình trạng: Good   |
| 🏪 Tiệm Nhà Gấu               ★ 4.9  |          +--------------------------------------+
+--------------------------------------+

      [VARIANT 3: SOLD PRODUCT]                     [VARIANT 4: UNAVAILABLE / RESTRICTED]
  (Hiển thị trên M-US-03 & M-PF-05)                (Khi món đồ trong Favorites vừa bị ẩn)
+--------------------------------------+          +--------------------------------------+
| [Like New]                      (♥)  |          | [Ngừng giao dịch]               (♥)  |
|   +------------------------------+   |          |                                      |
|   |   Lớp phủ rgba(48,45,42,0.45)|   |          |     [ Ảnh làm mờ Opacity 50% ]       |
|   |    [ ĐÃ BÁN (SOLD OUT) ]     |   |          |     Icon Lock / EyeSlash ở giữa      |
|   +------------------------------+   |          |                                      |
+--------------------------------------+          +--------------------------------------+
| Túi Da Đeo Chéo Coach Vintage 1995   |          | Áo Len Thổ Cẩm Cổ Điển               |
|                                      |          |                                      |
| 680.000đ  (16px Bold #655E57 Muted)  |          | Không còn khả dụng (#8C837A)         |
| 🏪 Tiệm Nhà Gấu         [Đã bán hết] |          | [ 🗑️ Xóa khỏi danh sách yêu thích ]  |
+--------------------------------------+          +--------------------------------------+
```

---

## Chương 3. Chuẩn Hóa 4 Trạng Thái Giao Diện Dùng Chung (`Standardized Loading, Empty, Error & Disabled States`)

Để tránh việc mỗi màn hình tự vẽ một kiểu thông báo khác nhau, toàn bộ các màn hình trong `P3-03` kế thừa 4 mẫu trạng thái chuẩn dưới đây:

1. **`STATE-LOAD-01` (Shimmer Skeleton State):**
   - Khung xương bo góc `8px–12px` chuyển màu nhịp nhàng giữa `#EAE3D9` và `#F4EBDD` (chu kỳ `1200ms`). Tuyệt đối không dùng màn hình trắng trơn với 1 vòng xoay đơn độc ở giữa.
2. **`STATE-EMP-01` (Vintage Empty State Card):**
   - Khung căn giữa màn hình (`Padding 32px`): Icon minh họa nét mảnh `56x56px` màu `#8C837A` (kèm họa tiết ngôi sao `#C79B4B` nếu bật cờ Giáng sinh) + Tiêu đề `Fraunces 18px SemiBold #302D2A` + Mô tả nguyên nhân `Be Vietnam Pro 14px #655E57` + Nút hành động gợi ý (`Secondary Button` cao `40px`).
3. **`STATE-ERR-01` (Recoverable Error State Card):**
   - Khung nền `#FCE8E8`, viền `1px solid #E5A6A6`, `radius.md = 12px`, padding `20px`: Icon `WarningCircle 32px #A62B2B` + Thông báo tiếng Việt rõ nghĩa + Nút **`[🔄 Thử tải lại]`**.
4. **`STATE-DIS-01` (Disabled & Self-Action Guard State – `BR-AC-02`):**
   - Mọi nút bị khóa đều chuyển sang nền `#E5DDD2`, chữ `#ACA399`, kèm chú thích lý do ngay bên cạnh hoặc qua Toast nhẹ để người dùng hiểu vì sao nút không bấm được.