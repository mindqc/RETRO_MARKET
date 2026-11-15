# 03. MOBILE SELLER CENTER & LISTING MANAGEMENT UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P304C-SELLER-UI`
- **Version:** `1.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR FINAL LOCK`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`
- **Target Screens Covered:** `M-SL-01`, `M-SL-02`, `M-SL-03`, `M-SL-03B`, `M-SL-04`, `M-SL-05`, `M-SL-06`, `M-SL-07`, `M-SL-08`

---

## Chương 1. Nguyên Tắc Nhận Diện Không Gian Người Bán (`Seller Context Visual Architecture – UI-DEC-02`)

Vì một tài khoản người dùng trên **`izithrift`** vừa đi mua hàng vừa bán hàng (`BR-AC-01`), giao diện của **Tab 4 – Kênh Bán (`/seller`)** áp dụng 3 quy tắc thị giác đặc trưng đã được phê duyệt tại `UI-DEC-02` và `SELLER-UX-01..02`:
1. **Header Màu Xanh Rừng Thông Trầm Đặc Trưng (`Forest Pine Seller Header #294638` – `UI-DEC-02`):** Toàn bộ các màn hình thuộc nhóm `M-SL-*` sử dụng Top App Bar nền `#294638` với chữ và icon màu kem sáng `#FAF5EC`. Ngay khi chuyển sang Tab 4, người dùng nhận biết tức thì *"Mình đang ở trong Kênh Quản Lý Bán Hàng của Tiệm mình"*, loại bỏ hoàn toàn nguy cơ nhầm lẫn giữa đơn mua và đơn bán (`NAV-DEC-02`).
2. **Hiển thị nhất quán chính sách "Nhận trọn 100% tiền hàng" (`SELLER-UX-01` & `DEC-04`):** Trên Form đăng bán (`M-SL-03`), Chi tiết đơn bán (`M-SL-06`) và Sổ cái Ví (`M-SL-08`), giao diện luôn tách bạch rõ: **Số tiền Người bán thực nhận = `100% item_subtotal` (Miễn phí hoa hồng)**, còn khoản `Buyer Protection Fee` là phí bảo vệ do Người mua trả riêng cho sàn.
3. **Tối ưu vòng lặp Kiểm duyệt & Sửa bài (`DEC-05`):** Khi bài đăng bị Moderator từ chối (`REJECTED`), màn hình `M-SL-04` và form sửa `M-SL-03` ghim cố định lý do từ chối ở đầu màn hình để người bán sửa đúng trọng tâm và bấm `Resubmit` nhanh chóng.

---

## Chương 2. Đặc Tả High-Fidelity Từng Màn Hình Người Bán (`M-SL-01` – `M-SL-08`)

### 2.1. `M-SL-01`: Seller Center Dashboard – Tab 4 Root (`/seller` – `SF-01`)

- **1. Top App Bar (`Cao 56px`, Nền `color.bg.mobile.seller_header #294638`, Chữ `#FAF5EC`):**
  - Trái: Icon `Storefront` (`22px #C79B4B`) + Tiêu đề `Fraunces 18px SemiBold #FAF5EC`: *"Kênh Người Bán (Tiệm của tôi)"*.
  - Phải: Nút nhỏ `[👁️ Xem Tiệm]` (Mở `M-US-03` để xem tiệm mình dưới góc nhìn khách mua) + Icon Thông báo `[🔔]`.
  - *(Lưu ý: Nếu chưa đăng nhập, phần thân hiển thị `CMP-GWC-01 Guest Welcome Card` theo `NAV-DEC-03`)*.
