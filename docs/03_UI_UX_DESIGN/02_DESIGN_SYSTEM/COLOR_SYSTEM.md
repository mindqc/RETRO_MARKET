# 01. COLOR SYSTEM SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P302-COLOR-SYSTEM`
- **Version:** `1.0.0`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`
- **Approved Direction Ref:** `UI-DEC-01` (*Warm Editorial Archive*), `UI-DEC-02` (*Seller Header Distinction*), `UI-DEC-03` (*Mobile vs Admin Surface Split*)

---

## Chương 1. Triết Lý Bảng Màu & Nguyên Tắc Phân Tách Ngữ Nghĩa (`Color Philosophy & Semantic Separation`)

Bảng màu của **Retro Market (`izithrift`)** được thiết kế để giải quyết bài toán kép: vừa mang lại cảm giác ấm áp, hoài cổ của một tiệm đồ secondhand tuyển chọn (`Warm Editorial Archive`), vừa đảm bảo độ sắc nét, không gây nhầm lẫn trong các giao dịch thương mại điện tử, đấu giá theo giây và quản lý dòng tiền trung gian Escrow:

1. **Nguyên tắc Nền ấm – Ảnh thật (`Warm Canvas, True-Color Imagery`):** Sử dụng tông nền Kem giấy ấm (`#F4EBDD`) và Be cát sáng (`#E7DAC6`) trên Mobile để giảm mỏi mắt và tạo chất hoài cổ tự nhiên, nhưng vùng khung chứa ảnh sản phẩm luôn giữ độ trung tính để không làm sai lệch màu sắc thực tế của món đồ cũ (`BR-PR-03`).
2. **Nguyên tắc Phân tách Bề mặt Mobile vs Web Admin (`UI-DEC-03`):**
   - **Mobile App (`izithrift`):** Dùng nền `Warm Cream` (`#F4EBDD`) và thẻ `Soft Alabaster` (`#FAF5EC`) / `Warm Sand` (`#E7DAC6`).
   - **Admin Dashboard (`Laravel Blade`):** Dùng Sidebar màu `Forest Pine` (`#294638`) đồng bộ nhận diện thương hiệu, nhưng vùng làm việc và bảng dữ liệu dùng nền `Light Warm Ivory` (`#FBF9F5`) và mặt bảng trắng ngà (`#FFFFFF`) để tối đa hóa độ tương phản khi kiểm duyệt hàng trăm dòng dữ liệu.
3. **Nguyên tắc Không Trùng Lặp Màu Trạng Thái Nhạy Cảm (`Zero Ambiguity in Status Colors`):**
   - Phân biệt rõ ràng giữa **Đang giữ tiền bảo vệ (`Escrow Held` – Xanh lục bảo trầm)**, **Đang chờ xử lý (`Pending` – Vàng hổ phách)**, **Bị vượt giá / Từ chối / Lỗi (`Outbid / Rejected` – Đỏ rượu vang / Đỏ đất)**, và **Đóng băng do Khiếu nại (`Disputed` – Tím mận trầm)**.
4. **Nguyên tắc Đạt Chuẩn Tương Phản WCAG 2.1 AA:** Mọi cặp màu chữ chính trên nền đều đạt tỷ lệ tương phản tối thiểu `>= 4.5:1` (văn bản thường) và `>= 3.0:1` (tiêu đề lớn & thành phần UI).

---

## Chương 2. Hệ Thống Token Màu Sắc Chi Tiết (`Comprehensive Color Tokens`)

### 2.1. Brand Colors (Màu Thương Hiệu & Nhận Diện Vai Trò – `UI-DEC-01`, `UI-DEC-02`)

