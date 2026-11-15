# 04. ADMIN MODERATION & DISPUTE RESOLUTION UI SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P306D-MODERATION-DISPUTE-UI`
- **Version:** `1.0.0 (HIGH-FIDELITY FULL SPECIFICATION)`
- **Status:** `SELF-VERIFIED & READY FOR PO REVIEW`
- **Project Codename:** `RETRO MARKET`
- **Application Brand Name:** `izithrift`
- **Phase:** `Phase 03 – Task P3-06 (Group 4: Moderation & Dispute Resolution)`
- **Screen IDs Covered:** `A-MD-01` (Product Moderation Queue), `A-MD-02` (Product Inspection & Approve/Reject), `A-CM-01` (Review & Violation Report Moderation), `A-DP-01` (Dispute Queue), `A-DP-02` (Dispute Case Resolution Room)
- **Compliance Ref:** `AFW-03`, `AFW-04`, `AFW-07`, `FR-MD-01..02`, `FR-DP-01..03`, `PERM-PR-06..07`, `PERM-CM-04..11`, `BR-PR-03..04`, `BR-DP-02`, `BR-FN-04..07`, `DEC-03`, `DEC-05`, `DEC-07`

---

## Chương 1. Thiết Kế Giao Diện Kiểm Duyệt & Phân Xử Tranh Chấp (`High-Trust Split-Pane Architecture`)

Hai quy trình tác nghiệp quan trọng nhất của đội ngũ quản trị trên **Retro Market (`izithrift`)** là:
1. **Kiểm duyệt chất lượng sản phẩm đồ secondhand trước khi lên kệ (`A-MD-01`, `A-MD-02` – `DEC-05`)** và **Xử lý báo cáo vi phạm (`A-CM-01`)**.
2. **Phân xử khiếu nại giao dịch & Điều phối dòng tiền Escrow (`A-DP-01`, `A-DP-02` – `DEC-03`, `DEC-07`)**.

Để giúp nhân sự quản trị đưa ra quyết định chính xác, không bỏ sót bằng chứng và tuyệt đối không vi phạm ma trận phân quyền, toàn bộ các màn hình chi tiết áp dụng bố cục **2 Cột Đối Chiếu (`Split-Pane Inspection Layout`)** kèm các cơ chế khóa bảo vệ giao diện (`RBAC UI Guards`).

---

## Chương 2. Đặc Tả High-Fidelity Cụm Kiểm Duyệt Sản Phẩm & Báo Cáo (`A-MD-01`, `A-MD-02`, `A-CM-01`)

