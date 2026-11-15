# P6-04: PRODUCT LISTINGS (7 STATES), SEARCH & MODERATION SERVICES SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P604-PRODUCT-MODERATION`
- **Version:** `1.0.0`
- **Status:** DONE / APPROVED
- **Phase:** `Phase 06 – Task P6-04`
- **Dependencies:** `P6-03 (Profile & Catalog Taxonomy)`
- **Completed Date:** `2026-11-14`
- **Verification:** `8/8 tests PASS (92 assertions, zero drift)`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
- **Mục tiêu:** Hiện thực hóa toàn bộ vòng đời sản phẩm đồ secondhand (`7 trạng thái`: `DRAFT`, `PENDING_REVIEW`, `APPROVED`, `REJECTED`, `SOLD`, `HIDDEN`, `ARCHIVED`), bộ máy tìm kiếm & lọc đa tiêu chí trên PostgreSQL 18 (`M-DS-02`), Kênh Người bán (`M-SL-01..04`) và dịch vụ Kiểm duyệt sản phẩm (`ProductModerationService` – `DEC-05`).
- **Phạm vi:** `ProductDiscoveryService`, `SellerProductService`, `ProductModerationService` và các API `/api/v1/products/*`, `/api/v1/seller/dashboard`, `/api/v1/seller/products/*`.

## 2. Source Documents (`Tài Liệu Nguồn`)
- `06_BUSINESS_RULES.md` (`BR-PR-01..05`, `DEC-05`, `NFR-PER-02`, `NFR-SEC-05`), `PRODUCT_LISTING_MODERATION_FLOW.md`, `API_ENDPOINTS_LIST.md` (Mục 1.2 & 1.5).
- Models: `Product`, `ProductImage`, `ProductModerationLog`, `Auction`, `AuctionSession`, `Order`.

## 3. Technical Design & Domain Services (`Thiết Kế Kỹ Thuật & Dịch Vụ Nghiệp Vụ`)
1. **`App\Services\Product\ProductDiscoveryService`:**
   - `searchPublicProducts(array $filters, ?User $viewer)`: Chỉ truy vấn `status = 'APPROVED'`. Hỗ trợ tìm kiếm từ khóa tiếng Việt Unicode NFC (`title ILIKE`, `description ILIKE`, `product_code ILIKE`), lọc theo `category_id` (bao gồm cả danh mục con), `brand_id`, `listing_type` (`FIXED_PRICE` / `AUCTION`), `condition` (`LIKE_NEW`, `GOOD`, `FAIR`, `VINTAGE_WORN`), khoảng giá `min_price <= price <= max_price`, và sắp xếp (`newest`, `price_asc`, `price_desc`, `popular` theo `favorite_count DESC`).
   - `getProductDetail(int $productId, ?User $viewer): array`: Nếu sản phẩm ở trạng thái `APPROVED` hoặc `SOLD` thì cho phép xem công khai; nếu ở trạng thái `DRAFT`, `PENDING_REVIEW`, `REJECTED`, `HIDDEN` thì chỉ chủ sở hữu (`seller_id === $viewer?->id`) hoặc nhân sự nội bộ (`isInternalStaff()`) mới được xem, còn lại ném `ResourceNotAvailableException` (`404`). Trả kèm cờ `is_owner = ($viewer?->id === $product->seller_id)` (`BR-AC-02`) và 4 sản phẩm liên quan.
2. **`App\Services\Product\SellerProductService`:**
   - `getSellerDashboardMetrics(User $seller): array`: Trả về `wallet_balance`, `escrow_held_balance` và bộ đếm việc cần xử lý trên `M-SL-01` (đơn `PAID` chờ đóng gói, đơn `PREPARING` có `cancellation_requested = true`, sản phẩm bị `REJECTED`, đơn đang `DISPUTE`).
   - `createListing(User $seller, array $data, array $images): Product`:
     - Bắt buộc có `condition` và `defect_info` không rỗng (`BR-PR-03`).
     - Nếu `listing_type === 'AUCTION'`, ép `total_quantity = 1` và `available_quantity = 1` (`BR-PR-01`).
     - Nếu `submit_for_review == true`, đặt `status = 'PENDING_REVIEW'` và ghi bản ghi `SUBMITTED` vào `product_moderation_logs`; ngược lại lưu `status = 'DRAFT'`.
   - `updateOrResubmitListing(User $seller, Product $product, array $data, ?array $images): Product`:
     - **Khóa chỉnh sửa (`BR-PR-05`):** Nếu sản phẩm đang có đơn hàng active hoặc phiên đấu giá đang `LIVE` đã có lượt trả giá (`bid_count > 0`), chặn sửa bằng `InvalidStateTransitionException` (`409`).
     - **Luồng Gửi duyệt lại (`Resubmit` – `DEC-05`, `M-SL-04`):** Nếu sản phẩm đang ở `REJECTED` (hoặc `APPROVED` nhưng sửa thông tin trọng yếu) và `submit_for_review == true`, chuyển `status` sang `'PENDING_REVIEW'`, xóa `rejection_reason` cũ và ghi log `SUBMITTED` vào `product_moderation_logs`.
