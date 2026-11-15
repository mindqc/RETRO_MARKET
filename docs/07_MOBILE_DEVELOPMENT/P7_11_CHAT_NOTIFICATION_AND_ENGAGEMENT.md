# P7-11: 1-ON-1 CHAT POLLING, NOTIFICATIONS, REVIEWS & ENGAGEMENT SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P711-CHAT-NOTIFICATION-ENGAGEMENT`
- **Version:** `1.0.0`
- **Status:** `DONE / PO APPROVED`
- **Phase:** `Phase 07 – Task P7-11`
- **Dependencies:** `P7-01, P7-02, P7-03, P7-04, P7-06, P7-09 Completed`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
Hiện thực hóa hệ thống giao tiếp, tương tác cộng đồng và chăm sóc khách hàng in-app: Hộp thư trò chuyện 1-1 có ghim ngữ cảnh sản phẩm/đơn hàng (`M-CM-01`, `M-CM-02`) hoạt động qua cơ chế HTTP Short-Polling `?after_id=` an toàn (`ADR-08`), báo cáo vi phạm & chặn người dùng (`M-CM-03`), trung tâm thông báo có điều hướng Deep-Link (`M-NT-01`), danh sách yêu thích và theo dõi tiệm (`M-PF-05`), cùng hệ thống đánh giá xác thực 1–5 sao từ đơn hàng đã hoàn thành (`M-RV-01`, `M-RV-02`). Gói này bao gồm đúng **7 màn hình Mobile**:
- `M-CM-01`: Hộp Thư Tin Nhắn (`Conversation Inbox` – Tab 4)
- `M-CM-02`: Phòng Trò Chuyện 1-1 (`1-on-1 Chat Room`)
- `M-CM-03`: Biểu Mẫu Báo Cáo Vi Phạm & Chặn Người Dùng (`Report & Block Modal`)
- `M-NT-01`: Trung Tâm Thông Báo In-App (`Notification Center`)
- `M-PF-05`: Đồ Yêu Thích & Tiệm Đang Theo Dõi (`Favorites & Followed Shops`)
- `M-RV-01`: Biểu Mẫu Viết Đánh Giá Xác Thực 1–5 Sao (`Submit Verified Review`)
- `M-RV-02`: Danh Sách Đánh Giá Của Tiệm (`Seller Reviews List`)

---

## 2. Screen Specifications & UX Flows (`Đặc Tả Chi Tiết 7 Màn Hình`)

### 2.1. Chat & Messaging Flow (`M-CM-01` $\rightarrow$ `M-CM-03`)
1. **`M-CM-01: Conversation Inbox Screen` (Tab 4 Root):**
   - Danh sách các cuộc trò chuyện từ `GET /api/v1/conversations`.
   - Mỗi mục hiển thị: Avatar đối phương, Tên đối phương/Tên tiệm, Tin nhắn mới nhất, Thời gian gửi, Huy hiệu số tin nhắn chưa đọc (`unread_count` màu đỏ).
   - Nếu cuộc trò chuyện gắn liền với một sản phẩm, hiển thị ảnh thumbnail nhỏ của sản phẩm đó.
   - Kéo để làm mới (`RefreshIndicator`), vuốt để xóa/lưu trữ.
2. **`M-CM-02: 1-on-1 Chat Room Screen`:**
   - **Thanh App Bar:** Avatar, Tên đối phương, Trạng thái (Online/Offline gần đây), Menu 3 chấm mở chức năng `Báo cáo / Chặn người này` (`M-CM-03`).
   - **Thẻ Ngữ Cảnh Ghim Đầu Phòng Chat (`Pinned Context Card`):**
     - Nếu mở chat từ bài đăng sản phẩm: Ghim ảnh, tiêu đề và giá sản phẩm. Có nút `[Mua ngay]` hoặc `[Gửi trả giá]`.
     - Nếu mở chat từ đơn hàng: Ghim mã đơn hàng, trạng thái đơn và tổng tiền.
   - **Bong Bóng Tin Nhắn (`Message Bubbles`):**
     - Tin nhắn của tôi: Căn phải, nền `Forest Green #294638`, chữ trắng/kem.
     - Tin nhắn của đối phương: Căn trái, nền `Soft Beige #E9DDCB`, chữ `Dark Charcoal #302D2A`.
     - Thời gian gửi định dạng `HH:mm`.
   - **Cơ Chế HTTP Short-Polling Có Kiểm Soát (`ADR-08, NFR-PER-03`):**
     - Tự động gọi `GET /api/v1/conversations/{id}/messages?after_id={lastMessageId}` mỗi 3–5 giây qua `LifecyclePollingController`.
     - Chỉ nối thêm các tin nhắn mới (`id > lastMessageId`), không cuộn giật màn hình.
     - Tự động dừng polling ngay khi người dùng thoát khỏi màn hình chat hoặc đưa app xuống background.
   - **Thanh Nhập Tin Nhắn:** Ô nhập văn bản, nút gửi. Nếu cuộc trò chuyện đang ở trạng thái bị chặn (`is_blocked == true`), khóa thanh nhập và hiển thị: *"Bạn không thể gửi tin nhắn cho người dùng này"*.
3. **`M-CM-03: Report Violation & Block Modal`:**
   - Chọn lý do vi phạm (`reason_category`): Lừa đảo, Hàng giả/nhái, Ngôn từ xúc phạm, Spam.
   - Ô mô tả chi tiết vi phạm (`description` tối thiểu 10 ký tự).
   - Công tắc `[Đồng thời chặn người này nhắn tin cho tôi]`.
   - Nút `[Gửi báo cáo vi phạm]`: Gọi `POST /api/v1/reports`.

