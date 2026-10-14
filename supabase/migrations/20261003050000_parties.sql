-- =============================================================================
-- 040_parties
-- suppliers, customers, loyalty_transactions (SPEC §12, §15, §69, §70).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- suppliers (SPEC §69)
-- ---------------------------------------------------------------------------
create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  name text not null,
  contact_person text,
  phone text,
  email text,
  address text,
  opening_balance numeric(14,2) not null default 0,
  status text not null default 'active',
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$ begin
  alter table public.suppliers
    add constraint suppliers_status_chk check (status in ('active','inactive'));
exception when duplicate_object then null; end $$;

create unique index if not exists suppliers_business_name_uq
  on public.suppliers (business_id, lower(name)) where deleted_at is null;
create index if not exists suppliers_business_id_idx on public.suppliers (business_id);
create index if not exists suppliers_name_trgm on public.suppliers using gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- customers (SPEC §70)
-- ---------------------------------------------------------------------------
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  name text not null,
  phone text,
  email text,
  address text,
  loyalty_points numeric(14,2) not null default 0,
  credit_limit numeric(14,2) not null default 0,
  status text not null default 'active',
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$ begin
  alter table public.customers
    add constraint customers_status_chk check (status in ('active','inactive'));
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.customers
    add constraint customers_loyalty_chk check (loyalty_points >= 0);
exception when duplicate_object then null; end $$;

create unique index if not exists customers_business_phone_uq
  on public.customers (business_id, phone)
  where phone is not null and deleted_at is null;
create index if not exists customers_business_id_idx on public.customers (business_id);
create index if not exists customers_name_idx on public.customers (business_id, lower(name));

-- ---------------------------------------------------------------------------
-- loyalty_transactions (SPEC §70) — append-only ledger
-- ---------------------------------------------------------------------------
create table if not exists public.loyalty_transactions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  customer_id uuid not null references public.customers(id) on delete restrict,
  sale_id uuid,
  type text not null,
  points numeric(14,2) not null,
  balance_after numeric(14,2) not null,
  note text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.loyalty_transactions
    add constraint loyalty_transactions_type_chk check (type in ('earn','redeem','adjust'));
exception when duplicate_object then null; end $$;

create index if not exists loyalty_transactions_customer_idx
  on public.loyalty_transactions (customer_id, created_at desc);
create index if not exists loyalty_transactions_business_id_idx
  on public.loyalty_transactions (business_id);

-- ---------------------------------------------------------------------------
-- migrate:down
--   drop table if exists public.loyalty_transactions;
--   drop table if exists public.customers;
--   drop table if exists public.suppliers;
-- ---------------------------------------------------------------------------