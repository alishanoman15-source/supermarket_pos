-- =============================================================================
-- 005_base_schema
-- Creates the ten core tables that the later migrations *reconcile* rather than
-- create. Without this file the migration set is not self-contained and cannot
-- apply to an empty database (SPEC §107, §95).
--
-- Ordering: runs after 000_extensions_and_helpers (gen_random_uuid, set_updated_at)
-- and BEFORE 010_core_tenancy / 020_catalog, which add columns, constraints and
-- indexes on top of these tables. Every statement is `if not exists` so applying
-- on a database that already has the tables is a no-op.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- businesses (SPEC §65, §30)
-- ---------------------------------------------------------------------------
create table if not exists public.businesses (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  legal_name  text,
  phone       text,
  email       text,
  address     text,
  currency    char(3) not null default 'PKR',
  timezone    text not null default 'Asia/Karachi',
  logo_url    text,
  settings    jsonb not null default '{}'::jsonb,
  status      text not null default 'active',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

-- ---------------------------------------------------------------------------
-- branches (SPEC §65)
-- ---------------------------------------------------------------------------
create table if not exists public.branches (
  id          uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  name        text not null,
  address     text,
  phone       text,
  is_active   boolean not null default true,
  status      text not null default 'active',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- permissions (SPEC §67) — platform-wide catalogue, keys are stable
-- ---------------------------------------------------------------------------
create table if not exists public.permissions (
  id          uuid primary key default gen_random_uuid(),
  key         text not null unique,
  description text,
  category    text,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- roles (SPEC §67) — per business; `key` is the stable template identifier
-- ---------------------------------------------------------------------------
create table if not exists public.roles (
  id          uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  key         text,
  name        text not null,
  description text,
  is_system   boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- role_permissions (SPEC §67)
-- ---------------------------------------------------------------------------
create table if not exists public.role_permissions (
  id            uuid primary key default gen_random_uuid(),
  role_id       uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  created_at    timestamptz not null default now(),
  unique (role_id, permission_id)
);

-- ---------------------------------------------------------------------------
-- profiles (SPEC §66) — id mirrors auth.users.id
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  auth_user_id uuid,
  business_id  uuid references public.businesses(id) on delete restrict,
  branch_id    uuid references public.branches(id) on delete set null,
  role_id      uuid references public.roles(id) on delete set null,
  name         text,
  phone        text,
  avatar_url   text,
  status       text not null default 'active',
  last_login_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists profiles_business_id_idx on public.profiles (business_id);
create index if not exists profiles_auth_user_id_idx on public.profiles (auth_user_id);

-- ---------------------------------------------------------------------------
-- units (SPEC §5, §68) — business_id NULL = system unit shared by everyone
-- ---------------------------------------------------------------------------
create table if not exists public.units (
  id              uuid primary key default gen_random_uuid(),
  business_id     uuid references public.businesses(id) on delete cascade,
  key             text,
  name            text not null,
  abbreviation    text,
  decimals_allowed smallint not null default 0,
  is_system       boolean not null default false,
  status          text not null default 'active',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- categories (SPEC §7, §68) — flat per-business, soft-deletable
-- ---------------------------------------------------------------------------
create table if not exists public.categories (
  id          uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  name        text not null,
  parent_id   uuid references public.categories(id) on delete set null,
  status      text not null default 'active',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

-- ---------------------------------------------------------------------------
-- brands (SPEC §7, §68)
-- ---------------------------------------------------------------------------
create table if not exists public.brands (
  id          uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  name        text not null,
  status      text not null default 'active',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

-- ---------------------------------------------------------------------------
-- products (SPEC §6, §71)
-- ---------------------------------------------------------------------------
create table if not exists public.products (
  id              uuid primary key default gen_random_uuid(),
  business_id     uuid not null references public.businesses(id) on delete restrict,
  name            text not null,
  sku             text,
  barcode         text,
  category_id     uuid references public.categories(id) on delete set null,
  brand_id        uuid references public.brands(id) on delete set null,
  unit_id         uuid references public.units(id) on delete set null,
  purchase_price  numeric(14,2) not null default 0,
  selling_price   numeric(14,2) not null default 0,
  tax_rate        numeric(6,3)  not null default 0,
  is_weight_based boolean not null default false,
  track_batch     boolean not null default false,
  reorder_level   numeric(14,3) not null default 0,
  image_url       text,
  description     text,
  status          text not null default 'active',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz
);

-- ---------------------------------------------------------------------------
-- migrate:down
--   -- dropped by 010/020/030 forward migrations; base tables are foundational
--   -- and are intentionally not dropped here (data-destructive).
-- ---------------------------------------------------------------------------