| Token Name | HEX | RGB | Vai Trò & Ngữ Cảnh Sử Dụng Thực Tế | Độ Tương Phản & Tương Thích Bề Mặt |
| :--- | :---: | :---: | :--- | :--- |
| `color.brand.primary` | `#294638` | `41, 70, 56` | **Forest Pine (Xanh rừng thông trầm):** Màu thương hiệu chính; dùng cho Primary Button, trạng thái Active trên Bottom Nav, Header của **Kênh Bán (`Tab 4 – Seller Center` theo `UI-DEC-02`)** và Left Sidebar của Admin Dashboard. | Chữ sáng `#FAF5EC` trên nền `#294638` đạt **`9.4:1` (AAA)**. |
| `color.brand.primary.hover` | `#1E352A` | `30, 53, 42` | Trạng thái Pressed (Mobile) hoặc Hover (Admin Web) của các thành phần dùng `color.brand.primary`. | Chữ `#FAF5EC` đạt **`11.8:1` (AAA)**. |
| `color.brand.primary.subtle` | `#E3ECE7` | `227, 236, 231` | Nền dịu nhẹ cho các badge thông tin thương hiệu, vùng highlight sản phẩm đã duyệt và nền pill tab đang chọn. | Chữ `#294638` trên nền `#E3ECE7` đạt **`7.8:1` (AAA)**. |
| `color.brand.secondary` | `#873A43` | `135, 58, 67` | **Vintage Burgundy (Đỏ rượu vang ấm):** Màu thương hiệu thứ cấp; dùng cho CTA Đấu giá (`Place Bid`), nhãn sự kiện mùa lễ hội Giáng sinh, và điểm nhấn cảm xúc biên tập. | Chữ sáng `#FAF5EC` trên nền `#873A43` đạt **`6.8:1` (AA+)**. |
| `color.brand.secondary.hover` | `#6E2D35` | `110, 45, 53` | Trạng thái Pressed / Hover của nút Đấu giá và thành phần Burgundy. | Chữ `#FAF5EC` đạt **`8.9:1` (AAA)**. |
| `color.brand.secondary.subtle` | `#F4E5E7` | `244, 229, 231` | Nền dịu nhẹ cho banner đấu giá, thông báo sắp hết giờ hoặc vùng cảnh báo nhẹ. | Chữ `#873A43` trên nền `#F4E5E7` đạt **`5.9:1` (AA)**. |
| `color.brand.accent` | `#C79B4B` | `199, 155, 75` | **Antique Brass (Vàng đồng cổ điển):** Dùng cho ngôi sao đánh giá (`1–5 Stars`), huy hiệu Người bán uy tín (`Trust Score`), biểu tượng Vương miện người dẫn đầu đấu giá và viền trang trí mùa lễ hội. | Chỉ dùng làm màu icon/huy hiệu hoặc nền có chữ tối `#302D2A` (đạt **`5.6:1` AA**). Không dùng chữ trắng trên nền vàng đồng. |
| `color.brand.accent.subtle` | `#F7EFE0` | `247, 239, 224` | Nền của hộp chứng nhận kiểm duyệt và thẻ ưu đãi/nổi bật. | Chữ `#6B4F1D` trên nền `#F7EFE0` đạt **`6.4:1` (AA)**. |

---

### 2.2. Neutral & Surface Colors (Màu Nền, Bề Mặt, Văn Bản & Đường Viền – `UI-DEC-03`)

