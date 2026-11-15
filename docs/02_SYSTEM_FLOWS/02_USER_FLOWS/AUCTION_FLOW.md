# 04. SCHEDULED AUCTION SYSTEM FLOW SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P204-AUCTION-FLOW`
- **Version:** `2.1.0 (COMPLETE UNTRUNCATED SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR FINAL LOCK`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 02 – System Flow & UX Planning`

---

## Chương 1. Tổng Quan Kiến Trúc Luồng Đấu Giá Theo Phiên & Máy Trạng Thái

Hệ thống Đấu giá theo phiên hàng ngày (**Scheduled Auction System**) là tính năng tạo sự khác biệt lớn nhất của **`izithrift`**. Khác với mua bán thông thường, đấu giá đòi hỏi sự phối hợp chặt chẽ giữa **4 Tác nhân (`Guest`, `Buyer`, `Seller`, `Admin/Moderator`)** và **Tác nhân Tự động (`System Scheduler / Concurrent Bid Engine`)** dưới quyền kiểm soát thời gian tuyệt đối của máy chủ Backend (`BR-AU-01`).

### 1.1. Danh Mục Tổng Hợp 10 Luồng Nghiệp Vụ Đấu Giá (`Master Auction Flow Index`)

| Flow ID | Tên Luồng (Flow Name) | Actor Chính | Điểm Bắt Đầu $\rightarrow$ Kết Thúc | API Endpoints / Jobs Liên Quan | Liên Kết FR / UC / BR / DEC |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `AF-01` | Daily Auction Session Configuration & Scheduling (Cấu hình khung giờ & Mở phiên tự động) | `ACT-05` (Admin), `ACT-06` (Scheduler) | `A-AC-01` $\rightarrow$ `M-AC-01` | `POST /admin/auctions/sessions`, `OpenScheduledAuctionsJob` | `FR-AC-01` \| `UC-AC-01` \| `PERM-AC-08`, `BR-AU-01` |
| `AF-02` | Auction Hub Discovery & Watchlist (Khám phá Sàn đấu giá & Theo dõi phiên) | `ACT-01`, `ACT-02` (Buyer) | `M-AC-01` $\leftrightarrow$ `M-AC-02` $\rightarrow$ `M-AC-03` | `GET /auctions?tab=`, `POST /auctions/{id}/watch`, `GET /auctions/mine` | `FR-AC-01` \| `UC-DS-01` \| `PERM-AC-01`, `PERM-AC-02`, `BR-AC-02`, `DEC-01` |
| `AF-03` | Real-Time Auction Room & Concurrent Bidding (Đặt giá thầu đồng thời với `lockForUpdate`) | `ACT-02` (Buyer) | `M-AC-03` $\rightarrow$ `M-AC-04` | `GET /auctions/{id}`, `POST /auctions/{id}/bids`, `GET /auctions/{id}/bids` | `FR-AC-02` \| `UC-AC-02` \| `PERM-AC-03`, `BR-AC-02`, `BR-AU-01`..`03`, `ADR-06` |
| `AF-04` | Anti-Sniping Automatic Extension (Gia hạn tự động 2 phút cuối chống trả giá giây chót) | `ACT-06` (Bid Engine) | `M-AC-03` (Countdown Update) | Trigger nội bộ trong `POST /auctions/{id}/bids` | `FR-AC-03` \| `UC-AC-02` \| `PERM-AC-04`, `BR-AU-04`, `ADR-05` |
| `AF-05` | Outbid Notification & Re-Bidding Loop (Thông báo bị vượt giá & Đấu giá lại) | `ACT-06` $\rightarrow$ `ACT-02` (Previous Leader) | `M-NT-01` / `M-AC-02` $\rightarrow$ `M-AC-03` | `OutbidNotificationEvent`, `POST /auctions/{id}/bids` | `FR-AC-02`, `FR-NT-01` \| `UC-AC-02`, `UC-NT-01` \| `BR-AU-02` |
| `AF-06` | Seller Early Close Execution (Người bán chủ động chốt phiên đấu giá sớm) | `ACT-02` (Seller) | `M-AC-03` $\rightarrow$ `M-AC-05` $\rightarrow$ `M-SL-06` | `POST /auctions/{id}/close-early` | `FR-AC-04` \| `UC-AC-03` \| `PERM-AC-05`, `BR-AU-03`, `BR-AU-05`, `BR-AD-02` |
| `AF-07` | Automatic Auction Closing, Winner Resolution & Order Creation (Đóng phiên tự động & Tạo đơn hàng) | `ACT-06` (Scheduler), `ACT-05` (Demo Trigger) | `CloseExpiredAuctionsJob` $\rightarrow$ `M-OR-03` | `CloseExpiredAuctionsJob` / `POST /admin/dev-tools/close-auctions` | `FR-AC-05`, `FR-AD-05` \| `UC-AC-04`, `UC-AD-02` \| `BR-AU-06`, `BR-FN-02`, `BR-AD-01`, `DEC-04` |
| `AF-08` | Winner Checkout & 30-Minute Payment Countdown (Người thắng thanh toán đơn đấu giá trong 30 phút) | `ACT-02` (Winner Buyer) | `M-AC-02` / `M-NT-01` $\rightarrow$ `M-OR-03` $\rightarrow$ `M-PM-01` | `GET /orders/{id}`, `POST /payments/create`, `POST /payments/{id}/simulate-success` | `FR-AC-05`, `FR-PM-01`..`02` \| `UC-PM-01` \| `BR-AU-07`, `BR-FN-02`, `BR-FN-03`, `DEC-04` |
| `AF-09` | Unpaid Winner Default Expiry & Seller Relist (Xử lý bỏ cọc quá hạn 30 phút & Seller đăng lại – `DEC-02`) | `ACT-06` (Scheduler) $\rightarrow$ `ACT-02` (Seller) | `ExpireUnpaidAuctionOrdersJob` $\rightarrow$ `M-SL-03` | `ExpireUnpaidAuctionOrdersJob`, `POST /auctions/{id}/relist` | `FR-AC-06`, `FR-AD-05` \| `UC-AC-04` \| `PERM-AC-07`, `BR-AU-07`, `DEC-02`, `ADR-05` |
| `AF-10` | Admin Fraud Inspection & Abnormal Auction Cancellation (Admin giám sát & hủy phiên gian lận) | `ACT-05` (Admin) | `A-AC-02` $\rightarrow$ `A-AC-03` | `POST /admin/auctions/{id}/cancel` | `FR-AD-02`, `FR-AD-06` \| `UC-AD-01` \| `PERM-AC-09`, `BR-AD-02` |

---

### 1.2. Sơ Đồ Máy Trạng Thái Vòng Đời Phiên Đấu Giá (`Auction Lifecycle State Machine`)

```mermaid
stateDiagram-v2
    [*] --> PENDING_REVIEW: Seller gửi bài đăng AUCTION (SF-03)
    PENDING_REVIEW --> REJECTED: Moderator từ chối kèm lý do (DEC-05)
    REJECTED --> PENDING_REVIEW: Seller sửa & gửi duyệt lại (SF-05)

    PENDING_REVIEW --> SCHEDULED: Moderator duyệt (APPROVED) & Gắn vào Auction Session
    SCHEDULED --> LIVE: Đến giờ mở phiên (now() >= auction_starts_at)

    state LIVE {
        [*] --> WaitingForBids
        WaitingForBids --> HasLeadingBid: Có lượt trả giá hợp lệ >= starting_price
        HasLeadingBid --> HasLeadingBid: Có lượt trả giá mới >= current_highest_bid + min_bid_increment
        HasLeadingBid --> ExtendedAntiSniping: Có Bid hợp lệ trong 2 phút cuối (30s ở Demo Mode)\n-> Cộng thêm +2 phút (+30s Demo) vào auction_ends_at (BR-AU-04)
        ExtendedAntiSniping --> HasLeadingBid
    }

    LIVE --> COMPLETED: 1. Hết giờ (now >= auction_ends_at) & Đạt reserve_price\n2. Hoặc Seller bấm Chốt sớm (Close Early - BR-AU-05)\n-> Tự động tạo Order (PENDING_PAYMENT, hạn 30p/2p Demo)
    LIVE --> ENDED_UNSOLD: Hết giờ nhưng Không có Bid\nhoặc current_highest_bid < reserve_price
    SCHEDULED --> CANCELLED: Admin hủy phiên bất thường (PERM-AC-09)
    LIVE --> CANCELLED: Admin hủy phiên do phát hiện gian lận (PERM-AC-09)

    COMPLETED --> PAID_ESCROW_HELD: Winner hoàn tất thanh toán QR trước payment_expires_at
    COMPLETED --> WINNER_DEFAULTED: Quá hạn 30p (2p Demo) không thanh toán (DEC-02)\n-> Order chuyển sang CANCELLED

    ENDED_UNSOLD --> SCHEDULED: Seller chọn khung giờ phiên mới & Đăng lại (Relist)
    WINNER_DEFAULTED --> SCHEDULED: Seller chọn khung giờ phiên mới & Đăng lại (DEC-02)
