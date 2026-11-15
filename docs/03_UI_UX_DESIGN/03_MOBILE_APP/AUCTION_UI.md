# 09. MOBILE SCHEDULED AUCTION SYSTEM UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P305A-AUCTION-UI`
- **Version:** `1.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – UI/UX Design System & High-Fidelity Specification`
- **Screen IDs Covered:** `M-AC-01` (Auction Hub), `M-AC-02` (My Auctions: Participating / Watchlist / Won), `M-AC-03` (Auction Detail & Real-Time Bid Room), `M-AC-04` (Place Bid & Bid History Bottom Sheet), `M-AC-05` (Seller Early Close Dialog)
- **Compliance Ref:** `AF-01..10`, `FR-AC-01..06`, `BR-AC-02`, `BR-AU-01..07`, `DEC-01`, `DEC-02`, `DEC-04`, `ADR-05`, `ADR-06`, `UI-DEC-01..04`, `DS-DEC-01..03`

---

## Chương 1. Triết Lý Thiết Kế Giao Diện Đấu Giá Theo Phiên (`Auction Ticket Motif & Real-Time Precision`)

Hệ thống Đấu giá theo khung giờ hàng ngày (`Scheduled Auction System`) sử dụng ngôn ngữ thị giác **"Cuống Vé Đấu Giá Cổ Điển" (`Auction Ticket Stub Motif` – `UI-DEC-01`)** kết hợp độ chính xác số học tuyệt đối để giải quyết 5 bài toán UX cốt lõi:
1. **Nhận diện hình khối tức thì (`Ticket Stub Geometry`):** Mọi thẻ đấu giá (`M-AC-01`, `M-AC-02`) và hộp giá trung tâm (`M-AC-03`) đều có đường kẻ nét đứt ngang (`1.5px dashed #B8A892`) kèm 2 vết khuyết bán nguyệt hai bên hông và tông màu điểm nhấn **Đỏ rượu vang ấm (`Vintage Burgundy #873A43`)**, giúp phân biệt ngay trong 1 giây với hàng bán giá cố định (`Forest Pine #294638`).
2. **Đồng hồ đếm ngược không giật chữ & Cảnh báo Anti-Sniping (`BR-AU-01`, `BR-AU-04`):** Toàn bộ bộ đếm thời gian (`HH : MM : SS`) bắt buộc dùng font `JetBrains Mono Bold` (`tabular-nums`) đồng bộ theo mốc `auction_ends_at` từ Server. Khi có lượt trả giá hợp lệ trong **2 phút cuối** (hoặc **30 giây cuối** ở `DEMO_MODE=true`), giao diện bật tức thì dải thông báo vàng hổ phách **`⚡ ĐÃ GIA HẠN ANTI-SNIPING (+2 PHÚT)`** để mọi người mua đều hiểu vì sao đồng hồ được cộng thêm giờ.
3. **Phân biệt rõ trạng thái Cá nhân: `LEADING` vs `OUTBID` vs `WON` (`M-AC-02` & `M-AC-03`):**
   - Đang dẫn đầu (`LEADING`): Huy hiệu xanh rừng thông `#DFF0E6` / `#1F5E3B` kèm icon Vương miện `👑`.
   - Bị vượt giá (`OUTBID`): Huy hiệu đỏ cảnh báo `#FCE6E6` / `#A62B2B` kèm nút kích hoạt đặt giá lại ngay.
   - Đã thắng (`WON`): Huy hiệu vàng đồng `#EED69F` / `#302D2A` kèm đồng hồ đếm ngược hạn thanh toán **30 phút** (`2 phút` ở Demo Mode – `BR-AU-07`).
4. **Đặt giá 1 chạm & Xử lý xung đột đồng thời (`Concurrent Bid UX` – `M-AC-04`):** Cung cấp 3 nút cộng bước giá nhanh (`+1x`, `+2x`, `+5x min_bid_increment`) và hiển thị thông báo cập nhật tức thì nếu xảy ra xung đột `409 Conflict` (khi người khác vừa đặt mức giá đó trước vài mili-giây).
5. **Tách biệt giao diện Chủ sản phẩm & Chốt phiên sớm (`Seller Early Close` – `BR-AC-02`, `BR-AU-05`):** Khi chủ sản phẩm (`auth.id == seller_id`) mở `M-AC-03`, hệ thống ẩn hoàn toàn nút `[Đặt giá thầu]` và thay bằng **Thanh điều khiển của Người bán** có nút **`[⚡ Chốt phiên sớm]`** (chỉ mở khóa khi phiên đang `LIVE`, đã có người dẫn đầu và đạt `reserve_price`).

