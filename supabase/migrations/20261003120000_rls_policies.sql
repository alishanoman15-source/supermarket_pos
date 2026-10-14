-- =============================================================================
-- 110_rls_policies
-- RLS enabled on EVERY table in `public`, with policies that go through the
-- helper functions only (BACKEND_SETUP.md Part D).
--
-- Hard rules honoured here:
--   * cost/profit columns are never reachable by a cashier (products table
--     SELECT is revoked; POS reads product_pos_view, managers read
--     product_full_view which nulls cost without products.view_cost)
--   * inventories / stock_movements / sales / sale_items / sale_payments /
--     audit_logs are SELECT-only for clients — writes come from RPCs
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Helper: branch-scoped visibility predicate used by many policies.
-- ---------------------------------------------------------------------------
create or replace function public.can_see_branch(p_business uuid, p_branch uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select p_business = public.current_business_id()
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
$$;

-- ===========================================================================
-- CORE TENANCY
-- ===========================================================================
alter table public.businesses          enable row level security;
alter table public.branches            enable row level security;
alter table public.profiles            enable row level security;
alter table public.roles               enable row level security;
alter table public.permissions         enable row level security;
alter table public.role_permissions    enable row level security;
alter table public.user_branch_access  enable row level security;

-- businesses: a member sees only their own business
create policy businesses_select on public.businesses
  for select to authenticated
  using (id = public.current_business_id());

create policy businesses_update on public.businesses
  for update to authenticated
  using (id = public.current_business_id() and public.has_permission('settings.manage'))
  with check (id = public.current_business_id());

-- branches
create policy branches_select on public.branches
  for select to authenticated
  using (business_id = public.current_business_id());

create policy branches_insert on public.branches
  for insert to authenticated
  with check (business_id = public.current_business_id()
              and public.has_permission('branches.manage'));

create policy branches_update on public.branches
  for update to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('branches.manage'))
  with check (business_id = public.current_business_id());

-- profiles: self always, plus everyone in the same business
create policy profiles_select on public.profiles
  for select to authenticated
  using (
    auth_user_id = auth.uid()
    or business_id = public.current_business_id()
  );

create policy profiles_insert_self on public.profiles
  for insert to authenticated
  with check (auth_user_id = auth.uid());

create policy profiles_update_self on public.profiles
  for update to authenticated
  using (auth_user_id = auth.uid())
  with check (auth_user_id = auth.uid());

create policy profiles_update_manage on public.profiles
  for update to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('users.manage'))
  with check (business_id = public.current_business_id());

-- roles
create policy roles_select on public.roles
  for select to authenticated
  using (business_id = public.current_business_id());

create policy roles_insert on public.roles
  for insert to authenticated
  with check (business_id = public.current_business_id()
              and public.has_permission('roles.manage'));

create policy roles_update on public.roles
  for update to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('roles.manage'))
  with check (business_id = public.current_business_id());

create policy roles_delete on public.roles
  for delete to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('roles.manage')
         and is_system = false);

-- permissions: global catalogue, readable by any signed-in user
create policy permissions_select on public.permissions
  for select to authenticated
  using (true);

-- role_permissions: rows belong to roles of my business
create policy role_permissions_select on public.role_permissions
  for select to authenticated
  using (exists (
    select 1 from public.roles r
     where r.id = role_id and r.business_id = public.current_business_id()
  ));

create policy role_permissions_write on public.role_permissions
  for all to authenticated
  using (exists (
    select 1 from public.roles r
     where r.id = role_id and r.business_id = public.current_business_id()
  ) and public.has_permission('roles.manage'))
  with check (exists (
    select 1 from public.roles r
     where r.id = role_id and r.business_id = public.current_business_id()
  ) and public.has_permission('roles.manage'));

-- user_branch_access
create policy user_branch_access_select on public.user_branch_access
  for select to authenticated
  using (exists (
    select 1 from public.profiles p
     where p.id = profile_id and p.business_id = public.current_business_id()
  ));

