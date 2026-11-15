# 07. MOBILE ENGAGEMENT, CHAT & NOTIFICATIONS UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P303-ENGAGEMENT-UI`
- **Version:** `1.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – Task P3-03 (Group 6A: Engagement, Chat & Notifications)`
- **Screen IDs Covered:** `M-PF-05` (Favorites & Followed Sellers), `M-CM-01` (Conversation List), `M-CM-02` (1-on-1 Chat Room), `M-CM-03` (Report / Block Modal), `M-NT-01` (In-App Notifications Center)
- **Compliance Ref:** `BF-11`, `BF-12`, `FR-DS-04`, `FR-US-04`, `FR-CM-01..02`, `FR-NT-01`, `BR-AC-02`, `NFR-PER-03`, `ADR-08`, `UI-DEC-01..04`, `DS-DEC-01..03`

---

## Chương 1. Kiến Trúc Tương Tác Cộng Đồng, Chat Ngữ Cảnh & Điều Hướng Sâu (`Engagement & Contextual Communication Architecture`)

Cụm 5 màn hình tương tác (`M-PF-05`, `M-CM-01..03`, `M-NT-01`) đóng vai trò là cầu nối giữ chân người dùng và hỗ trợ thương lượng minh bạch giữa Buyer và Seller trên **`izithrift`**:
1. **Quản lý Kho Lưu Trữ Cá Nhân (`Favorites & Followed Shops` – `M-PF-05`):** Khi một món đồ secondhand trong danh sách Yêu thích vừa được người khác mua mất (`SOLD`) hoặc bị ẩn (`HIDDEN`), thẻ sản phẩm không tự biến mất không dấu vết mà chuyển sang `CMP-COM-01 Variant 3 / Variant 4` (hiển thị rõ nhãn `ĐÃ BÁN` hoặc `Ngừng giao dịch` kèm nút xóa nhanh) để người dùng nắm bắt trạng thái thực tế.
2. **Phòng Chat 1-1 Ghim Ngữ Cảnh Sản Phẩm & Đơn Hàng (`Contextual Product/Order Chat` – `M-CM-02`):** Tuân thủ `ADR-08` và `NFR-PER-03`, phòng chat vận hành qua cơ chế **Controlled HTTP Polling (chu kỳ 3–5 giây khi màn hình đang mở, tự động `dispose` ngay khi rời màn hình)** và luôn ghim **Thẻ Ngữ Cảnh Sản Phẩm / Đơn Hàng (`Context Card`)** ở đỉnh khung chat để hai bên biết chính xác đang trao đổi về món đồ nào.
3. **Trung Tâm Thông Báo Điều Hướng Sâu (`Deep-Linked Notification Center` – `M-NT-01`):** Phân loại thông báo bằng icon và màu sắc ngữ nghĩa riêng biệt cho từng nhóm sự kiện (Đấu giá `Outbid / Won`, Đơn hàng & Escrow, Kiểm duyệt sản phẩm, Khiếu nại), chạm vào đi thẳng tới đúng màn hình đích theo Ma trận Điều hướng Chéo (`Chương 7` trong `SITEMAP.md`).

---

## Chương 2. Đặc Tả High-Fidelity Từng Màn Hình (`M-PF-05`, `M-CM-01..03`, `M-NT-01`)

