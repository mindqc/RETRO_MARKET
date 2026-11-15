# P7-03: DIO API CLIENT, SANCTUM TOKEN STORAGE, SERVER CLOCK SYNC & ERROR INTERCEPTORS SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P703-API-CLIENT-STATE-CORE`
- **Version:** `1.0.0`
- **Status:** `DONE (100% PASS)`
- **Phase:** `Phase 07 – Task P7-03`
- **Dependencies:** `P7-01, P7-02 Completed`

---

## 1. Objective (`Mục Tiêu`)
Xây dựng tầng giao tiếp mạng (`networking layer`) mạnh mẽ dựa trên thư viện `Dio`, đảm bảo kết nối mượt mà và an toàn với 74 RESTful API Endpoints (`/api/v1/*`) của Laravel Backend. Tích hợp lưu trữ bảo mật Sanctum Bearer Token (`flutter_secure_storage`), cơ chế đồng bộ thời gian máy chủ tự động qua mọi phản hồi (`ServerClockSyncInterceptor` theo `BR-AU-01`), bộ phân tích lỗi chuẩn hóa (`ApiEnvelopeErrorInterceptor`), và bộ điều khiển HTTP Polling có nhận biết vòng đời ứng dụng (`LifecyclePollingController` theo `ADR-08`, `NFR-PER-03`).

---

## 2. Technical Specifications & Architecture (`Đặc Tả Kỹ Thuật & Kiến Trúc`)

### 2.1. Dio Client Configuration
- **Connect Timeout:** 10.000 ms (10 giây).
- **Receive Timeout:** 15.000 ms (15 giây).
- **Default Headers:**
  - `Accept`: `application/json`
  - `Content-Type`: `application/json`
  - `X-App-Platform`: `flutter_mobile`
  - `X-App-Version`: `1.0.0`

