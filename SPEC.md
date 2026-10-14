# SPEC.md — Supermarket Inventory & POS System

**Version:** 1.0
**Status:** Source of truth for features. Conflicts with `CLI_MASTER_PROMPT.md` must be reported to the product owner before code is written.
**Stack:** Flutter (Dart, Material 3, Riverpod, GoRouter) · Supabase (Postgres, Auth, RLS, Storage, RPC, Edge Functions, Realtime, pg_cron) · Drift (offline POS cache)

---

## 1. Product Overview

A multi-tenant, multi-branch supermarket Inventory & Point-of-Sale system. It runs on
phones, tablets and desktop/web. The POS screen is optimised for tablet/desktop
landscape with hardware barcode scanners (USB/Bluetooth keyboard-wedge) and
ESC/POS thermal printers.

### 1.1 Goals
- Sell fast at the counter (< 500 ms scan-to-cart) with zero overselling.
- Never lose a sale: offline queue with exactly-once sync.
- Real-time, trustworthy stock and profit numbers for the owner.
- Every ruppee of stock movement is auditable (`stock_movements`, no exceptions).

### 1.2 Non-Goals (v1)
- E-commerce storefront, delivery routing, manufacturing/BOM, accounting software export beyond CSV.

---

## 2. Users & Roles

| Role | Description | Typical device |
|---|---|---|
| `owner` | Business owner, sees everything across branches | Desktop/Web |
| `manager` | Branch or inventory manager | Tablet/Desktop |
| `cashier` | Runs POS, no cost/profit/supplier access | Tablet/POS terminal |
| `stocker` | Stock counts, receiving, transfers | Phone/Tablet |
| `viewer` | Read-only reports | Desktop |

Roles are templates; permission keys are granular (§67). A business may create custom roles.

---

## 3. Multi-Tenancy & Branches
- Every business-owned row carries `business_id UUID NOT NULL`.
- Every user (`profiles`) belongs to exactly one business and (optionally) one default branch.
- Branch-scoped tables (sales, shifts, inventories, transfers) also carry `branch_id`.
- Two businesses can never see each other's data — enforced by RLS (§107).

---

## 4. Currency, Locale, Timezone
- Default currency **PKR**, configurable per business (ISO 4217 code stored).
- Default timezone **Asia/Karachi**, configurable per business (IANA name stored).
- Money in UI is formatted with `intl` using business settings; backend stores `numeric(14,2)`.

---

## 5. Units of Measure
- Units table: `Piece (pcs)`, `Kilogram (kg)`, `Gram (g)`, `Litre (L)`, `Millilitre (mL)`, `Box`, `Pack`.
- Weight-based units mark a product as `is_weight_based = true`; POS prompts for decimal quantity.
- Quantities are `numeric(14,3)` everywhere.

---

## 6. Products
- Fields: name, SKU (unique per business), barcode (unique per business, nullable), category, brand, unit, purchase price (cost), selling price, tax rate, `is_weight_based`, `track_batch`, `is_active`, `image_url`, description, reorder level.
- Barcode may be auto-generated (EAN-13 with correct check digit, or Code128) when the user doesn't supply one (§104).
- Soft delete: `status = 'archived'` / `deleted_at`; archived products disappear from POS but stay in history.
- Price changes create a `price_history` row (§72) via trigger.

---

## 7. Categories, Brands, Units
Flat (non-nested) categories and brands per business, soft-deletable. Deleting is blocked while products reference them (RESTRICT).

---

## 8. Inventory Model
- `inventories` = current on-hand qty per `(product, branch)`.
- **Every** qty change inserts a `stock_movements` row (type, qty before/after, ref table/id, user, reason). Enforced by DB trigger; clients cannot `UPDATE inventories` directly (§82).
- Movement types: `sale`, `sale_return`, `purchase`, `adjustment`, `count_correction`, `transfer_in`, `transfer_out`, `opening`.
- Negative stock allowed only if business setting `allow_negative_stock = true` (default false). Sale functions raise `INSUFFICIENT_STOCK` otherwise.
- Batch/expiry (FEFO) when `track_batch = true`; `complete_sale` consumes nearest-expiry batch first.

---

## 9. Weighted Average Cost (WAC)
See §55 for the authoritative calculation and its reporting surface.

---

## 10. Sales (POS) Flow
1. Open shift (required before any sale; else `SHIFT_NOT_OPEN`).
2. Scan/search products → cart (local cache first, server fallback).
3. Line discount / cart discount / price override (permission `pricing.override`).
4. Customer optional (guest supported); loyalty points accrue when applicable.
5. Payment: cash, card, mobile wallet, mixed (split). Change computed server-side.
6. `complete_sale` RPC (transactional, idempotent via `idempotency_key`) decrements stock, writes movements, writes `sale_items` snapshotting price/cost/tax at sale time.
7. Receipt rendered (ESC/POS + PDF fallback), printable/shareable.
8. Held carts persist locally and per-user; resume restores exactly.

