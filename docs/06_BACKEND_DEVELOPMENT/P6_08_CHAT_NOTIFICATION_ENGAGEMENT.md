# P6-08: 1-ON-1 CHAT (HTTP POLLING), IN-APP NOTIFICATIONS, VERIFIED REVIEWS & ENGAGEMENT SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P608-CHAT-NOTIFICATION-ENGAGEMENT`
- **Version:** `1.0.0`
- **Status:** DONE / APPROVED
- **Phase:** `Phase 06 – Task P6-08`
- **Dependencies:** `P6-04 (Products)`, `P6-06 (Completed Orders)`, `P6-07 (Auctions)`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
- **Mục tiêu:** Hiện thực hóa hệ thống Chat 1-1 có ghim ngữ cảnh Sản phẩm/Đơn hàng và hỗ trợ Controlled HTTP Short-Polling (`?after_id=` – `ADR-08`, `NFR-PER-03`), Trung tâm Thông báo In-App hỗ trợ Deep-Linking (`M-NT-01`), Đánh giá 1–5 sao xác thực từ đơn hàng đã `COMPLETED` (`M-RV-01` – `BR-RV-01`), Yêu thích sản phẩm & Theo dõi tiệm (`M-PF-05`), và Báo cáo vi phạm (`M-CM-03`, `A-CM-01`).
- **Phạm vi:** `ConversationChatService`, `NotificationService`, `ReviewService`, `EngagementService`, `ViolationReportService` và các API tương ứng.

## 2. Source Documents (`Tài Liệu Nguồn`)
- `API_ENDPOINTS_LIST.md` (Mục 1.2, 1.4, 1.6), `06_BUSINESS_RULES.md` (`BR-AC-02`, `BR-RV-01`), `08_ASSUMPTIONS_AND_DECISIONS.md` (`ADR-08`), `05_NON_FUNCTIONAL_REQUIREMENTS.md` (`NFR-PER-03`).
- Models: `Conversation`, `Message`, `Notification`, `Review`, `Favorite`, `SellerFollow`, `Report`, `Order`, `Product`, `SellerProfile`.

## 3. Technical Design & Domain Services (`Thiết Kế Kỹ Thuật & Dịch Vụ Nghiệp Vụ`)
1. **`App\Services\Communication\ConversationChatService`:**
   - `startOrGetConversation(User $sender, int $recipientId, ?int $contextProductId, ?int $contextOrderId): Conversation`:
     - Chặn tự chat với chính mình (`$sender->id === $recipientId` $\rightarrow$ `SelfTransactionForbiddenException`).
     - Gọi `Conversation::normalizeParticipants($sender->id, $recipientId)` để luôn đảm bảo `user_one_id < user_two_id` (`OQ-P6-03`, `chk_conversation_user_order`).
   - `pollMessages(User $viewer, Conversation $conversation, ?int $afterId): Collection`:
     - Kiểm tra `$viewer` là 1 trong 2 người tham gia phòng chat (`ConversationPolicy::view`).
     - Nếu có `?after_id=`, chỉ truy vấn `messages` có `id > $afterId` theo chỉ mục `idx_messages_polling (conversation_id, id ASC)` (`NFR-PER-03`).
     - Tự động đánh dấu `is_read = true`, `read_at = now()` cho các tin nhắn của đối phương gửi tới `$viewer`.
   - `sendMessage(User $sender, Conversation $conversation, string $text, ?int $attachedProductId): Message`:
     - Nếu `$conversation->blocked_by_user_id !== null`, ném `InvalidStateTransitionException` (`409`, `"Cuộc trò chuyện này đã bị chặn."`).
     - Lưu `Message` và cập nhật `last_message_preview`, `last_message_at = now()` trên `Conversation`.
2. **`App\Services\Communication\NotificationService`:**
   - Danh sách thông báo phân trang theo `category` (`all`, `auction`, `order`, `system`), đếm số thông báo chưa đọc (`unread_count`), đánh dấu đã đọc 1 thông báo hoặc toàn bộ (`read-all`).
3. **`App\Services\Engagement\ReviewService` (`BR-RV-01`):**
   - `createVerifiedOrderReview(User $buyer, Order $order, int $rating, string $comment): Review`:
     - Kiểm tra `$buyer->id === $order->buyer_id` và **`$order->order_status === 'COMPLETED'`** (`BR-RV-01`).
     - Kiểm tra đơn hàng chưa từng được đánh giá (`Review::where('order_id', $order->id)->exists()` $\rightarrow$ nếu đã có ném `InvalidStateTransitionException` `409`).
     - Trong `DB::transaction()`: Tạo bản ghi `reviews` và tính lại `average_rating`, `review_count` trên `SellerProfile` của `$order->seller_id`.
4. **`App\Services\Engagement\EngagementService` & `ViolationReportService`:**
   - `toggleFavoriteProduct(User $user, Product $product): array`: Thêm/xóa `favorites` và đồng bộ `products.favorite_count`.
   - `toggleFollowSeller(User $follower, User $seller): array`: Chặn `$follower->id === $seller->id` (`BR-AC-02`).
   - `submitReport(User $reporter, array $data): Report`: Tạo bản ghi `reports` (`PRODUCT`, `USER`, `CONVERSATION`); nếu có cờ `block_user = true` trên cuộc trò chuyện thì gán `conversations.blocked_by_user_id = $reporter->id`.

