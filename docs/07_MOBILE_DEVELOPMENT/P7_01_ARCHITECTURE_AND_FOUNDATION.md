# P7-01: FLUTTER ARCHITECTURE, PROJECT FOUNDATION, ROUTING SHELL & CORE UTILITIES SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P701-ARCHITECTURE-FOUNDATION`
- **Version:** `1.0.0`
- **Status:** `DONE`
- **Phase:** `Phase 07 – Task P7-01`
- **Dependencies:** `Phase 06 REST API (/api/v1/*) Completed`

---

## 1. Objective (`Mục Tiêu`)
Khởi tạo dự án Flutter chuẩn mực tại thư mục `mobile/`, thiết lập cấu trúc thư mục phân lớp (`core/` và `features/`), cấu hình môi trường kết nối linh hoạt tới Backend Laravel (`/api/v1`), xây dựng các tiện ích xử lý số liệu/tiền tệ/thời gian an toàn (`SafeJsonParser`, `VndFormatter`), và dựng bộ khung điều hướng **5-Tab Bottom Navigation Shell (`GoRouter`)** theo đúng `01_SITEMAP_AND_NAVIGATION.md` (`NAV-DEC-01`, `NAV-DEC-02`).

---

## 2. Scope Boundary (`Phạm Vi Của P7-01`)
- **Thuộc `P7-01`:**
  1. Khởi tạo Flutter project tại `mobile/` với các packages cốt lõi (`flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `intl`, `shared_preferences`, `image_picker`, `cached_network_image`, `shimmer`).
  2. Xây dựng `EnvConfig` tự động nhận diện URL Backend phù hợp (`http://10.0.2.2:8000/api/v1` cho Android Emulator, `http://127.0.0.1:8000/api/v1` cho Windows/iOS/Web, hoặc override qua `--dart-define=API_BASE_URL=...`).
  3. Xây dựng `SafeJsonParser` (parse an toàn `decimal:2` dạng chuỗi/số từ PostgreSQL 18), `VndCurrencyFormatter` (`400.000đ`, `850k`, `1,2tr`), và `DateTimeFormatter`.
  4. Xây dựng `AppRouter` (`GoRouter`) với `StatefulShellRoute.indexedStack` cho **5 Tab chính**:
     - Tab 1: **Trang chủ (`Home` – `/home`)**
     - Tab 2: **Khám phá (`Discover` – `/discover`)**
     - Tab 3: **Đấu giá (`Auctions` – `/auctions`)**
     - Tab 4: **Tin nhắn (`Messages` – `/messages`)**
     - Tab 5: **Cá nhân & Kênh Người bán (`Profile` – `/profile`)**
  5. Viết bộ Unit & Widget Test (`test/core/foundation_test.dart`) kiểm chứng `SafeJsonParser`, `VndCurrencyFormatter` và chuyển đổi 5 Tab trên `MainNavigationShell`.
- **Chưa thuộc `P7-01`:**
  - Chi tiết Design Tokens & Shared UI Components (`P7-02`).
  - Dio Interceptors, đồng bộ `server_time` & quản lý phiên token (`P7-03`).
  - Giao diện chi tiết của 52 màn hình nghiệp vụ (`P7-04` $\rightarrow$ `P7-11`).

---

## 3. Files Created in `P7-01`
- `mobile/pubspec.yaml` (Cấu hình dependencies Flutter 3.50.0 / Dart 3.14.0)
- `mobile/lib/main.dart` (Khởi chạy ứng dụng bọc ProviderScope)
- `mobile/lib/app.dart` (IzithriftApp kết nối MaterialApp.router)
- `mobile/lib/core/config/env_config.dart` (Nhận diện API URL thông minh)
- `mobile/lib/core/constants/api_endpoints.dart` (Đầy đủ 74 REST API endpoints)
- `mobile/lib/core/utils/safe_json_parser.dart` (toDouble, toInt, toBool, toDateTime)
- `mobile/lib/core/utils/vnd_formatter.dart` (Định dạng VNĐ tiêu chuẩn & rút gọn)
- `mobile/lib/core/router/app_routes.dart` (Định nghĩa hằng số URL các màn hình)
- `mobile/lib/core/router/app_router.dart` (StatefulShellRoute cho 5 Tab)
- `mobile/lib/core/widgets/main_navigation_shell.dart` (NavigationBar 5 Tab chuẩn NAV-DEC-01)
- `mobile/test/core/foundation_test.dart` (Bộ kiểm thử tự động 5/5 tests PASS)

---

## 4. Acceptance Criteria Checklist (`Tiêu Chí Nghiệm Thu P7-01`)
- [x] **AC-P701-01:** `flutter pub get` và `flutter analyze` chạy thành công với `0 errors, 0 warnings` (No issues found).
- [x] **AC-P701-02:** `SafeJsonParser` chuyển đổi chính xác cả `"431000.00"` (String từ PG18 `NUMERIC(15,2)`), `431000` (int), `431000.0` (double) và `null` mà không bao giờ ném ngoại lệ.
- [x] **AC-P701-03:** `MainNavigationShell` hiển thị đúng 5 Tab (`Trang chủ`, `Khám phá`, `Đấu giá`, `Tin nhắn`, `Cá nhân`) và giữ nguyên trạng thái từng nhánh (`StatefulShellRoute`).
- [x] **AC-P701-04:** `flutter test test/core/foundation_test.dart` đạt **100% PASS** (5/5 tests passed).

---

## 5. Execution & Verification Report (`Biên Bản Thực Thi P7-01`)
- **Flutter SDK:** Flutter `3.50.0` (channel stable), Dart `3.14.0`.
- **Static Analysis:**
  ```text
  $ flutter analyze
  Analyzing mobile...
  No issues found! (ran in 4.9s)
  ```
- **Automated Tests:**
  ```text
  $ flutter test
  00:00 +0: P7-01: Foundation Core Utils & Config Tests EnvConfig and ApiEndpoints definitions
  00:00 +1: P7-01: Foundation Core Utils & Config Tests SafeJsonParser.toDouble converts various Laravel serialized formats
  00:00 +2: P7-01: Foundation Core Utils & Config Tests SafeJsonParser.toInt, toBool and toDateTime parse safely
  00:00 +3: P7-01: Foundation Core Utils & Config Tests VndFormatter formats currency accurately according to Vietnamese conventions
  00:00 +4: P7-01: 5-Tab Navigation Shell & App Smoke Test Renders all 5 Navigation Tabs and switches branches smoothly
  00:00 +5: All tests passed!
  ```