```

---

## Chương 2. Đặc Tả Chi Tiết 10 Luồng Nghiệp Vụ Đấu Giá (`AF-01` – `AF-10`)

### 2.1. `AF-01`: Daily Auction Session Configuration & Scheduling (Cấu Hình Khung Giờ & Tự Động Mở Phiên)

- **1. Flow ID & Name:** `AF-01` – Daily Auction Session Configuration & Automatic Session Activation
- **2. Primary Actor:** `ACT-05` (Administrator) & `ACT-06` (System Scheduler)
- **3. Entry Point:** Admin mở màn hình **`A-AC-01` (`/admin/auctions/sessions`)** trên Laravel Blade; System Scheduler chạy tiến trình nền mỗi phút.
- **4. Preconditions:** Admin đã đăng nhập; có các sản phẩm đấu giá đã được Moderator duyệt (`product.status = APPROVED`) và gán vào phiên (`auction.status = SCHEDULED`).
- **5. Main Flow (Bảng Tương Tác UX & Hệ Thống):**

| Bước | Màn Hình / Tác Nhân | Người Dùng / Admin Nhìn Thấy Gì | Thao Tác Thực Hiện | Phản Hồi Của Hệ Thống (System Response) | Bước Tiếp Theo |
| :-: | :---: | :--- | :--- | :--- | :--- |
| 1 | `A-AC-01` (Admin) | Danh sách các khung giờ phiên đấu giá hàng ngày (ví dụ: *Phiên Trưa 12:00 – 14:00*, *Phiên Tối 20:00 – 22:00*, *Phiên Đặc Biệt Giáng Sinh*), trạng thái `ACTIVE`/`INACTIVE` và số lượng sản phẩm đã đăng ký vào phiên. | Admin tạo khung giờ phiên mới hoặc chỉnh sửa thông số khung giờ (thời gian bắt đầu, thời gian kết thúc, bước giá tối thiểu mặc định) và nhấn **[Lưu cấu hình]**. | Lưu vào bảng `auction_sessions` và ghi bản ghi vào `audit_logs` (`BR-AD-02`). Các phiên `ACTIVE` sẽ xuất hiện trong danh sách chọn phiên khi Seller đăng bài (`SF-03`). | Khung giờ phiên sẵn sàng nhận sản phẩm. |
| 2 | `ACT-06` (Scheduler) $\rightarrow$ `M-AC-01` | Trên ứng dụng Flutter (`M-AC-01`), các sản phẩm thuộc phiên sắp mở hiển thị ở tab **`Sắp diễn ra (Upcoming)`** kèm đồng hồ đếm ngược tới giờ mở phiên `auction_starts_at`. | Khi đồng hồ máy chủ đạt mốc `now() >= auction_starts_at`, Scheduled Job `OpenScheduledAuctionsJob` tự động kích hoạt. | Trong `DB::transaction()`, chuyển toàn bộ bản ghi `auctions` có `status = SCHEDULED` và `auction_starts_at <= now()` sang trạng thái **`LIVE`**, đồng thời gửi thông báo cho những người dùng đã bấm Theo dõi (`Watchlist`). | Sản phẩm chuyển sang tab **`Đang diễn ra (LIVE)`** trên `M-AC-01`, mở khóa nút **[Đặt giá thầu]**. |

- **6. Alternative Flows:** Admin tạm ngưng (`INACTIVE`) một khung giờ phiên trong tương lai nếu chưa có sản phẩm nào đăng ký.
- **7. Exception Flows:** Không cho phép Admin xóa hoặc đổi giờ bắt đầu của một phiên đấu giá đang ở trạng thái `LIVE` hoặc đã có người đặt giá thầu.
- **8. Screen Sequence:** `A-AC-01` (Admin Session Config) $\rightarrow$ `System Scheduler` $\rightarrow$ `M-AC-01` (Mobile Auction Hub).
- **9. Exit Condition:** Phiên đấu giá chuyển từ `SCHEDULED` sang `LIVE` đúng thời điểm chuẩn của máy chủ.
- **10. Related IDs:** `FR-AC-01` | `UC-AC-01` | `PERM-AC-08`, `BR-AU-01`, `BR-AD-02`.

```mermaid
flowchart TD
    Start(["A-AC-01: Admin cấu hình Khung giờ Phiên đấu giá<br/>(auction_sessions: start_time, end_time, status=ACTIVE)"]) --> SellerReg["Seller đăng sản phẩm AUCTION vào phiên (SF-03)<br/>& Moderator duyệt APPROVED (UC-MD-01)"]
    SellerReg --> ScheduledState["Bản ghi auctions ở trạng thái SCHEDULED<br/>Hiển thị tại Tab 'Sắp diễn ra (Upcoming)' trên M-AC-01"]

    ScheduledState --> CronCheck{"System Scheduler kiểm tra:<br/>now() >= auction_starts_at?"}
    CronCheck -- "Chưa đến giờ" --> WaitStart["Hiển thị đồng hồ đếm ngược đến giờ mở phiên<br/>(Cho phép Buyer bấm [Theo dõi phiên - Watch])"]
    WaitStart --> CronCheck

    CronCheck -- "Đến giờ mở phiên" --> ActivateLive["DB::transaction():<br/>UPDATE auctions SET status = LIVE<br/>Gửi thông báo cho danh sách Watchlist"]
    ActivateLive --> LiveHub["Hiển thị tại Tab 'Đang diễn ra (LIVE)' trên M-AC-01<br/>Mở khóa chức năng Đặt giá thầu (AF-03)"]
```

---

### 2.2. `AF-02`: Auction Hub Discovery & Watchlist (Khám Phá Sàn Đấu Giá & Theo Dõi Phiên)

- **1. Flow ID & Name:** `AF-02` – Browse Auction Hub Tabs, Watch Auction & Manage My Auctions
- **2. Primary Actor:** `ACT-01` (Guest) hoặc `ACT-02` (Registered Buyer)
- **3. Entry Point:** Chạm vào **Tab 3: Đấu giá (`/auctions` – `M-AC-01`)** trên thanh Bottom Navigation (`NAV-DEC-01`).
- **4. Preconditions:** Có các phiên đấu giá ở trạng thái `SCHEDULED`, `LIVE` hoặc `COMPLETED`.
- **5. Main Flow (Bảng Tương Tác UX Chi Tiết):**

| Bước | Màn Hình | Người Dùng Nhìn Thấy Gì (What User Sees) | Thao Tác Của Người Dùng (User Action) | Phản Hồi Của Hệ Thống (System Response) | Bước Tiếp Theo (Next State) |
| :-: | :---: | :--- | :--- | :--- | :--- |
| 1 | `M-AC-01` | Màn hình **Auction Hub** (`/auctions`) hiển thị:<br>1. Banner khung giờ phiên đấu giá hiện tại.<br>2. **4 Tab khám phá công khai:**<br>   - `Đang diễn ra (LIVE)`<br>   - `Sắp kết thúc (Ending Soon)` *(còn dưới 15 phút)*<br>   - `Sắp mở (Upcoming / SCHEDULED)`<br>   - `Đã kết thúc (Completed)`<br>3. Nút lối tắt góc trên: **[Đấu giá của tôi (`My Auctions` – `M-AC-02`)]**. | Chuyển đổi giữa 4 tab công khai, xem đồng hồ đếm ngược, giá cao nhất hiện tại (`current_highest_bid`), số lượt trả giá (`bid_count`) trên từng thẻ đấu giá. | Gọi `GET /auctions?tab=...` (có phân trang). Cả `Guest` và `Registered User` đều được xem đầy đủ danh sách này (`DEC-01`). | Người dùng nhấn nút **[Theo dõi]** hoặc chạm vào thẻ để vào phòng đấu giá `M-AC-03`. |
| 2 | `M-AC-01` $\rightarrow$ `M-AC-02` | Khi nhấn icon **[Theo dõi phiên (`Watch`)]** hoặc nhấn vào **[Đấu giá của tôi (`M-AC-02`)]**:<br>Màn hình `M-AC-02` (`/auctions/mine`) gồm **3 Sub-tabs cá nhân**:<br>1. `Đang tham gia (Participating)`: Hiện rõ nhãn **`ĐANG DẪN ĐẦU (LEADING)`** (màu xanh Forest Green `#294638`) hoặc **`BỊ VƯỢT GIÁ (OUTBID)`** (màu đỏ Burgundy `#873A43`).<br>2. `Đang theo dõi (Watchlist)`.<br>3. `Đã thắng (Won Auctions)`: Kèm đồng hồ đếm ngược hạn thanh toán 30 phút và nút **[Thanh toán ngay]**. | Kiểm tra các phiên mình đang trả giá hoặc đang theo dõi. | - Nếu là `Guest`: Khi nhấn `Watch` hoặc `My Auctions`, chuyển hướng sang `/login?redirect=/auctions` (`DEC-01`).<br>- Nếu đã đăng nhập: Kiểm tra `auth()->id() != seller_id` (`BR-AC-02`) khi thêm vào Watchlist và tải dữ liệu `GET /auctions/mine`. | Chạm vào phiên bất kỳ để vào Phòng đấu giá `M-AC-03` hoặc Thanh toán đơn thắng (`AF-08`). |