- **2. Cấu trúc Nội dung Dashboard (Khi đã đăng nhập `ACT-02`, Padding `16px`, Khoảng cách khối `20px`):**
  - **Block 1 – Seller Wallet & Escrow Summary Card (`Bg #294638` chuyển sắc nhẹ sang `#1E352A`, Viền `1px solid #C79B4B`, `radius.md = 12px`, Padding `20px`, Chữ `#FAF5EC`):**
    - Hàng trên: Nhãn `12px #E3ECE7`: *"💰 SỐ DƯ VÍ KHẢ DỤNG (ĐÃ GIẢI NGÂN 100% TIỀN HÀNG)"* + Con số lớn `type.numeric.price.hero` (`26px Bold #FAF5EC tabular-nums`: **`2.450.000 VNĐ`**).
    - Đường kẻ phân cách mờ `1px solid rgba(250,245,236,0.2)`.
    - Hàng dưới (2 cột):
      - Cột trái: *"🔒 Đang giữ trong Escrow (HELD):"* **`600.000 VNĐ`** (`15px SemiBold #EED69F tabular-nums`).
      - Cột phải (Căn phải): Nút `[Xem Sổ cái Ví ->]` (Mở `M-SL-08`).
  - **Block 2 – Primary Action CTA (`CMP-ACT-01`):**
    - Nút lớn cao `52px`, Full-width, nền `Vintage Burgundy #873A43`, chữ `#FAF5EC`, icon `PlusCircle 22px`: **`[+ ĐĂNG BÁN SẢN PHẨM MỚI (GIÁ CỐ ĐỊNH / ĐẤU GIÁ)]`** $\rightarrow$ Mở `M-SL-03`.
  - **Block 3 – Việc Cần Xử Lý Ngay (`Action Required Grid` – Lưới 2x2 thẻ trên nền `#FAF5EC`, viền `1px solid #D8CBB8`, `radius.md = 12px`):**
    1. **Ô 1 – Đơn mới chờ chuẩn bị (`PAID`):** Con số lớn `02` (`#294638`) + Nhãn *"Chờ xác nhận chuẩn bị"* $\rightarrow$ Mở `M-SL-05 (Tab PAID)`.
    2. **Ô 2 – Yêu cầu hủy chờ duyệt (`PREPARING` – `DEC-06`):** Con số `01` (Đổi màu đỏ `#A62B2B` nếu `> 0`) + Nhãn *"Khách xin hủy đơn"* $\rightarrow$ Mở `M-SL-05 (Tab PREPARING)`.
    3. **Ô 3 – Khiếu nại đang mở (`DISPUTED`):** Con số `00` (`#6A2C5A` nếu `> 0`) + Nhãn *"Khiếu nại cần đối chứng"* $\rightarrow$ Mở `M-DP-02`.
    4. **Ô 4 – Bài đăng bị từ chối (`REJECTED` – `DEC-05`):** Con số `01` (`#A62B2B` nếu `> 0`) + Nhãn *"Cần sửa & gửi duyệt lại"* $\rightarrow$ Mở `M-SL-02 (Tab REJECTED)`.
  - **Block 4 – Menu Quản Lý Nhanh (`List Tiles` trên nền `#FAF5EC`):**
    - `📦 Quản lý Sản phẩm của tôi (7 trạng thái)` $\rightarrow$ `M-SL-02`.
    - `🧾 Quản lý Đơn bán & Cập nhật Vận chuyển` $\rightarrow$ `M-SL-05`.
    - `🔨 Phiên đấu giá của Tiệm (Chốt sớm / Đăng lại)` $\rightarrow$ `M-SL-02 (Filter: Auction)`.
    - `⚙️ Chỉnh sửa Hồ sơ & Bio Tiệm đồ si` $\rightarrow$ `M-PF-02`.

---

### 2.2. `M-SL-02`: My Product Listings – 7 Status Tabs (`/seller/products` – `SF-06`)

