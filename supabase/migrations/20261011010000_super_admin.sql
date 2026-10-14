-- =============================================================================
-- 120_super_admin (SPEC §3.1)
--
-- Platform-level Super Admin: full system access across EVERY business.
--   * `super_admins`      — membership table (auth user ids)
--   * `is_super_admin()`  — helper used by policies, RPC guards and the app
--   * RLS                 — business-scoped policies get `or is_super_admin()`;
--                           `has_permission()` / `can_see_branch()` short-circuit
--                           true for a super admin so branch/permission-gated
--                           reads (inventory, sales, purchasing, reports…)
--                           open across businesses without touching each policy
--   * RPCs                — admin_list_businesses / admin_create_branch /
--                           grant_super_admin / revoke_super_admin
--
-- Bootstrap the FIRST super admin with SQL (never from the app — the table is
-- empty at that point and self-granting would be a privilege-escalation hole):
--   insert into public.super_admins (user_id)
--   select id from auth.users where email = 'you@example.com';
-- Later grants/revokes go through the RPCs below (super-admin only).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Membership table
-- ---------------------------------------------------------------------------
create table if not exists public.super_admins (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  granted_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now()
);

alter table public.super_admins enable row level security;

-- ---------------------------------------------------------------------------
-- Helper: is the caller a super admin? (security definer → bypasses RLS on
-- the membership table itself, which is the chicken-and-egg problem)
-- ---------------------------------------------------------------------------
create or replace function public.is_super_admin()
returns boolean
language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.super_admins sa
     where sa.user_id = auth.uid()
  )
$$;

-- Everyone may read their own membership row (so the app can tell a user they
-- are a super admin); only super admins see the full list.
create policy super_admins_select on public.super_admins
  for select to authenticated
  using (user_id = auth.uid() or public.is_super_admin());

-- Grants/revokes happen through the RPCs (security definer) only.

-- ---------------------------------------------------------------------------
-- Short-circuit the two shared predicates used by every other policy/RPC.
-- ---------------------------------------------------------------------------
create or replace function public.has_permission(p_key text) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select public.is_super_admin() or exists (
    select 1
    from public.profiles pr
    join public.role_permissions rp on rp.role_id = pr.role_id
    join public.permissions pm on pm.id = rp.permission_id
    where pr.auth_user_id = auth.uid()
      and pr.status = 'active'
      and pm.key = p_key
  )
$$;

create or replace function public.can_see_branch(p_business uuid, p_branch uuid)
returns boolean
language sql stable security definer set search_path = public, pg_temp
as $$
  select public.is_super_admin()
      or (
       p_business = public.current_business_id()
     and (
       p_branch is null
       or p_branch = public.current_branch_id()
       or public.has_permission('branches.access_all')
       or exists (
         select 1 from public.user_branch_access uba
          where uba.profile_id = public.current_profile_id()
            and uba.branch_id = p_branch
       )
     )
     )
$$;

-- ---------------------------------------------------------------------------
-- Business-scoped policies: add the super-admin bypass.
-- (Policies that already route through has_permission / can_see_branch are
-- covered by the short-circuits above and are left untouched.)
-- ---------------------------------------------------------------------------

-- businesses
drop policy if exists businesses_select on public.businesses;
create policy businesses_select on public.businesses
  for select to authenticated
  using (id = public.current_business_id() or public.is_super_admin());

drop policy if exists businesses_update on public.businesses;
create policy businesses_update on public.businesses
  for update to authenticated
  using ((id = public.current_business_id() and public.has_permission('settings.manage'))
         or public.is_super_admin())
  with check (id = public.current_business_id() or public.is_super_admin());

-- branches
drop policy if exists branches_select on public.branches;
create policy branches_select on public.branches
  for select to authenticated
  using (business_id = public.current_business_id() or public.is_super_admin());

drop policy if exists branches_insert on public.branches;
create policy branches_insert on public.branches
  for insert to authenticated
  with check ((business_id = public.current_business_id()
               and public.has_permission('branches.manage'))
              or public.is_super_admin());

drop policy if exists branches_update on public.branches;
create policy branches_update on public.branches
  for update to authenticated
  using ((business_id = public.current_business_id()
          and public.has_permission('branches.manage'))
         or public.is_super_admin())
  with check (business_id = public.current_business_id() or public.is_super_admin());