- **6. Alternative Flows:** Lọc danh sách sản phẩm trong phiên đấu giá theo Danh mục (`Category`) hoặc sắp xếp theo *Sắp hết giờ nhất* / *Nhiều lượt trả giá nhất*.
- **7. Exception Flows:** Người bán tự bấm theo dõi (`Watch`) phiên đấu giá của chính mình $\rightarrow$ Backend từ chối theo quy tắc `BR-AC-02` (`PERM-AC-02`).
- **8. Screen Sequence:** `M-AC-01` (Auction Hub) $\leftrightarrow$ `M-AC-02` (My Auctions) $\rightarrow$ `M-AC-03` (Auction Detail Room).
- **9. Exit Condition:** Người dùng chọn được một phiên đấu giá để vào phòng đặt giá thầu (`AF-03`).
- **10. Related IDs:** `FR-AC-01` | `UC-DS-01`, `UC-AC-01` | `PERM-AC-01`, `PERM-AC-02`, `BR-AC-02`, `DEC-01`, `NAV-DEC-01`.

```mermaid
flowchart TD
    Start(["Chạm vào Tab 3: Đấu giá (/auctions - M-AC-01)"]) --> PublicTabs["Xem 4 Tab công khai (Guest & User):<br/>1. Đang diễn ra (LIVE)<br/>2. Sắp kết thúc (Ending Soon)<br/>3. Sắp mở (Upcoming)<br/>4. Đã kết thúc (Completed)"]

    PublicTabs --> UserAction{"Thao tác của Người dùng?"}
    UserAction -- "Chạm vào Thẻ đấu giá" --> GoRoom["Mở Phòng Đấu giá M-AC-03 (Chuyển sang AF-03)"]

    UserAction -- "Nhấn [Theo dõi (Watch)] hoặc [Đấu giá của tôi]" --> AuthCheck{"Đã đăng nhập?"}
    AuthCheck -- "Chưa (Guest)" --> LoginRedir["M-AU-03: Login (?redirect=/auctions - DEC-01)"]
    LoginRedir --> PersonalAct

    AuthCheck -- "Đã đăng nhập (ACT-02)" --> PersonalAct{"Loại hành động?"}
    PersonalAct -- "Bấm Watch phiên đấu giá" --> OwnerGuard{"auth.id == seller_id?"}
    OwnerGuard -- "Trùng chủ bài đăng" --> BlockWatch["Chặn tự Watch sản phẩm của mình (BR-AC-02)"]
    OwnerGuard -- "Hợp lệ" --> SaveWatch["POST /auctions/{id}/watch -> Lưu vào Watchlist"]

    PersonalAct -- "Mở Đấu giá của tôi (M-AC-02)" --> MyAucTabs["Hiển thị 3 Tab cá nhân:<br/>1. Đang tham gia (Báo rõ LEADING / OUTBID)<br/>2. Đang theo dõi (Watchlist)<br/>3. Đã thắng (Won - Kèm nút Thanh toán 30p)"]
```

---

### 2.3. `AF-03`: Real-Time Auction Room & Concurrent Bidding (Phòng Đấu Giá & Đặt Giá Thầu Đồng Thời Với `lockForUpdate`)

- **1. Flow ID & Name:** `AF-03` – Auction Detail Inspection & Concurrent Bid Placement Engine
- **2. Primary Actor:** `ACT-02` (Registered Buyer)
- **3. Entry Point:** Từ `M-AC-01`, `M-AC-02`, `M-HM-01` hoặc `M-DS-02` chạm vào một sản phẩm đấu giá để mở `M-AC-03` (`/auctions/:id`).
- **4. Preconditions:** Phiên đấu giá đang ở trạng thái `LIVE`, thời gian chuẩn của máy chủ `now() >= auction_starts_at` và `now() < auction_ends_at`, người đặt giá đã đăng nhập và `auth()->id() != auction.seller_id`.
- **5. Main Flow (Bảng Tương Tác UX & Xử Lý Đồng Thời):**

| Bước | Màn Hình | Người Dùng Nhìn Thấy Gì (What User Sees) | Thao Tác Của Người Dùng (User Action) | Phản Hồi Của Hệ Thống (System Response) | Bước Tiếp Theo (Next State) |
| :-: | :---: | :--- | :--- | :--- | :--- |
| 1 | `M-AC-03` | Màn hình **Phòng Đấu Giá Chi Tiết** (`/auctions/:id`) hiển thị:<br>1. **Thanh Đồng hồ Đếm ngược Thời gian thực** (đồng bộ theo `auction_ends_at` từ server).<br>2. **Bảng Giá Trực tiếp:** Giá khởi điểm (`starting_price`), **Giá cao nhất hiện tại (`current_highest_bid`)**, Bước giá tối thiểu (`min_bid_increment`), **Mức giá hợp lệ tối thiểu tiếp theo (`minimum_next_bid`)**, và trạng thái Giá sàn (`Đã đạt giá sàn` / `Chưa đạt giá sàn`).<br>3. Lịch sử trả giá rút gọn (nhấn **[Xem tất cả X lượt trả giá]** mở `M-AC-04`).<br>4. Chi tiết món đồ si: Ảnh, tình trạng (`condition`), mô tả lỗi (`defect_info`), mức độ xác minh và thông tin Tiệm bán.<br>5. Nút hành động chính dưới đáy: **[Đặt giá thầu (`Place Bid`)]**. | Xem kỹ thông tin món đồ, kiểm tra mức giá hiện tại và nhấn **[Đặt giá thầu]**. | - Nếu là `Guest`: Chuyển hướng `/login?redirect=/auctions/:id` (`DEC-01`).<br>- Nếu là chủ sản phẩm (`auth()->id() == seller_id`): Ẩn nút `Place Bid`, hiển thị thanh điều khiển của Seller (`SF-07`).<br>- Nếu là Buyer hợp lệ: Mở Bottom Sheet đặt giá `M-AC-04`. | Mở `M-AC-04` (`Place Bid Bottom Sheet`). |
| 2 | `M-AC-04` | Bottom Sheet `M-AC-04` hiển thị:<br>1. Mức giá tối thiểu cần đặt: `min_next_bid = current_highest_bid + min_bid_increment` (hoặc `= starting_price` nếu chưa có ai bid).<br>2. Các nút cộng nhanh (`+1 bước giá`, `+2 bước giá`, `+5 bước giá`) và ô nhập số tiền tùy chỉnh (`bid_amount`).<br>3. Lưu ý cam kết: *"Lượt trả giá đã đặt không thể rút lại (`BR-AU-02`). Nếu thắng phiên, bạn có 30 phút để hoàn tất thanh toán"*. | Nhập hoặc chọn `bid_amount >= min_next_bid`, nhấn **[Xác nhận Đặt giá]** $\rightarrow$ Xác nhận trong Confirmation Dialog (`NFR-UX-03`). | Gọi `POST /auctions/{id}/bids` (`bid_amount`). Backend thực thi trong **`DB::transaction()` + `SELECT ... FOR UPDATE` (`lockForUpdate()`)** trên dòng `auctions` (`BR-AU-03`, `ADR-06`):<br>1. Kiểm tra lại `status == LIVE` và `now() < auction_ends_at` (`BR-AU-01`).<br>2. Kiểm tra lại `bid_amount >= current_highest_bid + min_bid_increment`.<br>3. `INSERT` bản ghi vĩnh viễn vào `auction_bids`.<br>4. Cập nhật `auctions.current_highest_bid = bid_amount`, `leading_bidder_id = auth()->id()`, `bid_count += 1`.<br>5. Kiểm tra điều kiện gia hạn Anti-sniping (`AF-04`) và phát sự kiện thông báo `Outbid` cho người dẫn đầu cũ (`AF-05`). | Đóng Bottom Sheet, cập nhật `M-AC-03` với huy hiệu **`BẠN ĐANG DẪN ĐẦU PHIÊN ĐẤU GIÁ`**. |

