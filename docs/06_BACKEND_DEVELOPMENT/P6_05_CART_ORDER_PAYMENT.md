# P6-05: SHOPPING CART, CHECKOUT PREVIEW (BUYER PROTECTION FEE), MOCK QR PAYMENT & 3-TIER CANCELLATION SPECIFICATION – RETRO MARKET (izithrift)

- **Document ID:** `DOC-P605-CART-ORDER-PAYMENT`
- **Version:** `1.0.0`
- **Status:** DONE / APPROVED
- **Phase:** `Phase 06 – Task P6-05`
- **Dependencies:** `P6-01 (PlatformConfigService)`, `P6-03 (AddressBookService)`, `P6-04 (Products)`
- **Completed Date:** `2026-11-14`
- **Verification:** `8/8 tests PASS (100 assertions, zero drift)`

---

## 1. Objective & Scope (`Mục Tiêu & Phạm Vi`)
- **Mục tiêu:** Hiện thực hóa Giỏ hàng gom nhóm theo Tiệm (`M-CR-01`), Xem trước bảng kê chi phí có `Buyer Protection Fee` (`M-OR-01` – `DEC-04`), Đặt hàng khóa dòng chống bán lố (`OF-02` + `BR-OR-02` Snapshot), Thanh toán QR mô phỏng lũy đẳng giữ tiền vào `ESCROW_HELD` (`M-PM-01..02` – `BR-FN-03`), và Luồng Hủy đơn 3 cấp kèm Hoàn tiền 100% `total_amount` (`M-OR-04`, `M-SL-06` – `DEC-06`, `DEC-07`).
- **Phạm vi:** `CartService`, `CheckoutService`, `MockQrPaymentService`, `OrderCancellationService` và các API giỏ hàng, đặt hàng, thanh toán, hủy đơn.

## 2. Source Documents (`Tài Liệu Nguồn`)
- `ORDER_PAYMENT_FLOW.md` (`OF-01..05`, `OF-09`), `06_BUSINESS_RULES.md` (`BR-AC-02`, `BR-OR-01..04`, `BR-FN-01..03`, `BR-FN-07`), `08_ASSUMPTIONS_AND_DECISIONS.md` (`DEC-04`, `DEC-06`, `DEC-07`, `ADR-03`, `NFR-SEC-03`).
- Models: `Cart`, `CartItem`, `Product`, `Order`, `OrderItem`, `Payment`, `EscrowTransaction`, `SellerProfile`, `UserAddress`.

## 3. Technical Design & Domain Services (`Thiết Kế Kỹ Thuật & Dịch Vụ Nghiệp Vụ`)
1. **`App\Services\Order\CartService`:**
   - Quản lý `carts` và `cart_items` cho sản phẩm `FIXED_PRICE` đang `APPROVED` và `available_quantity >= quantity`.
   - **Chặn tự mua hàng (`BR-AC-02`):** Nếu `$product->seller_id === $buyer->id`, ném `SelfTransactionForbiddenException` (`403 SELF_TRANSACTION_FORBIDDEN`).
   - Trả về giỏ hàng gom nhóm theo từng `seller_id` (`seller_groups[]`) để UI `M-CR-01` hiển thị rõ ràng từng tiệm (`BR-OR-01`).
2. **`App\Services\Order\CheckoutService`:**
   - **Zero Client-Side Price Trust (`NFR-SEC-03`):** Chỉ nhận `source` (`CART` hoặc `BUY_NOW`), `product_id`/`quantity` (hoặc `seller_id` nếu thanh toán từng tiệm từ giỏ) và `address_id`.
   - `previewCheckout(User $buyer, array $payload): array`: Tính toán chi phí cho từng nhóm Seller qua `PlatformConfigService::calculateBuyerProtectionFee($itemSubtotal)`:
     - `shipping_fee = 0.00`
     - `buyer_protection_fee = ROUND(item_subtotal * rate) + fixed_fee`
     - `total_amount = item_subtotal + buyer_protection_fee`
     - `seller_net_amount = item_subtotal` (`DEC-04`).
   - `placeOrder(User $buyer, array $payload): array`: Thực thi trong `DB::transaction()`:
     - Khóa dòng sản phẩm bằng `Product::whereIn('id', $ids)->orderBy('id')->lockForUpdate()->get()` (`OF-02`).
     - Nếu `available_quantity < requested_qty` hoặc `status !== 'APPROVED'`, Rollback và ném `ProductOutOfStockException` (`409 PRODUCT_OUT_OF_STOCK`).
     - Trừ `available_quantity`; nếu `available_quantity === 0` thì chuyển `products.status = 'SOLD'`.
     - Chụp cứng `shipping_address_snapshot` (`JSONB`) từ `UserAddress` của Buyer và tạo bản ghi `orders` + `order_items` snapshot (`BR-OR-02`).
     - Tạo phiên thanh toán QR `payments` (`status = 'PENDING'`, `amount = order.total_amount`).
     - Xóa các món đã đặt khỏi `cart_items`.
