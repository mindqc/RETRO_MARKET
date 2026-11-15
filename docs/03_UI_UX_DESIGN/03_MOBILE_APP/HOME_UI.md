# 03. MOBILE HOME & CURATED COLLECTION UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P303-HOME-UI`
- **Version:** `1.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – Task P3-03 (Group 3: Home Experience)`
- **Screen IDs Covered:** `M-HM-01` (Home Screen), `M-HM-02` (Curated Vintage / Christmas Collection)
- **Compliance Ref:** `BF-01`, `FR-DS-01`, `BR-PR-02`, `UI-DEC-01..04`, `DS-DEC-01..03`, `NAV-DEC-01`

---

## Chương 1. Triết Lý Dàn Trang "Warm Editorial Archive" Trên Trang Chủ (`Home Experience Architecture`)

Trang chủ (`M-HM-01`) là mặt tiền thương hiệu của **`izithrift`**, nơi người dùng (cả `Guest` và `Registered User` theo `DEC-01`) bắt đầu hành trình săn đồ secondhand. Giao diện giải quyết 3 bài toán UX trọng tâm:
1. **Dàn trang như một tạp chí đồ cổ điển nhưng mua sắm nhanh như TMĐT hiện đại:** Khối đầu trang sử dụng `Editorial Hero Card` kết hợp thanh danh mục nhanh (`Quick Category Strip`), ngay bên dưới đi thẳng vào 2 luồng sản phẩm giá trị nhất: **Đấu giá đang diễn ra (`LIVE Auctions`)** và **Mới lên kệ sau kiểm duyệt (`Newly Approved`)**.
2. **Bảo chứng kiểm duyệt 100% (`BR-PR-02`):** Mọi sản phẩm xuất hiện trên `M-HM-01` và `M-HM-02` đều bắt buộc có `status == APPROVED`. Giao diện hiển thị phụ đề bảo chứng *"100% đã kiểm duyệt hình ảnh & tình trạng bởi Moderator"* để củng cố niềm tin ngay từ giây đầu tiên.
3. **Kiến trúc Trang trí Mùa lễ hội Tách lớp (`Modular Seasonal Layer – NFR-UX-02`):** Hero Banner và các điểm nhấn mùa lễ hội Giáng sinh được điều khiển bởi cờ `enableSeasonalChristmasDecor`. Khi tắt cờ này, banner tự động chuyển sang chủ đề *Warm Editorial Archive* quanh năm mà không làm xê dịch bất kỳ pixel bố cục nào.

---

## Chương 2. Đặc Tả High-Fidelity Từng Màn Hình (`M-HM-01` & `M-HM-02`)

