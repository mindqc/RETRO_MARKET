# P6-01: BACKEND ARCHITECTURE & API FOUNDATION SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P601-API-FOUNDATION`
- **Version:** `1.0.0`
- **Status:** DONE / APPROVED
- **Phase:** `Phase 06 – Task P6-01`
- **Dependencies:** `Phase 05 Completed (P5-01..P5-07)`

---

## 1. Objective (`Mục Tiêu`)
Thiết lập bộ khung kiến trúc cốt lõi cho toàn bộ REST API `/api/v1/*` và tầng Domain Services của Laravel 13, bao gồm:
1. Cơ chế bắt và chuẩn hóa toàn bộ ngoại lệ (`Global API Exception Rendering`) về đúng định dạng JSON Envelope có `error_code` và `server_time`.
2. Hệ thống lớp ngoại lệ nghiệp vụ (`DomainExceptions`) hỗ trợ trả kèm trạng thái mới nhất (`latest_state`) khi xảy ra xung đột `409 Conflict`.
3. Bộ 4 Middlewares bảo mật & ngữ cảnh (`OptionalSanctumAuth`, `EnsureUserIsActive`, `EnsureInternalRole`, `EnsureDemoModeEnabled`).
4. Cấu hình 3 bộ giới hạn tần suất gọi API (`RateLimiter`: `auth`, `transactional`, `polling`).
5. Hai dịch vụ nền tảng dùng chung toàn hệ thống: `PlatformConfigService` (đọc/cache cấu hình từ bảng `platform_settings`) và `AuditLogService` (ghi nhật ký kiểm toán bất biến vào bảng `audit_logs`).
6. Endpoint khởi động ứng dụng `GET /api/v1/bootstrap` (`M-AU-01`) và `GET /api/v1/health`.

---

## 2. Source Documents (`Tài Liệu Nguồn`)
- `docs/04_SYSTEM_ARCHITECTURE_AND_DB/03_API_SPECIFICATIONS/REST_API_GUIDELINES.md` (JSON Envelope, HTTP Statuses, Error Codes, Rate Limits).
- `docs/04_SYSTEM_ARCHITECTURE_AND_DB/03_API_SPECIFICATIONS/API_ENDPOINTS_LIST.md` (`GET /api/v1/bootstrap`).
- `docs/01_REQUIREMENTS_ANALYSIS/06_BUSINESS_RULES.md` (`BR-AC-04`, `BR-AU-01`, `BR-AD-02`, `DEC-01`, `DEC-04`, `ADR-05`, `NFR-SEC-04`).
- `docs/05_BACKEND_FOUNDATION/P5_01_ENVIRONMENT_SETUP.md` & `P5_04_ELOQUENT_MODELS.md`.

---

## 3. Detailed Tasks (`Công Việc Chi Tiết`)
1. **Kiểm tra & nâng cấp `App\Support\ApiResponse`:** Đảm bảo hỗ trợ đầy đủ `success()`, `created()`, `paginated()`, `error()` với trường `server_time`, `error_code`, `errors` và `latest_state` (tùy chọn khi lỗi `409`).
2. **Xây dựng Hệ thống Domain Exceptions (`app/Exceptions/`):**
   - `DomainException`: Lớp cơ sở chứa `$errorCode`, `$httpStatus`, `$errors`, `$latestState`.
   - Các lớp con chuyên biệt:
     - `AccountSuspendedException` (`403`, `ACCOUNT_SUSPENDED`)
     - `SelfTransactionForbiddenException` (`403`, `SELF_TRANSACTION_FORBIDDEN`)
     - `RolePermissionDeniedException` (`403`, `ROLE_PERMISSION_DENIED`)
     - `ResourceNotAvailableException` (`404`, `RESOURCE_NOT_AVAILABLE`)
     - `AuctionOutbidConflictException` (`409`, `AUCTION_OUTBID_CONFLICT`, kèm `latest_state`)
     - `ProductOutOfStockException` (`409`, `PRODUCT_OUT_OF_STOCK`)
     - `InvalidStateTransitionException` (`409`, `INVALID_STATE_TRANSITION`)
