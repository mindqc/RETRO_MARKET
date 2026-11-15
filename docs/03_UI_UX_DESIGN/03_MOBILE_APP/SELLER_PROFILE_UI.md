# 06. MOBILE PUBLIC SELLER PROFILE & VERIFIED REVIEWS UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P303-SELLER-PROFILE-UI`
- **Version:** `1.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – Task P3-03 (Group 5B: Public Seller Profile & Reviews)`
- **Screen IDs Covered:** `M-US-03` (Public Seller Profile, Trust Score & Verified Reviews)
- **Compliance Ref:** `BF-03`, `BF-09`, `BF-11`, `FR-US-03`, `FR-US-04`, `FR-RV-01`, `BR-AC-02`, `BR-RV-01`, `UI-DEC-01..04`

---

## Chương 1. Thiết Kế Hồ Sơ Tiệm Bán Công Khai & Hệ Thống Đánh Giá Xác Thực (`Seller Credibility Architecture`)

Trong mô hình C2C Secondhand, người mua không chỉ đánh giá món đồ mà còn đánh giá **độ trung thực của người bán** (mô tả lỗi có chuẩn không, đóng gói có kỹ không, giao hàng có đúng hẹn không). Màn hình `M-US-03` (`/sellers/:id`) được thiết kế để hiển thị minh bạch uy tín của tiệm:
1. **Chỉ hiển thị Đánh giá từ Đơn hàng Hoàn tất thực tế (`100% Verified Completed Order Reviews – BR-RV-01`):** Không ai có thể bình luận tự do vào hồ sơ người bán nếu chưa từng mua và hoàn tất đơn hàng (`order_status == COMPLETED`). Mỗi thẻ đánh giá đều gắn kèm **Bản chụp món đồ đã mua (`Purchased Item Mini-Card`)** làm bằng chứng giao dịch thật.
2. **Bảng Chỉ Số Tin Cậy 3 Cột (`Seller Trust Scorecard`):** Hiển thị rõ Điểm đánh giá trung bình (`★ 1.0 – 5.0`), Tổng số đơn bán thành công, và Chỉ số uy tín (`Trust Score`).
3. **Tự động nhận diện khi Chủ tiệm xem trang công khai của chính mình (`BR-AC-02`):** Nếu `auth.id == seller_id`, ẩn nút `[+ Theo dõi]` và `[💬 Chat]`, thay bằng nút lối tắt `[✏️ Chỉnh sửa Hồ sơ Tiệm (M-PF-02)]`.

---

