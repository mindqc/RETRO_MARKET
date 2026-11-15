# 04. MOBILE DISCOVERY, SEARCH & FILTER UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P303-DISCOVERY-SEARCH-UI`
- **Version:** `1.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – Task P3-03 (Group 4: Discovery and Search)`
- **Screen IDs Covered:** `M-DS-01` (Category & Brand Directory), `M-DS-02` (Search & Browse Results), `M-DS-03` (Multi-Criteria Filter & Sort Sheet)
- **Compliance Ref:** `BF-02`, `FR-CT-01`, `FR-DS-02`, `BR-PR-02`, `NFR-PER-02`, `UI-DEC-01..04`, `DS-DEC-01..03`

---

## Chương 1. Kiến Trúc Tìm Kiếm & Phân Loại Đồ Secondhand (`Discovery & Filtering UX Strategy`)

Mua đồ secondhand khác hoàn toàn với mua hàng mới sản xuất hàng loạt: mỗi món đồ thường chỉ có **1 chiếc duy nhất (`available_quantity = 1`)** với tình trạng độ mới (`condition`) và mức giá khác nhau. Do đó, cụm 3 màn hình `M-DS-01`, `M-DS-02`, `M-DS-03` được thiết kế với 4 cải tiến UX then chốt:
1. **Duyệt Kép Theo Danh Mục & Thương Hiệu (`Dual Taxonomy Directory` – `M-DS-01`):** Cho phép người mua duyệt theo cây Danh mục sản phẩm (`Categories`) hoặc tìm theo Thương hiệu cổ điển (`Brands`) ngay trên Tab 2.
2. **Hiển thị trực quan các Bộ lọc đang kích hoạt (`Visible Active Filter Chips` – `M-DS-02`):** Người dùng luôn nhìn thấy rõ mình đang lọc theo điều kiện nào (`[Giá cố định X]`, `[Good 85-94% X]`, `[200k - 600k X]`) và có thể gỡ từng điều kiện chỉ bằng 1 chạm mà không cần mở lại Bottom Sheet.
3. **Kiểm tra hợp lệ Khoảng giá ngay khi gõ (`Real-Time Price Range Validation` – `M-DS-03`):** Chặn ngay lập tức lỗi nhập `Giá tối thiểu > Giá tối đa` trước khi cho phép gọi API tìm kiếm.
4. **Truy vấn 100% từ PostgreSQL (`NFR-PER-02`):** Không lọc giả ở phía Client; mọi thay đổi từ khóa, bộ lọc hoặc tiêu chí sắp xếp đều gửi query parameters chuẩn về `GET /api/v1/products`.

---

## Chương 2. Đặc Tả High-Fidelity Từng Màn Hình (`M-DS-01`, `M-DS-02`, `M-DS-03`)