create policy user_branch_access_write on public.user_branch_access
  for all to authenticated
  using (public.has_permission('users.manage')
         and exists (select 1 from public.branches b
                      where b.id = branch_id
                        and b.business_id = public.current_business_id()))
  with check (public.has_permission('users.manage')
              and exists (select 1 from public.branches b
                           where b.id = branch_id
                             and b.business_id = public.current_business_id()));

-- ===========================================================================
-- CATALOG
-- ===========================================================================
alter table public.units             enable row level security;
alter table public.categories        enable row level security;
alter table public.brands            enable row level security;
alter table public.products          enable row level security;
alter table public.product_barcodes  enable row level security;
alter table public.price_history     enable row level security;

-- units: system units (business_id null) + own business
create policy units_select on public.units
  for select to authenticated
  using (business_id is null or business_id = public.current_business_id());

create policy units_write on public.units
  for all to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('products.update'))
  with check (business_id = public.current_business_id()
              and public.has_permission('products.update'));

-- categories
create policy categories_select on public.categories
  for select to authenticated
  using (business_id = public.current_business_id());

create policy categories_insert on public.categories
  for insert to authenticated
  with check (business_id = public.current_business_id()
              and public.has_permission('products.create'));

create policy categories_update on public.categories
  for update to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('products.update'))
  with check (business_id = public.current_business_id());

-- brands
create policy brands_select on public.brands
  for select to authenticated
  using (business_id = public.current_business_id());

create policy brands_insert on public.brands
  for insert to authenticated
  with check (business_id = public.current_business_id()
              and public.has_permission('products.create'));

create policy brands_update on public.brands
  for update to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('products.update'))
  with check (business_id = public.current_business_id());

-- products (row-level). Column-level cost protection is handled by revoking
-- table SELECT and routing reads through product_pos_view / product_full_view.
create policy products_select on public.products
  for select to authenticated
  using (business_id = public.current_business_id());

create policy products_insert on public.products
  for insert to authenticated
  with check (business_id = public.current_business_id()
              and public.has_permission('products.create'));

create policy products_update on public.products
  for update to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('products.update'))
  with check (business_id = public.current_business_id());

-- product_barcodes
create policy product_barcodes_select on public.product_barcodes
  for select to authenticated
  using (business_id = public.current_business_id());

create policy product_barcodes_write on public.product_barcodes
  for all to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('products.update'))
  with check (business_id = public.current_business_id()
              and public.has_permission('products.update'));

-- price_history: cost-bearing → needs products.view_cost
create policy price_history_select on public.price_history
  for select to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('products.view_cost'));

-- ===========================================================================
-- INVENTORY  (SELECT only for clients — all writes via RPC)
-- ===========================================================================
alter table public.inventories            enable row level security;
alter table public.product_batches        enable row level security;
alter table public.stock_movements        enable row level security;
alter table public.inventory_adjustments  enable row level security;
alter table public.stock_counts           enable row level security;
alter table public.stock_count_items      enable row level security;
alter table public.stock_transfers        enable row level security;
alter table public.stock_transfer_items   enable row level security;

create policy inventories_select on public.inventories
  for select to authenticated
  using (public.can_see_branch(business_id, branch_id)
         and public.has_permission('inventory.view'));

create policy product_batches_select on public.product_batches
  for select to authenticated
  using (public.can_see_branch(business_id, branch_id)
         and public.has_permission('inventory.view'));

create policy stock_movements_select on public.stock_movements
  for select to authenticated
  using (public.can_see_branch(business_id, branch_id)
         and public.has_permission('inventory.view'));

create policy inventory_adjustments_select on public.inventory_adjustments
  for select to authenticated
  using (public.can_see_branch(business_id, branch_id)
         and public.has_permission('inventory.view'));

create policy stock_counts_select on public.stock_counts
  for select to authenticated
  using (public.can_see_branch(business_id, branch_id)
         and public.has_permission('inventory.count'));

create policy stock_count_items_select on public.stock_count_items
  for select to authenticated
  using (exists (
    select 1 from public.stock_counts sc
     where sc.id = stock_count_id
       and public.can_see_branch(sc.business_id, sc.branch_id)
       and public.has_permission('inventory.count')
  ));