3. **`App\Services\Governance\ProductModerationService` (Dùng cho Kiểm duyệt & Tái sử dụng ở Phase 08):**
   - `approveProduct(User $moderator, Product $product, string $verificationLevel): Product`: Kiểm tra quyền `isModerator() || isAdmin()`. Chuyển `status = 'APPROVED'`, gán `verification_level`, `approved_at = now()`, `approved_by = $moderator->id`. Nếu `listing_type === 'AUCTION'` và đã chọn khung giờ phiên, tự động kích hoạt/mở khóa phiên đấu giá tương ứng. Ghi `product_moderation_logs` và `audit_logs`, gửi thông báo `PRODUCT_APPROVED` cho Seller.
   - `rejectOrHideProduct(User $moderator, Product $product, string $action, string $reason): Product`: **Bắt buộc `trim($reason) !== ''` (`DEC-05`, `BR-PR-04`)**. Chuyển `status` sang `'REJECTED'` (hoặc `'HIDDEN'`), lưu `rejection_reason = $reason`, ghi `product_moderation_logs` + `audit_logs`, gửi thông báo kèm lý do cho Seller.

## 4. Files Created or Modified (`File Mã Nguồn Đã Thực Hiện`)
- `backend/app/Services/Product/ProductDiscoveryService.php` (Search, Filter, Detail, Eager loading, Access guard)
- `backend/app/Services/Product/SellerProductService.php` (Dashboard metrics, List, Create, Update, Resubmit, Status change, Image upload)
- `backend/app/Services/Governance/ProductModerationService.php` (Approve, Reject, Hide, Reason check, Notifications, Audit logs)
- `backend/app/Http/Controllers/Api/V1/ProductController.php` (Public product endpoints)
- `backend/app/Http/Controllers/Api/V1/SellerProductController.php` (Seller product endpoints)
- `backend/app/Http/Requests/Api/V1/Product/ProductSearchRequest.php` (Validation rules & Vietnamese messages)
- `backend/app/Http/Requests/Api/V1/Product/StoreProductRequest.php` (Validation rules & Vietnamese messages)
- `backend/app/Http/Requests/Api/V1/Product/UpdateProductRequest.php` (Validation rules & Vietnamese messages)
- `backend/app/Http/Resources/Api/V1/ProductImageResource.php` (Image formatting)
- `backend/app/Http/Resources/Api/V1/ProductDetailResource.php` (Detail formatting with owner/staff isolation)
- `backend/routes/api.php` (Registered 7 endpoints)
- `backend/tests/Feature/Api/V1/ProductAndModerationTest.php` (8 test methods, 92 assertions)

## 5. API Endpoints (`Danh Sách Endpoints`)
- `GET /api/v1/products` (Search & Multi-criteria Filter)
- `GET /api/v1/products/{id}` (Product Detail & Authenticity/Defect View)
- `GET /api/v1/seller/dashboard` (Seller Dashboard Metrics & Action counters)
- `GET /api/v1/seller/products` (Seller Product List with status filter)
- `POST /api/v1/seller/products` (Create Listing)
- `PUT /api/v1/seller/products/{id}` (Update / Resubmit Listing)
- `POST /api/v1/seller/products/{id}` (Multipart update / resubmit via POST)
- `PATCH /api/v1/seller/products/{id}/status` (Change status: HIDDEN, ARCHIVED)

## 6. Business Rules, Validation & Authorization
- **Validation:** `min_price <= max_price` (`422` nếu `min_price > max_price`); `defect_info` bắt buộc không rỗng; `condition` thuộc các giá trị hợp lệ; ảnh tải lên `1..8` ảnh, mỗi ảnh `<= 5120 KB` (`jpg,jpeg,png,webp`).
- **Business Rules:** `BR-PR-01..05`, `DEC-05`.

## 7. Test Cases & Acceptance Criteria (`Tiêu Chí Nghiệm Thu`)
- [x] 1. `test_public_product_search_filters_by_keyword_category_condition_price_and_sorts_accurately` (PASS)
- [x] 2. `test_product_search_rejects_invalid_price_range_when_min_exceeds_max_with_422` (PASS)
- [x] 3. `test_product_detail_hides_unapproved_products_from_public_but_allows_seller_owner_with_rejection_reason` (PASS)
- [x] 4. `test_seller_creates_fixed_price_and_auction_listings_enforcing_defect_info_and_single_auction_qty` (PASS)
- [x] 5. `test_moderator_approves_and_rejects_product_enforcing_mandatory_reason_dec05_and_notifies_seller` (PASS)
- [x] 6. `test_regular_user_or_support_cannot_moderate_products_returns_403` (PASS)
- [x] 7. `test_seller_resubmits_rejected_product_clears_rejection_reason_and_transitions_to_pending_review` (PASS)
- [x] 8. `test_seller_cannot_update_product_locked_by_active_order_or_live_auction_with_bids_returns_409` (PASS)
- **Acceptance Criteria:** 100% bài test trong `ProductAndModerationTest.php` đạt `PASS` (8/8 tests, 92 assertions).

## 8. Risks & Mitigation
- **Rủi ro:** Cập nhật sản phẩm có đính kèm file ảnh bằng phương thức `PUT` multipart/form-data trong PHP thường không parse được `$_FILES`.
- **Giảm thiểu:** Hỗ trợ cả `PUT /api/v1/seller/products/{id}` và `POST /api/v1/seller/products/{id}` (Method Spoofing `_method=PUT` hoặc direct POST) cho Multipart Form-Data trên Flutter (`Dio`).