Backend error codes raised: `SHIFT_NOT_OPEN`, `INSUFFICIENT_STOCK`, `INVALID_DISCOUNT`, `PRICE_OVERRIDE_FORBIDDEN`, `PRODUCT_NOT_FOUND`, `DUPLICATE_IDEMPOTENCY_KEY`, `NEGATIVE_TOTAL`, `CART_EMPTY`.

---

## 11. Returns, Refunds & Cancellations
- Completed sales are never deleted. `cancel_sale` (pre-completion void) and `return_sale` (post-sale return) both require a reason, restore stock (+movement), and write an audit row.
- Large refunds (`refund.large` permission threshold, configurable) need manager approval.
- Returns reference the original sale; partial returns supported at item level.

---

## 12. Purchases & Suppliers
- PO → approve → receive (`receive_purchase` updates stock + WAC, §55) → bill → pay supplier.
- Supplier payments tracked per bill with running balance.
- Purchase history stores historical cost per item.

---

## 13. Stock Adjustments, Counts & Transfers
- Adjustment: reason-coded manual fix, permission `inventory.adjust`.
- Stock count: start → enter counted qty per item → submit → approve/reconcile; discrepancies create `count_correction` movements.
- Transfer: branch A → branch B, two-step (out then in), in-transit visibility, permission `inventory.transfer`.

---

## 14. Shifts & Cash Drawer
- `open_shift` (opening float) → record cash movements (sale, refund, drawer-in, drawer-out) → `close_shift` computes expected vs counted, variance reason required if outside tolerance.
- Reports and day-close (X-report/Z-report) derive from shift data.

---

## 15. Customers & Loyalty
- Customers per business with phone/email search; guest checkout allowed.
- Loyalty: points per currency unit spent, configurable earn/redeem rates; redemption is a transactional RPC (`redeem_loyalty_points`) that fails with `INSUFFICIENT_POINTS` if short.

---

## 16. Promotions
- Types: percentage off, fixed amount off, buy-X-get-Y, price-per-unit deal.
- Time-bounded, product/category scoped, stackable flag. Applied via `apply_promotion` inside `complete_sale` (never client-side only).

---

## 17. Expenses
- Expense categories seeded by system, editable per business. Expenses belong to a branch + shift (optional) and feed the profit report (§51).

---

## 18. Employees & Auth
- Sign-up creates `auth.users`; trigger creates `profiles`. First-launch onboarding runs `create_business_with_owner` (business + branch + owner role assignment in one transaction).
- Staff invitation/creation happens server-side (Edge Function, service role only).
- Sensitive profile/role changes are audit-logged (§57).

---

## 19. Notifications
- Generated in-DB: low stock (qty ≤ reorder level), out of stock, expiry within N days, shift variance, failed sync (client-side).
- In-app inbox with read/unread; optional push later (out of scope v1).

---

## 20. Import / Export
- Product import: CSV/XLSX upload → Edge Function validation → row-level error report → preview → confirm (all-or-nothing per chunk).
- Exports: products, sales, stock, customers, audit → CSV/XLSX/PDF.

---

## 21. Printing
- Receipts: ESC/POS over Bluetooth/USB/network via `esc_pos`-family package; PDF fallback via `pdf` + `printing`.
- Barcode labels: product name + barcode + price, N copies, 50×25 mm default template.
- Hardware setup/testing documented in `docs/HARDWARE.md`.

---

## 22. Security Rules (summary; details §56–§58)
- `service_role`/secret keys never ship in Flutter. Publishable URL+anon key via `--dart-define` (or `.env` for tooling), gitignored.
- All authorization decisions live in Postgres (RLS + RPC permission checks).

---

## 23. Error Handling
- Backend raises exceptions with stable `errcode` (§81). Flutter maps every code to a localized friendly message (§100); raw messages are never shown.

---

## 24. Pagination
All list endpoints are keyset/offset paginated (default 50, max 200 per page): products, sales, movements, customers, suppliers, POs, audit logs, notifications, transfers, counts.

---

## 25. Performance Budgets
- Scan → cart: < 500 ms (local cache), < 1.2 s (server fallback).
- Dashboard first paint: < 1.5 s from RPC.
- POS must remain usable with 10k+ products and 100k+ sales.

---

## 26. Concurrency
- `SELECT … FOR UPDATE` on `inventories` rows inside all stock-mutating RPCs.
- Idempotent `complete_sale` keyed by client `idempotency_key` (UUID) — offline retries never double-sell.

---

## 27. Audit Logging
- Sensitive tables (products price, roles, settings, sales cancel/return, adjustments) write to `audit_logs`: actor, action, table, row id, before/after JSONB, ip/app version, timestamp.

---

## 28. Accessibility & UX
- Min tap target 48 dp (POS primary actions ≥ 56 dp), visible focus states, WCAG-AA contrast, confirmation dialogs for destructive/sensitive actions, screen-reader labels on POS controls.

---