### 2.1. Screen `M-DS-01`: Category & Brand Directory (Tab 2 Root – `/discover`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-DS-01` – Category & Brand Directory (`/discover` – Tab 2 Root) |
| **Purpose** | Trung tâm phân loại giúp người dùng khám phá sản phẩm theo Danh mục (`Categories`), Thương hiệu (`Brands`) hoặc bắt đầu nhập từ khóa tìm kiếm (`FR-CT-01`, `BF-02`). |
| **Entry Point** | Chạm vào **Tab 2 (`Khám phá`)** trên thanh Bottom Navigation (`NAV-DEC-01`). |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `TopSearchAppBar (Height 64px, Padding 16px, Bg #F4EBDD)`:<br>   - `SearchInputBox (CMP-FRM-01 V4, Height 44px, Bg #FAF5EC, Border 1px #D8CBB8, Radius 8px)` + `[🛒 CartIconBtn]`.<br>2. `QuickKeywordTagsSection (Padding Horizontal 16px, Padding Bottom 12px)`:<br>   - Nhãn `12px SemiBold #655E57`: *"Từ khóa phổ biến"* + `Wrap (Spacing 8px)` chứa các pill gợi ý (`Bg #E7DAC6`, `Height 30px`, `Radius 9999px`).<br>3. `DirectorySegmentedTabs (Height 44px, Bg #FAF5EC, Border Top/Bottom 1px #D8CBB8)`:<br>   - **Tab 1:** `🗂️ Danh mục đồ si (Categories)`<br>   - **Tab 2:** `🏷️ Thương hiệu (Brands)`<br>4. `Expanded TabBarView`:<br>   - **Trong Tab 1 (`Categories Grid`):** `GridView (Padding 16px, 2 Columns, Gutter 12px, ChildHeight 84px)`: Mỗi thẻ danh mục (`Bg #FAF5EC`, viền `1px solid #D8CBB8`, `radius.md = 12px`, padding `14px`) gồm Icon danh mục (`28px #294638`), Tên danh mục (`Fraunces 15px SemiBold #302D2A`) và Số món đang bán (`12px Regular #655E57 tabular-nums`).<br>   - **Trong Tab 2 (`Brands List`):** Danh sách các thẻ thương hiệu (`Height 64px`, `Bg #FAF5EC`, viền dưới `1px #E5D9C8`) gồm Khung chữ cái đầu/Logo (`40x40px #E3ECE7`), Tên thương hiệu (`15px SemiBold #302D2A`), xuất xứ/mô tả ngắn và mũi tên `[->]`.<br>5. `BottomNavigationBar (Tab 2 'Khám phá' Active)`. |
| **Main & Secondary Actions** | - **Main Actions:**<br>  1. Chạm vào một Thẻ Danh mục $\rightarrow$ Điều hướng sang `M-DS-02` (`/discover/search?category_id=:id`).<br>  2. Chạm vào một Thương hiệu $\rightarrow$ Điều hướng sang `M-DS-02` (`/discover/search?brand_id=:id`).<br>  3. Nhập từ khóa vào ô Search và nhấn `Search/Enter` trên bàn phím $\rightarrow$ Mở `M-DS-02?q=:keyword`.<br>- **Secondary Action:** Chạm vào một Pill từ khóa gợi ý $\rightarrow$ Mở `M-DS-02?q=:tag`. |
| **UI States (`Loading / Empty / Error`)** | - **Loading:** Lưới 8 khung xương `84px` cho Categories.<br>- **Empty:** *"Chưa có danh mục hoặc thương hiệu nào được kích hoạt"*.<br>- **Error:** Hiển thị `STATE-ERR-01` kèm nút `[Thử lại]`. |

---