| Token Name | HEX | RGB | Vai Trò & Ngữ Cảnh Sử Dụng (Phân Biệt Mobile vs Admin) | Độ Tương Phản (WCAG Check) |
| :--- | :---: | :---: | :--- | :--- |
| `color.bg.mobile.canvas` | `#F4EBDD` | `244, 235, 221` | **Warm Cream:** Màu nền chính toàn cục (`Scaffold Background`) của ứng dụng di động `izithrift` (Tab 1, 2, 3, 5). | Chữ chính `#302D2A` đạt **`11.2:1` (AAA)**. |
| `color.surface.mobile.card` | `#FAF5EC` | `250, 245, 236` | **Soft Alabaster:** Bề mặt của `Product Card`, `Auction Card`, `Order Card`, ô nhập liệu và Bottom Navigation trên Mobile. Tạo độ nổi tự nhiên trên nền `#F4EBDD`. | Chữ chính `#302D2A` đạt **`12.4:1` (AAA)**. |
| `color.surface.mobile.secondary` | `#E7DAC6` | `231, 218, 198` | **Warm Sand / Soft Beige:** Bề mặt thứ cấp dùng cho `Phiếu kiểm định tình trạng (Condition Slip)`, hộp tóm tắt phí, chip bộ lọc chưa chọn và khung ghim sản phẩm trong phòng Chat. | Chữ chính `#302D2A` đạt **`9.6:1` (AAA)**. |
| `color.surface.mobile.elevated` | `#FFFDF9` | `255, 253, 249` | Bề mặt nổi cao nhất dùng cho `Bottom Sheet`, `Dialog`, `Modal` và `Toast` trên Mobile. | Chữ chính `#302D2A` đạt **`13.5:1` (AAA)**. |
| `color.bg.admin.canvas` | `#FBF9F5` | `251, 249, 245` | **Light Warm Ivory (`UI-DEC-03`):** Màu nền vùng làm việc chính của Laravel Blade Admin Dashboard, giúp bảng dữ liệu sáng sủa, giảm mỏi mắt. | Chữ chính `#302D2A` đạt **`13.1:1` (AAA)**. |
| `color.surface.admin.card` | `#FFFFFF` | `255, 255, 255` | Bề mặt của `Data Table`, `Metric Card`, `Moderation Split-Pane` và `Dispute Case Room` trên Web Admin. | Chữ chính `#302D2A` đạt **`13.8:1` (AAA)**. |
| `color.text.primary` | `#302D2A` | `48, 45, 42` | **Deep Warm Charcoal:** Màu chữ chính cho toàn bộ tiêu đề, tên sản phẩm, giá tiền và nội dung thân bài. | Đạt chuẩn **AAA** trên mọi bề mặt sáng. |
| `color.text.secondary` | `#655E57` | `101, 94, 87` | **Muted Espresso Grey:** Màu chữ phụ cho nhãn trường dữ liệu, thời gian đăng, tên danh mục và mô tả bổ trợ. | Đạt **`5.4:1` (AA)** trên `#F4EBDD` và **`6.1:1` (AA)** trên `#FAF5EC`. |
| `color.text.tertiary` | `#8C837A` | `140, 131, 122` | Màu cho chữ gợi ý (`Placeholder`) trong ô tìm kiếm/input hoặc chú thích phụ không trọng yếu. | Đạt **`3.5:1`** (chỉ dùng cho placeholder, có label rõ ràng đi kèm). |
| `color.text.disabled` | `#ACA399` | `172, 163, 153` | Màu chữ và icon trên các nút bấm/trường nhập liệu đang bị vô hiệu hóa (`Disabled State`). | Kèm hiệu ứng khóa thao tác rõ ràng. |
| `color.text.inverse` | `#FAF5EC` | `250, 245, 236` | Màu chữ sáng hiển thị trên các nền tối (`#294638`, `#873A43`, `#302D2A`). | Đạt **`>= 6.8:1` (AA/AAA)**. |
| `color.border.default` | `#D8CBB8` | `216, 203, 184` | Đường viền `1px` tiêu chuẩn cho `Product Card`, `Input Field`, `Data Table Cell` và `Inspection Slip`. | Tách biệt rõ khối trên nền kem ấm. |
| `color.border.strong` | `#B8A892` | `184, 168, 146` | Đường viền nhấn mạnh cho ô Input đang có mặt hoặc đường kẻ nét đứt của cuống vé đấu giá (`Auction Ticket Divider`). | Rõ nét trên cả Mobile & Web. |
| `color.divider.hairline` | `#E5D9C8` | `229, 217, 200` | Đường kẻ phân cách mảnh `1px` giữa các dòng danh sách hoặc các mục trong bảng tính phí. | Tinh tế, không gây nhiễu thị giác. |

---

### 2.3. Semantic Colors (Màu Ngữ Nghĩa Hệ Thống Chuẩn)

| Token Name | HEX (Text/Icon) | HEX (Surface Bg) | HEX (Border) | Vai Trò & Ngữ Cảnh Sử Dụng |
| :--- | :---: | :---: | :---: | :--- |
| `color.semantic.success` | `#236343` | `#E3F2EA` | `#9ACBB0` | Thông báo thao tác thành công, xác nhận đã lưu, trạng thái hoạt động (`ACTIVE`). |
| `color.semantic.warning` | `#945814` | `#FDF1E1` | `#E8C28E` | Cảnh báo cần chú ý, yêu cầu bổ sung thông tin, thời gian sắp hết hạn. |
| `color.semantic.error` | `#A62B2B` | `#FCE8E8` | `#E5A6A6` | Lỗi validation form (`422`), lỗi kết nối mạng, hành động xóa/hủy mang tính phá hủy (`Destructive`). |
| `color.semantic.info` | `#28557A` | `#E6F0F8` | `#A2C4E0` | Hộp giải thích cơ chế hoạt động, hướng dẫn sử dụng, thông báo hệ thống trung lập. |

---

### 2.4. Commerce & Product Condition Colors (Màu Thương Mại & Tình Trạng Đồ Secondhand)