### 2.1. Screen `M-HM-01`: Home Screen (Tab 1 Root – `/home`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-HM-01` – Home Screen (`/home` – Tab 1 Root) |
| **Purpose** | Điểm chạm trung tâm giới thiệu bộ sưu tập chủ đề, lối tắt danh mục, các phiên đấu giá đang `LIVE`/`ENDING SOON`, các món đồ secondhand vừa được Moderator duyệt và các tiệm uy tín (`FR-DS-01`, `BF-01`). |
| **Entry Point** | Tự động vào sau `M-AU-01` (Splash) / `M-AU-02` (Onboarding), hoặc chạm vào **Tab 1 (`Trang chủ`)** trên thanh Bottom Navigation (`NAV-DEC-01`). |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `GlobalTopUtilityBar (CMP-NAV-01A, Height 56px, Sticky Top)`:<br>   - `BrandCluster`: `[Optional TreeEvergreen Icon 18px #294638]` + `[Logo 'izithrift' 24px #294638]`<br>   - `SearchTriggerPill (Height 38px, Bg #FAF5EC, Border 1px #D8CBB8, Radius 9999px)`<br>   - `UtilityActionCluster`: `[CartIconBtn + Badge]` + `[ChatIconBtn + Badge]` + `[NotiBellBtn + Badge]`<br>2. `RefreshIndicator (Color #294638, Bg #FAF5EC)` $\rightarrow$ `CustomScrollView (Bottom Padding 88px)`:<br>   - **Section A – `SeasonalHeroBanner` (`Margin 16px`, `Height 188px`, `Radius 12px`):** Thẻ biên tập bộ sưu tập nổi bật.<br>   - **Section B – `QuickCategoryStrip` (`Height 88px`, `Margin Top 20px`):** Danh sách cuộn ngang 7 danh mục đồ si.<br>   - **Section C – `LiveAuctionSpotlight` (`Margin Top 24px`):** Header có huy hiệu `🔴 LIVE` + `Horizontal ListView` chứa các thẻ `CMP-COM-01 Variant 2 (Auction Ticket Card, Width 204px)`.<br>   - **Section D – `TrustedVintageShopsStrip` (`Margin Top 24px`):** Dải cuộn ngang các thẻ `SellerMiniCard (Width 156px, Height 76px)`.<br>   - **Section E – `NewlyApprovedGrid` (`Margin Top 24px`, `Padding Horizontal 16px`):** Header *"Mới lên kệ sau kiểm duyệt"* + `SliverGrid (2 Columns, CrossAxisSpacing 12px, MainAxisSpacing 12px, ChildAspectRatio 173/318)` hiển thị `CMP-COM-01 (Variant 1 & Variant 2)`.<br>3. `BottomNavigationBar (CMP-NAV-01B, Height 64px, Tab 1 Active)`. |
| **Typography & Color Tokens** | - **Hero Banner:** Nền `color.brand.primary` (`#294638`), viền trong `1px solid rgba(199, 155, 75, 0.45)` (`#C79B4B`), nhãn mùa vụ `type.label.badge` (`11px SemiBold #EED69F`), tiêu đề `type.heading.h2` (`Fraunces 20px Bold #FAF5EC`), mô tả `13px Regular #E3ECE7`, nút CTA nền `#FAF5EC` chữ `#294638` (`13px SemiBold`).<br>- **Section Headers:** Tiêu đề `type.heading.h3` (`Fraunces 18px SemiBold #302D2A`), phụ đề `type.caption.default` (`12px Regular #655E57`), nút link phải `13px SemiBold #294638`.<br>- **Category Item:** Khung tròn `52x52px` (`Bg #FAF5EC`, viền `1px solid #D8CBB8`), icon `24px #294638`, nhãn dưới `12px Medium #302D2A` (1 dòng). |
| **Spacing & Dimensions** | - Lề trang ngang: `16px` (`space.4`).<br>- Khoảng cách dọc giữa các Section: `24px` (`space.6`).<br>- Khoảng cách giữa Header Section và nội dung bên dưới: `12px` (`space.3`).<br>- Grid Gutter (giữa 2 cột thẻ sản phẩm): `12px` (`space.3`). |
| **Main & Secondary Actions** | - **Main Actions:**<br>  1. Chạm vào `Product Card (Fixed-Price)` $\rightarrow$ Mở `M-PR-01` (`/products/:id`).<br>  2. Chạm vào `Auction Ticket Card` $\rightarrow$ Mở `M-AC-03` (`/auctions/:id`).<br>  3. Chạm vào `Hero Banner CTA` $\rightarrow$ Mở `M-HM-02` (`/home/collections/:slug`).<br>- **Secondary Actions:**<br>  - Chạm vào `SearchTriggerPill` $\rightarrow$ Mở `M-DS-02` (`/discover/search` với bàn phím bật sẵn).<br>  - Chạm vào `Category Circle` $\rightarrow$ Mở `M-DS-02?category_id=...`.<br>  - Chạm vào nút `[♡]` trên thẻ sản phẩm $\rightarrow$ Toggle Favorite (`BF-11`, nếu là `Guest` thì chuyển sang `M-AU-03 Login` kèm `redirect=/home`).<br>  - Kéo xuống (`Pull-to-Refresh`) $\rightarrow$ Gọi lại cụm API làm mới Trang chủ. |
| **UI States (`Loading / Empty / Error / Success`)** | - **Loading (`STATE-LOAD-01`):** Hiển thị Shimmer Skeleton cho Hero Banner (`188px`), 5 vòng tròn danh mục, 2 thẻ đấu giá ngang và 4 thẻ lưới sản phẩm.<br>- **Empty (`Live Auctions Section`):** Nếu thời điểm hiện tại không có phiên nào đang `LIVE`, thay dải thẻ ngang bằng 1 hộp gọn (`Bg #FAF5EC`, viền `1px dashed #B8A892`, cao `84px`, padding `12px`): *"⏳ Hiện chưa có phiên đấu giá đang chạy. Phiên kế tiếp mở lúc 20:00 tối nay — [Xem lịch phiên ->]"*.<br>- **Error (`STATE-ERR-01`):** Nếu mất mạng khi mở app, hiển thị hộp lỗi kèm nút `[🔄 Thử tải lại]`.<br>- **Success:** Hiển thị đầy đủ dữ liệu phân trang (`Infinite Scroll` tải thêm mỗi lần 20 sản phẩm ở Section E). |

