# 05. MOBILE FIXED-PRICE PRODUCT DETAIL & DEFECT ZOOM UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P303-PRODUCT-DETAIL-UI`
- **Version:** `1.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – Task P3-03 (Group 5A: Product Detail & Defect Inspection)`
- **Screen IDs Covered:** `M-PR-01` (Product Detail – Fixed Price View), `M-PR-02` (Fullscreen Image & Defect Zoom Inspector)
- **Compliance Ref:** `BF-03`, `BF-04`, `FR-DS-03`, `BR-AC-02`, `BR-PR-01..03`, `UI-DEC-01..04`, `DS-DEC-01..03`, `UX-CHECK-01`

---

## Chương 1. Triết Lý Thiết Kế Trang Chi Tiết Sản Phẩm Đồ Secondhand (`Secondhand Trust & Conversion Architecture`)

Khác với trang chi tiết sản phẩm mới trên các sàn B2C (nơi mọi chiếc áo cùng mẫu đều giống hệt nhau), trên **`izithrift`**, người mua ra quyết định dựa trên **tình trạng thực tế của đúng chiếc áo duy nhất đó**. Do đó, `M-PR-01` và `M-PR-02` được thiết kế xoay quanh 4 nguyên tắc bất biến:
1. **Không che giấu khuyết điểm (`Zero Defect Concealment – BR-PR-03`):** Khu vực **"Phiếu Kiểm Định Tình Trạng Đồ Secondhand" (`CMP-COM-02`)** chứa `condition`, `defect_info` và `verification_level` được đặt ngay dưới tên và giá bán — nằm phía trên cả bài viết mô tả chung của người bán.
2. **Ảnh gốc trung thực 100% kèm Trình soi lỗi chuyên dụng (`M-PR-02`):** Không áp bất kỳ bộ lọc màu ấm hay hạt nhiễu nào lên khung ảnh sản phẩm. Cung cấp nút mở nhanh trình xem ảnh toàn màn hình `M-PR-02` có ghim sẵn dòng mô tả vết xước ở đáy màn hình để người mua phóng đại `4.0x` đối chiếu trực tiếp.
3. **Điểm vào Mua sắm rõ ràng nhưng không tự ý ôm quy trình Checkout (`Purchase Entry Point Compliance`):** Thanh hành động cố định dưới đáy (`Sticky Bottom Action Bar`) cung cấp đúng 2 điểm vào theo `BF-04` và `BF-05` (`UX-CHECK-01`): **`[+ Thêm vào giỏ]`** (lưu vào `M-CR-01`) và **`[Mua ngay]`** (chuyển sang `M-OR-01 Checkout Preview` thuộc gói công việc sau).
4. **Tự động khóa giao dịch chéo khi Chủ tiệm tự xem bài đăng của mình (`Self-Transaction Guard – BR-AC-02`):** Khi `auth.id == product.seller_id`, thanh nút mua hàng tự động biến đổi thành thanh quản lý bài đăng dành riêng cho chủ sở hữu.

---

## Chương 2. Đặc Tả High-Fidelity Từng Màn Hình (`M-PR-01` & `M-PR-02`)