create policy stock_transfers_select on public.stock_transfers
  for select to authenticated
  using (public.can_see_branch(business_id, from_branch_id)
         and public.has_permission('inventory.view'));

create policy stock_transfer_items_select on public.stock_transfer_items
  for select to authenticated
  using (exists (
    select 1 from public.stock_transfers st
     where st.id = transfer_id
       and public.can_see_branch(st.business_id, st.from_branch_id)
       and public.has_permission('inventory.view')
  ));

-- ===========================================================================
-- PARTIES
-- ===========================================================================
alter table public.suppliers             enable row level security;
alter table public.customers             enable row level security;
alter table public.loyalty_transactions  enable row level security;

-- supplier data is confidential → purchases.view, not products.view
create policy suppliers_select on public.suppliers
  for select to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('purchases.view'));

create policy suppliers_write on public.suppliers
  for all to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('suppliers.manage'))
  with check (business_id = public.current_business_id()
              and public.has_permission('suppliers.manage'));

create policy customers_select on public.customers
  for select to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('customers.manage'));

create policy customers_write on public.customers
  for all to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('customers.manage'))
  with check (business_id = public.current_business_id()
              and public.has_permission('customers.manage'));

create policy loyalty_transactions_select on public.loyalty_transactions
  for select to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('customers.manage'));

-- ===========================================================================
-- PURCHASING
-- ===========================================================================
alter table public.purchase_orders       enable row level security;
alter table public.purchase_order_items  enable row level security;
alter table public.purchases             enable row level security;
alter table public.purchase_items        enable row level security;
alter table public.supplier_payments     enable row level security;

create policy purchase_orders_select on public.purchase_orders
  for select to authenticated
  using (public.can_see_branch(business_id, branch_id)
         and public.has_permission('purchases.view'));

create policy purchase_orders_insert on public.purchase_orders
  for insert to authenticated
  with check (business_id = public.current_business_id()
              and public.has_permission('purchases.create'));

create policy purchase_order_items_select on public.purchase_order_items
  for select to authenticated
  using (exists (
    select 1 from public.purchase_orders po
     where po.id = purchase_order_id
       and public.can_see_branch(po.business_id, po.branch_id)
       and public.has_permission('purchases.view')
  ));

create policy purchases_select on public.purchases
  for select to authenticated
  using (public.can_see_branch(business_id, branch_id)
         and public.has_permission('purchases.view'));

create policy purchase_items_select on public.purchase_items
  for select to authenticated
  using (exists (
    select 1 from public.purchases pu
     where pu.id = purchase_id
       and public.can_see_branch(pu.business_id, pu.branch_id)
       and public.has_permission('purchases.view')
  ));

create policy supplier_payments_select on public.supplier_payments
  for select to authenticated
  using (public.can_see_branch(business_id, branch_id)
         and public.has_permission('purchases.view'));

-- ===========================================================================
-- POS  (SELECT only for clients)
-- ===========================================================================
alter table public.pos_terminals    enable row level security;
alter table public.pos_shifts       enable row level security;
alter table public.cash_movements   enable row level security;
alter table public.invoice_sequences enable row level security;

create policy pos_terminals_select on public.pos_terminals
  for select to authenticated
  using (public.can_see_branch(business_id, branch_id)
         and public.has_permission('pos.sell'));

create policy pos_shifts_select on public.pos_shifts
  for select to authenticated
  using (
    (opened_by = public.current_profile_id() and public.has_permission('pos.sell'))
    or (public.can_see_branch(business_id, branch_id)
        and public.has_permission('shifts.close'))
  );

create policy cash_movements_select on public.cash_movements
  for select to authenticated
  using (exists (
    select 1 from public.pos_shifts s
     where s.id = shift_id
       and (s.opened_by = public.current_profile_id()
            or (s.business_id = public.current_business_id()
                and public.has_permission('shifts.close')))
  ));

-- invoice_sequences is internal: no client policy at all (RPC-only).