## 29. Localization
- All user-facing strings via ARB (`flutter gen-l10n`). Ship `en` now; structure is Urdu-ready (`ur` RTL). Currency/date via `intl` + business settings.

---

## 30. Settings (per business)
Store profile, logo, currency, timezone, tax rates (inclusive/exclusive), receipt footer/size, loyalty rates, refund threshold, negative-stock policy, invoice numbering prefixes, barcode format defaults.

---

## 31. Dashboard Requirements
Owner/manager see today vs yesterday: revenue, transactions, gross profit, low-stock count, top products. Cashier sees shift summary only. Data comes from aggregation RPCs only — never raw row downloads (§49).

---

## 32–48. Feature Modules (summary)

- **§32 Home/Dashboard shell:** adaptive navigation (bottom bar phone, rail tablet, sidebar desktop), global search, notifications bell.
- **§33 POS module:** §10, §11, hardware scanner capture, camera scanner (`mobile_scanner`: EAN-13, EAN-8, UPC-A, UPC-E, Code128, Code39), keyboard shortcuts (F2 search, F4 pay, F8 hold, F9 customer, Esc clear) on desktop.
- **§34 Catalog module:** §6, §7; list with search (trigram), filters, pagination, bulk archive.
- **§35 Inventory module:** §8, §13; on-hand, batches, movement timeline per product.
- **§36 Purchasing module:** §12.
- **§37 Customers module:** §15.
- **§38 Promotions module:** §16.
- **§39 Shifts module:** §14.
- **§40 Expenses module:** §17.
- **§41 Employees module:** §18, roles editor (§67).
- **§42 Reports module:** §49–55.
- **§43 Settings module:** §30, business setup wizard (§65 onboarding RPC).
- **§44 Import/Export module:** §20.
- **§45 Printing module:** §21.
- **§46 Notifications module:** §19.
- **§47 Sync module (client):** §61–62; visible sync chip + failed-queue screen with manual retry.
- **§48 Audit module:** audit log viewer, paginated, permission `audit.view`.

---

## 49. Reports & Dashboard — Overview
All reports: permission-gated, date-range + branch filters, server-side aggregation RPC/views, paginated detail drill-down, CSV/XLSX/PDF export. Never load raw rows into the client.

| # | Report | Key RPC/view | Permission |
|---|---|---|---|
| 49 | Dashboard KPIs | `dashboard_kpis(from,to,branch)` | `reports.dashboard.view` |
| 50 | Sales report | `report_sales(...)` | `reports.sales.view` |
| 51 | Profit & loss | `report_profit(...)` | `reports.profit.view` |
| 52 | Inventory report | `report_inventory(...)` | `reports.inventory.view` |
| 53 | Purchases & suppliers | `report_purchases(...)` | `reports.purchases.view` |
| 54 | Cash & shifts | `report_cash(...)` | `reports.cash.view` |
| 55 | Costing & margins | `report_costing(...)` | `reports.profit.view` |

Cashiers have access to none of the above except their own shift summary (`reports.shift.self`).

---

## 50. Sales Report
Grouping: day/hour, branch, cashier, category, product. Metrics: gross sales, discounts, net sales, tax collected, tender type split, returns, voids, basket size, items/txn.

---

## 51. Profit & Loss
Revenue − COGS − refunds − expenses = operating profit, per period/branch. COGS comes from `sale_items.cost_at_sale` snapshot (§76) — never current purchase price.

---

## 52. Inventory Report
On-hand qty/value at cost, retail value, margin, dead stock (no sale in N days), low-stock & out-of-stock lists, stock ageing, movement audit by product.

---

## 53. Purchases & Suppliers
Purchases by period/supplier/category, unpaid bills, supplier ageing (30/60/90), receiving lead time.

---

## 54. Cash & Shifts
Cash expected vs counted, drawer movements, variance history, per-cashier sales totals.

---

## 55. Costing & Margins (weighted-average cost)
Authoritative WAC rule, applied by `receive_purchase` inside its transaction:

```
new_wac = ((on_hand * old_wac) + (received_qty * received_unit_cost)) / (on_hand + received_qty)
```
- Computed per `(product, branch)`; `on_hand` and `wac` are locked with `SELECT … FOR UPDATE`.
- If `on_hand + received_qty = 0`, WAC becomes `received_unit_cost`.
- Negative/zero on-hand at receiving: WAC resets to `received_unit_cost` (documented edge case).
- `sale_items.cost_at_sale` snapshots WAC at sale time (§76) so historical profit never drifts.
- This report exposes WAC history, current margin per product/category, and margin trend; alerts fire on margin < configured floor.

---

## 56. Security & Secrets
- Publishable Supabase URL + anon key only in the client, via `--dart-define=SUPABASE_URL / SUPABASE_ANON_KEY` (fallback constants allowed in dev, must be removed before release). `.env` gitignored.
- `service_role` key exists only in Edge Functions/secrets.
- Postgres roles: `authenticated`, `anon`, `service_role` only.

---

