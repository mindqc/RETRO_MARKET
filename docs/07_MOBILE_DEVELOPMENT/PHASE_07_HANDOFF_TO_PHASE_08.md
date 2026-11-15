# RETRO MARKET (izithrift) – PHASE 07 TO PHASE 08 TECHNICAL HANDOFF DOCUMENT

- **Document ID:** `DOC-P7-TO-P8-HANDOFF`
- **Source Phase:** `Phase 07 – Flutter Mobile Application Development`
- **Target Phase:** `Phase 08 – Laravel Blade Admin Dashboard & Moderation Tools`
- **Auditor & Author:** Technical Lead & Repository Auditor
- **Date:** `2026-11-15`
- **Status:** `HANDOFF READY / NO CRITICAL BLOCKERS`

---

## 1. Executive Summary & Objective

Tài liệu này xác lập biên bản chuyển giao kỹ thuật từ **Phase 07 (Flutter Mobile App)** sang **Phase 08 (Laravel Blade Admin Dashboard)** của dự án Retro Market (`izithrift`).

Mục tiêu cốt lõi của Phase 08 là xây dựng module quản trị vận hành (**Admin Web Blade Dashboard**) phục vụ Ban quản trị sàn, Kiểm duyệt viên (`moderator`) và Chuyên viên hỗ trợ tranh chấp (`support`), **chia sẻ chung mã nguồn backend core tại `backend/`** mà không tạo duplicate repository hay duplicate logic.

---

## 2. Current Repository State for Admin Infrastructure

Qua khảo sát trực tiếp cấu trúc repository hiện tại:
1. **Thư mục `admin/`:**
   - Đang là thư mục placeholder ở cấp root theo phân bổ cấu trúc tổng quan ban đầu.
   - **Quy tắc Hiến pháp dự án (`GEMINI.md` Mục 1):** *"Admin Dashboard module (Laravel Blade sharing the single `backend/` core; do NOT create a separate duplicate backend)."* Do đó, toàn bộ Blade views, Blade controllers và Web routes của Phase 08 sẽ được triển khai trực tiếp bên trong `backend/resources/views/admin/`, `backend/app/Http/Controllers/Admin/`, và `backend/routes/web.php`.
2. **Hệ thống Views hiện tại (`backend/resources/views/`):**
   - Chỉ có file mặc định `welcome.blade.php`.
   - Chưa có Blade templates, layouts (`layouts/admin.blade.php`), hay components nào cho Admin.
3. **Định tuyến Web (`backend/routes/web.php`):**
   - Hiện chỉ có route mặc định:
     ```php
     Route::get('/', function () {
         return view('welcome');
     });
     ```
   - Chưa đăng ký route group `/admin/*`.

---

## 3. Reusable Backend Assets & Services from Phase 06

Một điểm thuận lợi rất lớn là toàn bộ **Domain Services nghiệp vụ quản trị, kiểm duyệt và phân xử** đã được xây dựng, kiểm thử 100% PASS từ Phase 06 và sẵn sàng tái sử dụng ngay trong các Blade Controllers của Phase 08:

### A. Nhóm Quản Trị & Kiểm Duyệt (`backend/app/Services/Governance/`)
- **`ProductModerationService.php`:**
  - `listPendingProducts(int $perPage = 20)`: Lấy danh sách sản phẩm chờ duyệt (`PENDING_REVIEW`).
  - `approveProduct(int $productId, int $moderatorId)`: Phê duyệt sản phẩm chuyển sang `APPROVED` và lên sàn.
  - `rejectProduct(int $productId, int $moderatorId, string $reason)`: Từ chối bài đăng kèm lý do (`DEC-05`), chuyển trạng thái `REJECTED`.
  - `bulkModerate(array $productIds, string $action, int $moderatorId, ?string $reason = null)`: Phê duyệt / Từ chối hàng loạt.