-- ===========================================================================
-- SALES  (SELECT only for clients)
-- ===========================================================================
alter table public.sales               enable row level security;
alter table public.sale_items          enable row level security;
alter table public.sale_payments       enable row level security;
alter table public.sale_returns        enable row level security;
alter table public.sale_return_items   enable row level security;

create policy sales_select on public.sales
  for select to authenticated
  using (
    public.can_see_branch(business_id, branch_id)
    and (
      public.has_permission('sales.view_all')
      or (public.has_permission('sales.view') and cashier_id = public.current_profile_id())
    )
  );

create policy sale_items_select on public.sale_items
  for select to authenticated
  using (exists (
    select 1 from public.sales s
     where s.id = sale_id
       and public.can_see_branch(s.business_id, s.branch_id)
       and (public.has_permission('sales.view_all')
            or (public.has_permission('sales.view') and s.cashier_id = public.current_profile_id()))
  ));

create policy sale_payments_select on public.sale_payments
  for select to authenticated
  using (exists (
    select 1 from public.sales s
     where s.id = sale_id
       and public.can_see_branch(s.business_id, s.branch_id)
       and (public.has_permission('sales.view_all')
            or (public.has_permission('sales.view') and s.cashier_id = public.current_profile_id()))
  ));

create policy sale_returns_select on public.sale_returns
  for select to authenticated
  using (public.can_see_branch(business_id, branch_id)
         and (public.has_permission('sales.view_all') or public.has_permission('sales.view')));

create policy sale_return_items_select on public.sale_return_items
  for select to authenticated
  using (exists (
    select 1 from public.sale_returns r
     where r.id = return_id
       and public.can_see_branch(r.business_id, r.branch_id)
       and (public.has_permission('sales.view_all') or public.has_permission('sales.view'))
  ));

-- ===========================================================================
-- FINANCE & MISC
-- ===========================================================================
alter table public.expense_categories  enable row level security;
alter table public.expenses            enable row level security;
alter table public.promotions          enable row level security;
alter table public.promotion_items     enable row level security;
alter table public.notifications       enable row level security;
alter table public.audit_logs          enable row level security;
alter table public.sync_log            enable row level security;
alter table public.imports             enable row level security;

create policy expense_categories_select on public.expense_categories
  for select to authenticated
  using (business_id is null or business_id = public.current_business_id());

create policy expense_categories_write on public.expense_categories
  for all to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('expenses.manage'))
  with check (business_id = public.current_business_id()
              and public.has_permission('expenses.manage'));

create policy expenses_select on public.expenses
  for select to authenticated
  using (public.can_see_branch(business_id, branch_id)
         and public.has_permission('expenses.manage'));

create policy expenses_write on public.expenses
  for all to authenticated
  using (public.can_see_branch(business_id, branch_id)
         and public.has_permission('expenses.manage'))
  with check (business_id = public.current_business_id()
              and public.has_permission('expenses.manage'));

create policy promotions_select on public.promotions
  for select to authenticated
  using (business_id = public.current_business_id());

create policy promotions_write on public.promotions
  for all to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('promotions.manage'))
  with check (business_id = public.current_business_id()
              and public.has_permission('promotions.manage'));

create policy promotion_items_select on public.promotion_items
  for select to authenticated
  using (exists (
    select 1 from public.promotions pr
     where pr.id = promotion_id
       and pr.business_id = public.current_business_id()
  ));

create policy promotion_items_write on public.promotion_items
  for all to authenticated
  using (exists (
    select 1 from public.promotions pr
     where pr.id = promotion_id
       and pr.business_id = public.current_business_id()
  ) and public.has_permission('promotions.manage'))
  with check (exists (
    select 1 from public.promotions pr
     where pr.id = promotion_id
       and pr.business_id = public.current_business_id()
  ) and public.has_permission('promotions.manage'));

-- notifications: strictly per-user
create policy notifications_select on public.notifications
  for select to authenticated
  using (user_id = public.current_profile_id()
         and business_id = public.current_business_id());

create policy notifications_update on public.notifications
  for update to authenticated
  using (user_id = public.current_profile_id())
  with check (user_id = public.current_profile_id());