---

## Chương 2. Đặc Tả High-Fidelity Từng Màn Hình (`M-AC-01` – `M-AC-05`)

### 2.1. Screen `M-AC-01`: Auction Hub (Tab 3 Root – `/auctions`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-AC-01` – Scheduled Auction Hub (`/auctions` – Tab 3 Root) |
| **Purpose** | Trung tâm khám phá toàn bộ các phiên đấu giá hàng ngày chia theo 4 trạng thái thời gian (`Đang diễn ra`, `Sắp kết thúc`, `Sắp mở`, `Đã kết thúc`) và lối tắt vào quản lý đấu giá cá nhân (`FR-AC-01`, `AF-02`). |
| **Entry Point** | Chạm vào **Tab 3 (`🔨 Đấu giá`)** trên thanh Bottom Navigation (`NAV-DEC-01`) hoặc nhấn `[Xem tất cả ->]` từ khu vực Đấu giá trên Trang chủ `M-HM-01`. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `TopAuctionAppBar (Height 56px, Bg #F4EBDD, Border Bottom 1px #E5D9C8)`:<br>   - Trái: Icon `Gavel Fill 22px #873A43` + Tiêu đề `Fraunces 20px Bold #302D2A` (*"Sàn Đấu Giá"*).<br>   - Phải: Nút pill nổi bật **`[👑 Đấu giá của tôi (N)]`** (`Height 34px`, `Bg #FAF5EC`, `Border 1.5px #873A43`, chữ `12px SemiBold #873A43` $\rightarrow$ Mở `M-AC-02`) + `[🔔]`.<br>2. `DailySessionScheduleBanner (Margin 12px 16px, Bg #294638, Border 1px #C79B4B, Radius 12px, Padding 14px 16px)`:<br>   - Hàng 1: Nhãn `11px SemiBold #EED69F` (*"📅 KHUNG GIỜ PHIÊN ĐẤU GIÁ HÔM NAY"*) + Trạng thái `[🔴 PHIÊN TỐI ĐANG LIVE]`.<br>   - Hàng 2 (`Margin Top 6px`): Dải 3 khung giờ phiên trong ngày (`Phiên Trưa 12:00–14:00 [Đã đóng]` \| **`Phiên Tối 20:00–22:00 [Đang LIVE]`** \| `Phiên Đêm 22:00–23:30 [Sắp mở]`).<br>3. `StickyAuctionStatusTabBar (Height 46px, Bg #FAF5EC, Border Bottom 1px #D8CBB8)`:<br>   - **Tab 1:** `🔴 Đang diễn ra (LIVE)`<br>   - **Tab 2:** `⏳ Sắp kết thúc (< 15p)`<br>   - **Tab 3:** `🕒 Sắp mở (Upcoming)`<br>   - **Tab 4:** `🏁 Đã kết thúc`<br>4. `CategoryFilterSubBar (Height 44px, Padding Horizontal 16px)`: Dải pill lọc nhanh theo danh mục (`Tất cả`, `Đồng hồ`, `Túi da`, `Áo khoác`, `Đồ sưu tầm`).<br>5. `Expanded`: `GridView.builder (Padding 16px, 2 Columns, Gutter 12px, ChildAspectRatio 173/326)` hiển thị **`CMP-COM-01 Variant 2 (Auction Ticket Card)`**:<br>   - Trên Tab 1 & 2 (`LIVE` / `Ending Soon`): Dải chân ảnh màu `#873A43` hiển thị `⏳ HH:MM:SS` + `🔥 X lượt trả`, giá hiện tại màu `#873A43`, nút chân vé `[Đặt giá ->]`.<br>   - Trên Tab 3 (`Upcoming / SCHEDULED`): Dải chân ảnh màu `#28557A` hiển thị `🕒 Mở lúc 22:00`, giá khởi điểm màu `#302D2A`, nút chân vé `[👁️ Theo dõi phiên]`.<br>   - Trên Tab 4 (`Completed`): Dải chân ảnh màu xám `#655E57` hiển thị `🏁 Đã chốt phiên`, giá thắng cuối cùng.<br>6. `BottomNavigationBar (Tab 3 'Đấu giá' Active với pill #F4E5E7 & icon #873A43)`. |
| **UI States (`Loading / Empty / Error`)** | - **Loading:** 6 khung xương `Auction Ticket Card`.<br>- **Empty (`Tab 2 – Sắp kết thúc`):** Icon `ClockCountdown 56px #8C837A` + *"Hiện chưa có phiên nào bước vào 15 phút cuối"* + Nút `[Xem các phiên đang LIVE]`.<br>- **Error:** Hiển thị `STATE-ERR-01` kèm nút `[Thử lại]`. |

