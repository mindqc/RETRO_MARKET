# P7-08: SHOPPING CART, CHECKOUT (DEC-04) & MOCK QR ESCROW PAYMENT SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P708-CART-CHECKOUT-PAYMENT`
- **Version:** `1.1.0`
- **Status:** `DONE / PO APPROVED`
- **Phase:** `Phase 07 – Task P7-08`
- **Dependencies:** `P7-01, P7-02, P7-03, P7-04, P7-06 Completed`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
Hiện thực hóa trải nghiệm giỏ hàng gom nhóm theo từng Tiệm (`BR-OR-01`), màn hình xác nhận đặt hàng và chiết tính Phí bảo vệ người mua bắt buộc theo quyết định `DEC-04`, và cổng thanh toán mô phỏng mã QR có cơ chế giữ tiền trung gian Escrow (`ESCROW_HELD`). Gói này bao gồm đúng **5 màn hình Mobile**:
- `M-CR-01`: Giỏ Hàng Gom Nhóm Theo Tiệm (`Grouped Shopping Cart`)
- `M-OR-01`: Xác Nhận Đặt Hàng & Bảng Phí Minh Bạch (`Checkout Preview & Place Order`)
- `M-PM-01`: Quét Mã QR Thanh Toán Mô Phỏng (`Mock QR Payment Screen`)
- `M-PM-02`: Thanh Toán Thành Công & Xác Nhận Giữ Tiền Escrow (`Payment Success & Escrow Hold`)
- `M-PM-03`: Thanh Toán Thất Bại / Hết Hạn Mã QR (`Payment Failure & Retry`)

---

## 2. Screen Specifications & UX Flows (`Đặc Tả Chi Tiết 5 Màn Hình`)

### 2.1. `M-CR-01: Grouped Shopping Cart Screen`
- **Gom Nhóm Theo Tiệm (`seller_groups[]` – `BR-OR-01`):**
  - Từng tiệm được hiển thị thành một khối riêng biệt gồm Header tiệm (Checkbox chọn tất cả đồ của tiệm, Tên tiệm, `shop_slug`).
  - Danh sách các món đồ trong giỏ của tiệm đó:
    - Ảnh nhỏ, Tiêu đề, Huy hiệu độ mới, Đơn giá VNĐ.
    - Bộ điều chỉnh số lượng `[-] [ 1 ] [+]` (chỉ cho phép tăng nếu `available_quantity` còn đủ, nếu là đồ độc bản thì cố định = 1).
    - Nút xóa sản phẩm khỏi giỏ (`DELETE /api/v1/cart/items/{id}`).
- **Thanh Tổng Kết Giỏ Hàng Dưới Cùng:**
  - Checkbox chọn tất cả đồ trong toàn giỏ.
  - Tạm tính tiền hàng: Hiển thị tổng số tiền của các món đang được chọn (`selected_subtotal`).
  - Nút **`[Mua Hàng (X món)]`**: Điều hướng sang `M-OR-01` với `source: 'CART'`.

### 2.2. `M-OR-01: Checkout Preview & Place Order Screen` (`DEC-04`)
- **Khối Địa Chỉ Nhận Hàng:**
  - Hiển thị địa chỉ mặc định của người mua (`recipient_name`, `recipient_phone`, `full_address`).
  - Nút `[Thay đổi]` mở danh sách sổ địa chỉ `M-PF-03` để chọn địa chỉ khác.
- **Khối Danh Sách Món Hàng Cần Đặt:**
  - Nhóm theo người bán, hiển thị snapshot hình ảnh, tình trạng và giá tiền.
- **Bảng Kê Chi Phí Minh Bạch (`PriceBreakdownCard` theo `DEC-04`):**
  - `Tiền hàng (Item Subtotal)`: Tổng giá trị hàng hóa.
  - `Phí vận chuyển (Shipping Fee)`: `0đ` (Mặc định miễn phí vận chuyển toàn sàn).
  - `Phí bảo vệ Người mua (Buyer Protection Fee)`: Tính theo công thức bắt buộc:
    $$\text{Buyer Protection Fee} = (\text{Tiền hàng} \times 6\%) + 7.000\text{đ}$$
  - `Tổng thanh toán (Total Amount)`: $\text{Tiền hàng} + \text{Phí bảo vệ Người mua}$.
  - Hộp thông tin cam kết: *"Khoản tiền này sẽ được izithrift giữ an toàn trong quỹ Escrow và chỉ giải ngân cho Người bán khi bạn xác nhận đã nhận hàng đúng mô tả."*
- **Thanh Đặt Hàng:**
  - Nút lớn **`[Đặt hàng & Thanh toán QR]`**:
    - Gọi `POST /api/v1/orders`.
    - Sau khi tạo đơn và bản ghi `Payment` thành công, lập tức chuyển sang `M-PM-01`.

