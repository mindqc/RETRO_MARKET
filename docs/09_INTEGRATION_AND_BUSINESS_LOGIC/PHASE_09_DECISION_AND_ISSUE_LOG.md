# PHASE 09 DECISION AND ISSUE LOG â€“ RETRO MARKET (izithrift)

- **Document ID:** `DOC-P9-DECISION-ISSUE-LOG`
- **Status:** `DRAFT / PENDING_PO_APPROVAL`
- **Evidence rule:** A repository fact may be marked verified only when Antigravity supplies the exact evidence. This generated document itself is not repository evidence.

## 1. PO Decisions
| Decision ID | Scope | Decision | Status / Boundary |
|---|---|---|---|
| DEC-P9-01 | Phase transition | PO confirmed Phase 08 closed and Phase 09 started | APPROVED |
| DEC-P9-02 | P9-01 approach | PO selected Option A (Flutter GoRouter route aliasing) as the preferred approach, subject to repository discovery | APPROVED AS APPROACH PREFERENCE; NOT IMPLEMENTATION AUTHORIZATION |
| DEC-P9-03 | P9 structure | Phase 09 organized into six sequential WPs | PLANNING DECISION; each WP still requires separate implementation approval |
| P9-03-DEC-01 | P9-03 Cancellation Matrix | PO Decision: Option A – Do NOT support Seller Direct Cancellation on PREPARING orders when an open Buyer cancellation request exists (`cancellation_requested = true`). Case A (`cancellation_requested = false`) is APPROVED for implementation (Test #07). Case B (`cancellation_requested = true`) is EXCLUDED from implementation; Scenario #08 is EXCLUDED. Reconciled inventory: 22 original business scenarios, 21 executable scenarios, 1 excluded scenario, 23 executable PHPUnit methods. Enforced via HTTP 409 `INVALID_STATE_TRANSITION` and zero state mutation. | PO APPROVED |
| P9-03-DEC-02 | P9-03 Technical Acceptance | PO Acceptance: The PO accepts the P9-03 technical implementation based on the final audit report dated 2026-11-17 15:05 +07:00 (8 approved files, 23/23 feature tests pass, 24/24 regression tests pass, lock hierarchy and concurrency evidence verified). External scheduler defect in `AuctionLifecycleService::finalizeAuctionWithWinner()` tracked separately. Work package closure remains pending separate decision. | PO ACCEPTED – TECHNICAL IMPLEMENTATION |

## 2. Potential Issues â€“ Not Yet Verified
| Issue ID | Area | Potential mismatch / question | Evidence status | Proposed next step |
|---|---|---|---|---|
| ISS-P9-01 | Order notification deep link | Candidate backend path `/buyer/orders/{id}` versus candidate Flutter path `/orders/:id` | NEEDS_VERIFICATION; no source evidence established by this document | Inspect notification producers and GoRouter; confirm actual values before proposing alias |
| ISS-P9-02 | Dispute notification deep links | Candidate buyer/seller dispute paths versus candidate Flutter path `/disputes/:id` | NEEDS_VERIFICATION; no source evidence established by this document | Inspect all producers, route definitions and auth guards |
| ISS-P9-03 | Seller product notification deep link | Candidate `/seller/products/{id}` versus candidate `/seller/listings/:id/edit` | NEEDS_VERIFICATION; no source evidence established by this document | Inspect notification producers and destination route |
| ISS-P9-04 | Auction concurrency | Test environment may not support genuinely overlapping DB transactions | NEEDS_VERIFICATION | Inspect DB/test harness and propose a true concurrency strategy |
| ISS-P9-05 | Cancellation | Exact state transitions and financial side effects are not established here | NEEDS_VERIFICATION | Trace service/controller/model/ledger implementation |
| ISS-P9-06 | Settings propagation | Safe setting, cache mechanism and consumers are not established here | NEEDS_VERIFICATION | Trace Admin update path, cache and Mobile config API |

## 3. Pending Verification / PO Queue
| Ref ID | WP | Verification item | Status |
|---|---|---|---|
| PV-P9-01 | P9-01 | Enumerate every notification producer and actual deep-link URI pattern | NEEDS_VERIFICATION |
| PV-P9-02 | P9-01 | Confirm destination routes, path/query parameters and authentication behavior | NEEDS_VERIFICATION |
| PV-P9-03 | P9-02 | Confirm genuine PostgreSQL concurrency test feasibility | NEEDS_VERIFICATION |
| PV-P9-04 | P9-02 | Confirm conflict payload and anti-sniping rule/configuration | NEEDS_VERIFICATION |
| PV-P9-05 | P9-03 | Confirm cancellation state machine and all financial/stock side effects | NEEDS_VERIFICATION |
| PV-P9-06 | P9-04 | Confirm safe setting, Admin endpoint/method, config endpoint and cache invalidation | NEEDS_VERIFICATION |
| PV-P9-07 | P9-05 | Confirm eight route/method/middleware/permission contracts and enum validation | NEEDS_VERIFICATION |
| PV-P9-08 | P9-06 | Confirm E2E setup and accounting reconciliation formula | NEEDS_VERIFICATION |

## 4. Change Control
Any change to schema, RBAC, financial rules, escrow, auction rules, order state machine, or immutable-ledger behavior requires evidence, impact analysis, and explicit PO approval before implementation.