- **1. Top App Bar (`#294638`):** Nút `[<-]`, Tiêu đề *"Sản phẩm của tôi"*, nút phải `[+ Đăng mới]` (`M-SL-03`).
- **2. Search & Type Filter Bar (`Cao 48px`, Nền `#FAF5EC`):** Ô tìm tên sản phẩm + Bộ lọc nhanh `[Tất cả | Giá cố định | Đấu giá]`.
- **3. Scrollable 7-Status Tab Bar (`CMP-NAV-01`, Cao `44px`, Nền `#FAF5EC`, Viền dưới `1px solid #D8CBB8`):**
  - Hiển thị đầy đủ **7 tab trạng thái vòng đời sản phẩm (`06_BUSINESS_RULES.md` Mục 8.1)** kèm số đếm:
    1. `Đang bán (APPROVED)` (Huy hiệu `#236343`)
    2. `Chờ duyệt (PENDING_REVIEW)` (Huy hiệu `#945814`)
    3. `Bị từ chối (REJECTED)` (Huy hiệu `#A62B2B` – nổi bật)
    4. `Bản nháp (DRAFT)` (Huy hiệu `#655E57`)
    5. `Đã bán / Kết thúc (SOLD)` (Bao gồm cả phiên đấu giá `ENDED_UNSOLD` và `WINNER_DEFAULTED` – `DEC-02`)
    6. `Đang ẩn (HIDDEN)`
    7. `Lưu trữ (ARCHIVED)`.
- **4. Danh sách Thẻ Quản lý Sản phẩm (`CMP-COM-01 Variant 4` – Dạng thẻ ngang `Full-width` cao `136px` để chứa đủ nút quản trị):**
  - Phần trên: Ảnh `80x80px` (`radius.sm = 8px`), Tên sản phẩm, Nhãn loại hình (`FIXED_PRICE` / `AUCTION`), Giá bán (hoặc Giá cao nhất hiện tại), Huy hiệu trạng thái.
  - Phần chân thẻ (Thanh nút hành động thay đổi theo đúng Tab trạng thái và quy tắc khóa `BR-PR-05`):
    - **Tại Tab `APPROVED`:**
      - Nếu chưa có đơn hàng active và chưa có bid: Nút `[✏️ Sửa]` (`M-SL-03`) + Nút `[👁️‍🗨️ Tạm ẩn (HIDDEN)]`.
      - Nếu là phiên Đấu giá đang `LIVE`: Nút **`[🔨 Vào Phòng Đấu Giá / Chốt phiên sớm]`** (`M-AC-03` – `SF-07`) và hiển thị nhãn khóa `🔒 Đang đấu giá (Khóa sửa/ẩn - BR-PR-05)`.
    - **Tại Tab `REJECTED` (`DEC-05`):** Hiển thị dòng tóm tắt lý do từ chối màu `#A62B2B` (1 dòng) + Nút chính màu đỏ rượu vang **`[🔍 Xem lý do & Sửa gửi duyệt lại]`** (`M-SL-04` – `SF-05`).
    - **Tại Tab `DRAFT`:** Nút `[✏️ Tiếp tục sửa]`, `[🚀 Gửi duyệt ngay]`, `[🗑️ Xóa nháp]`.
    - **Tại Tab `SOLD` (Khi phiên đấu giá ở trạng thái `WINNER_DEFAULTED` quá 30p không trả tiền hoặc `ENDED_UNSOLD` – `DEC-02`):** Hiển thị nhãn cảnh báo vàng nâu *"Người thắng quá hạn thanh toán 30p (Đã hủy đơn)"* + Nút nổi bật **`[🔄 Đăng lại vào phiên đấu giá mới (Relist)]`** (`M-SL-03`).

---

### 2.3. `M-SL-03` (Create / Edit Product Form) & `M-SL-03B` (Preview Modal) – `SF-02`, `SF-03`, `SF-04`

- **1. Top App Bar (`#294638`):** Nút `[<- Hủy]`, Tiêu đề *"Đăng sản phẩm mới"* (hoặc *"Chỉnh sửa sản phẩm"*), nút phải **`[👁️ Xem trước]`** (Mở `M-SL-03B`).
- **2. Pinned Moderation Rejection Banner (Chỉ xuất hiện khi đi từ `M-SL-04` vào sửa bài bị `REJECTED` – `DEC-05`):**
  - Ghim cố định ở đỉnh màn hình (`Bg #FCE8E8`, viền dưới `2px solid #A62B2B`, padding `12px`):
  - Chữ `13px SemiBold #A62B2B`: *"⚠️ Yêu cầu chỉnh sửa từ Moderator: [Hiển thị nguyên văn lý do từ chối để Seller đối chiếu khi sửa]."*
