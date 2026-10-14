-- =============================================================================
-- 06_offline_sales.sql — pgTAP
-- Verifies that captured-price overrides and negative stock are accepted only
-- through the permission-gated offline-sale RPC.
-- =============================================================================
begin;

select no_plan();

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values
  ('66666666-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'offline-owner@test.local',
   crypt('password', gen_salt('bf')), now(), now(), now(), '{}', '{"full_name":"Owner O"}'),
  ('66666666-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'offline-cashier@test.local',
   crypt('password', gen_salt('bf')), now(), now(), now(), '{}', '{"full_name":"Cashier O"}');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"66666666-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.create_business_with_owner('{"name":"Offline O","currency":"PKR"}','{"name":"Main O"}')$$,
  'owner can onboard a business');
select lives_ok(
  $$insert into public.products (business_id, name, sku, purchase_price, selling_price)
    values (public.current_business_id(), 'Offline product', 'OFFLINE-1', 4.00, 10.00)$$,
  'owner can create a product');
reset role;

update public.profiles
   set business_id = (select id from public.businesses where name = 'Offline O'),
       branch_id = (select id from public.branches
                     where business_id = (select id from public.businesses where name = 'Offline O')
                     limit 1),
       role_id = (select id from public.roles
                   where business_id = (select id from public.businesses where name = 'Offline O')
                     and key = 'cashier')
 where id = '66666666-0000-0000-0000-000000000002';

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"66666666-0000-0000-0000-000000000002"}', true);
select ok(public.has_permission('pos.sell_offline'),
  'default cashier has the explicit offline-sale permission');
select lives_ok($$select public.open_shift('{"opening_float":0}')$$,
  'cashier opens a shift');
-- Direct SELECT on public.products is revoked for clients (cost protection,
-- RLS migration D3.3); clients read product_full_view instead. Do the same here.
select set_config('test.product_id',
  (select id::text from public.product_full_view where sku = 'OFFLINE-1'), true);
select set_config('test.shift_id',
  (select id::text from public.pos_shifts
    where opened_by = '66666666-0000-0000-0000-000000000002' and status = 'open'), true);

select throws_like(
  $$select public.complete_sale(jsonb_build_object(
      'idempotency_key', 'ordinary-price-check',
      'shift_id', current_setting('test.shift_id')::uuid,
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid,
        'qty', 1, 'unit_price', 7)),
      'payments', jsonb_build_array(jsonb_build_object('method', 'cash', 'amount', 7))))$$,
  '%PRICE_OVERRIDE_FORBIDDEN%',
  'ordinary sale RPC does not accept an unauthorized captured-price override');

select lives_ok(
  $$select public.complete_offline_sale(jsonb_build_object(
      'idempotency_key', 'offline-captured-price',
      'shift_id', current_setting('test.shift_id')::uuid,
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid,
        'qty', 1, 'unit_price', 7)),
      'payments', jsonb_build_array(jsonb_build_object('method', 'cash', 'amount', 7))))$$,
  'offline sale accepts its captured price and can oversell');
reset role;

select is((select grand_total from public.sales
            where idempotency_key = 'offline-captured-price'),
  7.00::numeric, 'server records the captured offline price');
select is((select on_hand from public.inventories
            where product_id = current_setting('test.product_id')::uuid),
  (-1)::numeric, 'offline sale records a negative stock balance');
select ok((select offline_mode from public.sales
            where idempotency_key = 'offline-captured-price'),
  'offline sale is marked for audit');

select * from finish();
rollback;