## 57. Audit & Compliance
§27 + retention: audit logs kept ≥ 2 years; sales/financial rows never hard-deleted.

---

## 58. Backup
Supabase PITR (configured in dashboard); migrations + `seed.sql` reproduce schema; documented restore drill in `README.md`.

---

## 59. API Conventions
- Read: PostgrestSelect with RLS. Write/business logic: RPC only (§82).
- RPC naming: verb_noun; params JSONB or named args; returns JSONB `{ok, data, error:{code,message,details}}` or raises with `RAISE EXCEPTION USING ERRCODE`.
- Timestamps `timestamptz` UTC; client converts to business timezone.

---

## 60. Error Response Shape
```json
{ "ok": false, "error": { "code": "INSUFFICIENT_STOCK", "message": "…", "details": { "product_id": "…" } } }
```
Full code list: `docs/ERROR_CODES.md` (generated from §81).

---

## 61. Offline POS — Design
- Drift (SQLite) tables: `cached_products` (name, sku, barcode, prices, tax, unit, is_weight_based, updated_at), `cached_customers`, `cached_stock` (soft, advisory), `pending_sales`, `held_carts`, `sync_meta`.
- POS reads: exact barcode → exact SKU → name/brand partial **in Drift first**, server fallback; results merge into cache.
- All sales taken offline are written to `pending_sales` with client UUID `idempotency_key`, full cart snapshot, and state.
- Queue states: `pending → syncing → synced | failed`. Retry: exponential backoff (1s, 2s, 4s, … cap 5 min) + manual retry. Requires connectivity + open-shift awareness; offline sales attribute to the shift open at sale time.
- App must remain sellable when server is unreachable; banner shows queue depth.

---

## 62. Sync — Conflict Policy
- **Sales:** exactly-once via `idempotency_key`; server returns `DUPLICATE_IDEMPOTENCY_KEY` treated as success (already synced).
- **Product/price cache:** last-write-wins by `updated_at` (server wins on tie); full refresh on login and every 15 min.
- **Stock:** never merged client-side — local stock is advisory; server stock is authoritative.
- **Held carts:** per-device only (no conflict surface).
- Full design + state diagram: `docs/SYNC.md`.

---

## 63. Realtime
Enabled only for: notifications table (per-user channel), POS stock-change invalidation (`stock_movements` inserts for current branch). Nothing else subscribes.

---

## 64. Storage Buckets & Policies
`product-images`, `business-assets`, `receipts`, `imports` — all private, path-scoped `business_id/…`, write limited to authenticated members of that business (storage RLS mirrors §67 helpers).

---

## 65. Database — Businesses, Branches, Onboarding
Tables: `businesses`, `branches`.
- `businesses`: id, name, legal_name, phone, email, address, currency(3), timezone, logo_url, settings JSONB, `created_at/updated_at`, `deleted_at`.
- `branches`: id, business_id FK RESTRICT, name, address, phone, is_active, `created_at/updated_at`.
- RPC `create_business_with_owner(owner_auth_id, business_json, branch_json)` — one transaction: insert business, main branch, link profile, assign `owner` role; returns ids. Only callable pre-onboarding (profile without business).

---

## 66. Database — Profiles & Employees
Table `profiles`: id (= auth.users.id, FK CASCADE), business_id FK RESTRICT NULL until onboarding, branch_id FK SET NULL, name, phone, avatar_url, status (`active/suspended`), last_login_at, timestamps.
- Trigger on `auth.users` insert → create `profiles` (name from signup metadata).
- RPC `invite_staff`, `set_staff_status` (service-role Edge Function wraps).

---

## 67. Database — RBAC
Tables: `permissions` (key TEXT PK e.g. `products.create`, `sales.cancel`, `pricing.override`, `reports.profit.view`, `inventory.adjust`, `refund.large`, `audit.view`, `settings.manage`, `roles.manage`, `staff.manage`, `pos.sell`, …), `roles` (business_id, key, name, is_system), `role_permissions` (role, permission), `profile_roles` (profile, role).
- Seeded by `seed.sql` (system data, stable keys — never renamed).
- Helper `has_permission(perm_key TEXT) RETURNS boolean` — `security definer`, fixed `search_path`, checks *any* assigned role of `auth.uid()`.
- Helper `current_business_id()`, `current_branch_id()` — same constraints.
- Default templates: `owner` (all), `manager` (all except `roles.manage`), `cashier` (`pos.sell`, `sales.void` limited, `customers.create`, `reports.shift.self`), `stocker` (`inventory.*`), `viewer` (read reports).

---

## 68. Database — Categories, Brands, Units
`categories`, `brands`: id, business_id, name, status, timestamps; unique `(business_id, lower(name))`.
`units`: id, business_id NULL for system units, key, name, decimals_allowed.

---

## 69. Database — Suppliers
`suppliers`: business_id, name, contact person, phone, email, address, opening balance, status, timestamps. Financial history FKs RESTRICT.

---