Để người mua đánh giá và so sánh nhanh chất lượng đồ cũ trên lưới sản phẩm (`M-DS-02`) và trang chi tiết (`M-PR-01`), mỗi cấp độ tình trạng (`condition`) và trạng thái bài đăng có bộ token riêng:

| Token Name | HEX (Text/Badge) | HEX (Badge Bg) | Ngữ Cảnh Sử Dụng Cụ Thể (`BR-PR-03`) |
| :--- | :---: | :---: | :--- |
| `color.commerce.price.primary` | `#294638` | *(Transparent)* | Hiển thị **Giá bán cố định (`FIXED_PRICE`)** và **Tổng thanh toán (`total_amount`)** nổi bật, vững chãi. |
| `color.commerce.sold_out` | `#5C5650` | `#E0D8CE` | Nhãn **`ĐÃ BÁN (SOLD OUT)`** phủ lên sản phẩm có `status = SOLD` hoặc `available_quantity = 0`. |
| `color.condition.like_new` | `#1F5E3B` | `#E1F0E7` | Tình trạng **`Like New (Như mới 95–99%)`**: Xanh lá tươi tắn, biểu thị độ mới cao nhất. |
| `color.condition.good` | `#2B5B6C` | `#E3EFF3` | Tình trạng **`Good (Tốt 85–94%)`**: Xanh lam trầm tin cậy. |
| `color.condition.fair` | `#8C5A1B` | `#F9EFE0` | Tình trạng **`Fair (Khá – có dấu hiệu sử dụng)`**: Nâu hổ phách ấm. |
| `color.condition.vintage_worn` | `#6E473B` | `#EFE6E2` | Tình trạng **`Vintage Worn (Phong trần / Patina cổ điển)`**: Nâu đất cổ điển, nhắc người mua đọc kỹ `defect_info`. |

---

### 2.5. Scheduled Auction Colors (Màu Chuyên Biệt Cho Đấu Giá Theo Phiên – `AF-01..10`)

Tuyệt đối không dùng chung màu giữa người đang dẫn đầu và người bị vượt giá:

| Token Name | HEX (Text/Icon) | HEX (Surface Bg) | Ngữ Cảnh Sử Dụng Trong `Auction Hub` (`M-AC-01..04`) |
| :--- | :---: | :---: | :--- |
| `color.auction.live.badge` | `#FAF5EC` | `#873A43` | Nhãn **`🔴 LIVE ĐANG ĐẤU GIÁ`** trên thẻ đấu giá và phòng đấu giá `M-AC-03`. |
| `color.auction.highest_bid` | `#873A43` | `#F4E5E7` | Con số **Giá cao nhất hiện tại (`current_highest_bid`)** để phân biệt tức thì với giá mua đứt cố định (`#294638`). |
| `color.auction.leading` | `#1F5E3B` | `#DFF0E6` | Huy hiệu **`👑 BẠN ĐANG DẪN ĐẦU (LEADING)`** tại `M-AC-02` và `M-AC-03`. |
| `color.auction.outbid` | `#A62B2B` | `#FCE6E6` | Huy hiệu **`⚠️ BỊ VƯỢT GIÁ (OUTBID – Đặt lại ngay!)`** tại `M-AC-02` và thông báo `M-NT-01` (`AF-05`). |
| `color.auction.countdown.normal` | `#302D2A` | `#E7DAC6` | Đồng hồ đếm ngược phiên đấu giá khi thời gian còn `> 15 phút`. |
| `color.auction.countdown.urgent` | `#FAF5EC` | `#A62B2B` | Đồng hồ đếm ngược khi vào giai đoạn nước rút (`<= 15 phút` hoặc trong vùng **Anti-Sniping 2 phút cuối** `BR-AU-04`). |
| `color.auction.anti_sniping` | `#7A4B0E` | `#FDECC8` | Banner thông báo **`⚡ ĐÃ GIA HẠN ANTI-SNIPING (+2 PHÚT)`** (`AF-04`). |
| `color.auction.won` | `#302D2A` | `#EED69F` | Huy hiệu **`🏆 CHIẾN THẮNG ĐẤU GIÁ`** (Vàng đồng sáng) kèm đếm ngược 30 phút thanh toán (`AF-08`). |
| `color.auction.ended` | `#655E57` | `#E5DDD2` | Phiên đã kết thúc (`COMPLETED`, `ENDED_UNSOLD`) hoặc đã hủy. |