3. **`App\Services\Escrow\MockQrPaymentService`:**
   - `simulateSuccess(User $buyer, int $paymentId): array`: Thực thi lũy đẳng trong `DB::transaction()`:
     - Khóa dòng `Payment` và `Order` (`lockForUpdate()`).
     - **Kiểm tra lũy đẳng (`BR-FN-03`):** Nếu `order->payment_status === 'PAID'` và `payment->status === 'PAID'`, trả về ngay trạng thái thành công hiện tại mà **không sinh bút toán `HOLD` thứ hai**.
     - Nếu đơn đã `CANCELLED` hoặc quá hạn `payment_expires_at`, ném `InvalidStateTransitionException` (`409`).
     - Cập nhật `payments.status = 'PAID'`, `paid_at = now()`; cập nhật `orders`: `order_status = 'PAID'`, `payment_status = 'PAID'`, `escrow_status = 'HELD'`, `paid_at = now()`.
     - Ghi bút toán bất biến `HOLD` vào `escrow_transactions` (`gross_amount = total_amount`, `item_subtotal_amount = item_subtotal`, `buyer_protection_fee_amount = buyer_protection_fee`, `seller_released_amount = 0`, `buyer_refunded_amount = 0`, `platform_fee_retained = 0`).
     - Khóa dòng `SellerProfile` và cộng `escrow_held_balance = escrow_held_balance + order.item_subtotal`.
   - `simulateFailure(User $buyer, int $paymentId, ?string $reason): Payment`: Đánh dấu phiên QR `FAILED` và tự động sinh phiên QR `PENDING` mới nếu đơn vẫn còn hạn `payment_expires_at`.
4. **`App\Services\Order\OrderCancellationService` (Luồng Hủy Đơn 3 Cấp `DEC-06` & Hoàn Tiền 100% `DEC-07`):**
   - `buyerCancelOrRequest(User $buyer, Order $order, string $reason): Order`: Khóa dòng `Order` (`lockForUpdate()`):
     - **Cấp 1 (`order_status === 'PENDING_PAYMENT'`):** Hủy đơn ngay (`order_status = 'CANCELLED'`, `payment_status = 'EXPIRED'`, `cancelled_by_role = 'BUYER'`), khôi phục `available_quantity` (nếu là đơn `FIXED_PRICE`; nếu là đơn `AUCTION` thì chuyển phiên sang `WINNER_DEFAULTED` theo `DEC-02`).
     - **Cấp 2 (`order_status === 'PAID'` – Seller chưa bấm chuẩn bị hàng):** Hủy đơn ngay (`order_status = 'CANCELLED'`, `payment_status = 'REFUNDED'`, `escrow_status = 'REFUNDED'`), ghi bút toán **`FULL_REFUND`** vào `escrow_transactions` hoàn trả **100% `total_amount` (`gross_amount`)** cho Buyer (`DEC-07`), trừ `seller_profiles.escrow_held_balance`, khôi phục tồn kho sản phẩm `FIXED_PRICE`.
     - **Cấp 3 (`order_status === 'PREPARING'`):** Đặt `cancellation_requested = true`, `cancellation_request_reason = $reason` chờ Seller phê duyệt.
     - **Từ `SHIPPED` trở đi:** Ném `InvalidStateTransitionException` (`409` – `BR-OR-04`).
   - `buyerWithdrawCancelRequest(User $buyer, Order $order): Order`: Cho phép Buyer rút lại yêu cầu xin hủy khi đang ở `PREPARING` (`UX-CHECK-02`).
   - `sellerRespondCancelRequest(User $seller, Order $order, string $decision, ?string $note): Order`:
     - Nếu `decision === 'APPROVE'`: Thực hiện hủy đơn và ghi bút toán **`FULL_REFUND` (hoàn 100% `total_amount`)** giống Cấp 2.
     - Nếu `decision === 'REJECT'`: Đặt `cancellation_requested = false` để Seller tiếp tục đóng gói giao hàng.