### 2.1. Screen `M-PF-05`: Favorites & Followed Sellers Screen (`/profile/favorites`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-PF-05` – Favorites & Followed Sellers (`/profile/favorites`) |
| **Purpose** | Giúp người dùng quản lý các món đồ đã bấm lưu yêu thích (`Favorite Products`) và danh sách các tiệm đồ si đang theo dõi (`Followed Sellers`) (`FR-DS-04`, `FR-US-04`, `BF-11`). |
| **Entry Point** | Từ `M-PF-01 (Profile Hub)` nhấn mục *"Yêu thích & Đang theo dõi"*. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `TopAppBar (Height 56px, Bg #F4EBDD)`: `[<-]` + Tiêu đề `Fraunces 18px SemiBold #302D2A` (*"Đã lưu & Theo dõi"*) + `[🛒 CartIconBtn]`.<br>2. `StickySegmentedTabBar (Height 48px, Bg #FAF5EC, Border Bottom 1px #D8CBB8)`:<br>   - **`Tab 1: Món đồ yêu thích (12)`**<br>   - **`Tab 2: Tiệm đang theo dõi (05)`**<br>3. `Expanded TabBarView`:<br>   - **Trong Tab 1 (`Favorite Products Grid`):**<br>     - Thanh lọc phụ (`Padding 12px 16px`): `[Tất cả (12)]` \| `[Còn hàng (09)]` \| `[Đấu giá (02)]` \| `[Đã bán / Ngừng GD (03)]`.<br>     - Lưới 2 cột (`Padding 16px, Gutter 12px`) hiển thị `CMP-COM-01`:<br>       - Với món còn hàng: Hiển thị `Variant 1 (Fixed-Price)` hoặc `Variant 2 (Auction Ticket)` với nút Trái tim góc phải đang ở trạng thái tô đặc `Fill #873A43`.<br>       - Với món đã bán (`SOLD`): Hiển thị `Variant 3 (Sold Out Card)`.<br>       - Với món bị ẩn (`HIDDEN`): Hiển thị `Variant 4 (Unavailable Card)` kèm nút nhỏ `[🗑️ Bỏ lưu]`.<br>   - **Trong Tab 2 (`Followed Sellers List`):**<br>     - `ListView.separated (Padding 16px, Gap 12px)`: Mỗi thẻ `FollowedShopCard (Bg #FAF5EC, Border 1px #D8CBB8, Radius 12px, Padding 14px)` gồm: Avatar `48x48px`, Tên Tiệm (`Fraunces 16px SemiBold #302D2A`), Điểm sao `★ 4.9` + Số món đang bán (`"28 món đang bán"`), nút phải **`[Đang theo dõi]`** (`Height 32px`, `Bg #E3ECE7`, chữ `12px SemiBold #294638`) và dải 3 ảnh thu nhỏ (`48x48px`) của các món đồ mới nhất từ tiệm đó. |
| **Main & Secondary Actions** | - Chạm vào `Product Card` (còn hàng hoặc đã bán) $\rightarrow$ Mở `M-PR-01` hoặc `M-AC-03`.<br>- Chạm vào icon `[♥]` đỏ rượu vang trên thẻ $\rightarrow$ Bỏ lưu khỏi danh sách yêu thích (`POST /products/:id/favorite`) kèm Snackbar có nút `[Hoàn tác]`.<br>- Chạm vào `FollowedShopCard` $\rightarrow$ Mở `M-US-03` (`/sellers/:id`).<br>- Chạm vào nút `[Đang theo dõi]` $\rightarrow$ Hiện Confirmation Dialog xác nhận hủy theo dõi tiệm. |
| **UI States (`Loading / Empty / Error`)** | - **Loading:** 4 khung xương `Product Card` (Tab 1) hoặc 4 khung xương ngang `FollowedShopCard` (Tab 2).<br>- **Empty (`Tab 1`):** Icon `Heart 56px #8C837A` + *"Bạn chưa lưu món đồ yêu thích nào"* + Nút `[Khám phá đồ si ngay ->]` ($\rightarrow$ `M-DS-01`).<br>- **Empty (`Tab 2`):** Icon `Storefront 56px #8C837A` + *"Bạn chưa theo dõi tiệm đồ si nào"* + Nút `[Xem các tiệm uy tín ->]` ($\rightarrow$ `M-HM-01`). |

---

