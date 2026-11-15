# 05. COMPONENT LIBRARY SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P302-COMPONENT-LIBRARY`
- **Version:** `1.0.0`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`

---

## Chương 1. Quy Ước Thiết Kế Component Đa Trạng Thái (`Multi-State Component Standards`)

Mỗi Component trong thư viện này được định nghĩa đầy đủ **13 thuộc tính kỹ thuật** và bắt buộc hỗ trợ trọn vẹn các trạng thái tương tác (**`Default`**, **`Pressed / Hover`**, **`Focused`**, **`Disabled`**, **`Loading`**) cùng các biến thể nghiệp vụ (**`Variants`**) để đội ngũ Flutter và Laravel Blade tái sử dụng nhất quán trên toàn bộ 70 màn hình.

---

## Chương 2. Nhóm 1 – Actions (`Buttons & Interactive Triggers`)

### `CMP-ACT-01`: System Buttons (`Primary`, `Secondary`, `Auction Bid`, `Tertiary`, `Destructive`, `Icon Button`)

1. **Component ID:** `CMP-ACT-01`
2. **Purpose:** Thực thi các hành động chuyển đổi chính trên toàn ứng dụng (Mua hàng, Đặt giá thầu, Gửi kiểm duyệt, Thanh toán QR, Xác nhận nhận hàng, Phán quyết khiếu nại).
3. **Structure:** `[Container (Radius 8px)]` $\rightarrow$ `[Optional Leading Icon (20px)]` + `[Gap 8px]` + `[Label Text (Be Vietnam Pro SemiBold)]` (hoặc `[CircularProgressIndicator 20px]` khi đang ở trạng thái `Loading`).
4. **Variants (6 Biến thể chuẩn):**
   - **V1 – `Primary Button`:** Nền `color.brand.primary` (`#294638`), chữ `color.text.inverse` (`#FAF5EC`). Dùng cho: *Mua ngay*, *Đặt hàng*, *Gửi kiểm duyệt*, *Đã nhận được hàng*.
   - **V2 – `Auction CTA Button`:** Nền `color.brand.secondary` (`#873A43`), chữ `#FAF5EC`, icon búa đấu giá `🔨`. Dùng riêng cho: *Đặt giá thầu (`Place Bid`)*.
   - **V3 – `Secondary / Outlined Button`:** Nền `color.surface.mobile.card` (`#FAF5EC`), viền `1.5px solid #294638`, chữ `#294638`. Dùng cho: *Thêm vào giỏ*, *Lưu nháp*, *Xem trước*.
   - **V4 – `Tertiary / Ghost Button`:** Nền trong suốt, không viền, chữ `#294638` hoặc `#655E57`. Dùng cho: *Đặt lại bộ lọc*, *Đóng*, *Hủy bỏ trong Dialog*.
   - **V5 – `Destructive Button`:** Nền `color.semantic.error` (`#A62B2B`) và chữ `#FAF5EC` (hoặc nền `#FCE8E8`, viền `#E5A6A6`, chữ `#A62B2B` cho nút phụ). Dùng cho: *Hủy đơn hàng*, *Từ chối kiểm duyệt (`Reject`)*, *Khóa tài khoản (`Suspend`)*.
   - **V6 – `Icon Button`:** Khung chạm `48x48px`, icon trung tâm `24px`, hỗ trợ gắn `Notification Badge` tròn (`16px`, nền `#873A43`, chữ trắng `10px`) ở góc trên bên phải.
5. **States (5 Trạng thái bắt buộc):**
   - **`Default`:** Hiển thị màu chuẩn của từng Variant.
   - **`Pressed` (Mobile) / `Hover` (Web):** Nền tối hơn 1 cấp (`#1E352A` cho Primary, `#6E2D35` cho Auction CTA), thu nhỏ nhẹ `scale(0.99)` trong `100ms`.
   - **`Focused`:** Xuất hiện vòng viền ngoài `2px solid #C79B4B` cách nút `2px`.
   - **`Disabled`:** Nền `#E5DDD2`, chữ và icon `#ACA399`, khóa hoàn toàn sự kiện `onTap` (`null`).
   - **`Loading`:** Khóa sự kiện `onTap` (chống bấm đúp 2 lần gây lỗi Double Payment / Double Bid), ẩn icon trái, hiển thị `Spinner 20px` quay liên tục bên cạnh dòng chữ *"Đang xử lý..."*.
