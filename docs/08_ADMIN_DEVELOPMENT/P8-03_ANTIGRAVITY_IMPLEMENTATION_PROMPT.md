# P8-03 ANTIGRAVITY IMPLEMENTATION PROMPT – AUCTIONS, ORDERS & PAYMENTS

## A. Task Identity
- **Project:** Retro Market (`izithrift`)
- **Phase:** Phase 08 – Laravel Blade Admin Dashboard Development
- **Work Package ID:** `P8-03`
- **Work Package Name:** Auctions, Orders & Payments
- **Authorization:** `APPROVED` (Sequential Execution after `P8-02` PASS)
- **Current Status:** `READY_AFTER_P8_02`
- **Dependencies:** `P8-01` and `P8-02` Completed & Verified; Phase 06 Auction, Checkout, Order, Cancellation & Mock QR Payment Services.

## B. Context
- Scheduled Auctions support `SCHEDULED`, `LIVE`, `ENDED_SOLD` (`COMPLETED`), `ENDED_UNSOLD`, `WINNER_DEFAULTED`, and `CANCELLED` states, with Anti-Sniping (`BR-AU-04`), concurrency locking (`lockForUpdate`), and a 30-minute winner payment deadline (`BR-AU-07`, `DEC-02`).
- Orders operate with **4 independent state machines** (`order_status`, `payment_status`, `escrow_status`, `dispute_status`), transparent buyer protection fee calculation (`DEC-04`: `6% + 7,000 VND`, seller receives `100% item_subtotal`), and 3-tier cancellation (`DEC-06` / `DEC-07`).
- `auction_bids` and `order_items` are immutable (`ImmutableLedgerRecord`).

## C. Objective
Implement the 6 canonical Auction, Order, and Payment management screens (`A-AC-01`, `A-AC-02`, `A-AC-03`, `A-OR-01`, `A-OR-02`, `A-PM-01`), reusing Phase 06 Domain Services while strictly preserving transactional and financial integrity.

## D. Exact Scope
- **Screens Implemented (6 of 21):**
  1. `A-AC-01`: Auction Management List (verify exact name & route in `PHASE_08_IMPLEMENTATION_PLAN.md`).
  2. `A-AC-02`: Auction Detail / Live Monitoring (Ticket-stub motif, bid trail, Anti-Sniping status).
  3. `A-AC-03`: Auction History / Completed & Defaulted Winner Management View.
  4. `A-OR-01`: Order Management List (4 state machines filter & search).
  5. `A-OR-02`: Order Detail Inspector (Snapshot items, `DEC-04` breakdown, 3-tier cancel logs, shipment timeline).
  6. `A-PM-01`: Payment Management (QR payment transactions, status, expiration, order linkage).

## E. Implementation Tasks
- **TASK-P803-01 (Repository Inspection for Auction, Order & Payment Services/Policies):**
  - Inspect existing Phase 06 services (`AuctionService`, `CheckoutService`, `OrderCancellationService`, `MockQrPaymentService`, etc.) and policies to map read queries and any permitted administrative actions in `03_ACTOR_PERMISSION_MATRIX.md`.
- **TASK-P803-02 (`A-AC-01`, `A-AC-02`, `A-AC-03` Auction Management Views & Controllers):**
  - Implement `A-AC-01` (active/scheduled auctions with filters), `A-AC-02` (detailed **Ticket-Stub Motif** inspector displaying starting price, increment, reserve status, `current_highest_bid`, `extended_count` Anti-Sniping indicator per `BR-AU-04`, immutable `auction_bids` history, and any authorized administrative intervention via `AuctionService`), and `A-AC-03` (archive of ended, unsold, and `WINNER_DEFAULTED` auctions with winning order/payment deadline tracking per `BR-AU-07`).
- **TASK-P803-03 (`A-OR-01` & `A-OR-02` Order Management & 360° Inspector):**
  - Implement `A-OR-01` (paginated list with search by `order_code`, buyer/seller, and filters across all 4 state machines) and `A-OR-02` (displaying immutable `order_items` snapshots, shipping address snapshot, exact `DEC-04` fee breakdown `item_subtotal + (6% + 7,000 VND)`, `100%` seller payout, shipment tracking events, and 3-tier cancellation state `DEC-06`). Delegate any permitted action strictly to existing Order services.
- **TASK-P803-04 (`A-PM-01` Payment Management Screen):**
  - Implement `A-PM-01` listing payment sessions (`payment_code`, linked `order_code`, amount, QR transfer content, `payment_status`, `payment_expires_at`, `paid_at`) with filtering and search.
- **TASK-P803-05 (`P8-03` Automated Feature, Concurrency & Financial Integrity Tests):**
  - Create `tests/Feature/Admin/P803_AuctionsOrdersAndPaymentsTest.php` verifying all 6 screens, `DEC-04` math display, 4-state order rendering, immutable `auction_bids`/`order_items` protection, and RBAC matrix compliance.

## F. Acceptance Criteria
- **`AC-P803-01` (`A-AC-01..03`):** Accurately renders scheduled, live, ended, and `WINNER_DEFAULTED` auctions, Anti-Sniping `extended_count` (`BR-AU-04`), 30-min winner payment deadline (`BR-AU-07`), and immutable `auction_bids` trail.
- **`AC-P803-02` (`A-OR-01..02`):** Displays all 4 independent state machines (`order_status`, `payment_status`, `escrow_status`, `dispute_status`), immutable `order_items` snapshots, shipment timeline, and 3-tier cancellation details (`DEC-06`).
- **`AC-P803-03` (Financial Consistency `DEC-04`):** Order and Payment views (`A-OR-02`, `A-PM-01`) display server-calculated figures matching `Buyer Protection Fee = 6% + 7,000 VND` and `Seller Net Payout = 100% item_subtotal`.
- **`AC-P803-04` (`A-PM-01`):** Filters and displays QR payment records (`PENDING`, `PAID`, `FAILED`, `EXPIRED`) accurately linked to their orders.
- **`AC-P803-05` (RBAC & Immutability Protection):** Enforces role permissions across all 6 screens; prevents any modification/deletion of `auction_bids` or `order_items`.

## G. Regression, Documentation & Completion Report
- Run full Backend (`php artisan test`), DB constraints (`php artisan db:verify-constraints`), and Mobile (`flutter analyze`, `flutter test`).
- Create `docs/08_ADMIN_DEVELOPMENT/P8_03_AUCTIONS_ORDERS_AND_PAYMENTS.md` and update `MASTER_TASK_TRACKER.md` & `AI_SYNC_BRIDGE.md`.
- Output full Completion Report with AC Evidence Matrix (`AC-P803-01`..`05`) and Handoff to **`P8-04`**.