### 2.2. Screen `M-CM-01`: Conversation List – Chat Inbox (`/chat`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-CM-01` – Conversation List / 1-on-1 Chat Inbox (`/chat`) |
| **Purpose** | Hiển thị danh sách toàn bộ các cuộc trò chuyện 1-1 giữa người dùng với các Người mua / Người bán khác, làm nổi bật tin nhắn chưa đọc và sản phẩm đang trao đổi (`FR-CM-01`, `BF-12`). |
| **Entry Point** | Nhấn vào icon **`[💬 Chat]`** trên `Global Top Utility Bar` từ bất kỳ màn hình nào. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `TopAppBar (Height 56px, Bg #F4EBDD, Border Bottom 1px #E5D9C8)`: `[<-]` + Tiêu đề `Fraunces 18px SemiBold #302D2A` (*"Hộp thư trò chuyện"*).<br>2. `SearchConversationBar (Padding 12px 16px)`: Ô tìm nhanh theo tên đối phương hoặc tên sản phẩm (`Height 40px, Bg #FAF5EC, Radius 8px`).<br>3. `Expanded ListView.separated (Divider 1px #E5D9C8)`:<br>   - Mỗi dòng `ConversationListItem (Height 84px, Padding 12px 16px, Bg #FAF5EC khi chưa đọc / Bg #F4EBDD khi đã đọc)`:<br>     - **Trái:** Avatar đối phương `48x48px` (`Radius 9999px`, viền `1px #D8CBB8`).<br>     - **Giữa (`Expanded`):**<br>       - Hàng 1: Tên đối phương (`15px SemiBold #302D2A`) + Nhãn vai trò ngữ cảnh nhỏ (`[Tiệm bán]` màu `#294638` hoặc `[Khách mua]` màu `#8C5A1B`).<br>       - Hàng 2 (`Margin Top 4px`): Nội dung tin nhắn cuối cùng (`13px SemiBold #302D2A` nếu chưa đọc / `13px Regular #655E57` nếu đã đọc, 1 dòng `ellipsis`).<br>       - Hàng 3 (`Margin Top 4px`): Dòng ngữ cảnh sản phẩm nhỏ (`11px Medium #8C837A`: *"Đang hỏi: Áo Khoác Dạ Tweed..."*).<br>     - **Phải ( rộng `64px`, căn phải):**<br>       - Thời gian tin nhắn cuối (`11px Regular #8C837A tabular-nums`: `10:42` hoặc `12/11`).<br>       - Dưới thời gian: Ảnh vuông thu nhỏ của sản phẩm ngữ cảnh (`32x32px, Radius 4px`) kèm chấm badge đếm tin chưa đọc (`18x18px #873A43`, chữ `#FAF5EC 10px Bold`). |
| **UI States (`Loading / Empty / Error`)** | - **Loading:** 6 dòng Shimmer ngang cao `84px`.<br>- **Empty (`STATE-EMP-01`):** Icon `ChatCircleDots 56px #8C837A` + *"Chưa có cuộc trò chuyện nào"* + Mô tả: *"Khi bạn nhấn 'Chat với Tiệm' từ trang sản phẩm hoặc đơn hàng, cuộc trò chuyện sẽ xuất hiện tại đây."* |

---

