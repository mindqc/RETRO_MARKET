# P7-09: ORDER MANAGEMENT, 100% ESCROW RELEASE, FULFILLMENT & DISPUTES SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P709-ORDER-FULFILLMENT-DISPUTES`
- **Version:** `1.0.0`
- **Status:** `DONE / PO APPROVED`
- **Phase:** `Phase 07 – Task P7-09`
- **Dependencies:** `P7-01, P7-02, P7-03, P7-04, P7-07, P7-08 Completed`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
Hiện thực hóa toàn bộ vòng đời sau mua bán cho cả hai vai Người mua (`Buyer Purchases`) và Người bán (`Seller Fulfillment`). Xây dựng luồng hủy đơn 3 cấp (`DEC-06`), xác nhận nhận hàng giải ngân 100% tiền hàng vào Ví Seller (`DEC-04`), dòng thời gian vận đơn, và quy trình mở/xử lý khiếu nại trả hàng đóng băng quỹ Escrow (`DEC-03`, `BR-DP-02`). Gói này bao gồm đúng **10 màn hình Mobile**:
- `M-OR-02`: Danh sách Đơn mua của tôi (`My Purchases`)
- `M-OR-03`: Chi tiết Đơn mua (`Purchase Order Detail`)
- `M-OR-04`: Hộp thoại Hủy đơn 3 Cấp & Rút lại yêu cầu hủy (`3-Tier Order Cancellation Dialog`)
- `M-OR-05`: Dòng thời gian Vận đơn & Sổ cái Escrow (`Shipment Tracking & Escrow Timeline`)
- `M-SL-05`: Danh sách Đơn bán của Tiệm (`Seller Orders`)
- `M-SL-06`: Chi tiết Đơn bán cho Chủ tiệm (`Seller Order Detail`)
- `M-SL-07`: Biểu mẫu Giao hàng cho Vận chuyển (`Ship Order Form`)
- `M-DP-01`: Biểu mẫu Mở Khiếu nại Trả hàng / Hoàn tiền (`Open Dispute Form`)
- `M-DP-02`: Chi tiết Hồ sơ Khiếu nại & Bằng chứng 2 Chiều (`Dispute Case Detail`)
- `M-DP-03`: Biểu mẫu Nộp Bổ sung Bằng chứng / Giải trình Người bán (`Submit Counter-Evidence`)

---

## 2. Screen Specifications & UX Flows (`Đặc Tả Chi Tiết 10 Màn Hình`)

### 2.1. Buyer Order Flow (`M-OR-02` $\rightarrow$ `M-OR-05`)
1. **`M-OR-02: My Purchases Screen`:**
   - Thanh Tab trạng thái: `TẤT CẢ`, `CHỜ THANH TOÁN`, `ĐÃ THANH TOÁN`, `ĐANG CHUẨN BỊ`, `ĐANG GIAO`, `ĐÃ GIAO`, `HOÀN THÀNH`, `ĐÃ HỦY`, `KHIẾU NẠI`.
   - Danh sách đơn hàng dạng thẻ: Tên tiệm, Snapshot ảnh và tiêu đề món hàng, Tổng tiền thanh toán, Nút hành động nhanh tùy trạng thái (`Thanh toán ngay`, `Theo dõi đơn`, `Đã nhận được hàng`, `Đánh giá`).
2. **`M-OR-03: Purchase Order Detail Screen`:**
   - **4 Máy Trạng Thái Độc Lập:** Hiển thị rõ ràng 4 trạng thái:
     - Trạng thái đơn (`order_status`), Trạng thái thanh toán (`payment_status`), Trạng thái tiền ký quỹ (`escrow_status`), và Trạng thái khiếu nại (`dispute_status`).
   - Khối Snapshot đơn hàng: Thông tin sản phẩm và địa chỉ nhận hàng tại thời điểm đặt (không bị ảnh hưởng khi người bán sửa bài đăng).
   - Dòng thời gian đếm ngược tự động hoàn thành: Hiển thị thời điểm tự động xác nhận `auto_complete_at` (24h sau khi giao hàng).
   - **Các Nút Hành Động Nghiệp Vụ:**
     - Nút **`[Đã nhận được hàng & Hài lòng]`**:
       - Bật popup cảnh báo: *"Sau khi xác nhận, toàn bộ 100% tiền hàng sẽ được giải ngân vào Ví Người bán và bạn không thể mở khiếu nại nữa."*
       - Gọi `POST /api/v1/orders/{id}/confirm-delivery`. Đơn chuyển `COMPLETED`, tiền Escrow `RELEASED`.
     - Nút **`[Yêu cầu Trả hàng / Khiếu nại]`**: Mở `M-DP-01` (chỉ bật khi đơn ở `SHIPPED` hoặc `DELIVERED` và chưa có khiếu nại mở `DEC-03`).
     - Nút **`[Hủy đơn hàng]`**: Mở `M-OR-04`.
     - Nút **`[Viết đánh giá ⭐]`**: Mở `M-RV-01` (chỉ bật khi đơn đã `COMPLETED`).
