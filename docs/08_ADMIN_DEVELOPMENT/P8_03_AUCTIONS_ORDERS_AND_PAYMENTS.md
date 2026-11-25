# P8-03 IMPLEMENTATION REPORT: AUCTIONS, ORDERS & PAYMENTS

## 1. Executive Summary
- **Work Package:** `P8-03: Auctions Monitor, 4-State Orders Inspector & Payments Management`
- **Scope Implemented:** 6 Screens (`A-AC-01`, `A-AC-02`, `A-AC-03`, `A-OR-01`, `A-OR-02`, `A-PM-01`)
- **Status:** `COMPLETED & VERIFIED` (Ready for PO Review)
- **Zero Schema Touch:** 34 PostgreSQL 18 tables and database constraints untouched.
- **Zero Mobile Touch:** Mobile code and `/api/v1/*` contracts 100% preserved.

---

## 2. Implemented Screens & Controllers

### 2.1. `A-AC-01` & `A-AC-03`: Auction Management & Completed/Defaulted History
- **Route:** `GET /admin/auctions`
- **Controller:** `App\Http\Controllers\Admin\AuctionManagementController@index`
- **Permissions:** `auctions.view` (Admin & Moderator)
- **Features:**
  - Status summary metrics: Total, Live, Scheduled, Completed, Winner Defaulted (`BR-AU-07`, `DEC-02`), Cancelled.
  - Tabs: All auctions, Live/Scheduled (`A-AC-01`), Completed History (`A-AC-03`), Winner Defaulted (`tab=defaulted`).
  - Search by auction code, product title, seller name/email.
  - Displays Starting Price, Current Highest Bid, Reserve Price, Bid Count, Watch Count, Schedule, and Anti-Sniping extension badges (`BR-AU-04`).

### 2.2. `A-AC-02`: Auction Detail & Live Monitoring (Ticket-Stub Motif)
- **Route:** `GET /admin/auctions/{id}`
- **Controller:** `App\Http\Controllers\Admin\AuctionManagementController@show`
- **Permissions:** `auctions.view` (Admin & Moderator)
- **Design Motif:** **Warm Editorial Archive Ticket-Stub Motif** (`IZITHRIFT OFFICIAL AUCTION VOUCHER`, perforated edge dashed border, ticket lot header, typography).
- **Core Verification Points:**
  - Pricing rules: Starting price, minimum bid increment, reserve price (with indicator whether reserve met), current highest bid, leading bidder.
  - **Anti-Sniping Indicator (`BR-AU-04`)**: Displays `extended_count` with total minutes added (`+2 minutes` per late bid in final 2 minutes) and `last_extended_at`.
  - **30-Minute Winner Payment Deadline (`BR-AU-07` / `DEC-02`)**: Displays winner details, linked order (`#ORD-...`), and defaults status (`WINNER_DEFAULTED`).
  - **Immutable Bid History Trail (`auction_bids`)**: Renders append-only bid log with timestamp, bidder info, bid amount, previous bid, and anti-sniping trigger badge.
  - **Administrative Intervention:** Cancel auction (`POST /admin/auctions/{id}/cancel` via `AuctionLifecycleService@cancelAuctionByAdmin`), requiring reason, restoring product to `APPROVED`, recording audit log, and notifying seller.

### 2.3. `A-OR-01`: Order Management & 4 Independent State Machines
- **Route:** `GET /admin/orders`
- **Controller:** `App\Http\Controllers\Admin\OrderManagementController@index`
- **Permissions:** `orders.view` (Admin & Support Staff)
- **Core Architecture:**
  - Strict separation of **4 Independent State Machines**:
    1. `order_status`: `PENDING_PAYMENT`, `PAID`, `PREPARING`, `SHIPPED`, `DELIVERED`, `COMPLETED`, `CANCELLED`, `REFUNDED`
    2. `payment_status`: `UNPAID`, `PAID`, `EXPIRED`, `REFUNDED`
    3. `escrow_status`: `NONE`, `HELD`, `RELEASED`, `REFUNDED`, `PARTIALLY_REFUNDED`
    4. `dispute_status`: `NONE`, `OPEN`, `NEED_MORE_INFO`, `RESOLVED`
  - Filters across each state machine individually, plus search by order code, buyer, seller.
  - Summary metric cards for total orders, escrow held count, open disputes, completed orders, and GMV volume.