#### High-Fidelity Visual Preview (`M-AC-01` Auction Hub & `M-AC-02` My Auctions):
```text
      [M-AC-01: SCHEDULED AUCTION HUB]             [M-AC-02: MY PARTICIPATING & WON AUCTIONS]
+---------------------------------------+      +---------------------------------------+
| 🔨 Sàn Đấu Giá  [👑 Của tôi (2)] [🔔] |      | [<-]       Đấu giá của tôi            |
+---------------------------------------+      +---------------------------------------+
| +-----------------------------------+ |      | [Đang đấu (2)*] [Theo dõi (4)] [Thắng (1)]|
| | 📅 KHUNG GIỜ PHIÊN HÔM NAY (#294638)|      +---------------------------------------+
| | [12h: Đóng] [🔴 20h-22h: LIVE] [22h]|      | 🔥 ĐƠN THẮNG ĐẤU GIÁ CHỜ THANH TOÁN   |
| +-----------------------------------+ |      | +-----------------------------------+ |
| [🔴 Đang LIVE*] [⏳ <15p] [🕒 Sắp mở]  |      | | 🏆 BẠN ĐÃ THẮNG PHIÊN #AUC-102!   | |
| Lọc: (Tất cả*) (Đồng hồ) (Túi) (Áo)   |      | | ⏳ Hạn thanh toán: 00 : 24 : 18   | |
| +-----------------+ +---------------+ |      | | [Ảnh] Máy Ảnh Film Canon AE-1     | |
| | [🔴 LIVE]   (👁️)| | [⏳ < 2 phút!] | |      | | Giá thắng: 1.500.000đ (+Phí: 97k) | |
| |                 | | ⚡Anti-Sniping | |      | | [ 💳 THANH TOÁN QR NGAY (M-OR-03)]| |
| | [Ảnh: Seiko 5]  | | [Ảnh: Túi Da] | |      | +-----------------------------------+ |
| +-----------------+ +---------------+ |      |                                       |
| |⏳04:12 | 🔥09 bid| |⏳01:45 | 🔥18 | |      | 🔨 PHIÊN ĐANG THAM GIA TRẢ GIÁ (2)    |
| +-----------------+ +---------------+ |      | +-----------------------------------+ |
| | Đồng Hồ Cơ Seiko| | Túi Da Đeo    | |      | | [⚠️ BỊ VƯỢT GIÁ (OUTBID) #A62B2B] | |
| | 5 Mặt Vuông 1982| | Chéo Coach 90s| |      | | [Ảnh] Túi Da Đeo Chéo Coach 1995  | |
| o - - - - - - - - o o - - - - - - - o |      | | Giá bạn đặt: 1.200.000đ           | |
| | Hiện tại:       | | Hiện tại:     | |      | | Giá dẫn đầu mới: 1.250.000đ       | |
| | 850.000đ        | | 1.250.000đ    | |      | | ⏳ Còn: 01:45  [🔨 Đặt giá lại ->] | |
| | [ 🔨 Đặt giá -> ]| | [🔨 Đặt giá->]| |      | +-----------------------------------+ |
| +-----------------+ +---------------+ |      | +-----------------------------------+ |
|                                       |      | | [👑 BẠN ĐANG DẪN ĐẦU (#1F5E3B)]   | |
|                                       |      | | [Ảnh] Đồng Hồ Cơ Seiko 5 1982     | |
|                                       |      | | Giá dẫn đầu của bạn: 850.000đ     | |
+---------------------------------------+      | | ⏳ Còn: 04:12  [Xem phòng đấu giá >]|
| [Trang chủ][Khám phá][Đấu giá*][Bán][Tôi]|   +---------------------------------------+
+---------------------------------------+
```

