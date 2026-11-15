# P6-06: ORDER FULFILLMENT, ESCROW RELEASE, SELLER WALLET LEDGER & DISPUTE RESOLUTION SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P606-ESCROW-SHIPPING-DISPUTE`
- **Version:** `1.0.0`
- **Status:** DONE / APPROVED
- **Phase:** `Phase 06 – Task P6-06`
- **Dependencies:** `P6-05 (Cart, Order & Payment Services)`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
- **Mục tiêu:** Hiện thực hóa luồng giao vận của Người bán (`PAID` $\rightarrow$ `PREPARING` $\rightarrow$ `SHIPPED` $\rightarrow$ `DELIVERED` kèm đóng băng mốc `auto_complete_at` theo `BR-OR-05`), Giải ngân tiền hàng **100% `item_subtotal`** vào Ví Người bán (`EscrowReleaseService` – `DEC-04`, `BR-FN-04`), Sổ cái Ví Read-Only (`M-SL-08`), và toàn bộ luồng Khiếu nại & Phân xử 3 phán quyết tài chính (`DisputeService` – `DEC-03`, `DEC-07`, `BR-FN-06`, `BR-DP-02`).
- **Phạm vi:** `OrderFulfillmentService`, `EscrowReleaseService`, `DisputeService` và các API `/api/v1/seller/orders/*`, `/api/v1/orders/{id}/confirm-delivery`, `/api/v1/seller/wallet`, `/api/v1/disputes/*`.

## 2. Source Documents (`Tài Liệu Nguồn`)
- `ORDER_PAYMENT_FLOW.md` (`OF-04..10`), `SELLER_FLOW.md` (`SF-09..12`), `06_BUSINESS_RULES.md` (`BR-OR-05`, `BR-FN-04..07`, `BR-DP-01..02`), `08_ASSUMPTIONS_AND_DECISIONS.md` (`DEC-03`, `DEC-04`, `DEC-07`).
- Models: `Order`, `Shipment`, `EscrowTransaction`, `WalletTransaction`, `SellerProfile`, `Dispute`, `DisputeEvidence`, `AuditLog`.

## 3. Technical Design & Domain Services (`Thiết Kế Kỹ Thuật & Dịch Vụ Nghiệp Vụ`)
1. **`App\Services\Order\OrderFulfillmentService`:**
   - `markPreparing(User $seller, Order $order): Order`: Chuyển `PAID` $\rightarrow$ `PREPARING`, gán `preparing_at = now()`.
   - `shipOrder(User $seller, Order $order, array $shipmentData): Order`: Kiểm tra `order_status === 'PREPARING'` (nếu đang có `cancellation_requested === true`, buộc Seller phải phản hồi yêu cầu hủy trước hoặc tự động từ chối yêu cầu hủy khi nhập mã vận đơn). Tạo bản ghi `shipments` (`carrier_name`, `tracking_code`, `shipping_note`), chuyển `order_status = 'SHIPPED'`, `shipped_at = now()`.
   - `markDelivered(User $seller, Order $order): Order`: Chuyển `SHIPPED` $\rightarrow$ `DELIVERED`, cập nhật `shipments.status = 'DELIVERED'`, `delivered_at = now()`.
     - **Đóng băng mốc tự động hoàn tất (`BR-OR-05`, `ADR-05`):** Tính cố định 1 lần duy nhất `orders.auto_complete_at = now()->addSeconds($platformConfigService->orderAutoCompleteDurationSeconds())` (`+24 giờ` ở Production / `+2 phút` ở Demo Mode).