6. **Dimensions:**
   - Kích thước Lớn (`Large` – chuẩn Mobile CTA): Cao **`48px`** (`space.12`), padding ngang `20px`.
   - Kích thước Vừa (`Medium` – chuẩn Web Admin & Card): Cao **`40px`**, padding ngang `16px`.
   - Kích thước Nhỏ (`Small` – Chip/Table Action): Cao **`32px`**, padding ngang `12px`.
7. **Typography:** `type.button.large` (`15px SemiBold`) cho nút `48px`; `type.button.small` (`13px SemiBold`) cho nút `32px–40px`.
8. **Color & Spacing Tokens:** `color.brand.*`, `color.semantic.error`, `radius.sm` (`8px`), `space.2` (`8px` gap giữa icon và chữ).
9. **Interaction & Accessibility:** Vùng chạm tối thiểu `48x48dp` trên Mobile; có `Semantics(button: true, enabled: ...)` cho trình đọc màn hình.
10. **Usage Rules & Implementation Notes:** Trên một màn hình chỉ được có tối đa 1 cụm `Primary Button` nổi bật nhất. Trong Flutter triển khai qua `IzithriftButton` widget; trong Blade triển khai qua `<x-admin.button variant="..." state="...">`.

---

## Chương 3. Nhóm 2 – Form Controls (`Inputs, Search, Selectors & Image Uploader`)

### 3.1. `CMP-FRM-01`: Text Field, Search Field, Dropdown & Date/Time Input
1. **Component ID:** `CMP-FRM-01`
2. **Purpose:** Thu thập dữ liệu đầu vào từ người dùng (Đăng nhập, Tìm kiếm, Đăng bán sản phẩm, Nhập mã vận đơn, Cấu hình phí Admin).
3. **Structure:**
   - `[Top Label (14px SemiBold #302D2A + Dấu * đỏ nếu bắt buộc)]`
   - `[Gap 6px]`
   - `[Input Container (Height 48px, Radius 8px, Bg #FAF5EC)]`: `[Leading Icon]` + `[Text Input (16px Regular)]` + `[Trailing Action (Clear X / Show-Hide Eye / Unit 'VNĐ')]`
   - `[Gap 4px]`
   - `[Bottom Helper Text hoặc Error Message (12px Regular)]`.
4. **Variants:**
   - **V1 – `Standard Text / Password Field`** (`M-AU-03`, `M-PF-04`).
   - **V2 – `Multiline TextArea`** (Cao tối thiểu `96px–120px`, dùng cho mô tả lỗi `defect_info`, lý do từ chối `reason` và mô tả khiếu nại).
   - **V3 – `Currency Numeric Input`** (Tự động định dạng dấu chấm phân cách hàng nghìn khi gõ và có hậu tố `VNĐ` cố định bên phải, dùng cho Giá bán & Đặt giá thầu).
   - **V4 – `Global Search Field`** (Bo tròn `radius.full` hoặc `radius.sm`, có nút xóa nhanh `X` khi đang gõ).
   - **V5 – `Dropdown / Bottom Sheet Selector & Date/Time Picker`** (Dùng cho chọn Danh mục, Thương hiệu, Hãng vận chuyển và Khung giờ phiên đấu giá).
5. **States:**
   - **`Default`:** Nền `#FAF5EC` (`#FFFFFF` trên Admin), viền `1px solid #D8CBB8`.
   - **`Focused`:** Viền `1.5px solid #294638`, nền `#FFFDF9`.
   - **`Error (Validation Failed – 422)`:** Viền `1.5px solid #A62B2B`, nền `#FFF8F8`, hiển thị icon cảnh báo nhỏ kèm dòng lỗi màu `#A62B2B` ngay bên dưới.
   - **`Disabled / Read-Only`:** Nền `#EAE3D9`, chữ `#8C837A` (áp dụng cho ô Số lượng `= 1` bị khóa cứng khi chọn bán Đấu giá theo `BR-PR-01`).
6. **Dimensions & Tokens:** Cao `48px` (Single-line), padding ngang `16px`, `radius.sm` (`8px`), `type.body.large` (`16px`).

---