- **3. Cấu trúc Form 4 Khối (`SingleChildScrollView`, Padding `16px`, Khoảng cách khối `20px`):**
  - **Khối 1 – Hình ảnh Thực tế & Bằng chứng Xác thực (`Bg #FAF5EC`, Padding `16px`, `radius.md = 12px`):**
    - *Lưới Ảnh sản phẩm (`1..8` ảnh *):* Sử dụng `CMP-FRM-02 Image Uploader Grid`. Ô số 1 ghi rõ `[Ảnh bìa chính *]`, các ô sau gợi ý góc chụp (*Mặt trước*, *Mặt sau*, *Cận cảnh vết xước/lỗi*). Dung lượng tối đa `5MB/ảnh` (`jpg, png, webp` – `NFR-SEC-05`).
    - *Khung Ảnh Bằng chứng Xác thực (`authenticity_evidence` – Tùy chọn):* Tải lên 1–3 ảnh chụp tem mác, mã code dập chìm hoặc hóa đơn cũ để Moderator cấp nhãn `EVIDENCE_PROVIDED` / `MODERATOR_REVIEWED`.
  - **Khối 2 – Thông tin Cơ bản (`Bg #FAF5EC`, Padding `16px`, `radius.md = 12px`):**
    - `Tên sản phẩm *` (`CMP-FRM-01`, 5–120 ký tự).
    - `Danh mục *` & `Thương hiệu` (2 Dropdown Selector nằm trên 2 dòng).
    - `Mô tả chi tiết câu chuyện & số đo món đồ *` (`Multiline TextArea`, tối thiểu 20 ký tự).
  - **Khối 3 – Hồ sơ Tình trạng Đồ Secondhand Bắt buộc (`BR-PR-03` – `Bg #E7DAC6`, Viền `1px solid #B8A892`, Padding `16px`, `radius.md = 12px`):**
    - `Tình trạng món đồ (Condition) *`: 4 Choice Chips (`Like New`, `Good`, `Fair`, `Vintage Worn`).
    - `Khai báo Khuyết điểm / Vết xước (defect_info) *` (`CMP-FRM-01 Multiline`, bắt buộc nhập – nếu món đồ hoàn hảo không tì vết thì nhập *"Không có vết xước hay hư hỏng"*): Có dòng nhắc *"Khai báo trung thực giúp bảo vệ bạn 100% trước các khiếu nại sau bán hàng."*
  - **Khối 4 – Chọn Phương thức Bán & Định giá (`BR-PR-01` – `Bg #FAF5EC`, Padding `16px`, `radius.md = 12px`):**
    - **Segmented Mode Switcher (`Cao 44px`, Nền `#E7DAC6`, `radius.sm = 8px`):**
      - Nút Trái: **`[🏷️ Bán Giá Cố Định (Fixed Price)]`**
      - Nút Phải: **`[🔨 Đấu Giá Theo Phiên (Auction)]`**
    - **Nếu chọn Mode 1 (`FIXED_PRICE`):**
      1. `Giá bán cố định (price) *`: Ô nhập số tiền `VNĐ` (`> 0`).
      2. `Số lượng sẵn có (available_quantity) *`: Mặc định `= 1` (cho phép tăng nếu có nhiều món giống nhau).
      3. **Hộp Minh bạch Doanh thu (`SELLER-UX-01` – `Bg #E3F2EA`, viền `#9ACBB0`, padding `12px`):**
         - *"💚 Hoa hồng người bán: 0đ (Miễn phí 100%). Số tiền bạn thực nhận vào Ví khi đơn hoàn tất = 100% Giá bán (`DEC-04`)."*
    - **Nếu chọn Mode 2 (`AUCTION`):**
      1. `Số lượng`: Ô Read-Only khóa cứng **`01 chiếc duy nhất`** (`BR-PR-01`, `ASM-02`).
      2. `Chọn Khung giờ Phiên đấu giá (auction_session_id) *`: Dropdown hiển thị các phiên sắp mở do Admin cấu hình (ví dụ: *Phiên Tối 20:00 – 22:00 ngày 14/11/2026*).
      3. `Giá khởi điểm (starting_price) *`: Ô nhập tiền `VNĐ` (`> 0`).
      4. `Bước giá tối thiểu (min_bid_increment) *`: Ô nhập tiền `VNĐ` (`> 0`, gợi ý: `20.000đ`, `50.000đ`, `100.000đ`).
      5. `Giá sàn kỳ vọng (reserve_price – Tùy chọn)`: Ô nhập tiền `VNĐ` (Validation: nếu nhập thì bắt buộc `reserve_price >= starting_price`). Giải thích: *"Nếu hết giờ mà giá cao nhất chưa đạt Giá sàn, bạn không bắt buộc phải bán (`ENDED_UNSOLD`)."*
