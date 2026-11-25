# P9-05 â€“ SUPPLEMENTARY HTTP TEST BACKLOG

- **Status:** `PENDING_PO_APPROVAL`
- **Current authorization:** Read-only discovery only.

## A. Discovery Tasks â€“ Authorized Now
Cross-check the previously reported eight missing direct HTTP tests against actual route definitions, controllers, middleware, policies, API docs and current tests. Verify exact URI, HTTP method, payload/content type, authentication, permissions and response contract for:
1. Buyer purchases list.
2. Buyer order detail.
3. Disputes list.
4. Dispute detail.
5. Seller orders list.
6. Seller product update.
7. Auction bids list.
8. Health check.

The following are candidate paths only, not confirmed route contracts:
- `GET /api/v1/orders/purchases`
- `GET /api/v1/orders/{id}`
- `GET /api/v1/disputes`
- `GET /api/v1/disputes/{id}`
- `GET /api/v1/seller/orders`
- Seller product update: method and URI must be discovered.
- `GET /api/v1/auctions/{id}/bids`
- `GET /api/v1/health`

Also verify the canonical ProductCondition enum and every request validation location. Previously reported candidate values are `NEW_WITH_TAGS`, `LIKE_NEW`, `GOOD`, `FAIR`, `VINTAGE_WORN`; confirm them from repository evidence before treating them as authoritative. Candidate invalid inputs include `POOR`, `DAMAGED`, `VINTAGE`, `UNKNOWN_CONDITION`, and empty string.

## B. Proposed Test Work â€“ Only After Separate PO Approval
Create direct HTTP feature tests for confirmed route contracts and negative validation tests for confirmed enum rules. Do not change endpoint behavior or enum definitions as part of test coverage without separate PO approval.

## C. Draft Acceptance Criteria â€“ PO Review Required
- AC-P905-01: Every approved backlog endpoint has direct HTTP coverage matching its actual contract.
- AC-P905-02: ProductCondition validation tests match the canonical enum and actual validation contract.

## D. Required Immediate Output
Return a route/coverage audit table with source evidence and gaps. Do not create or edit test files. Wait for explicit PO approval.
