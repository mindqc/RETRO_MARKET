# P9-01 â€“ NOTIFICATION DEEP-LINK DISCOVERY / PROPOSED ROUTE ALIASING

- **Status:** `PENDING_PO_APPROVAL`
- **Current authorization:** Read-only discovery only.
- **PO preference:** Option A â€“ Flutter GoRouter aliasing, subject to discovery.
- **Important:** This preference does not authorize code or test changes.

## A. Discovery Tasks â€“ Authorized Now
1. Search all backend notification producers and actual `deep_link_route` values.
2. Inspect `mobile/lib/core/router/app_router.dart`, route names, path parameters, query parameters, redirect logic and auth guards.
3. Verify whether these are actual mappings or merely candidates:
   - `/buyer/orders/:id` -> `/orders/:id`
   - `/buyer/disputes/:id` -> `/disputes/:id`
   - `/seller/disputes/:id` -> `/disputes/:id`
   - `/seller/products/:id` -> `/seller/listings/:id/edit`
4. Identify other generated deep-link patterns and any destination that does not exist.
5. Report exact source paths, symbols, and evidence. Mark unsupported assumptions `NEEDS_VERIFICATION`.

## B. Proposed Implementation Scope â€“ Only After Separate PO Approval
If approved, implement only the verified aliases in GoRouter. Preserve path/query parameters, avoid redirect loops, and respect existing authentication/authorization behavior. Do not modify backend notification generation or database schema unless separately approved.

## C. Proposed Tests â€“ Only After Separate PO Approval
- Verify each confirmed URI resolves to the intended destination.
- Verify path and query parameter preservation.
- Verify guest/unauthorized behavior against existing guards.
- Verify malformed/nonexistent resource handling at the correct layer.
- Verify no `GoException`, crash, or redirect loop.

## D. Draft Acceptance Criteria â€“ PO Review Required
- AC-P901-01: Every repository-confirmed deep-link pattern resolves to its approved destination.
- AC-P901-02: Parameters and authentication behavior match the verified contract.
- AC-P901-03: Relevant Flutter analyze/tests pass with evidence.

## E. Required Immediate Output
Provide a read-only discovery report and draft test plan. Do not edit `app_router.dart`, create tests, or modify any file. State explicitly: `NO SOURCE OR TEST FILES MODIFIED`. Wait for explicit PO approval before implementation.
