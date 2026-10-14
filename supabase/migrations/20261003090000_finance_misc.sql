-- =============================================================================
-- 080_finance_misc
-- expense_categories, expenses, promotions, promotion_items, notifications,
-- audit_logs (SPEC §16, §17, §19, §27, §79, §80).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- expense_categories (SPEC §17) — business_id NULL = system category
-- ---------------------------------------------------------------------------
create table if not exists public.expense_categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references public.businesses(id) on delete cascade,
  name text not null,
  is_system boolean not null default false,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists expense_categories_name_uq
  on public.expense_categories (
    coalesce(business_id, '00000000-0000-0000-0000-000000000000'::uuid),
    lower(name)
  );
create index if not exists expense_categories_business_idx on public.expense_categories (business_id);

-- ---------------------------------------------------------------------------
-- expenses (SPEC §17)
-- ---------------------------------------------------------------------------
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  category_id uuid references public.expense_categories(id) on delete set null,
  shift_id uuid references public.pos_shifts(id) on delete set null,
  amount numeric(14,2) not null,
  paid_at timestamptz not null default now(),
  payment_method text not null default 'cash',
  payee text,
  receipt_url text,
  note text,
  status text not null default 'active',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$ begin
  alter table public.expenses
    add constraint expenses_amount_chk check (amount > 0);
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.expenses
    add constraint expenses_method_chk
    check (payment_method in ('cash','card','bank_transfer','mobile_wallet','other'));
exception when duplicate_object then null; end $$;

create index if not exists expenses_branch_idx on public.expenses (branch_id, paid_at desc);
create index if not exists expenses_category_idx on public.expenses (category_id);
create index if not exists expenses_shift_idx on public.expenses (shift_id);
create index if not exists expenses_business_idx on public.expenses (business_id, paid_at desc);

-- ---------------------------------------------------------------------------
-- promotions / promotion_items (SPEC §16)
-- ---------------------------------------------------------------------------
create table if not exists public.promotions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid references public.branches(id) on delete cascade,
  name text not null,
  promo_type text not null,
  value numeric(14,2) not null default 0,
  min_qty numeric(14,3) not null default 0,
  free_qty numeric(14,3) not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  is_stackable boolean not null default false,
  status text not null default 'active',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$ begin
  alter table public.promotions
    add constraint promotions_type_chk
    check (promo_type in ('percent_off','fixed_off','buy_x_get_y','price_per_unit'));
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.promotions
    add constraint promotions_window_chk
    check (ends_at is null or starts_at is null or ends_at > starts_at);
exception when duplicate_object then null; end $$;

create index if not exists promotions_business_idx on public.promotions (business_id);
create index if not exists promotions_branch_idx on public.promotions (branch_id);
create index if not exists promotions_window_idx on public.promotions (starts_at, ends_at);

create table if not exists public.promotion_items (
  id uuid primary key default gen_random_uuid(),
  promotion_id uuid not null references public.promotions(id) on delete cascade,
  product_id uuid references public.products(id) on delete cascade,
  category_id uuid references public.categories(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (product_id is not null or category_id is not null)
);

create index if not exists promotion_items_promotion_idx on public.promotion_items (promotion_id);
create index if not exists promotion_items_product_idx on public.promotion_items (product_id);
create index if not exists promotion_items_category_idx on public.promotion_items (category_id);

-- ---------------------------------------------------------------------------
-- notifications (SPEC §19)
-- ---------------------------------------------------------------------------
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  data jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.notifications
    add constraint notifications_type_chk check (type in (
      'LOW_STOCK','OUT_OF_STOCK','EXPIRING_SOON','EXPIRED',
      'SHIFT_VARIANCE','SYNC_FAILED','REFUND_LARGE','GENERAL'
    ));
exception when duplicate_object then null; end $$;

create index if not exists notifications_user_idx
  on public.notifications (user_id, created_at desc);
create index if not exists notifications_user_unread_idx
  on public.notifications (user_id, created_at desc) where is_read = false;
create index if not exists notifications_business_idx
  on public.notifications (business_id, created_at desc);
create index if not exists notifications_branch_idx on public.notifications (branch_id);

-- ---------------------------------------------------------------------------
-- audit_logs (SPEC §27) — append-only, enforced by trigger in 100_triggers
-- ---------------------------------------------------------------------------
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references public.businesses(id) on delete restrict,
  branch_id uuid references public.branches(id) on delete restrict,
  -- Deliberately NOT a foreign key: audit rows are immutable and must survive
  -- a profile removal. A FK with ON DELETE SET NULL would force an UPDATE on an
  -- append-only table, which the guard trigger rejects.
  actor_id uuid,
  action text not null,
  table_name text,
  row_id uuid,
  before_data jsonb,
  after_data jsonb,
  app_version text,
  created_at timestamptz not null default now()
);

create index if not exists audit_logs_business_idx on public.audit_logs (business_id, created_at desc);
create index if not exists audit_logs_table_row_idx on public.audit_logs (table_name, row_id);
create index if not exists audit_logs_actor_idx on public.audit_logs (actor_id, created_at desc);

-- ---------------------------------------------------------------------------
-- sync_log (SPEC §80) — server-side record of processed idempotency keys
-- ---------------------------------------------------------------------------
create table if not exists public.sync_log (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  kind text not null,
  idempotency_key text not null,
  ref_id uuid,
  processed_at timestamptz not null default now()
);

create unique index if not exists sync_log_kind_idem_uq
  on public.sync_log (business_id, kind, idempotency_key);
create index if not exists sync_log_business_idx on public.sync_log (business_id, processed_at desc);

-- ---------------------------------------------------------------------------
-- imports (SPEC §20, §80) — upload metadata + row errors
-- ---------------------------------------------------------------------------
create table if not exists public.imports (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete set null,
  kind text not null default 'products',
  file_path text,
  file_hash text,
  status text not null default 'uploaded',
  total_rows integer not null default 0,
  ok_rows integer not null default 0,
  error_rows integer not null default 0,
  errors jsonb not null default '[]'::jsonb,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

do $$ begin
  alter table public.imports
    add constraint imports_status_chk
    check (status in ('uploaded','validating','ready','committing','completed','failed'));
exception when duplicate_object then null; end $$;

create index if not exists imports_business_idx on public.imports (business_id, created_at desc);
create index if not exists imports_hash_idx on public.imports (business_id, file_hash);

-- ---------------------------------------------------------------------------
-- migrate:down
--   drop table if exists public.imports;
--   drop table if exists public.sync_log;
--   drop table if exists public.audit_logs;
--   drop table if exists public.notifications;
--   drop table if exists public.promotion_items;
--   drop table if exists public.promotions;
--   drop table if exists public.expenses;
--   drop table if exists public.expense_categories;
-- ---------------------------------------------------------------------------