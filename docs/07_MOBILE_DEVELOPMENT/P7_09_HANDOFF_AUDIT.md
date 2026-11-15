# P7-09 HANDOFF AUDIT REPORT: ORDER MANAGEMENT, ESCROW RELEASE, FULFILLMENT & DISPUTE RESOLUTION

- **Task Code:** `P7-09`
- **Specification:** `docs/07_MOBILE_DEVELOPMENT/P7_09_ORDER_FULFILLMENT_AND_DISPUTES.md`
- **Execution Date:** `2026-11-15`
- **Status:** `REVIEW` (Awaiting Product Owner Approval)
- **Branch/Workspace:** `RETRO_MARKET`

---

## 1. Executive Summary

Gói công việc `P7-09` đã hoàn thành toàn diện vòng đời sau mua bán (Order Lifecycle, 100% Escrow Release, Seller Fulfillment & Dispute Resolution) cho nền tảng Retro Market (izithrift) trên cả 2 vai Người mua và Người bán:
1. **Tuân thủ Tuyệt đối 4 Máy Trạng thái Độc lập:** `order_status`, `payment_status`, `escrow_status`, `dispute_status` được hiển thị và quản lý phân lập, không gộp trạng thái.
2. **Quy trình Hủy đơn 3 Cấp (`DEC-06` / `DEC-07`):**
   - Cấp 1 (`PENDING_PAYMENT`): Hủy tức thì, phục hồi tồn kho.
   - Cấp 2 (`PAID`): Hủy tự động, hoàn tiền 100% (`FULL_REFUND`) lại cho người mua.
   - Cấp 3 (`PREPARING`): Đánh dấu `cancellation_requested = true`, yêu cầu người bán duyệt (`APPROVE` / `REJECT`), hỗ trợ người mua rút lại yêu cầu hủy (`withdrawCancelRequest`).
3. **Giải ngân 100% Tiền hàng vào Ví Tiệm (`DEC-04`):**
   - Khi Người mua xác nhận nhận hàng (`confirmDeliveryAndReleaseEscrow`), toàn bộ `item_subtotal` được giải ngân ngay lập tức vào Ví Tiệm của Seller ($0\%$ khấu trừ hoa hồng).
4. **Quy trình Mở & Xử lý Khiếu nại (`DEC-03` / `BR-DP-02`):**
   - Khi mở khiếu nại, tiền ký quỹ lập tức bị đóng băng (`escrow_status: FROZEN`), đồng hồ `auto_complete_at` bị tạm dừng.
   - Ràng buộc: Mô tả lý do khiếu nại $\ge 10$ ký tự, đính kèm tối đa 5 ảnh/video bằng chứng.
   - Dòng đối chất 2 chiều: `BUYER_PROOF`, `SELLER_COUNTER_PROOF`, `STAFF_REQUEST_NOTE` cùng hiển thị phán quyết phân xử từ Admin.

---

## 2. Artifacts Created & Modified

### 2.1. Domain Models (`mobile/lib/features/orders/models/`)
| Model File | Responsibilities & Business Rules |
| :--- | :--- |
| `order_item_snapshot_model.dart` | Lưu trữ snapshot bất biến của sản phẩm tại thời điểm chốt đơn (`Order Snapshot Pattern`), bao gồm tiêu đề, mã SP, phân loại tình trạng (5 mức), thông tin khuyết điểm, đơn giá và ảnh đại diện. |
| `shipment_model.dart` | `ShipmentModel` và `ShipmentTimelineEventModel` quản lý đơn vị vận chuyển (GHN, GHTK, Viettel Post, J&T), mã vận đơn, ghi chú và các mốc thời gian hành trình bưu kiện. |
| `order_model.dart` | Mô hình đơn hàng đầy đủ quản trị 4 máy trạng thái, phương trình tài chính minh bạch `DEC-04`, địa chỉ nhận hàng snapshot, các cờ hủy đơn 3 cấp, thời gian đếm ngược `autoCompleteAt`, và phương thức tạo dòng thời gian `buildFullLifecycleTimeline()`. |
| `dispute_evidence_model.dart` | Mô hình chứng cứ đa vai trò (`BUYER_PROOF`, `SELLER_COUNTER_PROOF`, `STAFF_REQUEST_NOTE`) hỗ trợ ghi chú và tối đa 5 file đính kèm. |
| `dispute_model.dart` | Mô hình hồ sơ khiếu nại lưu trữ số tiền Escrow đóng băng, danh mục lý do, tiến trình xử lý (`OPEN`, `NEED_MORE_INFO`, `RESOLVED`), phán quyết của Admin (`FULL_REFUND_TO_BUYER`, `RELEASE_TO_SELLER`, `PARTIAL_REFUND`) và danh sách chứng cứ 2 chiều. |