## Chương 2. Đặc Tả High-Fidelity Màn Hình `M-US-03`: Public Seller Profile & Reviews (`/sellers/:id`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-US-03` – Public Seller Profile, Shop Listings & Verified Reviews (`/sellers/:id`) |
| **Purpose** | Hiển thị thông tin công khai của người bán, các chỉ số uy tín, danh sách sản phẩm đang đăng bán (`APPROVED` / `SOLD`) và toàn bộ đánh giá xác thực từ người mua trước (`FR-US-03`, `FR-RV-01`). |
| **Entry Point** | Chạm vào `SellerSummaryEntryCard` từ `M-PR-01`, `M-AC-03`, dải Tiệm uy tín trên `M-HM-01`, danh sách Đang theo dõi trên `M-PF-05`, hoặc nút `[👁️ Xem Tiệm]` từ `M-SL-01`. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)` $\rightarrow$ `NestedScrollView`:<br>1. `TopSellerAppBar (Height 56px, Bg #F4EBDD)`:<br>   - Trái: `BackIconButton [<-]`<br>   - Giữa: Tên tiệm rút gọn (`Fraunces 17px SemiBold`)<br>   - Phải: `[🛒 CartIconBtn]` + `[⋮ ReportUserBtn -> M-CM-03 (Report User)]`<br>2. **Header – `SellerStorefrontBannerCard (Bg #FAF5EC, Border Bottom 1px #D8CBB8, Padding 16px)`:**<br>   - **Hàng 1 (Identity & Action Row):**<br>     - Avatar tròn `64x64px` (viền `2px solid #C79B4B`).<br>     - Khối tên bên cạnh: Tên Tiệm (`type.heading.h2`: `Fraunces 20px Bold #302D2A`), nhãn thành viên (`"Thành viên từ 2025"` – `12px #655E57`), huy hiệu `🛡️ Đã xác minh thông tin`.<br>   - **Hàng 2 (Shop Bio):** Mô tả phong cách tiệm (`type.body.medium`: `14px Regular #302D2A`, tối đa 3 dòng).<br>   - **Hàng 3 (Trust Scorecard Box – `Bg #E7DAC6`, `Border 1px #B8A892`, `Radius 8px`, `Padding 12px`, 3 Cột chia đều bằng đường kẻ dọc `#B8A892`):**<br>     - *Cột 1 (Đánh giá):* **`★ 4.9`** (`16px Bold #302D2A tabular-nums`, ngôi sao `#C79B4B`) + Phụ đề `"42 đánh giá"` (`11px #655E57`).<br>     - *Cột 2 (Đã bán):* **`68 món`** (`16px Bold #302D2A tabular-nums`) + Phụ đề `"Đơn hoàn tất"`.<br>     - *Cột 3 (Uy tín):* **`98%`** (`16px Bold #236343 tabular-nums`) + Phụ đề `"Điểm tin cậy"`.<br>   - **Hàng 4 (Action Buttons Row – `Margin Top 14px`, `Gap 12px`):**<br>     - *(Khi `auth.id != seller_id`):*<br>       - Nút 1 (`Expanded, Height 40px`): **`[+ Theo dõi Tiệm]`** (`Primary Button #294638`; khi đã theo dõi đổi thành **`[✓ Đang theo dõi]`** nền `#E3ECE7`, viền `#294638`, chữ `#294638` – `BF-11`).<br>       - Nút 2 (`Expanded, Height 40px`): **`[💬 Chat với Tiệm]`** (`Secondary Outlined Button` $\rightarrow$ Mở `M-CM-02` – `BF-12`).<br>     - *(Khi `auth.id == seller_id` – `BR-AC-02`):*<br>       - Nút Full-width (`Height 40px`): **`[✏️ Chỉnh sửa Hồ sơ & Bio Tiệm (M-PF-02)]`**. <br>3. **Sticky Tab Bar (`Height 48px, Bg #FAF5EC, Border Bottom 1px #D8CBB8`):**<br>   - **`Tab 1: Sản phẩm của Tiệm (28)`**<br>   - **`Tab 2: Đánh giá từ Người mua (42)`**<br>4. **Body – `TabBarView`:**<br>   - **Nội dung Tab 1 (`Shop Listings Tab`):**<br>     - Thanh lọc phụ (`Padding 12px 16px`, 3 Choice Chips): `[Đang bán (28)]` \| `[Đấu giá (03)]` \| `[Đã bán (68)]`.<br>     - Lưới 2 cột (`CMP-COM-01`: Variant 1 cho hàng giá cố định, Variant 2 cho hàng đấu giá, Variant 3 cho hàng đã bán `SOLD`).<br>   - **Nội dung Tab 2 (`Verified Reviews Tab`):**<br>     - Khối tổng hợp tỷ lệ sao (`Rating Breakdown Bar`: `5 sao`, `4 sao`, `3 sao`, `2 sao`, `1 sao`).<br>     - Danh sách `VerifiedReviewCard (Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 16px, Margin Bottom 12px)`:<br>       - Header Review: Avatar người mua `32x32px`, Tên người mua (`14px SemiBold #302D2A`), Huy hiệu nhỏ `[✓ Đã mua hàng]` (`#236343`), Ngày đánh giá (`12px #8C837A tabular-nums`).<br>       - Dải sao: `★★★★★` (`14px #C79B4B`).<br>       - Nội dung nhận xét: `type.body.medium` (`14px Regular #302D2A`, `lineHeight 20px`).<br>       - **Khung Món Đồ Đã Mua (`Purchased Snapshot Mini-Box`: `Margin Top 10px`, `Bg #E7DAC6`, `Radius 6px`, `Padding 8px`):** Ảnh snapshot `36x36px` + Tên món đồ đã mua (`12px Medium #302D2A`) + Giá lúc mua (`12px SemiBold #294638 tabular-nums`). |
| **UI States (`Loading / Empty / Error`)** | - **Loading:** Shimmer cho Header Tiệm + 4 thẻ sản phẩm / đánh giá.<br>- **Empty (`Tab 1 – Sản phẩm`):** *"Tiệm hiện chưa có món đồ nào đang mở bán."*<br>- **Empty (`Tab 2 – Đánh giá`):** Icon `Star 48px #8C837A` + *"Tiệm chưa có đánh giá nào từ các đơn hàng hoàn tất."*<br>- **Error (`404 / Suspended Seller`):** Nếu tài khoản người bán đã bị Admin khóa (`SUSPENDED` / `BANNED`), hiển thị màn hình thông báo *"Tiệm bán này hiện đang tạm ngưng hoạt động"*. |

#### High-Fidelity Visual Preview (`M-US-03` Public Seller Profile & Verified Reviews):
```text
+-----------------------------------------------------------------------+
| [<-]                   Tiệm Đồ Si Nhà Gấu              [🛒2] [⋮ Báo cáo]|
+-----------------------------------------------------------------------+
|  +-----------------------------------------------------------------+  |
|  | (Avatar)  🏪 Tiệm Đồ Si Nhà Gấu     [🛡️ Đã xác minh]           |  |
|  |  64x64px  Thành viên từ 10/2025 • TP. Hồ Chí Minh               |  |
|  |                                                                 |  |
|  | "Chuyên tuyển chọn áo khoác dạ, len cổ điển Nhật - Âu thập niên |  |
|  |  80-90. Cam kết chụp thật từng vết xước nhỏ nhất."              |  |
|  |                                                                 |  |
|  | +-------------------+---------------------+-------------------+ |  |
|  | |    ★ 4.9 / 5.0    |       68 đơn        |       98%         | |  |
|  | |   (42 đánh giá)   |   (Đã bán hoàn tất) |  (Điểm tin cậy)   | |  |
|  | +-------------------+---------------------+-------------------+ |  |
|  |                                                                 |  |
|  | [ + Theo dõi Tiệm (#294638) ]   |   [ 💬 Chat với Tiệm ]        |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
|  [ 📦 Sản phẩm của Tiệm (28) ]   |   [ ★ Đánh giá từ Người mua (42)* ]|
+-----------------------------------------------------------------------+
|  Lọc đánh giá: ( Tất cả 42 )  ( 5 Sao: 40 )  ( 4 Sao: 02 )            |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | (Avt) Trần Bảo Ngọc   [✓ Đã mua hàng (#236343)]     12/11/2026  |  |
|  | ★★★★★ (#C79B4B)                                                 |  |
|  | "Áo dạ bên ngoài đẹp hơn cả trong ảnh, vết xước nhẹ ở cúc thứ 2 |  |
|  |  đúng y như shop đã ghi trong phiếu kiểm định. Đóng gói thơm!"  |  |
|  | +-------------------------------------------------------------+ |  |
|  | | [Ảnh 36x36] Sản phẩm đã mua: Áo Khoác Dạ Tweed   | 450.000đ | |  |
|  | +-------------------------------------------------------------+ |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | (Avt) Lê Hoàng Nam    [✓ Đã mua hàng (#236343)]     08/11/2026  |  |
|  | ★★★★★ (#C79B4B)                                                 |  |
|  | "Shop tư vấn số đo vai rất chuẩn, gửi hàng GHN nhanh."          |  |
|  | +-------------------------------------------------------------+ |  |
|  | | [Ảnh 36x36] Sản phẩm đã mua: Áo Len Thổ Cẩm      | 320.000đ | |  |
|  | +-------------------------------------------------------------+ |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
```