-- profiles
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated
  using (
    auth_user_id = auth.uid()
    or business_id = public.current_business_id()
    or public.is_super_admin()
  );

drop policy if exists profiles_update_manage on public.profiles;
create policy profiles_update_manage on public.profiles
  for update to authenticated
  using ((business_id = public.current_business_id()
          and public.has_permission('users.manage'))
         or public.is_super_admin())
  with check (business_id = public.current_business_id() or public.is_super_admin());

-- roles & permissions
drop policy if exists roles_select on public.roles;
create policy roles_select on public.roles
  for select to authenticated
  using (business_id = public.current_business_id() or public.is_super_admin());

drop policy if exists role_permissions_select on public.role_permissions;
create policy role_permissions_select on public.role_permissions
  for select to authenticated
  using (public.is_super_admin() or exists (
    select 1 from public.roles r
     where r.id = role_id and r.business_id = public.current_business_id()
  ));

drop policy if exists user_branch_access_select on public.user_branch_access;
create policy user_branch_access_select on public.user_branch_access
  for select to authenticated
  using (public.is_super_admin() or exists (
    select 1 from public.profiles p
     where p.id = profile_id and p.business_id = public.current_business_id()
  ));

-- catalog
drop policy if exists categories_select on public.categories;
create policy categories_select on public.categories
  for select to authenticated
  using (business_id = public.current_business_id() or public.is_super_admin());

drop policy if exists brands_select on public.brands;
create policy brands_select on public.brands
  for select to authenticated
  using (business_id = public.current_business_id() or public.is_super_admin());

drop policy if exists product_barcodes_select on public.product_barcodes;
create policy product_barcodes_select on public.product_barcodes
  for select to authenticated
  using (business_id = public.current_business_id() or public.is_super_admin());

-- price_history (cost-bearing; super admins are platform auditors)
drop policy if exists price_history_select on public.price_history;
create policy price_history_select on public.price_history
  for select to authenticated
  using ((business_id = public.current_business_id()
          and public.has_permission('products.view_cost'))
         or public.is_super_admin());

-- parties
drop policy if exists suppliers_select on public.suppliers;
create policy suppliers_select on public.suppliers
  for select to authenticated
  using ((business_id = public.current_business_id()
          and public.has_permission('purchases.view'))
         or public.is_super_admin());

drop policy if exists customers_select on public.customers;
create policy customers_select on public.customers
  for select to authenticated
  using ((business_id = public.current_business_id()
          and public.has_permission('customers.manage'))
         or public.is_super_admin());

drop policy if exists loyalty_transactions_select on public.loyalty_transactions;
create policy loyalty_transactions_select on public.loyalty_transactions
  for select to authenticated
  using ((business_id = public.current_business_id()
          and public.has_permission('customers.manage'))
         or public.is_super_admin());

-- marketing
drop policy if exists promotions_select on public.promotions;
create policy promotions_select on public.promotions
  for select to authenticated
  using (business_id = public.current_business_id() or public.is_super_admin());

drop policy if exists promotion_items_select on public.promotion_items;
create policy promotion_items_select on public.promotion_items
  for select to authenticated
  using (public.is_super_admin() or exists (
    select 1 from public.promotions pr
     where pr.id = promotion_id and pr.business_id = public.current_business_id()
  ));

-- system
drop policy if exists audit_logs_select on public.audit_logs;
create policy audit_logs_select on public.audit_logs
  for select to authenticated
  using ((business_id = public.current_business_id()
          and public.has_permission('audit.view'))
         or public.is_super_admin());

drop policy if exists sync_log_select on public.sync_log;
create policy sync_log_select on public.sync_log
  for select to authenticated
  using (business_id = public.current_business_id() or public.is_super_admin());

drop policy if exists imports_select on public.imports;
create policy imports_select on public.imports
  for select to authenticated
  using ((business_id = public.current_business_id()
          and public.has_permission('data.import'))
         or public.is_super_admin());

-- NOTE: notifications stay strictly per-user — a super admin must not read
-- other people's notification inbox (SPEC §57 is per-user by design).

