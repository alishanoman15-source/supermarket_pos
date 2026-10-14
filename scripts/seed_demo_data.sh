#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# seed_demo_data.sh — seeds a full demo dataset on the LINKED project so the
# backend can be exercised with real rows (SPEC §111: POS + inventory +
# purchases behaving as one connected system).
#
#   ./scripts/seed_demo_data.sh
#
# It creates (idempotently — safe to run twice):
#   * auth user        qa-bot@test.local / QaBot!Pass123  (owner of the demo)
#   * business         QA Demo Mart  (Main Branch) via create_business_with_owner
#   * catalogue        3 categories, 3 brands, 3 units, 8 products (EAN-13)
#   * parties          1 supplier, 1 customer
#   * stock            opening stock through adjust_stock (movement per product)
#   * purchasing       PO for 50 kg rice → approve → receive (stock +50, WAC)
#   * POS              open shift, one completed sale (split-ready cart),
#                      one partial return, one cash-out
#   * finance          one expense
#
# Every write goes through the same RPCs the Flutter app calls, as the QA
# owner (RLS + permissions included), so a green run means the app's own
# write paths work. It ends with a summary of what landed in the database.
# ---------------------------------------------------------------------------
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

./scripts/sql.sh <<'SQL'
begin;

-- ---------------------------------------------------------------------------
-- 1. QA auth user (password login must work for the live smoke test)
-- ---------------------------------------------------------------------------
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values (
  '11111111-1111-4111-8111-111111111111', '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'qa-bot@test.local',
  crypt('QaBot!Pass123', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{"full_name":"QA Bot"}')
on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, provider, provider_id, identity_data,
  last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), u.id, 'email', u.id::text,
       jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
       now(), now(), now()
  from auth.users u
 where u.email = 'qa-bot@test.local'
   and not exists (select 1 from auth.identities i
                    where i.user_id = u.id and i.provider = 'email');

-- ---------------------------------------------------------------------------
-- 2. Business + branch + roles, through the real onboarding RPC
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
       '{"sub":"11111111-1111-4111-8111-111111111111"}', true);

do $$
begin
  if not exists (select 1 from public.profiles
                  where id = '11111111-1111-4111-8111-111111111111'
                    and business_id is not null) then
    perform public.create_business_with_owner(
      '{"name":"QA Demo Mart","currency":"PKR","phone":"0300-1234567",
        "address":"Main Bazar, Model Town","timezone":"Asia/Karachi"}'::jsonb,
      '{"name":"Main Branch","phone":"0300-1234567"}'::jsonb);
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 3. Catalogue
-- ---------------------------------------------------------------------------
insert into public.categories (business_id, name, status)
select public.current_business_id(), x.name, 'active'
  from (values ('Groceries'), ('Beverages'), ('Snacks')) as x(name)
 where not exists (select 1 from public.categories c
                    where c.business_id = public.current_business_id()
                      and c.name = x.name);

insert into public.brands (business_id, name, status)
select public.current_business_id(), x.name, 'active'
  from (values ('Nestlé'), ('PepsiCo'), ('Sunrise Mills')) as x(name)
 where not exists (select 1 from public.brands b
                    where b.business_id = public.current_business_id()
                      and b.name = x.name);

insert into public.units (business_id, key, name, abbreviation,
                          decimals_allowed, is_system, status)
select public.current_business_id(), x.key, x.name, x.abb, x.dec, false, 'active'
  from (values ('piece', 'Piece', 'pc', 0),
               ('kg',    'Kg',    'kg', 1),
               ('litre', 'Liter', 'L',  1)) as x(key, name, abb, dec)
 where not exists (select 1 from public.units u
                    where u.business_id = public.current_business_id()
                      and u.key = x.key);

insert into public.products (
  business_id, category_id, brand_id, unit_id, name, sku, barcode,
  purchase_price, selling_price, tax_rate, reorder_level, status)
select public.current_business_id(),
       (select c.id from public.categories c
         where c.business_id = public.current_business_id() and c.name = x.cat),
       (select b.id from public.brands b
         where b.business_id = public.current_business_id() and b.name = x.brand),
       (select u.id from public.units u
         where u.business_id = public.current_business_id() and u.key = x.unit),
       x.name, x.sku, x.barcode, x.cost, x.price, x.tax, x.reorder, 'active'
  from (values
    ('QA Biscuit Pack', 'QA-BISC-1',  '2000000000108', 'Snacks',    'Sunrise Mills', 'piece',  70.00, 100.00, 0, 20),
    ('QA Cola 1L',      'QA-COLA-1',  '2000000000015', 'Beverages', 'PepsiCo',       'litre',  75.00, 100.00, 0, 30),
    ('QA Dal 1kg',      'QA-DAL-1',   '2000000000022', 'Groceries', 'Sunrise Mills', 'kg',    220.00, 280.00, 0, 15),
    ('QA Flour 5kg',    'QA-FLR-5',   '2000000000039', 'Groceries', 'Sunrise Mills', 'kg',    520.00, 640.00, 0, 10),
    ('QA Oil 1L',       'QA-OIL-1',   '2000000000046', 'Groceries', 'Nestlé',        'litre', 420.00, 520.00, 5, 12),
    ('QA Rice 5kg',     'QA-RICE-5',  '2000000000053', 'Groceries', 'Sunrise Mills', 'kg',   1200.00, 1450.00, 0, 8),
    ('QA Sugar 1kg',    'QA-SUG-1',   '2000000000060', 'Groceries', 'Nestlé',        'kg',    145.00, 180.00, 0, 25),
    ('QA Tea 200g',     'QA-TEA-200', '2000000000077', 'Beverages', 'Nestlé',        'piece', 380.00, 470.00, 0, 10)
  ) as x(name, sku, barcode, cat, brand, unit, cost, price, tax, reorder)
 where not exists (select 1 from public.product_pos_view p where p.sku = x.sku);

