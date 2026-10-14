-- =============================================================================
-- 08_branch_admin.sql — pgTAP
-- Covers SPEC §6 (multi-branch from day one) and §86 screens 58–59: the owner
-- can create branches and POS terminals from the app, a cashier can neither
-- create nor mutate them, and reads stay open for both.
--
-- Single transaction, rolled back. Run through scripts/run_backend_tests.sh.
-- =============================================================================
begin;

select no_plan();

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values
  ('eeeeeeee-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'branch-owner@test.local',
   crypt('password', gen_salt('bf')), now(), now(), now(), '{}', '{"full_name":"Branch Owner"}'),
  ('eeeeeeee-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'branch-cashier@test.local',
   crypt('password', gen_salt('bf')), now(), now(), now(), '{}', '{"full_name":"Branch Cashier"}');

-- Owner onboards and administers branches + terminals.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"eeeeeeee-0000-0000-0000-000000000001"}', true);

select lives_ok(
  $$select public.create_business_with_owner('{"name":"Branch Admin Store","currency":"PKR"}','{"name":"Main Counter"}')$$,
  'owner onboards a business');

select lives_ok(
  $$insert into public.branches (business_id, name, address)
    values (public.current_business_id(), 'Model Town Branch', 'Model Town')$$,
  'owner creates a second branch');
reset role;

select set_config('test.business_id',
  (select id::text from public.businesses where name = 'Branch Admin Store'), false);
select set_config('test.branch_id',
  (select b.id::text from public.branches b
    where b.business_id = current_setting('test.business_id')::uuid limit 1), false);

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"eeeeeeee-0000-0000-0000-000000000001"}', true);

select lives_ok(
  $$insert into public.pos_terminals (business_id, branch_id, name)
    values (public.current_business_id(), current_setting('test.branch_id')::uuid, 'Counter 1')$$,
  'owner creates a POS terminal');
reset role;

-- Hand the business to the cashier (role assignment is out of scope here).
update public.profiles
   set business_id = current_setting('test.business_id')::uuid,
       branch_id   = current_setting('test.branch_id')::uuid,
       role_id     = (select id from public.roles
                       where business_id = current_setting('test.business_id')::uuid
                         and key = 'cashier')
 where id = 'eeeeeeee-0000-0000-0000-000000000002';

-- Cashier: read yes, write no.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"eeeeeeee-0000-0000-0000-000000000002"}', true);

select ok(public.has_permission('pos.sell'), 'cashier can sell');
select ok(not public.has_permission('branches.manage'), 'cashier cannot manage branches');

select lives_ok(
  $$select id from public.branches where business_id = public.current_business_id()$$,
  'cashier can still list branches');

select lives_ok(
  $$select id from public.pos_terminals where business_id = public.current_business_id()$$,
  'cashier can still list terminals');

select throws_like(
  $$insert into public.branches (business_id, name)
    values (public.current_business_id(), 'Cashier Branch')$$,
  '%row-level security%', 'cashier cannot create a branch');

select throws_like(
  $$insert into public.pos_terminals (business_id, branch_id, name)
    values (public.current_business_id(), current_setting('test.branch_id')::uuid, 'Rogue Counter')$$,
  '%row-level security%', 'cashier cannot create a POS terminal');

update public.pos_terminals set status = 'inactive'
 where business_id = public.current_business_id();

select is(
  (select status from public.pos_terminals
    where business_id = public.current_business_id() and name = 'Counter 1'),
  'active',
  'cashier terminal update matches no rows');

reset role;

-- Owner can rename and deactivate what they created.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"eeeeeeee-0000-0000-0000-000000000001"}', true);

update public.pos_terminals set status = 'inactive'
 where business_id = public.current_business_id() and name = 'Counter 1';

select is(
  (select status from public.pos_terminals
    where business_id = public.current_business_id() and name = 'Counter 1'),
  'inactive',
  'owner can deactivate a POS terminal');

select is(
  (select count(*)::int from public.branches
    where business_id = public.current_business_id()),
  2,
  'owner sees both branches');

reset role;

select * from finish();
rollback;