### 3.2. `CMP-FRM-02`: Choice Controls (`Checkbox`, `Radio`, `Condition Choice Chips`, `Switch`) & `Image Uploader Grid`
1. **Component ID:** `CMP-FRM-02`
2. **Purpose:** Chọn sản phẩm theo nhóm Tiệm trong Giỏ hàng (`M-CR-01`), chọn Tình trạng đồ si (`M-SL-03`), bật/tắt trang trí Giáng sinh (`M-PF-06`) và tải ảnh sản phẩm/bằng chứng khiếu nại.
3. **Variants & States:**
   - **Checkbox & Radio:** Kích thước ô `20x20px` (vùng chạm `48x48px`); khi `Unchecked` có viền `1.5px solid #8C837A`; khi `Checked` tô đặc `#294638` với dấu tích `#FAF5EC`.
   - **Condition Choice Chips (`Like New`, `Good`, `Fair`, `Vintage Worn`):** Cao `36px`, khi chưa chọn có nền `#FAF5EC` viền `#D8CBB8`; khi chọn chuyển sang nền `#294638` chữ `#FAF5EC`.
   - **Image Uploader Grid (`1..8` Photos):** Lưới ô vuông `88x88px` (`radius.sm = 8px`). Ô đầu tiên có viền nét đứt `#294638` và nhãn **`[+ Ảnh bìa chính *]`**; các ô đã tải ảnh hiển thị nút `[X]` góc trên để xóa và thanh tiến trình khi đang upload; nếu chọn ảnh `> 5MB` hoặc sai định dạng (`NFR-SEC-05`), viền ô chuyển sang đỏ `#A62B2B` kèm thông báo lỗi ngay lập tức.

---

## Chương 4. Nhóm 3 – Commerce & Secondhand Trust Components (`Product Cards, Inspection Slip & Seller Card`)

### 4.1. `CMP-COM-01`: Product Card (Phân Biệt Rõ 4 Biến Thể Nghiệp Vụ – `UI-DEC-01`)

1. **Component ID:** `CMP-COM-01`
2. **Purpose:** Hiển thị tóm tắt sản phẩm trên lưới 2 cột (`M-HM-01`, `M-DS-02`, `M-PF-05`, `M-SL-02`), giúp người mua phân biệt trong 1 giây giữa hàng Giá cố định, hàng Đấu giá, hàng Đã bán và bài đăng đang quản lý.
3. **Structure:**
   - **Khung Thẻ (`Card Container`):** Rộng `(Viewport - 32px - 12px) / 2` (~`173px` trên màn hình `390px`), nền `#FAF5EC`, viền `1px solid #D8CBB8`, `radius.md` (`12px`), `elevation.1`.
   - **Vùng Ảnh (`Aspect Ratio 4:5`):** Hiển thị ảnh thật 100%, góc trên bên trái gắn **`Condition Badge`**, góc trên bên phải gắn nút **`Favorite Heart` (`32x32px`)**.
   - **Vùng Nội dung (`Padding 10px`):** Tên sản phẩm (`type.title.card`, tối đa 2 dòng), Giá bán (`type.numeric.price.card`), và dòng chân thẻ chứa Tên tiệm + Điểm sao (`★ 4.9`).
4. **4 Variants Bắt Buộc (Khác biệt rõ rệt về cấu trúc):**
   - **Variant 1 – `Fixed-Price Product Card` (Sản phẩm Giá cố định đang bán):**
     - Khung thẻ chữ nhật bo góc chuẩn.
     - Hiển thị nhãn Tình trạng (`Good` / `Like New`) và Giá bán cố định màu xanh `#294638` (`450.000đ`).
   - **Variant 2 – `Auction Product Card` (Sản phẩm Đấu giá – Thiết kế Cuống Vé `Ticket Stub Motif` theo `UI-DEC-01`):**
     - Ngay dưới chân ảnh có **Dải băng Đếm ngược & Lượt trả giá** (`Bg #873A43`, chữ `#FAF5EC`: `⏳ 08:42 | 🔥 12 bids`).
     - Giữa phần thông tin và phần giá có **đường kẻ nét đứt ngang (`1px dashed #B8A892`) kèm 2 vết khuyết bán nguyệt nhỏ (`6px`) ở hai cạnh bên** tạo hình dáng tấm vé đấu giá.
     - Giá hiển thị màu đỏ rượu vang `#873A43` kèm nhãn nhỏ *"Giá hiện tại"*.
   - **Variant 3 – `Sold Out Product Card` (Sản phẩm Đã bán `SOLD`):**
     - Phủ lớp mờ nhẹ `rgba(48, 45, 42, 0.45)` lên vùng ảnh kèm huy hiệu trung tâm **`ĐÃ BÁN (SOLD OUT)`** (`#E0D8CE` / `#302D2A`). Giá tiền chuyển sang màu xám `#655E57`.
   - **Variant 4 – `Seller Management Product Card` (Hiển thị trong `M-SL-02 My Listings`):**
     - Gắn **Huy hiệu Trạng thái Kiểm duyệt** (`APPROVED`, `PENDING_REVIEW`, `REJECTED`, `DRAFT`, `HIDDEN`) ở góc ảnh.
     - Phần chân thẻ thay thông tin Tiệm bằng thanh nút thao tác nhanh của người bán (`[Sửa]`, `[Tạm ẩn]`, hoặc **`[Xem lý do từ chối & Sửa lại]`** màu đỏ nếu đang ở `REJECTED` – `DEC-05`).