## 70. Database — Customers & Loyalty
`customers`: business_id, name, phone, email, loyalty_points numeric(14,2), credit_limit, status, timestamps; unique phone per business.
`loyalty_transactions`: customer_id, sale_id NULL, type (`earn/redeem/adjust`), points, balance_after, created_by.

---

## 71. Database — Products & Barcodes
`products`: business_id, name, sku, barcode, category_id, brand_id, unit_id, purchase_price numeric(14,2), selling_price numeric(14,2), tax_rate numeric(6,3), is_weight_based bool, track_batch bool, reorder_level numeric(14,3), image_url, description, status, deleted_at, timestamps.
`product_barcodes`: product_id, barcode, format — supports multi-barcode; unique per business.
Constraints: `CHECK (purchase_price >= 0 AND selling_price >= 0)`, unique `(business_id, sku)`, unique `(business_id, barcode)` where barcode not null.

---

## 72. Database — Price History
`price_history`: product_id, old_price numeric(14,2), new_price numeric(14,2), changed_by, reason, created_at. Filled by trigger on `products.selling_price` update.

---

## 73. Database — Inventories & Batches
`inventories`: product_id, branch_id, on_hand numeric(14,3), reserved numeric(14,3), wac numeric(14,4), updated_at; PK `(product_id, branch_id)`; `CHECK (on_hand >= -999999)`.
`product_batches`: id, inventory ref (product+branch), batch_no, expiry_date, qty numeric(14,3), received_at.
**No client UPDATE/INSERT allowed — trigger raises `RAISE EXCEPTION 'USE_RPC'`.**

---

## 74. Database — Stock Movements
`stock_movements`: id, business_id, branch_id, product_id, movement_type (enum via CHECK), qty_delta numeric(14,3), qty_before, qty_after, ref_table, ref_id, reason, created_by, created_at.
Indexes on `(product_id, created_at DESC)`, `(branch_id, created_at DESC)`, `(ref_table, ref_id)`.
FK RESTRICT to financial rows.

---

## 75. Database — Sales
`sales`: id, business_id, branch_id, invoice_no (unique per business/branch, via `generate_invoice_number`), shift_id, cashier_id, customer_id NULL, subtotal, discount_total, tax_total, grand_total, amount_paid, change_due, status (`completed/returned/partially_returned/cancelled`), idempotency_key unique, sold_at, created_at.
`sale_payments`: sale_id, method (`cash/card/mobile_wallet/other`), amount numeric(14,2), reference.

---

## 76. Database — Sale Items (historical snapshot)
`sale_items`: sale_id, product_id, name_snapshot, sku_snapshot, barcode_snapshot, qty numeric(14,3), unit_price, cost_at_sale numeric(14,4) ← WAC snapshot (§55), discount, tax_rate, tax_amount, line_total, batch_id NULL.
Immutable after insert (trigger blocks UPDATE/DELETE on completed sales).

---

## 77. Database — Purchases
`purchase_orders`, `purchase_order_items`, `purchases` (bills), `purchase_items` (cost snapshots), `supplier_payments`. Statuses: draft → approved → received → paid (partial allowed). All transitions via RPCs (§82).

---

## 78. Database — Shifts & Cash
`shifts`: id, business_id, branch_id, opened_by, closed_by, opening_float, closing_counted, expected_cash, variance, status (`open/closed`), opened_at, closed_at.
`cash_movements`: shift_id, type (`sale/refund/drawer_in/drawer_out/float`), amount, note, created_by, created_at.
One open shift per user per branch (partial unique index).

---

## 79. Database — Expenses & Adjustments & Counts & Transfers
- `expense_categories`, `expenses` (branch_id, shift_id NULL, amount, receipt_url, note).
- `inventory_adjustments` (+ implied movements).
- `stock_counts`, `stock_count_items` (system_qty, counted_qty, delta).
- `stock_transfers`, `stock_transfer_items` (status in_transit/received/cancelled).

---

## 80. Database — Support Tables
`invoice_sequences` (business, branch, kind, next_value, prefix), `notifications`, `audit_logs`, `price_history` (§72), `loyalty_transactions` (§70), `imports` (upload metadata + row errors), `sync_log`/idempotency audit (server-side record of processed `idempotency_key`s), `settings` mirror if split out of `businesses.settings`.

---

## 81. Error Codes (canonical list)
`UNAUTHENTICATED`, `NO_BUSINESS`, `NO_PERMISSION`, `SHIFT_NOT_OPEN`, `SHIFT_ALREADY_OPEN`, `INSUFFICIENT_STOCK`, `NEGATIVE_STOCK_NOT_ALLOWED`, `INVALID_DISCOUNT`, `PRICE_OVERRIDE_FORBIDDEN`, `PRODUCT_NOT_FOUND`, `PRODUCT_INACTIVE`, `CART_EMPTY`, `NEGATIVE_TOTAL`, `DUPLICATE_IDEMPOTENCY_KEY`, `DUPLICATE_BARCODE`, `DUPLICATE_SKU`, `INVALID_INVOICE_SEQUENCE`, `INSUFFICIENT_POINTS`, `REFUND_NEEDS_APPROVAL`, `COUNT_ALREADY_APPROVED`, `TRANSFER_NOT_IN_TRANSIT`, `PO_NOT_APPROVED`, `SUPPLIER_HAS_OPEN_BILLS`, `USE_RPC`, `VALIDATION_FAILED`, `INTERNAL_ERROR`.
Every code → localized UI message in `docs/ERROR_CODES.md` + `lib/core/errors/`.

