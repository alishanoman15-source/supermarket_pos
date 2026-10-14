-- =============================================================================
-- 04_permission_matrix.sql — pgTAP
-- Covers SPEC §82, §97: every sensitive RPC denies a cashier with NO_PERMISSION,
-- and RLS hides cost / supplier / audit / expense data from them. The owner is
-- shown to have the same capabilities so the test proves *authorisation*, not
-- just "the call failed".
--
-- Single transaction, rolled back.
-- =============================================================================
begin;

select no_plan();

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values
  ('dddddddd-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'owner-d@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Owner D"}'),
  ('dddddddd-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'cashier-d@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Cashier D"}');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"dddddddd-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.create_business_with_owner('{"name":"Business D","currency":"PKR"}','{"name":"Main D"}')$$,
  'owner D can onboard a business');
select lives_ok(
  $$insert into public.suppliers (business_id, name)
    values (public.current_business_id(), 'Hidden Supplier')$$,
  'owner can create a supplier');
select lives_ok(
  $$insert into public.products (business_id, name, sku, purchase_price, selling_price)
    values (public.current_business_id(), 'Perm Cola', 'PERM-1', 40.00, 60.00)$$,
  'owner can create a product');
reset role;

-- Make D-2 a cashier of business D.
update public.profiles
   set business_id = (select id from public.businesses where name = 'Business D'),
       branch_id   = (select id from public.branches
                       where business_id = (select id from public.businesses where name = 'Business D')
                       limit 1),
       role_id     = (select id from public.roles
                       where business_id = (select id from public.businesses where name = 'Business D')
                         and key = 'cashier')
 where id = 'dddddddd-0000-0000-0000-000000000002';

select set_config('test.business_id',
  (select id::text from public.businesses where name = 'Business D'), false);
select set_config('test.branch_id',
  (select id::text from public.branches
    where business_id = current_setting('test.business_id')::uuid limit 1), false);
select set_config('test.supplier_id',
  (select id::text from public.suppliers where name = 'Hidden Supplier'), false);
select set_config('test.product_id',
  (select id::text from public.products where sku = 'PERM-1'), false);

-- ---------------------------------------------------------------------------
-- Cashier: permission gates on the sensitive RPCs
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"dddddddd-0000-0000-0000-000000000002"}', true);

select ok(public.has_permission('pos.sell'), 'cashier can sell');
select ok(not public.has_permission('products.view_cost'), 'cashier cannot view cost');

select throws_like(
  $$select public.adjust_stock(jsonb_build_object(
      'product_id', current_setting('test.product_id')::uuid, 'qty_delta', 5, 'reason', 'test'))$$,
  '%NO_PERMISSION%', 'cashier cannot adjust stock');

select throws_like(
  $$select public.create_purchase_order(jsonb_build_object(
      'supplier_id', current_setting('test.supplier_id')::uuid,
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid, 'qty', 1, 'unit_cost', 1))))$$,
  '%NO_PERMISSION%', 'cashier cannot create a purchase order');

select throws_like(
  $$select public.pay_supplier(jsonb_build_object(
      'supplier_id', current_setting('test.supplier_id')::uuid, 'amount', 10))$$,
  '%NO_PERMISSION%', 'cashier cannot pay a supplier');

select throws_like(
  $$select public.receive_purchase(jsonb_build_object(
      'supplier_id', current_setting('test.supplier_id')::uuid,
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid, 'qty', 1, 'unit_cost', 1))))$$,
  '%NO_PERMISSION%', 'cashier cannot receive goods');

select throws_like(
  $$select public.start_stock_count('{}'::jsonb)$$,
  '%NO_PERMISSION%', 'cashier cannot start a stock count');

select throws_like(
  $$select public.transfer_stock(jsonb_build_object(
      'to_branch_id', current_setting('test.branch_id')::uuid,
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid, 'qty', 1))))$$,
  '%NO_PERMISSION%', 'cashier cannot transfer stock');

-- Shifts and drawer cash are intentionally within a cashier's remit: they may
-- open/close their own shift and move drawer cash. Assert the positive path.
create temp table cashier_shift as
select public.open_shift('{"opening_float":50}') as res;
select set_config('test.cashier_shift',
  (select res -> 'data' ->> 'shift_id' from cashier_shift), false);
select is((select res -> 'data' ->> 'status' from cashier_shift), 'open',
  'cashier can open their own shift (shifts.open)');
select lives_ok(
  $$select public.record_cash_movement(jsonb_build_object(
      'shift_id', current_setting('test.cashier_shift')::uuid,
      'type', 'drawer_in', 'amount', 25))$$,
  'cashier can move drawer cash on their own shift (cash.move)');
select throws_like(
  $$select public.record_cash_movement(jsonb_build_object(
      'shift_id', current_setting('test.cashier_shift')::uuid,
      'type', 'sale', 'amount', 5))$$,
  '%VALIDATION_FAILED%', 'record_cash_movement rejects a non drawer type');

select throws_like(
  $$select public.dashboard_kpis(now() - interval '7 days', now())$$,
  '%NO_PERMISSION%', 'cashier cannot read dashboard KPIs');

select throws_like(
  $$select public.report_sales(now() - interval '7 days', now())$$,
  '%NO_PERMISSION%', 'cashier cannot read the sales report');

select throws_like(
  $$select public.report_profit(now() - interval '7 days', now())$$,
  '%NO_PERMISSION%', 'cashier cannot read the profit report');

select throws_like(
  $$select public.report_purchases(now() - interval '7 days', now())$$,
  '%NO_PERMISSION%', 'cashier cannot read the purchases report');

-- ---------------------------------------------------------------------------
-- Cashier: RLS hides cost, supplier, audit and expense data
-- ---------------------------------------------------------------------------
select is((select purchase_price_visible from public.product_full_view limit 1),
  null::numeric, 'cashier sees a null cost column');
select is((select count(*) from public.suppliers), 0::bigint,
  'cashier cannot read suppliers (RLS: purchases.view)');
select is((select count(*) from public.audit_logs), 0::bigint,
  'cashier cannot read the audit log (RLS: audit.view)');
select is((select count(*) from public.expenses), 0::bigint,
  'cashier cannot read expenses (RLS: expenses.manage)');
select is((select count(*) from public.purchase_orders), 0::bigint,
  'cashier cannot read purchase orders');
reset role;

-- ---------------------------------------------------------------------------
-- Owner: the same calls succeed (proves the denials above are authorisation)
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"dddddddd-0000-0000-0000-000000000001"}', true);

select lives_ok(
  $$select public.adjust_stock(jsonb_build_object(
      'product_id', current_setting('test.product_id')::uuid,
      'qty_delta', 5, 'reason', 'opening'))$$,
  'owner can adjust stock');
select lives_ok(
  $$select public.open_shift('{"opening_float":100}')$$,
  'owner can open a shift');
select lives_ok(
  $$select public.report_profit(now() - interval '7 days', now())$$,
  'owner can read the profit report');
select lives_ok(
  $$select public.dashboard_kpis(now() - interval '7 days', now())$$,
  'owner can read dashboard KPIs');
select is((select count(*) from public.suppliers), 1::bigint,
  'owner can read their supplier');
select is((select purchase_price_visible from public.product_full_view limit 1),
  40.00::numeric, 'owner sees the real cost column');
reset role;

do $$
begin
  if (select num_failed()) > 0 then
    raise exception 'PGTAP: % test(s) failed', (select num_failed());
  end if;
end $$;

select * from finish();
rollback;
