# 10. MOBILE CART, CHECKOUT, MOCK QR PAYMENT, ORDER TRACKING & DISPUTE UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P305B-ORDER-PAYMENT-UI`
- **Version:** `1.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`
- **Screen IDs Covered:** `M-CR-01` (Cart), `M-OR-01` (Checkout Preview), `M-PM-01` (Mock QR Payment), `M-PM-02` (Escrow Receipt), `M-OR-02` (My Purchases List), `M-OR-03` (Buyer Order Detail), `M-OR-04` (3-Tier Cancel Modal), `M-OR-05` (Confirm Delivery Dialog), `M-RV-01` (Rate Seller), `M-DP-01` (Submit Dispute), `M-DP-02` (Dispute List), `M-DP-03` (Dispute Case Room)
- **Compliance Ref:** `BF-04..10`, `OF-01..10`, `BR-OR-01..05`, `BR-FN-01..07`, `BR-DP-01..02`, `BR-RV-01`, `DEC-02..07`, `ADR-03..06`, `UI-DEC-01..04`, `DS-DEC-01..03`

---

## Chương 1. Kiến Trúc Giao Diện Giao Dịch, Sổ Cái Escrow & 4 Máy Trạng Thái Độc Lập (`Transaction & Escrow UI Architecture`)

Cụm 12 màn hình giao dịch trong tài liệu này trực tiếp hiện thực hóa các quy tắc tài chính và vận hành nghiêm ngặt nhất của **Retro Market (`izithrift`)**:
1. **Giỏ hàng Gom nhóm theo Tiệm – Checkout Đơn Tiệm (`1 Seller per Order – BR-OR-01`):** Trên `M-CR-01`, các món đồ được đóng khung theo từng Tiệm bán. Khi người mua tích chọn sản phẩm ở Tiệm B, hệ thống tự động bỏ tích ở Tiệm A kèm chú thích nhẹ nhàng để đảm bảo mỗi đơn hàng có một luồng vận chuyển và một khoản giữ tiền Escrow độc lập.
2. **Phiếu Kê Chi Phí & Bảo Vệ Escrow Minh Bạch (`Buyer Protection Fee Slip – CMP-ORD-02` & `DEC-04`):** Trên `M-OR-01`, `M-PM-01`, `M-PM-02` và `M-OR-03`, bảng tính tiền luôn hiển thị rõ 4 dòng:
   - `Tổng tiền hàng (item_subtotal)`
   - `Phí vận chuyển trên ứng dụng (shipping_fee): 0 VNĐ`
   - `🛡️ Phí bảo vệ người mua (buyer_protection_fee: 5%–8% + 5k–10k)`
   - `💰 Tổng thanh toán (total_amount = item_subtotal + buyer_protection_fee)` kèm cam kết hoàn trả đủ **100% `total_amount`** nếu hủy hợp lệ hoặc thắng khiếu nại (`DEC-07`).
3. **Cổng Thanh Toán QR Mô Phỏng Phục Vụ Bảo Vệ Đồ Án (`Mock QR Payment Gateway` – `M-PM-01`):** Kết hợp mã QR sinh động nội bộ, đồng hồ đếm ngược `payment_expires_at` và **Bảng Điều Khiển Mô Phỏng Đồ Án (`Simulate Payment Success` / `Simulate Failure`)** có khóa chống bấm đúp (`Idempotent Loading Guard – BR-FN-03`).
4. **Thẻ Tổng Hợp 4 Trạng Thái & Ma Trận Nút Hành Động Động (`M-OR-03` – `ADR-03`, `DEC-03`, `DEC-06`):** Hiển thị đồng thời `order_status`, `payment_status`, `escrow_status` và `dispute_status`, tự động đổi thanh nút dưới đáy khớp 100% với từng cấp trạng thái (Hủy trực tiếp hoàn 100% ở `PAID` $\rightarrow$ Gửi yêu cầu xin hủy ở `PREPARING` $\rightarrow$ Mở khiếu nại ở `SHIPPED` / `DELIVERED` $\rightarrow$ Xác nhận nhận hàng giải ngân ở `DELIVERED` $\rightarrow$ Đánh giá 1–5 sao ở `COMPLETED`).

---

## Chương 2. Đặc Tả High-Fidelity Cụm Giỏ Hàng, Checkout & Thanh Toán QR (`M-CR-01`, `M-OR-01`, `M-PM-01`, `M-PM-02`)