#### High-Fidelity Visual Preview (`M-HM-01` Home Screen – `390x844px`):
```text
+-----------------------------------------------------------------------+
| 09:41                                                      WiFi 100%  |
+-----------------------------------------------------------------------+
| 🎄 izithrift   [ 🔍 Tìm áo khoác, đồng hồ...      ]  [🛒2] [💬1] [🔔3] | <-- Top Utility Bar (56px, #F4EBDD)
+-----------------------------------------------------------------------+
|  +-----------------------------------------------------------------+  |
|  | 🎄 BỘ SƯU TẬP MÙA LỄ HỘI (#EED69F)         (Bg: #294638)        |  |
|  | Góc Đồ Si Ấm Áp Đêm Giáng Sinh             (Fraunces 20px Bold) |  |
|  | Tuyển chọn áo khoác dạ, len cổ điển & phụ kiện đã kiểm duyệt.   |  |
|  |                                                                 |  |
|  | [ Khám phá Bộ sưu tập -> ] (Btn 34px, Bg #FAF5EC, Text #294638) |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|   (🧥)        (👖)        (👜)        (⌚)        (👞)        (🕯️)    | <-- Quick Categories (52x52px)
|  Áo khoác   Quần Jean    Túi da     Đồng hồ    Giày dép    Đồ Decor   |
|                                                                       |
|  🔨 Đấu giá đang diễn ra  [🔴 LIVE]                   [Xem tất cả >]  |
|  +-----------------------------------+ +---------------------------+  |
|  | [🔴 LIVE]                    (♡)  | | [⏳ Sắp đóng]        (♡)  |  |
|  |      [ Ảnh: Seiko 5 1982 ]        | |   [ Ảnh: Túi Coach 90s ]  |  |
|  +-----------------------------------+ +---------------------------+  |
|  | ⏳ 04:12:08       | 🔥 09 bids    | | ⏳ 00:01:42   | 🔥 18 bids|  |
|  +-----------------------------------+ +---------------------------+  |
|  | Đồng Hồ Cơ Seiko 5 Mặt Vuông...   | | Túi Da Đeo Chéo Coach...  |  |
|  o - - - - - - - - - - - - - - - - - o o - - - - - - - - - - - - - o  | <-- Rãnh vé nét đứt (UI-DEC-01)
|  | Giá hiện tại: 850.000đ (#873A43)  | | Giá hiện tại: 1.250.000đ  |  |
|  +-----------------------------------+ +---------------------------+  |
|                                                                       |
|  🏪 Tiệm đồ si uy tín                                 [Khám phá >]    |
|  +------------------------------+ +------------------------------+    |
|  | (Avt) Tiệm Nhà Gấu           | | (Avt) Retro Watch SG         |    |
|  | ★ 4.9 (42) • 28 món đang bán | | ★ 5.0 (19) • 14 món đang bán |    |
|  +------------------------------+ +------------------------------+    |
|                                                                       |
|  ✨ Mới lên kệ sau kiểm duyệt            (🛡️ 100% Moderator Approved) |
|  +---------------------------------+ +-----------------------------+  |
|  | [Good (#E3EFF3)]           (♡)  | | [Like New (#E1F0E7)]   (♡)  |  |
|  |                                 | |                             |  |
|  |    [ Ảnh: Áo Khoác Dạ Tweed ]   | |   [ Ảnh: Áo Len Thổ Cẩm ]   |  |
|  |         (173px x 216px)         | |        (173px x 216px)      |  |
|  +---------------------------------+ +-----------------------------+  |
|  | Áo Khoác Dạ Tweed Cổ Điển Mùa   | | Áo Len Thổ Cẩm Đỏ Rượu Vang |  |
|  | Đông (Cố định 2 dòng = 40px)    | | Mùa Giáng Sinh              |  |
|  | 450.000đ (#294638 Bold Tabular) | | 320.000đ (#294638 Bold)     |  |
|  | 🏪 Tiệm Nhà Gấu          ★ 4.9  | | 🏪 Góc Cổ Điển       ★ 4.8  |  |
|  +---------------------------------+ +-----------------------------+  |
+-----------------------------------------------------------------------+
|  [🎄 Trang chủ*] [🔍 Khám phá]  [🔨 Đấu giá]  [🏷️ Kênh Bán]  [👤 Cá nhân]| <-- 5-Tab Bottom Nav (64px)
+-----------------------------------------------------------------------+
```