5. **States:** `Default`, `Pressed` (hiệu ứng chạm nhẹ), `Loading Skeleton` (khung xám kem nhấp nháy khi đang tải API).

---

### 4.2. `CMP-COM-02`: Secondhand Condition & Defect Inspection Slip (`Phiếu Kiểm Định Tình Trạng Đồ Cũ` – `UI-DEC-01`, `BR-PR-03`)
1. **Component ID:** `CMP-COM-02`
2. **Purpose:** Trình bày minh bạch tình trạng món đồ secondhand, vết xước/lỗi (`defect_info`) và mức độ xác minh ngay trên màn hình Chi tiết sản phẩm (`M-PR-01`) và Phòng đấu giá (`M-AC-03`).
3. **Structure & Styling (`Direction C Synthesis`):**
   - Khung hộp nền `color.surface.mobile.secondary` (`#E7DAC6`), viền `1px solid #B8A892`, góc trên bên phải gắn **Huy hiệu Xác minh (`verification_level`: `🛡️ Đã kiểm duyệt ảnh - MODERATOR_REVIEWED`)**.
   - Chia làm 2 phần ngăn cách bằng đường kẻ nét đứt `1px dashed #B8A892`:
     1. **Lưới thông số 2 cột:** *Tình trạng (`Condition Badge`)* | *Thương hiệu* | *Danh mục* | *Số lượng*.
     2. **Hộp Mô tả Khuyết điểm / Vết xước (`defect_info`):** Có icon kính lúp soi lỗi `🔍`, in rõ nguyên văn mô tả lỗi của người bán và nút liên kết **`[Chạm vào ảnh để phóng to kiểm tra vết xước ->]`** mở `M-PR-02`.

---

### 4.3. `CMP-COM-03`: Product Image Gallery, Seller Card & Rating Component
- **Product Image Gallery (`CMP-COM-03A`):** Khung ảnh tỷ lệ `1:1` hoặc `4:5`, có bộ đếm vị trí ảnh (`1/5`) ở góc dưới bên phải, dải ảnh thu nhỏ (`Thumbnails 56x56px`) bên dưới và hỗ trợ chạm mở `M-PR-02` (`Pinch-to-Zoom` toàn màn hình).
- **Seller Profile Card (`CMP-COM-03B`):** Hiển thị Avatar `48x48px`, tên Tiệm (`Fraunces 16px SemiBold`), huy hiệu **Điểm uy tín (`Trust Score`)**, Điểm sao trung bình (`★ 4.9`), tỷ lệ hoàn tất đơn và nút `[Xem tiệm]` / `[+ Theo dõi]`.
- **Star Rating Component (`CMP-COM-03C`):** Hỗ trợ 2 chế độ: *Read-Only Display* (`16px` màu vàng đồng `#C79B4B`) và *Interactive Input* (`36px` trên màn hình đánh giá `M-RV-01` cho phép chạm chọn từ `1` đến `5` sao).

---

## Chương 5. Nhóm 4 – Scheduled Auction Components (`Countdown, Bid Display, Bid Sheet & History`)