3. **Cấu hình Global Exception Rendering trong `bootstrap/app.php`:**
   - Bắt mọi request khớp `api/*` hoặc `expectsJson()` để chuyển đổi:
     - `DomainException` $\rightarrow$ JSON Envelope chuẩn với `$e->getErrorCode()`, `$e->getHttpStatus()`, `$e->getLatestState()`.
     - `ValidationException` $\rightarrow$ `422 VALIDATION_ERROR`.
     - `AuthenticationException` $\rightarrow$ `401 UNAUTHENTICATED`.
     - `AccessDeniedHttpException` / `AuthorizationException` $\rightarrow$ `403 ROLE_PERMISSION_DENIED`.
     - `ModelNotFoundException` / `NotFoundHttpException` $\rightarrow$ `404 RESOURCE_NOT_AVAILABLE`.
     - `ThrottleRequestsException` $\rightarrow$ `429 TOO_MANY_REQUESTS`.
4. **Xây dựng 4 Middlewares trong `app/Http/Middleware/`:**
   - `OptionalSanctumAuth`: Nếu request vào endpoint công khai có gửi kèm `Bearer Token` hợp lệ thì tự động đăng nhập `Auth::setUser($user)` từ guard `sanctum` (phục vụ `DEC-01` để hiển thị `is_favorited`, `is_owner`, `is_watching`).
   - `EnsureUserIsActive`: Kiểm tra nếu user đã xác thực có `status !== 'ACTIVE'` (`SUSPENDED` hoặc `BANNED`) thì xóa token hiện tại và ném `AccountSuspendedException` (`BR-AC-04`).
   - `EnsureInternalRole`: Kiểm tra vai trò của user thuộc danh sách roles cho phép (ví dụ `role:admin,moderator`). Nếu không khớp, ném `RolePermissionDeniedException`.
   - `EnsureDemoModeEnabled`: Chỉ cho phép đi tiếp nếu `config('retromarket.demo_mode') === true` (`NFR-ENV-02`).
5. **Đăng ký Rate Limiters trong `AppServiceProvider`:**
   - `RateLimiter::for('auth', ...)` $\rightarrow$ `5 requests / minute / IP`.
   - `RateLimiter::for('transactional', ...)` $\rightarrow$ `30 requests / minute / user_id|IP`.
   - `RateLimiter::for('polling', ...)` $\rightarrow$ `60 requests / minute / user_id|IP`.
6. **Xây dựng 2 Domain Services nền tảng:**
   - `App\Services\Governance\PlatformConfigService`: Đọc cấu hình từ `platform_settings` (có cache Redis và tự động ép kiểu theo `value_type`: `DECIMAL`, `INTEGER`, `BOOLEAN`, `STRING`), cung cấp các hàm tiện ích lấy tỷ lệ phí bảo vệ người mua (`protectionFeeRate()`, `protectionFixedFee()`, `calculateBuyerProtectionFee(float $itemSubtotal)`), thời hạn thanh toán đơn đấu giá (`auctionWinnerPaymentDeadlineMinutes()`) và thời gian tự động hoàn tất đơn (`orderAutoCompleteDurationSeconds()`).
   - `App\Services\Governance\AuditLogService`: Ghi bản ghi bất biến vào bảng `audit_logs` (`record(?User $actor, string $action, string $targetType, ?int $targetId, ?string $reason, ?array $oldValues, ?array $newValues, ?string $ipAddress)`).
7. **Xây dựng `BootstrapController` & Định tuyến `/api/v1/bootstrap`:**
   - Trả về `server_time`, `demo_mode`, cấu hình phí bảo vệ công khai (`protection_fee_rate`, `protection_fixed_fee`, `shipping_fee_default`), cấu hình thời gian đếm ngược hiện hành và thông tin tóm tắt của `current_user` (nếu request có gửi kèm Sanctum token hợp lệ).

---