### 2.1. Screen `M-PR-01`: Fixed-Price Product Detail Screen (`/products/:id`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-PR-01` – Product Detail Screen – Fixed Price View (`/products/:id`) |
| **Purpose** | Cung cấp đầy đủ hình ảnh thực tế, thông tin giá bán, phiếu kiểm định tình trạng & vết xước (`defect_info`), cam kết bảo vệ Escrow, thông tin uy tín người bán và các nút hành động tương tác (`FR-DS-03`, `BF-03`). |
| **Entry Point** | Chạm vào một `CMP-COM-01 (Variant 1: Fixed-Price Product Card)` từ `M-HM-01`, `M-HM-02`, `M-DS-02`, `M-US-03` hoặc `M-PF-05`. *(Nếu sản phẩm có `listing_type == AUCTION`, Router tự động chuyển sang `M-AC-03` thuộc task Đấu giá)*. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `TopProductAppBar (Height 56px, Bg #F4EBDD, Border Bottom 1px #E5D9C8)`:<br>   - Trái: `BackIconButton [<-] (48x48px)`<br>   - Giữa: Tiêu đề `Fraunces 17px SemiBold #302D2A` (*"Chi tiết món đồ"*)<br>   - Phải: `[🛒 CartIconBtn + Badge]` + `[♡ FavoriteIconBtn]` + `[⋮ MoreReportMenuBtn -> M-CM-03]`<br>2. `Expanded CustomScrollView (Bottom Padding 96px)`:<br>   - **Block A – `ProductImageGallery (CMP-COM-03A)`:**<br>     - Khung ảnh chính tỷ lệ `4:5` (`390px x 487.5px`, nền chờ `#E7DAC6`, ảnh gốc 100%).<br>     - Góc dưới trái ảnh: Pill gợi ý `Bg rgba(48,45,42,0.75)` (`Height 28px`, `Radius 9999px`, icon `MagnifyingGlassPlus 14px #FAF5EC`, chữ `11px Medium #FAF5EC`: *"Chạm để phóng to soi chi tiết"*).<br>     - Góc dưới phải ảnh: Bộ đếm trang ảnh `1 / 5` (`Bg rgba(48,45,42,0.75)`, `12px SemiBold #FAF5EC tabular-nums`).<br>     - Dải ảnh thu nhỏ (`Thumbnail Strip`: `Height 68px`, `Padding 12px 16px`, các ô `48x48px`, `Radius 6px`; ô đang chọn có viền `2px solid #294638`).<br>   - **Block B – `ProductIdentityAndPriceBlock (Bg #FAF5EC, Padding 16px, Border Bottom 1px #D8CBB8)`:**<br>     - Hàng 1: Badge `[🏷️ BÁN GIÁ CỐ ĐỊNH]` (`Bg #E3ECE7`, chữ `11px SemiBold #294638`) + Mã `#PRD-204` (`JetBrains Mono 12px #655E57`).<br>     - Hàng 2 (`Margin Top 8px`): Tên sản phẩm (`type.heading.h2`: `Fraunces 20px SemiBold #302D2A`, `lineHeight 28px`, hiển thị đầy đủ không cắt chữ).<br>     - Hàng 3 (`Margin Top 10px`): Giá bán chính (`type.numeric.price.hero`: `Be Vietnam Pro 24px Bold #294638 tabular-nums`) + Nhãn số lượng còn lại bên phải (`Còn 01 chiếc` hoặc `Còn N chiếc` – `13px SemiBold #8C5A1B`).<br>   - **Block C – `ConditionInspectionSlip (CMP-COM-02 – Margin 16px, Bg #E7DAC6, Border 1px solid #B8A892, Radius 12px, Padding 16px)`:**<br>     - Header phiếu: Icon `ClipboardText 18px #302D2A` + Tiêu đề `15px SemiBold #302D2A` (*"Phiếu Kiểm Định Tình Trạng"*) + Huy hiệu `verification_level` ở góc phải (`🛡️ Đã duyệt ảnh` `#236343`).<br>     - Đường kẻ nét đứt `1.5px dashed #B8A892`.<br>     - Lưới thông số 2x2 (`Gap 12px`):<br>       - Ô 1: Nhãn *"Độ mới (Condition)"* $\rightarrow$ Huy hiệu `CMP-COM-02` (`Good – Độ mới ~88%` `#E3EFF3`/`#2B5B6C`).<br>       - Ô 2: Nhãn *"Thương hiệu"* $\rightarrow$ `Vintage Japan` (`14px SemiBold #302D2A`).<br>       - Ô 3: Nhãn *"Danh mục"* $\rightarrow$ `Áo khoác dạ`.<br>       - Ô 4: Nhãn *"Kiểm duyệt"* $\rightarrow$ `Đã xác minh hình ảnh`.<br>     - Hộp Khuyết điểm / Vết xước (`Defect Disclosure Sub-card`: `Margin Top 12px`, `Bg #FAF5EC`, `Border Left 3px solid #873A43`, `Radius 8px`, `Padding 12px`):<br>       - Tiêu đề mục: Icon `WarningCircle 16px #873A43` + Chữ `13px SemiBold #873A43`: *"Mô tả vết xước / khuyết điểm từ người bán (`defect_info`):"*<br>       - Nội dung: `type.body.medium` (`14px Regular #302D2A`, `lineHeight 20px`).<br>       - Link hành động dưới cùng: `[🔍 Mở trình soi ảnh độ phân giải cao (M-PR-02) ->]` (`12px SemiBold #294638`).<br>   - **Block D – `EscrowProtectionAssuranceBanner (Margin Horizontal 16px, Bg #DDF0F0, Border 1px #9ACBB0, Radius 8px, Padding 12px)`:**<br>     - Icon `ShieldCheck 22px #1C5858` + Nội dung `13px Regular #1C5858`: *"Bảo vệ Người mua izithrift: Tiền thanh toán được giữ an toàn trong sổ cái trung gian Escrow. Hoàn tiền 100% nếu sản phẩm bị rách, sai mô tả hoặc người bán không gửi hàng (`DEC-04`, `DEC-07`)."*<br>   - **Block E – `ProductDescriptionSection (Margin Top 16px, Bg #FAF5EC, Padding 16px, Border Top/Bottom 1px #D8CBB8)`:**<br>     - Tiêu đề `type.title.section` (`16px SemiBold #302D2A`: *"Chi tiết & Số đo sản phẩm"*).<br>     - Nội dung `type.body.large` (`16px Regular #302D2A`, `lineHeight 24px`, hỗ trợ thu gọn/mở rộng `[Xem thêm v]` nếu dài quá 8 dòng).<br>   - **Block F – `SellerSummaryEntryCard (CMP-COM-03B – Margin 16px, Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 16px)`:**<br>     - Avatar `48x48px`, Tên Tiệm (`Fraunces 16px SemiBold #302D2A`), Huy hiệu `Trust Score: 98%`, Điểm đánh giá `★ 4.9 (42 đánh giá)`, nút phải **`[Xem Tiệm ->]`** (mở `M-US-03`).<br>   - **Block G – `RelatedProductsSection (Padding 16px)`:**<br>     - Tiêu đề `Fraunces 18px SemiBold #302D2A`: *"Món đồ tương tự đã kiểm duyệt"* + Lưới 2 cột (4 sản phẩm liên quan).<br>3. `StickyBottomPurchaseBar (Height 72px + Safe Area, Bg #FFFDF9, Border Top 1px #D8CBB8, Elevation 2)`. |
| **Sticky Bottom Action Bar Variants (3 Ngữ Cảnh Nghiệp Vụ)** | - **Ngữ cảnh 1 – Người xem là Buyer / Guest & Sản phẩm đang còn hàng (`status == APPROVED` & `available_quantity >= 1`):**<br>  - `[💬 Chat]` (`IconButton 48x48px`, viền `1px #D8CBB8`, `Radius 8px`, icon `ChatCircleDots 22px #302D2A`).<br>  - `[♡ Lưu]` (`IconButton 48x48px`, viền `1px #D8CBB8`, `Radius 8px`, icon `Heart 22px`).<br>  - **`[+ Thêm vào giỏ]`** (`Secondary Outlined Button`, cao `48px`, viền `1.5px #294638`, chữ `14px SemiBold #294638`).<br>  - **`[Mua ngay]`** (`Primary Button`, cao `48px`, nền `#294638`, chữ `15px SemiBold #FAF5EC`).<br>- **Ngữ cảnh 2 – Người xem là Chủ sở hữu sản phẩm (`auth.id == seller_id` – `BR-AC-02`):**<br>  - Ẩn toàn bộ 4 nút trên; hiển thị nhãn *"Bạn là người đăng bán món đồ này"* kèm nút `Secondary Button` Full-width: **`[✏️ Quản lý bài đăng trong Kênh Bán]`**. <br>- **Ngữ cảnh 3 – Sản phẩm đã bán hết (`status == SOLD` hoặc `available_quantity == 0`):**<br>  - Giữ nút `[♡ Lưu]` và `[Xem Tiệm]`, thay cụm nút mua bằng 1 nút `Disabled` (`Bg #E0D8CE`, chữ `#5C5650`): **`[ĐÃ BÁN HẾT (SOLD OUT)]`**. |
| **Navigation Behavior** | - Nhấn `[+ Thêm vào giỏ]`: Nếu `Guest` $\rightarrow$ `/login?redirect=/products/:id` (`DEC-01`); nếu đã đăng nhập $\rightarrow$ Gọi `POST /cart/items` $\rightarrow$ Hiện Toast xanh *"Đã thêm vào giỏ hàng"* + Tăng số đếm trên icon `[🛒]` ở Top App Bar (`BF-04`).<br>- Nhấn `[Mua ngay]`: Nếu `Guest` $\rightarrow$ `/login?redirect=/products/:id`; nếu đã đăng nhập $\rightarrow$ Chuyển thẳng sang màn hình `M-OR-01 (Checkout Preview)` (`UX-CHECK-01`).<br>- Nhấn `[💬 Chat]` $\rightarrow$ Mở phòng chat `M-CM-02` kèm thẻ ngữ cảnh của sản phẩm này (`BF-12`).<br>- Nhấn vào `SellerSummaryEntryCard` $\rightarrow$ Mở `M-US-03` (`/sellers/:id`). |
| **UI States (`Loading / Error / Unavailable`)** | - **Loading:** Shimmer cho khung ảnh `4:5`, khối tiêu đề và phiếu kiểm định.<br>- **Error / Restricted (`404 Not Found` hoặc sản phẩm vừa bị ẩn `HIDDEN`):** Hiển thị `STATE-EMP-01` với icon `EyeSlash 56px #8C837A`: *"Món đồ này không còn tồn tại hoặc đã ngừng giao dịch"* + Nút `[Quay lại khám phá]`. |