## 4. Files to Create or Modify (`File Mã Nguồn Dự Kiến`)
- `backend/app/Services/Communication/ConversationChatService.php`
- `backend/app/Services/Communication/NotificationService.php`
- `backend/app/Services/Engagement/ReviewService.php`
- `backend/app/Services/Engagement/EngagementService.php`
- `backend/app/Services/Governance/ViolationReportService.php`
- `backend/app/Http/Controllers/Api/V1/ConversationController.php`, `NotificationController.php`, `ReviewController.php`, `EngagementController.php`, `ReportController.php`
- `backend/tests/Feature/Api/V1/ChatNotificationAndEngagementTest.php`

## 5. API Endpoints (`Danh Sách Endpoints`)
- `POST /api/v1/products/{id}/favorite`, `GET /api/v1/profile/favorites`, `POST /api/v1/sellers/{id}/follow`
- `POST /api/v1/orders/{id}/reviews`
- `GET /api/v1/conversations`, `POST /api/v1/conversations`
- `GET /api/v1/conversations/{id}/messages` (`throttle:polling`), `POST /api/v1/conversations/{id}/messages`
- `GET /api/v1/notifications`, `POST /api/v1/notifications/{id}/read`, `POST /api/v1/notifications/read-all`
- `POST /api/v1/reports`

## 6. Business Rules, Validation & Authorization
- **Business Rules:** `BR-AC-02` (Chặn tự theo dõi, tự chat, tự đánh giá), `BR-RV-01` (Chỉ đánh giá đơn đã `COMPLETED`, mỗi đơn tối đa 1 lần), `ADR-08` & `NFR-PER-03` (Incremental HTTP Polling `?after_id=`).

## 7. Test Cases & Acceptance Criteria (`Tiêu Chí Nghiệm Thu`)
1. `test_toggle_favorite_and_follow_enforces_anti_self_follow_rule`
2. `test_verified_review_succeeds_only_for_completed_order_and_updates_seller_average_rating`
3. `test_buyer_cannot_review_uncompleted_order_or_submit_duplicate_review_409`
4. `test_chat_conversation_normalizes_participant_order_and_supports_incremental_after_id_polling`
5. `test_reporting_conversation_with_block_flag_prevents_further_messages`
6. `test_notifications_list_and_mark_as_read_flow`
- **Acceptance Criteria:** 100% bài test trong `ChatNotificationAndEngagementTest.php` đạt `PASS`.

## 8. Risks & Mitigation
- **Rủi ro:** Người dùng thứ 3 đoán ID phòng chat (`conversations/{id}/messages`) để đọc trộm tin nhắn.
- **Giảm thiểu:** `ConversationPolicy` kiểm tra nghiêm ngặt `$user->id === $conversation->user_one_id || $user->id === $conversation->user_two_id` (hoặc Admin/Support khi xử lý báo cáo vi phạm).

## 9. Implementation & Automated Test Verification (`Kết Quả Thực Thi`)
- **Status:** DONE / APPROVED
- **Domain Services Implemented:**
  1. `App\Services\Communication\ConversationChatService`: `listUserConversations` (với đếm unread count), `startOrGetConversation` (chuẩn hóa `user_one_id < user_two_id` theo `OQ-P6-03` và chặn tự chat `BR-AC-02`), `pollMessages` (HTTP short-polling với `?after_id=` `ADR-08`, tự động đánh dấu đã đọc), `sendMessage` (chặn gửi tin nhắn khi cuộc trò chuyện bị chặn `409`).
  2. `App\Services\Communication\NotificationService`: `listUserNotifications` (hỗ trợ lọc category `auction`, `order`, `product`, `dispute`, `system` và đếm `unread_count`), `markAsRead`, `markAllAsRead`.
  3. `App\Services\Engagement\ReviewService`: `createVerifiedOrderReview` (khóa dòng `lockForUpdate()`, bắt buộc đơn đã `COMPLETED` `BR-RV-01`, chặn đánh giá trùng, tính lại `average_rating` và `review_count` trên `SellerProfile`, gửi notification cho seller).
  4. `App\Services\Engagement\EngagementService`: `toggleFavoriteProduct` (đồng bộ `favorite_count`), `listFavoriteProducts`, `toggleFollowSeller` (chặn tự theo dõi `BR-AC-02`).
  5. `App\Services\Governance\ViolationReportService`: `submitReport` (tạo báo cáo vi phạm `PRODUCT`, `USER`, `CONVERSATION`, hỗ trợ cờ `block_conversation`).
- **FormRequests & Resources Created:** `StartConversationRequest`, `SendMessageRequest`, `StoreReviewRequest`, `StoreReportRequest`, `ConversationResource`, `MessageResource`, `NotificationResource`, `ReportResource`. 12 routes đăng ký tại `api.php`.
- **Automated Verification:**
  - `ChatNotificationAndEngagementTest.php`: **8/8 tests PASS** (62 assertions).
  - Full PHPUnit Test Suite: **78/78 tests PASS** (903 assertions, 0 errors, 0 failures).
  - Seeders Reconciliation (`db:verify-seeders`): **100% integrity, ZERO ledger drift**.