### 2.1. Screen `M-CR-01`: Shopping Cart Grouped by Seller (`/cart` – `BF-04`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-CR-01` – Shopping Cart Grouped by Seller (`/cart`) |
| **Purpose** | Quản lý các sản phẩm `FIXED_PRICE` đã thêm vào giỏ, gom nhóm theo từng Người bán và chọn 1 nhóm Tiệm để tiến hành đặt hàng (`FR-CR-01`, `BR-OR-01`). |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `TopAppBar (Height 56px)`: `[<-]` + Tiêu đề `Fraunces 18px SemiBold #302D2A` (*"Giỏ hàng của bạn (N)"*).<br>2. `SingleSellerOrderRuleBanner (Bg #E7DAC6, Border Bottom 1px #B8A892, Padding 10px 16px)`:<br>   - Icon `Info 16px #294638` + Chữ `12px Regular #302D2A`: *"Mỗi đơn hàng được thanh toán riêng theo từng Tiệm bán để đảm bảo theo dõi vận chuyển và giữ tiền bảo vệ Escrow độc lập."*<br>3. `Expanded ListView (Padding 16px, Gap 16px, Bottom Padding 96px)`:<br>   - **Khối Nhóm Tiệm (`SellerCartGroupCard`: `Bg #FAF5EC`, `Border 1.5px #294638` khi đang được chọn / `1px #D8CBB8` khi chưa chọn, `Radius 12px`):**<br>     - *Group Header (`Height 44px`, `Padding Horizontal 12px`, `Border Bottom 1px #E5D9C8`):* `RadioGroupButton` chọn cả Tiệm + Icon `Storefront 18px #294638` + Tên Tiệm (`14px SemiBold #302D2A`).<br>     - *Cart Item Rows (`Padding 12px`):* `Checkbox (20x20px)` + Ảnh sản phẩm `68x68px (Radius 8px)` + Tên sản phẩm (`14px SemiBold`, 1 dòng) + Nhãn tình trạng `[Good]` + Giá bán (`15px Bold #294638 tabular-nums`) + Bộ chọn số lượng `[ - | 1 | + ]` (khóa nút `+` khi chạm `available_quantity`) + Nút xóa `[🗑️]` (`IconButton 36x36px` $\rightarrow$ Mở `Confirmation Dialog`).<br>   - **Khối Sản phẩm Không còn khả dụng (`Unavailable Cart Items Section` – Đặt ở cuối danh sách nếu có món vừa `SOLD` hoặc `HIDDEN`):**<br>     - Nền xám kem `#EAE3D9`, ảnh mờ 50%, nhãn `[Đã hết hàng]`, khóa Checkbox và có nút `[Xóa tất cả món hết hàng]`.<br>4. `StickyCartCheckoutBar (Height 76px + Safe Area, Bg #FFFDF9, Border Top 1px #D8CBB8, Elevation 2, Padding 12px 16px)`:<br>   - Trái: *"Tạm tính (2 món – Tiệm Nhà Gấu):"* + Số tiền **`600.000 VNĐ`** (`18px Bold #294638 tabular-nums`) + Chú thích nhỏ *"Chưa gồm Phí bảo vệ Escrow"*.<br>   - Phải: Nút `Primary Button (Height 48px, Bg #294638)`: **`[Mua hàng (2) ->]`** ($\rightarrow$ Mở `M-OR-01`). |

---

