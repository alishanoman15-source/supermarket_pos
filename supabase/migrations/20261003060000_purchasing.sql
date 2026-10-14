-- =============================================================================
-- 050_purchasing
-- purchase_orders, purchase_order_items, purchases (bills), purchase_items,
-- supplier_payments (SPEC §12, §77).
-- Flow: draft → approved → received → paid (partial allowed); all via RPCs.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- purchase_orders (SPEC §77)
-- ---------------------------------------------------------------------------
create table if not exists public.purchase_orders (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  supplier_id uuid not null references public.suppliers(id) on delete restrict,
  po_number text,
  status text not null default 'draft',
  expected_at date,
  subtotal numeric(14,2) not null default 0,
  tax_total numeric(14,2) not null default 0,
  total numeric(14,2) not null default 0,
  note text,
  created_by uuid references public.profiles(id) on delete set null,
  approved_by uuid references public.profiles(id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$ begin
  alter table public.purchase_orders
    add constraint purchase_orders_status_chk
    check (status in ('draft','approved','partially_received','received','cancelled'));
exception when duplicate_object then null; end $$;

create unique index if not exists purchase_orders_number_uq
  on public.purchase_orders (business_id, po_number) where po_number is not null;
create index if not exists purchase_orders_supplier_idx on public.purchase_orders (supplier_id);
create index if not exists purchase_orders_branch_idx on public.purchase_orders (branch_id, created_at desc);
create index if not exists purchase_orders_business_idx on public.purchase_orders (business_id);
create index if not exists purchase_orders_status_idx on public.purchase_orders (status);

create table if not exists public.purchase_order_items (
  id uuid primary key default gen_random_uuid(),
  purchase_order_id uuid not null references public.purchase_orders(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  qty numeric(14,3) not null,
  received_qty numeric(14,3) not null default 0,
  unit_cost numeric(14,2) not null default 0,
  tax_rate numeric(6,3) not null default 0,
  line_total numeric(14,2) not null default 0,
  created_at timestamptz not null default now(),
  unique (purchase_order_id, product_id)
);

do $$ begin
  alter table public.purchase_order_items
    add constraint purchase_order_items_qty_chk check (qty > 0 and received_qty >= 0);
exception when duplicate_object then null; end $$;

create index if not exists purchase_order_items_product_idx
  on public.purchase_order_items (product_id);

-- ---------------------------------------------------------------------------
-- purchases (SPEC §77) — the received bill
-- ---------------------------------------------------------------------------
create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  supplier_id uuid not null references public.suppliers(id) on delete restrict,
  purchase_order_id uuid references public.purchase_orders(id) on delete set null,
  bill_number text,
  status text not null default 'unpaid',
  subtotal numeric(14,2) not null default 0,
  tax_total numeric(14,2) not null default 0,
  total numeric(14,2) not null default 0,
  paid_total numeric(14,2) not null default 0,
  idempotency_key text,
  received_by uuid references public.profiles(id) on delete set null,
  received_at timestamptz not null default now(),
  due_at date,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$ begin
  alter table public.purchases
    add constraint purchases_status_chk
    check (status in ('unpaid','partially_paid','paid','cancelled'));
exception when duplicate_object then null; end $$;

create unique index if not exists purchases_idem_uq
  on public.purchases (business_id, idempotency_key) where idempotency_key is not null;
create index if not exists purchases_supplier_idx on public.purchases (supplier_id, created_at desc);
create index if not exists purchases_branch_idx on public.purchases (branch_id, created_at desc);
create index if not exists purchases_business_idx on public.purchases (business_id);
create index if not exists purchases_po_idx on public.purchases (purchase_order_id);
create index if not exists purchases_status_idx on public.purchases (status);

create table if not exists public.purchase_items (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null references public.purchases(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  qty numeric(14,3) not null,
  unit_cost numeric(14,2) not null,
  tax_rate numeric(6,3) not null default 0,
  line_total numeric(14,2) not null default 0,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.purchase_items
    add constraint purchase_items_qty_chk check (qty > 0);
exception when duplicate_object then null; end $$;

create index if not exists purchase_items_purchase_idx on public.purchase_items (purchase_id);
create index if not exists purchase_items_product_idx on public.purchase_items (product_id);

-- ---------------------------------------------------------------------------
-- supplier_payments (SPEC §12, §77)
-- ---------------------------------------------------------------------------
create table if not exists public.supplier_payments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  supplier_id uuid not null references public.suppliers(id) on delete restrict,
  purchase_id uuid references public.purchases(id) on delete restrict,
  method text not null default 'cash',
  amount numeric(14,2) not null,
  reference text,
  note text,
  idempotency_key text,
  paid_by uuid references public.profiles(id) on delete set null,
  paid_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.supplier_payments
    add constraint supplier_payments_method_chk
    check (method in ('cash','card','bank_transfer','mobile_wallet','other'));
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.supplier_payments
    add constraint supplier_payments_amount_chk check (amount > 0);
exception when duplicate_object then null; end $$;

create unique index if not exists supplier_payments_idem_uq
  on public.supplier_payments (business_id, idempotency_key) where idempotency_key is not null;
create index if not exists supplier_payments_supplier_idx
  on public.supplier_payments (supplier_id, paid_at desc);
create index if not exists supplier_payments_purchase_idx on public.supplier_payments (purchase_id);
create index if not exists supplier_payments_branch_idx on public.supplier_payments (branch_id);
create index if not exists supplier_payments_business_idx on public.supplier_payments (business_id);

-- ---------------------------------------------------------------------------
-- migrate:down
--   drop table if exists public.supplier_payments;
--   drop table if exists public.purchase_items;
--   drop table if exists public.purchases;
--   drop table if exists public.purchase_order_items;
--   drop table if exists public.purchase_orders;
-- ---------------------------------------------------------------------------