### 2.2. Screen `M-DS-02`: Search Screen & Search Results (`/discover/search`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-DS-02` – Search Input & Filtered Product Results (`/discover/search`) |
| **Purpose** | Cho phép nhập từ khóa tìm kiếm trực tiếp, hiển thị lưới sản phẩm khớp điều kiện truy vấn, quản lý các chip bộ lọc đang bật và sắp xếp kết quả (`FR-DS-02`, `BF-02`). |
| **Entry Point** | Từ thanh Search trên `M-HM-01` / `M-DS-01`, hoặc sau khi chọn một Danh mục / Thương hiệu. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `ActiveSearchTopBar (Height 60px, Padding Horizontal 12px, Bg #F4EBDD, Border Bottom 1px #E5D9C8)`:<br>   - `BackIconButton [<-] (48x48px)`<br>   - `Expanded`: `SearchTextField (Height 42px, Bg #FFFDF9, Border 1.5px #294638 when focused, Radius 8px, Clear Button [X], TextInputAction.search)`<br>   - `TextButton [Tìm] (14px SemiBold #294638)`.<br>2. `FilterAndSortStickyToolbar (Height 48px, Bg #FAF5EC, Border Bottom 1px #D8CBB8, Padding Horizontal 16px)`:<br>   - **Trái:** Nút **`[🎛️ Bộ lọc (N)]`** (`Height 34px`, `Radius 8px`; khi `N == 0`: nền `#E7DAC6` chữ `#302D2A`; khi `N > 0`: nền `#294638` chữ `#FAF5EC`).<br>   - **Phải:** Nút mở menu sắp xếp **`[↕️ Sắp xếp: Mới nhất v]`** (`13px SemiBold #302D2A`).<br>3. `ActiveFilterChipsStrip (Height 42px, Bg #F4EBDD, Padding Left 16px – Chỉ hiển thị khi N > 0)`:<br>   - `Horizontal ListView` các chip đang lọc (`Bg #E3ECE7`, viền `1px #9ACBB0`, chữ `12px SemiBold #294638` kèm icon `[✕]` `14px`) + Nút cuối dải `[Xóa tất cả]` (`12px #A62B2B`).<br>4. `ResultCountBar (Height 32px, Padding Horizontal 16px)`:<br>   - Dòng thông báo `12px Medium #655E57`: *"Hiển thị 24 kết quả cho 'Áo khoác da'"*.<br>5. `Expanded`: `GridView.builder (Padding 16px, 2 Columns, Gutter 12px, ChildAspectRatio 173/318)` hiển thị `CMP-COM-01 Product Cards` + `PaginationLoader` ở cuối danh sách. |
| **Sorting Options (`Sort Menu`)** | Khi nhấn `[↕️ Sắp xếp]`, hiển thị Popover / Mini Sheet với 4 lựa chọn có dấu tích `✓` ở mục đang chọn:<br>1. `Mới lên kệ nhất (sort=newest)` *(Mặc định)*<br>2. `Giá: Từ thấp đến cao (sort=price_asc)`<br>3. `Giá: Từ cao đến thấp (sort=price_desc)`<br>4. `Phổ biến / Nhiều người thích nhất (sort=popular)`. |
| **UI States (`Loading / Empty / Error / Success`)** | - **Typing / Suggestions State:** Khi ô tìm kiếm đang focus và người dùng đang gõ, hiển thị lớp gợi ý từ khóa gần đây bên dưới thanh Search.<br>- **Loading (`STATE-LOAD-01`):** Hiển thị 6 khung xương `Product Card` trong lưới 2 cột.<br>- **Empty (`STATE-EMP-01` – Không tìm thấy kết quả):** Khi API trả về `total == 0`, hiển thị ở giữa màn hình: Icon `MagnifyingGlass 56px #8C837A` + Tiêu đề `Fraunces 18px SemiBold #302D2A`: *"Không tìm thấy món đồ nào khớp điều kiện"* + Mô tả `14px #655E57`: *"Thử nới rộng khoảng giá, bỏ bớt bộ lọc tình trạng hoặc tìm với từ khóa ngắn gọn hơn."* + Nút Secondary **`[🔄 Xóa toàn bộ bộ lọc]`**.<br>- **Error (`STATE-ERR-01`):** Báo lỗi kết nối + nút `[Thử lại]`. |