### 2.2. Screen `M-OR-01`: Checkout Preview & Buyer Protection Fee Breakdown (`/checkout` – `BF-05`, `OF-01`, `OF-02`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-OR-01` – Checkout Preview & Buyer Protection Fee Breakdown (`/checkout`) |
| **Purpose** | Chọn địa chỉ nhận hàng, kiểm tra danh sách món đồ đặt mua từ 1 Tiệm, hiển thị minh bạch bảng tính **Phí bảo vệ người mua (`Buyer Protection Fee`)** + **Phí vận chuyển `0đ`** do Backend tính toán (`NFR-SEC-03`, `DEC-04`), và khởi tạo đơn hàng nguyên tử có lưu cứng Snapshot (`BR-OR-02`). |
| **Entry Point** | Nhấn `[Mua hàng ->]` từ `M-CR-01` hoặc nhấn `[Mua ngay]` từ `M-PR-01` (`UX-CHECK-01`). |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `TopAppBar (Height 56px)`: `[<-]` + Tiêu đề `Fraunces 18px SemiBold #302D2A` (*"Xác nhận Đơn hàng"*).<br>2. `Expanded SingleChildScrollView (Padding 16px, Gap 16px, Bottom Padding 96px)`:<br>   - **Card 1 – `ShippingAddressSelectorCard (Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 16px)`:**<br>     - Header: Icon `MapPinLine 18px #873A43` + *"Địa chỉ nhận hàng"* + Nút phải **`[Đổi địa chỉ >]`** ($\rightarrow$ Mở `M-PF-03`).<br>     - Nếu đã có địa chỉ: Hiển thị Tên người nhận + SĐT (`tabular-nums`) + Huy hiệu `[Mặc định]` + Địa chỉ đầy đủ.<br>     - Nếu sổ địa chỉ trống: Hiển thị nút viền nét đứt cao `48px`: **`[+ Thêm địa chỉ nhận hàng đầu tiên]`** ($\rightarrow$ Mở `M-PF-04`).<br>   - **Card 2 – `OrderItemsPreviewCard (Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 16px)`:**<br>     - Header: `🏪 Tiệm Đồ Si Nhà Gấu` (`14px SemiBold #294638`).<br>     - Danh sách món đồ: Ảnh `56x56px`, Tên sản phẩm, Tình trạng (`condition`), Khuyết điểm đã ghi (`defect_info` tóm tắt 1 dòng), Số lượng `x1` và Đơn giá (`tabular-nums`).<br>   - **Card 3 – `BuyerProtectionFeeBreakdownSlip (CMP-ORD-02 – Bg #E7DAC6, Border 1.5px solid #B8A892, Radius 12px, Padding 16px – DEC-04 & BR-FN-02)`:**<br>     - Tiêu đề phiếu: Icon `Receipt 18px #302D2A` + *"Chi tiết Thanh toán & Bảo vệ Escrow"* (`15px SemiBold #302D2A`).<br>     - Đường kẻ nét đứt `1px dashed #B8A892`.<br>     - **Dòng 1:** `Tổng tiền hàng (item_subtotal)` — Căn phải: **`600.000 VNĐ`** (`14px SemiBold #302D2A tabular-nums`).<br>     - **Dòng 2:** `Phí vận chuyển trên ứng dụng (shipping_fee)` — Căn phải: **`0 VNĐ`** (`14px SemiBold #236343`) + Chú thích dưới `11px #655E57`: *"(Miễn thu phí vận chuyển trên app – Hai bên tự thỏa thuận khi giao)"*.<br>     - **Dòng 3:** `🛡️ Phí bảo vệ người mua (Buyer Protection Fee)` — Căn phải: **`43.000 VNĐ`** (`14px SemiBold #1C5858 tabular-nums`) + Chú thích công thức dưới `11px #655E57`: *"(Gồm 6% giá trị tiền hàng [36.000đ] + 7.000đ phí cố định)"*.<br>     - **Hộp Quyền lợi Bảo hiểm Escrow (`Margin Top 10px`, `Bg #DDF0F0`, `Border 1px #9ACBB0`, `Radius 8px`, `Padding 10px`):**<br>       - Chữ `12px Regular #1C5858`: *"✓ Giữ 100% số tiền 643.000đ trong sổ cái trung gian Escrow (`ESCROW_HELD`).<br>✓ Hoàn trả đủ 100% (643.000đ gồm cả tiền hàng + phí bảo vệ) nếu hủy đơn hợp lệ hoặc nếu hàng bị rách, sai mô tả, không nhận được hàng (`DEC-07`)."*<br>     - Đường kẻ nét đứt `1.5px dashed #B8A892`.<br>     - **Dòng Tổng kết:** `TỔNG THANH TOÁN (total_amount)` — Căn phải: **`643.000 VNĐ`** (`20px Bold #294638 tabular-nums`).<br>3. `StickyPlaceOrderBottomBar (Height 76px + Safe Area, Bg #FFFDF9, Border Top 1px #D8CBB8, Elevation 2, Padding 12px 16px)`:<br>   - Trái: Nhãn *"Tổng thanh toán:"* + **`643.000 VNĐ`** (`20px Bold #294638 tabular-nums`).<br>   - Phải: Nút `Primary Button (Height 48px, Bg #294638)`: **`[Đặt hàng & Thanh toán QR]`** ($\rightarrow$ Hiện `Confirmation Dialog` $\rightarrow$ Gọi `POST /orders` $\rightarrow$ Chuyển thẳng sang `M-PM-01`). |
| **Exception Handling (`409 Race Condition`)** | Nếu tại thời điểm bấm `[Đặt hàng]`, món đồ vừa được người mua khác đặt trước vài giây (`409 Conflict` từ `lockForUpdate()`), hiển thị Dialog thông báo *"Rất tiếc, món đồ này vừa được người mua khác đặt trước vài giây"* và đưa người dùng quay lại Giỏ hàng (`OF-02`). |

---

### 2.3. Screen `M-PM-01` (Mock QR Payment Gateway) & `M-PM-02` (Payment & Escrow Hold Receipt) – `BF-06`, `OF-03`

