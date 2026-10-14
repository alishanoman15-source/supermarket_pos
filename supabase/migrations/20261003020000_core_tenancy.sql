-- =============================================================================
-- 010_core_tenancy
-- businesses, branches, roles, permissions, role_permissions, profiles,
-- user_branch_access + RLS helper functions (BACKEND_SETUP.md Part B2, D1).
--
-- The four tenancy tables already existed in the remote project (created by the
-- dashboard, without RLS). This migration *reconciles* them to the documented
-- shape rather than recreating them, so no data is lost. The tables were empty
-- at reconciliation time; every statement is guarded to stay idempotent.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- businesses (SPEC §65)
-- ---------------------------------------------------------------------------
alter table public.businesses add column if not exists legal_name text;
alter table public.businesses add column if not exists settings jsonb not null default '{}'::jsonb;
alter table public.businesses add column if not exists status text not null default 'active';
alter table public.businesses add column if not exists updated_at timestamptz not null default now();
alter table public.businesses add column if not exists deleted_at timestamptz;

do $$ begin
  alter table public.businesses
    add constraint businesses_status_chk check (status in ('active','inactive'));
exception when duplicate_object then null; end $$;

create index if not exists businesses_status_idx on public.businesses (status);

-- ---------------------------------------------------------------------------
-- branches (SPEC §65)
-- ---------------------------------------------------------------------------
alter table public.branches add column if not exists status text not null default 'active';
alter table public.branches add column if not exists updated_at timestamptz not null default now();

do $$ begin
  alter table public.branches
    add constraint branches_status_chk check (status in ('active','inactive'));
exception when duplicate_object then null; end $$;

create index if not exists branches_business_id_idx on public.branches (business_id);
create index if not exists branches_status_idx on public.branches (status);

-- ---------------------------------------------------------------------------
-- permissions (SPEC §67) — global catalogue, keys never renamed
-- ---------------------------------------------------------------------------
alter table public.permissions add column if not exists category text;
alter table public.permissions add column if not exists created_at timestamptz not null default now();

-- ---------------------------------------------------------------------------
-- roles (SPEC §67) — per business; `key` is the stable identifier
-- ---------------------------------------------------------------------------
alter table public.roles add column if not exists key text;
alter table public.roles add column if not exists is_system boolean not null default false;
alter table public.roles add column if not exists created_at timestamptz not null default now();
alter table public.roles add column if not exists updated_at timestamptz not null default now();

create index if not exists roles_business_id_idx on public.roles (business_id);
create unique index if not exists roles_business_key_uq
  on public.roles (business_id, key) where key is not null;

-- ---------------------------------------------------------------------------
-- role_permissions (SPEC §67)
-- ---------------------------------------------------------------------------
alter table public.role_permissions add column if not exists created_at timestamptz not null default now();
create index if not exists role_permissions_permission_id_idx
  on public.role_permissions (permission_id);

-- ---------------------------------------------------------------------------
-- profiles (SPEC §66)
--   `id` stays the primary key (FK auth.users.id) for backward compatibility;
--   `auth_user_id` mirrors it so the documented helper functions work verbatim.
-- ---------------------------------------------------------------------------
alter table public.profiles add column if not exists role_id uuid;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists status text not null default 'active';
alter table public.profiles add column if not exists last_login_at timestamptz;
alter table public.profiles add column if not exists updated_at timestamptz not null default now();

do $$ begin
  alter table public.profiles
    add constraint profiles_status_chk check (status in ('active','suspended'));
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.profiles
    add constraint profiles_role_id_fkey foreign key (role_id) references public.roles(id) on delete set null;
exception when duplicate_object then null; end $$;

-- existing FKs are CASCADE (dashboard default); SPEC §66 asks for RESTRICT on
-- business and SET NULL on branch. Re-point them so deleting a business can
-- never silently wipe staff history.
do $$ begin
  alter table public.profiles drop constraint if exists profiles_business_id_fkey;
  alter table public.profiles
    add constraint profiles_business_id_fkey foreign key (business_id)
    references public.businesses(id) on delete restrict;
exception when others then null; end $$;

do $$ begin
  alter table public.profiles drop constraint if exists profiles_branch_id_fkey;
  alter table public.profiles
    add constraint profiles_branch_id_fkey foreign key (branch_id)
    references public.branches(id) on delete set null;
exception when others then null; end $$;

create index if not exists profiles_business_id_idx on public.profiles (business_id);
create index if not exists profiles_branch_id_idx on public.profiles (branch_id);
create index if not exists profiles_role_id_idx on public.profiles (role_id);
create index if not exists profiles_auth_user_id_idx
  on public.profiles (auth_user_id) where auth_user_id is not null;

-- Backfill: profiles created before auth_user_id existed get it from the PK.
update public.profiles set auth_user_id = id where auth_user_id is null;

-- ---------------------------------------------------------------------------
-- user_branch_access (BACKEND_SETUP.md Part D1) — extra branch grants
-- ---------------------------------------------------------------------------
create table if not exists public.user_branch_access (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (profile_id, branch_id)
);
create index if not exists user_branch_access_branch_id_idx
  on public.user_branch_access (branch_id);

-- ===========================================================================
-- RLS helper functions (BACKEND_SETUP.md Part D1)
--   security definer + fixed search_path so they are safe inside policies.
-- ===========================================================================
create or replace function public.current_profile_id() returns uuid
language sql stable security definer set search_path = public, pg_temp as $$
  select pr.id
  from public.profiles pr
  where pr.auth_user_id = auth.uid() and pr.status = 'active'
$$;

create or replace function public.current_business_id() returns uuid
language sql stable security definer set search_path = public, pg_temp as $$
  select pr.business_id
  from public.profiles pr
  where pr.auth_user_id = auth.uid() and pr.status = 'active'
$$;

create or replace function public.current_branch_id() returns uuid
language sql stable security definer set search_path = public, pg_temp as $$
  select pr.branch_id
  from public.profiles pr
  where pr.auth_user_id = auth.uid() and pr.status = 'active'
$$;

create or replace function public.has_permission(p_key text) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1
    from public.profiles pr
    join public.role_permissions rp on rp.role_id = pr.role_id
    join public.permissions pm on pm.id = rp.permission_id
    where pr.auth_user_id = auth.uid()
      and pr.status = 'active'
      and pm.key = p_key
  )
$$;

create or replace function public.has_branch_access(p_branch uuid) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1 from public.profiles pr
    where pr.auth_user_id = auth.uid() and pr.status = 'active'
      and (
        pr.branch_id = p_branch
        or exists (
          select 1 from public.user_branch_access uba
          where uba.profile_id = pr.id and uba.branch_id = p_branch
        )
        or public.has_permission('branches.access_all')
      )
  )
$$;

-- Branch filter helper: NULL means "all branches of my business" (owner/manager).
create or replace function public.current_branch_id_or_all() returns uuid
language sql stable security definer set search_path = public, pg_temp as $$
  select case when public.has_permission('branches.access_all') then null
              else public.current_branch_id() end
$$;

-- ---------------------------------------------------------------------------
-- migrate:down
--   drop function if exists public.current_branch_id_or_all();
--   drop function if exists public.has_branch_access(uuid);
--   drop function if exists public.has_permission(text);
--   drop function if exists public.current_branch_id();
--   drop function if exists public.current_business_id();
--   drop function if exists public.current_profile_id();
--   drop table if exists public.user_branch_access;
--   -- column drops omitted (data-destructive)
-- ---------------------------------------------------------------------------