### 2.1. Screen `A-MD-01` (Moderation Queue) & `A-MD-02` (Product Inspection Split-Pane – `DEC-05`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen IDs & Names** | - `A-MD-01`: Product Moderation Queue (`GET /admin/moderation/products`)<br>- `A-MD-02`: Product Inspection & Approve/Reject Screen (`GET/POST /admin/moderation/products/{id}`) |
| **Quyền Truy Cập** | `Administrator (ACT-05)` và `Moderator (ACT-03)` (`PERM-PR-06`, `PERM-PR-07`). |
| **Bố Cục `A-MD-01` (Queue List)** | - **Header KPI Mini:** Số sản phẩm đang chờ duyệt (`PENDING_REVIEW`), phân tách rõ hàng `Giá cố định` vs hàng `Đấu giá` (ưu tiên hiển thị nhãn cảnh báo đỏ **`[🔥 Phiên đấu giá sắp mở]`** cho các bài đăng đấu giá cần duyệt gấp trước giờ mở phiên).<br>- **Data Table:** Ảnh bìa `52x52px` \| Tên sản phẩm \| Loại bán \| Người bán (kèm điểm uy tín & số lần từng bị từ chối) \| Tình trạng (`condition`) \| Thời gian gửi duyệt \| Nút Primary **`[🛡️ Kiểm duyệt ngay ->]`** ($\rightarrow$ Mở `A-MD-02`). |
| **Bố Cục `A-MD-02` (Split-Pane 7/5)** | **Lưới 12 Cột (`Gap 24px`):**<br>- **Cột Trái (`7/12 Cột` – Khu vực Soi Ảnh & Lịch sử):**<br>  1. **Trình xem Ảnh Độ phân giải cao (`Product Image & Evidence Inspector`):** Khung ảnh lớn + danh sách tất cả ảnh sản phẩm và ảnh bằng chứng xác thực (`authenticity_evidence`: ảnh tag, mã code, hóa đơn) hỗ trợ bấm phóng to (`Lightbox Zoom`) để kiểm tra xem ảnh có khớp với mô tả lỗi không.<br>  2. **Bảng Lịch sử Kiểm duyệt Trước Đó (`product_moderation_logs`):** Hiển thị các lần Moderator từ chối trước đó và nội dung Seller vừa chỉnh sửa gửi lại (`Resubmit` – `DEC-05`).<br>- **Cột Phải (`5/12 Cột`, `position: sticky; top: 88px` – Phiếu Đối Chiếu & Khung Ra Quyết Định):**<br>  1. **Phiếu Thông Tin Khai Báo Của Seller (`Bg #FFFFFF`, `Border 1px #D8CBB8`, `Radius 12px`, `Padding 20px`):**<br>     - Tên sản phẩm, Danh mục, Thương hiệu, Giá bán (hoặc Giá khởi điểm, Bước giá, Khung giờ phiên đấu giá).<br>     - Khối làm nổi bật (`Bg #FBF0D9`, viền trái `3px solid #945814`, padding `12px`): **`Tình trạng (condition)`** & **`Mô tả khuyết điểm / vết xước (defect_info - BR-PR-03)`**.<br>  2. **Khung Ra Quyết Định Kiểm Duyệt (`CMP-ADM-04` – `Bg #FFFFFF`, `Border 1.5px #294638`, `Radius 12px`, `Padding 20px`):**<br>     - **Bước 1 – Gán Mức Độ Xác Minh (`verification_level`):** Dropdown chọn 1 trong 3 mức:<br>       - `MODERATOR_REVIEWED` *(Đã kiểm duyệt hình ảnh & thông tin đầy đủ)*<br>       - `EVIDENCE_PROVIDED` *(Người bán có đính kèm bằng chứng xác thực)*<br>       - `UNVERIFIED` *(Duyệt tiêu chuẩn, không có bằng chứng bổ sung)*.<br>     - **Bước 2 – Ô Nhập Lý Do Từ Chối / Yêu Cầu Chỉnh Sửa (`reason`):** TextArea (`Height 96px`) kèm 4 chip gợi ý lý do nhanh (*"Ảnh mờ chưa thấy rõ vết xước đã mô tả"*, *"Thiếu ảnh chụp tag/mã code sản phẩm"*, *"Giá hoặc thông tin tình trạng chưa nhất quán"*, *"Nội dung vi phạm quy định sàn"*).<br>     - **Bước 3 – Cụm 2 Nút Hành Động:**<br>       - Nút Xanh (`Primary Button #294638`, rộng 55%): **`[✅ Phê duyệt (Approve)]`** $\rightarrow$ Chuyển `status = APPROVED` (đưa lên sàn / phiên đấu giá).<br>       - Nút Đỏ (`Destructive Button #A62B2B`, rộng 42%): **`[❌ Từ chối (Reject)]`** $\rightarrow$ **Kiểm tra bắt buộc `reason` không được rỗng (`BR-PR-04`, `DEC-05`)**; nếu trống báo lỗi đỏ tại chỗ và khóa gửi; nếu đủ chuyển `status = REJECTED`, ghi `product_moderation_logs` + `audit_logs` và thông báo cho Seller. |

---

### 2.2. Screen `A-CM-01`: Review & Violation Report Moderation (`GET/POST /admin/moderation/reports` – `AFW-04`)

- **Quyền Truy Cập:** `Administrator (ACT-05)` và `Moderator (ACT-03)` (`PERM-CM-04`, `PERM-CM-11`).
- **Cấu trúc 2 Tab Quản Trị:**
  - **Tab 1 – Hàng chờ Báo cáo Vi phạm (`reports`):** Hiển thị Người báo cáo, Đối tượng bị báo cáo (`PRODUCT`, `USER`, `CONVERSATION` – kèm link mở nhanh xem sản phẩm/hồ sơ), Lý do vi phạm, Mô tả chi tiết và cụm nút xử lý: **`[Ẩn sản phẩm vi phạm (HIDDEN)]`**, **`[Chuyển Admin khóa tài khoản]`**, hoặc **`[Bác bỏ báo cáo (Dismiss)]`**.
  - **Tab 2 – Kiểm duyệt Đánh giá (`reviews`):** Danh sách các bài đánh giá `1–5 sao` trên toàn sàn. Nếu phát hiện đánh giá chứa ngôn từ thô tục, spam quảng cáo hoặc công kích cá nhân vi phạm tiêu chuẩn cộng đồng, Moderator/Admin nhấn **`[Ẩn đánh giá vi phạm (`Hide Review`)]`** (kèm lý do bắt buộc; hệ thống tự động tính lại `average_rating` của Seller và ghi `audit_logs`).