#### High-Fidelity Visual Preview (`M-PR-01` Fixed-Price Product Detail):
```text
+-----------------------------------------------------------------------+
| [<-]                   Chi tiết món đồ             [🛒2] [♡] [⋮ Báo cáo]|
+-----------------------------------------------------------------------+
|  +-----------------------------------------------------------------+  |
|  |                                                                 |  |
|  |                 [ ẢNH SẢN PHẨM CHÍNH TỶ LỆ 4:5 ]                |  |
|  |                   (Màu sắc gốc trung thực 100%)                 |  |
|  |                                                                 |  |
|  | [🔍 Chạm để phóng to soi chi tiết]                      [1 / 5] |  |
|  +-----------------------------------------------------------------+  |
|  | [Ảnh 1*]  [Ảnh 2]  [Ảnh 3]  [Ảnh 4: Vết xước]  [Ảnh 5: Tag áo]  |  |
|  +-----------------------------------------------------------------+  |
|  [🏷️ BÁN GIÁ CỐ ĐỊNH (#E3ECE7/#294638)]            Mã: #PRD-204       |
|  Áo Khoác Dạ Tweed Cổ Điển Mùa Đông (Fraunces 20px SemiBold #302D2A)  |
|  450.000 VNĐ (24px Bold #294638 Tabular)     [Còn 01 chiếc duy nhất]  |
|  -------------------------------------------------------------------  |
|  +-----------------------------------------------------------------+  |
|  | 📋 PHIẾU KIỂM ĐỊNH TÌNH TRẠNG      [🛡️ Đã duyệt ảnh (#236343)]  |  |
|  | (Surface: Warm Sand #E7DAC6 | Border: 1px #B8A892 | Radius 12px)|  |
|  | - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - |  |
|  | • Độ mới: [Good - Độ mới ~88%]      | • Thương hiệu: Vintage JP |  |
|  | • Danh mục: Áo khoác dạ             | • Số lượng: 01 chiếc      |  |
|  | +-------------------------------------------------------------+ |  |
|  | | ⚠️ Mô tả vết xước / khuyết điểm từ người bán (BR-PR-03):    | |  |
|  | | "Cúc áo thứ 2 từ dưới lên hơi xước nhẹ ở viền, lớp lót lụa  | |  |
|  | |  bên trong nguyên vẹn không rách (Xem rõ tại Ảnh số 4)."    | |  |
|  | | [🔍 Mở trình soi ảnh độ phân giải cao (M-PR-02) ->]         | |  |
|  | +-------------------------------------------------------------+ |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | 🛡️ Bảo vệ Người mua izithrift: Tiền được giữ an toàn trong      |  |
|  |    Escrow. Hoàn tiền 100% nếu hàng rách hoặc sai mô tả (DEC-07).|  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | (Avt) 🏪 Tiệm Đồ Si Nhà Gấu                        [Xem Tiệm >] |  |
|  | ★ 4.9 (42 đánh giá) • Điểm tin cậy: 98% • Hoàn tất đơn: 99%     |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
| [💬]  [♡]  |  [ + Thêm vào giỏ (#294638) ]  |  [ MUA NGAY (#294638) ] | <-- Sticky Bottom Bar (72px)
+-----------------------------------------------------------------------+
```

