# IZITHRIFT (RETRO MARKET) – SYSTEM CONSTITUTION & AI CODING RULES

## 1. Project Identity & Directory Structure
- **App Brand Name:** `izithrift` (Project Codename / Root Folder: `RETRO_MARKET`)
- **Domain:** Mobile Secondhand & Vintage C2C Marketplace (Warm Vintage Editorial + Cozy Christmas Theme).
- **Governance & Tracker Path:** `docs/00_PROJECT_GOVERNANCE/MASTER_TASK_TRACKER.md`
- **AI Sync Bridge Path:** `docs/00_PROJECT_GOVERNANCE/AI_SYNC_BRIDGE.md`
- **Documentation Folders:**
  - `docs/00_PROJECT_GOVERNANCE/`
  - `docs/01_REQUIREMENTS_ANALYSIS/`
  - `docs/02_SYSTEM_FLOWS/`
  - `docs/03_UI_UX_DESIGN/`
  - `docs/04_SYSTEM_ARCHITECTURE/`
  - `docs/05_DATABASE_DESIGN/`
  - `docs/06_API_DOCUMENTATION/`
  - `docs/07_TESTING/`
  - `docs/08_DEPLOYMENT/`
- **Source Folders:**
  - `mobile/`: Flutter mobile app (`izithrift`).
  - `backend/`: Laravel 13 REST API (`/api/v1`) + PostgreSQL 18 migrations/seeders + shared business Services.
  - `admin/`: Admin Dashboard module (Laravel Blade sharing the single `backend/` core; do NOT create a separate duplicate backend).
  - `assets/`: Shared fonts, illustrations, and vintage/Christmas visual assets.

## 2. Official Tech Stack (STRICTLY ENFORCED)
- **Mobile Frontend:** Flutter (Dart), MVVM + Repository Pattern, `Provider`, `go_router`, `Dio`, `flutter_secure_storage`, `image_picker`.
- **Backend & Admin:** Laravel 13 (PHP 8.3+), RESTful API (`/api/v1`), Laravel Sanctum, Eloquent ORM, Form Requests, DB Transactions, Laravel Blade.
- **Database & Infra:** PostgreSQL 18 (Docker Compose `postgres:18-alpine`), Local Filesystem for uploads. No paid third-party services.
- **Typography:** `Wichita Vintage` (Brand Logo `izithrift` & verified glyph titles) -> fallback `Fraunces` (Vietnamese Headings) -> `Be Vietnam Pro` (Body, Buttons, Prices). Use Unicode NFC.
- **Color Tokens:** Warm Cream `#F4EBDD`, Soft Beige `#E9DDCB`, Forest Green `#294638`, Burgundy `#873A43`, Vintage Brown `#84664C`, Muted Gold `#C5A66B`, Dark Charcoal `#302D2A`.

## 3. Core Architectural & Business Rules
1. **Single Account Buyer/Seller:** Every Regular User account acts as both buyer and seller.
2. **Four Independent State Machines:** Keep `order_status`, `payment_status`, `escrow_status`, and `dispute_status` strictly separate.
3. **Append-Only Financial Ledger:** Never `UPDATE` or `DELETE` records in `escrow_transactions` or `wallet_transactions`. Use `DECIMAL/NUMERIC` for currency.
4. **Order Snapshot:** Store product name, price, condition, and image snapshot in `order_items` at checkout time.
5. **Concurrency & Locking:** Use `DB::transaction()` and `lockForUpdate()` for simultaneous auction bids, order creation, and escrow releases.
6. **Fixed Expiration Timestamps & Demo Mode:** Store explicit timestamps (`payment_expires_at`, `auto_complete_at`, `auction_ends_at`) on records. Support `DEMO_MODE=true` with configurable durations and Admin Developer Tools calling idempotent Service classes.

## 4. Controlled Development Task Protocol
1. Always inspect `docs/00_PROJECT_GOVERNANCE/MASTER_TASK_TRACKER.md` and `docs/00_PROJECT_GOVERNANCE/AI_SYNC_BRIDGE.md` before executing any task.
2. Follow the 6-step workflow: Pre-Implementation Analysis -> End-to-End Implementation -> Quality Verification -> Automated/Manual Testing -> Final Report -> Update Tracker to `REVIEW` (never mark `DONE` without user approval).
