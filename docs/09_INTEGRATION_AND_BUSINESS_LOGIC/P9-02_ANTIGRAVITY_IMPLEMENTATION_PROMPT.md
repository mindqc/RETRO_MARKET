# P9-02 â€“ HIGH-CONCURRENCY AUCTION BIDDING VERIFICATION

- **Status:** `PENDING_PO_APPROVAL`
- **Current authorization:** Read-only discovery only.

## A. Discovery Tasks â€“ Authorized Now
1. Inspect auction bidding service, conflict exception/response, Auction and AuctionBid models, database indexes/constraints, and existing tests.
2. Identify actual transaction boundaries and locking mechanism (including whether PostgreSQL `FOR UPDATE` is used).
3. Verify the exact `latest_state` response fields; do not assume a fixed field count.
4. Trace `BR-AU-04` and actual anti-sniping configuration/limits.
5. Determine whether the test environment can create genuinely overlapping independent DB connections/transactions or parallel HTTP requests.

## B. Proposed Test Design â€“ Only After Separate PO Approval
- **True concurrency:** Use independent concurrent connections/workers with evidence of overlapping transactions and lock contention. Sequential requests or a loop are not true concurrency.
- **Bid invariants:** Separately verify leading-bid uniqueness, minimum increment, bid ordering, and immutable bid-record behavior according to actual rules.
- **Conflict/anti-sniping:** Separately verify HTTP 409 and `latest_state`, plus `extended_count`/`auction_ends_at` only where supported by verified `BR-AU-04`.

## C. Strict Classification
- `TRUE_CONCURRENCY_VERIFIED`: actual overlapping DB transactions/connections and relevant lock behavior are evidenced.
- `SIMULATION_ONLY`: sequential or simulated race/load test; supplementary evidence only.
- `NOT_VERIFIED`: environment or evidence insufficient.
Only `TRUE_CONCURRENCY_VERIFIED` can pass the true-concurrency verification criterion.

## D. Draft Acceptance Criteria â€“ PO Review Required
- AC-P902-01: True DB concurrency is demonstrated and classified `TRUE_CONCURRENCY_VERIFIED`.
- AC-P902-02: Bid invariants match the verified domain contract.
- AC-P902-03: Conflict response and anti-sniping behavior match verified API/business-rule contracts.

## E. Required Immediate Output
Provide read-only feasibility analysis, proposed concurrency harness, verified contract details and limitations. Do not create/modify tests or source files. Wait for explicit PO approval.
