# P6-02: AUTHENTICATION, SANCTUM TOKENS & RBAC AUTHORIZATION SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P602-AUTH-RBAC`
- **Version:** `1.0.0`
- **Status:** DONE / APPROVED
- **Phase:** `Phase 06 – Task P6-02`
- **Dependencies:** `P6-01 (API Foundation, DomainExceptions, Middlewares, RateLimiters)`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
- **Mục tiêu:** Hiện thực hóa toàn bộ luồng xác thực người dùng (`Register`, `Login`, `Logout`, `Forgot Password`, `Reset Password`) qua Laravel Sanctum và thiết lập hệ thống phân quyền (`Policies` & `Gates`) bảo vệ 61 quyền trong `03_ACTOR_PERMISSION_MATRIX.md`.
- **Phạm vi:** Các API `/api/v1/auth/*`, `AuthService`, `UserGovernanceService` (khóa/mở khóa tài khoản thu hồi token theo `BR-AC-04`), và 6 Eloquent Policies cốt lõi (`ProductPolicy`, `AuctionPolicy`, `OrderPolicy`, `DisputePolicy`, `ConversationPolicy`, `ReviewPolicy`).

## 2. Source Documents (`Tài Liệu Nguồn`)
- `03_ACTOR_PERMISSION_MATRIX.md`, `06_BUSINESS_RULES.md` (`BR-AC-01..04`, `NFR-SEC-01..04`), `API_ENDPOINTS_LIST.md` (`M-AU-01..05`).
- Database & Models: `users` (`User`), `user_profiles` (`UserProfile`), `seller_profiles` (`SellerProfile`), `carts` (`Cart`), `personal_access_tokens`, `password_reset_tokens`.

## 3. Technical Design & Domain Services (`Thiết Kế Kỹ Thuật & Dịch Vụ Nghiệp Vụ`)
1. **`App\Services\Auth\AuthService`:**
   - `register(array $payload): array`: Thực thi trong `DB::transaction()` tạo nguyên tử 4 bản ghi: `User` (`role = 'registered_user'`, `status = 'ACTIVE'`, `password_hash = Hash::make(...)`), `UserProfile` (`seasonal_decor_enabled = true`), `SellerProfile` (`shop_slug` sinh duy nhất từ `display_name`, `trust_score = 100.00`, `wallet_balance = 0.00`), và `Cart` (`BR-AC-01`). Cấp phát Sanctum `plainTextToken`.
   - `login(string $email, string $password, string $deviceName): array`: Tìm user theo `LOWER(email)`, kiểm tra `Hash::check($password, $user->password_hash)`. Nếu sai trả `401 UNAUTHENTICATED`. Nếu `user->status !== 'ACTIVE'` ném `AccountSuspendedException` (`403 ACCOUNT_SUSPENDED` kèm `status_reason` – `BR-AC-04`). Cập nhật `last_login_at = now()` và cấp token.
   - `logout(User $user): void`: Xóa `$user->currentAccessToken()->delete()`.
   - `sendResetLink(string $email): void` & `resetPassword(array $payload): void`: Sinh token lưu vào `password_reset_tokens` (hết hạn sau 60 phút), gửi email qua Mailpit (`ASM-04`), đặt lại `password_hash` và thu hồi toàn bộ token cũ.
2. **`App\Services\Governance\UserGovernanceService` (Phục vụ `BR-AC-04` & tái sử dụng ở Phase 08):**
   - `updateAccountStatus(User $admin, User $targetUser, UserStatus $newStatus, string $reason, ?Carbon $suspendedUntil = null): User`: Khi chuyển sang `SUSPENDED` hoặc `BANNED`, xóa toàn bộ `personal_access_tokens` của `$targetUser` và ghi `AuditLogService::record(...)`.
3. **Hệ thống Eloquent Policies (`app/Policies/`):**
   - Thực thi quy tắc chống tự giao dịch (`BR-AC-02`: `$user->id !== $product->seller_id`) và phân tách quyền nội bộ (`PERM-CM-08` vs `PERM-CM-09`: `support` chỉ được yêu cầu bằng chứng, chỉ `admin` được gọi `resolve` khiếu nại tài chính).