### 2.2. Dedicated Interceptor Chain (`Chuỗi 4 Interceptor Chuyên Biệt`)
1. **`AuthBearerInterceptor` (Hiệu chỉnh bắt buộc #2 – Tương thích `optional.sanctum` / `DEC-01`):**
   - Đọc Sanctum Bearer Token từ `SecureTokenStorage`.
   - Nếu tồn tại, **tự động đính kèm `Authorization: Bearer <token>` vào request header cho cả các endpoint dùng `optional.sanctum`** (`/api/v1/bootstrap`, `/api/v1/home`, `/api/v1/products`, `/api/v1/auctions`, `/api/v1/catalog/...`) để Backend nhận diện được `current_user`, `is_favorited`, `is_owner`, `is_watching`.
   - **Chỉ bỏ qua** việc đính kèm token trên 4 endpoint xác thực thuần túy: `/auth/login`, `/auth/register`, `/auth/forgot-password`, `/auth/reset-password`.
2. **`ServerClockSyncInterceptor` (Hiệu chỉnh bắt buộc #3 – `BR-AU-01`):**
   - Lắng nghe và đồng bộ trường `"server_time"` (ISO-8601) trong **cả phản hồi thành công `onResponse` (HTTP 2xx) VÀ phản hồi lỗi `onError` (HTTP 4xx/5xx)**.
   - Đặc biệt quan trọng khi xảy ra lỗi `409 AUCTION_OUTBID_CONFLICT`: Backend trả về `server_time` mới sau khi Anti-Sniping gia hạn phiên đấu, interceptor lập tức cập nhật `ServerTimeService`.
   - Tính toán độ lệch thời gian: `offset = serverTime.difference(DateTime.now())`.
   - Lưu trữ vào singleton `ServerTimeService` để hàm `ServerTimeService.now()` luôn trả về thời gian chuẩn xác của máy chủ (bỏ qua đồng hồ bị chỉnh sai trên điện thoại).
3. **`ApiEnvelopeErrorInterceptor`:**
   - Chặn bắt mọi lỗi HTTP `4xx` và `5xx`.
   - Bóc tách JSON payload `{"success": false, "error_code": "...", "message": "...", "errors": {...}, "latest_state": {...}}`.
   - Chuyển đổi thành typed `ApiException`:
     - `401 UNAUTHENTICATED`: Kích hoạt hàm đăng xuất, xóa token và phát tín hiệu `AuthSessionAlert` điều hướng về Login.
     - `403 ACCOUNT_SUSPENDED`: Xóa token, phát tín hiệu `AuthSessionAlert` hiển thị thông báo tài khoản bị tạm khóa.
     - `403 SELF_TRANSACTION_FORBIDDEN`: Thông báo không thể tự mua/bán đồ của chính mình (`BR-AC-02`).
     - `409 AUCTION_OUTBID_CONFLICT`: Trích xuất `latest_state` để cập nhật trực tiếp lên UI đặt giá thầu.
     - `409 PRODUCT_OUT_OF_STOCK` / `409 INVALID_STATE_TRANSITION`: Cảnh báo trạng thái bất hợp lệ.
     - `422 VALIDATION_ERROR`: Trích xuất map lỗi `fieldErrors: Map<String, List<String>>` kèm helper `firstErrorFor(field)`.
     - `429 TOO_MANY_REQUESTS`: Cảnh báo thao tác quá nhanh, thử lại sau.
4. **`LoggingInterceptor`:** Ghi log định dạng curl/response chi tiết trong môi trường Debug (`kDebugMode`).

### 2.3. Secure Token Storage (`Lưu Trữ Token An Toàn`)
- Sử dụng `flutter_secure_storage` với cấu hình mã hóa phần cứng:
  - Android: `encryptedSharedPreferences: true` (Keystore).
  - iOS: `KeychainAccessibility.first_unlock`.
- Hỗ trợ chế độ `SecureTokenStorage.inMemory()` để chạy Unit/Widget Tests nhanh và độc lập.
- Lưu trữ: `access_token`, `auth_user_id`, `auth_user_role`, `auth_user_email`.
- Phát thông báo `sessionAlerts` khi session bị vô hiệu hóa (`401` hoặc `403 ACCOUNT_SUSPENDED`).

### 2.4. Lifecycle-Aware Polling Controller (`ADR-08, NFR-PER-03`)
- Xây dựng `LifecyclePollingController` kế thừa `WidgetsBindingObserver`:
  - **Hiệu chỉnh bắt buộc #1:** Có cờ khóa `_isPollingInProgress` để chống gọi chồng lấn khi request trước chưa giải phóng; không bắn request mới khi polling nhịp trước đang chạy.
  - Quản lý timer định kỳ (3–5 giây) cho Phòng Đấu Giá (`M-AC-03`) và Phòng Chat 1-1 (`M-CM-02`).
  - Tự động tạm dừng (`pause()`) khi ứng dụng chuyển sang `AppLifecycleState.paused`, `inactive`, hoặc `hidden`.
  - Tự động khôi phục (`resume()`) khi ứng dụng quay lại `AppLifecycleState.resumed`.
  - Hủy bỏ hoàn toàn (`dispose()`) giải phóng sạch timer và observer khi Widget bị unmount.

### 2.5. Base State Core (MVVM Architecture)
- Lớp trạng thái cơ sở `AsyncValue<T>` hoặc `ViewState` (`initial`, `loading`, `success`, `error`, `empty`).
- Lớp trừu tượng `BaseRepository` và `BaseViewModel` (`ChangeNotifier`).

---

## 3. Files to Create in `P7-03`
- `mobile/lib/core/network/dio_client.dart`
- `mobile/lib/core/network/interceptors/auth_bearer_interceptor.dart`
- `mobile/lib/core/network/interceptors/server_clock_sync_interceptor.dart`
- `mobile/lib/core/network/interceptors/api_envelope_error_interceptor.dart`
- `mobile/lib/core/network/interceptors/logging_interceptor.dart`
- `mobile/lib/core/services/secure_token_storage.dart`
- `mobile/lib/core/services/server_time_service.dart`
- `mobile/lib/core/services/lifecycle_polling_controller.dart`
- `mobile/lib/core/error/api_exception.dart`
- `mobile/lib/core/error/error_code_enum.dart`
- `mobile/lib/core/state/view_state.dart`
- `mobile/lib/core/state/base_view_model.dart`
- `mobile/test/core/api_client_and_state_test.dart`

---

## 4. Acceptance Criteria (`Tiêu Chí Nghiệm Thu P7-03`)
- [x] **AC-P703-01:** `DioClient` tự động đính kèm `Bearer token` khi token có trong `SecureTokenStorage` (kể cả trên `/bootstrap`, `/home`, `/products`, `/auctions` theo `optional.sanctum` / `DEC-01`).
- [x] **AC-P703-02:** `ServerClockSyncInterceptor` bóc tách chính xác `server_time` trên cả response 200 lẫn error 409 và cập nhật `ServerTimeService.now()`.
- [x] **AC-P703-03:** Các mã lỗi `401`, `403`, `409`, `422` được parse chính xác thành `ApiException` với đầy đủ `fieldErrors` và `latestState`.
- [x] **AC-P703-04:** `LifecyclePollingController` chống gọi chồng lấn, tạm dừng timer khi app vào background và hủy sạch timer khi dispose.
- [x] **AC-P703-05:** `flutter test test/core/api_client_and_state_test.dart` đạt **100% PASS** (14/14 tests pass).
