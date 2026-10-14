-- =============================================================================
-- 070_sales
-- sales, sale_items, sale_payments, sale_returns, sale_return_items
-- (SPEC §10, §11, §75, §76).
-- Written only by complete_sale / cancel_sale / return_sale RPCs.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- sales (SPEC §75)
-- ---------------------------------------------------------------------------
create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  invoice_number text not null,
  shift_id uuid references public.pos_shifts(id) on delete restrict,
  cashier_id uuid references public.profiles(id) on delete set null,
  customer_id uuid references public.customers(id) on delete set null,
  subtotal numeric(14,2) not null default 0,
  discount_total numeric(14,2) not null default 0,
  tax_total numeric(14,2) not null default 0,
  grand_total numeric(14,2) not null default 0,
  amount_paid numeric(14,2) not null default 0,
  change_due numeric(14,2) not null default 0,
  status text not null default 'completed',
  idempotency_key text,
  note text,
  sold_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.sales
    add constraint sales_status_chk
    check (status in ('completed','cancelled','partially_returned','returned'));
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.sales
    add constraint sales_totals_chk check (grand_total >= 0 and amount_paid >= 0);
exception when duplicate_object then null; end $$;

create unique index if not exists sales_invoice_uq
  on public.sales (business_id, branch_id, invoice_number);
create unique index if not exists sales_idem_uq
  on public.sales (business_id, idempotency_key) where idempotency_key is not null;
create index if not exists sales_business_sold_idx on public.sales (business_id, sold_at desc);
create index if not exists sales_branch_sold_idx on public.sales (branch_id, sold_at desc);
create index if not exists sales_cashier_sold_idx on public.sales (cashier_id, sold_at desc);
create index if not exists sales_shift_idx on public.sales (shift_id);
create index if not exists sales_customer_idx on public.sales (customer_id, sold_at desc);
create index if not exists sales_status_idx on public.sales (status);

-- ---------------------------------------------------------------------------
-- sale_items (SPEC §76) — immutable historical snapshot
-- ---------------------------------------------------------------------------
create table if not exists public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete restrict,
  business_id uuid not null references public.businesses(id) on delete restrict,
  product_id uuid not null references public.products(id) on delete restrict,
  batch_id uuid references public.product_batches(id) on delete set null,
  name_snapshot text not null,
  sku_snapshot text,
  barcode_snapshot text,
  qty numeric(14,3) not null,
  unit_price numeric(14,2) not null,
  cost_at_sale numeric(14,4) not null default 0,
  discount numeric(14,2) not null default 0,
  tax_rate numeric(6,3) not null default 0,
  tax_amount numeric(14,2) not null default 0,
  line_total numeric(14,2) not null default 0,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.sale_items
    add constraint sale_items_qty_chk check (qty > 0);
exception when duplicate_object then null; end $$;

create index if not exists sale_items_sale_idx on public.sale_items (sale_id);
create index if not exists sale_items_product_idx on public.sale_items (product_id, created_at desc);
create index if not exists sale_items_business_idx on public.sale_items (business_id);
create index if not exists sale_items_batch_idx on public.sale_items (batch_id);

-- ---------------------------------------------------------------------------
-- sale_payments (SPEC §75) — split payments supported
-- ---------------------------------------------------------------------------
create table if not exists public.sale_payments (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete restrict,
  business_id uuid not null references public.businesses(id) on delete restrict,
  method text not null,
  amount numeric(14,2) not null,
  reference text,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.sale_payments
    add constraint sale_payments_method_chk
    check (method in ('cash','card','mobile_wallet','other'));
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.sale_payments
    add constraint sale_payments_amount_chk check (amount > 0);
exception when duplicate_object then null; end $$;

create index if not exists sale_payments_sale_idx on public.sale_payments (sale_id);
create index if not exists sale_payments_business_idx on public.sale_payments (business_id);

-- ---------------------------------------------------------------------------
-- sale_returns / sale_return_items (SPEC §11)
-- ---------------------------------------------------------------------------
create table if not exists public.sale_returns (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  sale_id uuid not null references public.sales(id) on delete restrict,
  refund_method text not null default 'cash',
  total_refund numeric(14,2) not null default 0,
  reason text not null,
  approved_by uuid references public.profiles(id) on delete set null,
  idempotency_key text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.sale_returns
    add constraint sale_returns_method_chk
    check (refund_method in ('cash','card','mobile_wallet','other'));
exception when duplicate_object then null; end $$;

create unique index if not exists sale_returns_idem_uq
  on public.sale_returns (business_id, idempotency_key) where idempotency_key is not null;
create index if not exists sale_returns_sale_idx on public.sale_returns (sale_id, created_at desc);
create index if not exists sale_returns_branch_idx on public.sale_returns (branch_id);
create index if not exists sale_returns_business_idx on public.sale_returns (business_id);

create table if not exists public.sale_return_items (
  id uuid primary key default gen_random_uuid(),
  return_id uuid not null references public.sale_returns(id) on delete cascade,
  sale_item_id uuid not null references public.sale_items(id) on delete restrict,
  product_id uuid not null references public.products(id) on delete restrict,
  qty numeric(14,3) not null,
  unit_price numeric(14,2) not null,
  tax_amount numeric(14,2) not null default 0,
  line_total numeric(14,2) not null default 0,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.sale_return_items
    add constraint sale_return_items_qty_chk check (qty > 0);
exception when duplicate_object then null; end $$;

create index if not exists sale_return_items_return_idx on public.sale_return_items (return_id);
create index if not exists sale_return_items_sale_item_idx on public.sale_return_items (sale_item_id);
create index if not exists sale_return_items_product_idx on public.sale_return_items (product_id);

-- ---------------------------------------------------------------------------
-- migrate:down
--   drop table if exists public.sale_return_items;
--   drop table if exists public.sale_returns;
--   drop table if exists public.sale_payments;
--   drop table if exists public.sale_items;
--   drop table if exists public.sales;
-- ---------------------------------------------------------------------------