## 4. Files to Create or Modify (`Danh Sách File Tạo Mới / Chỉnh Sửa`)
- **Modify:** `backend/app/Support/ApiResponse.php`
- **Create:**
  - `backend/app/Exceptions/DomainException.php`
  - `backend/app/Exceptions/AccountSuspendedException.php`
  - `backend/app/Exceptions/SelfTransactionForbiddenException.php`
  - `backend/app/Exceptions/RolePermissionDeniedException.php`
  - `backend/app/Exceptions/ResourceNotAvailableException.php`
  - `backend/app/Exceptions/AuctionOutbidConflictException.php`
  - `backend/app/Exceptions/ProductOutOfStockException.php`
  - `backend/app/Exceptions/InvalidStateTransitionException.php`
  - `backend/app/Http/Middleware/OptionalSanctumAuth.php`
  - `backend/app/Http/Middleware/EnsureUserIsActive.php`
  - `backend/app/Http/Middleware/EnsureInternalRole.php`
  - `backend/app/Http/Middleware/EnsureDemoModeEnabled.php`
  - `backend/app/Services/Governance/PlatformConfigService.php`
  - `backend/app/Services/Governance/AuditLogService.php`
  - `backend/app/Http/Controllers/Api/V1/BootstrapController.php`
  - `backend/tests/Feature/Api/V1/ApiFoundationTest.php`
- **Modify:**
  - `backend/bootstrap/app.php`
  - `backend/app/Providers/AppServiceProvider.php`
  - `backend/routes/api.php`

---

## 5. API Endpoints (`Endpoints Triển Khai Trong P6-01`)
| Method | Endpoint | Middleware | Màn Hình | Mô Tả |
| :---: | :--- | :--- | :---: | :--- |
| `GET` | `/api/v1/health` | Public | System | Trả về trạng thái kết nối cơ bản và `server_time`. |
| `GET` | `/api/v1/bootstrap` | `optional.sanctum`, `active.user` | `M-AU-01` (Splash) | Trả về `server_time`, `demo_mode`, tham số `platform_settings` công khai và `current_user` (nếu đã đăng nhập). |

---

## 6. Domain Services (`Dịch Vụ Nghiệp Vụ`)
1. `PlatformConfigService`:
   - `get(string $key, mixed $default = null): mixed`
   - `calculateBuyerProtectionFee(float|string $itemSubtotal): array` $\rightarrow$ Trả về `['item_subtotal', 'shipping_fee' => '0.00', 'protection_fee_rate', 'protection_fixed_fee', 'buyer_protection_fee', 'total_amount', 'seller_net_amount']` tính bằng `bcmath` / `round()` chuẩn xác theo `DEC-04`.
   - `getPublicBootstrapConfig(): array`
2. `AuditLogService`:
   - `record(...)`: Ghi nhận hành động quản trị/hệ thống vào `audit_logs`.

---

## 7. Business Rules (`Quy Tắc Nghiệp Vụ Áp Dụng`)
- **`BR-AU-01`:** Mọi JSON response đều có `server_time` chuẩn ISO-8601 theo múi giờ máy chủ.
- **`BR-AC-04`:** Tài khoản có `status` là `'SUSPENDED'` hoặc `'BANNED'` bị chặn ngay tại middleware `EnsureUserIsActive` với mã `403 ACCOUNT_SUSPENDED` và bị thu hồi token đang gọi.
- **`DEC-04`:** Công thức tính phí bảo vệ người mua (`ROUND(item_subtotal * rate) + fixed_fee`, `shipping_fee = 0`, `seller_net_amount = item_subtotal`) được tập trung duy nhất tại `PlatformConfigService::calculateBuyerProtectionFee()`.
- **`BR-AD-02`:** Mọi bản ghi `audit_logs` được tạo qua `AuditLogService` là bất biến.

---

## 8. Validation Rules (`Quy Tắc Kiểm Tra Dữ Liệu`)
- Mọi lỗi `ValidationException` trên `/api/v1/*` luôn trả về HTTP `422` kèm `"error_code": "VALIDATION_ERROR"`, `"message"` tiếng Việt rõ ràng và mảng `"errors"` chi tiết theo từng trường.

---

## 9. Authorization Rules (`Quy Tắc Phân Quyền`)
- Middleware alias `optional.sanctum`: Cho phép Guest truy cập bình thường (`current_user: null`), nhưng nếu có Bearer Token hợp lệ thì nhận diện được User.
- Middleware alias `active.user`: Chặn tức thì nếu User đã xác thực không ở trạng thái `ACTIVE`.
- Middleware alias `role`: Kiểm tra `users.role` khớp danh sách vai trò được phép (`admin`, `moderator`, `support`, `registered_user`).

---