2. **`App\Services\Escrow\EscrowReleaseService`:**
   - `confirmDeliveryByBuyer(User $buyer, Order $order): Order` & `autoReleaseOrder(Order $order, ?User $triggeredBy = null): Order`:
     - Thực thi nguyên tử và lũy đẳng trong `DB::transaction()` với `lockForUpdate()` trên `Order` và `SellerProfile`.
     - **Chốt chặn an toàn (`BR-DP-02`):** Nếu `order->dispute_status !== 'NONE'` hoặc `order->escrow_frozen_at !== null`, ném `InvalidStateTransitionException` (`409` — Cấm tuyệt đối giải ngân đơn đang có khiếu nại).
     - **Kiểm tra lũy đẳng (`BR-FN-07`):** Nếu `order->escrow_status === 'RELEASED'` hoặc đã tồn tại `WalletTransaction::where('order_id', $order->id)->exists()`, thoát ngay lập tức.
     - Cập nhật `orders`: `order_status = 'COMPLETED'`, `escrow_status = 'RELEASED'`, `completed_at = now()`.
     - Ghi bút toán **`RELEASE`** vào `escrow_transactions`: `gross_amount = total_amount`, `seller_released_amount = item_subtotal` (**100% tiền hàng** – `DEC-04`), `buyer_refunded_amount = 0.00`, `platform_fee_retained = buyer_protection_fee`.
     - Ghi bút toán **`CREDIT`** vào `wallet_transactions`: `amount = item_subtotal`, `balance_before = sellerProfile->wallet_balance`, `balance_after = balance_before + item_subtotal`.
     - Cập nhật `SellerProfile`: `wallet_balance += item_subtotal`, `escrow_held_balance = max(0, escrow_held_balance - item_subtotal)`, `completed_orders_count += 1`.
3. **`App\Services\Escrow\DisputeService`:**
   - `openDispute(User $buyer, Order $order, array $data, array $files): Dispute`:
     - **Điều kiện mở khiếu nại (`DEC-03`, `BR-DP-01`):** Chỉ cho phép khi `order_status IN ('SHIPPED', 'DELIVERED')` và `dispute_status === 'NONE'`.
     - Khóa dòng `Order`, tạo bản ghi `disputes` (`opened_at_order_status = $order->order_status`, `status = 'OPEN'`), lưu bằng chứng `dispute_evidences` (`BUYER_PROOF`), cập nhật `orders.dispute_status = 'OPEN'` và **`orders.escrow_frozen_at = now()`** (khóa cứng tiến trình tự động giải ngân `BR-DP-02`).
   - `submitEvidenceOrResponse(User $actor, Dispute $dispute, ?string $note, ?UploadedFile $file): DisputeEvidence`: Cho phép Buyer gửi thêm bằng chứng, Seller gửi giải trình đối chứng (`SF-11`, cập nhật `disputes.seller_response`) hoặc Support Staff yêu cầu bổ sung thông tin (`status = 'NEED_MORE_INFO'` – `PERM-CM-08`).
   - `resolveDisputeByAdmin(User $admin, Dispute $dispute, string $verdict, ?float $partialRefundToBuyer, string $resolutionNote): Dispute`:
     - **Phân quyền cứng (`PERM-CM-09`):** Chỉ `admin` mới được thực thi (Moderator/Support gọi vào sẽ bị chặn bởi `DisputePolicy::resolve` với `403 ROLE_PERMISSION_DENIED`).
     - Xử lý 3 phán quyết tài chính trong `DB::transaction()` + `lockForUpdate()`:
       1. `APPROVE_BUYER_REFUND` (`DEC-07`): Cập nhật `orders` (`order_status = 'REFUNDED'`, `payment_status = 'REFUNDED'`, `escrow_status = 'REFUNDED'`, `dispute_status = 'RESOLVED'`), ghi bút toán **`FULL_REFUND`** hoàn trả **100% `total_amount`** cho Buyer, trừ `escrow_held_balance` và tăng `dispute_lost_count` của Seller.
       2. `RELEASE_TO_SELLER` (`DEC-04`): Bác bỏ khiếu nại, gỡ khóa `escrow_frozen_at = null`, cập nhật `dispute_status = 'RESOLVED'` và gọi `EscrowReleaseService` giải ngân **100% `item_subtotal`** vào Ví Seller.
       3. `PARTIAL_REFUND` (`BR-FN-06`): Kiểm tra `0 < $partialRefundToBuyer < $order->item_subtotal`. Hoàn cho Buyer `$partialRefundToBuyer`, giải ngân phần còn lại (`$sellerReleased = $order->item_subtotal - $partialRefundToBuyer`) vào `wallet_transactions` & `SellerProfile::wallet_balance`, nền tảng giữ `buyer_protection_fee`, ghi bút toán `PARTIAL_REFUND` vào `escrow_transactions`.

## 4. Files to Create or Modify (`File Mã Nguồn Dự Kiến`)
- `backend/app/Services/Order/OrderFulfillmentService.php`
- `backend/app/Services/Escrow/EscrowReleaseService.php`
- `backend/app/Services/Escrow/DisputeService.php`
- `backend/app/Http/Controllers/Api/V1/SellerOrderController.php`, `SellerWalletController.php`, `DisputeController.php`
- `backend/app/Http/Requests/Api/V1/Order/ShipOrderRequest.php`, `OpenDisputeRequest.php`, `SubmitDisputeEvidenceRequest.php`
- `backend/app/Http/Resources/Api/V1/DisputeResource.php`, `WalletSummaryResource.php`
- `backend/tests/Feature/Api/V1/EscrowShippingAndDisputeTest.php`

