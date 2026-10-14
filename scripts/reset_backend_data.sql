-- =============================================================================
-- reset_backend_data.sql — wipes EVERY tenant row and auth user from the
-- linked project while keeping the system catalogue (permission keys, system
-- units, system expense categories) intact.
--
-- Run it through the Management API helper:
--   ./scripts/sql.sh < scripts/reset_backend_data.sql
--
-- After this the project is in first-run state: no businesses, no users.
-- Sign up again in the app to create the first (owner) account.
-- (The QA demo data, if ever needed again, comes back with
--  ./scripts/seed_demo_data.sh)
-- =============================================================================
begin;

do $$
declare
  t text;
begin
  for t in
    select table_name
      from information_schema.tables
     where table_schema = 'public'
       and table_type = 'BASE TABLE'
  loop
    if t = 'permissions' then
      -- System permission catalogue: never delete.
      continue;
    elsif t in ('units', 'expense_categories') then
      -- Mixed tables: business-scoped rows are tenant data; the
      -- business_id IS NULL rows are the shared system defaults.
      execute format('delete from public.%I where business_id is not null', t);
    else
      -- Truncate with CASCADE so FK order across the 50+ tenant tables
      -- (sales, stock, shifts, audit, notifications, …) never matters.
      execute format('truncate table public.%I restart identity cascade', t);
    end if;
  end loop;
end $$;

-- Test/dummy auth accounts (app sign-ups + QA bot). Identities, sessions and
-- refresh tokens cascade with the user row.
delete from auth.users;

commit;

-- Report what is left: should be only the system catalogue.
select jsonb_pretty(jsonb_build_object(
  'auth_users_after', (select count(*) from auth.users),
  'businesses_after', (select count(*) from public.businesses),
  'profiles_after', (select count(*) from public.profiles),
  'permissions_kept', (select count(*) from public.permissions),
  'system_units_kept', (select count(*) from public.units where business_id is null),
  'system_expense_categories_kept',
    (select count(*) from public.expense_categories where business_id is null)
)) as reset_state;
