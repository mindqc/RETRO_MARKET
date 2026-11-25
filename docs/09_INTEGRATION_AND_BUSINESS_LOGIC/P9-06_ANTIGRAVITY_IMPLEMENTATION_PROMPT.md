# P9-06 â€“ BACKEND HTTP E2E GOLDEN DEMO AND FINAL SIGN-OFF

- **Status:** `PENDING_PO_APPROVAL`
- **Current authorization:** Read-only discovery only.

## A. Discovery Tasks â€“ Authorized Now
1. Map a feasible Backend HTTP E2E journey using actual endpoints, roles, fixtures and state transitions.
2. Verify seller listing creation, moderation approval, auction scheduling/opening/closing, bidding, winner determination and order creation.
3. Verify Mock VietQR payment behavior, seller shipment, buyer receipt confirmation and review eligibility.
4. Identify scheduled-job dependencies and safe test controls. Do not trigger mutating jobs during discovery.
5. Inspect actual order, payment, escrow, wallet and audit data model and derive a reconciliation formula from the implemented accounting semantics.
6. Identify existing backend, Flutter and Admin build/test commands from project manifests and CI configuration.

## B. Proposed Backend HTTP E2E â€“ Only After Separate PO Approval
Candidate journey:
`Prepare Accounts -> Seller Creates Auction Listing -> Admin Approves -> Auction Opens -> Buyer Bids -> Winner Determined -> Winner Order Created -> Mock VietQR Payment -> Seller Ships -> Buyer Confirms Receipt -> Eligible Buyer Review`.

This is a Backend HTTP E2E (for example, PHPUnit/API-level execution). It must not be described as Flutter or browser UI E2E unless those UI journeys are separately automated and evidenced.

## C. Reconciliation
Do not invent a ledger formula. Derive it from actual schema, transaction types, debit/credit semantics, fees, refunds, escrow release and wallet rules. State precisely which accounts/records are included and excluded. Any unsupported reconciliation assumption remains `NEEDS_VERIFICATION`.

## D. Draft Acceptance Criteria â€“ PO Review Required
- AC-P906-01: The approved Backend HTTP E2E journey completes according to verified business rules.
- AC-P906-02: Reconciliation produces no unexplained discrepancy under the verified accounting model.
- AC-P906-03: Applicable backend, Flutter and Admin regression/build checks pass; exact commands and scope are confirmed from repository configuration.
- AC-P906-04: Final audit and Phase 10 handoff documents are supported by test evidence.

## E. Required Immediate Output
Provide a read-only E2E feasibility map, endpoint sequence, fixtures/dependencies, reconciliation proposal and regression command inventory. Do not run the journey, mutate data, create tests or modify source. Wait for explicit PO approval.