3. **`M-OR-04: 3-Tier Order Cancellation Dialog` (`DEC-06` / `DEC-07`):**
   - **Cấp 1 (Tại `PENDING_PAYMENT`):** Hủy ngay lập tức không cần người bán duyệt, giải phóng tồn kho.
   - **Cấp 2 (Tại `PAID`):** Hủy tự động, hoàn tiền 100% (`FULL_REFUND`) lại cho người mua, trừ tiền ký quỹ giữ lại của seller.
   - **Cấp 3 (Tại `PREPARING`):** Người mua bắt buộc nhập lý do xin hủy (`cancel_reason`). Đơn được đánh dấu `cancellation_requested = true`.
   - Nút **`[Rút lại yêu cầu xin hủy]`**: Cho phép người mua thu hồi yêu cầu nếu đổi ý (`POST /api/v1/orders/{id}/withdraw-cancel-request`).
4. **`M-OR-05: Shipment Tracking Timeline`:**
   - Dòng thời gian hành trình đơn hàng: `Đặt hàng thành công` $\rightarrow$ `Đã thanh toán giữ tiền Escrow` $\rightarrow$ `Tiệm đang đóng gói` $\rightarrow$ `Đã giao cho đơn vị vận chuyển` (kèm mã vận đơn và tên hãng) $\rightarrow$ `Đã giao đến người mua`.

### 2.2. Seller Fulfillment Flow (`M-SL-05` $\rightarrow$ `M-SL-07`)
5. **`M-SL-05: Seller Orders Screen`:**
   - Danh sách các đơn bán của tiệm, hỗ trợ lọc theo các đơn cần xử lý gấp (`PAID` cần đóng gói, `PREPARING` cần gửi hàng, có yêu cầu hủy đơn cần phản hồi).
6. **`M-SL-06: Seller Order Detail Screen`:**
   - Thông tin người mua và địa chỉ giao hàng.
   - **Xử lý yêu cầu xin hủy (`DEC-06`):** Nếu có `cancellation_requested == true`, hiển thị hộp cảnh báo màu cam kèm lý do người mua đưa ra và 2 nút:
     - `[Đồng ý hủy & Hoàn tiền]` (`action: 'APPROVE'`).
     - `[Từ chối hủy (Tiếp tục gửi hàng)]` (`action: 'REJECT'` kèm lý do từ chối).
   - Nút **`[Bắt đầu chuẩn bị hàng]`**: Chuyển đơn từ `PAID` sang `PREPARING` (`POST /api/v1/seller/orders/{id}/prepare`).
   - Nút **`[Gửi hàng cho vận chuyển]`**: Mở `M-SL-07`.
   - Nút **`[Xác nhận đã giao hàng]`**: Chuyển đơn sang `DELIVERED`, bắt đầu kích hoạt đồng hồ đếm ngược tự động giải ngân (`POST /api/v1/seller/orders/{id}/deliver`).
7. **`M-SL-07: Ship Order Form Modal`:**
   - Chọn đơn vị vận chuyển (`carrier_name` ví dụ: Giao Hàng Nhanh, Viettel Post, Giao Hàng Tiết Kiệm, Tự vận chuyển).
   - Nhập mã vận đơn (`tracking_code`).
   - Gọi `POST /api/v1/seller/orders/{id}/ship`.