-- ---------------------------------------------------------------------------
-- RPC: list every business with headline counts (SPEC §3.1 "manage businesses")
-- ---------------------------------------------------------------------------
create or replace function public.admin_list_businesses()
returns table (
  id            uuid,
  name          text,
  currency      text,
  timezone      text,
  status        text,
  branch_count  bigint,
  staff_count   bigint,
  product_count bigint,
  created_at    timestamptz
)
language sql stable security definer
set search_path = public, pg_temp
as $$
  select b.id, b.name, b.currency, b.timezone, b.status,
         (select count(*) from public.branches br where br.business_id = b.id),
         (select count(*) from public.profiles pr where pr.business_id = b.id),
         (select count(*) from public.products pd where pd.business_id = b.id),
         b.created_at
    from public.businesses b
   order by b.created_at
$$;

revoke all on function public.admin_list_businesses() from public, anon;
grant execute on function public.admin_list_businesses() to authenticated;

-- Guard: only a super admin may call it.
create or replace function public.admin_list_businesses_guard()
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not public.is_super_admin() then
    perform public.raise_app_error('NO_PERMISSION', 'super admin only');
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: create a branch inside any business (SPEC §3.1 / §6)
-- ---------------------------------------------------------------------------
create or replace function public.admin_create_branch(
  p_business uuid,
  p_name     text,
  p_address  text default null,
  p_phone    text default null
) returns uuid
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_id uuid;
begin
  if not public.is_super_admin() then
    perform public.raise_app_error('NO_PERMISSION', 'super admin only');
  end if;
  if nullif(trim(coalesce(p_name, '')), '') is null then
    perform public.raise_app_error('INVALID_INPUT', 'branch name is required');
  end if;

  insert into public.branches (business_id, name, address, phone)
  values (p_business, trim(p_name), nullif(trim(coalesce(p_address, '')), ''),
          nullif(trim(coalesce(p_phone, '')), ''))
  returning id into v_id;

  perform public.write_audit(p_business, null, 'superadmin.branch_create',
                             'branches', v_id, null, jsonb_build_object('name', p_name));
  return v_id;
end;
$$;

revoke all on function public.admin_create_branch(uuid, text, text, text) from public, anon;
grant execute on function public.admin_create_branch(uuid, text, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- RPCs: grant / revoke super admin (SPEC §3.1) — super-admin only, audited.
-- ---------------------------------------------------------------------------
create or replace function public.grant_super_admin(p_email text)
returns boolean
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_user uuid;
begin
  if not public.is_super_admin() then
    perform public.raise_app_error('NO_PERMISSION', 'super admin only');
  end if;

  select id into v_user from auth.users
   where lower(email) = lower(trim(coalesce(p_email, '')));
  if v_user is null then
    perform public.raise_app_error('NOT_FOUND', 'no auth user with that email');
  end if;

  insert into public.super_admins (user_id, granted_by)
  values (v_user, auth.uid())
  on conflict (user_id) do nothing;

  perform public.write_audit(public.current_business_id(), null,
    'superadmin.grant', 'super_admins', v_user, null,
    jsonb_build_object('email', p_email));
  return true;
end;
$$;

revoke all on function public.grant_super_admin(text) from public, anon;
grant execute on function public.grant_super_admin(text) to authenticated;

create or replace function public.revoke_super_admin(p_email text)
returns boolean
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_user uuid;
begin
  if not public.is_super_admin() then
    perform public.raise_app_error('NO_PERMISSION', 'super admin only');
  end if;

  select id into v_user from auth.users
   where lower(email) = lower(trim(coalesce(p_email, '')));
  if v_user is null then
    perform public.raise_app_error('NOT_FOUND', 'no auth user with that email');
  end if;

  -- Never lock the platform out: refuse to remove the last super admin.
  if (select count(*) from public.super_admins) = 1
     and exists (select 1 from public.super_admins where user_id = v_user) then
    perform public.raise_app_error('INVALID_STATE', 'cannot revoke the last super admin');
  end if;

  delete from public.super_admins where user_id = v_user;

  perform public.write_audit(public.current_business_id(), null,
    'superadmin.revoke', 'super_admins', v_user,
    jsonb_build_object('email', p_email), null);
  return true;
end;
$$;

revoke all on function public.revoke_super_admin(text) from public, anon;
grant execute on function public.revoke_super_admin(text) to authenticated;
