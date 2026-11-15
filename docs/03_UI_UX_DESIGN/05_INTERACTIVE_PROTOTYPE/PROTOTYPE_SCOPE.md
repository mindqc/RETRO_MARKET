# 01. INTERACTIVE PROTOTYPE SCOPE & FLOWS – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P307A-PROTOTYPE-SCOPE`
- **Version:** `1.0.0`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`
- **Compliance Ref:** `UI-DEC-01..04`, `DS-DEC-01..03`

---

## Chương 1. Mục Tiêu Trình Diễn Prototype (`Prototyping Objectives`)

Interactive Prototype (Bản mẫu tương tác) không nhằm mục đích lập trình logic backend, mà được xây dựng trên Figma / Flutter UI Mockup để kiểm chứng **5 Luồng Trải Nghiệm Cốt Lõi (`Core UX Flows`)** trước khi bàn giao cho đội ngũ phát triển. Mục tiêu chính:
1. Xác nhận **ngôn ngữ thị giác (Warm Editorial Archive)** và **hệ thống Token (Màu sắc, Typography, Spacing)** hoạt động hiệu quả trên thiết bị thực tế.
2. Kiểm chứng tính rõ ràng của **Phiếu kiểm định đồ cũ**, **Công thức Phí bảo vệ Escrow** và **Trạng thái Đấu giá theo thời gian thực**.
3. Đảm bảo luồng điều hướng 5 Tab (`NAV-DEC-01`) và sự tách biệt giữa ngữ cảnh Buyer / Seller không gây nhầm lẫn.

---

## Chương 2. Kịch Bản Tương Tác Cốt Lõi Cần Trình Diễn (`5 Key Click-through Paths`)

### Flow 1: Khám Phá, Mua Hàng & Thanh Toán QR (Buyer Core Flow)
- **Điểm bắt đầu:** `M-AU-01` (Splash) $\rightarrow$ `M-AU-02` (Onboarding) $\rightarrow$ Nhấn `[Khám phá ngay (Guest)]` $\rightarrow$ `M-HM-01` (Home).
- **Tương tác:**
  1. Cuộn trang chủ, nhấn vào một `Product Card (Fixed-Price)` $\rightarrow$ Mở `M-PR-01`.
  2. Tại `M-PR-01`: Đọc `defect_info`, nhấn `[🔍 Phóng to soi lỗi]` $\rightarrow$ Mở `M-PR-02` (Zoom) $\rightarrow$ Đóng lại.
  3. Nhấn `[Mua ngay]` $\rightarrow$ Bật `Auth Guard` chuyển sang `M-AU-03` (Login) $\rightarrow$ Đăng nhập thành công, tự động quay lại `M-OR-01` (Checkout Preview).
  4. Tại `M-OR-01`: Kiểm tra bảng phí (`item_subtotal` + `buyer_protection_fee`), nhấn `[Đặt hàng & Thanh toán QR]` $\rightarrow$ Mở `M-PM-01`.
  5. Tại `M-PM-01`: Nhấn `[✅ Mô phỏng Thanh toán Thành công]` $\rightarrow$ Chuyển sang `M-PM-02` (Biên lai `ESCROW HELD`) $\rightarrow$ Nhấn `[Theo dõi Đơn hàng]` mở `M-OR-03`.

### Flow 2: Đấu Giá Thời Gian Thực & Anti-Sniping (Auction Flow)
- **Điểm bắt đầu:** `M-HM-01` $\rightarrow$ Chạm Tab 3 mở `M-AC-01` (Auction Hub).
- **Tương tác:**
  1. Nhấn vào một phiên đang `🔴 LIVE` $\rightarrow$ Mở `M-AC-03` (Auction Room).
  2. Tại `M-AC-03`: Quan sát đồng hồ đếm ngược, nhấn `[🔨 Đặt giá thầu ngay]` $\rightarrow$ Vuốt mở `M-AC-04` (Bottom Sheet).
  3. Tại `M-AC-04`: Nhấn chip `[+50k]`, nhấn `[Xác nhận]` $\rightarrow$ Hiện Dialog xác nhận $\rightarrow$ Quay lại `M-AC-03` với huy hiệu `[👑 BẠN ĐANG DẪN ĐẦU]`.
  4. Mô phỏng `Outbid`: Nhận Push Notification $\rightarrow$ Chạm vào mở lại `M-AC-03` thấy huy hiệu `[⚠️ BỊ VƯỢT GIÁ]`.

### Flow 3: Đăng Bán & Duyệt Yêu Cầu Hủy Của Seller (Seller Flow)
- **Điểm bắt đầu:** Chạm Tab 4 mở `M-SL-01` (Kênh Bán).
- **Tương tác:**
  1. Nhấn `[+ Đăng bán sản phẩm mới]` $\rightarrow$ Mở `M-SL-03`.
  2. Tại `M-SL-03`: Chọn ảnh, khai báo `condition` và `defect_info`, gạt công tắc chọn `Đấu giá theo phiên`, điền giá khởi điểm $\rightarrow$ Nhấn `[Gửi kiểm duyệt]` $\rightarrow$ Về `M-SL-02` (Tab `PENDING_REVIEW`).
  3. Quay lại `M-SL-01`, nhấn vào cảnh báo *"01 Khách xin hủy đơn"* $\rightarrow$ Mở `M-SL-06` (Chi tiết đơn bán đang ở `PREPARING`).
  4. Tại `M-SL-06`: Nhấn `[✅ Đồng ý Hủy (Hoàn 100% cho khách)]` $\rightarrow$ Đơn chuyển sang `CANCELLED`.

### Flow 4: Báo Cáo Vi Phạm & Khiếu Nại (Dispute Resolution Flow)
- **Điểm bắt đầu:** Màn hình chi tiết đơn mua `M-OR-03` đang ở trạng thái `DELIVERED`.
- **Tương tác:**
  1. Nhấn `[⚠️ Khiếu nại / Hoàn tiền]` $\rightarrow$ Mở `M-DP-01`.
  2. Tại `M-DP-01`: Chọn lý do *"Sản phẩm bị rách"*, tải ảnh $\rightarrow$ Nhấn `[🔒 Gửi Khiếu Nại & Đóng Băng Escrow]` $\rightarrow$ Mở `M-DP-03` (Case Room).
  3. Mở góc nhìn Admin (`A-DP-02` Split-pane): Cột trái soi ảnh lỗi; cột phải (Admin) chọn `[APPROVE_BUYER_REFUND]` $\rightarrow$ Nhấn xác nhận $\rightarrow$ Tranh chấp chuyển sang `RESOLVED`.

---

## Chương 3. Đặc Tả Hiệu Ứng Vi Mô (`Micro-Interactions & Transitions`)

- **Chuyển trang (`Page Transitions`):**
  - Mặc định: Trượt ngang từ phải sang trái (`Slide Left`) cho điều hướng tiến; Trượt ngược lại cho điều hướng lùi.
  - Bottom Navigation (5 Tabs): Chuyển cảnh làm mờ chéo (`Cross-fade 150ms`).
- **Nút Bấm (`Button States`):**
  - Nhấn (`Tap/Press`): Nút thu nhỏ `scale(0.98)` trong `100ms`, giảm opacity nhẹ, tự động bật `Spinner` khi xử lý API giả lập.
- **Overlays (Modals & Sheets):**
  - Bottom Sheet (`M-DS-03`, `M-AC-04`, `M-OR-04`): Vuốt từ dưới lên (`Slide Up`), nền đen mờ `Opacity 50%`, hỗ trợ vuốt xuống (`Swipe Down`) để đóng.
- **Thông Báo (`Toast/Snackbar`):**
  - Trượt từ trên xuống, nổi trên cùng màn hình trong `3 giây`, màu nền tương ứng ngữ nghĩa (`Success #236343`, `Error #A62B2B`).