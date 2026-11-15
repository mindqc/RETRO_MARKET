# P7-07: SELLER CHANNEL HUB, 7-STATE LISTINGS & WALLET LEDGER SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P707-SELLER-CHANNEL-LISTINGS`
- **Version:** `1.1.0`
- **Status:** `DONE / PO APPROVED`
- **Phase:** `Phase 07 – Task P7-07`
- **Dependencies:** `P7-01, P7-02, P7-03, P7-04, P7-06 Completed`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
Hiện thực hóa toàn diện Kênh Người bán (`Seller Channel`) cho mọi người dùng theo nguyên tắc tài khoản hợp nhất `BR-AC-01`. Bao gồm bảng điều khiển Người bán (`Seller Hub`), quản lý bài đăng theo 7 trạng thái, luồng tạo bài đăng mới (Giá cố định & Đấu giá `BR-PR-01`), luồng chỉnh sửa và gửi duyệt lại bài đăng bị từ chối (`DEC-05`), và sổ cái ví tiền người bán đối soát Escrow minh bạch. Gói này bao gồm đúng **5 màn hình Mobile**:
- `M-SL-01`: Bảng điều khiển Kênh Người bán (`Seller Hub`)
- `M-SL-02`: Quản lý Sản phẩm theo 7 Trạng thái (`Seller Listings Manager`)
- `M-SL-03`: Đăng bán Sản phẩm Mới (`Create Listing Form`)
- `M-SL-04`: Chỉnh sửa & Gửi duyệt lại (`Edit & Resubmit Listing`)
- `M-SL-08`: Sổ cái Ví Người bán & Đối soát Tiền Ký quỹ (`Seller Wallet Ledger`)

---

## 2. Screen Specifications & UX Flows (`Đặc Tả Chi Tiết 5 Màn Hình`)

### 2.1. `M-SL-01: Seller Hub Screen`
- **Thanh Tiêu Đề:** Nút quay lại Trung tâm cá nhân `M-PF-01`, Tên tiệm, `shop_slug`.
- **Thẻ Tóm Tắt Tài Chính Tiệm (`Seller Wallet Card`):**
  - Số dư khả dụng (`wallet_balance` VNĐ).
  - Số dư ký quỹ đang tạm giữ (`escrow_held_balance` VNĐ - tiền của các đơn đang chuẩn bị/đang giao/khiếu nại).
  - Nút `[Chi tiết sổ cái]` mở `M-SL-08`.
- **Hàng Việc Cần Làm Ngay (`Action Required Counters`):**
  - `Cần chuẩn bị hàng` (đơn `PAID`), `Cần giao cho vận chuyển` (đơn `PREPARING`), `Đơn có khiếu nại` (`DISPUTED`), `Bài đăng bị từ chối` (`REJECTED`).
- **Nút Hành Động Nổi Bật:**
  - Nút lớn cao `52px` màu Burgundy: **`[+ ĐĂNG BÁN SẢN PHẨM MỚI]`** mở `M-SL-03`.
- **Menu Quản Lý Tiệm:**
  - `Quản lý kho đồ đăng bán` (mở `M-SL-02`).
  - `Đơn bán của Tiệm` (mở `M-SL-05`).
  - `Xem cửa hàng của tôi như khách xem` (mở `M-US-03`).

### 2.2. `M-SL-02: Seller Listings Management Screen`
- **Thanh 7 Tab Trạng Thái:**
  - `TẤT CẢ`, `CHỜ DUYỆT` (`PENDING_REVIEW`), `ĐANG BÁN` (`APPROVED`), `BỊ TỪ CHỐI` (`REJECTED` kèm chấm đỏ), `ĐÃ BÁN` (`SOLD`), `BẢN NHÁP` (`DRAFT`), `ĐÃ ẨN` (`HIDDEN`).
- **Thẻ Sản Phẩm Quản Lý Trong Danh Sách:**
  - Ảnh đại diện, Tiêu đề, Mã sản phẩm, Giá bán, Tồn kho.
  - Các nút tác vụ nhanh theo trạng thái:
    - Nếu là `REJECTED`: Nút nổi bật **`[Xem lý do & Gửi duyệt lại]`** dẫn sang `M-SL-04`.
    - Nếu là `APPROVED`: Nút bật/tắt `[Ẩn bài / Hiện lại]` gọi `PATCH /api/v1/seller/products/{id}/status`.
    - Nếu là Đấu giá bị hủy do bỏ cọc hoặc không ai mua: Nút **`[Tái đăng đấu giá (Relist)]`** (`DEC-02`).
    - Nút `[Xóa]` (chỉ bật ở `DRAFT`).

### 2.3. `M-SL-03: Create Listing Form Screen`
- **Loại Hình Bán Hàng:** Nút chuyển đổi chọn `[Giá cố định]` hoặc `[Đấu giá theo phiên]`.
  - Nếu chọn `Đấu giá`: Tự động khóa số lượng tồn kho = `1` (`BR-PR-01`), mở thêm các trường: Giá khởi điểm, Bước giá tối thiểu, Giá bảo lưu (tùy chọn), Khung giờ phiên đấu giá.