---

## 82. RPC Catalog (transactional, permission-checked, audit-logged)
`complete_sale`, `cancel_sale`, `return_sale`, `adjust_stock`, `receive_purchase`, `create_purchase_order`, `approve_purchase_order`, `pay_supplier`, `open_shift`, `close_shift`, `record_cash_movement`, `transfer_stock`, `start_stock_count`, `submit_stock_count`, `approve_stock_count`, `calculate_product_price`, `apply_promotion`, `redeem_loyalty_points`, `generate_invoice_number`, `create_business_with_owner`, plus reporting RPCs (§49–55).
Conventions: `SECURITY DEFINER`, `SET search_path = public, pg_temp`, row locks per §26, permission check via §67 helper, `RAISE EXCEPTION … USING ERRCODE/MESSAGE`, audit rows (§27) where required.

---

## 83. Edge Functions (Deno/TS)
`import-products` (validate + commit), `export-file` (signed URL), `staff-invite` (service role), optional `receipt-pdf`. Never put business rules here that belong in Postgres.

---

## 84. Scheduled Jobs (pg_cron)
Low-stock scan (hourly), expiry alerts (daily 08:00 business TZ approximation), stale `imports` cleanup (daily), session/`sync_log` pruning (weekly).

---

## 85. Flutter Project Structure (exact)
```
lib/
├── main.dart
├── app.dart                       # MaterialApp.router, providers, l10n
├── core/
│   ├── config/app_config.dart     # --dart-define readers
│   ├── errors/                    # error_codes.dart, app_exception.dart, messages_en.arb
│   ├── router/app_router.dart     # GoRouter + auth/role guards
│   ├── theme/                     # colors, typography, component themes (light+dark)
│   ├── l10n/                      # ARB files + generated
│   ├── utils/                     # money (Decimal), validators, barcode utils
│   └── network/                   # supabase provider, retry, timeout
├── data/
│   ├── models/                    # freezed/json_serializable models, Decimal money
│   ├── repositories/              # one repository per domain (cart, products, sales…)
│   └── local/                     # Drift db, tables, daos, sync queue
├── features/
│   ├── auth/        (screens/, providers/, …)
│   ├── setup/       # business setup wizard
│   ├── dashboard/
│   ├── pos/         # terminal, cart, payment, held carts, scanner input
│   ├── products/
│   ├── inventory/   # stock, adjustments, counts, transfers, batches
│   ├── purchases/
│   ├── customers/
│   ├── promotions/
│   ├── shifts/
│   ├── expenses/
│   ├── employees/
│   ├── reports/
│   ├── notifications/
│   ├── settings/
│   ├── import_export/
│   └── sync/        # sync status, failed queue UI
└── l10n/            # app_en.arb, app_ur.arb
supabase/
├── config.toml
├── migrations/      # NNNN_description.sql (timestamped, ordered, idempotent-safe)
├── functions/
├── tests/           # pgTAP: test_rls.sql, test_sale_rpc.sql, …
└── seed.sql
docs/                # ARCHITECTURE, ERROR_CODES, SYNC, PERMISSIONS, HARDWARE
test/                # unit/ widget/ integration/ mirroring lib/
```

---

## 86. Screen Inventory (67 screens)

| # | Screen | # | Screen |
|---|---|---|---|
| 1 | Splash | 35 | Batch/Expiry view |
| 2 | Login | 36 | Purchase order list |
| 3 | Register | 37 | Purchase order form |
| 4 | Forgot password | 38 | Goods receive (PO) |
| 5 | Business setup wizard | 39 | Supplier list |
| 6 | Dashboard | 40 | Supplier detail |
| 7 | Global search | 41 | Supplier form |
| 8 | Notifications inbox | 42 | Purchase bills list |
| 9 | My profile | 43 | Customer list |
| 10 | POS terminal | 44 | Customer detail |
| 11 | POS product search | 45 | Customer form |
| 12 | Cart line editor | 46 | Loyalty transactions view |
| 13 | Customer picker (POS) | 47 | Sales history |
| 14 | Price/discount override sheet | 48 | Sale detail |
| 15 | Payment (split) | 49 | Return/refund form |
| 16 | Receipt preview | 50 | Open shift |
| 17 | Held carts list | 51 | Close shift (X/Z report) |
| 18 | Camera scanner | 52 | Cash movements (drawer) |
| 19 | Product list | 53 | Shift history |
| 20 | Product detail | 54 | Expense list |
| 21 | Add product | 55 | Expense form |
| 22 | Edit product | 56 | Expense categories manager |
| 23 | Category list | 57 | Promotion list |
| 24 | Category form | 58 | Promotion form |
| 25 | Brand list | 59 | Reports hub |
| 26 | Brand form | 60 | Sales report |
| 27 | Audit log | 61 | Profit report |
| 28 | Inventory list (on-hand) | 62 | Inventory report |
| 29 | Product stock detail | 63 | Purchases/suppliers report |
| 30 | Stock adjustment form | 64 | Cash/shifts report |
| 31 | Stock count list | 65 | Employees & roles admin |
| 32 | Stock count entry | 66 | Settings (business/tax/receipt) |
| 33 | Stock transfer list | 67 | Import/Export center |
| 34 | Stock transfer form | | |

