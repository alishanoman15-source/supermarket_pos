-- =============================================================================
-- 030_inventory
-- inventories, product_batches, stock_movements, stock_counts(+items),
-- stock_transfers(+items)  (SPEC §8, §13, §73–74, §79).
--
-- Nothing here is client-writable: writes happen only inside RPCs (Part D3).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- inventories (SPEC §73) — on-hand qty per (product, branch)
-- ---------------------------------------------------------------------------
create table if not exists public.inventories (
  product_id uuid not null references public.products(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  business_id uuid not null references public.businesses(id) on delete restrict,
  on_hand numeric(14,3) not null default 0,
  reserved numeric(14,3) not null default 0,
  wac numeric(14,4) not null default 0,
  updated_at timestamptz not null default now(),
  primary key (product_id, branch_id)
);

do $$ begin
  alter table public.inventories
    add constraint inventories_on_hand_chk check (on_hand >= -999999);
exception when duplicate_object then null; end $$;

create index if not exists inventories_branch_id_idx on public.inventories (branch_id);
create index if not exists inventories_business_id_idx on public.inventories (business_id);

-- ---------------------------------------------------------------------------
-- product_batches (SPEC §73) — FEFO source when products.track_batch
-- ---------------------------------------------------------------------------
create table if not exists public.product_batches (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  product_id uuid not null references public.products(id) on delete restrict,
  batch_no text not null,
  expiry_date date,
  qty numeric(14,3) not null default 0,
  received_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.product_batches
    add constraint product_batches_qty_chk check (qty >= 0);
exception when duplicate_object then null; end $$;

create index if not exists product_batches_product_branch_idx
  on public.product_batches (product_id, branch_id);
create index if not exists product_batches_expiry_idx
  on public.product_batches (branch_id, expiry_date) where expiry_date is not null;
create index if not exists product_batches_business_id_idx on public.product_batches (business_id);
create index if not exists product_batches_branch_id_idx on public.product_batches (branch_id);

-- ---------------------------------------------------------------------------
-- stock_movements (SPEC §74) — append-only ledger; one row per stock delta
-- ---------------------------------------------------------------------------
create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  product_id uuid not null references public.products(id) on delete restrict,
  movement_type text not null,
  qty_delta numeric(14,3) not null,
  qty_before numeric(14,3) not null,
  qty_after numeric(14,3) not null,
  ref_table text,
  ref_id uuid,
  reason text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.stock_movements
    add constraint stock_movements_type_chk check (movement_type in (
      'sale','sale_return','purchase','adjustment','count_correction',
      'transfer_in','transfer_out','opening'
    ));
exception when duplicate_object then null; end $$;

create index if not exists stock_movements_product_idx
  on public.stock_movements (product_id, created_at desc);
create index if not exists stock_movements_branch_idx
  on public.stock_movements (branch_id, created_at desc);
create index if not exists stock_movements_type_idx
  on public.stock_movements (movement_type, created_at desc);
create index if not exists stock_movements_ref_idx
  on public.stock_movements (ref_table, ref_id);
create index if not exists stock_movements_business_idx
  on public.stock_movements (business_id, created_at desc);

-- ---------------------------------------------------------------------------
-- inventory_adjustments (SPEC §79)
-- ---------------------------------------------------------------------------
create table if not exists public.inventory_adjustments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  product_id uuid not null references public.products(id) on delete restrict,
  qty_delta numeric(14,3) not null,
  reason text not null,
  note text,
  idempotency_key text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists inventory_adjustments_product_idx
  on public.inventory_adjustments (product_id, created_at desc);
create index if not exists inventory_adjustments_branch_id_idx on public.inventory_adjustments (branch_id);
create index if not exists inventory_adjustments_business_id_idx on public.inventory_adjustments (business_id);

-- ---------------------------------------------------------------------------
-- stock_counts / stock_count_items (SPEC §79)
-- ---------------------------------------------------------------------------
create table if not exists public.stock_counts (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  status text not null default 'draft',
  note text,
  started_by uuid references public.profiles(id) on delete set null,
  approved_by uuid references public.profiles(id) on delete set null,
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  approved_at timestamptz,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.stock_counts
    add constraint stock_counts_status_chk
    check (status in ('draft','submitted','approved','cancelled'));
exception when duplicate_object then null; end $$;

create index if not exists stock_counts_branch_idx on public.stock_counts (branch_id, created_at desc);
create index if not exists stock_counts_business_id_idx on public.stock_counts (business_id);

create table if not exists public.stock_count_items (
  id uuid primary key default gen_random_uuid(),
  stock_count_id uuid not null references public.stock_counts(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  system_qty numeric(14,3) not null default 0,
  counted_qty numeric(14,3),
  delta numeric(14,3),
  created_at timestamptz not null default now(),
  unique (stock_count_id, product_id)
);

create index if not exists stock_count_items_product_id_idx on public.stock_count_items (product_id);

-- ---------------------------------------------------------------------------
-- stock_transfers / stock_transfer_items (SPEC §79)
-- ---------------------------------------------------------------------------
create table if not exists public.stock_transfers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  from_branch_id uuid not null references public.branches(id) on delete restrict,
  to_branch_id uuid not null references public.branches(id) on delete restrict,
  status text not null default 'in_transit',
  note text,
  idempotency_key text,
  created_by uuid references public.profiles(id) on delete set null,
  received_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  received_at timestamptz
);

do $$ begin
  alter table public.stock_transfers
    add constraint stock_transfers_status_chk
    check (status in ('in_transit','received','cancelled'));
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.stock_transfers
    add constraint stock_transfers_branch_diff_chk check (from_branch_id <> to_branch_id);
exception when duplicate_object then null; end $$;

create index if not exists stock_transfers_from_branch_idx on public.stock_transfers (from_branch_id);
create index if not exists stock_transfers_to_branch_idx on public.stock_transfers (to_branch_id);
create index if not exists stock_transfers_business_id_idx on public.stock_transfers (business_id);

create table if not exists public.stock_transfer_items (
  id uuid primary key default gen_random_uuid(),
  transfer_id uuid not null references public.stock_transfers(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  qty numeric(14,3) not null,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.stock_transfer_items
    add constraint stock_transfer_items_qty_chk check (qty > 0);
exception when duplicate_object then null; end $$;

create index if not exists stock_transfer_items_product_id_idx on public.stock_transfer_items (product_id);

-- ---------------------------------------------------------------------------
-- migrate:down
--   drop table if exists public.stock_transfer_items;
--   drop table if exists public.stock_transfers;
--   drop table if exists public.stock_count_items;
--   drop table if exists public.stock_counts;
--   drop table if exists public.inventory_adjustments;
--   drop table if exists public.stock_movements;
--   drop table if exists public.product_batches;
--   drop table if exists public.inventories;
-- ---------------------------------------------------------------------------
