# 08B. LOW-FIDELITY ADMIN DASHBOARD WIREFRAME SPECIFICATIONS – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P208B-ADMIN-WIREFRAMES`
- **Version:** `2.1.0 (COMPLETE UNTRUNCATED SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR FINAL LOCK`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 02 – System Flow & UX Planning`

---

## Chương 1. Khung Bố Cục Tổng Thể Trang Quản Trị Web (`Laravel Blade Admin Layout Shell`)

Giao diện **Admin Dashboard** (`/admin/*`) thiết kế cho màn hình Desktop (`1440 x 900 px`), sử dụng bố cục **Fixed Left Sidebar (`260px`) + Top Header (`64px`) + Main Content Area (12-Column Responsive Grid)**:

```text
+---------------------------------------------------------------------------------------------------+
| 🎄 izithrift ADMIN  |  Breadcrumb: Admin > Moderation > Queue       | [DEMO_MODE: ON] | 👤 Admin  |
+---------------------+-----------------------------------------------------------------------------+
| [LEFT SIDEBAR MENU] | [MAIN WORKSPACE AREA - 12 COLUMNS]                                          |
| (Lọc theo Role RBAC)|                                                                             |
|                     |                                                                             |
| 📊 1. Dashboard     |                                                                             |
|                     |                                                                             |
| 🛡️ 2. Kiểm duyệt    |                                                                             |
|  • Hàng chờ duyệt   |                                                                             |
|  • Quản lý Sản phẩm |                                                                             |
|  • Danh mục & Hãng  |                                                                             |
|  • Báo cáo & Review |                                                                             |
|                     |                                                                             |
| 🔨 3. Đấu giá       |                                                                             |
|  • Khung giờ Phiên  |                                                                             |
|  • Giám sát Đấu giá |                                                                             |
|                     |                                                                             |
| 💳 4. Giao dịch     |                                                                             |
|  • Quản lý Đơn hàng |                                                                             |
|  • Phiên Thanh toán |                                                                             |
|  • Sổ cái Escrow    |                                                                             |
|  • Xử lý Khiếu nại  |                                                                             |
|                     |                                                                             |
| ⚙️ 5. Hệ thống      |                                                                             |
|  • Người dùng & Role|                                                                             |
|  • Cấu hình Phí/Giờ |                                                                             |
|  • Nhật ký Kiểm toán|                                                                             |
|                     |                                                                             |
| 🧪 6. Developer Tool|                                                                             |
|  • Demo Job Triggers|                                                                             |
+---------------------+-----------------------------------------------------------------------------+
```

---

## Chương 2. Đặc Tả Wireframe Chi Tiết Các Màn Hình Quản Trị Trọng Tâm

### 2.1. `A-DB-01`: Main KPI & Live Metrics Dashboard (`/admin/dashboard`)

```text
+---------------------------------------------------------------------------------------------------+
| 📊 BẢNG ĐIỀU KHIỂN TỔNG QUAN (LIVE POSTGRESQL METRICS - FR-AD-01)                                 |
+---------------------------------------------------------------------------------------------------+
| +-----------------------+ +-----------------------+ +-----------------------+ +-----------------+ |
| | 👥 TỔNG NGƯỜI DÙNG    | | 🛡️ CHỜ KIỂM DUYỆT     | | 🔨 ĐẤU GIÁ ĐANG LIVE  | | ⚖️ KHIẾU NẠI MỞ | |
| |       142 Users       | |    18 Sản phẩm        | |      06 Phiên         | |    03 Hồ sơ     | |
| | (139 Active | 3 Khóa) | | [Vào duyệt ngay ->]   | | [Giám sát phiên ->]   | | [Xử lý ngay ->] | |
| +-----------------------+ +-----------------------+ +-----------------------+ +-----------------+ |
|                                                                                                   |
| 💰 ĐỐI SOÁT DÒNG TIỀN MÔ PHỎNG & SỔ CÁI ESCROW (Chỉ hiển thị cho Administrator - ACT-05)          |
| +-------------------------------+ +-------------------------------+ +---------------------------+ |
| | 🔒 ĐANG GIỮ TRONG ESCROW      | | ✅ ĐÃ GIẢI NGÂN CHO SELLER    | | 🛡️ DOANH THU PHÍ BẢO VỆ   | |
| |    (escrow_status = HELD)     | |   (100% item_subtotal)        | |  (Buyer Protection Fee)   | |
| |       12.850.000 VNĐ          | |       48.200.000 VNĐ          | |       3.412.000 VNĐ       | |
| +-------------------------------+ +-------------------------------+ +---------------------------+ |
|                                                                                                   |
| 📋 CẢNH BÁO HOẠT ĐỘNG & NHẬT KÝ KIỂM TOÁN GẦN ĐÂY (Recent Audit Logs)                             |
| • Moderator #02 đã DUYỆT sản phẩm #PRD-204 (Áo Khoác Da Bò Vintage)                       |
| • Admin #01 đã PHÂN XỬ KHIẾU NẠI #DSP-042 -> APPROVE_BUYER_REFUND (Hoàn 100%: 643.000đ)   |
+---------------------------------------------------------------------------------------------------+
```

---

### 2.2. `A-MD-02`: Product Moderation Inspection & Decision Screen (`/admin/moderation/products/{id}` – `DEC-05`)

```text
+---------------------------------------------------------------------------------------------------+
| [<- Về Hàng chờ]    KIỂM DUYỆT SẢN PHẨM #PRD-209 (Trạng thái: PENDING_REVIEW)                     |
+---------------------------------------------------------------------------------------------------+
| +-----------------------------------------------+ +---------------------------------------------+ |
| | 📸 HÌNH ẢNH SẢN PHẨM & BẰNG CHỨNG XÁC THỰC    | | 📋 THÔNG TIN KHAI BÁO TỪ NGƯỜI BÁN          | |
| | +-------------------+ +-------------------+   | | • Tên bài đăng: Túi Da Coach Vintage 1995   | |
| | | [Ảnh chính 1]     | | [Ảnh góc cạnh 2]  |   | | • Người bán: Tiệm Đồ Si Nhà Gấu (Trust: 98) | |
| | +-------------------+ +-------------------+   | | • Loại bán: ĐẤU GIÁ (Phiên Tối 20:00-22:00) | |
| | +-------------------+ +-------------------+   | | • Giá khởi điểm: 600.000đ | Bước giá: 50.000đ| |
| | | [Ảnh vết xước 3]  | | [Ảnh Tag/Code 4]  |   | | • Tình trạng (Condition): Good              | |
| | +-------------------+ +-------------------+   | | • Khai báo lỗi (defect_info - BR-PR-03):    | |
| |                                               | |   "Khóa đồng hơi ngả màu patina tự nhiên,   | |
| | 📜 LỊCH SỬ KIỂM DUYỆT (product_moderation_logs)| |    viền đáy túi có 1 vết xước 1cm (Ảnh 3)." | |
| | • Lần 1 (12/11): REJECTED bởi Mod #02         | +---------------------------------------------+ |
| |   Lý do: "Thiếu ảnh chụp mã code dập trong"   | | 🛡️ QUYẾT ĐỊNH KIỂM DUYỆT (DEC-05 & BR-PR-04)| |
| | • Lần 2 (13/11): Seller đã bổ sung Ảnh số 4   | | Mức độ xác minh (verification_level):       | |
| |   và gửi duyệt lại (Resubmit).                | | [ MODERATOR_REVIEWED (Đã kiểm tra ảnh)   v ]| |
| |                                               | |                                             | |
| |                                               | | Lý do từ chối / Yêu cầu chỉnh sửa           | |
| |                                               | | (Bắt buộc nhập nếu bấm Từ chối):            | |
| |                                               | | [                                          ]| |
| |                                               | |                                             | |
| |                                               | | [ ✅ PHÊ DUYỆT (APPROVE) ] [ ❌ TỪ CHỐI ]   | |
| +-----------------------------------------------+ +---------------------------------------------+ |
+---------------------------------------------------------------------------------------------------+
```

---

### 2.3. `A-DP-02`: Dispute Case Resolution Room (`/admin/disputes/{id}` – Phân Tách Quyền `Support Staff` vs `Admin` Theo `PERM-CM-08`, `PERM-CM-09`, `DEC-07`)

```text
+---------------------------------------------------------------------------------------------------+
| [<- Hàng chờ Khiếu nại]   PHÒNG XỬ LÝ TRANH CHẤP #DSP-042 (Đơn #ORD-2026-0891)                    |
+---------------------------------------------------------------------------------------------------+
| 🔒 TRẠNG THÁI HIỆN TẠI: OPEN | 🛡️ TIỀN ĐANG ĐÓNG BĂNG TRONG ESCROW: 643.000 VNĐ (total_amount)    |
|    (Trong đó: Tiền hàng item_subtotal = 600.000đ | Phí bảo vệ buyer_protection_fee = 43.000đ)     |
+---------------------------------------------------------------------------------------------------+
| +-----------------------------------------------+ +---------------------------------------------+ |
| | 🙋 HỒ SƠ KHIẾU NẠI CỦA NGƯỜI MUA (BUYER)      | | 🏪 HỒ SƠ ĐỐI CHỨNG CỦA NGƯỜI BÁN (SELLER)   | |
| | • Mở lúc đơn ở trạng thái: DELIVERED (DEC-03) | | • Lỗi đã khai báo lúc đăng (Snapshot):      | |
| | • Lý do: Hàng bị rách / Không đúng mô tả      | |   "Chỉ ghi cúc thứ 2 xước nhẹ, không ghi    | |
| | • Mô tả: "Áo bị rách 5cm ở sau lưng"          | |    vết rách sau lưng."                      | |
| | • Bằng chứng: [Ảnh 1] [Ảnh 2] [Ảnh 3]         | | • Giải trình của Seller & Ảnh đóng gói      | |
| +-----------------------------------------------+ +---------------------------------------------+ |
|                                                                                                   |
| 🛠️ KHU VỰC 1: YÊU CẦU BỔ SUNG BẰNG CHỨNG (Dành cho cả Support Staff [ACT-04] & Admin [ACT-05])   |
| +-----------------------------------------------------------------------------------------------+ |
| | Nội dung yêu cầu 2 bên cung cấp thêm: [ Vui lòng chụp rõ tem mác và bao bì lúc nhận hàng... ] | |
| |                                       [ 📩 GỬI YÊU CẦU BỔ SUNG (REQUEST_MORE_EVIDENCE) ]      | |
| +-----------------------------------------------------------------------------------------------+ |
|                                                                                                   |
| ⚖️ KHU VỰC 2: PHÁN QUYẾT TÀI CHÍNH CUỐI CÙNG (ĐỘC QUYỀN CHỈ HIỂN THỊ CHO ADMINISTRATOR - ACT-05)  |
| *(Ẩn và khóa 403 đối với Support Staff theo PERM-CM-09)*                                          |
| +-----------------------------------------------------------------------------------------------+ |
| | Chọn 1 trong 3 Phán quyết Tài chính (Thực thi nguyên tử trong DB::transaction + lockForUpdate)| |
| |                                                                                               | |
| | (◉) 1. CHẤP NHẬN KHIẾU NẠI – HOÀN TRẢ 100% CHO NGƯỜI MUA (APPROVE_BUYER_REFUND - DEC-07)      | |
| |        -> Hoàn trả đủ 100% total_amount = 643.000 VNĐ (Gồm 600.000đ tiền hàng + 43.000đ phí)  | |
| |        -> Người bán nhận: 0 VNĐ | Đơn hàng chuyển sang: REFUNDED                              | |
| |                                                                                               | |
| | ( ) 2. BÁC BỎ KHIẾU NẠI – GIẢI NGÂN 100% TIỀN HÀNG CHO NGƯỜI BÁN (RELEASE_TO_SELLER - DEC-04) | |
| |        -> Cộng 100% item_subtotal = 600.000 VNĐ vào Ví Người bán | Sàn giữ phí: 43.000 VNĐ    | |
| |        -> Đơn hàng chuyển sang: COMPLETED                                                     | |
| |                                                                                               | |
| | ( ) 3. HOÀN TIỀN MỘT PHẦN – CHIA SẺ THIỆN CHÍ (PARTIAL_REFUND - BR-FN-06)                     | |
| |        -> Nhập số tiền hoàn cho Buyer (0 < X < 600.000đ): [ 150.000 VNĐ ]                     | |
| |        -> Tự động tính tiền giải ngân cho Seller:          450.000 VNĐ (600.000 - 150.000)    | |
| |        -> Sàn giữ phí bảo vệ: 43.000 VNĐ (Tổng cân bằng: 150k + 450k + 43k = 643.000đ)        | |
| |                                                                                               | |
| | Ghi chú phán quyết bắt buộc (Lưu vào audit_logs): [ Xác nhận áo bị rách ngoài mô tả ban đầu ] | |
| |                                                                                               | |
| |                        [ ⚖️ XÁC NHẬN & THỰC THI PHÁN QUYẾT TÀI CHÍNH ]                        | |
| +-----------------------------------------------------------------------------------------------+ |
+---------------------------------------------------------------------------------------------------+
```

---

### 2.4. `A-ES-01`: Immutable Escrow & Wallet Ledger Monitor (`/admin/escrow` – `Read-Only Ledger`)

```text
+---------------------------------------------------------------------------------------------------+
| 💳 GIÁM SÁT SỔ CÁI ESCROW & VÍ BẤT BIẾN (APPEND-ONLY READ-ONLY LEDGER - BR-FN-07)                 |
+---------------------------------------------------------------------------------------------------+
| 🔒 Quy tắc Toàn vẹn Tài chính: Sổ cái này ở chế độ CHỈ ĐỌC (Read-Only). Không ai (kể cả Admin)    |
|    được phép sửa hoặc xóa trực tiếp dòng bút toán lịch sử.                                        |
|                                                                                                   |
| Bộ lọc: [ Mã đơn hàng... ] [ Loại bút toán: Tất cả (HOLD / RELEASE / REFUND) v ] [ Lọc dữ liệu ]  |
| +---------------+---------------+--------------+---------------+----------------+---------------+ |
| | Mã Bút Toán   | Mã Đơn Hàng   | Loại Bút Toán| Tổng Tiền GD  | Phân Bổ Chi Tiết| Thời Gian Ghi | |
| +---------------+---------------+--------------+---------------+----------------+---------------+ |
| | ETX-2026-104  | #ORD-2026-0891| REFUND (100%)| 643.000 VNĐ   | Buyer: +643k   | 13/11 10:35   | |
| | ETX-2026-101  | #ORD-2026-0891| HOLD         | 643.000 VNĐ   | Giữ: 600k+43k  | 12/11 10:05   | |
| | ETX-2026-098  | #ORD-2026-0880| RELEASE      | 537.000 VNĐ   | Seller: +500k  | 11/11 18:00   | |
| |               |               |              |               | Sàn giữ: +37k  |               | |
| +---------------+---------------+--------------+---------------+----------------+---------------+ |
+---------------------------------------------------------------------------------------------------+
```

---

### 2.5. `A-ST-01` (Platform Settings – Cấu Hình Buyer Protection Fee) & `A-DT-01` (Developer Tools – Demo Mode)

#### A. `A-ST-01`: Platform Settings (`/admin/settings` – `DEC-04`, `ADR-05`)
```text
+---------------------------------------------------------------------------------------------------+
| ⚙️ CẤU HÌNH THÔNG SỐ NỀN TẢNG (PLATFORM SETTINGS - FR-AD-04)                                      |
+---------------------------------------------------------------------------------------------------+
| 1. CẤU HÌNH PHÍ BẢO VỆ NGƯỜI MUA & CHÍNH SÁCH VẬN CHUYỂN (DEC-04)                                 |
| +-----------------------------------------------------------------------------------------------+ |
| | • Phí vận chuyển trên ứng dụng (shipping_fee):        [ 0 VNĐ (Cố định miễn thu trên app) ]   | |
| | • Hoa hồng thu từ Người bán (seller_commission):      [ 0% (Seller nhận đủ 100% tiền hàng)]   | |
| | • Tỷ lệ % Phí bảo vệ người mua (protection_fee_rate): [ 6.0 ] %   (Cho phép từ 5.0% đến 8.0%) | |
| | • Phí bảo vệ cố định (protection_fixed_fee):          [ 7000 ] đ  (Cho phép từ 5.000đ - 10k)  | |
| +-----------------------------------------------------------------------------------------------+ |
|                                                                                                   |
| 2. CẤU HÌNH THỜI GIAN TỰ ĐỘNG (PRODUCTION MODE vs DEMO MODE - ADR-05)                             |
| +---------------------------------------------+-------------------------------------------------+ |
| | Thông số Thời gian                          | Production Mode         | Demo Mode (Bảo vệ ĐA) | |
| +---------------------------------------------+-------------------------+-----------------------+ |
| | • Hạn thanh toán đơn thắng đấu giá:         | [ 30 ] phút             | [ 2  ] phút           | |
| | • Thời gian tự hoàn tất đơn sau DELIVERED:  | [ 24 ] giờ              | [ 2  ] phút           | |
| | • Ngưỡng nhạy cảm & cộng giờ Anti-Sniping:  | [ 120 ] giây (+2 phút)  | [ 30 ] giây (+30 giây)| |
| +---------------------------------------------+-------------------------+-----------------------+ |
|                                                        [ 💾 LƯU CẤU HÌNH & GHI AUDIT LOG ]        |
+---------------------------------------------------------------------------------------------------+
```

#### B. `A-DT-01`: Developer Tools Control Panel (`/admin/dev-tools` – Chỉ hiện khi `DEMO_MODE=true`)
```text
+---------------------------------------------------------------------------------------------------+
| 🧪 CÔNG CỤ TRÌNH DIỄN ĐỒ ÁN (DEVELOPER TOOLS - DEMO_MODE=true - FR-AD-05 & ADR-05)                |
+---------------------------------------------------------------------------------------------------+
| ℹ️ Bảng điều khiển này gọi trực tiếp vào cùng các Service Class có tính Lũy đẳng (Idempotent)     |
|    của Laravel Scheduler để trình diễn tức thì các luồng phụ thuộc thời gian trước Hội đồng.      |
|                                                                                                   |
| +-----------------------------------------------------------------------------------------------+ |
| | 🔨 TÁC VỤ 1: ĐÓNG PHIÊN ĐẤU GIÁ & SINH ĐƠN HÀNG CHO NGƯỜI THẮNG (CloseExpiredAuctionsJob)     | |
| | • Chọn phiên đang LIVE (hoặc tất cả phiên hết hạn): [ #AUC-108: Đồng hồ Seiko (Giá: 900k) v ] | |
| | [ ⚡ RUN: KẾT THÚC PHIÊN & TẠO ĐƠN HÀNG THẮNG ĐẤU GIÁ NGAY ]                                  | |
| +-----------------------------------------------------------------------------------------------+ |
|                                                                                                   |
| +-----------------------------------------------------------------------------------------------+ |
| | ⏰ TÁC VỤ 2: HỦY ĐƠN ĐẤU GIÁ QUÁ HẠN THANH TOÁN (ExpireUnpaidAuctionOrdersJob - DEC-02)       | |
| | • Quét các đơn thắng đấu giá chưa thanh toán quá hạn -> Hủy đơn, đánh dấu WINNER_DEFAULTED    | |
| |   và mở khóa sản phẩm để Người bán đăng lại vào phiên tiếp theo.                              | |
| | [ ⚡ RUN: XỬ LÝ NGAY ĐƠN ĐẤU GIÁ QUÁ HẠN THANH TOÁN ]                                         | |
| +-----------------------------------------------------------------------------------------------+ |
|                                                                                                   |
| +-----------------------------------------------------------------------------------------------+ |
| | 💰 TÁC VỤ 3: TỰ ĐỘNG HOÀN TẤT ĐƠN ĐÃ GIAO & GIẢI NGÂN ESCROW (AutoCompleteDeliveredOrdersJob) | |
| | • Quét các đơn đang DELIVERED (không có Dispute mở) -> Chuyển sang COMPLETED, RELEASED        | |
| |   và giải ngân 100% tiền hàng (item_subtotal) vào Ví Người bán.                               | |
| | [ ⚡ RUN: TỰ ĐỘNG HOÀN TẤT ĐƠN & GIẢI NGÂN ESCROW NGAY ]                                      | |
| +-----------------------------------------------------------------------------------------------+ |
+---------------------------------------------------------------------------------------------------+
```

---

## Chương 3. Kết Quả Tự Động Kiểm Tra & Nghiệm Thu (`Self-Verified Quality Gate Checklist`)

- [x] **1. Đầy đủ Wireframe cho toàn bộ các màn hình Quản trị Trọng tâm:** Bao gồm Khung Layout Shell (Sidebar lọc theo Role RBAC), Dashboard KPI Live, Kiểm duyệt Sản phẩm (`A-MD-02`), Phòng Phân xử Khiếu nại tách quyền Support/Admin (`A-DP-02`), Giám sát Sổ cái Escrow Read-Only (`A-ES-01`), Cấu hình Phí bảo vệ & Thời gian (`A-ST-01`) và Bảng điều khiển Developer Tools (`A-DT-01`).
- [x] **2. Phản ánh chính xác 100% Ràng buộc Nghiệp vụ & Bảo mật:** Khóa nút phán quyết tài chính đối với Support Staff, khóa sửa số dư trực tiếp trên sổ cái Escrow, hiển thị đầy đủ 3 phương án phân xử tranh chấp (`APPROVE_BUYER_REFUND`, `RELEASE_TO_SELLER`, `PARTIAL_REFUND`) và 3 nút kích hoạt lũy đẳng trong Demo Mode.