## 10. Database Transactions & 11. Idempotency Requirements
- `PlatformConfigService` đọc từ bảng `platform_settings` với cơ chế cache an toàn (`Cache::remember`) và hàm `clearCache()` khi cập nhật cấu hình.
- Endpoint `GET /api/v1/bootstrap` là truy vấn chỉ đọc (`Idempotent Read-Only`).

---

## 12. Test Cases (`Danh Sách Bài Kiểm Thử Tự Động Trong ApiFoundationTest.php`)
1. `test_bootstrap_endpoint_returns_standard_envelope_for_guest`: Gọi `GET /api/v1/bootstrap` không có token $\rightarrow$ Trả về `200 OK`, có `server_time`, `protection_fee_rate = 0.06`, `protection_fixed_fee = 7000`, `current_user = null`.
2. `test_bootstrap_endpoint_resolves_authenticated_active_user`: Gọi `GET /api/v1/bootstrap` kèm Sanctum token của `buyer.linh@izithrift.local` $\rightarrow$ Trả về `200 OK` kèm thông tin `current_user` (không lộ `password_hash`).
3. `test_suspended_user_is_blocked_with_403_account_suspended_and_token_revoked`: Tạo token cho `suspended.user@izithrift.local` rồi gọi API có middleware `active.user` $\rightarrow$ Trả về `403`, `error_code = ACCOUNT_SUSPENDED` và token bị xóa khỏi `personal_access_tokens`.
4. `test_unknown_api_route_returns_standardized_404_json_envelope`: Gọi `GET /api/v1/non-existent-endpoint` $\rightarrow$ Trả về `404`, `error_code = RESOURCE_NOT_AVAILABLE`, có `server_time`.
5. `test_domain_exceptions_render_exact_error_codes_and_latest_state`: Kiểm tra `AuctionOutbidConflictException` trả về `409`, `error_code = AUCTION_OUTBID_CONFLICT` và đầy đủ object `latest_state`.
6. `test_platform_config_service_calculates_buyer_protection_fee_accurately`: Kiểm tra với `item_subtotal = 400000` $\rightarrow$ `buyer_protection_fee = 31000`, `shipping_fee = 0`, `total_amount = 431000`, `seller_net_amount = 400000` (`DEC-04`).
7. `test_audit_log_service_records_immutable_entry`: Gọi `AuditLogService::record(...)` $\rightarrow$ Tạo bản ghi trong `audit_logs` và xác nhận không thể sửa/xóa.
8. `test_role_middleware_blocks_unauthorized_roles_with_403`: Kiểm tra `EnsureInternalRole` chặn `registered_user` hoặc `support` khi truy cập route chỉ dành cho `admin`.

---

## 13. Acceptance Criteria (`Tiêu Chí Nghiệm Thu P6-01`)
- [x] Tất cả 8/8 bài kiểm thử trong `tests/Feature/Api/V1/ApiFoundationTest.php` đạt `PASS`.
- [x] Toàn bộ 12/12 bài kiểm thử nền tảng của Phase 05 (`DatabaseFoundationVerificationTest`) tiếp tục đạt `PASS` (Zero Regression).
- [x] `GET /api/v1/bootstrap` phản hồi đúng JSON Envelope đã quy định trong `REST_API_GUIDELINES.md`.

---

## 14. Risks & Mitigation (`Rủi Ro & Giảm Thiểu`)
- **Rủi ro:** Laravel 11/13 mặc định chỉ trả JSON cho exception khi request có header `Accept: application/json`.
- **Giảm thiểu:** Trong `bootstrap/app.php`, cấu hình `$exceptions->shouldRenderJsonWhen(fn (Request $request, Throwable $e) => $request->is('api/*') || $request->expectsJson());` để mọi request gọi vào `/api/*` luôn nhận về JSON Envelope chuẩn xác 100%.

---

## 15. Completion Status
- **Status:** DONE / APPROVED
- **Completed At:** `2026-11-14 15:38:00 +07:00`
- **Verification Summary:**
  - Automated Tests: 8/8 tests in `ApiFoundationTest` passed (60 assertions).
  - Full Regression Suite: 22/22 total tests passed (184 assertions).
  - Envelope Compliance: Verified 100% with `success`, `message`, `server_time`, `error_code`, `latest_state`.