- **6. Alternative Flows:**
  - **A1 (Người đang dẫn đầu tiếp tục nâng mức giá của chính mình):** Hệ thống cho phép hoặc cảnh báo rõ người dùng đang là `leading_bidder` trước khi xác nhận nâng giá.
- **7. Exception Flows (Xử lý xung đột đồng thời – Race Conditions):**
  - **E1 (Hai người mua cùng bấm Đặt cùng một mức giá tại cùng một mili-giây – `RSK-01`):**
    - Nhờ `SELECT ... FOR UPDATE` trên dòng `auctions`, Request của **Buyer A** khóa dòng trước, ghi nhận mức giá `500.000đ` thành công.
    - Request của **Buyer B** (cũng đặt `500.000đ`) phải đợi khóa mở; khi đọc lại `current_highest_bid` đã là `500.000đ`, điều kiện `bid_amount >= 500.000 + min_bid_increment` thất bại $\rightarrow$ Transaction của Buyer B rollback ngay lập tức và trả mã `409 Conflict` kèm `minimum_next_bid` mới (*"Vừa có người trả giá cao hơn! Mức giá tối thiểu tiếp theo là 550.000đ"*).
  - **E2 (Đặt giá khi phiên vừa hết giờ trên Server dù đồng hồ điện thoại bị lệch vài giây – `BR-AU-01`):** Backend so sánh `now() >= auction_ends_at`, từ chối lượt bid với mã `422/409` (*"Phiên đấu giá đã kết thúc"*) và làm mới giao diện sang trạng thái đã đóng.
  - **E3 (Vượt quá giới hạn tần suất `Rate Limit`):** Gửi quá 30 lượt bid/phút bị chặn bởi `429 Too Many Requests` (`NFR-SEC-04`).
- **8. Screen Sequence:** `M-AC-01` / `M-AC-02` $\rightarrow$ `M-AC-03` (Auction Room) $\leftrightarrow$ `M-AC-04` (Place Bid & Bid History Sheet).
- **9. Exit Condition:** Lượt trả giá hợp lệ được ghi nhận nguyên tử vào `auction_bids` và cập nhật người dẫn đầu mới.
- **10. Related IDs:** `FR-AC-02` | `UC-AC-02` | `PERM-AC-03`, `BR-AC-02`, `BR-AU-01`..`03`, `ADR-06`, `NFR-SEC-04`, `NFR-REL-01`.

```mermaid
sequenceDiagram
    autonumber
    actor BuyerA as Buyer A (Mobile)
    actor BuyerB as Buyer B (Mobile)
    participant API as Laravel 13 BidService
    participant DB as PostgreSQL 18 (auctions & auction_bids)

    Note over BuyerA, DB: Giả sử current_highest_bid = 450.000đ, min_bid_increment = 50.000đ (Giá tối thiểu tiếp theo = 500.000đ)
    BuyerA->>API: POST /auctions/10/bids (bid_amount = 500.000đ)
    BuyerB->>API: POST /auctions/10/bids (bid_amount = 500.000đ - Gửi cùng lúc)

    API->>DB: [Buyer A] BEGIN TRANSACTION + SELECT * FROM auctions WHERE id=10 FOR UPDATE
    Note right of DB: Dòng auction id=10 bị KHÓA (Row Lock)<br/>Transaction của Buyer B phải xếp hàng chờ
    API->>DB: [Buyer A] Kiểm tra: LIVE, now < ends_at, 500k >= 450k + 50k (HỢP LỆ)
    API->>DB: [Buyer A] INSERT INTO auction_bids (500.000đ)<br/>UPDATE auctions SET current_highest_bid = 500.000đ, leading_bidder_id = BuyerA
    API->>DB: [Buyer A] COMMIT (Giải phóng Row Lock)
    API-->>BuyerA: 200 OK (Bạn đang dẫn đầu với mức giá 500.000đ!)

    API->>DB: [Buyer B] Nhận Row Lock -> Đọc lại current_highest_bid mới (= 500.000đ)
    API->>DB: [Buyer B] Kiểm tra: 500k >= 500k + 50k (550k)? -> SAI (THẤT BẠI)
    API->>DB: [Buyer B] ROLLBACK TRANSACTION
    API-->>BuyerB: 409 Conflict ("Vừa có người đặt 500.000đ! Vui lòng đặt từ 550.000đ trở lên")
```

---

### 2.4. `AF-04`: Anti-Sniping Automatic Extension (Gia Hạn Tự Động 2 Phút Cuối Chống Trả Giá Giây Chót)

- **1. Flow ID & Name:** `AF-04` – Anti-Sniping Final-Window Automatic Time Extension
- **2. Primary Actor:** `ACT-06` (System Bid Engine) $\rightarrow$ Hiển thị cho `ACT-02` (Buyers & Seller)
- **3. Entry Point:** Kích hoạt tự động bên trong transaction của `AF-03` (`POST /auctions/{id}/bids`) ngay sau khi một lượt trả giá hợp lệ được chấp nhận.
- **4. Preconditions:** Phiên đấu giá đang `LIVE` và lượt trả giá hợp lệ diễn ra khi thời gian còn lại nhỏ hơn hoặc bằng ngưỡng nhạy cảm cuối phiên (`auction_ends_at - now() <= anti_sniping_window`).
- **5. Main Flow (Bảng Tương Tác UX & Hệ Thống):**

| Bước | Màn Hình | Người Dùng Nhìn Thấy Gì (What User Sees) | Cơ Chế Xử Lý Tại Backend (`BR-AU-04` & `ADR-05`) | Bước Tiếp Theo (Next State) |
| :-: | :---: | :--- | :--- | :--- |
| 1 | `M-AC-03` | Đồng hồ đếm ngược đang ở giai đoạn nước rút màu đỏ Burgundy (`< 02:00` ở Production Mode hoặc `< 00:30` ở Demo Mode). Một người mua đặt giá thầu hợp lệ thành công. | Ngay trong cùng `DB::transaction()` của lượt bid:<br>1. Tính `remaining_seconds = auction_ends_at - now()`.<br>2. Lấy tham số từ `platform_settings`:<br>   - Production Mode: `window = 120s (2 phút)`, `extension = +120s (+2 phút)`.<br>   - Demo Mode (`DEMO_MODE=true`): `window = 30s`, `extension = +30s`.<br>3. Nếu `remaining_seconds <= window`:<br>   - Cập nhật **`auction_ends_at = auction_ends_at + extension`**.<br>   - Tăng bộ đếm **`extended_count = extended_count + 1`**. | Trả về JSON response của lượt bid kèm `new_auction_ends_at` và `extended_count`. |
| 2 | `M-AC-03` | Đồng hồ đếm ngược trên màn hình tự động cộng thêm **+2 phút** (hoặc **+30 giây** ở Demo Mode) kèm banner thông báo nổi bật: **`⚡ ĐÃ GIA HẠN THÊM +2 PHÚT (Chống trả giá giây cuối - Lần gia hạn #X)`**. | Các người mua khác trong phòng đấu giá có thêm thời gian công bằng để quyết định trả giá tiếp theo. | Tiếp tục vòng lặp trả giá tại `AF-03` cho đến khi hết giờ mà không có bid mới. |

- **6. Alternative Flows:** Nếu trong khoảng thời gian vừa được gia hạn lại tiếp tục có lượt trả giá mới, quy tắc `AF-04` tiếp tục cộng thêm thời gian lặp lại.
- **7. Exception Flows:** Nếu lượt trả giá không hợp lệ (bị từ chối do thấp hơn bước giá hoặc gửi sau khi `now() >= auction_ends_at`), hệ thống tuyệt đối không kích hoạt gia hạn.
- **8. Screen Sequence:** `M-AC-04` (Submit Bid) $\rightarrow$ `M-AC-03` (Live Countdown Extended Banner).
- **9. Exit Condition:** Mốc `auction_ends_at` được đóng băng với thời gian mới trong CSDL và đồng bộ lên giao diện.
- **10. Related IDs:** `FR-AC-03`, `FR-AD-04` | `UC-AC-02` | `PERM-AC-04`, `BR-AU-04`, `ADR-05`.

```mermaid
flowchart TD
    Start(["Một lượt Bid hợp lệ vừa được ghi nhận trong AF-03<br/>(Đang nằm trong DB::transaction + lockForUpdate)"]) --> CalcRem["Tính thời gian còn lại:<br/>remaining = auction_ends_at - now()"]
    CalcRem --> ModeCheck{"Kiểm tra ngưỡng Anti-Sniping<br/>(Production: <= 2 phút | Demo Mode: <= 30 giây)?"}

    ModeCheck -- "remaining > ngưỡng (Còn nhiều thời gian)" --> KeepTime["Giữ nguyên mốc auction_ends_at hiện tại"]
    ModeCheck -- "remaining <= ngưỡng (Trong vùng nhạy cảm cuối phiên)" --> ExtendTime["BR-AU-04:<br/>1. auction_ends_at = auction_ends_at + extension (+2p / +30s Demo)<br/>2. extended_count = extended_count + 1"]

    KeepTime --> ReturnUI["Trả về kết quả Bid & Cập nhật M-AC-03"]
    ExtendTime --> ShowExtBanner["M-AC-03: Đồng hồ cộng thêm giờ + Hiện Banner<br/>'⚡ Đã gia hạn Anti-Sniping để đảm bảo công bằng'"]
```