#### High-Fidelity Visual Preview (`M-DS-01` Directory & `M-DS-02` Search Results):
```text
   [M-DS-01: CATEGORY & BRAND DIRECTORY]          [M-DS-02: SEARCH & FILTER RESULTS]
+---------------------------------------+      +---------------------------------------+
| [ 🔍 Tìm đồ si, thương hiệu... ] [🛒2]|      | [<-] [ 🔍 Áo khoác da      [X] ] [Tìm]|
+---------------------------------------+      +---------------------------------------+
| Từ khóa: (#ÁoKhoácDa) (#Seiko) (#Túi) |      | [🎛️ Bộ lọc (2) #294638] [↕️ Mới nhất v]|
+---------------------------------------+      +---------------------------------------+
| [ 🗂️ Danh mục đồ si* ] [ 🏷️ Thương hiệu]|      | [Giá cố định ✕] [Good ✕] [Xóa tất cả] |
+---------------------------------------+      +---------------------------------------+
| +-----------------+ +---------------+ |      | Tìm thấy 14 món đồ khớp điều kiện     |
| | 🧥              | | 👖            | |      | +-----------------+ +---------------+ |
| | Áo khoác Vintage| | Quần Jean & Kaki|      | | [Good]      (♡) | | [Good]    (♡) | |
| | 48 sản phẩm     | | 36 sản phẩm   | |      | |                 | |               | |
| +-----------------+ +---------------+ |      | | [Ảnh: Áo Da Bò] | | [Ảnh: Áo Biker| |
| +-----------------+ +---------------+ |      | |  (173 x 216px)  | |  (173 x 216px)| |
| | 👜              | | ⌚            | |      | +-----------------+ +---------------+ |
| | Túi xách & Ví da| | Đồng hồ cổ điển|      | | Áo Khoác Da Bò  | | Áo Khoác Da   | |
| | 29 sản phẩm     | | 18 sản phẩm   | |      | | Thập Niên 90    | | Biker Cổ Điển | |
| +-----------------+ +---------------+ |      | | 950.000đ        | | 1.150.000đ    | |
| +-----------------+ +---------------+ |      | | 🏪 Retro Corner | | 🏪 Nhà Gấu    | |
| | 👞              | | 🕯️            | |      | +-----------------+ +---------------+ |
| | Giày & Boots da | | Đồ Decor Retro| |      | +-----------------+ +---------------+ |
| | 22 sản phẩm     | | 31 sản phẩm   | |      | | [Good]      (♡) | | [Good]    (♡) | |
| +-----------------+ +---------------+ |      | | [Ảnh sản phẩm 3]| | [Ảnh SP 4]    | |
+---------------------------------------+      +-----------------+ +---------------+ |
| [Trang chủ][Khám phá*][Đấu giá][Bán][Tôi]|    |        ( ↻ Đang tải thêm... )         |
+---------------------------------------+      +---------------------------------------+
```

---