### 5.1. `CMP-AUC-01`: Real-Time Auction Countdown Banner & Anti-Sniping Alert
1. **Component ID:** `CMP-AUC-01`
2. **Purpose:** Hiển thị thời gian còn lại của phiên đấu giá chuẩn theo giờ máy chủ (`BR-AU-01`) và thông báo tức thì khi kích hoạt gia hạn 2 phút cuối (`BR-AU-04`).
3. **Variants & States (3 Trạng thái bắt buộc):**
   - **State 1 – `Normal Running` (`Còn > 15 phút`):** Nền `#E7DAC6`, chữ `#302D2A`, font `JetBrains Mono Bold 20px` (`tabular-nums`).
   - **State 2 – `Urgent Ending Soon` (`Còn <= 15 phút`):** Nền chuyển sang đỏ rượu vang `#873A43` (hoặc `#A62B2B` khi dưới 2 phút), chữ sáng `#FAF5EC`, icon đồng hồ cát cảnh báo.
   - **State 3 – `Anti-Sniping Extended` (`Khi có bid hợp lệ trong 2 phút cuối / 30s Demo` – `AF-04`):** Hiển thị dải thông báo nổi bật màu vàng hổ phách (`Bg #FDECC8`, viền `#C79B4B`, chữ `#7A4B0E`): **`⚡ ĐÃ CỘNG THÊM +02:00 (Gia hạn chống trả giá giây cuối – Lần #X)`**.
   - **State 4 – `Auction Ended`:** Nền `#E5DDD2`, chữ `#655E57`, hiển thị **`PHIÊN ĐẤU GIÁ ĐÃ KẾT THÚC`**.

### 5.2. `CMP-AUC-02`: Current Bid Display Box, Bid Input Sheet & Bid History Item
- **Current Bid Ticket Box (`M-AC-03`):** Khung cuống vé hiển thị Giá cao nhất hiện tại (`24px Bold #873A43`), người đang dẫn đầu, bước giá tối thiểu (`min_bid_increment`), mức giá hợp lệ tiếp theo (`minimum_next_bid`) và huy hiệu trạng thái Giá sàn (`✓ Đã đạt giá sàn` màu xanh `#236343` hoặc `Chưa đạt giá sàn` màu vàng nâu `#945814`).
- **Quick Bid Input Sheet (`M-AC-04`):** Chứa 3 nút cộng bước giá nhanh (`+1 bước giá`, `+2 bước giá`, `+5 bước giá` dạng pill cao `36px`), ô nhập số tiền tùy chỉnh và dòng cảnh báo không thể rút lại lượt trả giá (`BR-AU-02`).
- **Bid History Item:** Dòng lịch sử hiển thị thứ hạng (`#1 Dẫn đầu`), tên người đặt giá đã che một phần (`minh***`), số tiền đặt (`tabular-nums`) và thời gian đặt chính xác đến giây (`HH:mm:ss`).

---

## Chương 6. Nhóm 5 – Order, Payment, Escrow & Status Components (`4-State Header, Fee Slip & Timeline`)

### 6.1. `CMP-ORD-01`: Transaction 4-State Header Card (`Thẻ Tổng Hợp 4 Trạng Thái Độc Lập` – `ADR-03`)
1. **Component ID:** `CMP-ORD-01`
2. **Purpose:** Hiển thị rõ ràng cả 4 vòng đời trạng thái độc lập (`order_status`, `payment_status`, `escrow_status`, `dispute_status`) trên đầu màn hình Chi tiết Đơn mua (`M-OR-03`), Đơn bán (`M-SL-06`) và Admin (`A-OR-02`) mà không gây rối mắt (`UI-DESIGN-PRINCIPLE-04`).
3. **Structure:**
   - **Tầng 1 (Trạng thái Vận hành chính):** Tiêu đề lớn hiển thị `order_status` kèm mô tả hành động tiếp theo (ví dụ: *"Đơn hàng đã giao – Tự động hoàn tất sau 23 giờ 15 phút"*).
   - **Tầng 2 (Dải 3 Huy hiệu Bảo vệ Tài chính):**
     1. **`Escrow Status Badge`:** `🛡️ Tiền đang giữ trong Escrow (HELD)` (`#DDF0F0`/`#1C5858`) | `✅ Đã giải ngân cho Tiệm (RELEASED)` | `↩️ Đã hoàn tiền 100% (REFUNDED)`.
     2. **`Payment Status Badge`:** `💳 Đã thanh toán QR (PAID)` | `⏳ Chờ thanh toán (UNPAID)`.
     3. **`Dispute Status Badge` (Chỉ hiện khi khác `NONE`):** `🔒 Đang tranh chấp – Đã khóa giải ngân (OPEN)` (`#F4E4F0`/`#6A2C5A`).