#### A. `M-PM-01`: Mock QR Payment Gateway & Expiration Timer (`/payments/:id`)
- **1. Top App Bar (`56px`):** Nút `[<-]`, Tiêu đề `Fraunces 18px SemiBold`: *"Thanh toán QR & Giữ tiền Escrow"*.
- **2. Expiration Countdown Banner (`Height 44px`, `Bg #FDF1E1`, `Border Bottom 1px #E8C28E`, `Padding Horizontal 16px`):**
  - Trái: Icon `ClockCountdown 18px #945814` + *"Hạn thanh toán đơn hàng:"*; Phải: Đồng hồ **`00 : 29 : 18`** (`JetBrains Mono 18px Bold #945814 tabular-nums`; chuyển sang nền đỏ `#FCE8E8` chữ `#A62B2B` khi còn `< 5 phút`).
- **3. QR Payment Ticket Card (`Margin 16px`, `Bg #FAF5EC`, `Border 1.5px solid #294638`, `Radius 16px`, `Padding 20px`, Căn giữa):**
  - Nhãn đầu: `CỔNG THANH TOÁN QR MÔ PHỎNG IZITHRIFT` (`11px SemiBold #294638`).
  - Mã đơn hàng: `#ORD-2026-0891` \| Mã tham chiếu: `PAY-REF-99281` (`JetBrains Mono 13px #655E57`).
  - **Khung Hình Ảnh Mã QR (`200x200px`, `Bg #FFFFFF`, `Border 2px solid #D8CBB8`, `Radius 12px`, `Padding 12px`, `Margin Vertical 16px`):** Render mã QR động từ payload `{order_code, payment_reference, total_amount}`.
  - Số tiền thanh toán: **`643.000 VNĐ`** (`26px Bold #294638 tabular-nums`).
  - Dòng phân rã dưới số tiền (`12px Regular #655E57`): *"(Gồm 600.000đ Tiền hàng + 43.000đ Phí bảo vệ người mua)"*.
- **4. Academic Defense Testing Panel – Khung Điều Khiển Mô Phỏng Đồ Án (`Margin Horizontal 16px`, `Bg #E7DAC6`, `Border 1.5px dashed #B8A892`, `Radius 12px`, `Padding 16px`):**
  - Header: Icon `Flask 18px #302D2A` + Tiêu đề `13px SemiBold #302D2A`: *"Bảng điều khiển mô phỏng thanh toán (Phục vụ kiểm thử & bảo vệ đồ án)"*.
  - **Nút 1 (`Primary Button`, Cao `48px`, Full-width, Bg `#236343`, Chữ `#FAF5EC`):** **`[✅ Mô phỏng Thanh toán Thành công (Ghi nhận ESCROW HOLD)]`** $\rightarrow$ Khi bấm, bật `Loading State` khóa nút ngay lập tức (chống bấm đúp 2 lần – `BR-FN-03`), gọi `POST /payments/:id/simulate-success` và chuyển sang `M-PM-02`.
  - **Nút 2 (`Margin Top 10px`, `Destructive Outlined Button`, Cao `44px`, Full-width, Bg `#FAF5EC`, Viền `#A62B2B`, Chữ `#A62B2B`):** **`[❌ Mô phỏng Thanh toán Thất bại (Simulate Failure)]`** $\rightarrow$ Gọi `POST /payments/:id/simulate-failure`, hiện cảnh báo thanh toán lỗi và cho phép bấm `[Tạo lại mã QR mới]`.

#### B. `M-PM-02`: Payment Result & Escrow Hold Receipt (`/payments/:id/receipt`)
- **Cấu trúc Phiếu Biên Lai Giữ Tiền Trung Gian (`Margin 16px`, `Bg #FAF5EC`, `Border 1.5px solid #1C5858`, `Radius 16px`, `Padding 24px`):**
  - Biểu tượng trung tâm: `ShieldCheck Fill 64px #1C5858`.
  - Huy hiệu trạng thái lớn (`Bg #DDF0F0`, chữ `13px Bold #1C5858`, `Radius 9999px`, `Padding 6px 16px`): **`🛡️ ĐÃ THANH TOÁN – TIỀN ĐANG ĐƯỢC GIỮ BẢO VỆ (ESCROW HELD)`**.
  - Số tiền đang giữ trong sổ cái Escrow: **`643.000 VNĐ`** (`28px Bold #302D2A tabular-nums`).
  - Bảng thông tin 4 dòng (`JetBrains Mono` & `Be Vietnam Pro`): Mã bút toán Escrow (`ETX-2026-101`), Mã đơn hàng (`#ORD-2026-0891`), Thời gian ghi sổ (`13/11/2026 15:40:12`), Trạng thái đơn (`PAID – Chờ người bán chuẩn bị hàng`).
  - Cụm 2 nút dưới cùng: **`[📦 Theo dõi Đơn hàng (M-OR-03)]`** (`Primary #294638`) + **`[Về Trang chủ (M-HM-01)]`** (`Secondary`).

