# PHASE 09 MASTER EXECUTION PROMPT FOR ANTIGRAVITY

- **Project:** Retro Market (`izithrift`)
- **Role:** Repository Discovery, technical feasibility analysis, and (only after separate approval) QA/implementation executor.
- **Phase Status:** `PENDING_PO_APPROVAL`
- **Current Authorization:** `READ_ONLY_DISCOVERY_ONLY`

## 1. Immediate Task â€“ Read-Only Discovery
You are authorized only to inspect the repository and report:
- Actual route definitions, HTTP methods, middleware, permissions, controllers, services, models, enums, migrations, and relevant tests.
- Actual Flutter GoRouter routes, redirect/auth guards, and navigation tests.
- Actual auction locking/concurrency implementation and anti-sniping rules.
- Actual order cancellation, payment, escrow, refund, stock, wallet, and idempotency behavior.
- Actual settings storage, cache invalidation, Admin update path, and Mobile config endpoint.
- Exact missing HTTP test coverage and ProductCondition validation contract.
- Actual E2E prerequisites, payment/escrow lifecycle, accounting model, and available regression commands.

Use repository evidence: file paths, symbol names, relevant code excerpts/line references, and test names/results. Mark anything not established as `NEEDS_VERIFICATION`. Do not infer implementation facts from this planning package.

## 2. Strict Authorization Boundary
**Do not modify source code, create or edit tests, alter database state, run migrations/seeders, change configuration, or implement any WP during this discovery task.**

A PO-selected solution preference (including Option A for P9-01) is not authorization to implement it. Each WP requires a separate explicit PO approval after discovery and review of that WP's scope and Acceptance Criteria.

If the PO later approves a WP, execute only that WP and only within its approved scope. Do not proceed to the next WP automatically.

## 3. Discovery Report Format
For every WP, provide:
1. Verified facts with repository path and evidence.
2. Unverified assumptions and missing evidence.
3. Feasibility and test-environment constraints.
4. Proposed test design and exact commands (do not execute mutating commands).
5. Risks, dependencies, and scope impact.
6. Draft AC recommendations for PO review.
7. Explicit statement: `NO SOURCE OR TEST FILES MODIFIED`.

## 4. Post-Approval Completion Gate
Only after a separate PO approval for a specific WP, report implementation details, changed files (`git status --short`), tests and regression results, AC status, remaining issues, and proposed next step. Do not claim success without command output/evidence.

Potential regression commands (confirm actual project scripts before use): backend test suite, `db:verify-constraints`, Admin `npm run build`, Flutter `flutter analyze`, and `flutter test`. Do not assume every command exists or is applicable.