## 4. Files to Create or Modify (`File Mã Nguồn Dự Kiến`)
- `backend/app/Services/Auth/AuthService.php`
- `backend/app/Services/Governance/UserGovernanceService.php`
- `backend/app/Http/Controllers/Api/V1/AuthController.php`
- `backend/app/Http/Requests/Api/V1/Auth/RegisterRequest.php`
- `backend/app/Http/Requests/Api/V1/Auth/LoginRequest.php`
- `backend/app/Http/Requests/Api/V1/Auth/ForgotPasswordRequest.php`
- `backend/app/Http/Requests/Api/V1/Auth/ResetPasswordRequest.php`
- `backend/app/Http/Resources/Api/V1/AuthUserResource.php`
- `backend/app/Policies/ProductPolicy.php`, `AuctionPolicy.php`, `OrderPolicy.php`, `DisputePolicy.php`, `ConversationPolicy.php`, `ReviewPolicy.php`
- `backend/tests/Feature/Api/V1/AuthAndRbacTest.php`

## 5. API Endpoints (`Danh Sách Endpoints`)
- `POST /api/v1/auth/register` (`throttle:auth`)
- `POST /api/v1/auth/login` (`throttle:auth`)
- `POST /api/v1/auth/logout` (`auth:sanctum`, `active.user`)
- `POST /api/v1/auth/forgot-password` (`throttle:auth`)
- `POST /api/v1/auth/reset-password` (`throttle:auth`)

## 6. Business Rules, Validation & Authorization
- **Validation:** `email` chuẩn RFC, lưu chữ thường; `password` tối thiểu 8 ký tự, có `confirmed`; `phone` 10–11 chữ số.
- **Business Rules:** `BR-AC-01` (Tài khoản hợp nhất), `BR-AC-02` (Chặn tự giao dịch), `BR-AC-04` (Chặn đăng nhập & thu hồi token khi bị khóa).

## 7. Test Cases & Acceptance Criteria (`Tiêu Chí Nghiệm Thu`)
1. `test_register_creates_user_dual_profiles_and_cart_atomically`: Đăng ký tài khoản mới tạo đủ 4 bảng (`users`, `user_profiles`, `seller_profiles`, `carts`) và trả về Sanctum token.
2. `test_login_succeeds_for_active_user_and_updates_last_login_at`: Đăng nhập bằng `buyer.linh@izithrift.local` (`Retro@2026`) thành công.
3. `test_login_blocks_suspended_user_with_403_account_suspended`: Đăng nhập bằng `suspended.user@izithrift.local` trả về `403 ACCOUNT_SUSPENDED`.
4. `test_logout_revokes_current_access_token`: Sau khi gọi `logout`, token cũ không còn dùng được (`401`).
5. `test_forgot_and_reset_password_flow_updates_password_hash_and_revokes_tokens`: Khôi phục mật khẩu hoạt động chính xác với bảng `password_reset_tokens`.
6. `test_user_governance_service_suspends_user_and_revokes_all_tokens`: Khóa tài khoản lập tức xóa sạch token và ghi `audit_logs`.
7. `test_policies_enforce_anti_self_transaction_and_admin_only_dispute_verdict`: Kiểm tra `OrderPolicy`, `AuctionPolicy`, `DisputePolicy`.
- **Acceptance Criteria:** 100% bài test trong `AuthAndRbacTest.php` đạt `PASS`.

## 8. Risks & Mitigation
- **Rủi ro:** Lộ trường `password_hash` trong JSON response.
- **Giảm thiểu:** `User::$hidden = ['password_hash']` kết hợp `AuthUserResource` chỉ whitelist các trường an toàn.

## 9. Completion Status & Verification Results
- **Status:** DONE / APPROVED
- **Completed At:** `2026-11-14 15:50:30 +07:00`
- **Automated Verification:** 8/8 tests in `AuthAndRbacTest.php` PASSED (83 assertions).
- **Full Test Suite:** 30/30 tests PASSED (267 assertions, Zero Regressions).
- **Seeded Data Integrity:** 100% verified via `php artisan db:verify-seeders` (Zero Drift).