- **`UserGovernanceService.php`:**
  - `listUsers(array $filters = [], int $perPage = 20)`: Quản lý danh sách tài khoản người dùng.
  - `suspendUser(int $userId, int $adminId, string $reason)`: Khóa tài khoản vi phạm (HTTP 403 `ACCOUNT_SUSPENDED`), vô hiệu hóa token đăng nhập.
  - `unsuspendUser(int $userId, int $adminId)`: Mở khóa tài khoản.
- **`ViolationReportService.php`:**
  - `listReports(array $filters = [], int $perPage = 20)`: Tiếp nhận và xử lý báo cáo vi phạm nội dung / người dùng (`M-CM-03`).
  - `resolveReport(int $reportId, int $moderatorId, string $resolutionNotes, ?string $action = null)`.
- **`AuditLogService.php`:**
  - `logAction(int $userId, string $action, string $targetType, int $targetId, ?array $metadata = null)`: Ghi nhận vết kiểm toán hệ thống.
- **`PlatformConfigService.php`:**
  - Quản lý cấu hình sàn (tỷ lệ phí bảo vệ người mua 6%, phí cố định 7.000đ, thời gian tự động hoàn tất 24h/72h).
- **`SystemDevToolsService.php`:**
  - Idempotent triggers cho chế độ `DEMO_MODE=true` (`A-DT-01`): Quét phiên đấu giá hết hạn, quét đơn hàng quá hạn thanh toán, quét giải ngân Escrow tự động.

### B. Nhóm Tranh Chấp & Ký Quỹ Escrow (`backend/app/Services/Escrow/`)
- **`DisputeService.php`:**
  - `listDisputes(array $filters = [], int $perPage = 15)`: Danh sách các vụ tranh chấp mở (`DISPUTE_OPEN`).
  - `getDisputeDetail(int $disputeId)`: Chi tiết dòng thời gian bằng chứng 2 chiều.
  - `resolveDispute(int $disputeId, int $adminId, string $resolution, ?float $refundAmount = null, string $resolutionNote = '')`: Phân xử hoàn tiền 100% cho người mua hoặc giải ngân cho người bán, giải phóng trạng thái đóng băng `escrow_frozen_at`.
- **`EscrowReleaseService.php`:**
  - Xử lý giải ngân và đối soát tài chính ký quỹ.

### C. Nhóm Mô Hình & Phân Quyền (`backend/app/`)
- **`App\Enums\UserRole`:**
  - `REGISTERED_USER = 'registered_user'` (Người dùng Mobile / Buyer & Seller).
  - `MODERATOR = 'moderator'` (Kiểm duyệt viên bài đăng & báo cáo).
  - `SUPPORT = 'support'` (Chuyên viên hỗ trợ đơn hàng & giải quyết tranh chấp).
  - `ADMIN = 'admin'` (Toàn quyền quản trị hệ thống).
- **Policies:**
  - `ProductPolicy`, `OrderPolicy`, `DisputePolicy`, `AuctionPolicy`.

---

## 4. Architectural Analysis: Authentication & Session Strategy for Phase 08

### Vấn Đề Kỹ Thuật Trọng Yếu:
- **Phase 07 Mobile:** Sử dụng **Laravel Sanctum Bearer Token** (`auth:sanctum`), không dùng cookie/session, bảo mật qua header HTTP Authorization.
- **Phase 08 Admin Web Blade:** Là ứng dụng web truyền thống (Server-Side Rendered bằng Blade), bắt buộc phải sử dụng **Laravel Session-based Authentication** (`web` guard) với cookie bảo vệ CSRF (`@csrf`).