- **Tải Lên Hình Ảnh:**
  - Chọn tối đa 10 ảnh từ thư viện hoặc chụp ảnh trực tiếp. Ảnh đầu tiên được đánh dấu là `Ảnh chính (Primary Image)`.
  - Kiểm tra kích thước `<= 5MB` mỗi ảnh (`NFR-SEC-03`).
- **Thông Tin Cơ Bản:**
  - Tiêu đề sản phẩm, Danh mục (chọn từ cây phân cấp), Thương hiệu.
  - Giá bán (VNĐ).
  - Số lượng (cho sản phẩm Giá cố định).
- **Mục Bắt Buộc Đối Với Đồ Secondhand (`BR-PR-03`):**
  - **Tình trạng độ mới (`condition`):** Chọn 1 trong 5 mức (`Mới nguyên tem`, `Như mới 95%+`, `Tốt`, `Trung bình`, `Vintage sờn rách tự nhiên`).
  - **Mô tả chi tiết khuyết điểm (`defect_info`):** Bắt buộc nhập ít nhất 5 ký tự mô tả trung thực mọi vết sờn, ố, xước, lỗi đường may (nghiêm cấm để trống).
- **2 Nút Lưu:**
  - `[Lưu bản nháp]` (`submit_for_review = false`, trạng thái `DRAFT`).
  - `[Gửi phê duyệt ngay]` (`submit_for_review = true`, trạng thái `PENDING_REVIEW`).

### 2.4. `M-SL-04: Edit & Resubmit Rejected Listing Screen` (`DEC-05`)
- **Hộp Ghim Lý Do Từ Chối Ở Đầu Trang (`Rejection Reason Box`):**
  - Hiển thị trên nền đỏ Burgundy nhạt với icon cảnh báo: Lý do kiểm duyệt viên từ chối (ví dụ: *"Vui lòng bổ sung ảnh chụp cận cảnh nhãn mác thương hiệu để xác thực"*).
- Biểu mẫu chỉnh sửa cho phép sửa đổi thông tin, tải thêm ảnh bằng chứng mới.
- Nút **`[Gửi duyệt lại (Resubmit)]`**:
  - Gửi request `POST /api/v1/seller/products/{id}` kèm `_method: PUT` và `submit_for_review: true`.
  - Hệ thống tự động xóa lý do từ chối cũ và chuyển trạng thái về `PENDING_REVIEW`.

### 2.5. `M-SL-08: Seller Wallet Ledger Screen`
- Hiển thị thẻ số dư ví và tổng số tiền đang trong thời gian giữ ký quỹ Escrow.
- Danh sách lịch sử biến động số dư (`wallet_transactions`):
  - Giao dịch cộng tiền bán hàng (`CREDIT`) kèm mã đơn hàng, ngày giờ, số tiền cộng.
  - Giao dịch rút tiền (`DEBIT` - nếu có).
  - Không cho phép sửa đổi hoặc xóa giao dịch (`Append-Only Ledger`).

---

## 3. Architecture & State Management (MVVM Pattern)
- **Models:** `SellerDashboardModel`, `SellerProductItemModel`, `WalletTransactionModel`.
- **Repositories:** `SellerProductRepository`, `SellerWalletRepository`.
- **ViewModels (`ChangeNotifier`):**
  - `SellerHubViewModel`: Nạp số liệu tổng quan ví và bộ đếm việc cần làm.
  - `SellerListingsViewModel`: Quản lý danh sách sản phẩm theo 7 tab trạng thái, chuyển đổi trạng thái ẩn/hiện.
  - `CreateProductViewModel`: Quản lý form đăng bán, validation, tải ảnh lên.
  - `SellerWalletViewModel`: Nạp lịch sử giao dịch ví và đối soát Escrow.

---

## 4. API Endpoints Utilized
- `GET /api/v1/seller/dashboard`
- `GET /api/v1/seller/products`
- `POST /api/v1/seller/products`
- `PUT /api/v1/seller/products/{id}` (hoặc POST multipart kèm `_method: PUT`)
- `PATCH /api/v1/seller/products/{id}/status`
- `POST /api/v1/seller/products/{id}/relist`
- `GET /api/v1/seller/wallet`

---

## 5. Acceptance Criteria (`Tiêu Chí Nghiệm Thu P7-07`)
- [x] **AC-P707-01:** Bảng điều khiển Seller Hub hiển thị chính xác số dư ví và số tiền Escrow đang giữ.
- [x] **AC-P707-02:** Quản lý sản phẩm phân chia và lọc đúng theo 7 trạng thái độc lập.
- [x] **AC-P707-03:** Form tạo bài đăng bắt buộc nhập `defect_info` theo `BR-PR-03`, tự động khóa số lượng = 1 cho Đấu giá (`BR-PR-01`).
- [x] **AC-P707-04:** Màn hình duyệt lại `M-SL-04` hiển thị đúng lý do từ chối của Moderator và xóa lý do cũ sau khi gửi duyệt lại (`DEC-05`).
- [x] **AC-P707-05:** Viết đầy đủ Unit & Widget tests cho ViewModels và 5 màn hình trong `test/features/seller_channel_test.dart` đạt **100% PASS** (12/12 tests passed, toàn bộ Flutter 76/76 tests passed).