---

### 2.2. Screen `M-PR-02`: Fullscreen Image & Defect Zoom Inspector (`/products/:id/gallery`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-PR-02` – Fullscreen Image & Defect Zoom Inspector (`/products/:id/gallery`) |
| **Purpose** | Cho phép người mua phóng to ảnh sản phẩm và ảnh bằng chứng xác thực (`authenticity_evidence`) lên tới `4.0x` trên nền tối để kiểm tra kỹ chất liệu, đường chỉ may và đối chiếu vết xước (`defect_info`). |
| **Entry Point** | Chạm vào ảnh chính hoặc nhấn nút `[🔍 Mở trình soi ảnh độ phân giải cao]` trên `M-PR-01`. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #1A1817 – Deep Dark Studio Canvas)`:<br>1. `TopOverlayBar (Height 56px, Transparent)`:<br>   - Trái: Bộ đếm `Ảnh 4 / 5` (`14px SemiBold #FAF5EC tabular-nums`).<br>   - Phải: Nút `[Đóng ✕]` (`IconButton 48x48px`, nền tròn `rgba(250,245,236,0.15)`, icon `22px #FAF5EC`).<br>2. `Expanded`: `PageView.builder` chứa `InteractiveViewer (minScale: 1.0, maxScale: 4.0, panEnabled: true)`.<br>3. `BottomPinnedDefectOverlay (Bg rgba(30, 28, 26, 0.88), Border Top 1px rgba(216,203,184,0.25), Padding 16px)`:<br>   - Dải `Thumbnail Selector` (`48x48px` mỗi ảnh).<br>   - Hộp nhắc lại nguyên văn `defect_info` (`13px Regular #FAF5EC`, nhãn đầu màu vàng đồng `#EED69F`: *"🔍 Lưu ý vết xước người bán đã ghi:"*) để người mua đối chiếu ngay trong lúc đang zoom ảnh mà không cần thoát ra ngoài. |

#### High-Fidelity Visual Preview (`M-PR-02` Defect Zoom Inspector):
```text
+-----------------------------------------------------------------------+
| Ảnh 4 / 5 (Cận cảnh khuyết điểm)                              [Đóng ✕]|
+-----------------------------------------------------------------------+
|                                                                       |
|                                                                       |
|                [ KHUNG ẢNH INTERACTIVE VIEWER (ZOOM 1x - 4x) ]        |
|                   (Hỗ trợ Pinch-to-Zoom & Double-Tap Zoom)            |
|                         Nền tối tuyệt đối #1A1817                     |
|                                                                       |
|                                                                       |
+-----------------------------------------------------------------------+
|  [Ảnh 1]   [Ảnh 2]   [Ảnh 3]   [Ảnh 4*]   [Ảnh 5: Tag xác thực]       |
|  -------------------------------------------------------------------  |
|  🔍 Lưu ý vết xước người bán đã ghi (#EED69F):                        |
|  "Cúc áo thứ 2 từ dưới lên hơi xước nhẹ ở viền, lớp lót lụa bên trong |
|   nguyên vẹn không rách."                                             |
+-----------------------------------------------------------------------+
```