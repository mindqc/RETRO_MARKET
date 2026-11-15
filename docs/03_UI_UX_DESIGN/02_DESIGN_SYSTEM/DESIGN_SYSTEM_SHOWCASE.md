# 07. DESIGN SYSTEM VISUAL SHOWCASE & COMPONENT PREVIEW – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P302-SHOWCASE`
- **Version:** `1.0.0`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`

---

## 1. Minh Họa Trực Quan Sự Khác Biệt Giữa 2 Biến Thể Thẻ Sản Phẩm (`CMP-COM-01`: `Fixed-Price` vs `Auction Ticket`)

```text
   [VARIANT 1: FIXED-PRICE PRODUCT CARD]            [VARIANT 2: AUCTION TICKET CARD (UI-DEC-01)]
  (Khung bo góc 12px chuẩn, nền #FAF5EC)           (Có dải đếm ngược #873A43 & Rãnh vé nét đứt)
+-----------------------------------------+      +-----------------------------------------+
| [Good (#E3EFF3)]                   [♡]  |      | [🔴 LIVE (#873A43)]                [♡]  |
|                                         |      |                                         |
|           [ ẢNH SẢN PHẨM 4:5 ]          |      |           [ ẢNH SẢN PHẨM 4:5 ]          |
|        (Giữ nguyên màu thật 100%)       |      |        (Giữ nguyên màu thật 100%)       |
|                                         |      | +-------------------------------------+ |
|                                         |      | | ⏳ 04:18:22       | 🔥 14 lượt trả  | |
+-----------------------------------------+      +-----------------------------------------+
| Áo Khoác Dạ Tweed Cổ Điển Mùa Đông      |      | Đồng Hồ Cơ Seiko 5 Mặt Vuông 1982       |
| (Be Vietnam Pro 15px SemiBold #302D2A)  |      | (Be Vietnam Pro 15px SemiBold #302D2A)  |
|                                         |      o - - - - - - - - - - - - - - - - - - - - o <-- Khuyết vé & Nét đứt
| Giá bán:                                |      | Giá cao nhất hiện tại:                  |
| 450.000 VNĐ (#294638 Bold Tabular)      |      | 850.000 VNĐ (#873A43 Bold Tabular)      |
| --------------------------------------- |      | --------------------------------------- |
| 🏪 Tiệm Nhà Gấu                 ★ 4.9   |      | 🔨 Bước giá: +50.000đ      [Đặt giá ->] |
+-----------------------------------------+      +-----------------------------------------+
```

---

## 2. Minh Họa Phiếu Kiểm Định Tình Trạng Đồ Cũ (`CMP-COM-02` – `Inspection Slip Motif`)

```text
+-----------------------------------------------------------------------------------+
| 📋 PHIẾU KIỂM ĐỊNH TÌNH TRẠNG ĐỒ SECONDHAND        [🛡️ ĐÃ DUYỆT ẢNH (#236343)]    |
| (Nền Warm Sand #E7DAC6 | Viền 1px solid #B8A892 | Bo góc 12px)                    |
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - |
| • Tình trạng (Condition): [ Good - Độ mới ~88% ]   | • Thương hiệu: Schott NYC    |
| • Danh mục: Áo khoác da                            | • Số lượng: 01 chiếc duy nhất|
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - |
| 🔍 MÔ TẢ KHUYẾT ĐIỂM / VẾT XƯỚC (defect_info - Bắt buộc minh bạch theo BR-PR-03): |
| "Phần cổ tay áo bên phải có vết sờn nhẹ tự nhiên khoảng 1cm (xem rõ tại Ảnh số 4).|
|  Khóa kéo đồng hoạt động trơn tru, lớp lót lụa bên trong nguyên vẹn không rách."  |
|                                                                                   |
|                        [ 🔍 Chạm để phóng to kiểm tra ảnh chi tiết lỗi (M-PR-02) ]|
+-----------------------------------------------------------------------------------+
```

---

## 3. Minh Họa Thẻ Tổng Hợp 4 Trạng Thái & Biên Lai Phí Bảo Vệ Escrow (`CMP-ORD-01` & `CMP-ORD-02`)

```text
+-----------------------------------------------------------------------------------+
| 📦 TRẠNG THÁI ĐƠN HÀNG: ĐÃ GIAO HÀNG TỚI NƠI (DELIVERED)                          |
| ⏰ Tự động hoàn tất & giải ngân sau: 23 : 42 : 10 (Mốc đóng băng: 14/11 10:30)    |
| --------------------------------------------------------------------------------- |
| [🛡️ Escrow: ĐANG GIỮ BẢO VỆ (HELD #1C5858)] [💳 Thanh toán: ĐÃ TRẢ (#236343)]     |
| (Nếu có khiếu nại mở -> Hiện thêm: [🔒 Khiếu nại: ĐANG ĐÓNG BĂNG TIỀN (#6A2C5A)]) |
+-----------------------------------------------------------------------------------+
| 🧾 BIÊN LAI CHI PHÍ & BẢO VỆ ESCROW (DEC-04 & DEC-07)                             |
| • Tổng tiền hàng (item_subtotal - Seller nhận 100% khi hoàn tất):     600.000 VNĐ |
| • Phí vận chuyển trên ứng dụng (shipping_fee):                              0 VNĐ |
| • 🛡️ Phí bảo vệ người mua (Buyer Protection Fee: 6% + 7.000đ):         43.000 VNĐ |
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - |
| 💰 TỔNG THANH TOÁN ĐANG GIỮ TRONG ESCROW (total_amount):              643.000 VNĐ |
|    (Cam kết hoàn trả đủ 100% = 643.000đ nếu hủy hợp lệ hoặc thắng khiếu nại)      |
+-----------------------------------------------------------------------------------+
```