### 2.2. Notifications & Engagement (`M-NT-01`, `M-PF-05`)
4. **`M-NT-01: In-App Notification Center Screen`:**
   - Hàng Tab lọc: `TẤT CẢ`, `ĐƠN HÀNG`, `ĐẤU GIÁ`, `HỆ THỐNG`.
   - Nút `[Đánh dấu tất cả đã đọc]` gọi `POST /api/v1/notifications/read-all`.
   - Mỗi thông báo hiển thị icon theo loại, tiêu đề, nội dung, thời gian.
   - **Điều hướng Deep-Link (`deep_link_route`):** Nhấn vào thông báo sẽ đánh dấu đã đọc (`POST /api/v1/notifications/{id}/read`) và tự động mở đúng màn hình mục tiêu (ví dụ: chuyển thẳng sang `M-OR-03` khi có thông báo đơn hàng hoặc `M-AC-03` khi bị vượt giá đấu).
5. **`M-PF-05: Saved Favorites & Followed Shops Screen`:**
   - **Tab 1 – Sản phẩm yêu thích (`Favorites`):** Lưới các sản phẩm đã bấm thích (`ProductCard`). Nhấn icon tim để bỏ thích.
   - **Tab 2 – Tiệm đang theo dõi (`Followed Shops`):** Danh sách các tiệm secondhand đã theo dõi, hiển thị Trust Score và nút `[Đang theo dõi / Bỏ theo dõi]`.

### 2.3. Verified Reviews Flow (`M-RV-01`, `M-RV-02`)
6. **`M-RV-01: Submit Verified Review Form Screen` (`BR-RV-01`):**
   - Chỉ được mở từ các đơn hàng có `order_status == 'COMPLETED'`.
   - Chọn số sao đánh giá: 1 đến 5 sao (sao vàng tương tác mượt mà).
   - Ô nhập cảm nhận thực tế về chất lượng đồ si, độ chuẩn xác của mô tả và tốc độ đóng gói (tối thiểu 5 ký tự).
   - Cam kết: *"Đánh giá của bạn sẽ được gắn huy hiệu Đã mua hàng xác thực để tăng độ tin cậy cho cộng đồng izithrift."*
   - Gọi `POST /api/v1/orders/{id}/reviews`.
7. **`M-RV-02: Seller Reviews List Screen`:**
   - Thống kê tổng quan: Điểm trung bình (⭐ 4.9/5.0) và phân bố tỷ lệ số sao (1..5 sao).
   - Danh sách đánh giá: Tên người mua (ẩn bảo mật), số sao, ngày đánh giá, sản phẩm đã mua, và nội dung nhận xét.

---

## 3. Architecture & State Management (MVVM Pattern)
- **Models:** `ConversationModel`, `MessageModel`, `NotificationModel`, `ReportModel`, `ReviewModel`, `FavoriteItemModel`.
- **Repositories:** `ChatRepository`, `NotificationRepository`, `EngagementRepository`, `ReviewRepository`.
- **ViewModels (`ChangeNotifier`):**
  - `ChatInboxViewModel`: Quản lý danh sách cuộc trò chuyện, bộ đếm chưa đọc.
  - `ChatRoomViewModel`: Quản lý tin nhắn 1-1, gửi tin nhắn, polling định kỳ theo vòng đời.
  - `NotificationViewModel`: Quản lý danh sách thông báo, đánh dấu đã đọc, điều hướng deep-link.
  - `EngagementViewModel`: Quản lý danh sách yêu thích và theo dõi tiệm.
  - `ReviewViewModel`: Submit đánh giá xác minh 1-5 sao và tải danh sách review của tiệm.

---

## 4. API Endpoints Utilized
- `GET /api/v1/conversations`
- `POST /api/v1/conversations`
- `GET /api/v1/conversations/{id}/messages`
- `POST /api/v1/conversations/{id}/messages`
- `POST /api/v1/reports`
- `GET /api/v1/notifications`
- `POST /api/v1/notifications/{id}/read`
- `POST /api/v1/notifications/read-all`
- `GET /api/v1/profile/favorites`
- `POST /api/v1/products/{id}/favorite`
- `POST /api/v1/sellers/{id}/follow`
- `POST /api/v1/orders/{id}/reviews`
- `GET /api/v1/sellers/{id}/reviews`

---

## 5. Acceptance Criteria (`Tiêu Chí Nghiệm Thu P7-11`)
- [x] **AC-P711-01:** Hộp thư tin nhắn và phòng chat 1-1 ghim đúng ngữ cảnh sản phẩm, polling nhận tin mới mượt mà.
- [x] **AC-P711-02:** Trung tâm thông báo điều hướng chính xác theo `deep_link_route` đến đúng đơn hàng hoặc phòng đấu giá.
- [x] **AC-P711-03:** Danh sách đồ yêu thích và tiệm theo dõi cập nhật tức thì khi bấm toggle.
- [x] **AC-P711-04:** Đánh giá xác minh chỉ mở được từ đơn `COMPLETED` và tính đúng lại điểm trung bình của Seller (`BR-RV-01`).
- [x] **AC-P711-05:** Viết đầy đủ Unit & Widget tests cho ViewModels và 7 màn hình trong `test/features/chat_and_engagement_test.dart` đạt **100% PASS** (17/17 PASS, tổng thể Mobile 128/128 PASS).