---

### 2.2. Screen `M-HM-02`: Curated Vintage / Christmas Collection Screen (`/home/collections/:slug`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-HM-02` – Curated Vintage / Christmas Collection (`/home/collections/:slug`) |
| **Purpose** | Trình bày danh sách sản phẩm được tuyển chọn theo một chủ đề biên tập cụ thể (ví dụ: *Áo Len & Khoác Dạ Giáng Sinh*, *Đồng Hồ & Phụ Kiện Thập Niên 80–90*) kèm bộ lọc nhanh. |
| **Entry Point** | Nhấn vào `Hero Banner CTA` hoặc các thẻ Bộ sưu tập trên `M-HM-01`. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)` $\rightarrow$ `AppBar (56px: '[<-] Bộ sưu tập tuyển chọn' + [🛒])` $\rightarrow$ `CustomScrollView`:<br>1. `EditorialCollectionHeaderCard (Margin 16px, Bg #E7DAC6, Border 1px #B8A892, Radius 12px, Padding 20px)`:<br>   - Nhãn: `CURATED ARCHIVE` (`11px SemiBold #873A43`).<br>   - Tiêu đề bộ sưu tập: `type.heading.h1` (`Fraunces 22px Bold #302D2A`).<br>   - Đoạn dẫn nhập biên tập: `type.body.medium` (`Be Vietnam Pro 14px Regular #655E57`, 2–3 dòng).<br>2. `StickyCollectionControlBar (Height 48px, Bg #FAF5EC, Border Top/Bottom 1px #D8CBB8, Padding Horizontal 16px)`:<br>   - Trái: Số lượng món đồ (`"24 món đồ đã duyệt"`).<br>   - Phải: Nút `[🎛️ Lọc]` (mở `M-DS-03`) + Dropdown `[Sắp xếp: Mới nhất v]`.<br>3. `CollectionProductSliverGrid (Padding 16px, 2 Columns, Gutter 12px)`: Lưới thẻ `CMP-COM-01`. |
| **UI States (`Loading / Empty / Error / Success`)** | - **Loading:** Shimmer cho Header Card + 6 khung xương `Product Card`.<br>- **Empty (`STATE-EMP-01`):** *"Hiện chưa có món đồ nào trong bộ sưu tập này"* + Nút `[Khám phá toàn bộ sản phẩm ->]` (dẫn sang `M-DS-02`).<br>- **Error:** Hiển thị `STATE-ERR-01` kèm nút `[Thử lại]`. |