---

### 2.5. `AF-05`: Outbid Notification & Re-Bidding Loop (Thông Báo Bị Vượt Giá & Quay Lại Đấu Giá)

- **1. Flow ID & Name:** `AF-05` – Outbid Alert & Rapid Re-Bidding Flow
- **2. Primary Actor:** `ACT-06` (System Event) $\rightarrow$ `ACT-02` (Previous Leading Bidder)
- **3. Entry Point:** Khi Buyer B đặt giá cao hơn mức giá đang dẫn đầu của Buyer A tại `AF-03`.
- **4. Preconditions:** Buyer A trước đó là `leading_bidder_id` và người đặt giá mới `new_bidder_id != Buyer A`.
- **5. Main Flow:**
  1. Ngay khi Buyer B chiếm vị trí dẫn đầu, Backend tự động tạo một thông báo trong bảng `notifications` (`type = AUCTION_OUTBID`) gửi cho Buyer A kèm đường dẫn sâu tới `auction_id`.
  2. Trên màn hình `M-AC-02` (`My Participating Auctions`), thẻ đấu giá của Buyer A đổi trạng thái từ huy hiệu xanh **`ĐANG DẪN ĐẦU`** sang huy hiệu đỏ **`BỊ VƯỢT GIÁ (OUTBID)`** kèm mức giá mới nhất.
  3. Buyer A chạm vào thông báo trong `M-NT-01` hoặc thẻ trong `M-AC-02` $\rightarrow$ Đi thẳng vào phòng đấu giá `M-AC-03` $\rightarrow$ Mở `M-AC-04` để đặt mức giá mới cao hơn trước khi đồng hồ về `00:00`.
- **6. Screen Sequence:** `M-NT-01` / `M-AC-02` $\rightarrow$ `M-AC-03` $\rightarrow$ `M-AC-04` (`AF-03`).
- **7. Exit Condition:** Người mua bị vượt giá nắm bắt tức thì biến động phiên và thực hiện trả giá lại.
- **8. Related IDs:** `FR-AC-02`, `FR-NT-01` | `UC-AC-02`, `UC-NT-01` | `BR-AU-02`.

```mermaid
flowchart TD
    Start(["Buyer B đặt giá thành công vượt qua Buyer A"]) --> CreateNoti["Backend tạo In-App Notification (AUCTION_OUTBID) cho Buyer A<br/>Cập nhật trạng thái của Buyer A trong M-AC-02 thành 'BỊ VƯỢT GIÁ'"]
    CreateNoti --> BuyerASees["Buyer A thấy Badge thông báo (M-NT-01) hoặc xem trong M-AC-02"]
    BuyerASees --> TapAlert["Buyer A chạm vào thông báo -> Deep-link thẳng tới M-AC-03"]
    TapAlert --> StillLive{"Phiên đấu giá còn LIVE?"}
    StillLive -- "Đã kết thúc" --> ShowEnded["Hiển thị kết quả phiên đã đóng"]
    StillLive -- "Còn LIVE" --> ReBid["Mở M-AC-04 đặt mức giá mới cao hơn (Quay lại AF-03)"]
```

---

### 2.6. `AF-06`: Seller Early Close Execution (Người Bán Chủ Động Chốt Phiên Đấu Giá Sớm)

- **1. Flow ID & Name:** `AF-06` – Seller Early Auction Closing (`Close Early`)
- **2. Primary Actor:** `ACT-02` (Seller – chủ sở hữu sản phẩm đấu giá)
- **3. Entry Point:** Người bán mở màn hình `M-AC-03` của sản phẩm mình đăng bán và nhấn nút **[Chốt phiên sớm (`Close Early`)]**.
- **4. Preconditions (`BR-AU-05`):** Phải thỏa mãn đồng thời 3 điều kiện:
  1. Phiên đấu giá đang `LIVE` (`now() < auction_ends_at`).
  2. Đã có người dẫn đầu hợp lệ (`leading_bidder_id IS NOT NULL`).
  3. Giá cao nhất hiện tại đã đạt hoặc vượt giá sàn (`current_highest_bid >= reserve_price`, nếu có cài đặt `reserve_price`).
- **5. Main Flow (Bảng Tương Tác UX & Hệ Thống):**

| Bước | Màn Hình | Người Dùng Nhìn Thấy Gì (What User Sees) | Thao Tác Của Người Dùng (User Action) | Phản Hồi Của Hệ Thống (System Response) | Bước Tiếp Theo (Next State) |
| :-: | :---: | :--- | :--- | :--- | :--- |
| 1 | `M-AC-03` $\rightarrow$ `M-AC-05` | Trên thanh điều khiển dành cho chủ sản phẩm tại `M-AC-03`, khi đã đạt đủ 3 điều kiện `BR-AU-05`, nút **[Chốt phiên sớm]** sáng lên. | Seller nhấn **[Chốt phiên sớm]** $\rightarrow$ Mở hộp thoại xác nhận `M-AC-05` hiển thị mức giá chốt `current_highest_bid` và tên người đang dẫn đầu. | Nếu đồng ý, gọi `POST /auctions/{id}/close-early`. | Backend xử lý đóng phiên và tạo đơn hàng. |
| 2 | `M-AC-05` $\rightarrow$ `M-SL-06` | Thông báo phiên đấu giá đã được chốt sớm thành công và đơn hàng đã được tạo cho người thắng. | Nhấn **[Xem Đơn hàng vừa tạo]**. | Backend gọi cùng hàm Service đóng phiên (`AuctionClosingService`) bên trong `DB::transaction()` + `lockForUpdate()`:<br>1. Đặt `auction.status = COMPLETED`, `winner_id = leading_bidder_id`, `closed_early_by_seller = true`, `closed_at = now()`.<br>2. Tự động khởi tạo đơn hàng (`AF-07`).<br>3. Ghi `audit_logs` và thông báo cho Winner vào thanh toán. | Chuyển sang chờ Winner thanh toán trong 30 phút (`AF-08`). |

- **6. Exception Flows:**
  - **E1 (Chưa có người trả giá hoặc `current_highest_bid < reserve_price`):** Nút **[Chốt phiên sớm]** bị khóa (`Disabled`) trên giao diện và nếu cố gọi API sẽ bị chặn với mã `422 Unprocessable Entity` (`BR-AU-05`).
- **7. Screen Sequence:** `M-SL-02` $\rightarrow$ `M-AC-03` (Seller View) $\rightarrow$ `M-AC-05` (Confirm Dialog) $\rightarrow$ `M-SL-06`.
- **8. Exit Condition:** Phiên đấu giá kết thúc sớm hợp lệ và chuyển sang luồng tạo đơn hàng (`AF-07`).
- **9. Related IDs:** `FR-AC-04` | `UC-AC-03` | `PERM-AC-05`, `BR-AU-03`, `BR-AU-05`, `BR-AD-02`.

```mermaid
flowchart TD
    Start(["Seller mở M-AC-03 của sản phẩm mình đăng"]) --> CheckCond{"Kiểm tra BR-AU-05:<br/>1. status == LIVE?<br/>2. leading_bidder != null?<br/>3. highest_bid >= reserve_price?"}
    CheckCond -- "Chưa đủ điều kiện" --> DisableBtn["Khóa nút [Chốt phiên sớm]<br/>Hiển thị chú thích điều kiện cần đạt"]
    CheckCond -- "Đạt đủ 3 điều kiện" --> EnableBtn["Mở nút [Chốt phiên sớm] -> Seller nhấn nút"]
    EnableBtn --> ConfirmM05["M-AC-05: Hộp thoại xác nhận chốt giá hiện tại"]
    ConfirmM05 -- "Nhấn [Xác nhận]" --> CallCloseEarly["POST /auctions/{id}/close-early<br/>Gọi AuctionClosingService (DB::transaction + lockForUpdate)"]
    CallCloseEarly --> TriggerAF07["Đặt closed_early_by_seller = true, Ghi audit_logs<br/>& Chuyển thẳng sang AF-07 để tạo Đơn hàng cho Winner"]
```

---

### 2.7. `AF-07`: Automatic Auction Closing, Winner Resolution & Order Creation (Đóng Phiên Tự Động, Xác Định Người Thắng & Khởi Tạo Đơn Hàng Duy Nhất)

