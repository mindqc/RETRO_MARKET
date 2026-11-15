# 08A. LOW-FIDELITY MOBILE WIREFRAME SPECIFICATIONS – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P208A-MOBILE-WIREFRAMES`
- **Version:** `2.1.0 (COMPLETE UNTRUNCATED SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR FINAL LOCK`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 02 – System Flow & UX Planning`

---

## Chương 1. Quy Chuẩn Khung Bố Cục & Thành Phần Toàn Cục (`Mobile Layout Shell & Global Rules`)

Toàn bộ các màn hình trên ứng dụng di động **`izithrift`** tuân thủ một bộ khung bố cục vật lý thống nhất để sẵn sàng chuyển sang thiết kế Figma High-Fidelity ở Phase 03:

### 1.1. Khung Lưới & Vùng An Toàn (`Viewport, Grid & Safe Area`)
- **Kích thước tham chiếu chuẩn (`Reference Viewport`):** `390 x 844 px` (Tỷ lệ 19.5:9 phổ biến trên iOS & Android).
- **Hệ thống lưới (`Grid System`):** 4 cột (`4-Column Grid`), lề trái/phải cố định `16px` (`Horizontal Padding = 16px`), khoảng cách giữa 2 cột thẻ sản phẩm `12px` (`Gutter = 12px`).
- **Phân tầng Typography bắt buộc (`ADR-07`):**
  - **Tầng 1 – Brand Logo & Seasonal Display:** `Wichita Vintage` (Chỉ dùng cho chữ `izithrift` và nhãn trang trí đã kiểm chứng đủ glyph).
  - **Tầng 2 – Section & Product Headings:** `Fraunces` (Hỗ trợ đầy đủ 100% dấu tiếng Việt Unicode NFC).
  - **Tầng 3 – Body, Price, Badges & Buttons:** `Be Vietnam Pro` (Đảm bảo độ rõ nét tuyệt đối cho số tiền `VND`, mã đơn và trạng thái).

### 1.2. Khung Điều Hướng Toàn Cục (`Global App Bar & 5-Tab Bottom Navigation – NAV-DEC-01`)

```text
+-----------------------------------------------------------------------+
| [Status Bar: 09:41]                                    [WiFi] [100%]  |
+-----------------------------------------------------------------------+
| 🎄 izithrift   [ 🔍 Tìm áo khoác vintage, đồng hồ... ]  [🛒2] [💬1] [🔔3] | <-- Global Top Utility Bar
+-----------------------------------------------------------------------+
|                                                                       |
|                                                                       |
|                     [ NỘI DUNG CUỘN CHÍNH (SCROLLVIEW) ]              |
|                       (Padding trái/phải: 16px)                       |
|                                                                       |
|                                                                       |
+-----------------------------------------------------------------------+
|  [🎄 Trang chủ]  [🔍 Khám phá]  [🔨 Đấu giá]  [🏷️ Kênh Bán]  [👤 Cá nhân] | <-- 5-Tab Bottom Navigation
+-----------------------------------------------------------------------+
```

---

## Chương 2. Đặc Tả Wireframe Chi Tiết Các Màn Hình Trọng Tâm Trên Mobile

### 2.1. Nhóm Khởi Động, Xác Thực & Guest Welcome Card (`M-AU-02`, `M-AU-03`, `Guest Card`)

#### A. `M-AU-02` (Onboarding) & `M-AU-03` (Login Screen với `redirect` ngữ cảnh)
```text
+-----------------------------------------------------------------------+
| [M-AU-03: ĐĂNG NHẬP]                                        [Đóng X]  |
+-----------------------------------------------------------------------+
|  (Banner nhỏ nếu bị chặn từ hành động cần quyền - DEC-01):            |
|  +-----------------------------------------------------------------+  |
|  | 🔒 Vui lòng đăng nhập để tiếp tục [Đặt giá thầu / Mua hàng]      |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|                         🎄 izithrift 🎄                               |
|              Tiệm Đồ Si Tuyển Chọn & Đấu Giá Theo Phiên               |
|                                                                       |
|  Email đăng nhập *                                                    |
|  +-----------------------------------------------------------------+  |
|  | nguyenminhduc@example.com                                       |  |
|  +-----------------------------------------------------------------+  |
|  Mật khẩu *                                                           |
|  +-----------------------------------------------------------------+  |
|  | ••••••••••••                                            [Hiện]  |  |
|  +-----------------------------------------------------------------+  |
|                                                  [Quên mật khẩu?]     |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  |                   [ ĐĂNG NHẬP VÀO TIỆM ]                        |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|        Chưa có tài khoản? [Đăng ký tài khoản C2C hợp nhất]            |
|        ---------------------------------------------------            |
|             [ Tiếp tục khám phá dưới quyền Khách (Guest) ]            |
+-----------------------------------------------------------------------+
```

#### B. `Guest Welcome Card` Bên Trong Tab 4 (`Kênh Bán`) & Tab 5 (`Cá Nhân`) (`NAV-DEC-03`)
- Khi `Guest` chạm vào Tab 4 hoặc Tab 5, **thanh Bottom Navigation vẫn giữ nguyên bên dưới**, phần thân hiển thị thẻ chào mừng ấm cúng:
```text
+-----------------------------------------------------------------------+
| 🏷️ KÊNH NGƯỜI BÁN (SELLER CENTER)                         [🛒] [🔔]   |
+-----------------------------------------------------------------------+
|  +-----------------------------------------------------------------+  |
|  |                 🧦🎄 MỞ TIỆM ĐỒ SI MIỄN PHÍ 🎄🧦                |  |
|  |                                                                 |  |
|  |   • 1 Tài khoản duy nhất vừa Mua sắm vừa Đăng bán (BR-AC-01)    |  |
|  |   • Miễn phí 100% hoa hồng – Nhận đủ 100% tiền hàng (DEC-04)    |  |
|  |   • Hỗ trợ cả Bán Giá Cố Định & Đấu Giá Theo Phiên              |  |
|  |                                                                 |  |
|  |   +---------------------------------------------------------+   |  |
|  |   |               [ ĐĂNG NHẬP ĐỂ MỞ TIỆM ]                  |   |  |
|  |   +---------------------------------------------------------+   |  |
|  |   +---------------------------------------------------------+   |  |
|  |   |             [ ĐĂNG KÝ TÀI KHOẢN MỚI ]                   |   |  |
|  |   +---------------------------------------------------------+   |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
|  [🎄 Trang chủ]  [🔍 Khám phá]  [🔨 Đấu giá]  [🏷️ Kênh Bán*] [👤 Cá nhân] |
+-----------------------------------------------------------------------+
```

---

### 2.2. `M-HM-01` (Trang Chủ) & `M-DS-02` / `M-DS-03` (Tìm Kiếm & Bộ Lọc)

```text
+-----------------------------------------------------------------------+
| 🎄 izithrift   [ 🔍 Tìm kiếm đồ vintage... ]         [🛒2] [💬1] [🔔3] |
+-----------------------------------------------------------------------+
|  +-----------------------------------------------------------------+  |
|  | 🎄 [CHRISTMAS HERO BANNER]                                      |  |
|  | "Góc Đồ Si Ấm Áp Đêm Giáng Sinh – Săn Kho Báu Cổ Điển"         |  |
|  | [ Khám phá Bộ sưu tập Giáng sinh -> ]                           |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  DANH MỤC: [🧥 Áo khoác] [👖 Quần] [👜 Túi da] [⌚ Đồng hồ] [🕯️ Decor] |
|                                                                       |
|  🔨 ĐẤU GIÁ ĐANG DIỄN RA (LIVE)                     [Xem tất cả ->]   |
|  +---------------------------------+ +-----------------------------+  |
|  | [Ảnh: Đồng hồ Seiko 1980]       | | [Ảnh: Túi Coach Vintage]    |  |
|  | ⏳ Còn: 08:42  | 🔥 12 lượt bid | | ⏳ Còn: 01:50 (Sắp đóng!)   |  |
|  | Giá hiện tại: 850.000đ          | | Giá hiện tại: 1.200.000đ    |  |
|  | [ Đặt giá ngay ]                | | [ Đặt giá ngay ]            |  |
|  +---------------------------------+ +-----------------------------+  |
|                                                                       |
|  ✨ MỚI LÊN KỆ (ĐÃ KIỂM DUYỆT - APPROVED)           [Bộ lọc | Sắp xếp]|
|  +---------------------------------+ +-----------------------------+  |
|  | [Ảnh: Áo len Wool đỏ]      [♡]  | | [Ảnh: Áo khoác da nâu]  [♡] |  |
|  | [✓ Đã duyệt] Tình trạng: Good   | | [✓ Đã duyệt] Like New       |  |
|  | Áo Len Thổ Cẩm Giáng Sinh       | | Áo Khoác Da Bò Thập Niên 90 |  |
|  | 350.000đ                        | | 950.000đ                    |  |
|  | 🏪 Tiệm Nhà Gấu (★ 4.9)         | | 🏪 Retro Corner (★ 4.8)     |  |
|  +---------------------------------+ +-----------------------------+  |
+-----------------------------------------------------------------------+
|  [🎄 Trang chủ*] [🔍 Khám phá]  [🔨 Đấu giá]  [🏷️ Kênh Bán]  [👤 Cá nhân] |
+-----------------------------------------------------------------------+
```

---

### 2.3. `M-PR-01` (Chi Tiết Sản Phẩm Giá Cố Định) & `M-US-03` (Hồ Sơ Công Khai Người Bán)

```text
+-----------------------------------------------------------------------+
| [<- Quay lại]          CHI TIẾT SẢN PHẨM              [🛒2] [♡] [...] |
+-----------------------------------------------------------------------+
|  +-----------------------------------------------------------------+  |
|  |                                                                 |  |
|  |                  [ CAROUSEL ẢNH SẢN PHẨM (1/5) ]                |  |
|  |             (Chạm vào để mở M-PR-02 Phóng to soi lỗi)           |  |
|  |                                                                 |  |
|  +-----------------------------------------------------------------+  |
|  [Nhãn: BÁN GIÁ CỐ ĐỊNH]              [🛡️ MODERATOR REVIEWED]         |
|  Áo Khoác Dạ Tweed Cổ Điển Mùa Đông                                   |
|  Giá bán: 450.000 VNĐ                 (Số lượng còn lại: 1 chiếc)     |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | 📋 HỒ SƠ TÌNH TRẠNG ĐỒ SECONDHAND (MINH BẠCH 100% - BR-PR-03)   |  |
|  | • Tình trạng (Condition): Good (Độ mới ~88%)                    |  |
|  | • Thương hiệu: Vintage Japan  | • Danh mục: Áo khoác nữ         |  |
|  | • Khuyết điểm / Vết xước (Defect Info):                         |  |
|  |   "Cúc áo thứ 2 từ dưới lên hơi xước nhẹ ở viền, lớp lót trong   |  |
|  |    nguyên vẹn không rách (Xem ảnh chụp cận cảnh số 4)."         |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | 🛡️ Bảo vệ Người mua izithrift: Tiền được giữ trong Escrow,      |  |
|  |    hoàn tiền 100% nếu sản phẩm bị rách hoặc sai mô tả.          |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | (Avatar) 🏪 TIỆM ĐỒ SI NHÀ GẤU            [Xem tiệm (M-US-03)]  |  |
|  | ★ 4.9 (42 Đánh giá) | Điểm uy tín: 98/100 | Hoàn tất: 99%       |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
| [💬 Chat] | [♡ Lưu] | [ 🛒 Thêm vào giỏ ] | [ ⚡ MUA NGAY (M-OR-01) ] | <-- Sticky Bottom Action Bar
+-----------------------------------------------------------------------+
```
*(Lưu ý quy tắc `BR-AC-02`: Nếu người đang xem chính là chủ sản phẩm `auth.id == seller_id`, thanh dưới đáy tự động đổi thành: `[ Đây là sản phẩm của bạn – ✏️ Quản lý / Chỉnh sửa bài đăng ]`).*

---

### 2.4. `M-AC-01` (Auction Hub), `M-AC-03` (Phòng Đấu Giá Thời Gian Thực) & `M-AC-04` (Bottom Sheet Đặt Giá)

```text
+-----------------------------------------------------------------------+
| [<-]               PHÒNG ĐẤU GIÁ TRỰC TIẾP #AUC-108        [👁️ Watch] |
+-----------------------------------------------------------------------+
|  +-----------------------------------------------------------------+  |
|  | ⏳ THỜI GIAN CÒN LẠI:  00 : 01 : 45   (Chuẩn giờ Server)        |  |
|  | ⚡ [ĐÃ GIA HẠN ANTI-SNIPING +2 PHÚT - Lần #1 (BR-AU-04)]        |  |
|  +-----------------------------------------------------------------+  |
|  |                  [ CAROUSEL ẢNH ĐỒNG HỒ SEIKO 1982 ]            |  |
|  +-----------------------------------------------------------------+  |
|  Đồng Hồ Cơ Seiko 5 Mặt Vuông Cổ Điển (Số lượng: 01 chiếc duy nhất)  |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | 💰 GIÁ CAO NHẤT HIỆN TẠI:          850.000 VNĐ                  |  |
|  | 👑 Người đang dẫn đầu:             minh*** (Bạn đang dẫn đầu!)  |  |
|  | --------------------------------------------------------------- |  |
|  | • Giá khởi điểm: 500.000đ        | • Bước giá tối thiểu: 50.000đ|  |
|  | • Giá đặt tối thiểu tiếp theo:     900.000 VNĐ                  |  |
|  | • Trạng thái Giá sàn (Reserve):   [✓ ĐÃ ĐẠT GIÁ SÀN KỲ VỌNG]   |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  📜 LỊCH SỬ TRẢ GIÁ (12 lượt)                 [Xem toàn bộ (M-AC-04)] |
|  • 1. minh*** đặt 850.000đ                     (Vừa xong - Dẫn đầu)   |
|  • 2. bao_*** đặt 800.000đ                     (1 phút trước)         |
|  • 3. nam_*** đặt 750.000đ                     (4 phút trước)         |
+-----------------------------------------------------------------------+
| (Nếu là Buyer):    [ 🔨 ĐẶT GIÁ THẦU NGAY (Tối thiểu 900.000đ) ]      |
| (Nếu là Seller):   [ ⚡ CHỐT PHIÊN SỚM VỚI GIÁ 850.000đ (M-AC-05) ]    |
+-----------------------------------------------------------------------+
```

#### Bottom Sheet Đặt Giá Thầu (`M-AC-04`):
```text
+-----------------------------------------------------------------------+
|                     ĐẶT GIÁ THẦU CỦA BẠN                   [Đóng X]   |
+-----------------------------------------------------------------------+
|  Giá cao nhất hiện tại: 850.000đ  | Bước giá tối thiểu: +50.000đ      |
|  Mức giá hợp lệ tối thiểu bạn cần đặt: 900.000 VNĐ                    |
|                                                                       |
|  Chọn nhanh:  [ +50k (900.000đ) ]  [ +100k (950.000đ) ]  [ +200k ]    |
|                                                                       |
|  Nhập mức giá bạn muốn đặt (VNĐ):                                     |
|  +-----------------------------------------------------------------+  |
|  | 900000                                                     VNĐ  |  |
|  +-----------------------------------------------------------------+  |
|  ⚠️ Lưu ý cam kết (BR-AU-02 & BR-AU-07):                              |
|  • Lượt trả giá sau khi xác nhận sẽ KHÔNG THỂ rút lại.                |
|  • Nếu thắng phiên, hệ thống tự động tạo đơn hàng và bạn có 30 phút   |
|    (2 phút ở Demo Mode) để thanh toán QR.                             |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  |              [ XÁC NHẬN ĐẶT GIÁ 900.000 VNĐ ]                   |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
```

---

### 2.5. `M-CR-01` (Giỏ Hàng Nhóm Theo Tiệm), `M-OR-01` (Checkout Preview & Buyer Protection Fee) & `M-PM-01` (Mock QR Payment)

#### A. `M-CR-01` (Giỏ Hàng Gom Nhóm Theo Từng Seller – `BR-OR-01`)
```text
+-----------------------------------------------------------------------+
| [<-]                   GIỎ HÀNG CỦA BẠN (3)                           |
+-----------------------------------------------------------------------+
|  ℹ️ Mỗi đơn hàng được thanh toán riêng theo từng Tiệm bán để đảm bảo  |
|     theo dõi vận chuyển và giữ tiền bảo vệ Escrow độc lập.            |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | (◉) 🏪 TIỆM ĐỒ SI NHÀ GẤU (Đang chọn thanh toán)                |  |
|  | --------------------------------------------------------------- |  |
|  | [✓] [Ảnh] Áo Khoác Dạ Tweed Cổ Điển         450.000đ   [x1] [🗑️]|  |
|  | [✓] [Ảnh] Khăn Choàng Len Đỏ Giáng Sinh     150.000đ   [x1] [🗑️]|  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | ( ) 🏪 RETRO CORNER (Tự động bỏ chọn khi đang chọn Tiệm Nhà Gấu)|  |
|  | --------------------------------------------------------------- |  |
|  | [ ] [Ảnh] Túi Da Đeo Chéo Vintage           320.000đ   [x1] [🗑️]|  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
| Đã chọn: 2 món (Tiệm Nhà Gấu) | Tạm tính: 600.000đ  [ MUA HÀNG -> ]   |
+-----------------------------------------------------------------------+
```

#### B. `M-OR-01` (Checkout Preview & Bảng Kê Phí Bảo Vệ Người Mua – `DEC-04`, `BR-FN-02`)
```text
+-----------------------------------------------------------------------+
| [<-]              XÁC NHẬN ĐƠN HÀNG & PHÍ BẢO VỆ                      |
+-----------------------------------------------------------------------+
|  📍 ĐỊA CHỈ NHẬN HÀNG                               [Đổi địa chỉ >]   |
|  +-----------------------------------------------------------------+  |
|  | Nguyễn Minh Đức | 0901234567                        [Mặc định]  |  |
|  | Khu phố 6, Phường Linh Trung, TP. Thủ Đức, TP. Hồ Chí Minh     |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  🏪 SẢN PHẨM TỪ: TIỆM ĐỒ SI NHÀ GẤU (2 sản phẩm)                      |
|  • 1x Áo Khoác Dạ Tweed Cổ Điển (Condition: Good)         450.000đ    |
|  • 1x Khăn Choàng Len Đỏ Giáng Sinh (Condition: Like New) 150.000đ    |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | 💳 CHI TIẾT THANH TOÁN & BẢO VỆ ESCROW (DEC-04)                 |  |
|  | --------------------------------------------------------------- |  |
|  | • Tổng tiền hàng (item_subtotal):                    600.000 VNĐ|  |
|  | • Phí vận chuyển trên ứng dụng (shipping_fee):         0 VNĐ    |  |
|  |   (Người mua & Người bán tự thỏa thuận/thanh toán khi gửi)      |  |
|  | • Phí bảo vệ người mua (Buyer Protection Fee):        43.000 VNĐ|  |
|  |   (Gồm 6% giá trị đơn [36.000đ] + 7.000đ phí cố định)           |  |
|  | --------------------------------------------------------------- |  |
|  | 🛡️ Quyền lợi Gói Bảo Vệ Người Mua:                              |  |
|  |   - Giữ 100% tiền trong sổ cái trung gian Escrow (ESCROW_HELD). |  |
|  |   - Hoàn trả đủ 100% (643.000đ) nếu hủy đơn hợp lệ hoặc nếu     |  |
|  |     hàng bị rách, sai mô tả, không nhận được hàng (DEC-07).     |  |
|  | --------------------------------------------------------------- |  |
|  | 💰 TỔNG THANH TOÁN (total_amount):                   643.000 VNĐ|  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
| Tổng thanh toán: 643.000 VNĐ             [ XÁC NHẬN ĐẶT HÀNG -> ]     |
+-----------------------------------------------------------------------+
```

#### C. `M-PM-01` (Màn Hình Thanh Toán QR Mô Phỏng & Khung Kiểm Thử Đồ Án)
```text
+-----------------------------------------------------------------------+
| [<-]                 THANH TOÁN QR & GIỮ TIỀN ESCROW                  |
+-----------------------------------------------------------------------+
|  Mã đơn hàng: #ORD-2026-0891      | Mã tham chiếu: PAY-REF-99281      |
|  ⏳ Thời gian thanh toán còn lại:  29 : 18  (Quá hạn đơn tự động hủy) |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  |                    QUÉT MÃ QR ĐỂ THANH TOÁN                     |  |
|  |                      +-------------------+                      |  |
|  |                      |  ▄▄▄▄▄ █▀█ ▄▄▄▄▄  |                      |  |
|  |                      |  █   █ █▄█ █   █  |                      |  |
|  |                      |  █▄▄▄█ ▄▀▄ █▄▄▄█  |                      |  |
|  |                      |  ▄▄▄▄▄ █ ▄ █▄█ ▄  |                      |  |
|  |                      +-------------------+                      |  |
|  |                 Số tiền: 643.000 VNĐ (total_amount)             |  |
|  |        (600.000đ Tiền hàng + 43.000đ Phí bảo vệ người mua)      |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | 🧪 BẢNG ĐIỀU KHIỂN MÔ PHỎNG ĐỒ ÁN (MOCK PAYMENT GATEWAY)        |  |
|  | (Dùng để kiểm thử & trình diễn luồng giữ tiền trung gian Escrow)|  |
|  |                                                                 |  |
|  | +-------------------------------------------------------------+ |  |
|  | |   [ ✅ MÔ PHỎNG THANH TOÁN THÀNH CÔNG (ESCROW HOLD) ]       | |  |
|  | +-------------------------------------------------------------+ |  |
|  | +-------------------------------------------------------------+ |  |
|  | |   [ ❌ MÔ PHỎNG THANH TOÁN THẤT BẠI (SIMULATE FAILURE) ]    | |  |
|  | +-------------------------------------------------------------+ |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
```

---

### 2.6. `M-OR-03` (Chi Tiết Đơn Mua – 4 Trạng Thái Độc Lập, Hủy 3 Cấp, Xác Nhận Nhận Hàng & Mở Khiếu Nại)

```text
+-----------------------------------------------------------------------+
| [<-]                CHI TIẾT ĐƠN MUA #ORD-2026-0891        [💬 Chat]  |
+-----------------------------------------------------------------------+
|  +-----------------------------------------------------------------+  |
|  | 📦 TRẠNG THÁI ĐƠN HÀNG (order_status):     ĐÃ GIAO (DELIVERED)  |  |
|  | 🛡️ TRẠNG THÁI TIỀN (escrow_status):        ĐANG GIỮ (HELD)      |  |
|  | 💳 THANH TOÁN (payment_status):            ĐÃ TRẢ (PAID)        |  |
|  | ⚖️ KHIẾU NẠI (dispute_status):             KHÔNG CÓ (NONE)      |  |
|  +-----------------------------------------------------------------+  |
|  | ⏰ Tự động hoàn tất & giải ngân sau: 23 giờ 15 phút             |  |
|  |    (Mốc đóng băng auto_complete_at: 14/11/2026 10:30 - BR-OR-05)|  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  🚚 TIẾN TRÌNH VẬN CHUYỂN (Đơn vị: GHN | Mã vận đơn: GHN8829104)      |
|  ● 13/11 10:30 - Đã giao hàng thành công (Người bán cập nhật)         |
|  │ 12/11 15:20 - Đã gửi hàng tại bưu cục (Mã: GHN8829104)             |
|  │ 12/11 11:00 - Người bán đang chuẩn bị hàng (PREPARING)             |
|  ○ 12/11 10:05 - Đã thanh toán 643.000đ vào sổ cái Escrow (HELD)      |
|                                                                       |
|  📸 SẢN PHẨM ĐÃ MUA (BẢN CHỤP SNAPSHOT LÚC ĐẶT ĐƠN - BR-OR-02)        |
|  +-----------------------------------------------------------------+  |
|  | [Ảnh Snapshot] Áo Khoác Dạ Tweed Cổ Điển             450.000đ   |  |
|  | Tình trạng lúc mua: Good | Lỗi đã ghi: Cúc thứ 2 xước nhẹ       |  |
|  +-----------------------------------------------------------------+  |
|  Tiền hàng: 600.000đ | Ship: 0đ | Phí bảo vệ: 43.000đ | Tổng: 643.000đ|
+-----------------------------------------------------------------------+
|  [BẢNG NÚT HÀNH ĐỘNG ĐỘNG THEO TRẠNG THÁI (DEC-03, DEC-06, DEC-07)]:  |
|  • Khi PENDING_PAYMENT: [ Thanh toán QR ]  | [ Hủy đơn ]              |
|  • Khi PAID:            [ Hủy đơn trực tiếp (Hoàn 100%: 643.000đ) ]   |
|  • Khi PREPARING:       [ Gửi yêu cầu hủy (Chờ Tiệm duyệt) ]          |
|  • Khi SHIPPED:         [ ⚠️ Gửi khiếu nại / Báo chưa nhận được hàng ]|
|  • Khi DELIVERED:       [ ⚠️ Gửi khiếu nại ] | [ ✅ ĐÃ NHẬN ĐƯỢC HÀNG ]|
|  • Khi COMPLETED:       [ ⭐ Đánh giá Người bán (1-5 sao) (M-RV-01) ] |
+-----------------------------------------------------------------------+
```

---

### 2.7. `M-SL-03` (Form Đăng Sản Phẩm Fixed/Auction), `M-SL-06` (Chi Tiết Đơn Bán & Duyệt Hủy) & `M-SL-08` (Sổ Cái Ví Người Bán)

#### A. `M-SL-03` (Form Đăng Sản Phẩm Chuyển Đổi Linh Hoạt Fixed Price / Auction)
```text
+-----------------------------------------------------------------------+
| [<- Hủy]                ĐĂNG SẢN PHẨM MỚI              [Xem trước]    |
+-----------------------------------------------------------------------+
|  1. HÌNH ẢNH THỰC TẾ (1-8 ảnh) * & BẰNG CHỨNG XÁC THỰC               |
|  [ + Tải ảnh chính ] [Ảnh 2] [Ảnh 3] [Ảnh chụp vết xước] [+ Tag/Code] |
|                                                                       |
|  2. THÔNG TIN SẢN PHẨM & TÌNH TRẠNG ĐỒ SI (BR-PR-03)                  |
|  Tên sản phẩm *: [ Áo Khoác Da Bò Vintage Thập Niên 90             ]  |
|  Danh mục *:     [ Áo khoác nam v ]  Thương hiệu: [ Schott NYC   v ]  |
|  Tình trạng *:   ( ) Like New   (◉) Good   ( ) Fair   ( ) Vintage Worn|
|  Mô tả khuyết điểm / Vết xước (defect_info) *:                        |
|  [ Phần cổ tay áo bên phải có vết sờn nhẹ tự nhiên theo thời gian ]   |
|                                                                       |
|  3. CHỌN PHƯƠNG THỨC BÁN (BR-PR-01):                                  |
|  +---------------------------------+----------------------------------+
|  | (◉) BÁN GIÁ CỐ ĐỊNH             | ( ) ĐẤU GIÁ THEO PHIÊN           |
|  +---------------------------------+----------------------------------+
|  | • Giá bán *: [ 950.000 VNĐ ]    | • Số lượng: Khóa cố định = 01    |
|  | • Số lượng *: [ 1 ]             | • Chọn Phiên *: [Tối 20h-22h v]  |
|  | 💚 Bạn nhận đủ 100% (950.000đ)  | • Giá khởi điểm *: [ 500.000đ ]  |
|  |    khi đơn hoàn tất (DEC-04).   | • Bước giá *:      [ 50.000đ  ]  |
|  |                                 | • Giá sàn (Tùy chọn): [700.000đ] |
|  +---------------------------------+----------------------------------+
+-----------------------------------------------------------------------+
| [ 💾 Lưu bản nháp (DRAFT) ]    |    [ 🚀 GỬI KIỂM DUYỆT (PENDING) ]   |
+-----------------------------------------------------------------------+
```

#### B. `M-SL-06` (Chi Tiết Đơn Bán – Duyệt Yêu Cầu Hủy Ở `PREPARING` & Cập Nhật Vận Chuyển)
```text
+-----------------------------------------------------------------------+
| [<-]               CHI TIẾT ĐƠN BÁN #ORD-2026-0891         [💬 Chat]  |
+-----------------------------------------------------------------------+
|  📦 Trạng thái: ĐANG CHUẨN BỊ (PREPARING) | 🛡️ Escrow: ĐANG GIỮ (HELD)|
|  💰 TIỀN HÀNG BẠN SẼ NHẬN (100% item_subtotal):       600.000 VNĐ     |
|     (Phí bảo vệ 43.000đ do Người mua chi trả riêng cho sàn - DEC-04)  |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  | ⚠️ YÊU CẦU HỦY ĐƠN TỪ NGƯỜI MUA (Khi đơn đang PREPARING - DEC-06)|  |
|  | Lý do khách nêu: "Mình đặt nhầm size, cho mình xin hủy đơn nhé" |  |
|  |                                                                 |  |
|  | [ ✅ Đồng ý Hủy (Hoàn 100% cho khách) ] | [ ❌ Từ chối & Giao ]  |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  🚚 CẬP NHẬT VẬN CHUYỂN THỦ CÔNG (Mở M-SL-07):                        |
|  +-----------------------------------------------------------------+  |
|  | Đơn vị vận chuyển *: [ Giao Hàng Nhanh (GHN)                 v ]|  |
|  | Mã vận đơn (Tracking Code) *: [ GHN8829104                     ]|  |
|  | [ 🚚 XÁC NHẬN ĐÃ GỬI HÀNG (Chuyển sang SHIPPED) ]               |  |
|  | --------------------------------------------------------------- |  |
|  | (Khi đơn đang SHIPPED):                                         |  |
|  | [ 📦 XÁC NHẬN ĐÃ GIAO TỚI NƠI (DELIVERED -> Đếm ngược 24h) ]    |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
```

#### C. `M-SL-08` (Ví Người Bán & Sổ Cái Bất Biến – `Read-Only Immutable Ledger`)
```text
+-----------------------------------------------------------------------+
| [<-]              VÍ NGƯỜI BÁN & SỔ CÁI ESCROW                        |
+-----------------------------------------------------------------------+
|  +-----------------------------------------------------------------+  |
|  | 🎓 VÍ MÔ PHỎNG ĐỒ ÁN MÔN HỌC (Không kết nối ngân hàng thực tế)  |  |
|  | 💰 SỐ DƯ KHẢ DỤNG (Đã giải ngân 100% tiền hàng):  2.450.000 VNĐ |  |
|  | 🔒 ĐANG CHỜ GIẢI NGÂN TRONG ESCROW (HELD):          600.000 VNĐ |  |
|  +-----------------------------------------------------------------+  |
|  [ Tab 1: Biến động Ví (wallet_transactions) ] [ Tab 2: Sổ cái Escrow]|
|  +-----------------------------------------------------------------+  |
|  | • +600.000đ | Giải ngân 100% tiền hàng đơn #ORD-0891 (RELEASED) |  |
|  |   Mã bút toán: WTX-9012 | Số dư sau GD: 2.450.000đ | 14/11/2026 |  |
|  | --------------------------------------------------------------- |  |
|  | • +350.000đ | Giải ngân phần còn lại đơn #ORD-0850 (PARTIAL)    |  |
|  |   Mã bút toán: WTX-8841 | Số dư sau GD: 1.850.000đ | 10/11/2026 |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
```

---

### 2.8. `M-DP-01` & `M-DP-03` (Màn Hình Gửi Khiếu Nại & Phòng Đối Chứng Bằng Chứng Trên Mobile)

```text
+-----------------------------------------------------------------------+
| [<-]              HỒ SƠ KHIẾU NẠI #DSP-2026-042                       |
+-----------------------------------------------------------------------+
|  +-----------------------------------------------------------------+  |
|  | 🔒 TRẠNG THÁI: ĐANG XỬ LÝ TRANH CHẤP (OPEN)                     |  |
|  | 🛡️ Đã khóa cứng tự động hoàn tất 24h & khóa giải ngân Escrow!   |  |
|  | 💰 Số tiền đang được bảo vệ: 643.000 VNĐ (total_amount)         |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  🙋 BẰNG CHỨNG CỦA NGƯỜI MUA (Gửi ở trạng thái DELIVERED - DEC-03):   |
|  • Lý do: Sản phẩm bị rách / Không đúng mô tả                         |
|  • Mô tả: "Áo bị rách một đường dài 5cm ở mặt sau lưng chưa được      |
|            người bán khai báo trong mục defect_info."                 |
|  • Ảnh bằng chứng: [Ảnh vết rách 1] [Ảnh vết rách 2] [Ảnh bao bì]     |
|                                                                       |
|  🏪 GIẢI TRÌNH & BẰNG CHỨNG ĐỐI CHỨNG CỦA NGƯỜI BÁN:                  |
|  • Giải trình: "Shop xin lỗi, có thể do khâu đóng gói bị móc vào kéo."|
|  • Ảnh đối chứng: [Ảnh đóng gói]                                      |
|                                                                       |
|  🏛️ PHẢN HỒI / PHÁN QUYẾT TỪ QUẢN TRỊ VIÊN (ADMIN VERDICT):          |
|  +-----------------------------------------------------------------+  |
|  | ✅ Quyết định: CHẤP NHẬN KHIẾU NẠI (APPROVE_BUYER_REFUND)       |  |
|  | • Hoàn trả 100% total_amount = 643.000 VNĐ (gồm cả 600.000đ     |  |
|  |   tiền hàng + 43.000đ Phí bảo vệ người mua) về cho Người mua.   |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
```

---

## Chương 3. Kết Quả Tự Động Kiểm Tra & Nghiệm Thu (`Self-Verified Quality Gate Checklist`)

- [x] **1. Đầy đủ bố cục Low-Fidelity cho toàn bộ cụm màn hình Mobile:** Đã phác thảo chi tiết khung điều hướng 5 Tab + Top Bar, Login/Onboarding, Guest Welcome Card, Home, Search/Filter, Product Detail (Fixed Price), Auction Room & Bid Sheet, Cart (Grouped by Seller), Checkout Preview (**Buyer Protection Fee + Ship 0đ**), Mock QR Payment, Buyer Order Detail (Hủy 3 cấp & Confirm Delivery), Seller Form (Fixed & Auction), Seller Order Detail (Duyệt hủy ở `PREPARING`), Seller Wallet Ledger và Dispute Room.
- [x] **2. Sẵn sàng 100% cho Thiết kế Figma ở Phase 03:** Đã quy định rõ cấu trúc khối, nhãn tiếng Việt chuẩn NFC, vị trí nút hành động và phân tầng Typography (`Wichita Vintage`, `Fraunces`, `Be Vietnam Pro`).