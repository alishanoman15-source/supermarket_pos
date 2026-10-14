-- =============================================================================
-- 020_catalog
-- units, categories, brands, products, product_barcodes, price_history
-- (SPEC §68, §71, §72 · BACKEND_SETUP.md Part B3/C).
--
-- units/categories/brands/products already existed without constraints or RLS;
-- they are reconciled here rather than recreated.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- units (SPEC §5, §68) — business_id NULL = system unit shared by everyone
-- ---------------------------------------------------------------------------
alter table public.units add column if not exists key text;
alter table public.units add column if not exists decimals_allowed smallint not null default 0;
alter table public.units add column if not exists is_system boolean not null default false;
alter table public.units add column if not exists status text not null default 'active';
alter table public.units add column if not exists updated_at timestamptz not null default now();

do $$ begin
  alter table public.units
    add constraint units_decimals_chk check (decimals_allowed between 0 and 3);
exception when duplicate_object then null; end $$;

create unique index if not exists units_business_key_uq
  on public.units (coalesce(business_id, '00000000-0000-0000-0000-000000000000'::uuid), key)
  where key is not null;
create index if not exists units_business_id_idx on public.units (business_id);

-- ---------------------------------------------------------------------------
-- categories (SPEC §7, §68)
-- ---------------------------------------------------------------------------
alter table public.categories add column if not exists status text not null default 'active';
alter table public.categories add column if not exists updated_at timestamptz not null default now();
alter table public.categories add column if not exists deleted_at timestamptz;

create unique index if not exists categories_business_name_uq
  on public.categories (business_id, lower(name)) where deleted_at is null;
create index if not exists categories_business_id_idx on public.categories (business_id);
create index if not exists categories_parent_id_idx on public.categories (parent_id);

-- ---------------------------------------------------------------------------
-- brands (SPEC §7, §68)
-- ---------------------------------------------------------------------------
alter table public.brands add column if not exists status text not null default 'active';
alter table public.brands add column if not exists updated_at timestamptz not null default now();
alter table public.brands add column if not exists deleted_at timestamptz;

create unique index if not exists brands_business_name_uq
  on public.brands (business_id, lower(name)) where deleted_at is null;
create index if not exists brands_business_id_idx on public.brands (business_id);

-- ---------------------------------------------------------------------------
-- products (SPEC §6, §71)
-- ---------------------------------------------------------------------------
alter table public.products alter column purchase_price type numeric(14,2) using purchase_price::numeric(14,2);
alter table public.products alter column selling_price  type numeric(14,2) using selling_price::numeric(14,2);
alter table public.products alter column tax_rate       type numeric(6,3)  using tax_rate::numeric(6,3);
alter table public.products add column if not exists is_weight_based boolean not null default false;
alter table public.products add column if not exists track_batch boolean not null default false;
alter table public.products add column if not exists reorder_level numeric(14,3) not null default 0;
alter table public.products add column if not exists deleted_at timestamptz;
alter table public.products alter column status set default 'active';

do $$ begin
  alter table public.products
    add constraint products_prices_chk check (purchase_price >= 0 and selling_price >= 0);
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.products
    add constraint products_tax_chk check (tax_rate >= 0 and tax_rate <= 100);
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.products
    add constraint products_status_chk check (status in ('active','inactive','archived'));
exception when duplicate_object then null; end $$;

create unique index if not exists products_sku_uq
  on public.products (business_id, sku) where sku is not null;
create unique index if not exists products_barcode_uq
  on public.products (business_id, barcode)
  where barcode is not null and status = 'active';
create index if not exists products_business_id_idx on public.products (business_id);
create index if not exists products_category_id_idx on public.products (category_id);
create index if not exists products_brand_id_idx on public.products (brand_id);
create index if not exists products_unit_id_idx on public.products (unit_id);
create index if not exists products_status_idx on public.products (status) where status = 'active';
create index if not exists products_name_trgm on public.products using gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- product_barcodes (SPEC §71) — a product may carry several barcodes
-- ---------------------------------------------------------------------------
create table if not exists public.product_barcodes (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  product_id uuid not null references public.products(id) on delete cascade,
  barcode text not null,
  format text not null default 'EAN13',
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

do $$ begin
  alter table public.product_barcodes
    add constraint product_barcodes_format_chk
    check (format in ('EAN13','EAN8','UPCA','UPCE','CODE128','CODE39','QR'));
exception when duplicate_object then null; end $$;

create unique index if not exists product_barcodes_business_barcode_uq
  on public.product_barcodes (business_id, barcode);
create index if not exists product_barcodes_product_id_idx on public.product_barcodes (product_id);
create index if not exists product_barcodes_business_id_idx on public.product_barcodes (business_id);

-- ---------------------------------------------------------------------------
-- price_history (SPEC §72) — populated by trigger in 100_triggers
-- ---------------------------------------------------------------------------
create table if not exists public.price_history (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  product_id uuid not null references public.products(id) on delete cascade,
  old_selling_price numeric(14,2),
  new_selling_price numeric(14,2),
  old_purchase_price numeric(14,2),
  new_purchase_price numeric(14,2),
  changed_by uuid references public.profiles(id) on delete set null,
  reason text,
  created_at timestamptz not null default now()
);

create index if not exists price_history_product_idx
  on public.price_history (product_id, created_at desc);
create index if not exists price_history_business_idx
  on public.price_history (business_id, created_at desc);

-- ---------------------------------------------------------------------------
-- migrate:down
--   drop table if exists public.price_history;
--   drop table if exists public.product_barcodes;
--   -- column/constraint drops omitted (data-destructive)
-- ---------------------------------------------------------------------------