-- audit_logs: read-only, permission gated (append-only trigger enforces the rest)
create policy audit_logs_select on public.audit_logs
  for select to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('audit.view'));

-- sync_log / imports
create policy sync_log_select on public.sync_log
  for select to authenticated
  using (business_id = public.current_business_id());

create policy imports_select on public.imports
  for select to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('data.import'));

create policy imports_write on public.imports
  for all to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('data.import'))
  with check (business_id = public.current_business_id()
              and public.has_permission('data.import'));

-- ===========================================================================
-- COLUMN-LEVEL COST PROTECTION (BACKEND_SETUP.md Part D3.3)
--   Direct SELECT on products is revoked; clients read a view instead.
--   product_full_view returns cost as NULL unless products.view_cost is held.
-- ===========================================================================
-- These views are intentionally NOT security_invoker: authenticated has no
-- direct SELECT on public.products, so the view reads the table as its owner.
-- Business isolation is re-applied by the explicit business filter below.
create or replace view public.product_pos_view as
select
  p.id,
  p.business_id,
  p.name,
  p.sku,
  p.barcode,
  p.selling_price as price,
  p.selling_price,
  p.tax_rate,
  p.category_id,
  p.brand_id,
  p.unit_id,
  p.description,
  p.image_url,
  p.is_weight_based,
  p.track_batch,
  p.reorder_level,
  p.status,
  p.created_at,
  p.updated_at,
  coalesce((select sum(i.on_hand) from public.inventories i where i.product_id = p.id), 0) as stock
from public.products p
where p.business_id = public.current_business_id();

create or replace view public.product_full_view as
select
  p.id,
  p.business_id,
  p.name,
  p.description,
  p.sku,
  p.barcode,
  p.category_id,
  p.brand_id,
  p.unit_id,
  p.selling_price,
  p.tax_rate,
  p.track_batch,
  p.is_weight_based,
  p.reorder_level,
  p.status,
  p.image_url,
  p.created_at,
  p.updated_at,
  case when public.has_permission('products.view_cost') then p.purchase_price else null end
    as purchase_price_visible,
  coalesce((select sum(i.on_hand) from public.inventories i where i.product_id = p.id), 0) as stock
from public.products p
where p.business_id = public.current_business_id();

-- Only SELECT is withdrawn (that is what protects the cost columns).
-- INSERT/UPDATE/DELETE stay granted so the row-level policies above still work;
-- a cashier can never UPDATE a cost column because products_update requires
-- the products.update permission.
revoke select on public.products from authenticated, anon;
grant insert, update, delete on public.products to authenticated;
grant select on public.product_pos_view  to authenticated;
grant select on public.product_full_view to authenticated;

comment on view public.product_pos_view is
  'POS-safe product projection: no purchase_price / cost. Read this instead of public.products.';
comment on view public.product_full_view is
  'Product projection that reveals purchase_price only to holders of products.view_cost.';

-- ===========================================================================
-- EXPLICIT WRITE REVOKES (BACKEND_SETUP.md Part D3.2)
--   Ledger / money tables are written exclusively by SECURITY DEFINER RPCs.
--   RLS already blocks client writes (there is no INSERT/UPDATE/DELETE policy),
--   but revoking the grants makes the intent explicit and stops the guard
--   triggers from being the only line of defence.
--   apply_stock_delta() runs as the table owner, so it is unaffected.
-- ===========================================================================
revoke insert, update, delete, truncate, references, trigger
  on public.inventories, public.stock_movements, public.sales, public.sale_items,
     public.sale_payments, public.audit_logs, public.loyalty_transactions,
     public.invoice_sequences, public.sale_returns, public.sale_return_items,
     public.cash_movements, public.pos_shifts
  from authenticated, anon;

-- anon is never a legitimate actor in this app
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;

-- ---------------------------------------------------------------------------
-- migrate:down
--   grant select on public.products to authenticated;
--   drop view if exists public.product_full_view;
--   drop view if exists public.product_pos_view;
--   drop function if exists public.can_see_branch(uuid, uuid);
--   (policies/RLS left enabled — disabling them would be a security regression)
-- ---------------------------------------------------------------------------