---

## 87. Flutter Layers (strict)
`Widget → Provider (Riverpod Notifier) → Repository → Supabase datasource / Drift DAO`.
- No `Supabase` calls inside widgets. Providers own loading/error state; repositories own queries; models are immutable (freezed), money as `Decimal` (package `decimal`), quantities as `Decimal` too.
- Every list screen: search + filters + pagination + pull-to-refresh + empty + error-with-retry + loading skeleton.

---

## 88. Responsive & POS UX Rules
- Breakpoints: phone < 600, tablet 600–1024, desktop ≥ 1024.
- POS layout: catalog/search left (or toggle), cart right; landscape-first; number pad for qty on touch.
- Scanner input: focused hidden field, keystroke debounce 40 ms, min length 3, Enter terminates; duplicates within 300 ms ignored.
- Shortcuts (desktop): F2 search, F4 pay, F8 hold, F9 customer, F10 reports, Esc clear dialog.
- Destructive actions confirm twice (dialog + typed reason where §27 applies).

---

## 89. Theme
Material 3, light+dark, seed color teal (existing brand), dynamic color off for brand consistency; component themes in `core/theme/`; no inline magic colors in features.

---

## 90. Localization
`flutter gen-l10n`, ARB in `l10n/`, `app_en.arb` complete; placeholders for currency/numbers via `intl`. `ur` scaffolded but incomplete is acceptable in v1 (structure must be Urdu-ready).

---

## 91. Accessibility
Per §28; enforced in code review + widget tests (semantics labels on POS cart actions).

---

## 92. Database Indexes
Required (plus composites discovered by `EXPLAIN` during sprints):
- `products`: `business_id`, trigram GIN on `name` (`pg_trgm`), unique `(business_id, sku)`, unique `(business_id, barcode)`, `(category_id)`, `(status)` partial where active.
- `inventories`: PK `(product_id, branch_id)`, `(branch_id)`.
- `stock_movements`: `(product_id, created_at DESC)`, `(branch_id, created_at DESC)`, `(movement_type, created_at DESC)`, `(ref_table, ref_id)`.
- `sales`: `(business_id, sold_at DESC)`, `(branch_id, sold_at DESC)`, `(cashier_id, sold_at DESC)`, `(status)`, unique `idempotency_key`, unique `(business_id, branch_id, invoice_no)`.
- `sale_items`: `(sale_id)`, `(product_id)`.
- `audit_logs`: `(business_id, created_at DESC)`, `(table_name, row_id)`.
- `notifications`: `(user_id, created_at DESC)` partial where unread.
- `shifts`: partial unique `(branch_id, opened_by) WHERE status='open'`.
- `customers`: `(business_id, phone)`, `(business_id, lower(name))`.
- FK columns generally indexed; every FK in the schema gets an index (verified in migration review).

---

## 93. Edge Function Contracts
See §83. Each function: validates JWT, resolves `business_id` from claims, inputs via zod-style validation, returns `{ok,data,error}` shape (§60).

---

## 94. Cron & Cleanup
See §84.

---

## 95. Environments
`local` (Docker), `staging`, `prod`. Migrations apply in order on empty DB from zero (`supabase db reset` proof required each sprint).

---

## 96. Flutter Tests
- Unit: money/tax/discount math (Decimal), cart logic, EAN-13 check digit, sync queue state machine, error-code mapping, WAC client formatting.
- Widget: POS cart flow, login/role redirects, product form validation, list empty/error states.
- Integration: login → open shift → scan → pay → receipt → stock decreased → close shift.

---

## 97. Backend Tests (pgTAP)
RLS isolation between two businesses; cashier cannot read `purchase_price`; `complete_sale` happy path + insufficient stock + no open shift + duplicate idempotency; return restores stock; cancel reverses stock; concurrent sale race; every stock mutation writes a movement; WAC math (§55); permission denial matrix for §82 RPCs.

---

## 98. Observability
Edge function logs + Supabase logs; client errors to console in dev; `sync_log` for queue forensics. No third-party analytics in v1.

---

## 99. Deployment
Flutter web build → static host; Android APK/AAB; Supabase prod project with migrations CI. Steps in `README.md`.