### Khuyến Nghị Kiến Trúc Cho Phase 08:
1. **Không can thiệp vào cấu hình Sanctum của API:** Giữ nguyên vẹn toàn bộ route `/api/v1/*` cho Mobile App hoạt động ổn định.
2. **Cấu hình Web Guard cho Admin:**
   - Trong `backend/config/auth.php`, đảm bảo guard `web` trỏ đến `App\Models\User`.
   - Tạo Middleware `AdminRoleMiddleware` (`EnsureUserIsStaffOrAdmin`) kiểm tra:
     ```php
     in_array($user->role, [UserRole::MODERATOR, UserRole::SUPPORT, UserRole::ADMIN])
     ```
   - Đăng ký nhóm route trong `backend/routes/web.php`:
     ```php
     Route::prefix('admin')->name('admin.')->group(function () {
         // Guest Admin Login
         Route::get('login', [AdminAuthController::class, 'showLoginForm'])->name('login');
         Route::post('login', [AdminAuthController::class, 'login'])->name('login.submit');
         Route::post('logout', [AdminAuthController::class, 'logout'])->name('logout');

         // Authenticated Staff Routes
         Route::middleware(['auth:web', 'admin.staff'])->group(function () {
             Route::get('dashboard', [AdminDashboardController::class, 'index'])->name('dashboard');
             Route::resource('moderation', AdminProductModerationController::class);
             Route::resource('disputes', AdminDisputeController::class);
             Route::resource('users', AdminUserController::class);
             Route::resource('devtools', AdminDevToolsController::class);
         });
     });
     ```

---

## 5. Potential Risks & Anti-Patterns to Avoid in Phase 08

1. **Nguy cơ trùng lặp Business Logic (Duplicated Business Logic):**
   - *Nguy cơ:* Viết lại logic kiểm duyệt bài đăng, hoàn tiền Escrow hoặc khóa tài khoản trực tiếp trong Controller thay vì gọi Domain Service.
   - *Biện pháp ngăn chặn:* Tất cả Blade Controllers **chỉ đóng vai trò HTTP Presentation Layer**, bắt buộc inject và gọi các Service sẵn có (`ProductModerationService`, `DisputeService`, `UserGovernanceService`).
2. **Vi phạm Sổ cái Bất biến (Append-Only Ledger Violation):**
   - *Nguy cơ:* Tạo chức năng Admin cho phép sửa hoặc xóa bản ghi giao dịch trong `wallet_transactions` hoặc `escrow_transactions`.
   - *Biện pháp ngăn chặn:* Tuân thủ triệt để Hiến pháp dự án: Không bao giờ tạo câu lệnh `UPDATE` hoặc `DELETE` trên 2 bảng ledger tài chính. Phân xử chỉ ghi thêm bản ghi điều chỉnh (Credit/Debit mới).
3. **Ảnh hưởng đến Mobile App khi chỉnh sửa Shared Models:**
   - *Nguy cơ:* Thay đổi accessor/mutator hoặc quan hệ trong Eloquent Models làm vỡ JSON serialization của API `/api/v1/*`.
   - *Biện pháp ngăn chặn:* Mọi thay đổi trên Models trong Phase 08 phải được bảo đảm bằng việc chạy lại `php artisan test` (88 tests) và `flutter test` (134 tests).

---

## 6. Pre-requisites & Checklist Before Starting Phase 08

- [x] Phase 07 Mobile Application 100% hoàn tất và vượt qua mọi bài kiểm thử.
- [x] Backend Phase 06 Domain Services đầy đủ và hoạt động hoàn hảo.
- [x] Quyết định PO về 5 mức phân hạng tình trạng sản phẩm đã được đồng bộ toàn diện.
- [x] Tài khoản Admin mặc định đã được khởi tạo trong Seeder (`AdminUserSeeder`: `admin@izithrift.vn`, `mod@izithrift.vn`, `support@izithrift.vn`).
- [ ] Product Owner phát lệnh khởi động chính thức Phase 08.

**Kết Luận:** Phase 08 hoàn toàn không bị chặn bởi bất kỳ vấn đề kỹ thuật nào. Hệ thống sẵn sàng 100% để tiến hành cài đặt giao diện Blade Admin ngay khi có yêu cầu từ PO.