### 2.3. Screen `M-CM-02`: 1-on-1 Chat Room (with HTTP Polling & Pinned Context Card – `/chat/:id`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-CM-02` – 1-on-1 Chat Room (`/chat/:id`) |
| **Purpose** | Giao diện nhắn tin trực tiếp giữa Buyer và Seller để hỏi chi tiết vết xước, số đo sản phẩm hoặc trao đổi tình trạng đơn hàng; đồng bộ tin nhắn qua HTTP Polling có kiểm soát (`FR-CM-01`, `ADR-08`, `NFR-PER-03`). |
| **Entry Point** | Chạm vào một hội thoại từ `M-CM-01`, hoặc nhấn nút `[💬 Chat]` từ `M-PR-01`, `M-US-03`, `M-OR-03`, `M-SL-06`. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD, resizeToAvoidBottomInset: true)`:<br>1. `TopChatRoomAppBar (Height 56px, Bg #FAF5EC, Border Bottom 1px #D8CBB8)`:<br>   - Trái: `BackIconButton [<-]` + Avatar đối phương `36x36px` + Tên đối phương (`15px SemiBold #302D2A`) & Điểm uy tín (`★ 4.9`).<br>   - Phải: `[🏪 Xem Tiệm -> M-US-03]` + `[⋮ Báo cáo / Chặn -> M-CM-03]`.<br>2. **Pinned Context Banner – `ProductOrOrderContextCard (Height 68px, Bg #E7DAC6, Border Bottom 1px #B8A892, Padding 10px 16px)`:**<br>   - Trái: Ảnh sản phẩm `48x48px` (`Radius 6px`).<br>   - Giữa: Nhãn *"Đang trao đổi về sản phẩm:"* (`11px #655E57`) + Tên sản phẩm (`13px SemiBold #302D2A`, 1 dòng) + Giá bán (`13px Bold #294638 tabular-nums`) + Tình trạng (`[Good]`).<br>   - Phải: Nút nhỏ **`[Xem món đồ >]`** (`Height 28px`, mở `M-PR-01`).<br>3. **Safety Notice Pill (Đặt ở đầu luồng tin nhắn, căn giữa):**<br>   - Khung nền `#F7EFE0`, viền `1px #E8C28E`, `Radius 8px`, `Padding 8px 12px`, chữ `11px Regular #6B4F1D`: *"🛡️ Lưu ý an toàn: Luôn đặt hàng và thanh toán trực tiếp trên ứng dụng izithrift để được giữ tiền bảo vệ trong sổ cái Escrow. Tuyệt đối không chuyển khoản riêng bên ngoài."*<br>4. **Message Stream (`Expanded ListView.builder`, `reverse: true`, `Padding 16px`):**<br>   - **Bong bóng tin nhắn của Đối phương (`Incoming Bubble` – Căn trái, `MaxWidth 75%`):** Nền `#FAF5EC`, viền `1px solid #D8CBB8`, bo góc `TopLeft 4px, TopRight 12px, BottomLeft 12px, BottomRight 12px`, chữ `15px Regular #302D2A`, thời gian gửi dưới chân `11px #8C837A tabular-nums`.<br>   - **Bong bóng tin nhắn của Bản thân (`Outgoing Bubble` – Căn phải, `MaxWidth 75%`):** Nền `Forest Pine #294638`, chữ `15px Regular #FAF5EC`, bo góc `TopLeft 12px, TopRight 4px, BottomLeft 12px, BottomRight 12px`, kèm nhãn trạng thái dưới chân (`11px #655E57`: `Đang gửi...` $\rightarrow$ `Đã gửi` $\rightarrow$ `✓✓ Đã xem`).<br>5. **Bottom Composer Bar (`MinHeight 64px + Safe Area`, `Bg #FAF5EC`, `Border Top 1px #D8CBB8`, `Padding 8px 12px`):**<br>   - Ô nhập tin nhắn đa dòng (`MinHeight 44px, MaxHeight 100px, Bg #FFFDF9, Border 1px #D8CBB8, Radius 22px, Padding Horizontal 16px, Font 15px #302D2A`).<br>   - Nút Gửi bên phải (`44x44px CircleButton`, nền `#294638` khi có chữ / nền `#E5DDD2` Disabled khi ô nhập trống, icon `PaperPlaneRight Fill 20px #FAF5EC`). |
| **HTTP Polling Lifecycle (`NFR-PER-03`)** | - Trong `initState()` của `M-CM-02`: Khởi tạo `Timer.periodic(Duration(seconds: 4))` gọi `GET /conversations/:id/messages?after_id=...` để lấy tin nhắn mới và cập nhật `is_read`.<br>- Trong `dispose()` hoặc khi ứng dụng chuyển xuống nền (`AppLifecycleState.paused`): **Hủy ngay lập tức `Timer.cancel()`** để không gây rò rỉ bộ nhớ hoặc tốn tài nguyên máy chủ. |
| **UI States (`Blocked / Rate Limited / Error`)** | - **Blocked State:** Nếu một trong hai bên đã bấm Chặn (`is_blocked == true`), thay thế `Bottom Composer Bar` bằng thanh thông báo khóa (`Bg #EAE3D9`, chữ `13px SemiBold #655E57`): *"🔒 Cuộc trò chuyện này đã bị chặn. Không thể gửi thêm tin nhắn"* kèm nút `[Bỏ chặn]` (nếu người xem là người đã bấm chặn).<br>- **Rate Limit (`429`):** Nếu gửi quá 60 tin/phút, hiện Toast cảnh báo *"Bạn đang gửi tin nhắn quá nhanh, vui lòng chờ vài giây"*. |

#### High-Fidelity Visual Preview (`M-CM-01` Inbox & `M-CM-02` 1-on-1 Chat Room):
```text
      [M-CM-01: CHAT INBOX LIST]                    [M-CM-02: 1-ON-1 CHAT ROOM]
+---------------------------------------+      +---------------------------------------+
| [<-]       Hộp thư trò chuyện         |      | [<-] (Avt) Tiệm Nhà Gấu ★4.9 [🏪] [⋮] |
+---------------------------------------+      +---------------------------------------+
| [ 🔍 Tìm tên tiệm, món đồ...        ] |      | [Ảnh] Đang hỏi: Áo Khoác Dạ Tweed     |
+---------------------------------------+      | 48x48 450.000đ • [Good]  [Xem món >]  | <-- Pinned Context Card (#E7DAC6)
| (Avt) Tiệm Đồ Si Nhà Gấu [Tiệm] 10:42 |      +---------------------------------------+
|       "Vết xước ở cúc áo thứ 2 rất    |      | +-----------------------------------+ |
|        nhỏ thôi bạn ạ, mình gửi..."   |      | | 🛡️ Luôn thanh toán trên izithrift | |
|       Đang hỏi: Áo Khoác Dạ  [Ảnh][2] |      | | để được bảo vệ tiền trong Escrow. | |
+---------------------------------------+      | +-----------------------------------+ |
| (Avt) Retro Watch SG     [Tiệm] Hôm qua|     |                                       |
|       "Đồng hồ cơ Seiko vẫn chạy chuẩn|      |        +----------------------------+ |
|        giờ, sai số dưới 10s/ngày."    |      |        | Chào shop, áo dạ này phần  | |
|       Đang hỏi: Seiko 5 1982 [Ảnh]    |      |        | cúc thứ 2 bị xước có lộ rõ | |
+---------------------------------------+      |        | lắm không ạ? (Bg #294638)  | |
| (Avt) Trần Bảo Ngọc     [Khách] 10/11 |      |        +----------------------------+ |
|       "Mình đã nhận được áo và bấm    |      |                    10:40 • ✓✓ Đã xem  |
|        xác nhận nhận hàng rồi nhé!"   |      | +----------------------------+        |
|       Đơn: #ORD-2026-0812    [Ảnh]    |      | | (Bg #FAF5EC) Vết xước ở    |        |
+---------------------------------------+      | | viền cúc rất nhỏ thôi bạn  |        |
|                                       |      | | ạ, mặc lên hoàn toàn không |        |
|                                       |      | | thấy rõ đâu nhé!           |        |
|                                       |      | +----------------------------+        |
|                                       |      | 10:42                                 |
+---------------------------------------+      +---------------------------------------+
|                                       |      | [ Nhập tin nhắn...            ] (➤)   | <-- Composer Bar + Send (#294638)
+---------------------------------------+      +---------------------------------------+
```

---

### 2.4. Screen `M-CM-03`: Report Violation / Block User Bottom Sheet (`Modal Bottom Sheet`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-CM-03` – Report Violation / Block User Modal *(Modal Bottom Sheet)* |
| **Purpose** | Cho phép người dùng báo cáo sản phẩm vi phạm (`PRODUCT`), báo cáo người dùng (`USER`) hoặc báo cáo/chặn cuộc trò chuyện lừa đảo (`CONVERSATION`) gửi thẳng tới hàng chờ của Moderator (`A-CM-01`) (`FR-CM-02`). |
| **Entry Point** | Nhấn nút `[⋮]` góc phải trên `M-PR-01`, `M-US-03`, hoặc `M-CM-02`. |
| **Layout & Component Hierarchy** | `ModalBottomSheet (Bg #FFFDF9, TopRadius 16px, Padding 16px)`:<br>1. `SheetHeader`: Tiêu đề `Fraunces 18px SemiBold #302D2A` (*"Báo cáo vi phạm cộng đồng"*) + Nút `[✕]`.<br>2. `TargetSummaryBox (Bg #E7DAC6, Radius 8px, Padding 10px)`: Hiển thị tên đối tượng đang bị báo cáo (Sản phẩm / Tiệm / Hội thoại).<br>3. `ReasonRadioGroup (Gap 8px)` – Chọn 1 lý do bắt buộc:<br>   - `(◉) Lừa đảo / Gạ chuyển khoản riêng ngoài hệ thống Escrow`<br>   - `( ) Sản phẩm giả mạo / Không đúng sự thật`<br>   - `( ) Che giấu khuyết điểm nghiêm trọng / Ảnh mạng không phải ảnh thật`<br>   - `( ) Ngôn từ xúc phạm, quấy rối hoặc Spam`<br>   - `( ) Lý do khác`<br>4. `DetailDescriptionInput (CMP-FRM-01 Multiline, Height 88px)`: Nhập mô tả chi tiết hành vi vi phạm (Required).<br>5. `BlockUserSwitchTile (Chỉ hiển thị khi mở từ M-CM-02 hoặc M-US-03)`: Công tắc `Switch` (*"Đồng thời chặn người dùng này nhắn tin cho tôi"*).<br>6. `SubmitDestructiveButton (CMP-ACT-01 V5, Height 48px, Full-width, Bg #A62B2B)`: **`[Gửi Báo Cáo Cho Kiểm Duyệt Viên]`**. |

---

### 2.5. Screen `M-NT-01`: In-App Notifications Center (`/notifications`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `M-NT-01` – In-App Notifications Center (`/notifications`) |
| **Purpose** | Hiển thị tập trung toàn bộ thông báo hệ thống thời gian thực (Đấu giá, Đơn hàng & Escrow, Kiểm duyệt sản phẩm, Khiếu nại) và điều hướng sâu tới đúng màn hình nghiệp vụ khi chạm vào (`FR-NT-01`). |
| **Entry Point** | Nhấn icon **`[🔔 Thông báo]`** trên `Global Top Utility Bar`. |
| **Layout & Component Hierarchy** | `Scaffold (Bg #F4EBDD)`:<br>1. `TopAppBar (Height 56px, Bg #F4EBDD)`: `[<-]` + Tiêu đề `Fraunces 18px SemiBold #302D2A` (*"Thông báo"*) + Nút chữ phải **`[Đọc tất cả]`** (`13px SemiBold #294638`).<br>2. `CategoryFilterChipsRow (Height 48px, Bg #FAF5EC, Border Bottom 1px #D8CBB8, Padding Horizontal 16px)`:<br>   - 4 Pill lọc nhanh: `[Tất cả]` \| `[🔨 Đấu giá]` \| `[📦 Đơn hàng & Escrow]` \| `[🛡️ Kiểm duyệt & Hệ thống]`.<br>3. `Expanded ListView.separated (Divider 1px #E5D9C8)`:<br>   - Mỗi thẻ `NotificationItemTile (Padding 14px 16px, Bg #FAF5EC nếu chưa đọc kèm chấm tròn 8px #873A43 bên phải / Bg #F4EBDD nếu đã đọc)`:<br>     - **Khung Icon Ngữ nghĩa bên trái (`40x40px, Radius 10px`):**<br>       - *Bị vượt giá (`AUCTION_OUTBID`):* Nền `#FCE6E6`, Icon `Gavel 20px #A62B2B`.<br>       - *Thắng đấu giá (`AUCTION_WON`):* Nền `#EED69F`, Icon `Crown 20px #302D2A`.<br>       - *Thanh toán & Giữ tiền (`ESCROW_HELD` / `RELEASED`):* Nền `#DDF0F0`, Icon `ShieldCheck 20px #1C5858`.<br>       - *Bài đăng được duyệt (`PRODUCT_APPROVED`):* Nền `#E3F2EA`, Icon `SealCheck 20px #236343`.<br>       - *Bài đăng bị từ chối (`PRODUCT_REJECTED` – `DEC-05`):* Nền `#FCE8E8`, Icon `NotePencil 20px #A62B2B`.<br>       - *Khiếu nại (`DISPUTE_UPDATE`):* Nền `#F4E4F0`, Icon `Scales 20px #6A2C5A`.<br>     - **Khối Nội dung ở giữa:** Tiêu đề thông báo (`14px SemiBold #302D2A`), nội dung tóm tắt (`13px Regular #655E57`, 2 dòng), thời gian (`11px #8C837A tabular-nums`) và nhãn hành động gợi ý (`"Chạm để đặt giá lại ->"`, `"Chạm để thanh toán trong 30 phút ->"`). |
| **Deep-Linking Navigation Rules (`SITEMAP.md Chương 7`)** | Khi chạm vào thông báo, gọi `POST /notifications/:id/read` và điều hướng theo `target_type`:<br>- `AUCTION_OUTBID` $\rightarrow$ Mở `M-AC-03` (`/auctions/:target_id`).<br>- `AUCTION_WON` $\rightarrow$ Mở `M-OR-03` (`/profile/orders/:order_id` kèm đếm ngược 30 phút).<br>- `PRODUCT_REJECTED` $\rightarrow$ Mở `M-SL-04` (`/seller/products/:target_id/moderation`).<br>- `ORDER_STATUS / ESCROW` $\rightarrow$ Mở `M-OR-03` (nếu là Buyer) hoặc `M-SL-06` (nếu là Seller).<br>- `DISPUTE_UPDATE` $\rightarrow$ Mở `M-DP-03` (`/profile/disputes/:target_id`). |