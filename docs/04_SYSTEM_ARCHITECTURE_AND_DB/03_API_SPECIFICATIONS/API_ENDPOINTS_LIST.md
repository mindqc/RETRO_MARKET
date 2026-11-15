# 02. COMPLETE API ENDPOINTS & ADMIN ROUTES SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P404B-API-ENDPOINTS`
- **Version:** `1.0.0 (COMPLETE 70-SCREEN ENDPOINT MAPPING)`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 04 – System Architecture, Database Design & API Specification`
- **Compliance Ref:** `04_FUNCTIONAL_REQUIREMENTS.md`, `03_ACTOR_PERMISSION_MATRIX.md`, `SCREEN_INVENTORY.md`

---

## Chương 1. Danh Mục REST API Dành Cho Ứng Dụng Di Động Flutter (`/api/v1/*`)

### 1.1. Phân Hệ 1: Authentication, Profile & Address Book (`M-AU-01..05`, `M-PF-01..06`)

| Method & Endpoint | Auth Guard | Màn Hình Gọi | Request Payload / Query Params Chính | Response & Hành Vi Nghiệp Vụ Cốt Lõi |
| :--- | :---: | :---: | :--- | :--- |
| `GET /api/v1/bootstrap` | Optional | `M-AU-01` | — | Trả về `server_time`, cấu hình công khai từ `platform_settings` (`protection_fee_rate`, `protection_fixed_fee`, `demo_mode`) và thông tin user hiện tại (nếu có token). |
| `POST /api/v1/auth/register` | Public (`Throttle 5/m`) | `M-AU-04` | `{display_name, email, phone?, password, password_confirmation}` | Tạo nguyên tử `users`, `user_profiles`, `seller_profiles`, `carts` (`BR-AC-01`); trả về `token` + `user`. |
| `POST /api/v1/auth/login` | Public (`Throttle 5/m`) | `M-AU-03` | `{email, password, device_name?}` | Kiểm tra mật khẩu và `status == 'ACTIVE'` (`BR-AC-04`); trả về `token` + `user`. |
| `POST /api/v1/auth/logout` | `auth:sanctum` | `M-PF-06` | — | Thu hồi `currentAccessToken()` trong bảng `personal_access_tokens`. |
| `POST /api/v1/auth/forgot-password` | Public | `M-AU-05` | `{email}` | Sinh mã khôi phục lưu vào `password_reset_tokens` và gửi qua Mailpit/Log (`ASM-04`). |
| `POST /api/v1/auth/reset-password` | Public | `M-AU-05` | `{email, token, password, password_confirmation}` | Đặt lại mật khẩu mới và xóa token khôi phục. |
| `GET /api/v1/profile` | `auth:sanctum` | `M-PF-01` | — | Trả về thông tin tài khoản, `user_profiles`, `seller_profiles` và bộ đếm số lượng đơn mua theo từng trạng thái (`NAV-DEC-02`). |
| `POST /api/v1/profile` | `auth:sanctum` | `M-PF-02` | `Multipart: {display_name, phone?, bio?, avatar?}` | Cập nhật hồ sơ cá nhân & Bio Tiệm đồ si (`NFR-SEC-05`). |
| `PUT /api/v1/profile/settings` | `auth:sanctum` | `M-PF-06` | `{seasonal_decor_enabled: boolean}` | Bật/tắt lớp trang trí Giáng sinh mùa vụ (`NFR-UX-02`). |
| `PUT /api/v1/profile/password` | `auth:sanctum` | `M-PF-06` | `{current_password, password, password_confirmation}` | Đổi mật khẩu đăng nhập. |
| `GET /api/v1/profile/addresses`<br>`POST /api/v1/profile/addresses`<br>`PUT /api/v1/profile/addresses/{id}`<br>`DELETE /api/v1/profile/addresses/{id}` | `auth:sanctum` | `M-PF-03`<br>`M-PF-04` | `{recipient_name, recipient_phone, province_city, district_ward, street_address, is_default}` | CRUD sổ địa chỉ nhận hàng; khi đặt `is_default = true`, tự động hạ các địa chỉ cũ của user đó về `false`. |

---

### 1.2. Phân Hệ 2: Discovery, Search, Fixed-Price Product & Public Seller (`M-HM-01..02`, `M-DS-01..03`, `M-PR-01..02`, `M-US-03`)

| Method & Endpoint | Auth Guard | Màn Hình Gọi | Request Payload / Query Params Chính | Response & Hành Vi Nghiệp Vụ Cốt Lõi |
| :--- | :---: | :---: | :--- | :--- |
| `GET /api/v1/home` | Optional | `M-HM-01` | — | Trả về Hero Banner, danh mục nhanh, danh sách phiên đấu giá đang `LIVE`, các tiệm uy tín và lưới sản phẩm `APPROVED` mới lên kệ (`BR-PR-02`). |
| `GET /api/v1/catalog/taxonomy` | Public | `M-DS-01` | — | Trả về cây `categories` và danh sách `brands` đang `is_active = true` kèm số lượng sản phẩm `APPROVED`. |
| `GET /api/v1/products` | Optional | `M-DS-02`<br>`M-HM-02` | `?q=&category_id=&brand_id=&listing_type=&condition=&min_price=&max_price=&sort=newest\|price_asc\|price_desc\|popular&page=1` | Truy vấn trực tiếp PostgreSQL (`NFR-PER-02`) trên các bản ghi `status = 'APPROVED'`; kiểm tra `min_price <= max_price`. |
| `GET /api/v1/products/{id}` | Optional | `M-PR-01`<br>`M-PR-02` | — | Trả về chi tiết sản phẩm, toàn bộ `product_images`, `condition`, `defect_info`, `verification_level` (`BR-PR-03`), thông tin `seller`, cờ `is_owner` (`BR-AC-02`) và 4 sản phẩm liên quan. |
| `POST /api/v1/products/{id}/favorite` | `auth:sanctum` | `M-PR-01`<br>`M-PF-05` | — | Toggle lưu/bỏ lưu sản phẩm yêu thích (`favorites`) và cập nhật `products.favorite_count`. |
| `GET /api/v1/profile/favorites` | `auth:sanctum` | `M-PF-05` | `?tab=products\|sellers&status_filter=` | Trả về danh sách sản phẩm đã thích (kể cả món vừa `SOLD` / `HIDDEN`) và danh sách tiệm đang theo dõi. |
| `GET /api/v1/sellers/{id}` | Optional | `M-US-03` | `?listing_tab=approved\|auction\|sold` | Trả về hồ sơ công khai của Tiệm, `trust_score`, `average_rating`, `completed_orders_count`, cờ `is_following` và danh sách sản phẩm của tiệm. |
| `GET /api/v1/sellers/{id}/reviews` | Public | `M-US-03` | `?rating=&page=1` | Trả về danh sách đánh giá `VISIBLE` từ các đơn `COMPLETED` (`BR-RV-01`) kèm snapshot món đồ đã mua. |
| `POST /api/v1/sellers/{id}/follow` | `auth:sanctum` | `M-US-03` | — | Toggle theo dõi / hủy theo dõi Tiệm (Chặn `follower_id == seller_id` theo `BR-AC-02`). |

---

### 1.3. Phân Hệ 3: Scheduled Auctions & Concurrent Bidding (`M-AC-01` – `M-AC-05`)

| Method & Endpoint | Auth Guard | Màn Hình Gọi | Request Payload / Query Params Chính | Response & Hành Vi Nghiệp Vụ Cốt Lõi |
| :--- | :---: | :---: | :--- | :--- |
| `GET /api/v1/auctions` | Optional | `M-AC-01` | `?tab=live\|ending_soon\|upcoming\|completed&category_id=&page=1` | Trả về lịch `auction_sessions` trong ngày và lưới thẻ đấu giá theo từng tab thời gian. |
| `GET /api/v1/auctions/mine` | `auth:sanctum` | `M-AC-02` | `?tab=participating\|watchlist\|won` | Trả về các phiên user đang tham gia (kèm trạng thái `LEADING` / `OUTBID`), danh sách Watchlist và các đơn thắng đấu giá kèm đồng hồ đếm ngược 30 phút (`payment_expires_at`). |
| `GET /api/v1/auctions/{id}` | Optional | `M-AC-03` | — | Trả về chi tiết phòng đấu giá, `server_time`, `auction_ends_at`, `current_highest_bid`, `minimum_next_bid`, trạng thái đạt `reserve_price`, `extended_count` và 5 lượt bid mới nhất. |
| `GET /api/v1/auctions/{id}/bids` | Public | `M-AC-04` | `?page=1` | Trả về toàn bộ lịch sử `auction_bids` phân trang. |
| `POST /api/v1/auctions/{id}/bids` | `auth:sanctum` | `M-AC-04` | `{bid_amount: numeric}` | **Thực thi trong `DB::transaction()` + `lockForUpdate()` (`AF-03`, `AF-04`):**<br>1. Chặn `bidder_id == seller_id` (`403 BR-AC-02`).<br>2. Kiểm tra `status == 'LIVE'` và `NOW() < auction_ends_at`.<br>3. Kiểm tra bước giá hợp lệ (nếu sai trả `409 AUCTION_OUTBID_CONFLICT` kèm `latest_state`).<br>4. Nếu đặt trong 2 phút cuối (`30s` Demo Mode), tự động cộng thêm `+2 phút` (`+30s` Demo) vào `auction_ends_at` và tăng `extended_count` (`BR-AU-04`).<br>5. Tạo thông báo `AUCTION_OUTBID` cho người dẫn đầu cũ (`AF-05`). |
| `POST /api/v1/auctions/{id}/watch` | `auth:sanctum` | `M-AC-03` | — | Toggle theo dõi phiên đấu giá (`auction_watches`). |
| `POST /api/v1/auctions/{id}/close-early` | `auth:sanctum` (`Seller Owner`) | `M-AC-05` | `{confirm: true}` | **Chốt phiên sớm của Seller (`BR-AU-05`, `AF-06`):** Kiểm tra `auth.id == seller_id`, `status == 'LIVE'`, đã có `leading_bidder_id` và `current_highest_bid >= COALESCE(reserve_price, starting_price)`. Đóng phiên, tự động tạo `orders` cho người thắng (cộng `buyer_protection_fee` `DEC-04`, hạn 30 phút) và ghi `audit_logs`. |

---

### 1.4. Phân Hệ 4: Cart, Checkout Preview (Buyer Protection Fee), Mock QR Payment, Order Lifecycle & Disputes (`M-CR-01`, `M-OR-01..05`, `M-PM-01..02`, `M-RV-01`, `M-DP-01..03`)

| Method & Endpoint | Auth Guard | Màn Hình Gọi | Request Payload / Query Params Chính | Response & Hành Vi Nghiệp Vụ Cốt Lõi |
| :--- | :---: | :---: | :--- | :--- |
| `GET /api/v1/cart`<br>`POST /api/v1/cart/items`<br>`PUT /api/v1/cart/items/{id}`<br>`DELETE /api/v1/cart/items/{id}` | `auth:sanctum` | `M-CR-01` | `{product_id, quantity, is_selected}` | Quản lý giỏ hàng sản phẩm `FIXED_PRICE`, trả về danh sách gom nhóm theo từng `seller` (`BR-OR-01`), chặn thêm sản phẩm của chính mình (`BR-AC-02`). |
| `POST /api/v1/checkout/preview` | `auth:sanctum` | `M-OR-01` | `{source: 'CART'\|'BUY_NOW', product_id?, quantity?, address_id?}` | **Tính toán bảng kê chi phí tại Server (`DEC-04`, `NFR-SEC-03`):** Trả về `item_subtotal`, `shipping_fee (0đ)`, `buyer_protection_fee`, `total_amount` và địa chỉ nhận hàng mặc định. |
| `POST /api/v1/orders` | `auth:sanctum` | `M-OR-01` | `{source: 'CART'\|'BUY_NOW', product_id?, quantity?, address_id}` | **Tạo đơn hàng nguyên tử (`OF-02`):** Khóa dòng `products` (`lockForUpdate()`), kiểm tra tồn kho `available_quantity`, trừ tồn kho, đóng băng `order_items` snapshot (`BR-OR-02`), tạo phiên `payments` QR và trả về `order_id` + `payment_id`. |
| `GET /api/v1/payments/{id}` | `auth:sanctum` | `M-PM-01`<br>`M-PM-02` | — | Trả về thông tin phiên thanh toán QR (`qr_payload`, `amount`, `expires_at`, `status`) và biên lai bút toán `ESCROW_HELD`. |
| `POST /api/v1/payments/{id}/simulate-success` | `auth:sanctum` | `M-PM-01` | — | **Mô phỏng thanh toán QR thành công lũy đẳng (`OF-03`, `BR-FN-03`):** Khóa dòng `orders` & `payments` $\rightarrow$ Chuyển `payment_status = 'PAID'`, `order_status = 'PAID'`, `escrow_status = 'HELD'`, ghi bút toán `HOLD` vào `escrow_transactions` và tăng `seller_profiles.escrow_held_balance`. |
| `POST /api/v1/payments/{id}/simulate-failure` | `auth:sanctum` | `M-PM-01` | `{failure_reason?}` | Đánh dấu phiên QR `FAILED` và cho phép tạo lại mã QR mới nếu đơn chưa quá hạn `payment_expires_at`. |
| `GET /api/v1/orders/purchases` | `auth:sanctum` | `M-OR-02` | `?status=&q=&page=1` | Danh sách **Đơn mua của tôi (`My Purchases` – `NAV-DEC-02`)** theo 7 tab trạng thái. |
| `GET /api/v1/orders/{id}` | `auth:sanctum` | `M-OR-03`<br>`M-SL-06` | — | Chi tiết đơn hàng (4 trạng thái độc lập, snapshot, `shipments`, `escrow_transactions`, mốc `auto_complete_at`). |
| `POST /api/v1/orders/{id}/cancel` | `auth:sanctum` | `M-OR-04` | `{reason: string}` | **Luồng Hủy Đơn 3 Cấp Của Buyer (`DEC-06`, `DEC-07`):**<br>- Nếu `PENDING_PAYMENT`: Hủy đơn ngay, khôi phục tồn kho.<br>- Nếu `PAID`: Hủy đơn ngay, ghi bút toán `FULL_REFUND` hoàn trả **100% `total_amount`** cho Buyer.<br>- Nếu `PREPARING`: Đặt `cancellation_requested = true` chờ Seller duyệt.<br>- Nếu `SHIPPED` trở đi: Từ chối `409 INVALID_STATE_TRANSITION` (`BR-OR-04`). |
| `POST /api/v1/orders/{id}/withdraw-cancel-request` | `auth:sanctum` | `M-OR-03` | — | Cho phép Buyer rút lại yêu cầu xin hủy đơn khi đơn đang ở `PREPARING` (`UX-CHECK-02`). |
| `POST /api/v1/orders/{id}/confirm-delivery` | `auth:sanctum` (`Buyer`) | `M-OR-05` | — | **Buyer xác nhận đã nhận hàng (`OF-06`, `BR-FN-04`, `DEC-04`):** Kiểm tra `order_status == 'DELIVERED'` & `dispute_status == 'NONE'` $\rightarrow$ Chuyển `COMPLETED`, `escrow_status = 'RELEASED'`, ghi bút toán `RELEASE` và cộng **100% `item_subtotal`** vào `seller_profiles.wallet_balance` (`wallet_transactions`). |
| `POST /api/v1/orders/{id}/reviews` | `auth:sanctum` (`Buyer`) | `M-RV-01` | `{rating: 1..5, comment: string}` | Tạo đánh giá xác thực khi `order_status == 'COMPLETED'` (`BR-RV-01`) và cập nhật `seller_profiles.average_rating`. |
| `POST /api/v1/orders/{id}/disputes` | `auth:sanctum` (`Buyer`) | `M-DP-01` | `Multipart: {reason_category, description, evidences[]}` | **Mở khiếu nại & Khóa cứng giải ngân (`DEC-03`, `BR-DP-02`):** Cho phép khi `order_status IN ('SHIPPED', 'DELIVERED')` $\rightarrow$ Tạo bản ghi `disputes`, chuyển `orders.dispute_status = 'OPEN'`, ghi nhận `escrow_frozen_at`. |
| `GET /api/v1/disputes`<br>`GET /api/v1/disputes/{id}`<br>`POST /api/v1/disputes/{id}/evidences` | `auth:sanctum` | `M-DP-02`<br>`M-DP-03` | `Multipart: {message_note?, file?}` | Xem danh sách/chi tiết hồ sơ tranh chấp và tải bổ sung bằng chứng (cho cả Buyer và Seller đối chứng `SF-11`). |

---

### 1.5. Phân Hệ 5: Seller Center, Listings, Order Fulfillment & Wallet Ledger (`M-SL-01` – `M-SL-08`)

| Method & Endpoint | Auth Guard | Màn Hình Gọi | Request Payload / Query Params Chính | Response & Hành Vi Nghiệp Vụ Cốt Lõi |
| :--- | :---: | :---: | :--- | :--- |
| `GET /api/v1/seller/dashboard` | `auth:sanctum` | `M-SL-01` | — | Trả về `wallet_balance`, `escrow_held_balance` và bộ đếm việc cần xử lý (`PAID` chờ chuẩn bị, `PREPARING` có khách xin hủy, bài đăng bị `REJECTED`, đơn `DISPUTED`). |
| `GET /api/v1/seller/products`<br>`POST /api/v1/seller/products`<br>`PUT /api/v1/seller/products/{id}` | `auth:sanctum` | `M-SL-02`<br>`M-SL-03`<br>`M-SL-04` | `Multipart: {title, category_id, brand_id?, condition, defect_info, listing_type, price, quantity, auction_session_id?, min_bid_increment?, reserve_price?, submit_for_review: bool, images[]}` | Quản lý sản phẩm theo 7 trạng thái; tạo mới hoặc sửa bài gửi duyệt lại (`Resubmit` từ `REJECTED` $\rightarrow$ `PENDING_REVIEW` theo `DEC-05`); khóa sửa khi đã có bid/đơn active (`BR-PR-05`). |
| `POST /api/v1/seller/products/{id}/relist` | `auth:sanctum` | `M-SL-02` | `{auction_session_id, starting_price, min_bid_increment, reserve_price?}` | **Đăng lại sản phẩm đấu giá (`DEC-02`, `AF-09`):** Khi phiên cũ ở trạng thái `ENDED_UNSOLD` hoặc `WINNER_DEFAULTED` (quá 30p không trả tiền), tạo bản ghi `auctions` mới gắn vào phiên tiếp theo. |
| `GET /api/v1/seller/orders` | `auth:sanctum` | `M-SL-05` | `?status=&cancellation_requested=&page=1` | Danh sách **Đơn bán của Tiệm (`Seller Orders` – `NAV-DEC-02`)**. |
| `POST /api/v1/seller/orders/{id}/prepare` | `auth:sanctum` | `M-SL-06` | — | Seller xác nhận bắt đầu đóng gói (`PAID` $\rightarrow$ `PREPARING`). |
| `POST /api/v1/seller/orders/{id}/respond-cancel` | `auth:sanctum` | `M-SL-06` | `{decision: 'APPROVE'\|'REJECT', note?}` | **Seller duyệt yêu cầu xin hủy đơn ở `PREPARING` (`DEC-06`):**<br>- Nếu `APPROVE`: Hủy đơn, hoàn trả **100% `total_amount`** cho Buyer (`DEC-07`), khôi phục tồn kho.<br>- Nếu `REJECT`: Giữ trạng thái `PREPARING` để tiếp tục giao hàng. |
| `POST /api/v1/seller/orders/{id}/ship` | `auth:sanctum` | `M-SL-07` | `{carrier_name, tracking_code, shipping_note?}` | Cập nhật vận đơn thủ công (`PREPARING` $\rightarrow$ `SHIPPED` – `SF-10`). |
| `POST /api/v1/seller/orders/{id}/deliver` | `auth:sanctum` | `M-SL-07` | — | Cập nhật đã giao hàng tới nơi (`SHIPPED` $\rightarrow$ `DELIVERED`), đồng thời tính và **đóng băng cột `auto_complete_at`** (`NOW() + 24h` hoặc `+2m` Demo Mode – `BR-OR-05`). |
| `GET /api/v1/seller/wallet` | `auth:sanctum` | `M-SL-08` | `?tab=wallet_tx\|escrow_tx&page=1` | Trả về số dư khả dụng, số dư đang giữ trong Escrow và lịch sử sổ cái bất biến (`Read-Only`). |

---

### 1.6. Phân Hệ 6: 1-on-1 Chat (HTTP Polling), Notifications & Reports (`M-CM-01..03`, `M-NT-01`)

| Method & Endpoint | Auth Guard | Màn Hình Gọi | Request Payload / Query Params Chính | Response & Hành Vi Nghiệp Vụ Cốt Lõi |
| :--- | :---: | :---: | :--- | :--- |
| `GET /api/v1/conversations`<br>`POST /api/v1/conversations` | `auth:sanctum` | `M-CM-01`<br>`M-PR-01` | `{recipient_id, context_product_id?, context_order_id?}` | Lấy danh sách hộp thư hoặc mở/lấy phòng chat 1-1 với đối phương. |
| `GET /api/v1/conversations/{id}/messages`<br>`POST /api/v1/conversations/{id}/messages` | `auth:sanctum` | `M-CM-02` | `GET: ?after_id=120` *(HTTP Polling 3–5s)*<br>`POST: {message_text, attached_product_id?}` | Lấy các tin nhắn mới có `id > after_id`, đánh dấu `is_read = true` và gửi tin nhắn mới (`ADR-08`, `NFR-PER-03`). |
| `GET /api/v1/notifications`<br>`POST /api/v1/notifications/{id}/read`<br>`POST /api/v1/notifications/read-all` | `auth:sanctum` | `M-NT-01` | `?category=all\|auction\|order\|system` | Lấy danh sách thông báo kèm `deep_link_route` và đánh dấu đã đọc. |
| `POST /api/v1/reports` | `auth:sanctum` | `M-CM-03` | `{target_type: 'PRODUCT'\|'USER'\|'CONVERSATION', target_id, reason_category, description, block_user?: bool}` | Gửi báo cáo vi phạm về hàng chờ Moderator (`A-CM-01`) và tùy chọn chặn chat. |

---

## Chương 2. Danh Mục Web Routes Dành Cho Laravel Blade Admin Dashboard (`/admin/*`)

| Nhóm Quản Trị | Method & Route Path | Middleware Phân Quyền (`RBAC`) | Màn Hình Blade | Chức Năng Thực Thi & Ghi Nhận Audit Log |
| :--- | :--- | :---: | :---: | :--- |
| **1. Auth & KPI** | `GET/POST /admin/login`<br>`POST /admin/logout`<br>`GET /admin/dashboard` | `guest` / `auth`, `role:admin,moderator,support` | `A-AU-01`<br>`A-DB-01` | Đăng nhập nội bộ (chặn `registered_user` – `PERM-AU-01`); hiển thị KPI truy vấn trực tiếp từ PostgreSQL (`CON-04`). |
| **2. Moderation & Catalog** | `GET /admin/moderation/products`<br>`GET /admin/moderation/products/{id}`<br>`POST /admin/moderation/products/{id}/approve`<br>`POST /admin/moderation/products/{id}/reject` | `role:admin,moderator` | `A-MD-01`<br>`A-MD-02` | Kiểm duyệt sản phẩm, gán `verification_level`, bắt buộc nhập `reason` khi Reject (`DEC-05`, `BR-PR-04`). |
| | `GET /admin/products`<br>`POST /admin/products/{id}/toggle-visibility`<br>`GET/POST /admin/catalog`<br>`GET/POST /admin/moderation/reports` | `role:admin,moderator` | `A-PR-01`<br>`A-CT-01`<br>`A-CM-01` | Ẩn/khôi phục sản phẩm vi phạm; CRUD Danh mục/Thương hiệu (Admin); xử lý báo cáo & ẩn đánh giá vi phạm. |
| **3. Auctions** | `GET/POST /admin/auctions/sessions`<br>`GET /admin/auctions`<br>`GET /admin/auctions/{id}`<br>`POST /admin/auctions/{id}/cancel` | `role:admin` *(Mod: Read-only)* | `A-AC-01`<br>`A-AC-02`<br>`A-AC-03` | Cấu hình khung giờ phiên đấu giá hàng ngày; kiểm tra lịch sử trả giá và hủy phiên đấu giá gian lận (`PERM-AC-09`). |
| **4. Orders, Escrow & Disputes** | `GET /admin/orders`<br>`GET /admin/orders/{id}`<br>`GET /admin/payments`<br>`GET /admin/escrow` | `role:admin,support` *(Payments & Escrow: Admin only)* | `A-OR-01`<br>`A-OR-02`<br>`A-PM-01`<br>`A-ES-01` | Giám sát đơn hàng 4 trạng thái, bản chụp snapshot và **Sổ cái Escrow/Ví Read-Only bất biến (`BR-FN-07`)**. |
| | `GET /admin/disputes`<br>`GET /admin/disputes/{id}`<br>`POST /admin/disputes/{id}/request-evidence`<br>`POST /admin/disputes/{id}/resolve` | `request-evidence`: `role:admin,support`<br>**`resolve`: `role:admin` ONLY (`PERM-CM-09`)** | `A-DP-01`<br>`A-DP-02` | Support Staff & Admin yêu cầu bổ sung bằng chứng; **chỉ Administrator** được thực thi 1 trong 3 phán quyết tài chính (`APPROVE_BUYER_REFUND` hoàn 100% `total_amount` `DEC-07`, `RELEASE_TO_SELLER` giải ngân 100% `item_subtotal` `DEC-04`, hoặc `PARTIAL_REFUND` `BR-FN-06`). |
| **5. System & DevTools** | `GET/POST /admin/users`<br>`GET/POST /admin/settings`<br>`GET /admin/audit-logs`<br>`GET/POST /admin/dev-tools` | `role:admin`<br>*(DevTools: + `EnsureDemoModeEnabled`)* | `A-US-01..02`<br>`A-ST-01`<br>`A-AD-01`<br>`A-DT-01` | Khóa/mở khóa user & đổi role; cấu hình `Buyer Protection Fee` & thời gian Demo; xem `audit_logs`; kích hoạt thủ công các Scheduled Jobs lũy đẳng (`ADR-05`). |