---

### 2.2. Screen `M-AC-02`: My Participating, Watchlist & Won Auctions (`/auctions/mine`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-AC-02` – My Auctions: Participating, Watchlist & Won (`/auctions/mine`) |
| **Purpose** | Giúp người mua theo dõi tức thì các phiên mình đang đặt giá (`LEADING` hay `OUTBID`), các phiên đã lưu Watchlist và đặc biệt là xử lý thanh toán đúng hạn **30 phút** cho các phiên **Đã thắng (`Won Auctions`)** (`FR-AC-01`, `FR-AC-05..06`, `AF-02`, `AF-08`). |
| **Entry Point** | Nhấn nút `[👑 Đấu giá của tôi]` trên `M-AC-01`, hoặc mục *"Đấu giá tham gia & Đã thắng"* trên `M-PF-01`. *(Nếu là `Guest`, kích hoạt `Auth Guard` chuyển tới `/login?redirect=/auctions/mine`)*. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `TopAppBar (Height 56px)`: `[<-]` + Tiêu đề `Fraunces 18px SemiBold #302D2A` (*"Đấu giá của tôi"*).<br>2. `Sticky3SubTabBar (Height 48px, Bg #FAF5EC, Border Bottom 1px #D8CBB8)`:<br>   - **`Tab 1: Đang tham gia (Participating)`**<br>   - **`Tab 2: Đang theo dõi (Watchlist)`**<br>   - **`Tab 3: Đã thắng (Won Auctions)`** *(Có chấm đỏ cảnh báo nếu có đơn thắng chưa thanh toán)*.<br>3. `UrgentWonOrderPinnedBanner (Chỉ hiển thị ở đầu Tab 1 và Tab 3 khi có đơn thắng đang ở PENDING_PAYMENT)`:<br>   - Khung viền đôi nổi bật (`Bg #F7EFE0`, `Border 2px solid #C79B4B`, `Radius 12px`, `Padding 16px`):<br>   - Huy hiệu `🏆 CHIẾN THẮNG ĐẤU GIÁ` + Đồng hồ đếm ngược hạn thanh toán 30 phút (`⏳ Còn 00:24:18` font `JetBrains Mono Bold #A62B2B`).<br>   - Thông tin món đồ, Giá thắng (`winning_bid`), Phí bảo vệ người mua (`buyer_protection_fee`) và nút `Primary Button (#294638)`: **`[💳 Thanh toán QR ngay (Hạn 30 phút)]`** ($\rightarrow$ Mở `M-OR-03` / `M-PM-01`).<br>4. `ParticipatingAuctionCardList (Trong Tab 1 – Dạng thẻ ngang cao 148px, Bg #FAF5EC, Radius 12px)`:<br>   - **Trạng thái A – Khi người dùng đang dẫn đầu (`leading_bidder_id == auth.id`):** Viền trái dày `4px solid #1F5E3B`, gắn huy hiệu **`[👑 BẠN ĐANG DẪN ĐẦU]`** (`Bg #DFF0E6`, chữ `#1F5E3B`), hiển thị mức giá của bạn và thời gian còn lại.<br>   - **Trạng thái B – Khi người dùng vừa bị vượt giá (`leading_bidder_id != auth.id` – `AF-05`):** Viền trái dày `4px solid #A62B2B`, gắn huy hiệu **`[⚠️ BỊ VƯỢT GIÁ (OUTBID)]`** (`Bg #FCE6E6`, chữ `#A62B2B`), hiển thị so sánh *Giá bạn đã đặt* vs *Giá dẫn đầu mới* và nút CTA đỏ rượu vang `#873A43`: **`[🔨 Đặt giá lại ngay ->]`** ($\rightarrow$ Mở `M-AC-03`). |
| **Defaulted Winner State (`DEC-02`)** | Trong Tab 3 (`Đã thắng`), nếu đơn hàng đấu giá đã quá 30 phút (2 phút ở Demo Mode) không thanh toán (`order_status == CANCELLED`, `auction.status == WINNER_DEFAULTED`), thẻ chuyển sang nền xám `#EAE3D9` với nhãn đỏ **`[ĐÃ HỦY DO QUÁ HẠN THANH TOÁN 30 PHÚT]`** và khóa nút thanh toán. |