---

## Chương 3. Đặc Tả High-Fidelity Cụm Quản Lý & Phân Xử Khiếu Nại (`A-DP-01`, `A-DP-02` – `DEC-03`, `DEC-07`)

### 3.1. Screen `A-DP-01`: Dispute & Complaint Queue (`GET /admin/disputes` – `AFW-07`)

- **Quyền Truy Cập:** `Administrator` *(Xem toàn bộ hồ sơ)* và `Support Staff` *(Chỉ xem các hồ sơ được phân công `ASSIGNED` – `PERM-CM-08`)*.
- **Data Table Hàng Chờ Tranh Chấp:**
  - `Mã Khiếu nại (#DSP-...)` \| `Mã Đơn hàng (#ORD-...)` \| `Trạng thái lúc mở` (`SHIPPED` / `DELIVERED` – `DEC-03`) \| `Buyer vs Seller` \| `Lý do khiếu nại` \| `Tiền đóng băng Escrow (total_amount)` \| `Trạng thái xử lý` (`OPEN` `#6A2C5A`, `NEED_MORE_INFO` `#945814`, `RESOLVED` `#236343`) \| `Nhân sự phụ trách` \| Nút **`[⚖️ Mở Phòng Phân Xử -> A-DP-02]`**.

---

### 3.2. Screen `A-DP-02`: Dispute Case Resolution Room (`GET/POST /admin/disputes/{id}` – `OF-08`, `OF-09`, `DEC-07`)