### 2.4. `A-OR-02`: Order 360° Inspector & DEC-04 Financial Breakdown
- **Route:** `GET /admin/orders/{id}`
- **Controller:** `App\Http\Controllers\Admin\OrderManagementController@show`
- **Permissions:** `orders.view` (Admin & Support Staff)
- **Core Verification Points:**
  - 4 State Machine control panel with distinct indicators.
  - Buyer and Seller 360° profile cards (including seller escrow held balance).
  - Shipping address snapshot.
  - **Immutable `order_items` Snapshot Table**: Shows frozen title, code, condition, defect info, unit price snapshot, quantity, line total (`ImmutableLedgerRecord`).
  - **DEC-04 Financial Breakdown Table**:
    - Item Subtotal (`item_subtotal`)
    - Shipping Fee (`shipping_fee = 0 đ`)
    - Buyer Protection Fee: `item_subtotal * 6% + 7,000 đ`
    - Total Amount (`item_subtotal + buyer_protection_fee`)
    - Seller Net Payout: `100% item_subtotal` (0% seller commission)
    - Formatted with `tabular-nums font-mono`.
  - Shipment tracking timeline (`Shipment` carrier, tracking code, shipping note, timestamps).
  - 3-tier cancellation status (`DEC-06` / `DEC-07`).

### 2.5. `A-PM-01`: Payment Management Screen
- **Route:** `GET /admin/payments`
- **Controller:** `App\Http\Controllers\Admin\PaymentManagementController@index`
- **Permissions:** `payments.view` (Admin only; 403 Default Deny for Moderator & Support)
- **Features:**
  - Lists Mock QR payment sessions (`payment_reference`, linked `order_code`, payer, amount, standardized QR payload, `status`, `expires_at`, `paid_at`).
  - Status filters: `PENDING`, `PAID`, `EXPIRED`, `FAILED`, `REFUNDED`.
  - Summary cards: Total sessions, paid total amount, pending QR count, expired QR count.

---

## 3. Test Coverage & Verification Evidence

### 3.1. Automated Feature Test Suite
- **File:** `backend/tests/Feature/Admin/P803_AuctionsOrdersAndPaymentsTest.php`
- **Results:** 9/9 tests PASS (91 assertions, 0 errors, 0 failures)
  1. `test_admin_and_moderator_can_view_auctions_list_and_filters` -> PASS
  2. `test_auction_ticket_stub_monitor_displays_pricing_anti_sniping_and_bid_trail` -> PASS
  3. `test_winner_defaulted_auction_displays_30min_payment_rule` -> PASS
  4. `test_admin_and_moderator_can_cancel_auction_and_restore_product` -> PASS
  5. `test_orders_list_displays_4_independent_state_machines` -> PASS
  6. `test_order_360_inspector_displays_dec04_breakdown_and_immutable_items` -> PASS
  7. `test_payment_management_displays_qr_sessions` -> PASS
  8. `test_rbac_matrix_and_default_deny_enforced_across_screens` -> PASS
  9. `test_immutable_ledger_protection_on_bids_and_order_items` -> PASS

### 3.2. RBAC & Default Deny Matrix Verification
- Moderator: Access to Auctions (`A-AC-01..03`), strictly denied (`403`) from Orders (`A-OR-01..02`) and Payments (`A-PM-01`).
- Support: Access to Orders (`A-OR-01..02`), strictly denied (`403`) from Auctions (`A-AC-01..03`) and Payments (`A-PM-01`).
- Registered User: Strictly denied (`403`) from all Admin routes.
- Admin: Full access across all 6 screens.
- Immutability: Calling `update()` or `delete()` on `AuctionBid` or `OrderItem` throws `LogicException` (`ImmutableLedgerRecord`).
