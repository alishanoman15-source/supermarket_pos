-- =============================================================================
-- 01_foundation_and_pos.sql — pgTAP
-- Covers SPEC §97: RLS isolation, cashier cannot read cost, complete_sale
-- happy path / insufficient stock / no shift / duplicate idempotency, stock
-- invariant (every change writes a movement), cancel restores stock.
--
-- Runs as a single transaction and rolls back, so it never leaves data behind.
-- Run locally with `supabase test db`, or against a linked project through
-- scripts/run_backend_tests.sh.
--
-- Note: product ids are carried in a session setting because `authenticated`
-- intentionally has no SELECT privilege on public.products (cost protection).
-- =============================================================================
begin;

select no_plan();

-- ---------------------------------------------------------------------------
-- Fixtures (executed as the connection role, which bypasses RLS)
-- ---------------------------------------------------------------------------
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values
  ('aaaaaaaa-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'owner-a@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Owner A"}'),
  ('aaaaaaaa-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'cashier-a@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Cashier A"}'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'owner-b@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Owner B"}');

select is((select count(*) from public.profiles
            where id in ('aaaaaaaa-0000-0000-0000-000000000001',
                         'aaaaaaaa-0000-0000-0000-000000000002',
                         'bbbbbbbb-0000-0000-0000-000000000001')),
          3::bigint, 'auth.users trigger creates a profile per user');

-- Onboard business A and business B through the real RPC.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.create_business_with_owner('{"name":"Business A","currency":"PKR"}','{"name":"Main A"}')$$,
  'owner A can onboard a business');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"bbbbbbbb-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.create_business_with_owner('{"name":"Business B","currency":"PKR"}','{"name":"Main B"}')$$,
  'owner B can onboard a business');
reset role;

select is(
  (select count(*) from public.role_permissions rp
     join public.roles r on r.id = rp.role_id
    where r.business_id = (select id from public.businesses where name = 'Business A')
      and r.key = 'owner'),
  (select count(*) from public.permissions),
  'owner role receives the full permission catalogue');

update public.profiles
   set business_id = (select id from public.businesses where name = 'Business A'),
       branch_id   = (select id from public.branches
                       where business_id = (select id from public.businesses where name = 'Business A')
                       limit 1),
       role_id     = (select id from public.roles
                       where business_id = (select id from public.businesses where name = 'Business A')
                         and key = 'cashier')
 where id = 'aaaaaaaa-0000-0000-0000-000000000002';

-- ---------------------------------------------------------------------------
-- RLS isolation between two businesses (SPEC §107)
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}', true);
select is(public.current_business_id(),
   (select id from public.businesses where name = 'Business A'),
   'current_business_id resolves owner A');
select is((select count(*) from public.businesses), 1::bigint,
   'owner A sees only their own business row');
select is((select count(*) from public.branches), 1::bigint,
   'owner A sees only their own branches');

-- Create a product for A through the client-safe INSERT grant.
insert into public.products (business_id, name, sku, barcode, purchase_price, selling_price, tax_rate, reorder_level)
values (public.current_business_id(), 'Test Cola 1L', 'SKU-1', '1234567890128', 50.00, 100.00, 0, 3);
reset role;

-- Carry the product id through a setting (authenticated cannot read products).
select set_config('test.product_id',
                  (select id::text from public.products where sku = 'SKU-1'), false);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"bbbbbbbb-0000-0000-0000-000000000001"}', true);
select is((select count(*) from public.product_full_view), 0::bigint,
   'business B sees none of business A products (RLS isolation)');
select is((select count(*) from public.sales), 0::bigint,
   'business B sees none of business A sales');
reset role;

-- ---------------------------------------------------------------------------
-- Cost protection: cashiers must never read purchase price (PART D3.3)
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}', true);
select ok(public.has_permission('products.create'), 'owner has products.create');
select ok(public.has_permission('products.view_cost'), 'owner has products.view_cost');
select is((select purchase_price_visible from public.product_full_view limit 1), 50.00::numeric,
   'owner sees the cost through product_full_view');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000002"}', true);