### 2.3. Screen `M-DS-03`: Multi-Criteria Filter Bottom Sheet (`Modal Bottom Sheet`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-DS-03` – Multi-Criteria Filter Sheet *(Modal Bottom Sheet trên `M-DS-02` & `M-HM-02`)* |
| **Purpose** | Cung cấp bộ lọc đa tiêu chí chuyên sâu dành riêng cho đồ secondhand (Loại hình bán, Tình trạng `condition`, Khoảng giá `min-max`, Danh mục, Thương hiệu). |
| **Entry Point** | Nhấn nút **`[🎛️ Bộ lọc]`** trên thanh công cụ của `M-DS-02` hoặc `M-HM-02`. |
| **Layout & Component Hierarchy** | `ModalBottomSheet (MaxHeight 85% Viewport, Bg #FFFDF9, TopRadius 16px, Elevation 3)`:<br>1. `SheetHeader (Height 56px, Padding Horizontal 16px, Border Bottom 1px #D8CBB8)`:<br>   - `DragHandle (40x4px #D8CBB8)` ở đỉnh.<br>   - Trái: Nút `[Đóng X]` (`48x48px`); Giữa: Tiêu đề `Fraunces 18px SemiBold #302D2A` (*"Bộ lọc tìm kiếm"*); Phải: Nút chữ **`[Thiết lập lại]`** (`14px SemiBold #873A43`).<br>2. `Expanded SingleChildScrollView (Padding 16px, Divider #E5D9C8 giữa các nhóm)`:<br>   - **Nhóm 1 – Hình thức mua bán (`listing_type`):** 3 Choice Chips (`Tất cả` \| `🏷️ Giá cố định` \| `🔨 Đấu giá theo phiên`).<br>   - **Nhóm 2 – Tình trạng món đồ (`condition` – `BR-PR-03`):** 4 Choice Chips có mô tả rõ:<br>     - `Like New (Như mới 95–99%)`<br>     - `Good (Tốt 85–94%)`<br>     - `Fair (Khá – có dấu hiệu sử dụng)`<br>     - `Vintage Worn (Phong trần cổ điển)`<br>   - **Nhóm 3 – Khoảng giá (`min_price` – `max_price` VNĐ):**<br>     - Hàng 1: 2 ô `Currency Numeric Input` (`Cao 44px`, font `tabular-nums`): `[ Giá từ (VNĐ) ]` — `[ Giá đến (VNĐ) ]`.<br>     - Hàng 2: Dòng báo lỗi validation đỏ `#A62B2B` *(ẩn khi hợp lệ, hiện ngay khi `min_price > max_price`)*.<br>     - Hàng 3: 4 Pill chọn nhanh (`< 200.000đ`, `200k – 500k`, `500k – 1.000.000đ`, `> 1.000.000đ`).<br>   - **Nhóm 4 – Danh mục & Thương hiệu:** Danh sách `FilterChip` chọn nhanh.<br>3. `StickySheetFooter (Height 72px, Padding 12px 16px, Bg #FFFDF9, Border Top 1px #D8CBB8)`:<br>   - `PrimaryButton (Height 48px, Full-width, Bg #294638)`: **`[Áp dụng bộ lọc]`**. |
| **Validation & Error States** | - **Price Range Error State:** Nếu người dùng nhập `min_price = 800.000` và `max_price = 300.000` (`min > max`), viền cả 2 ô lập tức chuyển sang `1.5px solid #A62B2B`, hiển thị dòng chữ `12px Regular #A62B2B`: *"⚠️ Giá tối thiểu không được lớn hơn giá tối đa"*, đồng thời nút **`[Áp dụng bộ lọc]`** chuyển sang trạng thái **`Disabled`** (`Bg #E5DDD2`, chữ `#ACA399`) cho đến khi người dùng sửa lại hợp lệ. |

#### High-Fidelity Visual Preview (`M-DS-03` Filter Bottom Sheet):
```text
+-----------------------------------------------------------------------+
|                              ( ━━━━━ )                                |
| [X]                       Bộ lọc tìm kiếm             [Thiết lập lại] |
+-----------------------------------------------------------------------+
|  1. HÌNH THỨC MUA BÁN (listing_type)                                  |
|  ( [✓] Tất cả )   ( 🏷️ Giá cố định )   ( 🔨 Đấu giá theo phiên )       |
|  -------------------------------------------------------------------  |
|  2. TÌNH TRẠNG ĐỒ SECONDHAND (condition - BR-PR-03)                   |
|  +-------------------------------+ +-------------------------------+  |
|  | [✓] Like New (Như mới 95-99%) | | [✓] Good (Tốt 85-94%)         |  |
|  +-------------------------------+ +-------------------------------+  |
|  | [ ] Fair (Khá 75-84%)         | | [ ] Vintage Worn (Cổ điển)    |  |
|  +-------------------------------+ +-------------------------------+  |
|  -------------------------------------------------------------------  |
|  3. KHOẢNG GIÁ (VNĐ - Tabular Numerals)                               |
|  +-----------------------------+     +-----------------------------+  |
|  | Từ: 200.000             VNĐ |  —  | Đến: 800.000            VNĐ |  |
|  +-----------------------------+     +-----------------------------+  |
|  Chọn nhanh: (< 200k)  (200k - 500k)  (500k - 1 triệu)  (> 1 triệu)   |
|  -------------------------------------------------------------------  |
|  4. DANH MỤC SẢN PHẨM                                                 |
|  ( [✓] Áo khoác )  ( Quần Jean )  ( Túi da )  ( Đồng hồ )  ( Decor )  |
+-----------------------------------------------------------------------+
|  +-----------------------------------------------------------------+  |
|  |                [ ÁP DỤNG BỘ LỌC (XEM KẾT QUẢ) ]                 |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
```