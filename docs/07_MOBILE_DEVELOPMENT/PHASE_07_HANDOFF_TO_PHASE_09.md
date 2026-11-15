# RETRO MARKET (izithrift) – PHASE 07 TO PHASE 09 INTEGRATION CONSIDERATIONS & HANDOFF DOCUMENT

- **Document ID:** `DOC-P7-TO-P9-HANDOFF`
- **Source Phase:** `Phase 07 – Flutter Mobile Application Development`
- **Target Phase:** `Phase 09 – Transaction Lifecycle, Escrow Ledger, Shipping & Auto-Complete Integration`
- **Auditor & Author:** Technical Lead & Repository Auditor
- **Date:** `2026-11-15`
- **Status:** `INTEGRATION ARCHITECTURE PREPARED`

---

## 1. Executive Summary & Objective

Theo lộ trình phát triển tổng thể (`MASTER_TASK_TRACKER.md`), **Phase 09** tập trung vào việc hoàn thiện và tích hợp sâu chu trình giao dịch toàn tuyến (**Transaction Lifecycle, Order Snapshot, QR Mock Payment, Escrow Ledger Reconciliation, Shipping Carrier Tracking & Auto-Complete Background Automation**).

Tài liệu này tổng hợp toàn bộ các điểm kết nối kỹ thuật (**Integration Touchpoints**), các cơ chế kiểm soát đồng bộ thời gian thực và các ràng buộc toàn vẹn dữ liệu từ ứng dụng di động Flutter (Phase 07) để chuẩn bị cho quá trình tích hợp sâu trong Phase 09.

---

## 2. Mobile Client Readiness for Phase 09 Scope

Toàn bộ **15 màn hình Mobile** thuộc phạm vi Giỏ hàng, Thanh toán, Vận hành Đơn hàng, Ký quỹ Escrow và Tranh chấp đã được xây dựng và kiểm thử hoàn chỉnh tại Phase 07:

1. **Giỏ hàng & Đặt hàng (`P7-08`):**
   - `M-CR-01` (`shopping_cart_screen.dart`): Giỏ hàng nhóm theo Người Bán (`BR-OR-01`), ràng buộc chỉ đặt mua đồ của 1 người bán trong 1 lần checkout.
   - `M-OR-01` (`checkout_screen.dart`): Bảng kê chi phí minh bạch phương trình `DEC-04`.
2. **Thanh toán QR Escrow (`P7-08`):**
   - `M-PM-01` (`mock_qr_payment_screen.dart`): Hiển thị VietQR, đồng hồ đếm ngược 30 phút.
   - `M-PM-02` (`payment_success_screen.dart`): Xác nhận tiền đã vào tài khoản Ký quỹ Escrow an toàn.
   - `M-PM-03` (`payment_failure_screen.dart`): Xử lý khi quá hạn thanh toán hoặc thất bại.
3. **Quản lý Đơn hàng Người Mua (`P7-09`):**
   - `M-OR-02` (`my_purchases_screen.dart`): 9 tab trạng thái đơn mua.
   - `M-OR-03` (`purchase_order_detail_screen.dart`): Hiển thị 4 máy trạng thái độc lập, snapshot sản phẩm bất biến tại thời điểm mua, nút `Đã nhận được hàng & Hài lòng` giải ngân 100% cho người bán.
   - `M-OR-04` (`order_cancellation_dialog.dart`): Hủy đơn 3 cấp (`DEC-06` / `DEC-07`).
   - `M-OR-05` (`shipment_tracking_screen.dart`): Dòng thời gian giao nhận vận đơn.
4. **Vận hành Đơn hàng Người Bán (`P7-09`):**
   - `M-SL-05` (`seller_orders_screen.dart`): Danh sách đơn bán cần xử lý.
   - `M-SL-06` (`seller_order_detail_screen.dart`): Chi tiết đơn bán, phản hồi yêu cầu hủy Tier 2.
   - `M-SL-07` (`ship_order_form_modal.dart`): Nhập hãng vận chuyển và mã vận đơn.
5. **Tranh chấp & Đóng băng Escrow (`P7-09`):**
   - `M-DP-01` (`open_dispute_form_screen.dart`): Form mở khiếu nại (đóng băng Escrow `DEC-03`).
   - `M-DP-02` (`dispute_case_detail_screen.dart`): Chi tiết tranh chấp, dòng thời gian bằng chứng 2 bên.
   - `M-DP-03` (`submit_counter_evidence_screen.dart`): Bổ sung bằng chứng phản hồi.

---

## 3. Critical Integration Touchpoints for Phase 09

