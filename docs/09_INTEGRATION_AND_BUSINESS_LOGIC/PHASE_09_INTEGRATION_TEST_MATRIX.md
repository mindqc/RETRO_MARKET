# PHASE 09 INTEGRATION TEST MATRIX â€“ RETRO MARKET (izithrift)

- **Document ID:** `DOC-P9-TEST-MATRIX`
- **Status:** `DRAFT / PENDING_PO_APPROVAL`
- **Rule:** All routes, preconditions, expected outcomes, and test mechanics below are planning candidates until verified against repository evidence and approved by the PO.

| Test ID | WP | Scenario | Preconditions / Steps (draft) | Expected result / verification rule | Actual / Evidence | Status |
|---|---|---|---|---|---|---|
| IT-P901-01 | P9-01 | Buyer order deep link | Verify notification payload and target route; test candidate `/buyer/orders/:id` | Target mapping, ID/query preservation, auth behavior verified from actual router | | NEEDS_VERIFICATION |
| IT-P901-02 | P9-01 | Buyer/seller dispute deep links | Verify generated payloads and target route; test candidate buyer/seller dispute paths | Both mappings and access behavior verified from actual router | | NEEDS_VERIFICATION |
| IT-P901-03 | P9-01 | Seller product deep link | Verify generated payload and target route; test candidate `/seller/products/:id` | Mapping and destination screen behavior verified from actual router | | NEEDS_VERIFICATION |
| IT-P901-04 | P9-01 | Deep-link edge cases | Guest, unauthorized user, malformed/missing/nonexistent ID | Behavior follows verified auth guards and target-screen/API contract; no crash/redirect loop | | NEEDS_VERIFICATION |
| IT-P902-01 | P9-02 | True DB concurrency | LIVE auction; use genuinely independent concurrent DB connections/transactions or parallel HTTP workers | `TRUE_CONCURRENCY_VERIFIED` only if actual overlapping transactions and DB lock behavior are evidenced. Sequential/simulated tests are not a pass | | NEEDS_VERIFICATION |
| IT-P902-02 | P9-02 | Bid invariants | Valid concurrent/serialized bids according to verified service contract | Leading-bid, increment, ordering, and immutability invariants match actual approved rules | | NEEDS_VERIFICATION |
| IT-P902-03 | P9-02 | Conflict response and anti-sniping | Verify conflict contract and BR-AU-04 configuration before testing | HTTP 409/latest-state fields and extension behavior match verified implementation/configuration | | NEEDS_VERIFICATION |
| IT-P903-01 | P9-03 | PENDING_PAYMENT cancellation | Discover exact order/payment/escrow state preconditions and buyer cancellation contract | Actual state transitions, stock and financial effects match verified implementation and approved rules | | NEEDS_VERIFICATION |
| IT-P903-02 | P9-03 | PAID cancellation | Discover associated Payment/Escrow states; do not assume an escrow status | Refund, ledger, wallet, order and stock effects match verified implementation and approved rules | | NEEDS_VERIFICATION |
| IT-P903-03 | P9-03 | PREPARING cancellation paths | Discover request, withdrawal, seller approval and rejection endpoints/states | Each transition and side effect matches verified contract | | NEEDS_VERIFICATION |
| IT-P903-04 | P9-03 | SHIPPED/DELIVERED cancellation | Discover direct-cancel restrictions and dispute flow | HTTP/state/dispute behavior matches verified contract | | NEEDS_VERIFICATION |
| IT-P903-05 | P9-03 | Duplicate/idempotency guards | Discover idempotency mechanism and retry semantics | No duplicate financial/stock side effects where the verified contract requires idempotency | | NEEDS_VERIFICATION |
| IT-P904-01 | P9-04 | Settings propagation | Discover safe setting, Admin update path, config consumer, cache mechanism | Actual propagation/cache/audit behavior is asserted only if supported by implementation and approved scope | | NEEDS_VERIFICATION |
| IT-P905-01 | P9-05 | Purchases list HTTP coverage | Verify route, method, auth and permission | Direct HTTP test matches actual contract | | NEEDS_VERIFICATION |
| IT-P905-02 | P9-05 | Order detail HTTP coverage | Verify route, method and participant authorization | Direct HTTP test matches actual contract | | NEEDS_VERIFICATION |
| IT-P905-03 | P9-05 | Disputes list HTTP coverage | Verify route, method and authorization | Direct HTTP test matches actual contract | | NEEDS_VERIFICATION |
| IT-P905-04 | P9-05 | Dispute detail HTTP coverage | Verify route, method and participant/evidence access | Direct HTTP test matches actual contract | | NEEDS_VERIFICATION |
| IT-P905-05 | P9-05 | Seller orders HTTP coverage | Verify route, method and seller authorization | Direct HTTP test matches actual contract | | NEEDS_VERIFICATION |
| IT-P905-06 | P9-05 | Seller product update HTTP coverage | Verify exact route, method, payload/multipart behavior and owner policy | Direct HTTP test matches actual contract | | NEEDS_VERIFICATION |
| IT-P905-07 | P9-05 | Auction bids HTTP coverage | Verify route, method, masking and chronological ordering contract | Direct HTTP test matches actual contract | | NEEDS_VERIFICATION |
| IT-P905-08 | P9-05 | Health endpoint HTTP coverage | Verify route, method, public access and response envelope | Direct HTTP test matches actual contract | | NEEDS_VERIFICATION |
| IT-P905-09 | P9-05 | ProductCondition negative validation | Verify canonical enum and request validation locations | Invalid values are rejected according to the verified validation contract | | NEEDS_VERIFICATION |
| IT-P906-01 | P9-06 | Backend HTTP E2E Golden Demo | Discover viable fixtures, lifecycle, jobs and API sequence | Journey completes according to verified business rules; evidence retained | | NEEDS_VERIFICATION |
| IT-P906-02 | P9-06 | Financial/ledger reconciliation | Discover schema, ledger semantics, fee/refund rules and accounting formula | Reconciliation formula is derived from actual accounting model; no assumed formula | | NEEDS_VERIFICATION |

## Notes
- P9-02 distinguishes true DB concurrency from simulation. `SIMULATION_ONLY` and `NOT_VERIFIED` do not satisfy the true-concurrency verification gate.
- P9-03 must not hardcode `escrow_status = HELD` or any other unverified associated state.
- P9-04 must not assume a cache key, cache flush, audit event, or immediate-consistency contract before discovery.
- P9-05 route names and methods are placeholders until verified in route definitions and middleware.
- P9-06 means Backend HTTP E2E (e.g. PHPUnit/API execution), not automatically Flutter or browser UI E2E.