### 2.3. Dispute Resolution Flow (`M-DP-01` $\rightarrow$ `M-DP-03`)
8. **`M-DP-01: Open Dispute Form Screen` (`DEC-03` / `BR-DP-02`):**
   - Chọn danh mục lý do (`reason_category`): Hàng không đúng mô tả, Hàng giả/nhái, Hàng hư hỏng trong quá trình vận chuyển, Chưa nhận được hàng.
   - Nhập mô tả chi tiết khuyết điểm (`description` tối thiểu 10 ký tự).
   - Tải lên tối đa 5 hình ảnh hoặc video bằng chứng rõ nét (`image_picker`).
   - Cảnh báo: *"Khi mở khiếu nại, tiền thanh toán sẽ được khóa cứng tại quỹ Escrow cho đến khi hai bên hòa giải hoặc Quản trị viên phân xử."*
   - Gọi `POST /api/v1/orders/{id}/disputes`.
9. **`M-DP-02: Dispute Case Detail Screen`:**
   - Hiển thị tiến trình xử lý khiếu nại (`OPEN` $\rightarrow$ `NEED_MORE_INFO` $\rightarrow$ `RESOLVED`).
   - Dòng thời gian đối chất 2 chiều:
     - Bằng chứng và mô tả ban đầu của Người mua (`BUYER_PROOF`).
     - Lời giải trình và bằng chứng đối ứng của Người bán (`SELLER_COUNTER_PROOF`).
     - Ghi chú yêu cầu bổ sung từ Chuyên viên Hỗ trợ (`STAFF_REQUEST_NOTE`).
   - Phán quyết tài chính cuối cùng từ Admin (`DEC-07` / `BR-FN-06`): Hoàn tiền 100% cho người mua, hoặc Giải ngân cho người bán, hoặc Hoàn tiền một phần.
10. **`M-DP-03: Submit Counter-Evidence Form Screen`:**
    - Biểu mẫu cho phép Người bán nộp tài liệu giải trình đối chứng (`message_note`) và tải file đính kèm (`file`). Gọi `POST /api/v1/disputes/{id}/evidences`.

---

## 3. Architecture & State Management (MVVM Pattern)
- **Models:** `OrderModel`, `OrderItemModel`, `ShipmentModel`, `DisputeModel`, `DisputeEvidenceModel`.
- **Repositories:** `BuyerOrderRepository`, `SellerOrderRepository`, `DisputeRepository`.
- **ViewModels (`ChangeNotifier`):**
  - `BuyerOrderViewModel`: Quản lý danh sách đơn mua, hủy đơn 3 cấp, xác nhận nhận hàng giải ngân.
  - `SellerOrderViewModel`: Quản lý danh sách đơn bán, phản hồi yêu cầu hủy, cập nhật chuẩn bị/giao hàng.
  - `DisputeViewModel`: Quản lý mở khiếu nại, nạp tiến trình đối chất và nộp bằng chứng bổ sung.

---

## 4. API Endpoints Utilized
- `GET /api/v1/orders/purchases`
- `GET /api/v1/orders/{id}`
- `POST /api/v1/orders/{id}/cancel`
- `POST /api/v1/orders/{id}/withdraw-cancel-request`
- `POST /api/v1/orders/{id}/confirm-delivery`
- `GET /api/v1/seller/orders`
- `POST /api/v1/seller/orders/{id}/prepare`
- `POST /api/v1/seller/orders/{id}/ship`
- `POST /api/v1/seller/orders/{id}/deliver`
- `POST /api/v1/seller/orders/{id}/respond-cancel`
- `GET /api/v1/disputes`
- `GET /api/v1/disputes/{id}`
- `POST /api/v1/orders/{id}/disputes`
- `POST /api/v1/disputes/{id}/evidences`

---

## 5. Acceptance Criteria (`Tiêu Chí Nghiệm Thu P7-09`)
- [x] **AC-P709-01:** Luồng hủy đơn 3 cấp (`DEC-06`) hoạt động chuẩn xác trên từng trạng thái đơn hàng.
- [x] **AC-P709-02:** Nút xác nhận nhận hàng gọi giải ngân 100% tiền hàng vào Ví Seller theo `DEC-04`.
- [x] **AC-P709-03:** Mở khiếu nại thành công lập tức đóng băng Escrow và hiển thị dòng thời gian đối chất 2 chiều.
- [x] **AC-P709-04:** Người bán thực hiện trọn vẹn pipeline vận hành đơn hàng: Chuẩn bị $\rightarrow$ Gửi hàng $\rightarrow$ Giao hàng.
- [x] **AC-P709-05:** Viết đầy đủ Unit & Widget tests cho ViewModels và 10 màn hình trong `test/features/orders_and_disputes_test.dart` đạt **100% PASS** (15/15 tests PASS, 101/101 all mobile tests PASS).
