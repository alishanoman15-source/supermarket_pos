-- =============================================================================
-- 10_super_admin.sql — pgTAP (SPEC §3.1)
-- Covers: is_super_admin() helper, cross-business visibility for a super
-- admin, business isolation for everyone else, admin_list_businesses guard,
-- grant_super_admin / revoke_super_admin guards and the last-admin lock.
--
-- Runs as a single transaction and rolls back, so it never leaves data behind.
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
   'authenticated', 'authenticated', 'sa-owner-a@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Owner A"}'),
  ('aaaaaaaa-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'sa-owner-b@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Owner B"}'),
  ('aaaaaaaa-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'sa-platform@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Platform Admin"}');

-- Onboard two businesses through the real RPC.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.create_business_with_owner('{"name":"SA Business A","currency":"PKR"}','{"name":"Main A"}')$$,
  'owner A can onboard a business');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000002"}', true);
select lives_ok(
  $$select public.create_business_with_owner('{"name":"SA Business B","currency":"PKR"}','{"name":"Main B"}')$$,
  'owner B can onboard a business');
reset role;

-- ---------------------------------------------------------------------------
-- is_super_admin(): false before the grant, true after (bootstrap insert)
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000003"}', true);
select ok(not public.is_super_admin(), 'a plain user is not a super admin');
reset role;

-- Bootstrap the first super admin exactly as documented (direct insert).
insert into public.super_admins (user_id)
values ('aaaaaaaa-0000-0000-0000-000000000003');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000003"}', true);
select ok(public.is_super_admin(), 'membership row makes the user a super admin');
reset role;

-- ---------------------------------------------------------------------------
-- Cross-business visibility (SPEC §3.1): the super admin (no business of his
-- own) sees both businesses and both branches; an owner sees only his own.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000003"}', true);

select is((select count(*) from public.businesses), 2::bigint,
  'super admin sees every business');

select is((select count(*) from public.branches), 2::bigint,
  'super admin sees every branch');

select is((select count(*) from public.profiles), 3::bigint,
  'super admin sees every profile');

select results_eq(
  $$select name from public.admin_list_businesses()$$,
  $$values ('SA Business A'), ('SA Business B')$$,
  'admin_list_businesses returns every business');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}', true);

select is((select count(*) from public.businesses), 1::bigint,
  'a normal owner still sees only their own business');

select throws_ok(
  $$select public.admin_list_businesses()$$,
  'NO_PERMISSION: super admin only',
  null,
  'admin_list_businesses denies a non-super-admin');
reset role;

-- ---------------------------------------------------------------------------
-- admin_create_branch: super admin creates a branch in someone else's business
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000003"}', true);

select lives_ok(
  $$select public.admin_create_branch(
       (select id from public.businesses where name = 'SA Business B'),
       'SA DHA Branch', 'DHA Phase 5', '03001234567')$$,
  'super admin can create a branch in any business');

select is((select count(*) from public.branches
            where business_id = (select id from public.businesses where name = 'SA Business B')),
          2::bigint, 'the new branch landed in business B');

select throws_ok(
  $$select public.admin_create_branch(
       (select id from public.businesses where name = 'SA Business B'), '')$$,
  'INVALID_INPUT: branch name is required',
  null,
  'admin_create_branch validates the name');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}', true);

select throws_ok(
  $$select public.admin_create_branch(
       (select id from public.businesses where name = 'SA Business B'), 'Nope')$$,
  'NO_PERMISSION: super admin only',
  null,
  'admin_create_branch denies a non-super-admin');
reset role;

-- ---------------------------------------------------------------------------
-- grant / revoke guards
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}', true);

select throws_ok(
  $$select public.grant_super_admin('sa-owner-b@test.local')$$,
  'NO_PERMISSION: super admin only',
  null,
  'grant_super_admin denies a non-super-admin');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000003"}', true);

select throws_ok(
  $$select public.grant_super_admin('nobody@test.local')$$,
  'NOT_FOUND: no auth user with that email',
  null,
  'grant_super_admin rejects an unknown email');

select lives_ok(
  $$select public.grant_super_admin('sa-owner-b@test.local')$$,
  'super admin can grant super admin to another user');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000002"}', true);
select ok(public.is_super_admin(), 'the granted user is now a super admin');
reset role;

-- ---------------------------------------------------------------------------
-- The last super admin cannot be revoked (no platform lockout)
-- ---------------------------------------------------------------------------
delete from public.super_admins
 where user_id = 'aaaaaaaa-0000-0000-0000-000000000002';
-- exactly one super admin remains (…003)

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-0000-0000-000000000003"}', true);

select throws_ok(
  $$select public.revoke_super_admin('sa-platform@test.local')$$,
  'INVALID_STATE: cannot revoke the last super admin',
  null,
  'the last super admin cannot be revoked');
reset role;

select * from finish();
rollback;
