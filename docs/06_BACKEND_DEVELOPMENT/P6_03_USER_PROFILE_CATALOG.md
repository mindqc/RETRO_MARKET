# P6-03: USER PROFILE, ADDRESS BOOK, CATALOG TAXONOMY & HOME DISCOVERY SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P603-PROFILE-CATALOG`
- **Version:** `1.0.0`
- **Status:** DONE / APPROVED
- **Phase:** `Phase 06 – Task P6-03`
- **Dependencies:** `P6-01 (API Foundation)`, `P6-02 (Auth & RBAC)`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
- **Mục tiêu:** Xây dựng các dịch vụ quản lý Hồ sơ cá nhân & Tiệm đồ si (`M-PF-01`, `M-PF-02`, `M-PF-06`), Sổ địa chỉ nhận hàng (`M-PF-03`, `M-PF-04`), Cây danh mục & Thương hiệu (`M-DS-01`), Trang chủ khám phá (`M-HM-01`) và Hồ sơ công khai của Tiệm bán (`M-US-03`).
- **Phạm vi:** `ProfileService`, `AddressBookService`, `CatalogTaxonomyService`, `HomeDiscoveryService`, `SellerStorefrontService` và các API tương ứng.

## 2. Source Documents (`Tài Liệu Nguồn`)
- `API_ENDPOINTS_LIST.md` (Mục 1.1 & 1.2), `MOBILE_SCREENS_SPEC.md` (`M-HM-01`, `M-DS-01`, `M-PF-01..06`, `M-US-03`), `DB_01_CORE_SCHEMA.md`.
- Models: `User`, `UserProfile`, `SellerProfile`, `UserAddress`, `Category`, `Brand`, `Product`, `Auction`, `Review`, `SellerFollow`.

## 3. Technical Design & Domain Services (`Thiết Kế Kỹ Thuật & Dịch Vụ Nghiệp Vụ`)
1. **`App\Services\User\ProfileService`:**
   - `getMyProfileSummary(User $user): array`: Trả về thông tin `User`, `UserProfile`, `SellerProfile` kèm bộ đếm đơn mua (`buyerOrders`) theo từng trạng thái (`PENDING_PAYMENT`, `PAID`, `PREPARING`, `SHIPPED`, `DELIVERED`, `COMPLETED`, `DISPUTED`) phục vụ huy hiệu trên `M-PF-01` (`NAV-DEC-02`).
   - `updateProfile(User $user, array $data, ?UploadedFile $avatar): User`: Cập nhật `display_name`, `phone`, `bio`, kiểm tra và lưu ảnh `avatar` (`<= 5MB`, `jpg/png/webp` – `NFR-SEC-05`).
   - `updateSettings(User $user, bool $seasonalDecorEnabled): UserProfile`: Bật/tắt hiệu ứng trang trí Giáng sinh (`NFR-UX-02`).
   - `changePassword(User $user, string $currentPassword, string $newPassword): void`.
2. **`App\Services\User\AddressBookService`:**
   - CRUD bảng `user_addresses` của `auth()->id()`.
   - Trong `DB::transaction()`: Khi thêm địa chỉ đầu tiên hoặc khi đặt `is_default = true`, tự động cập nhật `user_addresses` khác của user đó về `is_default = false`.
3. **`App\Services\Catalog\CatalogTaxonomyService`:**
   - `getActiveTaxonomy(): array`: Trả về cây danh mục `categories` (`is_active = true`, kèm `children` và số lượng sản phẩm `APPROVED`) và danh sách `brands` (`is_active = true`).
4. **`App\Services\Catalog\HomeDiscoveryService`:**
   - `getHomeFeed(?User $viewer): array`: Trả về dữ liệu tổng hợp cho `M-HM-01` gồm: danh mục nổi bật, danh sách phiên đấu giá đang `LIVE` (sắp xếp theo `auction_ends_at ASC`), các tiệm uy tín (`trust_score DESC`), và sản phẩm `APPROVED` mới lên kệ (kèm cờ `is_favorited` nếu `$viewer` khác null).