---

## Chương 3. Đặc Tả High-Fidelity Cụm Theo Dõi Đơn Mua, Hủy Đơn 3 Cấp, Xác Nhận Nhận Hàng & Đánh Giá (`M-OR-02` – `M-OR-05` & `M-RV-01`)

### 3.1. Screen `M-OR-02`: My Purchase History – 7 Status Tabs (`/profile/orders` – `BF-07`, `NAV-DEC-02`)
- **Top App Bar (`56px`):** `[<-]` + Tiêu đề `Fraunces 18px SemiBold #302D2A` (*"Đơn mua của tôi"*).
- **Search Order Bar:** Tìm theo mã đơn `#ORD-...` hoặc tên sản phẩm.
- **Scrollable 7-Status Tab Bar (`CMP-NAV-01`):**
  1. `Chờ thanh toán (PENDING_PAYMENT)`
  2. `Đang chuẩn bị (PAID / PREPARING)`
  3. `Đang giao (SHIPPED)`
  4. `Đã giao chờ xác nhận (DELIVERED)` *(Gắn chấm đỏ nhắc người mua xác nhận / kiểm tra hàng)*
  5. `Hoàn tất (COMPLETED)`
  6. `Đã hủy / Hoàn tiền (CANCELLED / REFUNDED)`
  7. `Đang khiếu nại (DISPUTED)`.
- **Order Summary Card (`Bg #FAF5EC`, `Border 1px #D8CBB8`, `Radius 12px`, `Padding 16px`):** Hiển thị Tên Tiệm, Huy hiệu `order_status` + Huy hiệu `escrow_status` (`🛡️ Escrow: Đang giữ`), ảnh & tên sản phẩm snapshot, tổng thanh toán `total_amount` và nút hành động ngữ cảnh ở góc phải chân thẻ.

---