---

### 6.2. `CMP-ORD-02`: Buyer Protection Fee Breakdown Slip & Escrow Shield Box (`DEC-04`, `DEC-07`)
1. **Component ID:** `CMP-ORD-02`
2. **Purpose:** Trình bày minh bạch công thức tính tiền đơn hàng tại màn hình Checkout (`M-OR-01`), Chi tiết đơn hàng (`M-OR-03`, `M-SL-06`) và Biên lai thanh toán (`M-PM-02`).
3. **Structure (`Receipt Slip Style`):**
   - Dòng 1: `Tổng tiền hàng (item_subtotal)` $\rightarrow$ Căn phải `tabular-nums`.
   - Dòng 2: `Phí vận chuyển trên ứng dụng (shipping_fee)` $\rightarrow$ **`0 VNĐ`** *(Kèm ghi chú nhỏ: Hai bên tự thỏa thuận vận chuyển)*.
   - Dòng 3: **`🛡️ Phí bảo vệ người mua (Buyer Protection Fee)`** $\rightarrow$ Căn phải `tabular-nums` (Kèm chú thích công thức: `X% giá trị đơn + Y đ phí cố định`).
   - Hộp thông tin bảo hiểm màu xanh nhạt (`#E3ECE7`): *"Cam kết hoàn trả đủ 100% Tổng thanh toán (gồm cả tiền hàng + phí bảo vệ) nếu hủy đơn hợp lệ hoặc nếu hàng bị rách, sai mô tả, không giao hàng (`DEC-07`)"*.
   - Đường kẻ nét đứt `1.5px dashed #B8A892`.
   - Dòng Tổng kết: **`TỔNG THANH TOÁN (total_amount)`** (`20px Bold #294638`).
   - *(Biến thể dành riêng cho Người bán trên `M-SL-06` – `SELLER-UX-01`):* Làm nổi bật dòng **`TIỀN HÀNG BẠN THỰC NHẬN (100% item_subtotal)`** để người bán thấy rõ mình nhận đủ 100% giá bán.

---

### 6.3. `CMP-ORD-03`: Order & Shipment Vertical Timeline (`M-OR-03`, `M-SL-06`, `A-OR-02`)
- Hiển thị chuỗi các mốc thời gian dọc từ dưới lên trên: `Đặt hàng` $\rightarrow$ `Thanh toán & Giữ tiền Escrow (HELD)` $\rightarrow$ `Người bán chuẩn bị hàng (PREPARING)` $\rightarrow$ `Đã gửi hàng (SHIPPED – Hiển thị rõ Tên hãng vận chuyển & nút Sao chép Mã vận đơn tracking_code)` $\rightarrow$ `Đã giao hàng (DELIVERED – Hiển thị mốc đóng băng auto_complete_at)` $\rightarrow$ `Hoàn tất & Giải ngân (COMPLETED / RELEASED)`.

---

## Chương 7. Nhóm 6 – Navigation, Overlays & Feedback (`Bars, Sheets, Dialogs & 4 UI States`)

### 7.1. `CMP-NAV-01`: Mobile Top App Bar, 5-Tab Bottom Navigation (`NAV-DEC-01`) & Tab Bar
- **Global Top App Bar:** Cao `56px`, nền `#F4EBDD` (riêng trên **Tab 4 – Kênh Bán `/seller`** đổi nền sang **`Forest Pine #294638`** và chữ/icon sang **`#FAF5EC`** theo đúng quyết định `UI-DEC-02`).
- **5-Tab Bottom Navigation Bar:** Cao `64px`, nền `#FAF5EC`, viền trên `1px solid #D8CBB8`. Tab đang chọn có pill nền `#E3ECE7`, icon Fill `#294638` và nhãn `11px SemiBold #294638`; tab chưa chọn có icon Outline `#655E57` và nhãn `11px Regular #655E57`.
- **Scrollable Status Tab Bar (trên `M-SL-02`, `M-OR-02`, `M-SL-05`, `M-AC-01`):** Cao `44px`, hỗ trợ cuộn ngang cho 7 tab trạng thái kèm badge đếm số lượng bản ghi trong từng tab.