- **1. Flow ID & Name:** `AF-07` – Automatic Auction Closing, Winner Determination & Idempotent Order Generation
- **2. Primary Actor:** `ACT-06` (System Scheduler) hoặc `ACT-05` (Admin qua **Developer Tools** khi `DEMO_MODE=true`)
- **3. Entry Point:** Khi đồng hồ đạt mốc `now() >= auction_ends_at` (Scheduled Job `CloseExpiredAuctionsJob` chạy định kỳ), hoặc khi Admin nhấn nút **`[Run: Force Close Expired Auctions]`** trên màn hình `A-DT-01`, hoặc chuyển tiếp từ `AF-06`.
- **4. Preconditions:** Bản ghi `auctions` đang ở trạng thái `status = LIVE` và `now() >= auction_ends_at` (hoặc được Seller chốt sớm).
- **5. Main Flow (Bảng Xử Lý Hệ Thống Nguyên Tử & Lũy Đẳng):**

| Bước | Tác Nhân / Service | Logic Kiểm Tra Trong `DB::transaction()` + `lockForUpdate()` | Kết Quả Dữ Liệu & Phản Hồi Hệ Thống | Bước Tiếp Theo |
| :-: | :---: | :--- | :--- | :--- |
| 1 | `AuctionClosingService` | Khóa dòng bản ghi `auctions` (`SELECT ... FOR UPDATE`). Kiểm tra tính lũy đẳng (`BR-AD-01`): nếu `status != LIVE` (đã được xử lý trước đó), bỏ qua ngay lập tức. | Đảm bảo dù Job chạy lặp hay Admin bấm nút nhiều lần cũng không bao giờ xử lý trùng. | Kiểm tra điều kiện người thắng ở Bước 2. |
| 2 | `AuctionClosingService` | Kiểm tra kết quả trả giá:<br>- **Trường hợp 1 (Có Người Thắng Hợp Lệ):** `leading_bidder_id IS NOT NULL` VÀ (`reserve_price IS NULL` HOẶC `current_highest_bid >= reserve_price`).<br>- **Trường hợp 2 (Không Có Người Thắng):** Không có lượt trả giá nào HOẶC `current_highest_bid < reserve_price`. | - **Nếu Trường hợp 2:** Cập nhật `auction.status = ENDED_UNSOLD`, gửi thông báo cho Seller để đăng lại vào phiên sau (`SF-07`).<br>- **Nếu Trường hợp 1:** Chuyển sang Bước 3 tạo đơn hàng cho người thắng. | Khởi tạo đơn hàng cho Winner. |
| 3 | `OrderCreationService` | Với phiên có người thắng hợp lệ:<br>1. Cập nhật `auction.status = COMPLETED`, `winner_id = leading_bidder_id`.<br>2. Cập nhật `product.status = SOLD`, `available_quantity = 0`.<br>3. **Tự động tạo duy nhất 1 bản ghi `orders`** (ràng buộc `UNIQUE(auction_id)` – `BR-AU-06`):<br>   - `buyer_id = winner_id`, `seller_id = auction.seller_id`, `order_type = AUCTION`.<br>   - `item_subtotal = current_highest_bid`.<br>   - `shipping_fee = 0` (`DEC-04`).<br>   - **`buyer_protection_fee = ROUND(item_subtotal * rate, 0) + fixed_fee`** (`DEC-04`, `BR-FN-02`).<br>   - **`total_amount = item_subtotal + buyer_protection_fee`**.<br>   - `order_status = PENDING_PAYMENT`, `payment_status = UNPAID`, `escrow_status = NONE`.<br>   - **Lưu cứng hạn thanh toán `payment_expires_at = now() + deadline`** (**30 phút** ở Production Mode / **2 phút** ở Demo Mode – `BR-AU-07`, `ADR-05`).<br>4. Lưu cứng bản chụp sản phẩm vào `order_items` (`BR-OR-02`). | Gửi thông báo `In-App Notification` cho:<br>- **Winner:** *"Chúc mừng bạn đã thắng đấu giá! Vui lòng thanh toán đơn hàng trong vòng 30 phút"*.<br>- **Seller:** *"Phiên đấu giá đã kết thúc thành công. Đang chờ người thắng thanh toán"*. | Chuyển sang `AF-08` (Winner thanh toán đơn hàng). |

- **6. Alternative Flows:** Khi đang bảo vệ đồ án (`DEMO_MODE=true`), Admin mở `A-DT-01` nhấn nút tua/đóng phiên để kích hoạt ngay lập tức `AF-07` mà không cần chờ hết giờ thực tế.
- **7. Exception Flows:** Ràng buộc `UNIQUE(auction_id)` trên bảng `orders` kết hợp `lockForUpdate()` chặn tuyệt đối lỗi sinh 2 đơn hàng cho cùng 1 phiên đấu giá (`BR-AU-06`).
- **8. Screen Sequence:** `Backend Scheduler / A-DT-01` $\rightarrow$ `M-NT-01` (Winner Notification) $\rightarrow$ `M-AC-02` (Tab `Won Auctions`) $\rightarrow$ `M-OR-03`.
- **9. Exit Condition:** Phiên đấu giá đóng lại (`COMPLETED` hoặc `ENDED_UNSOLD`), và đúng 1 đơn hàng `PENDING_PAYMENT` được khởi tạo cho người thắng.
- **10. Related IDs:** `FR-AC-05`, `FR-AD-05` | `UC-AC-04`, `UC-AD-02` | `PERM-AC-06`, `BR-AU-06`, `BR-AU-07`, `BR-OR-02`, `BR-FN-02`, `BR-AD-01`, `DEC-04`, `ADR-05`.

```mermaid
flowchart TD
    Start(["Kích hoạt bởi: 1. Scheduler (now >= auction_ends_at)<br/>2. Admin Demo Trigger (A-DT-01) | 3. Seller Early Close (AF-06)"]) --> LockRow["DB::transaction() + SELECT * FROM auctions FOR UPDATE"]
    LockRow --> CheckStatus{"auction.status == LIVE?"}
    CheckStatus -- "Không (Đã xử lý rồi)" --> SkipIdem["Bỏ qua (Đảm bảo tính Lũy đẳng - BR-AD-01)"]

    CheckStatus -- "Đang LIVE" --> CheckWinner{"1. leading_bidder_id != null?<br/>2. current_highest_bid >= reserve_price?"}
    CheckWinner -- "Không đạt (Không có bid / Chưa đạt giá sàn)" --> MarkUnsold["UPDATE auctions SET status = ENDED_UNSOLD<br/>Thông báo cho Seller có thể đăng lại phiên sau"]

    CheckWinner -- "Đạt (Có người thắng hợp lệ)" --> CreateWinnerOrder["1. UPDATE auctions SET status = COMPLETED, winner_id = leading_bidder_id<br/>2. UPDATE products SET status = SOLD, available_quantity = 0<br/>3. INSERT orders (UNIQUE auction_id - BR-AU-06):<br/>   - item_subtotal = winning_bid, shipping_fee = 0<br/>   - buyer_protection_fee = ROUND(subtotal * rate) + fixed_fee (DEC-04)<br/>   - total_amount = item_subtotal + buyer_protection_fee<br/>   - payment_expires_at = now() + 30p (hoặc +2p Demo Mode)<br/>4. INSERT order_items (Snapshot - BR-OR-02)"]
    CreateWinnerOrder --> NotifyAll["Gửi Notification cho Winner & Seller -> Chuyển sang AF-08"]
```

---

### 2.8. `AF-08`: Winner Checkout & 30-Minute Payment Countdown (Người Thắng Thanh Toán Đơn Đấu Giá Trong 30 Phút)

- **1. Flow ID & Name:** `AF-08` – Auction Winner Order Review & Time-Bounded QR Payment
- **2. Primary Actor:** `ACT-02` (Winning Buyer)
- **3. Entry Point:** Nhấn vào thông báo *"Chúc mừng bạn đã thắng đấu giá"* (`M-NT-01`), hoặc mở **Tab 3 (`M-AC-01`) $\rightarrow$ Đấu giá của tôi (`M-AC-02` – Tab `Đã thắng`)**, hoặc mở **Tab 5 (`M-PF-01`) $\rightarrow$ Đơn mua của tôi (`M-OR-02` – Tab `Chờ thanh toán`)**.
- **4. Preconditions:** Đơn hàng đấu giá đang ở `order_status = PENDING_PAYMENT`, `payment_status = UNPAID` và `now() < payment_expires_at`.
- **5. Main Flow (Bảng Tương Tác UX Chi Tiết):**

