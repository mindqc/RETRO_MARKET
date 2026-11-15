# 02. ADMIN LIVE KPI DASHBOARD UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P306B-ADMIN-DASHBOARD-UI`
- **Version:** `1.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – Task P3-06 (Group 2: Dashboard Overview)`
- **Screen ID Covered:** `A-DB-01` (`GET /admin/dashboard`)
- **Compliance Ref:** `AFW-02`, `FR-AD-01`, `PERM-AD-01`, `CON-04`, `DEC-04`, `NFR-PER-01`

---

## Chương 1. Nguyên Tắc Hiển Thị Chỉ Số Thời Gian Thực (`Live PostgreSQL Metrics Architecture`)

Màn hình Tổng quan (`A-DB-01`) là điểm chạm đầu tiên sau khi nhân sự nội bộ đăng nhập thành công. Giao diện tuân thủ 3 quy tắc kỹ thuật:
1. **Dữ liệu Thực 100% Từ PostgreSQL (`Zero Hardcoded Metrics – CON-04`):** Mọi con số trên các thẻ KPI đều được truy vấn trực tiếp từ CSDL tại thời điểm tải trang, kèm nhãn thời gian cập nhật gần nhất (`"Cập nhật lúc: 21:42:05"` + nút `[🔄 Làm mới số liệu]`).
2. **Hiển thị Phân tầng Theo Quyền Hạn (`Role-Filtered KPI Grid`):**
   - **Administrator (`ACT-05`):** Nhìn thấy toàn bộ **7 Thẻ KPI** (4 thẻ Vận hành + 3 thẻ Tài chính & Sổ cái Escrow).
   - **Moderator (`ACT-03`):** Chỉ nhìn thấy nhóm KPI Kiểm duyệt (Hàng chờ `PENDING_REVIEW`, Sản phẩm đã duyệt, Báo cáo vi phạm chờ xử lý) và bị ẩn khối Tài chính Escrow.
   - **Support Staff (`ACT-04`):** Chỉ nhìn thấy nhóm KPI Hỗ trợ (Khiếu nại đang mở `OPEN`, Khiếu nại cần bổ sung bằng chứng `NEED_MORE_INFO`, Đơn hàng đang tranh chấp).
3. **Thẻ KPI Hành Động Nhanh (`Actionable Metric Cards`):** Mỗi thẻ KPI đều có liên kết điều hướng trực tiếp tới hàng chờ xử lý tương ứng để rút ngắn thao tác quản trị.

---

## Chương 2. Đặc Tả High-Fidelity Màn Hình `A-DB-01` (`GET /admin/dashboard`)

### 2.1. Cấu Trúc Lưới 12 Cột & Chi Tiết Từng Thẻ KPI (`CMP-ADM-02`)

| Nhóm Khu Vực | Mã Thẻ & Bố Cục Lưới | Dữ Liệu Hiển Thị & Tokens (`Be Vietnam Pro Tabular`) | Nút Điều Hướng Nhanh (`Deep Link`) |
| :--- | :--- | :--- | :--- |
| **Hàng 1: Chỉ Số Vận Hành Sàn**<br>*(4 Thẻ – Mỗi thẻ chiếm `3/12 cột`, Cao `132px`, `Bg #FFFFFF`, `Border 1px #D8CBB8`, `Radius 12px`, `Padding 20px`)* | **KPI-01: Tổng Người Dùng** | - Icon: `Users 22px #294638` (Nền tròn `#E3ECE7`).<br>- Con số chính: **`142`** (`28px Bold #302D2A tabular-nums`).<br>- Phân rã phụ (`12px #655E57`): `139 Đang hoạt động` \| `3 Bị khóa`. | `[Quản lý Users ->]` (`A-US-01`) |
| | **KPI-02: Hàng Chờ Kiểm Duyệt** | - Icon: `ShieldWarning 22px #945814` (Nền tròn `#FDF1E1`).<br>- Con số chính: **`18`** (`28px Bold #945814 tabular-nums`).<br>- Phân rã phụ: `14 Giá cố định` \| `04 Đấu giá`. | **`[Vào duyệt ngay ->]`** (`A-MD-01`) |
| | **KPI-03: Phiên Đấu Giá** | - Icon: `Gavel 22px #873A43` (Nền tròn `#F4E5E7`).<br>- Con số chính: **`06`** (`28px Bold #873A43 tabular-nums`).<br>- Phân rã phụ: `06 Đang LIVE` \| `24 Đã hoàn tất`. | `[Giám sát đấu giá ->]` (`A-AC-02`) |
| | **KPI-04: Khiếu Nại Đang Mở** | - Icon: `Scales 22px #6A2C5A` (Nền tròn `#F4E4F0`).<br>- Con số chính: **`03`** (`28px Bold #6A2C5A tabular-nums`).<br>- Phân rã phụ: `02 Mới mở (OPEN)` \| `01 Chờ bằng chứng`. | **`[Xử lý tranh chấp ->]`** (`A-DP-01`) |
| **Hàng 2: Đối Soát Tài Chính & Sổ Cái Escrow**<br>*(Chỉ hiển thị cho `Administrator` – 3 Thẻ, mỗi thẻ chiếm `4/12 cột`, Cao `140px`, `Bg #FFFFFF`, `Border 1.5px #1C5858`, `Radius 12px`, `Padding 20px`)* | **FIN-01: Tổng Tiền Đang Giữ Trong Escrow** | - Nhãn: `🔒 ĐANG GIỮ BẢO VỆ (escrow_status = HELD)` (`12px SemiBold #1C5858`).<br>- Con số chính: **`12.850.000 VNĐ`** (`26px Bold #1C5858 tabular-nums`).<br>- Chú thích: *"Tổng total_amount của 19 đơn hàng đang giao dịch."* | `[Xem Sổ cái Escrow ->]` (`A-ES-01`) |
| | **FIN-02: Tổng Tiền Hàng Đã Giải Ngân Cho Seller** | - Nhãn: `✅ ĐÃ GIẢI NGÂN CHO NGƯỜI BÁN (100% item_subtotal)` (`12px SemiBold #236343`).<br>- Con số chính: **`48.200.000 VNĐ`** (`26px Bold #236343 tabular-nums`).<br>- Chú thích: *"Miễn phí hoa hồng người bán theo chính sách DEC-04."* | `[Đối soát Ví & Giao dịch ->]` (`A-ES-01`) |
| | **FIN-03: Doanh Thu Phí Bảo Vệ Người Mua** | - Nhãn: `🛡️ PHÍ BẢO VỆ NGƯỜI MUA ĐÃ THU (Buyer Protection Fee)` (`12px SemiBold #294638`).<br>- Con số chính: **`3.412.000 VNĐ`** (`26px Bold #294638 tabular-nums`).<br>- Chú thích: *"Cấu hình hiện tại: 6.0% + 7.000đ / đơn hoàn tất."* | `[Cấu hình mức phí ->]` (`A-ST-01`) |
| **Hàng 3: Bảng Tổng Hợp Nhanh** *(12 cột chia 2 khối ngang: Trái `6 cột`, Phải `6 cột`)* | **Block Trái: 5 Sản phẩm Chờ Duyệt Mới Nhất**<br>**Block Phải: 5 Nhật Ký Kiểm Toán Quản Trị Gần Nhất** | - Bảng rút gọn (`Bg #FFFFFF`, `Radius 12px`, `Border 1px #D8CBB8`): Hiển thị mã, đối tượng, người thực hiện, thời gian (`HH:mm DD/MM`) và nút `[Chi tiết]`. | `[Xem tất cả Hàng chờ]` / `[Xem toàn bộ Audit Logs]` |