-- ---------------------------------------------------------------------------
-- 4. Parties + expense categories
-- ---------------------------------------------------------------------------
insert into public.suppliers (
  business_id, name, contact_person, phone, email, address,
  opening_balance, status)
select public.current_business_id(), 'QA Test Supplier', 'Rafiq Khan',
       '0300-1112223', 'supplier@qa.test', 'Industrial Estate, Lahore', 0, 'active'
 where not exists (select 1 from public.suppliers s
                    where s.business_id = public.current_business_id()
                      and s.name = 'QA Test Supplier');

insert into public.customers (
  business_id, name, phone, email, address, loyalty_points, credit_limit, status)
select public.current_business_id(), 'QA Test Customer', '0321-5551234',
       'customer@qa.test', 'Gulberg III, Lahore', 0, 0, 'active'
 where not exists (select 1 from public.customers c
                    where c.business_id = public.current_business_id()
                      and c.name = 'QA Test Customer');

insert into public.expense_categories (business_id, name, is_system, status)
select public.current_business_id(), x.name, false, 'active'
  from (values ('Transportation'), ('Utilities')) as x(name)
 where not exists (select 1 from public.expense_categories e
                    where e.business_id = public.current_business_id()
                      and e.name = x.name);

-- ---------------------------------------------------------------------------
-- 5. Transactions through the real RPCs (only the first time)
-- ---------------------------------------------------------------------------
do $$
declare
  v_business uuid := public.current_business_id();
  v_branch   uuid := public.current_branch_id();
  v_supplier uuid;
  v_customer uuid;
  v_po       uuid;
  v_shift    uuid;
  v_sale     uuid;
  v_item     uuid;
begin
  if exists (select 1 from public.sales where business_id = v_business) then
    raise notice 'demo transactions already present — skipping';
    return;
  end if;

  select id into v_supplier from public.suppliers
   where business_id = v_business and name = 'QA Test Supplier';
  select id into v_customer from public.customers
   where business_id = v_business and name = 'QA Test Customer';

  -- Opening stock: one movement per product (SPEC §17).
  -- NOTE: `authenticated` has no SELECT grant on public.products (cost
  -- protection), exactly like the Flutter app — lookups go through the
  -- cost-stripped product_pos_view.
  perform public.adjust_stock(jsonb_build_object(
    'product_id', p.id, 'qty_delta', v.qty, 'reason', 'Opening stock'))
    from (values
      ('QA-BISC-1',  40), ('QA-COLA-1', 60), ('QA-DAL-1', 25), ('QA-FLR-5', 20),
      ('QA-OIL-1',    5), ('QA-RICE-5', 30), ('QA-SUG-1', 45)
    ) as v(sku, qty)
    join public.product_pos_view p on p.sku = v.sku;
  -- QA-TEA-200 is deliberately left at zero: it is the OUT-OF-_STOCK fixture,
  -- and QA-OIL-1 (5 on hand vs reorder level 12) is the LOW-STOCK fixture.

  -- Purchasing: PO → approve → receive (stock +50 kg rice, WAC).
  select (public.create_purchase_order(jsonb_build_object(
    'supplier_id', v_supplier,
    'note', 'Monthly rice restock',
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', (select id from public.product_pos_view where sku = 'QA-RICE-5'),
      'qty', 50, 'unit_cost', 1200.00)))) -> 'data' ->> 'purchase_order_id')
    into v_po;

  perform public.approve_purchase_order(v_po);

  perform public.receive_purchase(jsonb_build_object(
    'purchase_order_id', v_po,
    'note', 'Delivered in full',
    'items', jsonb_build_array(jsonb_build_object(
      'product_id', (select id from public.product_pos_view where sku = 'QA-RICE-5'),
      'qty', 50, 'unit_cost', 1200.00))));

  -- POS: open a shift (left open on purpose — the live smoke test uses it).
  select (public.open_shift(jsonb_build_object(
    'branch_id', v_branch, 'opening_float', 20000)) -> 'data' ->> 'shift_id')
    into v_shift;

  -- One completed sale: 3 biscuits + 1 rice bag, paid in cash.
  select (public.complete_sale(jsonb_build_object(
    'branch_id', v_branch,
    'shift_id', v_shift,
    'idempotency_key', 'demo-sale-0001',
    'customer_id', v_customer,
    'items', jsonb_build_array(
      jsonb_build_object('product_id', (select id from public.product_pos_view
                                where sku = 'QA-BISC-1'),
                         'qty', 3),
      jsonb_build_object('product_id', (select id from public.product_pos_view
                                where sku = 'QA-RICE-5'),
                         'qty', 1)),
    'payments', jsonb_build_array(
      jsonb_build_object('method', 'cash', 'amount', 2000)))) -> 'data' ->> 'sale_id')
    into v_sale;

  -- Partial return: 1 biscuit back on the shelf (SPEC §42).
  select id into v_item from public.sale_items
   where sale_id = v_sale
     and product_id = (select id from public.product_pos_view where sku = 'QA-BISC-1');

  perform public.return_sale(jsonb_build_object(
    'sale_id', v_sale,
    'reason', 'Customer changed mind',
    'refund_method', 'cash',
    'items', jsonb_build_array(jsonb_build_object(
      'sale_item_id', v_item, 'qty', 1))));

  -- Cash drawer: transport expense taken out of the float.
  perform public.record_cash_movement(jsonb_build_object(
    'shift_id', v_shift, 'type', 'drawer_out', 'amount', 500,
    'note', 'Transport'));

  -- Expense row.
  insert into public.expenses (
    business_id, branch_id, category_id, amount, paid_at, payment_method,
    payee, note, status, created_by)
  select v_business, v_branch,
         (select id from public.expense_categories
           where business_id = v_business and name = 'Transportation'),
         500, now(), 'cash', 'Qureshi Transport', 'Delivery charges', 'posted',
         public.current_profile_id();