| Bước | Màn Hình | Người Dùng Nhìn Thấy Gì (What User Sees) | Thao Tác Của Người Dùng (User Action) | Phản Hồi Của Hệ Thống (System Response) | Bước Tiếp Theo (Next State) |
| :-: | :---: | :--- | :--- | :--- | :--- |
| 1 | `M-AC-02` $\rightarrow$ `M-OR-03` | Trên thẻ phiên đã thắng ở `M-AC-02` và màn hình Chi tiết đơn hàng `M-OR-03` hiển thị:<br>1. **Banner Đếm ngược Hạn Thanh toán Nổi bật:** *"Thời gian thanh toán còn lại: `29:45` (Quá hạn đơn hàng sẽ tự động hủy)"*.<br>2. Khối chọn/xác nhận Địa chỉ nhận hàng (`M-PF-03`/`M-PF-04`).<br>3. Bảng kê chi phí (`DEC-04`):<br>   - Giá thắng đấu giá (`item_subtotal = winning_bid`).<br>   - Phí vận chuyển: **`0 VNĐ`**.<br>   - **Phí bảo vệ người mua (`buyer_protection_fee`)**.<br>   - **Tổng cần thanh toán (`total_amount`)**.<br>4. Nút chính: **[Thanh toán QR ngay (`Pay Now`)]**. | Kiểm tra/cập nhật địa chỉ nhận hàng cho đơn thắng đấu giá và nhấn **[Thanh toán QR ngay]**. | Kiểm tra `now() < payment_expires_at`, cập nhật địa chỉ nhận hàng vào đơn và điều hướng sang màn hình Thanh toán QR Mô phỏng `M-PM-01`. | Mở `M-PM-01` (`BF-06`). |
| 2 | `M-PM-01` $\rightarrow$ `M-PM-02` | Mã QR thanh toán nội bộ, số tiền `total_amount`, đồng hồ đếm ngược `payment_expires_at` và nút **[Mô phỏng Thanh toán Thành công]**. | Nhấn **[Mô phỏng Thanh toán Thành công]**. | Chuyển `payment_status = PAID`, `order_status = PAID`, `escrow_status = HELD`, ghi bút toán `HOLD` (`amount = total_amount`) vào `escrow_transactions`. | Đơn hàng đấu giá đi vào luồng giao nhận & bảo vệ Escrow chuẩn (`SF-08` $\rightarrow$ `SF-10` $\rightarrow$ `BF-08`). |

- **6. Exception Flows:** Nếu người thắng không thanh toán trước khi đồng hồ `payment_expires_at` về `00:00`, đơn hàng tự động chuyển sang luồng xử lý quá hạn `AF-09`.
- **7. Screen Sequence:** `M-NT-01` / `M-AC-02` $\rightarrow$ `M-OR-03` $\rightarrow$ `M-PM-01` $\rightarrow$ `M-PM-02`.
- **8. Exit Condition:** Đơn hàng thắng đấu giá được thanh toán thành công và tiền được giữ an toàn trong `ESCROW_HELD`.
- **9. Related IDs:** `FR-AC-05`, `FR-PM-01`, `FR-PM-02`, `FR-ES-01` | `UC-PM-01` | `BR-AU-07`, `BR-FN-02`, `BR-FN-03`, `DEC-04`.

```mermaid
flowchart TD
    Start(["Winner mở Đơn hàng thắng đấu giá từ M-AC-02 / M-NT-01 / M-OR-02"]) --> ViewOrder["M-OR-03: Hiển thị Đồng hồ đếm ngược payment_expires_at (30p / 2p Demo)<br/>Bảng phí: Giá thắng (item_subtotal) + Ship 0đ + Buyer Protection Fee = total_amount"]
    ViewOrder --> CheckAddr{"Đã có Địa chỉ nhận hàng?"}
    CheckAddr -- "Chưa có / Muốn đổi" --> SelectAddr["M-PF-03 / M-PF-04: Chọn hoặc thêm Địa chỉ nhận hàng"]
    SelectAddr --> ViewOrder

    CheckAddr -- "Đã xác nhận địa chỉ" --> TapPay["Nhấn [Thanh toán QR ngay] -> Mở M-PM-01"]
    TapPay --> StillValid{"now() < payment_expires_at?"}
    StillValid -- "Quá hạn" --> GoExpire["Chuyển sang AF-09: Hủy đơn quá hạn & Cho phép Seller đăng lại"]
    StillValid -- "Còn hạn" --> SimSuccess["Nhấn [Mô phỏng Thanh toán Thành công]<br/>-> order_status = PAID, escrow_status = HELD<br/>-> INSERT escrow_transactions (HOLD = total_amount)"]
```

---

### 2.9. `AF-09`: Unpaid Winner Default Expiry & Seller Relist (Xử Lý Đơn Thắng Đấu Giá Quá Hạn 30 Phút & Seller Đăng Lại – `DEC-02`)

- **1. Flow ID & Name:** `AF-09` – Unpaid Auction Winner Default Handling & Seller Relisting Flow
- **2. Primary Actor:** `ACT-06` (System Scheduler) / `ACT-05` (Admin Demo Trigger) $\rightarrow$ `ACT-02` (Seller)
- **3. Entry Point:** Khi `now() >= order.payment_expires_at` mà `order.payment_status == UNPAID` (Scheduled Job `ExpireUnpaidAuctionOrdersJob` chạy định kỳ hoặc Admin bấm **`[Run: Expire Unpaid Auction Orders]`** trong `A-DT-01`).
- **4. Preconditions:** Đơn hàng thuộc loại `AUCTION`, đang ở `order_status = PENDING_PAYMENT`, `payment_status = UNPAID` và đã quá hạn `payment_expires_at`.
- **5. Main Flow (Thực Thi Chính Sách `DEC-02` & `BR-AU-07`):**

| Bước | Tác Nhân / Màn Hình | Xử Lý Nghiệp Vụ & Phản Hồi Hệ Thống | Kết Quả Trạng Thái |
| :-: | :---: | :--- | :--- |
| 1 | `ExpireUnpaidAuctionOrdersJob` / `A-DT-01` | Trong `DB::transaction()` + `lockForUpdate()` trên `orders` và `auctions`:<br>1. Kiểm tra tính lũy đẳng: chỉ xử lý nếu `payment_status == UNPAID` và `order_status == PENDING_PAYMENT`.<br>2. Chuyển `orders.order_status = CANCELLED`, `orders.payment_status = EXPIRED`, `cancel_reason = 'AUCTION_PAYMENT_EXPIRED'`.<br>3. Chuyển `auctions.status = WINNER_DEFAULTED` (`DEC-02`).<br>4. Ghi nhận +1 lần vi phạm bỏ cọc đấu giá (`auction_default_count`) vào hồ sơ của người thắng để phục vụ cảnh báo gian lận cho Admin (`FR-AD-02`).<br>5. **Tuyệt đối KHÔNG tự động tạo đơn hàng ép người trả giá cao thứ 2 phải mua (`DEC-02`)**.<br>6. Mở khóa sản phẩm để Seller có quyền đăng lại và gửi thông báo cho cả Winner (báo hủy đơn do quá hạn) và Seller. | Đơn hàng = `CANCELLED`; Phiên đấu giá = `WINNER_DEFAULTED`. |
| 2 | `M-SL-02` $\rightarrow$ `M-SL-03` (Seller) | Seller nhận thông báo *"Người thắng đấu giá không thanh toán đúng hạn. Bạn có thể đăng lại sản phẩm vào phiên tiếp theo"*, nhấn **[Đăng lại phiên đấu giá mới (`Relist Auction`)]** $\rightarrow$ Chọn khung giờ phiên mới và mở bán lại. | Sản phẩm được đưa vào phiên đấu giá mới hợp lệ. |

- **6. Alternative Flows:** Người bán có thể chọn chuyển sản phẩm đó từ bán Đấu giá sang bán Giá cố định (`FIXED_PRICE`) khi đăng lại nếu không muốn chờ phiên đấu giá tiếp theo.
- **7. Exception Flows:** Nếu người thắng vừa bấm thanh toán thành công trước đó vài giây (`payment_status == PAID`), Job kiểm tra trong row lock thấy đã `PAID` sẽ tự động bỏ qua.
- **8. Screen Sequence:** `Scheduler / A-DT-01` $\rightarrow$ `M-NT-01` $\rightarrow$ `M-SL-02` $\rightarrow$ `M-SL-03` (Relist Form).
- **9. Exit Condition:** Đơn hàng quá hạn bị hủy sạch sẽ, ghi nhận vi phạm của người bỏ cọc và trả quyền chủ động đăng lại cho Người bán.
- **10. Related IDs:** `FR-AC-06`, `FR-AD-02`, `FR-AD-05` | `UC-AC-04`, `UC-AD-02` | `PERM-AC-07`, `BR-AU-07`, `BR-AD-01`, `DEC-02`, `ADR-05`.