### 3.2. Screen `M-OR-03`: Buyer Order Detail, Snapshot & Tracking (`/profile/orders/:id` – `BF-07`, `BF-08`, `OF-04..07`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-OR-03` – Buyer Order Detail, Snapshot & Shipment Timeline (`/profile/orders/:id`) |
| **Purpose** | Hiển thị toàn diện 4 trạng thái độc lập của đơn hàng (`ADR-03`), tiến trình vận chuyển kèm mã vận đơn, bản chụp sản phẩm lúc mua (`BR-OR-02`), bảng kê phí bảo vệ và cung cấp đúng các nút hành động theo từng cấp trạng thái (`DEC-03`, `DEC-06`, `DEC-07`). |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `TopAppBar (Height 56px)`: `[<-]` + Mã đơn `#ORD-2026-0891` (`JetBrains Mono 15px SemiBold`) + `[💬 Chat với Tiệm -> M-CM-02]`.<br>2. `Expanded SingleChildScrollView (Padding 16px, Gap 16px, Bottom Padding 96px)`:<br>   - **Block 1 – `TransactionFourStateHeaderCard (CMP-ORD-01 – Bg #FAF5EC, Border 1.5px #294638, Radius 12px, Padding 16px)`:**<br>     - Tầng 1: Tiêu đề trạng thái đơn (`order_status`) + Đồng hồ đếm ngược tự động hoàn tất 24h (`⏰ Tự động hoàn tất & giải ngân sau: 23:15:40` dựa trên cột `auto_complete_at` khi đơn ở `DELIVERED` – `BR-OR-05`).<br>     - Tầng 2 (Dải 3 Badge độc lập):<br>       - `Escrow Badge`: `[🛡️ Escrow: ĐANG GIỮ BẢO VỆ (HELD)]` (`#DDF0F0`/`#1C5858`) \| `[✅ ĐÃ GIẢI NGÂN]` \| `[↩️ ĐÃ HOÀN TIỀN 100%]`.<br>       - `Payment Badge`: `[💳 Đã thanh toán QR]`.<br>       - `Dispute Badge`: `[⚖️ Không có tranh chấp]` (hoặc `[🔒 Đang khiếu nại – Đã khóa giải ngân]` màu `#F4E4F0`/`#6A2C5A` nếu `dispute_status != NONE`).<br>   - **Block 2 – `PendingCancelRequestNoticeBanner (Chỉ hiển thị khi đơn đang ở PREPARING và cancellation_requested == true – DEC-06 & UX-CHECK-02)`:**<br>     - Khung nền `#FDF1E1`, viền `1px #E8C28E`, padding `12px`: *"⏳ Bạn đã gửi yêu cầu xin hủy đơn hàng này. Đang chờ Người bán xác nhận."* kèm nút nhỏ bên phải: **`[Rút lại yêu cầu hủy]`** (cho phép Buyer đổi ý tiếp tục nhận hàng trước khi Seller xử lý).<br>   - **Block 3 – `ShipmentVerticalTimelineCard (CMP-ORD-03 – Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 16px)`:**<br>     - Hiển thị Đơn vị vận chuyển (`carrier_name: GHN`) + Mã vận đơn (`tracking_code: GHN8829104` kèm nút `[📋 Sao chép]`) và các mốc thời gian (`delivered_at`, `shipped_at`, `prepared_at`, `paid_at`).<br>   - **Block 4 – `FrozenOrderSnapshotCard (Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 16px – BR-OR-02)`:**<br>     - Nhãn bảo chứng: *"📸 Bản chụp thông tin sản phẩm tại thời điểm đặt mua (Snapshot bất biến)"*.<br>     - Hiển thị `product_name_snapshot`, `unit_price_snapshot`, `condition_snapshot`, `defect_snapshot` và `image_url_snapshot`.<br>   - **Block 5 – `BuyerProtectionFeeBreakdownSlip (CMP-ORD-02)`.**<br>3. `StickyDynamicOrderActionBar (Height 76px + Safe Area, Bg #FFFDF9, Border Top 1px #D8CBB8, Elevation 2)`. |
| **Ma Trận Nút Hành Động Dưới Đáy Theo Đúng Trạng Thái (`DEC-03`, `DEC-06`, `DEC-07`, `BR-OR-04`)** | 1. **Khi `order_status == PENDING_PAYMENT`:**<br>   - Nút Trái (`Destructive Outlined`): **`[Hủy đơn]`** ($\rightarrow$ Mở `M-OR-04`).<br>   - Nút Phải (`Primary #294638`): **`[💳 Thanh toán QR ngay (Còn XX:XX)]`** ($\rightarrow$ Mở `M-PM-01`).<br>2. **Khi `order_status == PAID` *(Seller chưa bấm `PREPARING`)*:**<br>   - Nút Full-width (`Destructive Outlined #A62B2B`): **`[✕ Hủy đơn hàng & Nhận hoàn tiền 100% (643.000đ)]`** ($\rightarrow$ Mở `M-OR-04` hủy trực tiếp, hoàn trả đủ 100% `total_amount` theo `DEC-06`, `DEC-07`).<br>3. **Khi `order_status == PREPARING` *(Seller đang đóng gói)*:**<br>   - Nếu `cancellation_requested == false`: Nút Full-width (`Secondary Outlined`): **`[📩 Gửi yêu cầu xin hủy đơn (Chờ Tiệm duyệt)]`** ($\rightarrow$ Mở `M-OR-04` – `DEC-06`).<br>   - Nếu `cancellation_requested == true`: Nút **`[↩️ Rút lại yêu cầu xin hủy đơn]`** (`UX-CHECK-02`).<br>4. **Khi `order_status == SHIPPED` *(Đang giao hàng – Cấm hủy trực tiếp theo `BR-OR-04`, mở quyền Khiếu nại theo `DEC-03`)*:**<br>   - Ẩn hoàn toàn nút Hủy đơn.<br>   - Hiển thị nút (`Destructive Outlined #A62B2B`): **`[⚠️ Gửi khiếu nại / Báo chưa nhận được hàng]`** ($\rightarrow$ Mở `M-DP-01`).<br>5. **Khi `order_status == DELIVERED` & `dispute_status == NONE`:**<br>   - Nút Trái (`Destructive Outlined #A62B2B`, rộng 42%): **`[⚠️ Khiếu nại / Hoàn tiền]`** ($\rightarrow$ Mở `M-DP-01` khóa giải ngân ngay lập tức).<br>   - Nút Phải (`Primary Button #294638`, rộng 54%): **`[✅ Đã nhận được hàng]`** ($\rightarrow$ Mở Dialog xác nhận giải ngân `M-OR-05`).<br>6. **Khi `order_status == COMPLETED`:**<br>   - Nếu chưa đánh giá (`has_reviewed == false`): Nút `Primary Button (#294638)`: **`[⭐ Đánh giá Người bán (1–5 sao)]`** ($\rightarrow$ Mở `M-RV-01` – `BF-09`).<br>   - Nếu đã đánh giá: Nhãn `[✓ Bạn đã đánh giá đơn hàng này]`. |