### A. Đồng Bộ Thời Gian Thực & Đồng Hồ Đếm Ngược (`Real-Time Clock Sync`)
- **Vấn đề:** Thiết bị của người dùng có thể bị lệch múi giờ hoặc sai giờ hệ thống, dẫn đến việc tính toán thời gian hết hạn thanh toán (30 phút) hoặc thời gian tự động hoàn tất đơn (24h/72h) bị sai lệch.
- **Giải pháp đã triển khai tại Phase 07:**
  - `ServerTimeService.instance`: Singleton lưu trữ độ trôi thời gian (`clockOffset = serverTime - deviceTime`).
  - `ServerClockSyncInterceptor`: Tự động trích xuất header `meta.server_time` trên mọi phản hồi HTTP từ Backend Laravel 13 để hiệu chỉnh `clockOffset`.
  - `ServerCountdownTimer`: Widget đếm ngược độc quyền dựa trên thời gian server thực tế, tự động kích hoạt callback `onExpired` khi hết giờ.
- **Yêu cầu đối với Phase 09:**
  - Mọi API liên quan đến đơn hàng và thanh toán (`/orders/*`, `/payments/*`) bắt buộc tiếp tục trả về `meta.server_time` chuẩn ISO-8601 UTC trong JSON Envelope.

### B. Kiểm Soát Bất Biến & Phương Trình Tài Chính (`DEC-04` & Ledger)
- **Phương trình khóa cứng:**
  $$\text{Total Amount} = \text{Item Subtotal} + \text{Shipping Fee} + \text{Buyer Protection Fee}$$
  Trong đó: $\text{Buyer Protection Fee} = \text{round}(\text{Item Subtotal} \times 6\% + 7.000\text{đ})$.
  Người bán nhận 100% tiền hàng ($\text{Seller Net} = \text{Item Subtotal}$).
- **Nguyên tắc Sổ cái Bất biến (`ADR-04`):**
  - Mọi giao dịch giữ tiền, giải ngân hoặc hoàn tiền đều được ghi nhận vào `escrow_transactions` và `wallet_transactions` bằng các bản ghi mới.
  - Tuyệt đối không thực hiện câu lệnh `UPDATE` hay `DELETE` trên số liệu tài chính đã phát sinh.

### C. Quy Tắc 3 Cấp Hủy Đơn Hàng (`DEC-06` / `DEC-07`)
1. **Tier 1 (Tự động & Ngay lập tức):** Khi đơn hàng ở trạng thái `PENDING_PAYMENT` hoặc `PAID` (người bán chưa chuẩn bị hàng), người mua bấm Hủy đơn $\rightarrow$ Hệ thống lập tức cập nhật `order_status = CANCELLED`, `payment_status = REFUNDED`, `escrow_status = REFUNDED` (nếu đã thanh toán) và hoàn trả 100% tiền qua Escrow Ledger.
2. **Tier 2 (Chờ phê duyệt):** Khi đơn hàng ở `PREPARING`, người mua gửi yêu cầu hủy $\rightarrow$ Cờ `cancellation_requested = true`. Người bán có quyền đồng ý (hủy & hoàn tiền) hoặc từ chối (tiếp tục đóng gói giao hàng). Người mua có quyền rút lại yêu cầu hủy (`withdraw-cancel-request`).
3. **Tier 3 (Khóa hủy đơn):** Khi đơn hàng đã chuyển sang `SHIPPED` hoặc `DELIVERED`, nút Hủy đơn bị khóa hoàn toàn. Nếu hàng lỗi/không đúng mô tả, người mua phải mở Khiếu nại Escrow (`M-DP-01`).

### D. Cơ Chế Đóng Băng Ký Quỹ Escrow Khi Khiếu Nại (`DEC-03`)
- Khi người mua gửi đơn khiếu nại (`POST /api/v1/orders/{id}/disputes`), backend phải thiết lập:
  - `orders.dispute_status = 'OPEN'`
  - `orders.escrow_frozen_at = now()`
- **Tác động:** Tiến trình nền tự động hoàn tất sau 24h (`EscrowReleaseService::autoCompleteDueDeliveredOrders`) phải bỏ qua các đơn hàng có `dispute_status <> 'NONE'` hoặc `escrow_frozen_at IS NOT NULL`. Tiền tiếp tục được giữ an toàn tại tài khoản Escrow cho đến khi Ban quản trị/Support phân xử xong trong Phase 08.

---

## 4. Concurrency & Locking Checklist for Phase 09

Trong Phase 09, khi triển khai các Background Jobs và mô phỏng webhook thanh toán, bắt buộc áp dụng:
1. `DB::transaction()` bao bọc toàn bộ chu trình giải ngân Escrow và cập nhật số dư ví người bán.
2. `lockForUpdate()` trên bản ghi `Order`, `Payment` và `SellerWallet` để ngăn chặn double-spending hoặc race conditions khi người mua bấm xác nhận nhận hàng đồng thời với job tự động giải ngân của hệ thống.
3. Partial unique index `uq_payments_one_paid_per_order` và unique index trên `wallet_transactions(order_id)` ngăn chặn hoàn toàn việc giải ngân lặp lại.

---

## 5. Handoff Readiness Conclusion

Hệ thống Mobile Flutter (Phase 07) đã được trang bị đầy đủ tầng giao diện, ViewModels, Repositories và xử lý ngoại lệ đồng bộ, sẵn sàng kết nối và kiểm thử toàn diện với Phase 09 ngay khi Phase 08 hoàn tất.