---

### 2.3. Screen `M-AC-03`: Auction Detail & Real-Time Bid Room (`/auctions/:id`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-AC-03` – Auction Detail & Real-Time Bid Room (`/auctions/:id`) |
| **Purpose** | Phòng đấu giá trực tiếp hiển thị đồng hồ đếm ngược thời gian thực chuẩn Server (`BR-AU-01`), cảnh báo gia hạn Anti-Sniping (`BR-AU-04`), bảng giá cuống vé, lịch sử trả giá, phiếu kiểm định tình trạng món đồ và thanh hành động theo đúng vai trò Buyer hoặc Seller (`FR-AC-02..04`, `AF-03`, `AF-06`). |
| **Entry Point** | Chạm vào `Auction Ticket Card` từ `M-HM-01`, `M-DS-02`, `M-AC-01`, `M-AC-02`, hoặc thông báo `Outbid` từ `M-NT-01`. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `TopAuctionRoomAppBar (Height 56px, Bg #F4EBDD)`: `[<-]` + Mã phiên `#AUC-108` (`JetBrains Mono 14px SemiBold`) + Cụm phải `[👁️ WatchBtn]` + `[⋮ ReportBtn -> M-CM-03]`.<br>2. **Sticky Top Countdown & Anti-Sniping Bar (`CMP-AUC-01`):**<br>   - Hàng chính (`Height 48px`, `Padding Horizontal 16px`):<br>     - Khi còn `> 15 phút`: Nền `#E7DAC6`, chữ `#302D2A`.<br>     - Khi còn `<= 15 phút`: Nền `#873A43` (hoặc `#A62B2B` khi `< 2 phút`), chữ `#FAF5EC`.<br>     - Bên trái: Nhãn *"⏳ Thời gian kết thúc phiên:"*; Bên phải: Đồng hồ **`00 : 01 : 45`** (`JetBrains Mono 20px Bold tabular-nums`).<br>   - Hàng phụ Anti-Sniping (`Height 32px`, `Bg #FDECC8`, `Border Bottom 1px #C79B4B`, chỉ bật khi `extended_count > 0` – `AF-04`):<br>     - Icon `Lightning Fill 16px #7A4B0E` + Chữ `12px SemiBold #7A4B0E`: *"⚡ Đã tự động cộng +02:00 chống trả giá giây cuối (Lần gia hạn #1 - BR-AU-04)"*.<br>3. `Expanded CustomScrollView (Bottom Padding 96px)`:<br>   - **Block A – `ProductImageGallery (CMP-COM-03A, AspectRatio 4:5)`:** Giống `M-PR-01`, hỗ trợ chạm mở `M-PR-02` soi chi tiết lỗi.<br>   - **Block B – `AuctionTicketBidBoard (CMP-AUC-02 – Margin 16px, Bg #FAF5EC, Border 1.5px solid #873A43, Radius 12px, Thiết kế Cuống Vé có rãnh nét đứt ngang)`:**<br>     - **Phần Đầu Vé (`Padding 16px`):**<br>       - Tên món đồ đấu giá (`Fraunces 20px Bold #302D2A`) + Nhãn `Số lượng: 01 chiếc duy nhất`.<br>       - Khung Giá Cao Nhất Hiện Tại (`Margin Top 12px`, `Bg #F4E5E7`, `Radius 8px`, `Padding 12px`):<br>         - Nhãn `12px SemiBold #873A43`: *"GIÁ CAO NHẤT HIỆN TẠI (CURRENT HIGHEST BID)"*<br>         - Số tiền lớn: **`850.000 VNĐ`** (`Be Vietnam Pro 26px Bold #873A43 tabular-nums`).<br>         - Dòng người dẫn đầu: Icon `Crown 16px #C79B4B` + *"Người dẫn đầu: minh***"* (Nếu chính là người đang xem thì hiện huy hiệu xanh **`[👑 Bạn đang dẫn đầu!]`**).<br>     - **Rãnh Cuống Vé (`Perforated Divider`):** 2 khuyết bán nguyệt hai bên hông + đường kẻ `1.5px dashed #B8A892`.<br>     - **Phần Chân Vé (`Padding 12px 16px`, Lưới 2x2 thông số đấu giá):**<br>       - *Giá khởi điểm:* `500.000đ` \| *Bước giá tối thiểu:* **`+50.000đ`**<br>       - *Giá đặt tối thiểu tiếp theo:* **`900.000đ`** \| *Trạng thái Giá sàn (`Reserve Price`):* Huy hiệu **`[✓ Đã đạt giá sàn]`** (`#236343`) hoặc **`[Chưa đạt giá sàn]`** (`#945814`).<br>   - **Block C – `LiveBidHistoryPreviewCard (Margin Horizontal 16px, Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 16px)`:**<br>     - Header: Icon `Gavel 18px #302D2A` + *"Lịch sử trả giá (12 lượt)"* + Nút phải **`[Xem tất cả >]`** (mở `M-AC-04`).<br>     - Danh sách 4 lượt trả giá mới nhất: Hạng (`#1`, `#2`...), tên che ẩn danh (`minh***`, `bao_***`), mức giá (`tabular-nums`) và thời gian đặt đến từng giây (`20:41:12`).<br>   - **Block D – `ConditionInspectionSlip (CMP-COM-02)`:** Hiển thị đầy đủ `condition`, `defect_info` và `verification_level` (`BR-PR-03`).<br>   - **Block E – `SellerSummaryEntryCard (CMP-COM-03B)` & `ProductDescriptionSection`.**<br>4. `StickyBottomAuctionActionBar (Height 76px + Safe Area, Bg #FFFDF9, Border Top 1px #D8CBB8, Elevation 2)`. |
| **Sticky Bottom Bar theo 4 Ngữ Cảnh Nghiệp Vụ** | 1. **Khi người xem là Buyer (`auth.id != seller_id`) & Phiên đang `LIVE`:**<br>   - Trái: Thông tin nhắc nhanh *"Tối thiểu: 900.000đ"* (`13px SemiBold #302D2A`).<br>   - Phải (`Expanded`): Nút `Auction CTA Button (CMP-ACT-01 V2, Height 48px, Bg #873A43, Text #FAF5EC)`: **`[🔨 ĐẶT GIÁ THẦU NGAY]`** ($\rightarrow$ Mở `M-AC-04`).<br>2. **Khi người xem là Chủ sản phẩm (`auth.id == seller_id` – `BR-AC-02` & `BR-AU-05`):**<br>   - Ẩn hoàn toàn nút `Đặt giá thầu` (chặn tự bid giá sản phẩm của mình).<br>   - Hiển thị **Seller Auction Control Bar**:<br>     - Nếu đã có `leading_bidder` và `current_highest_bid >= reserve_price`: Mở khóa nút `Primary Button (Bg #294638, Height 48px)`: **`[⚡ CHỐT PHIÊN SỚM VỚI GIÁ 850.000đ]`** ($\rightarrow$ Mở Dialog xác nhận `M-AC-05` – `AF-06`).<br>     - Nếu chưa có người trả giá hoặc chưa đạt giá sàn: Nút ở trạng thái `Disabled` (`Bg #E5DDD2`, chữ `#8C837A`): **`[Chốt phiên sớm (Cần đạt giá sàn)]`**. <br>3. **Khi Phiên đấu giá ở trạng thái `SCHEDULED (Sắp mở)`:**<br>   - Nút `Secondary Outlined Button (Full-width, Height 48px)`: **`[👁️ Theo dõi phiên (Nhận thông báo khi mở)]`**. <br>4. **Khi Phiên đã kết thúc (`COMPLETED` / `ENDED_UNSOLD`):**<br>   - Nếu người xem là Winner (`winner_id == auth.id`): Nút `Primary Button (#294638)`: **`[🏆 Bạn đã thắng! Thanh toán ngay (Còn 28:12)]`** ($\rightarrow$ Mở `M-OR-03`).<br>   - Nếu người xem là người khác: Nút `Disabled`: **`[🏁 Phiên đấu giá đã kết thúc]`**. |