### 7.2. `CMP-OVL-01`: Bottom Sheet, Confirmation Dialog (`NFR-UX-03`) & Toast / Alert
- **Bottom Sheet (`M-DS-03`, `M-AC-04`, `M-OR-04`, `M-SL-07`):** Bo góc trên `16px`, có thanh kéo (`Drag Handle 40x4px #D8CBB8`) ở đỉnh, chiều cao tối đa `85%` màn hình, lớp phủ mờ phía sau `rgba(48, 45, 42, 0.5)`.
- **Mandatory Confirmation Dialog (`NFR-UX-03`):** Bắt buộc xuất hiện trước mọi hành động quan trọng (Đặt giá thầu, Chốt phiên sớm, Hủy đơn hàng, Xác nhận đã nhận hàng giải ngân Escrow, Duyệt/Từ chối sản phẩm, Phán quyết tài chính). Luôn có tiêu đề `Fraunces 18px`, nội dung giải thích hậu quả nghiệp vụ rõ ràng và 2 nút: `[Hủy bỏ]` (Tertiary) + `[Xác nhận thực hiện]` (Primary hoặc Destructive).
- **4 Trạng thái Màn hình Chuẩn (`Loading Skeleton`, `Empty State Card`, `Error Retry Card`, `Guest Welcome Card`):** Được đóng gói thành 4 Widget/Blade Component dùng chung toàn hệ thống.

---

## Chương 8. Nhóm 7 – Admin Dashboard Components (`Data Table, Split-Pane Moderation, Dispute Verdict & DevTools`)

1. **`CMP-ADM-01` – Admin Left Sidebar & Header Shell:** Sidebar rộng `260px` nền `#294638`, tự động ẩn/hiện các mục menu theo Role (`Admin`, `Moderator`, `Support Staff`) và cờ `DEMO_MODE=true`.
2. **`CMP-ADM-02` – Dashboard KPI Metric Card (`A-DB-01`, `A-ES-01`):** Thẻ nền `#FFFFFF`, viền `1px solid #D8CBB8`, hiển thị tiêu đề chỉ số (`13px SemiBold #655E57`), con số thống kê lớn truy vấn thực từ PostgreSQL (`28px Bold #302D2A tabular-nums`), phân rã trạng thái phụ và link điều hướng nhanh.
3. **`CMP-ADM-03` – High-Density Data Table & Filter Panel (`A-OR-01`, `A-PM-01`, `A-ES-01`, `A-AD-01`):**
   - Header bảng nền `#F4EBDD`, chữ `12px SemiBold #302D2A` viết hoa nhẹ.
   - Dòng dữ liệu cao tối thiểu `52px`, hover đổi nền `#FBF9F5`. Các cột số tiền bắt buộc căn phải (`text-right tabular-nums`), các cột mã đơn/mã bút toán dùng font `JetBrains Mono`.
   - Chân bảng tích hợp `Pagination Component` hiển thị rõ *"Hiển thị 1–20 trên tổng số X bản ghi"*.
4. **`CMP-ADM-04` – Product Moderation Split-Pane Panel (`A-MD-02` – `DEC-05`):** Cột trái hiển thị bộ ảnh phóng to + `product_moderation_logs`; cột phải chứa bộ chọn `verification_level`, ô nhập `reason` (bắt buộc khi Reject) và 2 nút `[Phê duyệt (Approve)]` / `[Từ chối (Reject)]`.
5. **`CMP-ADM-05` – Dispute Financial Verdict Panel (`A-DP-02` – `PERM-CM-09`, `DEC-07`):**
   - Khung ra quyết định tài chính **chỉ render cho `Administrator` (`ACT-05`)**, bị khóa và ẩn đối với `Support Staff` (`ACT-04`).
   - Gồm 3 Radio Cards tương ứng 3 phán quyết: (1) `APPROVE_BUYER_REFUND` (Hoàn 100% `total_amount`), (2) `RELEASE_TO_SELLER` (Giải ngân 100% `item_subtotal`), (3) `PARTIAL_REFUND` (Tự động tính số tiền còn lại cho Seller khi Admin gõ số tiền hoàn cho Buyer theo `BR-FN-06`).
6. **`CMP-ADM-06` – Developer Tools Trigger Card (`A-DT-01` – `DEMO_MODE=true`):** Thẻ điều khiển có viền cảnh báo `#C79B4B`, hiển thị số lượng bản ghi đủ điều kiện và nút bấm kích hoạt thủ công các Scheduled Jobs lũy đẳng (`BR-AD-01`, `ADR-05`).