5. **`App\Services\Catalog\SellerStorefrontService`:**
   - `getPublicStorefront(int $sellerId, ?User $viewer, string $tab): array`: Trả về thông tin công khai của Tiệm, `trust_score`, `average_rating`, `review_count`, `completed_orders_count`, `followers_count`, cờ `is_following` và danh sách sản phẩm của tiệm (`approved`, `auction`, `sold`).
   - `getSellerReviews(int $sellerId, ?int $rating, int $perPage)`: Phân trang đánh giá `VISIBLE` từ các đơn `COMPLETED` (`BR-RV-01`).

## 4. Files to Create or Modify (`File Mã Nguồn Dự Kiến`)
- `backend/app/Services/User/ProfileService.php`
- `backend/app/Services/User/AddressBookService.php`
- `backend/app/Services/Catalog/CatalogTaxonomyService.php`
- `backend/app/Services/Catalog/HomeDiscoveryService.php`
- `backend/app/Services/Catalog/SellerStorefrontService.php`
- `backend/app/Http/Controllers/Api/V1/ProfileController.php`
- `backend/app/Http/Controllers/Api/V1/AddressController.php`
- `backend/app/Http/Controllers/Api/V1/CatalogController.php`
- `backend/app/Http/Controllers/Api/V1/SellerStorefrontController.php`
- `backend/app/Http/Requests/Api/V1/Profile/*` & `backend/app/Http/Resources/Api/V1/*`
- `backend/tests/Feature/Api/V1/UserProfileAndCatalogTest.php`

## 5. API Endpoints (`Danh Sách Endpoints`)
- `GET /api/v1/profile`, `POST /api/v1/profile`, `PUT /api/v1/profile/settings`, `PUT /api/v1/profile/password`
- `GET /api/v1/profile/addresses`, `POST /api/v1/profile/addresses`, `PUT /api/v1/profile/addresses/{id}`, `DELETE /api/v1/profile/addresses/{id}`
- `GET /api/v1/home`, `GET /api/v1/catalog/taxonomy`
- `GET /api/v1/sellers/{id}`, `GET /api/v1/sellers/{id}/reviews`

## 6. Business Rules, Validation & Authorization
- **Authorization:** Người dùng chỉ được xem/sửa/xóa `UserAddress` thuộc `user_id` của chính mình (`403` hoặc `404` nếu truy cập địa chỉ người khác).
- **Business Rules:** `BR-PR-02` (Trang chủ & Storefront công khai chỉ hiển thị sản phẩm `APPROVED` / `SOLD`), `NFR-SEC-05` (Avatar `<= 5MB`), `NFR-UX-02` (`seasonal_decor_enabled`).

## 7. Test Cases & Acceptance Criteria (`Tiêu Chí Nghiệm Thu`)
1. `test_get_profile_returns_unified_account_and_order_counters`
2. `test_update_profile_and_seasonal_decor_toggle_succeeds`
3. `test_address_book_crud_maintains_single_default_address_invariant`
4. `test_user_cannot_modify_or_delete_another_users_address`
5. `test_home_and_taxonomy_endpoints_return_only_approved_products_and_live_auctions`
6. `test_public_seller_storefront_and_verified_reviews_pagination`
- **Acceptance Criteria:** 100% bài test trong `UserProfileAndCatalogTest.php` đạt `PASS`.

## 8. Risks & Mitigation
- **Rủi ro:** Lỗi `N+1 Query` khi tải Trang chủ (`M-HM-01`) hoặc Storefront (`M-US-03`).
- **Giảm thiểu:** Sử dụng `with(['primaryImage', 'seller.sellerProfile', 'category', 'brand'])` trên toàn bộ truy vấn danh sách sản phẩm.

## 9. Completion Status & Verification Results
- **Status:** DONE / APPROVED
- **Completed At:** `2026-11-14 16:00:20 +07:00`
- **Automated Verification:** 8/8 tests in `UserProfileAndCatalogTest.php` PASSED (224 assertions).
- **Full Test Suite:** 38/38 tests PASSED (491 assertions, Zero Regressions).
- **Seeded Data Integrity:** 100% verified via `php artisan db:verify-seeders` (Zero Drift).