select ok(not public.has_permission('products.create'), 'cashier lacks products.create');
select ok(not public.has_permission('products.view_cost'), 'cashier lacks products.view_cost');
select ok(public.has_permission('pos.sell'), 'cashier has pos.sell');
select throws_ok($$select * from public.products limit 1$$, '42501', null,
   'authenticated cannot SELECT public.products directly (cost protection)');
select is((select purchase_price_visible from public.product_full_view limit 1), null::numeric,
   'cashier cost column is nulled in product_full_view');

-- ---------------------------------------------------------------------------
-- POS: stock in, shift, sale
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.adjust_stock(jsonb_build_object(
      'product_id', current_setting('test.product_id')::uuid,
      'qty_delta', 10, 'reason', 'opening stock'))$$,
  'owner can adjust stock in');
reset role;

select is((select on_hand from public.inventories
     where product_id = current_setting('test.product_id')::uuid),
   10.000::numeric, 'adjustment set on_hand to 10');
select is((select count(*) from public.stock_movements
     where product_id = current_setting('test.product_id')::uuid
       and movement_type = 'adjustment'),
   1::bigint, 'adjustment wrote exactly one movement row');

-- Cashier with no shift cannot sell.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000002"}', true);
select throws_like(
  $$select public.complete_sale(jsonb_build_object(
      'idempotency_key', 'cashier-no-shift',
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid, 'qty', 1)),
      'payments', jsonb_build_array(jsonb_build_object('method','cash','amount',100))))$$,
  '%SHIFT_NOT_OPEN%', 'sale without an open shift raises SHIFT_NOT_OPEN');
reset role;

-- Owner opens a shift.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}', true);
select lives_ok($$select public.open_shift('{"opening_float":100}')$$, 'owner opens a shift');

-- inventory_view: business-scoped on-hand with names, and cost excluded.
select is(
  (select on_hand from public.inventory_view where product_id = current_setting('test.product_id')::uuid),
  10.000::numeric, 'inventory_view exposes on-hand to the owning business');
select is(
  (select count(*) from information_schema.columns
    where table_name = 'inventory_view' and column_name = 'wac'),
  0::bigint, 'inventory_view never exposes the wac cost column');
select throws_ok(
  $$select on_hand from public.inventories limit 1$$, '42501', null,
  'authenticated cannot read the raw inventories table (wac is cost data)');

-- Happy path: sell 2 units at 100 each.
create temp table sale1 as
select public.complete_sale(jsonb_build_object(
  'idempotency_key', 'sale-happy-1',
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', current_setting('test.product_id')::uuid, 'qty', 2)),
  'payments', jsonb_build_array(jsonb_build_object('method','cash','amount',200))
)) as res;

select is((select res -> 'data' ->> 'grand_total' from sale1), '200.00',
   'complete_sale recomputes grand total server-side (2 x 100.00)');
select is((select res -> 'data' ->> 'change_due' from sale1), '0.00',
   'exact payment leaves zero change');
select is((select res -> 'data' ->> 'duplicate' from sale1), 'false',
   'first sale is not marked duplicate');
select set_config('test.sale_id', (select res -> 'data' ->> 'sale_id' from sale1), false);
reset role;

select is((select on_hand from public.inventories
     where product_id = current_setting('test.product_id')::uuid),
   8.000::numeric, 'sale decremented stock to 8');
select is((select count(*) from public.stock_movements
     where product_id = current_setting('test.product_id')::uuid
       and movement_type = 'sale'),
   1::bigint, 'sale wrote exactly one movement row');
select is((select sum(qty_delta) from public.stock_movements
     where product_id = current_setting('test.product_id')::uuid),
   (select on_hand from public.inventories
     where product_id = current_setting('test.product_id')::uuid),
   'stock invariant: sum of movements equals inventory on_hand');