---

### 3.3. Modals `M-OR-04` (Cancel / Request Cancel), `M-OR-05` (Confirm Delivery Dialog) & `M-RV-01` (Rate Seller)

1. **`M-OR-04` – 3-Tier Order Cancellation Bottom Sheet (`DEC-06`, `DEC-07`):**
   - Hiển thị tiêu đề động theo trạng thái đơn:
     - Ở `PAID`: *"Hủy đơn hàng & Nhận hoàn tiền 100%"* + Hộp thông báo xanh `#E4EFF8` / `#28557A`: *"Bạn sẽ được hoàn trả trọn vẹn 100% Tổng thanh toán = 643.000 VNĐ (bao gồm cả 600.000đ tiền hàng và 43.000đ Phí bảo vệ người mua) từ sổ cái Escrow (`DEC-07`)."*
     - Ở `PREPARING`: *"Gửi yêu cầu xin hủy đơn hàng"* + Hộp thông báo vàng `#FDF1E1` / `#945814`: *"Vì người bán đã bắt đầu đóng gói chuẩn bị hàng, yêu cầu hủy của bạn sẽ được gửi tới người bán để xác nhận. Nếu người bán đồng ý, bạn vẫn được hoàn trả đủ 100% số tiền 643.000 VNĐ (`DEC-06`)."*
   - Danh sách Radio chọn lý do hủy + Nút xác nhận.
2. **`M-OR-05` – Confirm Delivery & Release Escrow Alert Dialog (`OF-06`, `BR-FN-04`):**
   - Tiêu đề (`Fraunces 18px Bold`): *"Xác nhận Đã nhận hàng & Giải ngân?"*
   - Nội dung: *"Bạn xác nhận đã nhận kiện hàng và kiểm tra món đồ đúng với mô tả trong Phiếu kiểm định? Sau khi bấm đồng ý, hệ thống sẽ giải ngân 100% tiền hàng (`600.000 VNĐ`) cho Người bán và đóng quyền mở khiếu nại cho đơn hàng này."*
   - 2 Nút: `[Kiểm tra lại]` + **`[✅ Đồng ý Xác nhận & Giải ngân]`**.
3. **`M-RV-01` – Rate & Review Seller Screen / Modal (`/profile/orders/:id/review` – `BF-09`, `BR-RV-01`):**
   - Hiển thị thông tin Tiệm bán & ảnh snapshot món đồ đã mua.
   - Bộ chọn **5 Ngôi sao lớn (`CMP-COM-03C`, `36x36px #C79B4B`)** kèm nhãn cảm xúc tương ứng (*5 sao: Tuyệt vời – Đúng mô tả 100%*, *4 sao: Hài lòng*, *3 sao: Tạm ổn*, *2 sao: Kém*, *1 sao: Rất tệ*).
   - Ô nhập nhận xét (`Multiline TextArea`, 10–1000 ký tự) + Nút Primary **`[Gửi đánh giá xác thực]`** (`POST /reviews`).

---

## Chương 4. Đặc Tả High-Fidelity Cụm Khiếu Nại & Đóng Băng Escrow (`M-DP-01`, `M-DP-02`, `M-DP-03` – `BF-10`, `OF-08`, `DEC-03`, `DEC-07`)

### 4.1. Screen `M-DP-01`: Submit Complaint / Dispute & Upload Evidence (`/profile/orders/:id/dispute`)
- **Top App Bar (`56px`):** `[<-]` + Tiêu đề `Fraunces 18px SemiBold #302D2A` (*"Gửi khiếu nại & Bảo vệ Escrow"*).
- **Escrow Freeze Assurance Banner (`Bg #F4E4F0`, `Border 1px #6A2C5A`, `Radius 8px`, `Padding 12px`, `Margin 16px`):**
  - Icon `LockKey Fill 20px #6A2C5A` + Chữ `13px SemiBold #6A2C5A`: *"🔒 Ngay khi bạn gửi khiếu nại này, hệ thống sẽ KHÓA CỨNG bộ đếm tự động hoàn tất 24h và đóng băng toàn bộ 643.000 VNĐ trong sổ cái Escrow cho đến khi Quản trị viên phân xử xong (`BR-DP-02`)."*