## 5. API Endpoints (`Danh Sách Endpoints`)
- `GET /api/v1/seller/orders`, `POST /api/v1/seller/orders/{id}/prepare`, `POST /api/v1/seller/orders/{id}/ship`, `POST /api/v1/seller/orders/{id}/deliver`
- `POST /api/v1/orders/{id}/confirm-delivery`
- `GET /api/v1/seller/wallet`
- `POST /api/v1/orders/{id}/disputes`, `GET /api/v1/disputes`, `GET /api/v1/disputes/{id}`, `POST /api/v1/disputes/{id}/evidences`

## 6. Business Rules, Validation & Authorization
- **Business Rules:** `BR-OR-05` (Đóng băng `auto_complete_at`), `BR-FN-04..07` (Cân bằng sổ cái Escrow & Ví), `DEC-03` (Mở khiếu nại ở `SHIPPED` & `DELIVERED`), `DEC-04` (Seller nhận 100% tiền hàng), `DEC-07` (Buyer thắng khiếu nại nhận lại 100% `total_amount`), `PERM-CM-08..09`.

## 7. Test Cases & Acceptance Criteria (`Tiêu Chí Nghiệm Thu`)
1. `test_seller_fulfillment_pipeline_freezes_auto_complete_at_timestamp_on_delivery`
2. `test_buyer_confirm_delivery_releases_100_percent_item_subtotal_to_seller_wallet_idempotently`
3. `test_opening_dispute_at_shipped_or_delivered_freezes_escrow_and_blocks_confirm_delivery`
4. `test_support_staff_can_request_more_info_but_cannot_execute_financial_verdict_403`
5. `test_admin_verdict_approve_buyer_refund_returns_100_percent_total_amount`
6. `test_admin_verdict_partial_refund_splits_item_subtotal_and_credits_seller_wallet_accurately`
- **Acceptance Criteria:** 100% bài test trong `EscrowShippingAndDisputeTest.php` đạt `PASS`.

## 8. Risks & Mitigation
- **Rủi ro:** Lệch số dư giữa `seller_profiles.wallet_balance` và tổng `wallet_transactions`.
- **Giảm thiểu:** Mọi bài test trong `EscrowShippingAndDisputeTest` đều gọi kiểm toán đối soát sổ cái sau mỗi phán quyết.

## 9. Implementation & Automated Test Verification (Kết Quả Thực Thi)
- **Status:** DONE / APPROVED
- **Domain Services Implemented:**
  1. App\Services\Order\OrderFulfillmentService: listSellerOrders, markPreparing, shipOrder, markDelivered (freezes uto_complete_at per BR-OR-05).
  2. App\Services\Escrow\EscrowReleaseService: confirmDeliveryByBuyer, 
eleaseOrderEscrowToSeller (releases 100% item_subtotal per DEC-04, idempotent per BR-FN-07), getSellerWalletSummary.
  3. App\Services\Escrow\DisputeService: openDispute (freezes escrow per BR-DP-02 / DEC-03), submitEvidenceOrResponse (SF-11 / PERM-CM-08), 
esolveDisputeByAdmin (3 verdicts: APPROVE_BUYER_REFUND 100% per DEC-07, RELEASE_TO_SELLER per DEC-04, PARTIAL_REFUND per BR-FN-06 with PERM-CM-09 admin-only guard).
- **FormRequests & Resources Created:** ShipOrderRequest, OpenDisputeRequest, SubmitDisputeEvidenceRequest, ShipmentResource, WalletTransactionResource, DisputeEvidenceResource, DisputeResource.
- **Controllers & Endpoints:** SellerOrderController, SellerWalletController, DisputeController, BuyerOrderController::confirmDelivery. 10 routes registered in pi.php.
- **Automated Verification:**
  - EscrowShippingAndDisputeTest.php: **8/8 tests PASS** (78 assertions).
  - Full PHPUnit Test Suite: **62/62 tests PASS** (775 assertions, 0 errors, 0 failures).
  - Seeders Reconciliation (db:verify-seeders): **100% integrity, ZERO ledger drift**.