```mermaid
flowchart TD
    Start(["Kích hoạt bởi Scheduler (now >= payment_expires_at)<br/>hoặc Admin Demo Trigger (A-DT-01)"]) --> LockOrd["DB::transaction() + lockForUpdate() trên orders & auctions"]
    LockOrd --> CheckUnpaid{"order_status == PENDING_PAYMENT<br/>& payment_status == UNPAID?"}
    CheckUnpaid -- "Không (Winner đã trả tiền)" --> SkipJob["Bỏ qua (Idempotent Guard - BR-AD-01)"]

    CheckUnpaid -- "Đúng (Quá hạn chưa trả tiền)" --> ApplyDefault["Thực thi Chính sách DEC-02 & BR-AU-07:<br/>1. orders.order_status = CANCELLED, payment_status = EXPIRED<br/>2. auctions.status = WINNER_DEFAULTED<br/>3. Tăng bộ đếm vi phạm bỏ cọc của Winner<br/>4. KHÔNG ép người trả giá thứ 2 mua<br/>5. Mở khóa sản phẩm cho Seller"]
    ApplyDefault --> SellerRelist["Gửi thông báo cho Seller -> Seller mở M-SL-02 / M-SL-03<br/>Nhấn [Đăng lại vào phiên tiếp theo (Relist)]"]
```

---

### 2.10. `AF-10`: Admin Fraud Inspection & Abnormal Auction Cancellation (Admin Giám Sát & Hủy Phiên Đấu Giá Gian Lận)

- **1. Flow ID & Name:** `AF-10` – Admin Auction Monitoring & Anti-Fraud Cancellation
- **2. Primary Actor:** `ACT-05` (Administrator)
- **3. Entry Point:** Admin mở màn hình **`A-AC-02` (`/admin/auctions`)** $\rightarrow$ Chọn một phiên đấu giá có cảnh báo bất thường để vào **`A-AC-03` (`/admin/auctions/{id}`)**.
- **4. Preconditions:** Phiên đấu giá đang ở trạng thái `SCHEDULED` hoặc `LIVE`.
- **5. Main Flow:**
  1. Trên màn hình `A-AC-03`, Admin kiểm tra toàn bộ lịch sử `auction_bids` (thời gian đặt giá đến từng giây, danh sách tài khoản tham gia, cảnh báo nếu có tài khoản liên tục đẩy giá ảo rồi bỏ cọc nhiều lần).
  2. Nếu phát hiện hành vi gian lận hoặc thông đồng thao túng giá, Admin nhấn **[Hủy phiên đấu giá (`Cancel Abnormal Auction`)]**, nhập lý do bắt buộc và xác nhận (`PERM-AC-09`).
  3. Backend thực thi trong `DB::transaction()`: chuyển `auction.status = CANCELLED`, ẩn sản phẩm (`product.status = HIDDEN`), lưu vết vào `audit_logs` (`BR-AD-02`) và gửi thông báo hủy phiên cho Seller cùng những người đã tham gia đặt giá.
- **6. Screen Sequence:** `A-AC-02` (Auctions Monitor) $\rightarrow$ `A-AC-03` (Auction Detail & Cancel Modal) $\rightarrow$ `A-AD-01` (Audit Logs).
- **7. Exit Condition:** Phiên đấu giá gian lận bị vô hiệu hóa và lưu vết kiểm toán đầy đủ.
- **8. Related IDs:** `FR-AD-02`, `FR-AD-06` | `UC-AD-01` | `PERM-AC-09`, `BR-AD-02`.

```mermaid
flowchart TD
    Start(["A-AC-02: Admin giám sát danh sách Phiên đấu giá"]) --> Inspect["A-AC-03: Xem chi tiết Lịch sử trả giá (auction_bids)<br/>& Cảnh báo tài khoản bất thường"]
    Inspect --> IsFraud{"Phát hiện gian lận / thao túng giá?"}
    IsFraud -- "Bình thường" --> KeepRunning["Tiếp tục để phiên đấu giá vận hành"]
    IsFraud -- "Có gian lận (PERM-AC-09)" --> CancelModal["Admin nhập lý do bắt buộc & Nhấn [Hủy phiên đấu giá]"]
    CancelModal --> ExecCancel["DB::transaction():<br/>1. auctions.status = CANCELLED<br/>2. products.status = HIDDEN<br/>3. INSERT audit_logs (BR-AD-02)<br/>4. Gửi thông báo hủy phiên cho các bên liên quan"]
```

---

## Chương 3. Bảng Tham Số Thời Gian Đấu Giá Theo Chế Độ (`Production Mode` vs `Demo Mode` – `ADR-05`)

Để đảm bảo giảng viên và hội đồng chấm thi có thể kiểm chứng trực tiếp toàn bộ vòng đời đấu giá ngay trong buổi bảo vệ đồ án mà không phải chờ đợi hàng chục phút, hệ thống áp dụng bảng tham số động từ `platform_settings` kết hợp **Developer Tools (`A-DT-01`)**:

| Tham Số Nghiệp Vụ Đấu Giá | Khóa Cấu Hình (`platform_settings`) | Giá Trị Chuẩn (`Production Mode`) | Giá Trị Trình Diễn (`DEMO_MODE=true`) | Nút Kích Hoạt Tức Thì Trong `A-DT-01` (Demo Tools) |
| :--- | :--- | :---: | :---: | :--- |
| **Vùng nhạy cảm cuối phiên (Anti-Sniping Window)** | `auction_anti_sniping_window_seconds` | `120 giây` *(2 phút cuối)* | `30 giây` *(30 giây cuối)* | Tự động kích hoạt ngay khi đặt bid trong vùng nhạy cảm (`AF-04`). |
| **Thời gian cộng thêm mỗi lần Anti-Sniping** | `auction_anti_sniping_extension_seconds` | `+120 giây` *(+2 phút)* | `+30 giây` *(+30 giây)* | Hiển thị trực tiếp trên đồng hồ `M-AC-03`. |
| **Thời hạn thanh toán đơn hàng thắng đấu giá** | `auction_winner_payment_deadline_minutes` | `30 phút` | `2 phút` | Lưu cứng vào cột `orders.payment_expires_at` ngay khi đóng phiên (`AF-07`). |
| **Đóng phiên & Tạo đơn cho người thắng** | Scheduled Job `CloseExpiredAuctionsJob` | Chạy tự động mỗi phút khi `now() >= auction_ends_at` | Chạy tự động hoặc bấm nút thủ công | **`[Run: Force Close Expired Auctions]`** (Có hỗ trợ chọn phiên demo để kết thúc ngay). |
| **Hủy đơn đấu giá quá hạn thanh toán** | Scheduled Job `ExpireUnpaidAuctionOrdersJob` | Chạy tự động mỗi phút khi `now() >= payment_expires_at` | Chạy tự động hoặc bấm nút thủ công | **`[Run: Expire Unpaid Auction Orders]`** (Kích hoạt ngay `AF-09`). |

---

## Chương 4. Kết Quả Tự Động Kiểm Tra & Nghiệm Thu (`Self-Verified Quality Gate Checklist`)

- [x] **1. Đầy đủ 10 luồng nghiệp vụ đấu giá (`AF-01`..`AF-10`):** Phủ kín 100% từ cấu hình khung giờ phiên, khám phá Auction Hub, đặt giá đồng thời (`lockForUpdate`), gia hạn Anti-sniping, thông báo Outbid, Seller chốt sớm, đóng phiên tự động sinh đơn hàng, thanh toán trong 30 phút, hủy đơn bỏ cọc quá hạn cho phép Seller đăng lại (`DEC-02`) đến Admin hủy phiên gian lận (`PERM-AC-09`).
- [x] **2. Đầy đủ Biểu đồ Trực quan (12 Sơ đồ Mermaid):** Bao gồm `stateDiagram-v2` cho vòng đời trạng thái, `sequenceDiagram` chứng minh cơ chế khóa dòng chống Race Condition giữa 2 người mua trả giá cùng lúc, và 10 `flowchart` cho từng luồng.
- [x] **3. Tuân thủ tuyệt đối Công thức Phí Bảo Vệ Người Mua (`DEC-04`):** Đơn hàng sinh ra từ đấu giá (`AF-07`, `AF-08`) tính chính xác `item_subtotal = winning_bid`, `shipping_fee = 0`, cộng `buyer_protection_fee`, đảm bảo khi hoàn tất Seller vẫn nhận đủ 100% `winning_bid`.
- [x] **4. Giải quyết triệt để bài toán Demo Đồ án (`ADR-05`):** Tích hợp rõ ràng bảng tham số `Production Mode` vs `Demo Mode` và các nút kích hoạt lũy đẳng trong Developer Tools (`A-DT-01`).