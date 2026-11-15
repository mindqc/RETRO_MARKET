# P7-08: SHOPPING CART, CHECKOUT (DEC-04) & MOCK QR ESCROW PAYMENT AUDIT REPORT

- **Project:** Retro Market (`izithrift`)
- **Phase:** Phase 07 – Flutter Mobile Application Development
- **Task ID:** `P7-08`
- **Status:** `REVIEW` (Ready for PO Verification & Approval)
- **Date:** 2026-11-15
- **Quality Gates:**
  - `flutter analyze`: **0 issues** (clean)
  - `flutter test`: **86/86 PASS** (100% across all mobile test suites)
  - Backend `php artisan test`: **88/88 PASS** (100%, 1043 assertions)

---

## 1. Executive Summary

Task `P7-08` expands the `izithrift` mobile application with complete shopping cart, checkout preview enforcing Decision `DEC-04`, order creation, and mock QR escrow payment simulation. The package implements 5 standardized mobile screens, unified Riverpod ViewModels, a centralized `CartCheckoutRepository`, robust SafeJsonParser models, and 10 dedicated automated tests.

---

## 2. Deliverables Checklist

### 2.1. Standardized Models (`mobile/lib/features/cart/models/`)
| Model File | Description & Specifications Covered |
| :--- | :--- |
| `cart_item_model.dart` | Cart item model parsing `product_code`, `unit_price`, `quantity`, `available_quantity`, condition badge, `item_subtotal`, and selection state. |
| `cart_seller_group_model.dart` | Grouped store model enforcing `BR-OR-01` (orders and cart split per store), store name, trust score, items list, and group-level selection check. |
| `cart_model.dart` | Full cart model containing `seller_groups[]`, `total_items_count`, `selected_subtotal`, and selection state helpers. |
| `checkout_preview_model.dart` | Grand preview and seller group breakdown models strictly enforcing Decision `DEC-04` ($\text{Buyer Protection Fee} = \text{Item Subtotal} \times 6\% + 7.000đ$, $\text{Shipping Fee} = 0đ$, $\text{Seller Net Amount} = 100\%$). |
| `payment_session_model.dart` | Mock QR Payment model containing VietQR payload, `transfer_content` (`IZITHRIFT {order_code}`), `payment_expires_at`, `order_status: PAID`, and `escrow_status: HELD`. |

### 2.2. Unified Repository (`mobile/lib/features/cart/repositories/`)
| File | Methods Implemented |
| :--- | :--- |
| `cart_checkout_repository.dart` | `fetchCart()`, `addToCart()`, `updateCartItemQuantity()`, `removeCartItem()`, `previewCheckout()`, `placeOrder()`, `fetchPaymentStatus()`, `simulatePaymentSuccess()`, `simulatePaymentFailure()`. |

### 2.3. State Management ViewModels (`mobile/lib/features/cart/viewmodels/`)
| ViewModel | Responsibilities |
| :--- | :--- |
| `cart_view_model.dart` | Manages cart state, optimistic quantity updates locked to available stock, store-level selection toggle (`toggleSellerGroupSelection`), individual item selection, and select-all. |
| `checkout_view_model.dart` | Fetches breakdown from `POST /api/v1/checkout/preview`, handles shipping address selection, optional order note, and submits order (`placeOrder`). |
| `payment_view_model.dart` | Handles QR payment loading, ServerCountdownTimer sync, and triggers Demo Mode simulations (`simulateSuccess`, `simulateFailure`). |

### 2.4. Screens & UI Components (`mobile/lib/features/cart/screens/`)
| Screen ID | File | Key Features |
| :--- | :--- | :--- |
| `M-CR-01` | `shopping_cart_screen.dart` | Store-level group cards (`BR-OR-01`), store checkboxes, quantity steppers, empty state (`RetroEmptyStateView`), sticky bottom bar with total and checkout CTA. |
| `M-OR-01` | `checkout_screen.dart` | Delivery address summary card with change trigger, order item snapshot per seller, note input, transparent `PriceBreakdownCard` (`DEC-04`), Escrow trust badge, and `[Đặt hàng & Thanh toán QR]` button. |
| `M-PM-01` | `mock_qr_payment_screen.dart` | Simulated VietQR frame, transfer content with clipboard copy, `ServerCountdownTimer` synced with server clock (`BR-AU-01`), and 2 Demo Mode buttons (`[✅ Mô phỏng Thanh toán Thành công]`, `[❌ Mô phỏng Thanh toán Thất bại]`). |
| `M-PM-02` | `payment_success_screen.dart` | Confirmation screen with Pine Green theme, order code, paid amount, `order_status: PAID`, `escrow_status: HELD` (`BR-FN-03`), Escrow explanation note, and order detail / continue shopping CTAs. |
| `M-PM-03` | `payment_failure_screen.dart` | Burgundy failure screen with failure/expiration reason banner, retry button (`[Thử thanh toán lại / Tạo mã mới]`), and return home CTA. |

### 2.5. Routing Integration (`mobile/lib/core/router/`)
- Registered routes in `app_routes.dart` and `app_router.dart`:
  - `AppRoutes.cart` (`/cart`) -> `ShoppingCartScreen`
  - `AppRoutes.checkout` (`/checkout`) -> `CheckoutScreen`
  - `AppRoutes.paymentQr` (`/payments/:id`) -> `MockQrPaymentScreen`
  - `AppRoutes.paymentSuccess` (`/payments/:id/success`) -> `PaymentSuccessScreen`
  - `AppRoutes.paymentFailure` (`/payments/:id/failure`) -> `PaymentFailureScreen`

---

## 3. Test Suite Verification

### 3.1. `mobile/test/features/cart_and_checkout_test.dart` (10/10 PASS)
1. `CartItemModel, CartSellerGroupModel, CartModel parse JSON correctly`: Verifies robust parsing with `SafeJsonParser`.
2. `CheckoutPreviewModel parses DEC-04 fee breakdown accurately`: Validates fee computation against formula $(550.000 \times 6\% + 7.000 = 40.000đ)$.
3. `PaymentSessionModel parses mock escrow session and expiration`: Validates session data, transfer content, and expiration parsing.
4. `CartViewModel handles item selection, group toggle, and select all`: Tests multi-level selection logic (`BR-OR-01`).
5. `Empty cart displays RetroEmptyStateView with CTA`: Tests empty cart state and discover CTA.
6. `Populated cart renders seller groups (BR-OR-01) and checkout bottom bar`: Tests grouped items and checkout summary.
7. `CheckoutScreen renders address, items, and PriceBreakdownCard with DEC-04 formula`: Tests address card, item snapshot, and transparent price breakdown.
8. `MockQrPaymentScreen displays VietQR, transfer content, countdown timer, and Demo triggers`: Tests VietQR frame, transfer content, timer, and demo buttons.
9. `PaymentSuccessScreen displays escrow held badge and navigation buttons`: Tests success confirmation and `escrow_status: HELD`.
10. `PaymentFailureScreen displays error reason and retry buttons`: Tests failure reason and retry action.

### 3.2. Global Verification
- `flutter analyze`: **0 issues found** (1.2s).
- `flutter test`: **86/86 PASS** (100% across all suites).
- Backend tests: **88/88 PASS** (100%, 1043 assertions).

---

## 4. Next Step Recommendation
Awaiting Product Owner (PO) verification and approval of Task `P7-08`. Upon sign-off, update `P7-08` to `DONE` and proceed to Task `P7-09` (`Order Fulfillment & Disputes`).
