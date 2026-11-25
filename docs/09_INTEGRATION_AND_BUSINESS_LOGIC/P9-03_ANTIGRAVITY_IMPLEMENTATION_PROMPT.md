# P9-03 â€“ THREE-TIER ORDER CANCELLATION MATRIX

- **Status:** `PENDING_PO_APPROVAL`
- **Current authorization:** Read-only discovery only.

## A. Discovery Tasks â€“ Authorized Now
Trace actual cancellation behavior across Buyer API, Seller API, Admin, domain services, models, policies, payment, escrow, wallet, stock and audit records. Identify:
- Exact order states and permitted transitions.
- Buyer cancellation, withdrawal, seller approval and rejection paths.
- Payment/Escrow states associated with each order state.
- Refund and wallet/ledger entries and their idempotency guards.
- Stock restoration behavior.
- SHIPPED/DELIVERED restrictions and dispute routing.
- HTTP methods, routes, middleware and permissions.

Do not assume `escrow_status = HELD` or any other payment/escrow state from the order status alone. Derive preconditions from the actual implementation and data relationships.

## B. Proposed Test Matrix â€“ Only After Separate PO Approval
1. `PENDING_PAYMENT`: verify cancellation and actual side effects.
2. `PAID`: discover associated Payment/Escrow state, then verify refund path and ledger effects.
3. `PREPARING`: verify request, withdrawal, seller approval and seller rejection paths that actually exist.
4. `SHIPPED` / `DELIVERED`: verify direct-cancel restrictions and dispute flow.
5. Duplicate/retry behavior: verify idempotency according to the actual contract.

Any expected result not established by source evidence must remain `NEEDS_VERIFICATION`; do not encode guessed outcomes as assertions.

## C. Draft Acceptance Criteria â€“ PO Review Required
- AC-P903-01: All verified cancellation transitions behave according to approved business rules.
- AC-P903-02: Financial, stock and ledger side effects are consistent with the actual accounting model.
- AC-P903-03: Retry/idempotency behavior matches the verified contract.

## D. Required Immediate Output
Provide a read-only state-transition matrix with source evidence and unresolved questions. Do not write tests or modify code. Wait for explicit PO approval.