- **4. Sticky Bottom Action Bar (`Cao 72px`, Nền `#FFFDF9`):**
  - Nút Phụ (`Secondary Button`, rộng 38%): **`[💾 Lưu nháp]`** (`status = DRAFT`).
  - Nút Chính (`Primary Button`, rộng 58%, nền `#294638`): **`[🚀 Gửi kiểm duyệt]`** (Hoặc **`[🚀 Gửi duyệt lại]`** nếu đang sửa bài `REJECTED` $\rightarrow$ Chuyển sang `PENDING_REVIEW`).

---

### 2.4. `M-SL-04`: Moderation Rejection Feedback & Resubmit Screen (`/seller/products/:id/moderation` – `DEC-05`, `SF-05`)

- **Cấu trúc Bố cục:**
  - **Top App Bar (`#294638`):** Nút `[<-]`, Tiêu đề *"Chi tiết Kiểm duyệt Bài đăng"*.
  - **Rejection Alert Card (`Bg #FCE8E8`, Viền `1.5px solid #A62B2B`, `radius.md = 12px`, Padding `16px`):**
    - Huy hiệu đỏ **`BỊ TỪ CHỐI KIỂM DUYỆT (REJECTED)`** + Thời gian kiểm duyệt.
    - Tiêu đề `15px SemiBold #A62B2B`: *"Lý do từ chối / Yêu cầu chỉnh sửa từ Moderator:"*
    - Nội dung hộp trắng ngà bên trong (`14px Regular #302D2A`): Hiển thị rõ `reason` trong bảng `product_moderation_logs`.
  - **Moderation History Timeline (`product_moderation_logs`):** Lịch sử các lần gửi duyệt và phản hồi trước đó.
  - **Bottom Action Bar:** Nút `Primary Button` (`#294638`): **`[✏️ Chỉnh sửa bài đăng & Gửi duyệt lại]`** (Mở `M-SL-03`) + Nút phụ `[Lưu trữ bài đăng]`.

---

### 2.5. `M-SL-05` (Seller Orders List), `M-SL-06` (Seller Order Detail & Cancel Approval) & `M-SL-07` (Shipment Update Modal) – `SF-08`, `SF-09`, `SF-10`

#### A. `M-SL-05`: Seller Order Management List (`/seller/orders` – `NAV-DEC-02`)
- **Top App Bar (`#294638`):** Tiêu đề *"Quản lý Đơn bán của Tiệm"*.
- **7-Status Scrollable Tab Bar:** `Chờ xác nhận (PAID)` | `Đang chuẩn bị (PREPARING)` | `Đang giao (SHIPPED)` | `Đã giao (DELIVERED)` | `Khiếu nại (DISPUTED)` | `Hoàn tất (COMPLETED)` | `Đã hủy / Hoàn tiền`.
- Nếu trong tab `PREPARING` có đơn hàng mà Buyer đang gửi yêu cầu xin hủy (`cancellation_requested == true` – `DEC-06`), trên tab và trên thẻ đơn hàng hiện huy hiệu nhấp nháy màu đỏ **`[⚠️ Khách xin hủy đơn]`**.

