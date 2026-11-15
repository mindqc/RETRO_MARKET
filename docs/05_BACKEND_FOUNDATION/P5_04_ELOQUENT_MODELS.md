# 04. ELOQUENT MODELS, RELATIONSHIPS & ORM INTEGRITY SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P504-ELOQUENT-MODELS`
- **Version:** `1.0.0`
- **Status:** `DONE / APPROVED`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 05 – Backend Foundation & Database Implementation (Task P5-04)`
- **Compliance Ref:** `ERD_RELATIONSHIPS.md`, `DB_01..03`, `BR-AC-01..04`, `BR-FN-01..07`, `NFR-REL-04`

---

## Chương 1. Quy Chuẩn Kiến Trúc Eloquent Models (`ORM Engineering Standards`)

Toàn bộ **32 Domain Models** trong `backend/app/Models/` tuân thủ 5 nguyên tắc thiết kế:
1. **Bảo mật Mass-Assignment (`Explicit $fillable & Sensitive Field Guarding`):**
   - Khai báo tường minh `$fillable` cho từng Model.
   - Đối với các cột nhạy cảm về phân quyền và tài chính (như `seller_profiles.wallet_balance`, `seller_profiles.escrow_held_balance`), mọi thao tác thay đổi số dư trong thực tế bắt buộc đi qua `EscrowReleaseService` / `MockQrPaymentService` kèm khóa dòng `lockForUpdate()`.
2. **Chuẩn hóa Timestamp Constants (`CREATED_AT` / `UPDATED_AT`):**
   - **19 Models có cả `created_at` và `updated_at`:** `User`, `UserProfile`, `SellerProfile`, `UserAddress`, `Category`, `Brand`, `Product`, `Conversation`, `AuctionSession`, `Auction`, `Cart`, `CartItem`, `Order`, `Shipment`, `Payment`, `Dispute`, `Review`, `Report`.
   - **12 Models chỉ có `created_at` (`public const UPDATED_AT = null;`):** `ProductImage`, `ProductModerationLog`, `Favorite`, `SellerFollow`, `Message`, `Notification`, `AuditLog`, `AuctionBid`, `AuctionWatch`, `OrderItem`, `EscrowTransaction`, `WalletTransaction`, `DisputeEvidence` *(13 Models append-only/event-based)*.
   - **1 Model chỉ có `updated_at` (`public const CREATED_AT = null;`):** `PlatformSetting` (`key` là `VARCHAR(80) PRIMARY KEY`).
3. **Ép kiểu Dữ liệu Chuẩn Xác (`Strict Attribute Casting`):**
   - Tiền tệ `NUMERIC(15,2)` $\rightarrow$ `'decimal:2'`.
   - Tỷ lệ phí `NUMERIC(5,4)` $\rightarrow$ `'decimal:4'`.
   - Cột `JSONB` (`shipping_address_snapshot`, `old_values`, `new_values`) $\rightarrow$ `'array'`.
   - Cột `TIMESTAMPTZ` $\rightarrow$ `'datetime'`.
   - Cột trạng thái & vai trò $\rightarrow$ Ánh xạ với 9 Backed Enums trong `App\Enums\*` (`UserRole`, `UserStatus`, `ProductCondition`, `ProductStatus`, `AuctionStatus`, `OrderStatus`, `PaymentStatus`, `EscrowStatus`, `DisputeStatus`).
4. **Trait Bảo Vệ Bản Ghi Bất Biến (`App\Models\Concerns\ImmutableLedgerRecord`):**
   - Gắn vào `EscrowTransaction`, `WalletTransaction`, `AuctionBid`, `OrderItem`, `ProductModerationLog`, `AuditLog` để chặn mọi lệnh `update()` hoặc `delete()` ở tầng Eloquent (`BR-FN-07`, `BR-AU-02`, `BR-AD-02`).

---

## Chương 2. Danh Mục 32 Eloquent Models & Bản Đồ Quan Hệ (`Complete Model & Relationship Matrix`)

### 2.1. Nhóm 1: Identity, Unified Profiles, Catalog & Products (`11 Models`)

| STT | Model Class (`App\Models\*`) | Bảng DB | Timestamp Config | Các Phương Thức Quan Hệ (`Eloquent Relationships`) |
| :-: | :--- | :--- | :---: | :--- |
| 01 | `User` | `users` | `Both` | - `profile(): HasOne(UserProfile)`<br>- `sellerProfile(): HasOne(SellerProfile)`<br>- `addresses(): HasMany(UserAddress)`<br>- `cart(): HasOne(Cart)`<br>- `products(): HasMany(Product, 'seller_id')`<br>- `auctionsAsSeller(): HasMany(Auction, 'seller_id')`<br>- `auctionBids(): HasMany(AuctionBid, 'bidder_id')`<br>- `auctionWatches(): HasMany(AuctionWatch, 'user_id')`<br>- `buyerOrders(): HasMany(Order, 'buyer_id')`<br>- `sellerOrders(): HasMany(Order, 'seller_id')`<br>- `walletTransactions(): HasMany(WalletTransaction, 'seller_id')`<br>- `favorites(): HasMany(Favorite, 'user_id')`<br>- `followingSellers(): HasMany(SellerFollow, 'follower_id')`<br>- `followers(): HasMany(SellerFollow, 'seller_id')`<br>- `notifications(): HasMany(Notification, 'user_id')`<br>- `reviewsWritten(): HasMany(Review, 'reviewer_id')`<br>- `reviewsReceived(): HasMany(Review, 'seller_id')` |
| 02 | `UserProfile` | `user_profiles` | `Both` | - `user(): BelongsTo(User, 'user_id')` |
| 03 | `SellerProfile` | `seller_profiles` | `Both` | - `user(): BelongsTo(User, 'user_id')` |
| 04 | `UserAddress` | `user_addresses` | `Both` | - `user(): BelongsTo(User, 'user_id')` |
| 05 | `Category` | `categories` | `Both` | - `parent(): BelongsTo(Category, 'parent_id')`<br>- `children(): HasMany(Category, 'parent_id')`<br>- `products(): HasMany(Product, 'category_id')` |
| 06 | `Brand` | `brands` | `Both` | - `products(): HasMany(Product, 'brand_id')` |
| 07 | `Product` | `products` | `Both` | - `seller(): BelongsTo(User, 'seller_id')`<br>- `category(): BelongsTo(Category, 'category_id')`<br>- `brand(): BelongsTo(Brand, 'brand_id')`<br>- `approver(): BelongsTo(User, 'approved_by')`<br>- `images(): HasMany(ProductImage, 'product_id')`<br>- `primaryImage(): HasOne(ProductImage, 'product_id')->where('is_primary', true)`<br>- `moderationLogs(): HasMany(ProductModerationLog, 'product_id')`<br>- `auctions(): HasMany(Auction, 'product_id')`<br>- `activeAuction(): HasOne(Auction, 'product_id')->whereIn('status', ['SCHEDULED', 'LIVE'])`<br>- `favorites(): HasMany(Favorite, 'product_id')`<br>- `orderItems(): HasMany(OrderItem, 'product_id')`<br>- `reviews(): HasMany(Review, 'product_id')` |
| 08 | `ProductImage` | `product_images` | `created_at only` | - `product(): BelongsTo(Product, 'product_id')` |
| 09 | `ProductModerationLog` | `product_moderation_logs` | `created_at only`<br>*(Immutable)* | - `product(): BelongsTo(Product, 'product_id')`<br>- `moderator(): BelongsTo(User, 'moderator_id')` |
| 10 | `PlatformSetting` | `platform_settings` | `updated_at only`<br>*(PK: `key` string)* | - `updater(): BelongsTo(User, 'updated_by')`<br>- Helper tĩnh: `PlatformSetting::getValue(string $key, mixed $default = null)` |
| 11 | `AuditLog` | `audit_logs` | `created_at only`<br>*(Immutable)* | - `actor(): BelongsTo(User, 'actor_id')` |

---

### 2.2. Nhóm 2: Scheduled Auctions & Concurrent Bidding (`4 Models`)

| STT | Model Class (`App\Models\*`) | Bảng DB | Timestamp Config | Các Phương Thức Quan Hệ (`Eloquent Relationships`) |
| :-: | :--- | :--- | :---: | :--- |
| 12 | `AuctionSession` | `auction_sessions` | `Both` | - `creator(): BelongsTo(User, 'created_by')`<br>- `auctions(): HasMany(Auction, 'session_id')` |
| 13 | `Auction` | `auctions` | `Both` | - `product(): BelongsTo(Product, 'product_id')`<br>- `seller(): BelongsTo(User, 'seller_id')`<br>- `session(): BelongsTo(AuctionSession, 'session_id')`<br>- `leadingBidder(): BelongsTo(User, 'leading_bidder_id')`<br>- `winner(): BelongsTo(User, 'winner_id')`<br>- `bids(): HasMany(AuctionBid, 'auction_id')`<br>- `watches(): HasMany(AuctionWatch, 'auction_id')`<br>- `order(): HasOne(Order, 'auction_id')` |
| 14 | `AuctionBid` | `auction_bids` | `created_at only`<br>*(Immutable)* | - `auction(): BelongsTo(Auction, 'auction_id')`<br>- `bidder(): BelongsTo(User, 'bidder_id')` |
| 15 | `AuctionWatch` | `auction_watches` | `created_at only` | - `auction(): BelongsTo(Auction, 'auction_id')`<br>- `user(): BelongsTo(User, 'user_id')` |

---

### 2.3. Nhóm 3: Cart, 4-State Orders, Payments & Immutable Ledgers (`8 Models`)

| STT | Model Class (`App\Models\*`) | Bảng DB | Timestamp Config | Các Phương Thức Quan Hệ (`Eloquent Relationships`) |
| :-: | :--- | :--- | :---: | :--- |
| 16 | `Cart` | `carts` | `Both` | - `user(): BelongsTo(User, 'user_id')`<br>- `items(): HasMany(CartItem, 'cart_id')` |
| 17 | `CartItem` | `cart_items` | `Both` | - `cart(): BelongsTo(Cart, 'cart_id')`<br>- `product(): BelongsTo(Product, 'product_id')`<br>- `seller(): BelongsTo(User, 'seller_id')` |
| 18 | `Order` | `orders` | `Both` | - `buyer(): BelongsTo(User, 'buyer_id')`<br>- `seller(): BelongsTo(User, 'seller_id')`<br>- `auction(): BelongsTo(Auction, 'auction_id')`<br>- `items(): HasMany(OrderItem, 'order_id')`<br>- `shipment(): HasOne(Shipment, 'order_id')`<br>- `payments(): HasMany(Payment, 'order_id')`<br>- `paidPayment(): HasOne(Payment, 'order_id')->where('status', 'PAID')`<br>- `escrowTransactions(): HasMany(EscrowTransaction, 'order_id')`<br>- `walletTransaction(): HasOne(WalletTransaction, 'order_id')`<br>- `dispute(): HasOne(Dispute, 'order_id')`<br>- `review(): HasOne(Review, 'order_id')` |
| 19 | `OrderItem` | `order_items` | `created_at only`<br>*(Immutable)* | - `order(): BelongsTo(Order, 'order_id')`<br>- `product(): BelongsTo(Product, 'product_id')` |
| 20 | `Shipment` | `shipments` | `Both` | - `order(): BelongsTo(Order, 'order_id')`<br>- `updater(): BelongsTo(User, 'updated_by')` |
| 21 | `Payment` | `payments` | `Both` | - `order(): BelongsTo(Order, 'order_id')`<br>- `payer(): BelongsTo(User, 'payer_id')`<br>- `escrowTransactions(): HasMany(EscrowTransaction, 'payment_id')` |
| 22 | `EscrowTransaction` | `escrow_transactions` | `created_at only`<br>*(Immutable)* | - `order(): BelongsTo(Order, 'order_id')`<br>- `payment(): BelongsTo(Payment, 'payment_id')`<br>- `buyer(): BelongsTo(User, 'buyer_id')`<br>- `seller(): BelongsTo(User, 'seller_id')`<br>- `triggeredBy(): BelongsTo(User, 'triggered_by_user_id')`<br>- `walletTransaction(): HasOne(WalletTransaction, 'escrow_transaction_id')` |
| 23 | `WalletTransaction` | `wallet_transactions` | `created_at only`<br>*(Immutable)* | - `seller(): BelongsTo(User, 'seller_id')`<br>- `order(): BelongsTo(Order, 'order_id')`<br>- `escrowTransaction(): BelongsTo(EscrowTransaction, 'escrow_transaction_id')` |

---

### 2.4. Nhóm 4: Disputes, Verified Reviews, Chat 1-1 & Engagement (`9 Models`)

| STT | Model Class (`App\Models\*`) | Bảng DB | Timestamp Config | Các Phương Thức Quan Hệ (`Eloquent Relationships`) |
| :-: | :--- | :--- | :---: | :--- |
| 24 | `Dispute` | `disputes` | `Both` | - `order(): BelongsTo(Order, 'order_id')`<br>- `buyer(): BelongsTo(User, 'buyer_id')`<br>- `seller(): BelongsTo(User, 'seller_id')`<br>- `assignedSupport(): BelongsTo(User, 'assigned_support_id')`<br>- `resolvedByAdmin(): BelongsTo(User, 'resolved_by_admin_id')`<br>- `evidences(): HasMany(DisputeEvidence, 'dispute_id')` |
| 25 | `DisputeEvidence` | `dispute_evidences` | `created_at only` | - `dispute(): BelongsTo(Dispute, 'dispute_id')`<br>- `uploader(): BelongsTo(User, 'uploader_id')` |
| 26 | `Review` | `reviews` | `Both` | - `order(): BelongsTo(Order, 'order_id')`<br>- `product(): BelongsTo(Product, 'product_id')`<br>- `reviewer(): BelongsTo(User, 'reviewer_id')`<br>- `seller(): BelongsTo(User, 'seller_id')`<br>- `hiddenByUser(): BelongsTo(User, 'hidden_by')` |
| 27 | `Report` | `reports` | `Both` | - `reporter(): BelongsTo(User, 'reporter_id')`<br>- `handler(): BelongsTo(User, 'handled_by')` |
| 28 | `Favorite` | `favorites` | `created_at only` | - `user(): BelongsTo(User, 'user_id')`<br>- `product(): BelongsTo(Product, 'product_id')` |
| 29 | `SellerFollow` | `seller_follows` | `created_at only` | - `follower(): BelongsTo(User, 'follower_id')`<br>- `seller(): BelongsTo(User, 'seller_id')` |
| 30 | `Conversation` | `conversations` | `Both` | - `userOne(): BelongsTo(User, 'user_one_id')`<br>- `userTwo(): BelongsTo(User, 'user_two_id')`<br>- `contextProduct(): BelongsTo(Product, 'context_product_id')`<br>- `contextOrder(): BelongsTo(Order, 'context_order_id')`<br>- `blockedByUser(): BelongsTo(User, 'blocked_by_user_id')`<br>- `messages(): HasMany(Message, 'conversation_id')` |
| 31 | `Message` | `messages` | `created_at only` | - `conversation(): BelongsTo(Conversation, 'conversation_id')`<br>- `sender(): BelongsTo(User, 'sender_id')`<br>- `attachedProduct(): BelongsTo(Product, 'attached_product_id')` |
| 32 | `Notification` | `notifications` | `created_at only` | - `user(): BelongsTo(User, 'user_id')` |

---

## Chương 3. Tiêu Chí Nghiệm Thu & Các Bước Kiểm Tra `P5-04` (`Acceptance Criteria`)

- [x] **AC-P504-01 (32 Models Instantiation & Schema Mapping):** Cả 32 Models đều khởi tạo thành công, khớp tên bảng (`getTable()`) và danh sách cột thực tế trong `information_schema.columns` của PostgreSQL 18.
- [x] **AC-P504-02 (Relationship Signature Verification):** Toàn bộ các phương thức quan hệ (`HasOne`, `HasMany`, `BelongsTo`) trên cả 32 Models đều trả về đúng instance của `Illuminate\Database\Eloquent\Relations\Relation` và sinh câu lệnh SQL hợp lệ không lỗi cột khóa ngoại.
- [x] **AC-P504-03 (Auth Password Column & Casts):** Model `User` trả về `getAuthPasswordName() === 'password_hash'`, ẩn `password_hash` khi serialize JSON và hỗ trợ kiểm tra quyền nhanh (`isAdmin()`, `isModerator()`, `isSupport()`, `isActive()`).
- [x] **AC-P504-04 (Append-Only Immutability Guard):** Các Model sổ cái bất biến (`EscrowTransaction`, `WalletTransaction`, `AuctionBid`, `OrderItem`, `ProductModerationLog`, `AuditLog`) tự động chặn thao tác `update()` và `delete()` bằng `LogicException`.

---

## Chương 4. Kết Quả Kiểm Thử Kiến Trúc (`Architectural Audit Log`)

Thực thi tự động bằng lệnh `php artisan model:verify-architecture` trên PostgreSQL 18 vào ngày `2026-11-14`:

### 4.1. Tổng Hợp 4 Hạng Mục Kiểm Tra
1. **Check 1 (Model & Schema Mapping):** Khởi tạo thành công 32/32 Models, khớp 100% bảng PostgreSQL 18 và mọi cột trong `$fillable` đều tồn tại thật trong Database Schema.
2. **Check 2 (Relationships & Foreign Keys):** Xác minh 116 phương thức quan hệ trên 32 Models. Toàn bộ đều trả về instance của `Relation`, khóa ngoại tồn tại thật trên bảng quan hệ tương ứng (`ALL PASS`).
3. **Check 3 (Auth & Convenience Helpers):**
   - `User::getAuthPasswordName()` $\rightarrow$ `'password_hash'` (**PASS**).
   - `User::isAdmin()`, `isModerator()`, `isSupport()`, `isInternalStaff()`, `isActive()` (**PASS**).
   - `PlatformSetting::getValue('protection_fee_rate')` $\rightarrow$ `0.06` (**PASS**).
   - `PlatformSetting::getValue('auction_payment_window_production_sec')` $\rightarrow$ `1800` (**PASS**).
   - `Conversation::normalizeParticipants(42, 10)` $\rightarrow$ `[10, 42]` (**PASS**).
4. **Check 4 (Immutability Guards):**
   - `AuditLog->update()` $\rightarrow$ `LogicException` (**BLOCKED [PASS]**).
   - `AuditLog->delete()` $\rightarrow$ `LogicException` (**BLOCKED [PASS]**).
   - `EscrowTransaction->update()` $\rightarrow$ `LogicException` (**BLOCKED [PASS]**).
   - `EscrowTransaction->delete()` $\rightarrow$ `LogicException` (**BLOCKED [PASS]**).
   - `ProductModerationLog->update()` $\rightarrow$ `LogicException` (**BLOCKED [PASS]**).