---

### 2.4. Screen `M-AC-04` (Place Bid & Bid History Sheet) & `M-AC-05` (Seller Early Close Dialog)

#### A. `M-AC-04`: Place Bid & Full Bid History Bottom Sheet (`Modal Bottom Sheet`)
- **Cấu trúc 2 Tab trong Bottom Sheet (`MaxHeight 82% Viewport`, `Bg #FFFDF9`, `TopRadius 16px`):**
  - **Tab 1 – `🔨 Đặt giá thầu của bạn`:**
    1. **Tóm tắt thời gian thực ở đầu Sheet:** Giá cao nhất hiện tại (`850.000đ`) \| Bước giá tối thiểu (`+50.000đ`) \| **Mức giá tối thiểu hợp lệ tiếp theo (`900.000 VNĐ`)**.
    2. **Dải 3 Nút Cộng Bước Giá Nhanh (`Quick Increment Pills` – Cao `38px`, `Gap 8px`):**
       - `[ +1 bước (900.000đ) ]` \| `[ +2 bước (950.000đ) ]` \| `[ +5 bước (1.100.000đ) ]` (Chạm vào tự động điền số tiền vào ô Input bên dưới).
    3. **Ô Nhập Số Tiền Đặt Giá (`CMP-FRM-01 V3 Currency Input`, Cao `52px`, Font `20px Bold #873A43 tabular-nums`, Hậu tố `VNĐ`).**
    4. **Hộp Cảnh Báo Cam Kết Đấu Giá (`Bg #F7EFE0`, Viền `1px #E8C28E`, Padding `12px`, `Radius 8px`):**
       - *"⚠️ Quy định đấu giá (`BR-AU-02`, `BR-AU-07`): (1) Lượt trả giá sau khi xác nhận sẽ không thể rút lại hoặc hủy bỏ; (2) Nếu thắng phiên, đơn hàng sẽ tự động được tạo (cộng Phí bảo vệ người mua `DEC-04`) và bạn cần hoàn tất thanh toán QR trong vòng 30 phút."*
    5. **Hộp Báo Lỗi Xung Đột Đồng Thời (`409 Race Condition Alert` – Chỉ hiện khi người khác vừa đặt giá cao hơn trong lúc người dùng đang mở Sheet – `AF-03`):**
       - Khung đỏ `#FCE8E8`, viền `#A62B2B`, chữ `13px SemiBold #A62B2B`: *"⚡ Vừa có người mua khác đặt mức giá 900.000đ trước bạn vài giây! Mức giá tối thiểu mới là 950.000 VNĐ."*
    6. **Nút Xác Nhận (`Auction CTA Button`, Cao `48px`, Full-width, Bg `#873A43`):** **`[🔨 Xác nhận Đặt giá 900.000 VNĐ]`** (Nhấn vào bật `Mandatory Confirmation Dialog` trước khi gửi `POST /auctions/:id/bids`).
  - **Tab 2 – `📜 Toàn bộ Lịch sử trả giá (N lượt)`:** Danh sách phân trang toàn bộ các bản ghi `auction_bids` theo thứ tự từ mới nhất đến cũ nhất.