---

## 100. Documentation Deliverables
`README.md`, `docs/ARCHITECTURE.md`, `docs/ERROR_CODES.md`, `docs/SYNC.md`, `docs/PERMISSIONS.md`, `docs/HARDWARE.md`.

---

## 101. Observability & Support (stub)
Support runbook lives in docs; expand as sprints land.

---

## 102. Data Import Guarantees
Chunked commit, row-level errors preserved for download, idempotent re-upload of same file (hash check).

---

## 103. Hardware Support Matrix
Scanners: any USB/Bluetooth HID keyboard-wedge; camera via `mobile_scanner`. Printers: ESC/POS 58/80 mm Bluetooth + USB + network; label printers 50×25 mm. Tested models listed in `docs/HARDWARE.md`.

---

## 104. Barcode Generation
- EAN-13: 12 digits + computed check digit (mod-10); prefix from business-reserved range to guarantee uniqueness per business.
- Code128 fallback for internal SKUs.
- Validation on entry: format + check digit + per-business uniqueness (DB unique constraint is the final guard).
- Label layout: name (top), barcode, price; N copies per product.

---

## 105. Versioning & Releases
SemVer app version in `pubspec.yaml`; migrations never edited after apply (forward-fix only); release checklist = §108.

---

## 106. Definition of Done — Product Features
A feature is done only when:
- ✅ UI → provider → repository → Supabase → DB → UI works end-to-end with **real data**.
- ✅ Loading, empty, error+retry states exist on every screen touching data.
- ✅ Permission enforced in DB (RLS/RPC), not just hidden in UI.
- ✅ Money via `Decimal`; quantities via `Decimal`.
- ✅ Pagination on lists (§24).
- ✅ Localized strings (no hard-coded user-facing text).
- ✅ Unit/widget tests for the logic added (§96).
- ✅ No TODO/mock/UnimplementedError left behind.

---

## 107. Definition of Done — Backend & Data
- ✅ Migrations apply cleanly from zero (`supabase db reset`).
- ✅ RLS on every `public` table; two-business isolation test passes (pgTAP).
- ✅ Cashier cannot read cost/profit/suppliers — proven at DB level (pgTAP) **and** UI level.
- ✅ Every stock change produces exactly one `stock_movements` row (trigger + tests).
- ✅ All §82 RPCs permission-checked, audited where required, error-coded per §81.
- ✅ `supabase test db` green; seed idempotent.
- ✅ No secret/service_role key in client code or repo.

---

## 108. Definition of Done — Release
- ✅ `flutter analyze` = 0 issues; `flutter test` green; pgTAP green; migrations from empty DB green.
- ✅ All 67 screens (§86) reachable and functional with real data.
- ✅ Offline sale syncs exactly once after repeated retries (test).
- ✅ Grep clean: no `TODO`, `FIXME`, mock data, dead commented code.
- ✅ Docs (§100) match reality.
- ✅ Final report: what exists, what was tested, known limitations, manual hardware tests remaining (§103).

---

## 109. Sprint Plan (order is mandatory)

| Sprint | Scope | Depends on |
|---|---|---|
| **1** | Foundation: repo hygiene, AppConfig (`--dart-define`), theme, router with auth+role guards, error-code layer, Supabase local init, migrations for §65–66 + profiles trigger + RBAC §67, RLS baseline, `create_business_with_owner`, auth/onboarding screens wired end-to-end, `flutter analyze`/`test` green, CI workflow | — |
| **2** | Catalog: products/categories/brands/units CRUD (§68, §71, §72), barcode generation (§104), image upload (§64), product list screens with search/pagination, import skeleton | 1 |
| **3** | Inventory core: inventories + movements + trigger guard (§73–74), adjustments, counts, transfers, adjust/count/transfer RPCs, inventory screens | 2 |
| **4** | POS: shifts (§78), pricing RPCs, `complete_sale`/`cancel_sale`/`return_sale` (§75–76), idempotency, split payments, receipt print/PDF (§21), POS screen + scanner input + shortcuts, sales history | 3 |
| **5** | Purchasing: PO→receive→pay (§77), WAC (§55), suppliers (§69), receiving & supplier screens | 3 |
| **6** | Customers/loyalty/promotions/expenses (§70, §16, §17) + their screens | 4 |
| **7** | Reports & dashboard (§49–55), charts, exports, notifications (§19) | 4–6 |
| **8** | Offline POS: Drift cache + sync engine + conflict policy + sync UI (§61–62), failed-queue screen | 4 |
| **9** | Import/Export (§20), audit viewer, roles admin UI, printing polish, hardware docs, perf passes, full test matrix, docs, release checklist (§108) | 7–8 |

Sprint gate (after each): `flutter analyze` 0, `flutter test` green, `supabase db reset` clean, `supabase test db` green, §106–108 checklist printed with ✅/❌ + evidence, conventional commit, report, **wait for owner's "continue"**.