### 2.2. Repository (`mobile/lib/features/orders/repositories/`)
- `order_fulfillment_repository.dart`: Repository thống nhất kế thừa `DioClient`, quản lý 14 API endpoints:
  - Buyer: `fetchMyPurchases`, `fetchOrderDetail`, `cancelOrder`, `withdrawCancelRequest`, `confirmDeliveryAndReleaseEscrow`.
  - Seller: `fetchSellerOrders`, `markOrderPreparing`, `shipOrder`, `markOrderDelivered`, `respondToCancelRequest`.
  - Disputes: `fetchDisputes`, `fetchDisputeDetail`, `openDispute`, `submitDisputeEvidence`.

### 2.3. ViewModels (`mobile/lib/features/orders/viewmodels/`)
- `buyer_order_view_model.dart`: Quản lý 9 tabs lọc đơn mua, chi tiết đơn mua, hủy đơn 3 cấp, rút yêu cầu hủy và giải ngân Escrow 100%.
- `seller_order_view_model.dart`: Quản lý 7 tabs đơn bán, tiếp nhận đơn (`PREPARING`), giao hàng (`SHIPPED`), giao thành công (`DELIVERED`), và xử lý yêu cầu xin hủy từ khách mua (`APPROVE` / `REJECT`).
- `dispute_view_model.dart`: Quản lý form mở khiếu nại (kiểm tra $\ge 10$ ký tự, $\le 5$ ảnh), tải chi tiết hồ sơ khiếu nại và nộp chứng cứ bổ sung.

### 2.4. Screens & Modals (`mobile/lib/features/orders/screens/`)
| Screen / Modal | Route | Purpose & Key Widgets |
| :--- | :--- | :--- |
| `my_purchases_screen.dart` (`M-OR-02`) | `/orders/purchases` | 9 tabs trạng thái, danh sách đơn mua dạng thẻ với snapshot hàng hóa, nút hành động ngữ cảnh (`Hủy`, `Thanh toán`, `Vận đơn`, `Đã nhận hàng`). |
| `purchase_order_detail_screen.dart` (`M-OR-03`) | `/orders/:id` | Thẻ 4 máy trạng thái độc lập, danh sách sản phẩm snapshot, địa chỉ giao snapshot, đồng hồ đếm ngược tự động hoàn tất `ServerCountdownTimer`, bảng giá minh bạch `PriceBreakdownCard` (`DEC-04`), nút `[Đã nhận được hàng & Hài lòng]` kích hoạt giải ngân 100% vào Ví Tiệm. |
| `order_cancellation_dialog.dart` (`M-OR-04`) | Modal Dialog | Hộp thoại hủy đơn thích ứng động theo 3 cấp (`DEC-06` / `DEC-07`): Cấp 1 hủy tức thì, Cấp 2 tự động hoàn 100%, Cấp 3 gửi yêu cầu chờ duyệt. |
| `shipment_tracking_screen.dart` (`M-OR-05`) | `/orders/:id/tracking` | Hiển thị hãng vận chuyển, mã vận đơn, cảnh báo bảo vệ tiền hàng Escrow, và dòng thời gian hành trình đơn hàng trực quan. |
| `seller_orders_screen.dart` (`M-SL-05`) | `/seller/orders` | 7 tabs tiến trình đơn bán của tiệm, cảnh báo đơn có khách xin hủy, nút hành động nhanh chuẩn bị hàng và giao hàng. |
| `seller_order_detail_screen.dart` (`M-SL-06`) | `/seller/orders/:id` | Chi tiết đơn bán, hộp quyết định xử lý yêu cầu xin hủy gấp (`APPROVE` hoàn tiền 100% / `REJECT` tiếp tục gửi kèm lý do), thông tin người mua, thanh điều hướng trạng thái đơn hàng. |
| `ship_order_form_modal.dart` (`M-SL-07`) | Modal Bottom Sheet | Biểu mẫu chọn đơn vị vận chuyển (GHN, GHTK, Viettel Post, J&T, Tự vận chuyển), nhập mã vận đơn và ghi chú giao hàng. |
| `open_dispute_screen.dart` (`M-DP-01`) | `/orders/:id/dispute/create` | Form mở khiếu nại với chọn danh mục lý do, nhập mô tả khuyết điểm ($\ge 10$ ký tự), tải tối đa 5 ảnh đính kèm, cảnh báo đóng băng Escrow. |
| `dispute_detail_screen.dart` (`M-DP-02`) | `/disputes/:id` | Chi tiết hồ sơ khiếu nại, banner tiền Escrow đóng băng, banner phán quyết phân xử từ Admin, luồng đối chất 2 chiều theo dòng thời gian. |
| `submit_counter_evidence_screen.dart` (`M-DP-03`) | `/disputes/:id/evidence` | Form nộp giải trình đối chứng và đính kèm bằng chứng ảnh/video của Người bán hoặc Người mua. |