-- Scoped to this suite's own business: the database may already hold demo/
-- fixture rows for other businesses (seeded data), so global counts would lie.
select is((select count(*) from public.sales
     where business_id = (select business_id from public.products
                           where id = current_setting('test.product_id')::uuid)),
   1::bigint, 'exactly one sale row exists');
select is((select count(*) from public.sale_items
     where sale_id in (select id from public.sales
                        where business_id = (select business_id from public.products
                                             where id = current_setting('test.product_id')::uuid))),
   1::bigint, 'one sale_item snapshot exists');
select is((select cost_at_sale from public.sale_items
     where sale_id = current_setting('test.sale_id')::uuid), 0.0000::numeric,
   'sale_item snapshots WAC at sale time');

-- Idempotency: replaying the same key returns the original sale, no double-sell.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}', true);
create temp table sale1_replay as
select public.complete_sale(jsonb_build_object(
  'idempotency_key', 'sale-happy-1',
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', current_setting('test.product_id')::uuid, 'qty', 2)),
  'payments', jsonb_build_array(jsonb_build_object('method','cash','amount',200))
)) as res;
select is((select res -> 'data' ->> 'duplicate' from sale1_replay), 'true',
   'retried idempotency key is reported as duplicate');
select is((select res -> 'data' ->> 'sale_id' from sale1_replay),
   (select res -> 'data' ->> 'sale_id' from sale1), 'duplicate returns the original sale id');
reset role;
select is((select on_hand from public.inventories
     where product_id = current_setting('test.product_id')::uuid),
   8.000::numeric, 'duplicate replay did not decrement stock again');

-- Insufficient stock is rejected.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}', true);
select throws_like(
  $$select public.complete_sale(jsonb_build_object(
      'idempotency_key', 'sale-too-big',
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid, 'qty', 1000)),
      'payments', jsonb_build_array(jsonb_build_object('method','cash','amount',100000))))$$,
  '%INSUFFICIENT_STOCK%', 'selling more than on-hand raises INSUFFICIENT_STOCK');
reset role;
select is((select on_hand from public.inventories
     where product_id = current_setting('test.product_id')::uuid),
   8.000::numeric, 'failed sale left stock unchanged (transaction rollback)');

-- Cancel a sale reverses stock.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.cancel_sale(current_setting('test.sale_id')::uuid, 'customer changed mind')$$,
  'owner can cancel a completed sale');
reset role;
select is((select on_hand from public.inventories
     where product_id = current_setting('test.product_id')::uuid),
   10.000::numeric, 'cancel restored stock to 10');
select is((select status from public.sales
     where id = current_setting('test.sale_id')::uuid), 'cancelled',
   'cancelled sale is marked, not deleted');

-- ---------------------------------------------------------------------------
-- Structural guarantees (SPEC §107)
-- ---------------------------------------------------------------------------
select is(
  (select count(*) from pg_tables where schemaname = 'public' and rowsecurity = false),
  0::bigint, 'RLS is enabled on every public table');
select is(
  (select count(*) from public.permissions), 51::bigint,
  'the full permission catalogue is seeded');
select is(
  (select count(*) from public.units where business_id is null), 7::bigint,
  'the seven system units are seeded');

-- ---------------------------------------------------------------------------
-- Append-only guard
-- ---------------------------------------------------------------------------
select throws_ok(
  $$update public.audit_logs set action = 'tampered'$$, 'P0001', null,
  'audit_logs is append-only');

-- Raise (not just print) when anything failed, so a non-zero exit is guaranteed
-- whether this runs under `supabase test db` or the linked-project runner.
do $$
begin
  if (select num_failed()) > 0 then
    raise exception 'PGTAP: % test(s) failed', (select num_failed());
  end if;
end $$;

select * from finish();
rollback;