#### B. `M-SL-06`: Seller Order Detail & Cancel Request Approval (`/seller/orders/:id`)
1. **Block 1 – Transaction 4-State Header Card (`CMP-ORD-01`):** Hiển thị rõ `order_status`, `payment_status`, `escrow_status` (`HELD` / `RELEASED` / `REFUNDED`) và `dispute_status`.
   - Khi đơn ở trạng thái `DELIVERED` (`SELLER-UX-02`): Hiển thị rõ dòng đếm ngược **`⏰ Tự động hoàn tất & giải ngân vào Ví của bạn sau: 23 giờ 15 phút (Mốc auto_complete_at: 14/11 10:30)`**.
2. **Block 2 – Hộp Duyệt Yêu Cầu Hủy Đơn Của Người Mua (Chỉ hiển thị khi `order_status == PREPARING` và `cancellation_requested == true` – `DEC-06`):**
   - Khung cảnh báo nổi bật (`Bg #FDF1E1`, viền `1.5px solid #E8C28E`, `radius.md = 12px`, padding `16px`):
   - Tiêu đề `15px SemiBold #945814`: *"⚠️ Người mua vừa gửi yêu cầu xin hủy đơn hàng này"*
   - Lý do khách nêu: *"Đặt nhầm kích cỡ / Muốn đổi món khác..."*
   - Cụm 2 nút quyết định dành cho Seller (Mỗi nút mở `Confirmation Dialog` trước khi gọi API):
     - Nút Trái (`Destructive Outlined Button`): **`[✅ Đồng ý Hủy (Hoàn 100% cho khách)]`** $\rightarrow$ Đơn chuyển sang `CANCELLED`, `escrow_status = REFUNDED`, hoàn trả 100% `total_amount` cho Buyer (`DEC-07`) và khôi phục tồn kho sản phẩm cho Seller.
     - Nút Phải (`Primary Button #294638`): **`[❌ Từ chối Hủy & Tiếp tục Giao hàng]`** $\rightarrow$ Đóng yêu cầu hủy và mở Modal nhập mã vận đơn `M-SL-07`.
3. **Block 3 – Bảng Doanh Thu Thực Nhận Của Người Bán (`CMP-ORD-02 Seller Variant` – `SELLER-UX-01`, `DEC-04`):**
   - Khung nền `#FAF5EC`, viền `1px solid #D8CBB8`, padding `16px`:
   - Dòng 1: `Giá bán sản phẩm (item_subtotal):` **`600.000 VNĐ`**
   - Dòng 2: `Phí hoa hồng người bán:` **`0 VNĐ (Miễn phí 100%)`**
   - Dòng 3 (Chữ nhỏ `#655E57`): *(Khoản Phí bảo vệ người mua 43.000đ do người mua trả riêng cho sàn, đang giữ chung trong Escrow 643.000đ)*.
   - Đường kẻ nét đứt `1px dashed #B8A892`.
   - Dòng Tổng kết (`18px Bold #294638`): **`💰 SỐ TIỀN BẠN THỰC NHẬN KHI ĐƠN HOÀN TẤT: 600.000 VNĐ (100%)`**.
4. **Block 4 – Địa chỉ Người nhận, Snapshot Sản phẩm (`order_items`) & Timeline Vận chuyển.**
5. **Sticky Bottom Action Bar (Thay đổi theo trạng thái đơn bán):**
   - Khi `order_status == PAID`: Nút Phụ `[Chủ động Hủy đơn]` + Nút Chính **`[📦 Xác nhận Chuẩn bị hàng (Chuyển sang PREPARING)]`**.
   - Khi `order_status == PREPARING`: Nút Phụ `[Chủ động Hủy đơn]` + Nút Chính **`[🚚 Nhập mã vận đơn & Xác nhận Gửi hàng]`** (Mở `M-SL-07`).
   - Khi `order_status == SHIPPED`: Nút Chính **`[✅ Cập nhật: Đã giao hàng tới nơi (DELIVERED)]`** (Mở `M-SL-07`).
   - Khi `dispute_status == OPEN`: Nút Chính màu tím mận `#6A2C5A`: **`[⚖️ Xem Khiếu nại & Tải Bằng chứng Đối chứng]`** (Mở `M-DP-03` – `SF-11`).