#### B. `M-AC-05`: Seller Early Close Confirmation Dialog (`Alert Dialog` – `AF-06`, `BR-AU-05`)
- **Cấu trúc Hộp thoại (`CMP-OVL-01`, `Bg #FFFDF9`, `Radius 16px`, `Padding 24px`):**
  - Icon đỉnh: `Gavel Fill 36px #294638`.
  - Tiêu đề (`Fraunces 18px Bold #302D2A`, căn giữa): *"Xác nhận Chốt phiên đấu giá sớm?"*
  - Hộp thông tin chốt phiên (`Bg #E7DAC6`, `Radius 8px`, `Padding 12px`):
    - *Người đang dẫn đầu:* `minh***`
    - *Mức giá chốt bán (`item_subtotal`):* **`850.000 VNĐ`** *(Bạn nhận đủ 100% khi đơn hoàn tất – `DEC-04`)*.
  - Nội dung cảnh báo (`13px Regular #655E57`): *"Phiên đấu giá sẽ đóng lại ngay lập tức. Hệ thống sẽ tự động tạo đơn hàng cho người dẫn đầu với hạn thanh toán 30 phút. Thao tác này được ghi vào nhật ký kiểm toán và không thể hoàn tác."*
  - Cụm 2 nút ngang: **`[Hủy bỏ]`** (`Tertiary`) + **`[⚡ Đồng ý Chốt bán ngay]`** (`Primary #294638` $\rightarrow$ Gọi `POST /auctions/:id/close-early`).