| Thuộc Tính | Đặc Tả Chi Tiết High-Fidelity |
| :--- | :--- |
| **Screen ID & Name** | `A-DP-02` – Dispute Case Resolution Room (`GET/POST /admin/disputes/{id}`) |
| **Purpose** | Tập trung toàn bộ bằng chứng của Buyer, giải trình của Seller, bản chụp đơn hàng gốc (`order_items` snapshot), lịch sử vận chuyển và chat vào một màn hình duy nhất để Support Staff thu thập bằng chứng và **Administrator ra phán quyết tài chính cuối cùng** (`FR-DP-02..03`, `PERM-CM-08..09`). |
| **Header Banner (`Full-width 12 cột`)** | - Nền tím mận nhạt `#F4E4F0`, viền `1.5px solid #6A2C5A`, `Radius 12px`, `Padding 16px 20px`:<br>- Trái: Huy hiệu **`🔒 TIỀN ĐANG ĐÓNG BĂNG TRONG ESCROW (FROZEN HELD)`** + Mã đơn `#ORD-2026-0891` + Mốc mở khiếu nại (ở trạng thái `SHIPPED` hoặc `DELIVERED` – `DEC-03`).<br>- Phải (Bảng số liệu tài chính của đơn tranh chấp):<br>  - `Tiền hàng (item_subtotal):` **`600.000 VNĐ`** \| `Phí bảo vệ người mua:` **`43.000 VNĐ`** \| **`Tổng tiền đang giữ (total_amount): 643.000 VNĐ`**. |
| **Bố Cục 2 Cột Đối Chiếu (`7/12 Cột Trái` vs `5/12 Cột Phải`)** | **CỘT TRÁI (`7/12 Cột` – Hồ Sơ Đối Chứng Đa Chiều):**<br>1. **Thẻ Bằng Chứng Của Người Mua (`Buyer Claim Card` – Viền trái `4px solid #873A43`):** Lý do khiếu nại, mô tả chi tiết và lưới ảnh bằng chứng độ phân giải cao (`dispute_evidence` – click mở Lightbox phóng to).<br>2. **Thẻ Giải Trình & Đối Chứng Của Người Bán (`Seller Counter-Evidence Card` – Viền trái `4px solid #294638`):** Giải trình của shop, ảnh đóng gói/phiếu vận đơn.<br>3. **Thẻ Đối Chiếu Bản Chụp Đơn Hàng Gốc (`Order Snapshot & Shipment Audit`):** Hiển thị nguyên văn mô tả lỗi `defect_snapshot` lúc người mua đặt hàng (`BR-OR-02`) và lịch sử vận đơn `tracking_code` để Admin so sánh xem vết rách/lỗi đã được khai báo từ đầu hay chưa.<br>4. **Khung Lịch Sử Tin Nhắn Chat Giữa 2 Bên (`Conversation Transcript`):** Hiển thị lịch sử trao đổi trong `M-CM-02` (Read-Only) để kiểm tra thỏa thuận giữa hai bên.<br><br>**CỘT PHẢI (`5/12 Cột`, `position: sticky; top: 88px` – Bảng Điều Khiển Xử Lý Theo Phân Quyền RBAC):**<br>- **Khối A – Yêu Cầu Bổ Sung Bằng Chứng (`Hiển thị cho CẢ Support Staff [ACT-04] VÀ Administrator [ACT-05]` – `PERM-CM-08`):**<br>  - Khung nền `#FFFFFF`, viền `1px #D8CBB8`, `Radius 12px`, `Padding 20px`:<br>  - Nhập nội dung yêu cầu gửi cho Buyer hoặc Seller + Nút Secondary **`[📩 Gửi Yêu Cầu Bổ Sung Bằng Chứng (`REQUEST_MORE_EVIDENCE`)]`** (`POST /admin/disputes/{id}/request-evidence` $\rightarrow$ Chuyển trạng thái sang `NEED_MORE_INFO`).<br>- **Khối B – Phán Quyết Tài Chính Cuối Cùng (`CMP-ADM-05` – ĐỘC QUYỀN CHỈ HIỂN THỊ CHO `ADMINISTRATOR [ACT-05]` – `PERM-CM-09`):**<br>  - *(Nếu tài khoản đang đăng nhập là `Support Staff`, toàn bộ Khối B này bị ẩn hoàn toàn ở tầng Blade `@can('resolve', $dispute)` và hiển thị một hộp chú thích nhỏ: "ℹ️ Quyền ra phán quyết hoàn tiền / giải ngân thuộc thẩm quyền của Administrator")*.<br>  - **Khi tài khoản là `Administrator`:** Hiển thị khung viền `2px solid #294638`, nền `#FFFFFF`, padding `20px` với **3 Radio Decision Cards**:<br>    1. **Card 1 – `APPROVE_BUYER_REFUND` *(Chấp nhận Khiếu nại – Hoàn trả 100% cho Buyer theo `DEC-07`)*:**<br>       - Hiển thị rõ số tiền hạch toán: **Hoàn trả Buyer = `643.000 VNĐ` (`100% total_amount` gồm `600.000đ` tiền hàng + `43.000đ` Phí bảo vệ)** \| **Seller nhận = `0 VNĐ`**.<br>    2. **Card 2 – `RELEASE_TO_SELLER` / `REJECT_DISPUTE` *(Bác bỏ Khiếu nại – Giải ngân cho Seller theo `DEC-04`)*:**<br>       - Hiển thị rõ số tiền hạch toán: **Giải ngân vào Ví Seller = `600.000 VNĐ` (`100% item_subtotal`)** \| **Buyer nhận = `0 VNĐ`** \| **Nền tảng giữ phí bảo vệ = `43.000 VNĐ`**.<br>    3. **Card 3 – `PARTIAL_REFUND` *(Hoàn tiền Một phần theo `BR-FN-06`)*:**<br>       - Ô nhập số tiền hoàn cho Buyer (`0 < partial_refund_amount < 600.000đ`).<br>       - Tự động tính real-time bên dưới: **Seller nhận = `600.000đ - partial_refund_amount`** \| **Nền tảng giữ phí = `43.000đ`** \| **Tổng cân bằng = `643.000đ`**.<br>  - **Ô Nhập Lý Do Phán Quyết Bắt Buộc (`resolution_note *`):** Lưu vào bảng `disputes` và `audit_logs` (`BR-AD-02`).<br>  - **Nút Xác Nhận (`Primary Button #294638`, Cao `48px`, Full-width):** **`[⚖️ Xác Nhận & Thực Thi Phán Quyết Tài Chính]`** (Bật Confirmation Dialog trước khi gọi `POST /admin/disputes/{id}/resolve`). |