---

### 2.6. Order, Payment, Escrow & Dispute Colors (Màu Cho 4 Vòng Đời Giao Dịch Độc Lập – `ADR-03`, `DEC-04..07`)

Để người mua, người bán và Admin phân biệt rõ trạng thái vận hành đơn hàng với trạng thái giữ tiền Escrow và tranh chấp:

| Nhóm Trạng Thái | Token Name | HEX (Text) | HEX (Badge Bg) | Trạng Thái Nghiệp Vụ Đại Diện |
| :--- | :--- | :---: | :---: | :--- |
| **1. Thanh toán (`payment_status`)** | `color.payment.pending` | `#945814` | `#FDF1E1` | `UNPAID` / `PENDING_PAYMENT` (Đang chờ quét QR thanh toán). |
| | `color.payment.paid` | `#236343` | `#E3F2EA` | `PAID` (Thanh toán QR mô phỏng thành công). |
| | `color.payment.failed` | `#A62B2B` | `#FCE8E8` | `FAILED` / `EXPIRED` (Thanh toán thất bại hoặc quá hạn 30 phút). |
| **2. Sổ cái Escrow (`escrow_status`)** | `color.escrow.held` | `#1C5858` | `#DDF0F0` | **`ESCROW_HELD` (Xanh lục bảo Bắc Âu):** Tiền `total_amount` đang được giữ bảo vệ an toàn tại trung gian (`OF-03`). |
| | `color.escrow.released` | `#236343` | `#E3F2EA` | **`ESCROW_RELEASED`:** Đã giải ngân 100% `item_subtotal` vào Ví Người bán (`DEC-04`). |
| | `color.escrow.refunded` | `#28557A` | `#E4EFF8` | **`ESCROW_REFUNDED` / `PARTIALLY_REFUNDED` (Xanh dương bảo hoàn):** Đã hoàn trả 100% `total_amount` (hoặc 1 phần) về cho Người mua (`DEC-07`). |
| **3. Đơn hàng (`order_status`)** | `color.order.preparing` | `#7A4B0E` | `#FBF0D9` | `PREPARING` (Người bán đang đóng gói chuẩn bị hàng). |
| | `color.order.shipped` | `#28557A` | `#E6F0F8` | `SHIPPED` / `DELIVERED` (Đang vận chuyển / Đã giao chờ hoàn tất 24h). |
| | `color.order.completed` | `#236343` | `#E3F2EA` | `COMPLETED` (Đơn hàng hoàn tất trọn vẹn). |
| | `color.order.cancelled` | `#655E57` | `#E6E0D6` | `CANCELLED` (Đơn hàng đã hủy). |
| **4. Khiếu nại (`dispute_status`)** | `color.dispute.open` | `#6A2C5A` | `#F4E4F0` | **`DISPUTE_OPEN` / `NEED_MORE_INFO` (Tím mận cảnh báo):** Đơn đang có tranh chấp, **khóa cứng giải ngân Escrow** (`BR-DP-02`). |

---

### 2.7. Moderation & Account Governance Colors (Màu Kiểm Duyệt & Quản Trị – `DEC-05`)

| Token Name | HEX (Text) | HEX (Badge Bg) | Ngữ Cảnh Sử Dụng Tại `My Listings` (`M-SL-02`) & `Admin Moderation` (`A-MD-01..02`) |
| :--- | :---: | :---: | :--- |
| `color.mod.draft` | `#655E57` | `#EAE3D9` | Bản nháp (`DRAFT`) chưa gửi kiểm duyệt. |
| `color.mod.pending` | `#945814` | `#FDF1E1` | Đang chờ Moderator kiểm duyệt (`PENDING_REVIEW`). |
| `color.mod.approved` | `#236343` | `#E3F2EA` | Đã phê duyệt công khai (`APPROVED`) hoặc xác minh `MODERATOR_REVIEWED`. |
| `color.mod.rejected` | `#A62B2B` | `#FCE8E8` | Bị từ chối / Yêu cầu chỉnh sửa kèm lý do bắt buộc (`REJECTED` – `DEC-05`). |
| `color.mod.suspended` | `#FAF5EC` | `#7A1F1F` | Tài khoản bị khóa (`SUSPENDED` / `BANNED`) hoặc sản phẩm bị gỡ ẩn (`HIDDEN`). |