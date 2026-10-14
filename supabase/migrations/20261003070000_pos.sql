-- =============================================================================
-- 060_pos
-- pos_terminals, pos_shifts, cash_movements, invoice_sequences
-- (SPEC §14, §78 · BACKEND_SETUP.md Part B7).
--
-- SPEC calls the shift table `shifts`; this project names it `pos_shifts`
-- because `shifts` is already taken by a legacy dashboard table. Documented
-- deviation — see BACKEND_SETUP_NOTES.md.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- pos_terminals — one row per physical counter/device
-- ---------------------------------------------------------------------------
create table if not exists public.pos_terminals (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  name text not null,
  device_fingerprint text,
  status text not null default 'active',
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$ begin
  alter table public.pos_terminals
    add constraint pos_terminals_status_chk check (status in ('active','inactive'));
exception when duplicate_object then null; end $$;

create index if not exists pos_terminals_branch_idx on public.pos_terminals (branch_id);
create index if not exists pos_terminals_business_idx on public.pos_terminals (business_id);

-- ---------------------------------------------------------------------------
-- pos_shifts (SPEC §78)
-- ---------------------------------------------------------------------------
create table if not exists public.pos_shifts (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  terminal_id uuid references public.pos_terminals(id) on delete set null,
  opened_by uuid not null references public.profiles(id) on delete restrict,
  closed_by uuid references public.profiles(id) on delete set null,
  opening_float numeric(14,2) not null default 0,
  closing_counted numeric(14,2),
  expected_cash numeric(14,2),
  variance numeric(14,2),
  variance_reason text,
  status text not null default 'open',
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.pos_shifts
    add constraint pos_shifts_status_chk check (status in ('open','closed'));
exception when duplicate_object then null; end $$;

-- One open shift per user per branch (SPEC §78).
create unique index if not exists pos_shifts_one_open_uq
  on public.pos_shifts (branch_id, opened_by) where status = 'open';
create index if not exists pos_shifts_branch_idx on public.pos_shifts (branch_id, opened_at desc);
create index if not exists pos_shifts_opened_by_idx on public.pos_shifts (opened_by, opened_at desc);
create index if not exists pos_shifts_business_idx on public.pos_shifts (business_id);
create index if not exists pos_shifts_terminal_idx on public.pos_shifts (terminal_id);

-- ---------------------------------------------------------------------------
-- cash_movements (SPEC §14, §78)
-- ---------------------------------------------------------------------------
create table if not exists public.cash_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  shift_id uuid not null references public.pos_shifts(id) on delete restrict,
  type text not null,
  amount numeric(14,2) not null,
  note text,
  ref_table text,
  ref_id uuid,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.cash_movements
    add constraint cash_movements_type_chk
    check (type in ('sale','refund','drawer_in','drawer_out','float'));
exception when duplicate_object then null; end $$;

create index if not exists cash_movements_shift_idx on public.cash_movements (shift_id, created_at desc);
create index if not exists cash_movements_business_idx on public.cash_movements (business_id);
create index if not exists cash_movements_ref_idx on public.cash_movements (ref_table, ref_id);

-- ---------------------------------------------------------------------------
-- invoice_sequences (SPEC §75, §80) — locked counter per business/branch/kind
-- ---------------------------------------------------------------------------
create table if not exists public.invoice_sequences (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid references public.branches(id) on delete restrict,
  kind text not null,
  prefix text not null default '',
  next_value bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$ begin
  alter table public.invoice_sequences
    add constraint invoice_sequences_kind_chk
    check (kind in ('sale','purchase','transfer','count','adjustment'));
exception when duplicate_object then null; end $$;

create unique index if not exists invoice_sequences_scope_uq
  on public.invoice_sequences (
    business_id,
    coalesce(branch_id, '00000000-0000-0000-0000-000000000000'::uuid),
    kind
  );
create index if not exists invoice_sequences_business_idx on public.invoice_sequences (business_id);
create index if not exists invoice_sequences_branch_idx on public.invoice_sequences (branch_id);

-- ---------------------------------------------------------------------------
-- migrate:down
--   drop table if exists public.invoice_sequences;
--   drop table if exists public.cash_movements;
--   drop table if exists public.pos_shifts;
--   drop table if exists public.pos_terminals;
-- ---------------------------------------------------------------------------