### 2.3. `M-PM-01: Mock QR Payment Screen`
- **Mã QR Thanh Toán:**
  - Hiển thị mã QR ngân hàng mô phỏng (chuẩn VietQR template) kèm số tiền chính xác và nội dung chuyển khoản: `IZITHRIFT {order_code}`.
- **Đồng Hồ Đếm Ngược Hạn Thanh Toán (`BR-AU-01`):**
  - Đếm ngược chính xác thời gian còn lại đến `payment_expires_at` (30 phút trong production hoặc 2 phút trong demo mode).
  - Sử dụng `CountdownTimerWidget` đồng bộ thời gian máy chủ.
- **2 Nút Giả Lập Dành Cho Đồ Án / Kiểm Thử (`Demo Mode Simulation`):**
  - Nút xanh lá: **`[✅ Mô phỏng Thanh toán Thành công]`** $\rightarrow$ Gọi `POST /api/v1/payments/{id}/simulate-success`. Chuyển ngay sang `M-PM-02`.
  - Nút xám: **`[❌ Mô phỏng Thanh toán Thất bại]`** $\rightarrow$ Gọi `POST /api/v1/payments/{id}/simulate-failure`. Chuyển ngay sang `M-PM-03`.

### 2.4. `M-PM-02: Payment Success Screen`
- Biểu tượng tích xanh vintage, thông báo: *"Thanh toán thành công! Tiền đã được giữ an toàn trong Escrow"*.
- Hiển thị Mã đơn hàng, Số tiền đã thanh toán, Thời điểm thanh toán.
- Trạng thái 4 máy trạng thái được giải thích rõ cho người dùng:
  - `order_status`: **PAID** (Đã thanh toán)
  - `escrow_status`: **HELD** (Đang giữ tiền ký quỹ)
- 2 Nút hành động: `[Xem chi tiết đơn mua]` (vào `M-OR-03`) và `[Tiếp tục mua sắm]` (về `/home`).

### 2.5. `M-PM-03: Payment Failure / Expired Screen`
- Biểu tượng cảnh báo màu đỏ Burgundy: *"Thanh toán chưa hoàn tất hoặc phiên thanh toán đã hết hạn"*.
- Nút `[Thử thanh toán lại / Tạo mã mới]` (gọi lại API payment) và `[Về trang chủ]`.

---

## 3. Architecture & State Management (MVVM Pattern)
- **Models:** `CartModel`, `CartItemModel`, `CheckoutPreviewModel`, `OrderCreatedModel`, `PaymentModel`.
- **Repositories:** `CartRepository`, `CheckoutRepository`, `PaymentRepository`.
- **ViewModels (`ChangeNotifier`):**
  - `CartViewModel`: Quản lý giỏ hàng, chọn/bỏ chọn món đồ, thay đổi số lượng, xóa món.
  - `CheckoutViewModel`: Gọi `previewCheckout`, validate địa chỉ, gọi `placeOrder`.
  - `PaymentViewModel`: Quản lý đếm ngược thanh toán, gọi các endpoint simulate.

---

## 4. API Endpoints Utilized
- `GET /api/v1/cart`
- `POST /api/v1/cart/items`
- `PUT /api/v1/cart/items/{id}`
- `DELETE /api/v1/cart/items/{id}`
- `POST /api/v1/checkout/preview`
- `POST /api/v1/orders`
- `GET /api/v1/payments/{id}`
- `POST /api/v1/payments/{id}/simulate-success`
- `POST /api/v1/payments/{id}/simulate-failure`

---

## 5. Acceptance Criteria (`Tiêu Chí Nghiệm Thu P7-08`)
- [x] **AC-P708-01:** Giỏ hàng gom nhóm chuẩn xác theo từng Seller (`seller_groups[]`), hỗ trợ chọn/bỏ chọn linh hoạt theo từng món hoặc theo cả tiệm (`BR-OR-01`).
- [x] **AC-P708-02:** Màn hình xác nhận đặt hàng tính đúng công thức Phí bảo vệ `DEC-04` ($6\% + 7.000đ$, shipping $0đ$) minh bạch qua `PriceBreakdownCard`.
- [x] **AC-P708-03:** Màn hình thanh toán hiển thị mã VietQR và đếm ngược hạn thanh toán chính xác theo thời gian máy chủ (`ServerCountdownTimer`).
- [x] **AC-P708-04:** Nút giả lập Demo Mode chuyển đổi trạng thái đơn sang `order_status: PAID` và tiền ký quỹ sang `escrow_status: HELD`.
- [x] **AC-P708-05:** Bộ kiểm thử `cart_and_checkout_test.dart` (10/10 tests PASS) và toàn bộ kiểm thử Mobile (86/86 PASS) đạt **100% PASS** với 0 cảnh báo `flutter analyze`.