end $$;

reset role;
commit;
SQL

./scripts/sql.sh <<'SUMMARY'
-- ---------------------------------------------------------------------------
-- 6. What actually landed in the database
-- ---------------------------------------------------------------------------
with b as (select business_id as id from public.profiles
            where id = '11111111-1111-4111-8111-111111111111')
select jsonb_pretty(jsonb_build_object(
  'business',           (select name from public.businesses where id = (select id from b)),
  'branch',             (select name from public.branches where business_id = (select id from b) limit 1),
  'roles',              (select count(*) from public.roles where business_id = (select id from b)),
  'categories',         (select count(*) from public.categories where business_id = (select id from b)),
  'brands',             (select count(*) from public.brands where business_id = (select id from b)),
  'units',              (select count(*) from public.units where business_id = (select id from b)),
  'products',           (select count(*) from public.products where business_id = (select id from b)),
  'suppliers',          (select count(*) from public.suppliers where business_id = (select id from b)),
  'customers',          (select count(*) from public.customers where business_id = (select id from b)),
  'inventory_rows',     (select count(*) from public.inventories where business_id = (select id from b)),
  'stock_movements',    (select count(*) from public.stock_movements where business_id = (select id from b)),
  'stock_adjustments',  (select count(*) from public.inventory_adjustments where business_id = (select id from b)),
  'purchase_orders',    (select count(*) from public.purchase_orders where business_id = (select id from b)),
  'purchases',          (select count(*) from public.purchases where business_id = (select id from b)),
  'pos_shifts',         (select count(*) from public.pos_shifts where business_id = (select id from b)),
  'cash_movements',     (select count(*) from public.cash_movements where business_id = (select id from b)),
  'sales',              (select count(*) from public.sales where business_id = (select id from b)),
  'sale_items',         (select count(*) from public.sale_items where business_id = (select id from b)),
  'sale_payments',      (select count(*) from public.sale_payments where sale_id in (select id from public.sales where business_id = (select id from b))),
  'sale_returns',       (select count(*) from public.sale_returns where business_id = (select id from b)),
  'sale_return_items',  (select count(*) from public.sale_return_items where return_id in (select id from public.sale_returns where business_id = (select id from b))),
  'expenses',           (select count(*) from public.expenses where business_id = (select id from b)),
  'audit_logs',         (select count(*) from public.audit_logs where business_id = (select id from b)),
  'notifications',      (select count(*) from public.notifications where business_id = (select id from b)),
  'last_invoice',       (select invoice_number from public.sales where business_id = (select id from b) order by created_at desc limit 1),
  'cola_stock',         (select i.on_hand from public.inventories i join public.products p on p.id = i.product_id
                          where p.business_id = (select id from b) and p.sku = 'QA-COLA-1'),
  'rice_stock_after_po_sale_return', (select i.on_hand from public.inventories i join public.products p on p.id = i.product_id
                          where p.business_id = (select id from b) and p.sku = 'QA-RICE-5'),
  'biscuit_stock',      (select i.on_hand from public.inventories i join public.products p on p.id = i.product_id
                          where p.business_id = (select id from b) and p.sku = 'QA-BISC-1'),
  'customer_points',    (select loyalty_points from public.customers
                          where business_id = (select id from b) and name = 'QA Test Customer')
)) as seeded_state;
SUMMARY
