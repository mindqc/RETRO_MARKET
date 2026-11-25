# P9-04 â€“ PLATFORM SETTINGS PROPAGATION AND CACHE INVALIDATION

- **Status:** `PENDING_PO_APPROVAL`
- **Current authorization:** Read-only discovery only.

## A. Discovery Tasks â€“ Authorized Now
1. Identify actual Admin settings routes, HTTP methods, controllers and validation.
2. Identify setting storage, cache keys/tags/TTL, invalidation mechanism and Redis usage.
3. Identify the Mobile-facing configuration endpoint and actual consumer behavior.
4. Identify audit-log behavior, if any.
5. Propose a safe non-financial setting suitable for an isolated test. Do not assume one exists.
6. Confirm whether propagation is intended to be immediate or bounded by a documented TTL/cache contract.

## B. Proposed Test Design â€“ Only After Separate PO Approval
Use a verified safe setting or isolated test data. Do not change `buyer_protection_fee` or any approved financial setting/rule. Assert only the cache and API behavior supported by verified implementation.

## C. Draft Acceptance Criteria â€“ PO Review Required
- AC-P904-01: A verified setting update is reflected according to the actual cache/propagation contract.
- AC-P904-02: No approved financial configuration or business rule is changed.
- AC-P904-03: Audit behavior is verified only if the implementation contract requires it.

## D. Required Immediate Output
Provide a read-only trace of Admin update -> storage -> cache -> Mobile config consumer, with evidence and a safe test proposal. Do not update settings, clear caches, write tests or modify source. Wait for explicit PO approval.