### 2.5. Routing Integration
- `mobile/lib/core/router/app_routes.dart`: Khai báo hằng số đường dẫn và helper path generators cho toàn bộ 10 màn hình của P7-09.
- `mobile/lib/core/router/app_router.dart`: Đăng ký GoRoutes có type-safe parameters cho các tuyến đường `/orders/purchases`, `/orders/:id`, `/orders/:id/tracking`, `/seller/orders`, `/seller/orders/:id`, `/orders/:id/dispute/create`, `/disputes/:id`, `/disputes/:id/evidence`.

---

## 3. Quality Verification & Test Results

### 3.1. Mobile Static Code Analysis
```powers
flutter analyze
# Output: Analyzing mobile...
# No issues found! (ran in 1.3s)
```
- **0 errors, 0 warnings, 0 infos** trên toàn bộ dự án Flutter.

### 3.2. P7-09 Test Suite (`mobile/test/features/orders_and_disputes_test.dart`)
15/15 unit and widget tests **100% PASS**:
1. `OrderItemSnapshotModel` SafeJsonParser test
2. `OrderModel` 4 independent state machines and monetary fields test
3. `ShipmentModel` and timeline events test
4. `DisputeModel` and multi-role evidence parsing test
5. `MyPurchasesScreen` 9 status tabs and contextual action buttons test
6. `PurchaseOrderDetailScreen` 4 state machines card and `PriceBreakdownCard` test
7. `OrderCancellationDialog` 3-tier cancellation logic test
8. Escrow release (`DEC-04`) confirmation dialog test
9. `SellerOrdersScreen` 7 tabs and seller orders list test
10. `SellerOrderDetailScreen` urgent cancellation decision card test
11. `ShipOrderFormModal` carrier and tracking code validation test
12. `ShipmentTrackingScreen` carrier, tracking code, and timeline steps test
13. `OpenDisputeScreen` >= 10 chars validation and submission test
14. `DisputeDetailScreen` status banner, claims, and counter-evidence thread test
15. `SubmitCounterEvidenceScreen` submission and role handling test

### 3.3. Full Mobile Test Suite
```powers
flutter test
# Output: 00:05 +101: All tests passed!
```
- **101/101 tests PASS (100%)** trên toàn bộ 6 file test của Mobile app.

### 3.4. Full Backend Test Suite
```powers
php artisan test
# Output: Tests: 88 passed (1043 assertions), Duration: 13.71s
```
- **88/88 tests PASS (100%)** với 1043 assertions, đảm bảo không có bất kỳ xung đột hay hồi quy nào với Backend API Phase 06.

---

## 4. Master Task Tracker Status

| Task ID | Description | Location | Status |
| :--- | :--- | :--- | :--- |
| `P7-09` | Buyer/Seller Order Management (M-OR-02..05, M-SL-05..07) & Disputes (M-DP-01..03) | `mobile/lib/features/orders/` | **`REVIEW`** (Ready for PO Approval) |

> **Cam kết:** Giữ nguyên trạng thái `REVIEW`, TUYỆT ĐỐI KHÔNG tự ý chuyển sang `DONE` hoặc thực hiện `P7-10` trước khi có lệnh phê duyệt chính thức từ Product Owner.