- **Dispute Submission Form Card (`Bg #FAF5EC`, `Radius 12px`, `Padding 16px`, `Gap 16px`):**
  1. **Chọn lý do khiếu nại (`reason` * – Hiển thị thông minh theo trạng thái đơn `DEC-03`):**
     - Nếu đơn đang `SHIPPED`: `(◉) Quá lâu chưa nhận được hàng / Mã vận đơn không hợp lệ` \| `( ) Người bán không gửi hàng`.
     - Nếu đơn đang `DELIVERED`: `(◉) Sản phẩm bị rách / hư hỏng ngoài mô tả trong Phiếu kiểm định` \| `( ) Sản phẩm sai khác hoàn toàn hình ảnh / kích cỡ` \| `( ) Nghi ngờ hàng giả / sai thương hiệu cam kết` \| `( ) Chưa nhận được kiện hàng dù báo đã giao`.
  2. **Mô tả chi tiết tình trạng thực tế (`description` * – `Multiline TextArea`, tối thiểu 20 ký tự).**
  3. **Tải ảnh bằng chứng thực tế (`dispute_evidence` * – `CMP-FRM-02 Image Uploader Grid`, bắt buộc từ `1..5` ảnh, $\le 5\text{MB}$):** Gợi ý chụp rõ vết rách, tem mác và bao bì kiện hàng.
- **Sticky Bottom CTA:** Nút `Primary Button (Height 48px, Bg #6A2C5A, Text #FAF5EC)`: **`[🔒 Gửi Khiếu Nại & Đóng Băng Tiền Escrow]`** ($\rightarrow$ Gọi `POST /disputes` và chuyển sang `M-DP-03`).

---

### 4.2. Screen `M-DP-02` (My Disputes List) & `M-DP-03` (Dispute Case Detail, Counter-Evidence & Admin Verdict Room)
- **`M-DP-02` (`/profile/disputes`):** Chia 3 tab (`Đang xử lý - OPEN`, `Cần bổ sung bằng chứng - NEED_MORE_INFO`, `Đã có phán quyết - RESOLVED`).
- **`M-DP-03` (`/profile/disputes/:id`):**
  1. **Header Trạng thái Khiếu nại & Tiền đóng băng (`Bg #F4E4F0`, `Border 1.5px #6A2C5A`, `Radius 12px`, `Padding 16px`):** Hiển thị mã hồ sơ `#DSP-2026-042`, trạng thái `OPEN` / `NEED_MORE_INFO` / `RESOLVED` và số tiền đang được đóng băng bảo vệ (`643.000 VNĐ`).
  2. **Hộp Yêu cầu Bổ sung Bằng chứng từ Support Staff / Admin (Chỉ bật khi `status == NEED_MORE_INFO`):** Khung vàng `#FDF1E1` hiển thị lời nhắn của nhân sự hỗ trợ (*"Vui lòng chụp rõ thêm ảnh toàn bộ mặt sau áo và phiếu dán trên hộp hàng"*) kèm nút **`[📷 Tải bổ sung ảnh bằng chứng]`**.
  3. **Luồng Hồ sơ Đối chứng 2 Bên (`Evidence Timeline Cards`):**
     - *Khối Bằng chứng của Người mua (`Buyer Evidence Card`):* Lý do, mô tả và lưới ảnh bằng chứng (chạm vào mở `M-PR-02` phóng to).
     - *Khối Giải trình & Bằng chứng đối chứng của Người bán (`Seller Counter-Evidence Card` – `SF-11`):* Lời giải trình của tiệm và ảnh chụp lúc đóng gói. *(Nếu người đang xem là Seller và tranh chấp đang mở, hiển thị nút **`[+ Gửi giải trình & Ảnh đối chứng của Tiệm]`**)*.
  4. **Khối Phán Quyết Tài Chính Cuối Cùng Của Administrator (Hiển thị nổi bật khi `status == RESOLVED` – `OF-09`, `DEC-07`):**
     - **Nếu Admin xử `APPROVE_BUYER_REFUND`:** Khung xanh `#E4EFF8` / `#28557A`: *"⚖️ Phán quyết của Admin: CHẤP NHẬN KHIẾU NẠI CỦA NGƯỜI MUA. Đã hoàn trả đủ 100% Tổng thanh toán = 643.000 VNĐ (gồm 600.000đ tiền hàng + 43.000đ Phí bảo vệ người mua) về cho Người mua (`DEC-07`)."*
     - **Nếu Admin xử `PARTIAL_REFUND` (`BR-FN-06`):** Hiển thị rõ số tiền hoàn một phần cho Buyer (`150.000đ`) và số tiền giải ngân phần còn lại cho Seller (`450.000đ`).
     - **Nếu Admin xử `RELEASE_TO_SELLER` / `REJECT_DISPUTE`:** Hiển thị rõ lý do bác bỏ khiếu nại và xác nhận đã giải ngân `100% item_subtotal (600.000đ)` cho Người bán.