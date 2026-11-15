# 04. ICONOGRAPHY SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P302-ICONOGRAPHY`
- **Version:** `1.0.0`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`

---

## Chương 1. Định Hướng Bộ Biểu Tượng & Quy Tắc Kỹ Thuật (`Iconography Direction & Technical Rules`)

Để đảm bảo tính nhất quán tuyệt đối và khả năng triển khai sẵn có trên cả **Flutter** và **Laravel Blade Admin** mà không phải vẽ tay hàng trăm icon rời rạc, dự án sử dụng hệ thống biểu tượng chuẩn **`Phosphor Icons` (`phosphor_flutter` trên Mobile & `phosphor-icons` trên Web)** (hoặc `Lucide Icons` tương đương):

1. **Phong cách nét (`Stroke & Fill Approach`):**
   - **Trạng thái Mặc định / Chưa chọn (`Inactive / Default`):** Sử dụng kiểu **`Regular Outline` (`Stroke width = 1.75px – 2px`)**, đầu nét và góc nối bo tròn mềm mại (`Round Cap & Round Join`), hài hòa với kiểu chữ `Fraunces` và `Be Vietnam Pro`.
   - **Trạng thái Đang chọn / Nhấn mạnh (`Active / Selected`):** Chuyển sang kiểu **`Fill` hoặc `Duotone`** (có lớp nền màu phụ độ mờ `20%`), tạo phản hồi thị giác rõ ràng trên thanh Bottom Navigation 5 Tab và nút Yêu thích.
2. **Thang kích thước biểu tượng (`Icon Sizing Scale`):**
   - `icon.size.xs` (`14px`): Icon nằm bên trong `Status Badge`, `Condition Badge` hoặc nhãn thời gian nhỏ.
   - `icon.size.sm` (`16px`): Icon đi kèm văn bản phụ, ngôi sao đánh giá trên thẻ sản phẩm (`★ 4.9`).
   - `icon.size.md` (`20px`): Kích thước chuẩn cho icon nằm bên trong Button, Input Field (`Search`, `Show/Hide Password`) và menu Sidebar của Admin.
   - `icon.size.lg` (`24px`): Kích thước chuẩn cho **5 Tab trên Bottom Navigation Bar** và **3 Global Utility Icons trên Top App Bar** (`Giỏ hàng`, `Chat`, `Thông báo`).
   - `icon.size.xl` (`48px – 64px`): Icon minh họa trung tâm cho các trạng thái `Empty State`, `Payment Success Receipt` (`M-PM-02`) và `Guest Welcome Card`.
3. **Vùng chạm & Căn chỉnh (`Touch Target & Alignment`):**
   - Dù hình vẽ icon trên App Bar chỉ rộng `24px`, vùng nhận cảm ứng (`IconButton Hit Box`) bắt buộc phải đạt tối thiểu **`48px x 48px`** (`space.12`), căn giữa hoàn hảo theo trục dọc (`CrossAxisAlignment.center`) với dòng chữ đi kèm (khoảng cách giữa icon và chữ = `8px` tức `space.2`).

---

## Chương 2. Từ Điển Biểu Tượng Theo 12 Nhóm Nghiệp Vụ (`Master Icon Catalog by Domain`)

| Nhóm Nghiệp Vụ | Tên Biểu Tượng (Semantic Name) | Icon Chuẩn (`Phosphor / Lucide`) | Ý Nghĩa & Vị Trí Sử Dụng Chính Thức |
| :--- | :--- | :--- | :--- |
| **1. Navigation (Điều hướng)** | `icon.nav.home` | `House` (Outline / Fill) | Tab 1: Trang chủ (`/home`). |
| | `icon.nav.discover` | `Compass` / `SquaresFour` | Tab 2: Khám phá & Danh mục (`/discover`). |
| | `icon.nav.auction` | `Gavel` (Chiếc búa đấu giá) | Tab 3: Đấu giá (`/auctions`) & Sidebar Admin. |
| | `icon.nav.seller` | `Storefront` (Mặt tiền tiệm) | Tab 4: Kênh Bán (`/seller` – Seller Center). |
| | `icon.nav.profile` | `UserCircle` | Tab 5: Cá nhân (`/profile`). |
| **2. Product & Condition (Sản phẩm & Đồ si)** | `icon.product.condition` | `Sparkle` / `Tag` | Nhãn tình trạng sản phẩm (`Like New`, `Good`, `Fair`, `Vintage Worn`). |
| | `icon.product.defect` | `MagnifyingGlassPlus` / `WarningCircle` | Mục khai báo vết xước/khuyết điểm (`defect_info` – `BR-PR-03`) & nút phóng to ảnh soi lỗi (`M-PR-02`). |
| | `icon.product.verified` | `SealCheck` (Fill `#294638`) | Huy hiệu xác minh `MODERATOR_REVIEWED` / `EVIDENCE_PROVIDED`. |
| **3. Commerce (Mua sắm)** | `icon.commerce.cart` | `ShoppingBag` / `ShoppingCart` | Icon Giỏ hàng trên Top Header & nút Thêm vào giỏ. |
| | `icon.commerce.favorite` | `Heart` (Outline $\rightarrow$ Fill `#873A43`) | Nút lưu sản phẩm yêu thích (`BF-11`). |
| | `icon.commerce.filter` | `SlidersHorizontal` | Nút mở Bộ lọc đa tiêu chí (`M-DS-03`). |
| **4. Auction (Đấu giá)** | `icon.auction.bid` | `Gavel` | Nút Đặt giá thầu (`Place Bid`) và lịch sử trả giá. |
| | `icon.auction.timer` | `ClockCountdown` / `HourglassHigh` | Đồng hồ đếm ngược phiên đấu giá & hạn thanh toán 30 phút. |
| | `icon.auction.anti_sniping` | `Lightning` (Fill `#C79B4B`) | Cảnh báo gia hạn tự động 2 phút cuối (`Anti-Sniping` – `AF-04`). |
| | `icon.auction.leading` | `Crown` (Fill `#C79B4B`) | Huy hiệu đang dẫn đầu phiên đấu giá (`LEADING`). |
| | `icon.auction.watch` | `Eye` / `BellRinging` | Nút theo dõi phiên đấu giá (`Watchlist`). |
| **5. Order & Shipping (Đơn hàng & Vận chuyển)** | `icon.order.package` | `Package` | Trạng thái đang chuẩn bị / đóng gói hàng (`PREPARING`). |
| | `icon.order.truck` | `Truck` | Trạng thái đang vận chuyển (`SHIPPED`) & thông tin hãng vận chuyển. |
| | `icon.order.delivered` | `CheckCircle` / `MapPinLine` | Trạng thái đã giao hàng tới nơi (`DELIVERED`). |
| **6. Payment (Thanh toán)** | `icon.payment.qr` | `QrCode` | Màn hình thanh toán QR mô phỏng (`M-PM-01`). |
| | `icon.payment.receipt` | `Receipt` | Biên lai thanh toán & bảng kê chi phí (`M-OR-01`, `M-PM-02`). |
| **7. Escrow & Protection (Giữ tiền & Bảo vệ)** | `icon.escrow.shield_held` | `ShieldCheck` (Fill `#1C5858`) | Biểu tượng **Phí bảo vệ người mua (`Buyer Protection Fee`)** & trạng thái tiền đang giữ an toàn trong **`ESCROW_HELD`**. |
| | `icon.escrow.released` | `HandCoins` / `Wallet` | Giải ngân 100% tiền hàng vào Ví Người bán (`ESCROW_RELEASED`). |
| | `icon.escrow.refund` | `ArrowCounterClockwise` | Hoàn trả 100% `total_amount` về cho Người mua (`ESCROW_REFUNDED`). |
| | `icon.escrow.frozen` | `LockKey` (Fill `#6A2C5A`) | Tiền trong Escrow đang bị đóng băng do có Khiếu nại mở (`BR-DP-02`). |
| **8. Chat & Notifications** | `icon.chat.bubble` | `ChatCircleDots` | Icon Hộp thư Chat trên Top Header & nút Chat với người bán. |
| | `icon.noti.bell` | `Bell` | Icon Thông báo hệ thống (`M-NT-01`). |
| **9. Seller & Moderation** | `icon.seller.add_item` | `PlusCircle` | Nút đăng sản phẩm mới (`M-SL-03`). |
| | `icon.mod.approve` | `CheckFat` | Nút Phê duyệt sản phẩm (`Approve` – `A-MD-02`). |
| | `icon.mod.reject` | `XCircle` / `NotePencil` | Nút Từ chối / Yêu cầu chỉnh sửa (`Reject` – `DEC-05`). |
| **10. Dispute & Admin** | `icon.dispute.scale` | `Scales` (Cán cân công lý) | Phòng xử lý tranh chấp & Phán quyết tài chính của Admin (`A-DP-02`). |
| | `icon.admin.audit` | `FileSearch` / `Scroll` | Nhật ký kiểm toán hệ thống (`Audit Logs` – `A-AD-01`). |
| | `icon.admin.devtools` | `TerminalWindow` / `Flask` | Bảng điều khiển **Developer Tools (`DEMO_MODE=true` – `A-DT-01`)**. |

---

## Chương 3. Quy Tắc Cho Biểu Tượng Trang Trí Mùa Lễ Hội (`Seasonal Christmas Decorative Icons – NFR-UX-02`)

1. Các biểu tượng trang trí mùa lễ hội (Cây thông nhỏ `TreeEvergreen`, Tất Giáng sinh `Stocking`, Ngôi sao lấp lánh `Sparkle`, Chuông nhỏ `BellSimple`) chỉ được phép xuất hiện ở:
   - Cạnh Logo `izithrift` trên Top Header.
   - Bên trong Hero Banner Giáng sinh (`M-HM-01`).
   - Minh họa `Empty State` và `Guest Welcome Card` (`NAV-DEC-03`).
2. **Cấm tuyệt đối** đặt icon trang trí Giáng sinh đè lên ảnh sản phẩm, giá bán, đồng hồ đếm ngược hoặc nút hành động thương mại.
3. Toàn bộ icon trang trí mùa lễ hội được bọc trong điều kiện cấu hình `enableSeasonalChristmasDecor` để có thể ẩn đi ngay lập tức khi hết mùa lễ hội (`UI-DESIGN-PRINCIPLE-10`).