-- =============================================================================
-- 02_inclusive_tax.sql — pgTAP
-- Regression for SPEC §30: tax-inclusive pricing must never charge tax twice.
--
-- `complete_sale` previously added `tax_total` on top of an already
-- tax-inclusive subtotal, inflating `grand_total` (a 117.00 shelf price with
-- 17% tax was charged as 134.00). Fixed in
-- migration 170_fix_inclusive_sale_total.
--
-- Self-contained: opens a transaction, asserts, and rolls back — no data left
-- behind. Runs under `supabase test db` or the linked-project runner.
-- =============================================================================
begin;

select no_plan();

-- ---------------------------------------------------------------------------
-- Fixtures
-- ---------------------------------------------------------------------------
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values
  ('dddddddd-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'inclusive@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Inclusive Owner"}');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"dddddddd-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.create_business_with_owner(
      '{"name":"Inclusive Co","currency":"PKR","settings":{"tax_inclusive":true}}',
      '{"name":"Main"}')$$,
  'owner can onboard a tax-inclusive business');
reset role;

-- One tax-inclusive shelf item (117.00 with 17% embedded) and one exclusive item.
insert into public.products (business_id, name, sku, selling_price, tax_rate)
values
  ((select id from public.businesses where name = 'Inclusive Co'), 'Inc Item', 'INC-1', 117.00, 17),
  ((select id from public.businesses where name = 'Inclusive Co'), 'Exc Item', 'EXC-1', 100.00, 17);

select set_config('test.inc_product',
  (select id::text from public.products where sku = 'INC-1'), true);
select set_config('test.exc_product',
  (select id::text from public.products where sku = 'EXC-1'), true);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"dddddddd-0000-0000-0000-000000000001"}', true);
select public.adjust_stock(jsonb_build_object(
  'product_id', current_setting('test.inc_product')::uuid, 'qty_delta', 5, 'reason', 'opening'));
select public.adjust_stock(jsonb_build_object(
  'product_id', current_setting('test.exc_product')::uuid, 'qty_delta', 5, 'reason', 'opening'));
select lives_ok($$select public.open_shift('{"opening_float":0}')$$, 'shift opens for selling');

-- ---------------------------------------------------------------------------
-- Inclusive: a 117.00 shelf price (17% inside) charges exactly 117.00
-- ---------------------------------------------------------------------------
create temp table inc_sale as
select public.complete_sale(jsonb_build_object(
  'idempotency_key', 'inclusive-1',
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', current_setting('test.inc_product')::uuid, 'qty', 1)),
  'payments', jsonb_build_array(jsonb_build_object('method', 'cash', 'amount', 117))
)) as res;

select is((select res -> 'data' ->> 'subtotal' from inc_sale), '117.00',
  'inclusive subtotal is the tax-inclusive shelf price');
select is((select res -> 'data' ->> 'tax_total' from inc_sale), '17.00',
  'inclusive tax_total reports the tax contained inside the price');
select is((select res -> 'data' ->> 'grand_total' from inc_sale), '117.00',
  'inclusive grand_total does not add tax a second time');
select is((select res -> 'data' ->> 'change_due' from inc_sale), '0.00',
  'inclusive sale paid with 117.00 leaves zero change');
reset role;

-- ---------------------------------------------------------------------------
-- Exclusive still adds tax on top (guards the fix against over-correction)
-- ---------------------------------------------------------------------------
update public.businesses
   set settings = settings - 'tax_inclusive'
 where name = 'Inclusive Co';

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"dddddddd-0000-0000-0000-000000000001"}', true);
create temp table exc_sale as
select public.complete_sale(jsonb_build_object(
  'idempotency_key', 'exclusive-1',
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', current_setting('test.exc_product')::uuid, 'qty', 1)),
  'payments', jsonb_build_array(jsonb_build_object('method', 'cash', 'amount', 117))
)) as res;

select is((select res -> 'data' ->> 'grand_total' from exc_sale), '117.00',
  'exclusive pricing still adds tax on top (100.00 + 17% = 117.00)');
reset role;

-- Raise (not just print) when anything failed, so the linked-project runner
-- and `supabase test db` both surface a real error.
do $$
begin
  if (select num_failed()) > 0 then
    raise exception 'PGTAP: % test(s) failed', (select num_failed());
  end if;
end $$;

select * from finish();
rollback;