## 4. Files Created or Modified (`File Mã Nguồn Đã Thực Hiện`)
- `backend/app/Services/Order/CartService.php` (Get Grouped Cart, Add, Update, Remove)
- `backend/app/Services/Order/CheckoutService.php` (Preview Checkout, Place Order with FOR UPDATE lock, Snapshot)
- `backend/app/Services/Escrow/MockQrPaymentService.php` (Payment Session, Idempotent Simulate Success, Simulate Failure)
- `backend/app/Services/Order/OrderCancellationService.php` (3-tier Cancellation, Withdraw request, Seller respond with 100% refund)
- `backend/app/Http/Controllers/Api/V1/CartController.php` (Shopping Cart endpoints)
- `backend/app/Http/Controllers/Api/V1/CheckoutController.php` (Preview & Place order endpoints)
- `backend/app/Http/Controllers/Api/V1/PaymentController.php` (Mock QR payment endpoints)
- `backend/app/Http/Controllers/Api/V1/BuyerOrderController.php` (Buyer orders & cancellation endpoints)
- `backend/app/Http/Requests/Api/V1/Order/*` (`AddCartItemRequest`, `UpdateCartItemRequest`, `CheckoutPreviewRequest`, `PlaceOrderRequest`, `CancelOrderRequest`, `RespondCancelOrderRequest`)
- `backend/app/Http/Resources/Api/V1/*` (`OrderItemResource`, `PaymentResource`, `EscrowTransactionResource`, `OrderResource`)
- `backend/routes/api.php` (14 API Routes registered under `/api/v1`)
- `backend/tests/Feature/Api/V1/CartOrderAndPaymentTest.php` (8 test methods, 100 assertions)

## 5. API Endpoints (`Danh Sách Endpoints`)
- `GET /api/v1/cart`, `POST /api/v1/cart/items`, `PUT /api/v1/cart/items/{id}`, `DELETE /api/v1/cart/items/{id}`
- `POST /api/v1/checkout/preview`, `POST /api/v1/orders` (`throttle:transactional`)
- `GET /api/v1/payments/{id}`, `POST /api/v1/payments/{id}/simulate-success`, `POST /api/v1/payments/{id}/simulate-failure`
- `GET /api/v1/orders/purchases`, `GET /api/v1/orders/{id}`
- `POST /api/v1/orders/{id}/cancel`, `POST /api/v1/orders/{id}/withdraw-cancel-request`
- `POST /api/v1/seller/orders/{id}/respond-cancel`

## 6. Business Rules, Validation & Authorization
- **Business Rules:** `BR-AC-02` (Chặn tự mua), `BR-OR-01..04`, `BR-FN-01..03`, `DEC-04` (Buyer Protection Fee), `DEC-06` (Hủy 3 cấp), `DEC-07` (Hoàn 100% `total_amount`).

## 7. Test Cases & Acceptance Criteria (`Tiêu Chí Nghiệm Thu`)
- [x] 1. `test_cart_groups_items_by_seller_and_blocks_adding_own_product_with_403_self_transaction` (PASS)
- [x] 2. `test_checkout_preview_and_place_order_calculates_exact_dec04_buyer_protection_fee_and_freezes_snapshots` (PASS)
- [x] 3. `test_placing_order_decrements_stock_marks_product_sold_and_blocks_second_purchase_with_409_out_of_stock` (PASS)
- [x] 4. `test_simulate_qr_payment_success_is_idempotent_and_creates_single_escrow_hold_entry` (PASS)
- [x] 5. `test_simulate_qr_payment_failure_marks_failed_and_issues_new_pending_payment_session` (PASS)
- [x] 6. `test_tier1_and_tier2_buyer_cancel_at_paid_triggers_immediate_100_percent_full_refund_dec07_and_restores_stock` (PASS)
- [x] 7. `test_tier3_cancel_at_preparing_supports_withdraw_and_seller_approve_or_reject_dec06` (PASS)
- [x] 8. `test_buyer_cannot_cancel_order_once_shipped_returns_409_invalid_state_transition` (PASS)
- **Acceptance Criteria:** 100% bài test trong `CartOrderAndPaymentTest.php` đạt `PASS` (8/8 tests, 100 assertions).

## 8. Risks & Mitigation
- **Rủi ro:** Deadlock khi nhiều đơn hàng khóa nhiều sản phẩm theo thứ tự ID khác nhau.
- **Giảm thiểu:** Luôn sắp xếp mảng `product_id` tăng dần (`orderBy('id', 'asc')`) trước khi gọi `lockForUpdate()`.
