-- =============================================================================
-- 05_stock_policy_and_race.sql — pgTAP
-- Covers SPEC §8, §97:
--   * the negative-stock policy defaults to OFF and blocks overselling;
--   * turning the policy ON allows a sale to take stock below zero;
--   * the "sell the last unit" invariant: once the last unit is sold a second
--     sale of that unit must fail, so stock can never be double-spent.
--
-- Note on true concurrency: pgTAP runs a single session, so a genuinely
-- parallel two-session race cannot be exercised here. `complete_sale` takes
-- `SELECT ... FOR UPDATE` on the inventory row (apply_stock_delta), which is
-- what serialises concurrent callers; this suite asserts the observable
-- invariant that the lock guarantees, and checks the lock is present in the
-- function body.
--
-- Single transaction, rolled back.
-- =============================================================================
begin;

select no_plan();

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values
  ('eeeeeeee-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'owner-e@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Owner E"}');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"eeeeeeee-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.create_business_with_owner('{"name":"Business E","currency":"PKR"}','{"name":"Main E"}')$$,
  'owner E can onboard a business');
select lives_ok(
  $$insert into public.products (business_id, name, sku, purchase_price, selling_price)
    values (public.current_business_id(), 'Last Unit', 'LAST-1', 10.00, 20.00)$$,
  'owner can create a product');
select lives_ok($$select public.open_shift('{"opening_float":0}')$$, 'owner opens a shift');
reset role;

select set_config('test.business_id',
  (select id::text from public.businesses where name = 'Business E'), false);
select set_config('test.product_id',
  (select id::text from public.products where sku = 'LAST-1'), false);

-- Stock in exactly one unit.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"eeeeeeee-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.adjust_stock(jsonb_build_object(
      'product_id', current_setting('test.product_id')::uuid,
      'qty_delta', 1, 'reason', 'opening'))$$,
  'one unit is stocked in');
reset role;

select is((select on_hand from public.inventories
            where product_id = current_setting('test.product_id')::uuid),
  1.000::numeric, 'on-hand starts at exactly one unit');

-- ---------------------------------------------------------------------------
-- Default policy: the last unit sells once, the next attempt fails
-- ---------------------------------------------------------------------------
select ok(not public.allow_negative_stock(current_setting('test.business_id')::uuid),
  'negative stock is disallowed by default');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"eeeeeeee-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.complete_sale(jsonb_build_object(
      'idempotency_key', 'last-unit-1',
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid, 'qty', 1)),
      'payments', jsonb_build_array(jsonb_build_object('method', 'cash', 'amount', 20))))$$,
  'the last unit can be sold once');

select throws_like(
  $$select public.complete_sale(jsonb_build_object(
      'idempotency_key', 'last-unit-2',
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid, 'qty', 1)),
      'payments', jsonb_build_array(jsonb_build_object('method', 'cash', 'amount', 20))))$$,
  '%INSUFFICIENT_STOCK%', 'a second sale of the last unit is rejected');
reset role;

select is((select on_hand from public.inventories
            where product_id = current_setting('test.product_id')::uuid),
  0.000::numeric, 'stock lands exactly on zero, never negative');
-- Scoped to this suite's business: other seeded businesses may have sales.
select is((select count(*) from public.sales
     where business_id = current_setting('test.business_id')::uuid), 1::bigint,
  'only the successful sale exists');

-- ---------------------------------------------------------------------------
-- Policy ON: stock is allowed to go negative
-- ---------------------------------------------------------------------------
update public.businesses
   set settings = coalesce(settings, '{}'::jsonb) || '{"allow_negative_stock": true}'::jsonb
 where id = current_setting('test.business_id')::uuid;

select ok(public.allow_negative_stock(current_setting('test.business_id')::uuid),
  'the negative-stock policy can be switched on');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"eeeeeeee-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.complete_sale(jsonb_build_object(
      'idempotency_key', 'negative-1',
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid, 'qty', 2)),
      'payments', jsonb_build_array(jsonb_build_object('method', 'cash', 'amount', 40))))$$,
  'with the policy on, a sale may take stock negative');
reset role;

select is((select on_hand from public.inventories
            where product_id = current_setting('test.product_id')::uuid),
  (-2)::numeric, 'on-hand is -2 after an allowed oversell');
select is((select count(*) from public.stock_movements
            where product_id = current_setting('test.product_id')::uuid),
  3::bigint, 'every stock change still wrote a movement (1 adjust + 2 sales)');

-- ---------------------------------------------------------------------------
-- Serialisation guarantee: the stock writer takes a row lock
-- ---------------------------------------------------------------------------
select ok(
  (select prosrc ilike '%for update%'
     from pg_proc where proname = 'apply_stock_delta'),
  'apply_stock_delta locks the inventory row with FOR UPDATE (race protection)');
select ok(
  (select prosrc ilike '%for update%'
     from pg_proc where proname = 'receive_purchase'),
  'receive_purchase locks the inventory row before the WAC maths');

do $$
begin
  if (select num_failed()) > 0 then
    raise exception 'PGTAP: % test(s) failed', (select num_failed());
  end if;
end $$;

select * from finish();
rollback;