#### C. `M-SL-07`: Manual Shipment & Tracking Update Bottom Sheet (`SF-10`)
- **Chế độ 1 (`PREPARING` $\rightarrow$ `SHIPPED`):**
  - Dropdown `Đơn vị vận chuyển (carrier_name) *`: *Giao Hàng Nhanh (GHN)*, *Giao Hàng Tiết Kiệm (GHTK)*, *Viettel Post*, *J&T Express*, *VNPost*, *Tự giao nội thành*.
  - Input `Mã vận đơn (tracking_code) *`: Font `JetBrains Mono` viết hoa, bắt buộc nhập.
  - Input `Ghi chú gửi hàng (Tùy chọn)`.
  - Nút Primary: **`[Xác nhận Đã gửi hàng (Chuyển sang SHIPPED)]`**.
- **Chế độ 2 (`SHIPPED` $\rightarrow$ `DELIVERED`):**
  - Hộp xác nhận: *"Bạn xác nhận đơn vị vận chuyển đã giao kiện hàng này tới tay người mua? Hệ thống sẽ bắt đầu đếm ngược 24 giờ (2 phút ở Demo Mode) để tự động hoàn tất đơn và giải ngân 100% tiền hàng vào Ví của bạn (`BR-OR-05`)."*
  - Nút Primary: **`[Xác nhận Đã giao hàng thành công (DELIVERED)]`**.

---

### 2.6. `M-SL-08`: Seller Wallet & Immutable Escrow Ledger Screen (`/seller/wallet` – `SF-12`)

- **1. Top App Bar (`#294638`):** Nút `[<-]`, Tiêu đề *"Ví Người Bán & Sổ Cái Escrow"*.
- **2. Academic Simulation Disclaimer Banner (`CON-02`, `ASM-06`):**
  - Khung nền `#E6F0F8`, viền `1px solid #A2C4E0`, padding `10px 16px`, chữ `12px #28557A`:
  - *"🎓 Ví điện tử và Sổ cái trung gian mô phỏng phục vụ đồ án môn học – Không kết nối tài khoản ngân hàng thực tế."*
- **3. Dual Balance Summary Card (`Bg #294638`, Chữ `#FAF5EC`, Padding `20px`, `radius.md = 12px`):**
  - Cột 1: **Số dư Ví khả dụng (Đã giải ngân):** `2.450.000 VNĐ` (`22px Bold #FAF5EC tabular-nums`).
  - Cột 2: **Đang chờ giải ngân (Escrow HELD):** `600.000 VNĐ` (`18px SemiBold #EED69F tabular-nums`).
  - Dòng chú thích dưới (`12px #E3ECE7`): *"Chính sách nền tảng (`DEC-04`): Miễn phí 100% hoa hồng người bán. Bạn luôn nhận đủ 100% tiền hàng (`item_subtotal`) khi đơn hoàn tất."*
- **4. Immutable Append-Only Ledger Tabs (`BR-FN-07`, `PERM-FN-07`):**
  - **Tab 1 – `Lịch sử Biến động Ví (wallet_transactions)`:**
    - Mỗi dòng là một thẻ giao dịch bất biến (`Bg #FAF5EC`, viền `1px solid #D8CBB8`): Hiển thị Mã bút toán (`WTX-...` font `JetBrains Mono`), Loại biến động (`+ Giải ngân tiền hàng đơn #ORD-...`), Số tiền cộng màu xanh `#236343` (`+600.000 VNĐ` căn phải `tabular-nums`), Số dư sau giao dịch (`balance_after`) và Thời gian ghi sổ.
  - **Tab 2 – `Sổ cái Giữ tiền Trung gian (escrow_transactions)`:**
    - Hiển thị toàn bộ các bút toán `HOLD` (Giữ tiền lúc khách trả QR), `RELEASE` (Giải ngân 100% `item_subtotal` về Ví Seller) và `REFUND` (Hoàn trả cho Buyer khi hủy đơn hoặc thua Dispute). Chạm vào bất kỳ dòng nào sẽ mở màn hình Chi tiết Đơn bán `M-SL-06` tương ứng.