-- =============================================================================
-- 090_functions_rpc
-- Shared helpers + every business RPC (BACKEND_SETUP.md Part F).
--
-- Conventions (mandatory):
--   * SECURITY DEFINER + SET search_path = public, pg_temp
--   * permission check is the first business step (has_permission / require_permission)
--   * stock rows locked with SELECT ... FOR UPDATE in a consistent (product_id) order
--   * errors raised as  RAISE EXCEPTION 'CODE: human text' USING ERRCODE='P0001'
--   * stock writes go through apply_stock_delta so exactly one movement row lands
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Error helper: raises the canonical  "<CODE>: <message>"  shape that the
-- Flutter ErrorMapper understands (lib/core/errors/error_codes.dart).
-- ---------------------------------------------------------------------------
create or replace function public.raise_app_error(
  p_code text,
  p_message text default '',
  p_details jsonb default '{}'::jsonb
) returns void
language plpgsql
as $$
begin
  raise exception '%: %', p_code, coalesce(nullif(p_message, ''), p_code)
    using errcode = 'P0001', detail = p_details::text;
end;
$$;

-- ---------------------------------------------------------------------------
-- require_permission: resolves the caller profile and asserts a permission.
-- Returns the profile id so callers do not query it twice.
-- ---------------------------------------------------------------------------
create or replace function public.require_permission(p_key text)
returns uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
begin
  v_profile := public.current_profile_id();
  if v_profile is null then
    perform public.raise_app_error('UNAUTHENTICATED', 'no active profile for caller');
  end if;
  if not public.has_permission(p_key) then
    perform public.raise_app_error('NO_PERMISSION', 'missing permission ' || p_key,
      jsonb_build_object('permission', p_key));
  end if;
  return v_profile;
end;
$$;

-- ---------------------------------------------------------------------------
-- allow_negative_stock: business setting, default false (SPEC §8).
-- ---------------------------------------------------------------------------
create or replace function public.allow_negative_stock(p_business uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (select (b.settings ->> 'allow_negative_stock')::boolean
       from public.businesses b where b.id = p_business),
    false
  )
$$;

-- ---------------------------------------------------------------------------
-- tax_inclusive: business setting, default false (SPEC §30).
-- ---------------------------------------------------------------------------
create or replace function public.tax_inclusive(p_business uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (select (b.settings ->> 'tax_inclusive')::boolean
       from public.businesses b where b.id = p_business),
    false
  )
$$;

-- ---------------------------------------------------------------------------
-- generate_invoice_number: locked counter per (business, branch, kind)
-- → PREFIX-000001 (SPEC §75, BACKEND_SETUP.md Part C).
-- ---------------------------------------------------------------------------
create or replace function public.generate_invoice_number(
  p_business uuid,
  p_branch uuid,
  p_kind text
) returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_row public.invoice_sequences%rowtype;
  v_number text;
begin
  insert into public.invoice_sequences (business_id, branch_id, kind, prefix, next_value)
  values (p_business, p_branch, p_kind, upper(left(p_kind, 3)) || '-', 1)
  on conflict do nothing;

  select * into v_row
    from public.invoice_sequences
   where business_id = p_business
     and kind = p_kind
     and branch_id is not distinct from p_branch
   for update;

  if not found then
    perform public.raise_app_error('INVALID_INVOICE_SEQUENCE', 'no sequence row for kind ' || p_kind);
  end if;

  v_number := v_row.prefix || lpad(v_row.next_value::text, 6, '0');

  update public.invoice_sequences
     set next_value = next_value + 1,
         updated_at = now()
   where id = v_row.id;

  return v_number;
end;
$$;

-- ---------------------------------------------------------------------------
-- apply_stock_delta: the ONLY sanctioned way to move stock.
--   * locks the inventory row (FOR UPDATE)
--   * enforces the negative-stock policy
--   * writes exactly one stock_movements row
--   * sets app.stock_write so the guard trigger permits the write
-- ---------------------------------------------------------------------------
create or replace function public.apply_stock_delta(
  p_business uuid,
  p_branch uuid,
  p_product uuid,
  p_delta numeric,
  p_type text,
  p_ref_table text default null,
  p_ref_id uuid default null,
  p_reason text default null,
  p_actor uuid default null
) returns numeric
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_before numeric;
  v_after numeric;
begin
  perform set_config('app.stock_write', 'on', true);

  select i.on_hand into v_before
    from public.inventories i
   where i.product_id = p_product and i.branch_id = p_branch
   for update;

  if not found then
    insert into public.inventories (product_id, branch_id, business_id, on_hand, reserved, wac)
    values (p_product, p_branch, p_business, 0, 0, 0)
    on conflict do nothing;

    select i.on_hand into v_before
      from public.inventories i
     where i.product_id = p_product and i.branch_id = p_branch
     for update;
  end if;

  v_before := coalesce(v_before, 0);
  v_after := v_before + p_delta;

  if v_after < 0 and not public.allow_negative_stock(p_business) then
    perform public.raise_app_error(
      'INSUFFICIENT_STOCK',
      format('on hand %s, requested %s', v_before, p_delta),
      jsonb_build_object('product_id', p_product, 'branch_id', p_branch, 'on_hand', v_before)
    );
  end if;

  update public.inventories
     set on_hand = v_after,
         updated_at = now()
   where product_id = p_product and branch_id = p_branch;

  insert into public.stock_movements (
    business_id, branch_id, product_id, movement_type,
    qty_delta, qty_before, qty_after, ref_table, ref_id, reason, created_by
  ) values (
    p_business, p_branch, p_product, p_type,
    p_delta, v_before, v_after, p_ref_table, p_ref_id, p_reason, p_actor
  );

  return v_after;
end;
$$;

-- ---------------------------------------------------------------------------
-- audit: append a row to audit_logs (SPEC §27).
-- ---------------------------------------------------------------------------
create or replace function public.write_audit(
  p_business uuid,
  p_branch uuid,
  p_action text,
  p_table text default null,
  p_row_id uuid default null,
  p_before jsonb default null,
  p_after jsonb default null
) returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.audit_logs (
    business_id, branch_id, actor_id, action, table_name, row_id, before_data, after_data
  ) values (
    p_business, p_branch, public.current_profile_id(), p_action, p_table, p_row_id, p_before, p_after
  );
end;
$$;

-- ===========================================================================
-- ONBOARDING
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- create_business_with_owner (SPEC §65)
--   Atomic: business + main branch + default roles/permissions + settings +
--   invoice sequences + caller profile promoted to Owner.
--   Only callable by a signed-in user who has no business yet.
-- ---------------------------------------------------------------------------
create or replace function public.create_business_with_owner(
  p_business jsonb,
  p_branch jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_existing uuid;
  v_business uuid;
  v_branch uuid;
  v_owner_role uuid;
  v_name text;
begin
  v_profile := public.current_profile_id();
  if v_profile is null then
    perform public.raise_app_error('UNAUTHENTICATED', 'sign in first');
  end if;

  select p.business_id into v_existing from public.profiles p where p.id = v_profile;
  if v_existing is not null then
    perform public.raise_app_error('VALIDATION_FAILED', 'profile already belongs to a business',
      jsonb_build_object('business_id', v_existing));
  end if;

  v_name := nullif(trim(p_business ->> 'name'), '');
  if v_name is null then
    perform public.raise_app_error('VALIDATION_FAILED', 'business name is required');
  end if;

  insert into public.businesses (name, legal_name, phone, email, address, currency, timezone, settings)
  values (
    v_name,
    p_business ->> 'legal_name',
    p_business ->> 'phone',
    p_business ->> 'email',
    p_business ->> 'address',
    coalesce(p_business ->> 'currency', 'PKR'),
    coalesce(p_business ->> 'timezone', 'Asia/Karachi'),
    coalesce(p_business -> 'settings', '{}'::jsonb)
  )
  returning id into v_business;

  insert into public.branches (business_id, name, address, phone)
  values (
    v_business,
    coalesce(nullif(trim(p_branch ->> 'name'), ''), 'Main Branch'),
    coalesce(p_branch ->> 'address', p_business ->> 'address'),
    coalesce(p_branch ->> 'phone', p_business ->> 'phone')
  )
  returning id into v_branch;

  -- Default role templates (SPEC §67, BACKEND_SETUP.md Part E).
  insert into public.roles (business_id, key, name, description, is_system)
  values
    (v_business, 'owner',   'Owner',   'Full access', true),
    (v_business, 'manager', 'Manager', 'All except role management', true),
    (v_business, 'cashier', 'Cashier', 'POS only, no cost/profit', true),
    (v_business, 'stocker', 'Stocker', 'Inventory operations', true),
    (v_business, 'viewer',  'Viewer',  'Read-only reports', true)
  on conflict do nothing;

  select id into v_owner_role
    from public.roles where business_id = v_business and key = 'owner';

  -- owner gets every permission
  insert into public.role_permissions (role_id, permission_id)
  select v_owner_role, pm.id from public.permissions pm
  on conflict do nothing;

  -- manager gets everything except roles.manage
  insert into public.role_permissions (role_id, permission_id)
  select r.id, pm.id
    from public.roles r
    join public.permissions pm on pm.key <> 'roles.manage'
   where r.business_id = v_business and r.key = 'manager'
  on conflict do nothing;

  -- cashier: POS + limited sales + customers + own shift report
  insert into public.role_permissions (role_id, permission_id)
  select r.id, pm.id
    from public.roles r
    join public.permissions pm on pm.key in (
      'pos.sell','pos.hold','products.view','inventory.view',
      'sales.view','customers.manage','shifts.open','shifts.close','cash.move',
      'reports.shift.self','notifications.view'
    )
   where r.business_id = v_business and r.key = 'cashier'
  on conflict do nothing;

  -- stocker: inventory operations
  insert into public.role_permissions (role_id, permission_id)
  select r.id, pm.id
    from public.roles r
    join public.permissions pm on pm.key in (
      'products.view','inventory.view','inventory.adjust','inventory.count',
      'inventory.transfer','notifications.view'
    )
   where r.business_id = v_business and r.key = 'stocker'
  on conflict do nothing;

  -- viewer: read-only reports
  insert into public.role_permissions (role_id, permission_id)
  select r.id, pm.id
    from public.roles r
    join public.permissions pm on pm.key in (
      'products.view','inventory.view','sales.view','sales.view_all',
      'reports.dashboard.view','reports.sales.view','reports.profit.view',
      'reports.inventory.view','reports.purchases.view','reports.cash.view',
      'notifications.view'
    )
   where r.business_id = v_business and r.key = 'viewer'
  on conflict do nothing;

  -- invoice sequences for this branch
  insert into public.invoice_sequences (business_id, branch_id, kind, prefix, next_value)
  values
    (v_business, v_branch, 'sale',       'INV-', 1),
    (v_business, v_branch, 'purchase',   'PO-',  1),
    (v_business, v_branch, 'transfer',   'TRF-', 1),
    (v_business, v_branch, 'count',      'CNT-', 1),
    (v_business, v_branch, 'adjustment', 'ADJ-', 1)
  on conflict do nothing;

  update public.profiles
     set business_id = v_business,
         branch_id = v_branch,
         role_id = v_owner_role,
         status = 'active',
         updated_at = now()
   where id = v_profile;

  perform public.write_audit(v_business, v_branch, 'business.create', 'businesses', v_business,
    null, jsonb_build_object('name', v_name));

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'business_id', v_business,
    'branch_id', v_branch,
    'role_id', v_owner_role
  ));
end;
$$;

-- ===========================================================================
-- POS / SALES
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- complete_sale (SPEC §10, §26 · BACKEND_SETUP.md Part F)
--   Server recomputes every total; client totals are never trusted.
-- ---------------------------------------------------------------------------
create or replace function public.complete_sale(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_branch uuid;
  v_shift public.pos_shifts%rowtype;
  v_sale_id uuid;
  v_existing uuid;
  v_idem text := nullif(p_payload ->> 'idempotency_key', '');
  v_invoice text;
  v_item jsonb;
  v_pay jsonb;
  v_product public.products%rowtype;
  v_qty numeric(14,3);
  v_unit_price numeric(14,2);
  v_override numeric(14,2);
  v_discount numeric(14,2);
  v_tax_rate numeric(6,3);
  v_net numeric(14,2);
  v_tax numeric(14,2);
  v_net_line numeric(14,2);
  v_wac numeric(14,4);
  v_subtotal numeric(14,2) := 0;
  v_discount_total numeric(14,2) := 0;
  v_tax_total numeric(14,2) := 0;
  v_cart_discount numeric(14,2) := 0;
  v_grand numeric(14,2) := 0;
  v_paid numeric(14,2) := 0;
  v_cash_paid numeric(14,2) := 0;
  v_change numeric(14,2) := 0;
  v_items jsonb := coalesce(p_payload -> 'items', '[]'::jsonb);
  v_payments jsonb := coalesce(p_payload -> 'payments', '[]'::jsonb);
  v_customer uuid := nullif(p_payload ->> 'customer_id', '')::uuid;
  v_inclusive boolean;
  v_loyalty_rate numeric(14,4);
  v_points numeric(14,2) := 0;
  v_new_balance numeric(14,2);
  v_batch record;
  v_remaining numeric(14,3);
  v_take numeric(14,3);
  v_lines jsonb := '[]'::jsonb;
  v_line jsonb;
begin
  v_profile := public.require_permission('pos.sell');
  v_business := public.current_business_id();
  if v_business is null then
    perform public.raise_app_error('NO_BUSINESS', 'caller has no business');
  end if;

  v_branch := coalesce(nullif(p_payload ->> 'branch_id', '')::uuid, public.current_branch_id());
  if v_branch is null then
    perform public.raise_app_error('VALIDATION_FAILED', 'branch_id is required');
  end if;
  if not public.has_branch_access(v_branch) then
    perform public.raise_app_error('NO_PERMISSION', 'no access to branch',
      jsonb_build_object('branch_id', v_branch));
  end if;

  -- Idempotency: a retried offline sale returns the original as success (§62).
  if v_idem is not null then
    select s.id into v_existing
      from public.sales s
     where s.business_id = v_business and s.idempotency_key = v_idem;
    if v_existing is not null then
      return jsonb_build_object('ok', true, 'data', jsonb_build_object(
        'sale_id', v_existing, 'duplicate', true));
    end if;
  end if;

  if jsonb_array_length(v_items) = 0 then
    perform public.raise_app_error('CART_EMPTY', 'no items in payload');
  end if;

  -- Shift must be open (§10 step 1).
  if nullif(p_payload ->> 'shift_id', '') is not null then
    select * into v_shift from public.pos_shifts
     where id = (p_payload ->> 'shift_id')::uuid;
  else
    select * into v_shift from public.pos_shifts
     where branch_id = v_branch and opened_by = v_profile and status = 'open'
     order by opened_at desc limit 1;
  end if;

  if not found or v_shift.status <> 'open' then
    perform public.raise_app_error('SHIFT_NOT_OPEN', 'open a shift before selling');
  end if;
  if v_shift.business_id <> v_business then
    perform public.raise_app_error('NO_PERMISSION', 'shift belongs to another business');
  end if;

  v_inclusive := public.tax_inclusive(v_business);
  v_cart_discount := coalesce((p_payload ->> 'cart_discount')::numeric, 0);
  if v_cart_discount < 0 then
    perform public.raise_app_error('INVALID_DISCOUNT', 'cart discount cannot be negative');
  end if;

  -- ---------------------------------------------------------------------
  -- Pass 1: validate, lock (consistent product_id order), compute totals.
  -- ---------------------------------------------------------------------
  for v_item in
    select value from jsonb_array_elements(v_items)
    order by (value ->> 'product_id')
  loop
    select * into v_product from public.products
     where id = (v_item ->> 'product_id')::uuid;

    if not found or v_product.business_id <> v_business then
      perform public.raise_app_error('PRODUCT_NOT_FOUND', 'unknown product',
        jsonb_build_object('product_id', v_item ->> 'product_id'));
    end if;
    if v_product.status <> 'active' then
      perform public.raise_app_error('PRODUCT_INACTIVE', v_product.name,
        jsonb_build_object('product_id', v_product.id));
    end if;

    v_qty := coalesce((v_item ->> 'qty')::numeric, 0);
    if v_qty <= 0 then
      perform public.raise_app_error('VALIDATION_FAILED', 'qty must be > 0',
        jsonb_build_object('product_id', v_product.id));
    end if;

    -- lock the inventory row for this product (no movement written here)
    perform set_config('app.stock_write', 'on', true);
    insert into public.inventories (product_id, branch_id, business_id, on_hand, reserved, wac)
    values (v_product.id, v_branch, v_business, 0, 0, 0)
    on conflict do nothing;

    select i.wac into v_wac from public.inventories i
     where i.product_id = v_product.id and i.branch_id = v_branch
     for update;
    v_wac := coalesce(v_wac, 0);

    v_unit_price := v_product.selling_price;
    v_override := nullif(v_item ->> 'unit_price', '')::numeric;
    if v_override is not null and v_override <> v_product.selling_price then
      if not public.has_permission('pricing.override') then
        perform public.raise_app_error('PRICE_OVERRIDE_FORBIDDEN', 'missing pricing.override',
          jsonb_build_object('product_id', v_product.id));
      end if;
      if v_override < 0 then
        perform public.raise_app_error('VALIDATION_FAILED', 'unit_price cannot be negative');
      end if;
      v_unit_price := v_override;
    end if;

    v_discount := coalesce((v_item ->> 'discount')::numeric, 0);
    if v_discount < 0 then
      perform public.raise_app_error('INVALID_DISCOUNT', 'discount cannot be negative',
        jsonb_build_object('product_id', v_product.id));
    end if;
    if v_discount > 0 and not public.has_permission('pricing.discount') then
      perform public.raise_app_error('INVALID_DISCOUNT', 'missing pricing.discount');
    end if;

    v_tax_rate := coalesce(v_product.tax_rate, 0);
    v_net := round(v_qty * v_unit_price, 2) - v_discount;
    if v_net < 0 then
      perform public.raise_app_error('INVALID_DISCOUNT', 'discount exceeds line value',
        jsonb_build_object('product_id', v_product.id));
    end if;

    if v_inclusive then
      v_tax := round(v_net - (v_net / (1 + v_tax_rate / 100.0)), 2);
      v_net_line := v_net;
    else
      v_tax := round(v_net * v_tax_rate / 100.0, 2);
      v_net_line := v_net + v_tax;
    end if;

    v_subtotal := v_subtotal + round(v_qty * v_unit_price, 2);
    v_discount_total := v_discount_total + v_discount;
    v_tax_total := v_tax_total + v_tax;

    v_lines := v_lines || jsonb_build_object(
      'product_id', v_product.id,
      'qty', v_qty,
      'unit_price', v_unit_price,
      'discount', v_discount,
      'tax_rate', v_tax_rate,
      'tax_amount', v_tax,
      'line_total', v_net_line,
      'name_snapshot', v_product.name,
      'sku_snapshot', v_product.sku,
      'barcode_snapshot', v_product.barcode,
      'cost_at_sale', v_wac
    );
  end loop;

  v_grand := v_subtotal - v_discount_total - v_cart_discount + v_tax_total;
  if v_grand < 0 then
    perform public.raise_app_error('NEGATIVE_TOTAL', 'grand total is negative');
  end if;
  if v_cart_discount > 0 and not public.has_permission('pricing.discount_cart') then
    perform public.raise_app_error('INVALID_DISCOUNT', 'missing pricing.discount_cart');
  end if;

  -- Payments must cover the server-computed total.
  for v_pay in select value from jsonb_array_elements(v_payments) loop
    v_paid := v_paid + coalesce((v_pay ->> 'amount')::numeric, 0);
    if (v_pay ->> 'method') = 'cash' then
      v_cash_paid := v_cash_paid + coalesce((v_pay ->> 'amount')::numeric, 0);
    end if;
  end loop;

  if v_paid < v_grand then
    perform public.raise_app_error('VALIDATION_FAILED', 'payments do not cover the total',
      jsonb_build_object('paid', v_paid, 'total', v_grand));
  end if;
  v_change := v_paid - v_grand;

  -- ---------------------------------------------------------------------
  -- Pass 2: write the sale.
  -- ---------------------------------------------------------------------
  v_invoice := public.generate_invoice_number(v_business, v_branch, 'sale');

  insert into public.sales (
    business_id, branch_id, invoice_number, shift_id, cashier_id, customer_id,
    subtotal, discount_total, tax_total, grand_total, amount_paid, change_due,
    status, idempotency_key, note
  ) values (
    v_business, v_branch, v_invoice, v_shift.id, v_profile, v_customer,
    v_subtotal, v_discount_total + v_cart_discount, v_tax_total, v_grand, v_paid, v_change,
    'completed', v_idem, p_payload ->> 'note'
  ) returning id into v_sale_id;

  for v_line in select value from jsonb_array_elements(v_lines) loop
    insert into public.sale_items (
      sale_id, business_id, product_id, name_snapshot, sku_snapshot, barcode_snapshot,
      qty, unit_price, cost_at_sale, discount, tax_rate, tax_amount, line_total
    ) values (
      v_sale_id, v_business,
      (v_line ->> 'product_id')::uuid,
      v_line ->> 'name_snapshot',
      v_line ->> 'sku_snapshot',
      v_line ->> 'barcode_snapshot',
      (v_line ->> 'qty')::numeric,
      (v_line ->> 'unit_price')::numeric,
      (v_line ->> 'cost_at_sale')::numeric,
      (v_line ->> 'discount')::numeric,
      (v_line ->> 'tax_rate')::numeric,
      (v_line ->> 'tax_amount')::numeric,
      (v_line ->> 'line_total')::numeric
    );
  end loop;

  for v_pay in select value from jsonb_array_elements(v_payments) loop
    insert into public.sale_payments (sale_id, business_id, method, amount, reference)
    values (
      v_sale_id, v_business,
      coalesce(v_pay ->> 'method', 'cash'),
      (v_pay ->> 'amount')::numeric,
      v_pay ->> 'reference'
    );
  end loop;

  -- Stock out + movement per line, FEFO batches when tracked.
  for v_line in select value from jsonb_array_elements(v_lines) order by (value ->> 'product_id') loop
    v_remaining := (v_line ->> 'qty')::numeric;

    if exists (select 1 from public.products p
                where p.id = (v_line ->> 'product_id')::uuid and p.track_batch) then
      for v_batch in
        select b.id, b.qty from public.product_batches b
         where b.product_id = (v_line ->> 'product_id')::uuid
           and b.branch_id = v_branch and b.qty > 0
         order by b.expiry_date nulls last, b.received_at
         for update
      loop
        exit when v_remaining <= 0;
        v_take := least(v_remaining, v_batch.qty);
        perform set_config('app.stock_write', 'on', true);
        update public.product_batches set qty = qty - v_take where id = v_batch.id;
        v_remaining := v_remaining - v_take;
      end loop;
    end if;

    perform public.apply_stock_delta(
      v_business, v_branch, (v_line ->> 'product_id')::uuid,
      -(v_line ->> 'qty')::numeric, 'sale', 'sales', v_sale_id,
      'sale ' || v_invoice, v_profile
    );
  end loop;

  -- Cash drawer movement (SPEC §78).
  if v_cash_paid > 0 then
    insert into public.cash_movements (business_id, shift_id, type, amount, note, ref_table, ref_id, created_by)
    values (v_business, v_shift.id, 'sale', v_cash_paid, 'sale ' || v_invoice, 'sales', v_sale_id, v_profile);
  end if;

  -- Loyalty earn (SPEC §15).
  if v_customer is not null then
    select coalesce((b.settings ->> 'loyalty_earn_rate')::numeric, 0)
      into v_loyalty_rate from public.businesses b where b.id = v_business;
    if coalesce(v_loyalty_rate, 0) > 0 then
      v_points := round(v_grand * v_loyalty_rate, 2);
      if v_points > 0 then
        update public.customers
           set loyalty_points = loyalty_points + v_points, updated_at = now()
         where id = v_customer and business_id = v_business
         returning loyalty_points into v_new_balance;
        insert into public.loyalty_transactions (
          business_id, customer_id, sale_id, type, points, balance_after, note, created_by
        ) values (v_business, v_customer, v_sale_id, 'earn', v_points, v_new_balance,
                  'earned on ' || v_invoice, v_profile);
      end if;
    end if;
  end if;

  perform public.write_audit(v_business, v_branch, 'sale.complete', 'sales', v_sale_id,
    null, jsonb_build_object('invoice_number', v_invoice, 'grand_total', v_grand));

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'sale_id', v_sale_id,
    'invoice_number', v_invoice,
    'subtotal', v_subtotal,
    'discount_total', v_discount_total + v_cart_discount,
    'tax_total', v_tax_total,
    'grand_total', v_grand,
    'amount_paid', v_paid,
    'change_due', v_change,
    'duplicate', false
  ));
end;
$$;

-- ---------------------------------------------------------------------------
-- cancel_sale (SPEC §11) — void a completed sale, restore stock.
-- ---------------------------------------------------------------------------
create or replace function public.cancel_sale(p_sale_id uuid, p_reason text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_sale public.sales%rowtype;
  v_item record;
begin
  v_profile := public.require_permission('sales.cancel');
  v_business := public.current_business_id();

  select * into v_sale from public.sales where id = p_sale_id for update;
  if not found or v_sale.business_id <> v_business then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'sale not found');
  end if;
  if v_sale.status = 'cancelled' then
    perform public.raise_app_error('VALIDATION_FAILED', 'sale already cancelled');
  end if;
  if v_sale.status <> 'completed' then
    perform public.raise_app_error('VALIDATION_FAILED', 'only a completed sale can be cancelled');
  end if;
  if coalesce(trim(p_reason), '') = '' then
    perform public.raise_app_error('VALIDATION_FAILED', 'a reason is required');
  end if;

  for v_item in
    select si.product_id, sum(si.qty) as qty
      from public.sale_items si where si.sale_id = p_sale_id
     group by si.product_id order by si.product_id
  loop
    perform public.apply_stock_delta(
      v_business, v_sale.branch_id, v_item.product_id, v_item.qty,
      'sale_return', 'sales', p_sale_id, 'cancel: ' || p_reason, v_profile);
  end loop;

  update public.sales set status = 'cancelled' where id = p_sale_id;

  if exists (select 1 from public.cash_movements cm
              where cm.ref_table = 'sales' and cm.ref_id = p_sale_id and cm.type = 'sale') then
    insert into public.cash_movements (business_id, shift_id, type, amount, note, ref_table, ref_id, created_by)
    select v_business, cm.shift_id, 'refund', cm.amount, 'cancel ' || v_sale.invoice_number,
           'sales', p_sale_id, v_profile
      from public.cash_movements cm
     where cm.ref_table = 'sales' and cm.ref_id = p_sale_id and cm.type = 'sale';
  end if;

  perform public.write_audit(v_business, v_sale.branch_id, 'sale.cancel', 'sales', p_sale_id,
    jsonb_build_object('status', 'completed'), jsonb_build_object('status', 'cancelled', 'reason', p_reason));

  return jsonb_build_object('ok', true, 'data', jsonb_build_object('sale_id', p_sale_id, 'status', 'cancelled'));
end;
$$;

-- ---------------------------------------------------------------------------
-- return_sale (SPEC §11) — partial returns capped at sold-minus-returned.
-- ---------------------------------------------------------------------------
create or replace function public.return_sale(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_sale public.sales%rowtype;
  v_sale_id uuid := (p_payload ->> 'sale_id')::uuid;
  v_idem text := nullif(p_payload ->> 'idempotency_key', '');
  v_reason text := p_payload ->> 'reason';
  v_method text := coalesce(p_payload ->> 'refund_method', 'cash');
  v_return_id uuid;
  v_existing uuid;
  v_line jsonb;
  v_item public.sale_items%rowtype;
  v_qty numeric(14,3);
  v_already numeric(14,3);
  v_refund numeric(14,2) := 0;
  v_tax numeric(14,2);
  v_line_total numeric(14,2);
  v_all_returned boolean;
  v_threshold numeric(14,2);
  v_cash_refund numeric(14,2) := 0;
  v_shift uuid;
  v_lines jsonb := '[]'::jsonb;
begin
  v_profile := public.require_permission('returns.process');
  v_business := public.current_business_id();

  if v_idem is not null then
    select r.id into v_existing from public.sale_returns r
     where r.business_id = v_business and r.idempotency_key = v_idem;
    if v_existing is not null then
      return jsonb_build_object('ok', true, 'data', jsonb_build_object(
        'return_id', v_existing, 'duplicate', true));
    end if;
  end if;

  select * into v_sale from public.sales where id = v_sale_id for update;
  if not found or v_sale.business_id <> v_business then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'sale not found');
  end if;
  if v_sale.status = 'cancelled' then
    perform public.raise_app_error('VALIDATION_FAILED', 'cancelled sale cannot be returned');
  end if;
  if coalesce(trim(v_reason), '') = '' then
    perform public.raise_app_error('VALIDATION_FAILED', 'a reason is required');
  end if;

  if jsonb_array_length(coalesce(p_payload -> 'items', '[]'::jsonb)) = 0 then
    perform public.raise_app_error('CART_EMPTY', 'no items to return');
  end if;

  for v_line in select value from jsonb_array_elements(p_payload -> 'items') loop
    select * into v_item from public.sale_items
     where id = (v_line ->> 'sale_item_id')::uuid and sale_id = v_sale_id;
    if not found then
      perform public.raise_app_error('PRODUCT_NOT_FOUND', 'sale item not found');
    end if;

    v_qty := coalesce((v_line ->> 'qty')::numeric, 0);
    if v_qty <= 0 then
      perform public.raise_app_error('VALIDATION_FAILED', 'return qty must be > 0');
    end if;

    select coalesce(sum(sri.qty), 0) into v_already
      from public.sale_return_items sri
     where sri.sale_item_id = v_item.id;

    if v_already + v_qty > v_item.qty then
      perform public.raise_app_error('VALIDATION_FAILED', 'return qty exceeds sold quantity',
        jsonb_build_object('sale_item_id', v_item.id, 'sold', v_item.qty, 'already', v_already));
    end if;

    v_line_total := round(v_qty * v_item.unit_price - (v_qty * v_item.discount / v_item.qty), 2);
    v_tax := round(v_qty * v_item.tax_amount / v_item.qty, 2);
    v_refund := v_refund + v_line_total + v_tax;

    v_lines := v_lines || jsonb_build_object(
      'sale_item_id', v_item.id,
      'product_id', v_item.product_id,
      'qty', v_qty,
      'unit_price', v_item.unit_price,
      'tax_amount', v_tax,
      'line_total', v_line_total + v_tax
    );
  end loop;

  -- Large refunds need manager approval (SPEC §11).
  select coalesce((b.settings ->> 'refund_approval_threshold')::numeric, 0)
    into v_threshold from public.businesses b where b.id = v_business;
  if coalesce(v_threshold, 0) > 0 and v_refund >= v_threshold
     and not public.has_permission('refund.large') then
    perform public.raise_app_error('REFUND_NEEDS_APPROVAL', 'refund exceeds the approval threshold',
      jsonb_build_object('amount', v_refund, 'threshold', v_threshold));
  end if;

  insert into public.sale_returns (
    business_id, branch_id, sale_id, refund_method, total_refund, reason,
    idempotency_key, created_by, approved_by
  ) values (
    v_business, v_sale.branch_id, v_sale_id, v_method, v_refund, v_reason,
    v_idem, v_profile,
    case when v_refund >= coalesce(v_threshold, 0) then v_profile else null end
  ) returning id into v_return_id;

  for v_line in select value from jsonb_array_elements(v_lines) loop
    insert into public.sale_return_items (
      return_id, sale_item_id, product_id, qty, unit_price, tax_amount, line_total
    ) values (
      v_return_id,
      (v_line ->> 'sale_item_id')::uuid,
      (v_line ->> 'product_id')::uuid,
      (v_line ->> 'qty')::numeric,
      (v_line ->> 'unit_price')::numeric,
      (v_line ->> 'tax_amount')::numeric,
      (v_line ->> 'line_total')::numeric
    );
  end loop;

  -- restore stock (one movement per product, in a consistent order)
  for v_line in
    select jsonb_build_object('product_id', x.product_id, 'qty', sum(x.qty)) as j
      from (
        select (value ->> 'product_id')::uuid as product_id,
               (value ->> 'qty')::numeric as qty
          from jsonb_array_elements(v_lines)
      ) x
     group by x.product_id
     order by x.product_id
  loop
    perform public.apply_stock_delta(
      v_business, v_sale.branch_id, (v_line ->> 'product_id')::uuid,
      (v_line ->> 'qty')::numeric, 'sale_return', 'sale_returns', v_return_id,
      'return ' || v_sale.invoice_number, v_profile);
  end loop;

  -- mark sale status
  select not exists (
    select 1 from public.sale_items si
     where si.sale_id = v_sale_id
       and si.qty > coalesce((
         select sum(sri.qty) from public.sale_return_items sri where sri.sale_item_id = si.id
       ), 0)
  ) into v_all_returned;

  update public.sales
     set status = case when v_all_returned then 'returned' else 'partially_returned' end
   where id = v_sale_id;

  if v_method = 'cash' then
    v_cash_refund := v_refund;
    select id into v_shift from public.pos_shifts
     where branch_id = v_sale.branch_id and opened_by = v_profile and status = 'open'
     order by opened_at desc limit 1;
    insert into public.cash_movements (business_id, shift_id, type, amount, note, ref_table, ref_id, created_by)
    values (v_business, v_shift, 'refund', v_cash_refund,
            'return ' || v_sale.invoice_number, 'sale_returns', v_return_id, v_profile);
  end if;

  perform public.write_audit(v_business, v_sale.branch_id, 'sale.return', 'sale_returns', v_return_id,
    null, jsonb_build_object('sale_id', v_sale_id, 'total_refund', v_refund, 'reason', v_reason));

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'return_id', v_return_id, 'sale_id', v_sale_id, 'total_refund', v_refund,
    'status', case when v_all_returned then 'returned' else 'partially_returned' end));
end;
$$;

-- ---------------------------------------------------------------------------
-- redeem_loyalty_points (SPEC §15)
-- ---------------------------------------------------------------------------
create or replace function public.redeem_loyalty_points(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_customer uuid := (p_payload ->> 'customer_id')::uuid;
  v_points numeric(14,2) := coalesce((p_payload ->> 'points')::numeric, 0);
  v_balance numeric(14,2);
  v_new numeric(14,2);
  v_sale uuid := nullif(p_payload ->> 'sale_id', '')::uuid;
begin
  v_profile := public.require_permission('pos.sell');
  v_business := public.current_business_id();

  if v_points <= 0 then
    perform public.raise_app_error('VALIDATION_FAILED', 'points must be > 0');
  end if;

  select c.loyalty_points into v_balance
    from public.customers c where c.id = v_customer and c.business_id = v_business
   for update;
  if not found then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'customer not found');
  end if;

  if v_balance < v_points then
    perform public.raise_app_error('INSUFFICIENT_POINTS', 'customer has fewer points',
      jsonb_build_object('balance', v_balance, 'requested', v_points));
  end if;

  v_new := v_balance - v_points;
  update public.customers set loyalty_points = v_new, updated_at = now() where id = v_customer;

  insert into public.loyalty_transactions (
    business_id, customer_id, sale_id, type, points, balance_after, note, created_by
  ) values (v_business, v_customer, v_sale, 'redeem', v_points, v_new,
            coalesce(p_payload ->> 'note', 'redeemed at POS'), v_profile);

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'customer_id', v_customer, 'points_redeemed', v_points, 'balance_after', v_new));
end;
$$;

-- ---------------------------------------------------------------------------
-- calculate_product_price / apply_promotion (SPEC §16, §82)
-- ---------------------------------------------------------------------------
create or replace function public.apply_promotion(
  p_product_id uuid,
  p_qty numeric,
  p_unit_price numeric
) returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_business uuid := public.current_business_id();
  v_promo public.promotions%rowtype;
  v_discount numeric(14,2) := 0;
  v_free numeric(14,3) := 0;
  v_price numeric(14,2) := p_unit_price;
  v_category uuid;
begin
  select p.category_id into v_category from public.products p where p.id = p_product_id;

  select * into v_promo
    from public.promotions pr
   where pr.business_id = v_business
     and pr.status = 'active'
     and (pr.starts_at is null or pr.starts_at <= now())
     and (pr.ends_at is null or pr.ends_at >= now())
     and exists (
       select 1 from public.promotion_items pi
        where pi.promotion_id = pr.id
          and (pi.product_id = p_product_id or pi.category_id = v_category)
     )
   order by pr.value desc
   limit 1;

  if not found then
    return jsonb_build_object('discount', 0, 'free_qty', 0, 'unit_price', p_unit_price, 'promotion_id', null);
  end if;

  if v_promo.promo_type = 'percent_off' then
    v_discount := round(p_unit_price * p_qty * v_promo.value / 100.0, 2);
  elsif v_promo.promo_type = 'fixed_off' then
    v_discount := least(v_promo.value, p_unit_price * p_qty);
  elsif v_promo.promo_type = 'buy_x_get_y' then
    if p_qty >= v_promo.min_qty + v_promo.free_qty and v_promo.min_qty > 0 then
      v_free := floor(p_qty / (v_promo.min_qty + v_promo.free_qty)) * v_promo.free_qty;
      v_discount := round(v_free * p_unit_price, 2);
    end if;
  elsif v_promo.promo_type = 'price_per_unit' then
    v_price := least(p_unit_price, v_promo.value);
    v_discount := round((p_unit_price - v_price) * p_qty, 2);
  end if;

  return jsonb_build_object(
    'discount', v_discount, 'free_qty', v_free,
    'unit_price', v_price, 'promotion_id', v_promo.id);
end;
$$;

create or replace function public.calculate_product_price(
  p_product_id uuid,
  p_qty numeric default 1
) returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_business uuid := public.current_business_id();
  v_price numeric(14,2);
  v_promo jsonb;
begin
  select p.selling_price into v_price
    from public.products p where p.id = p_product_id and p.business_id = v_business;
  if not found then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'unknown product');
  end if;
  v_promo := public.apply_promotion(p_product_id, p_qty, v_price);
  return jsonb_build_object(
    'unit_price', (v_promo ->> 'unit_price')::numeric,
    'discount', (v_promo ->> 'discount')::numeric,
    'promotion_id', v_promo -> 'promotion_id');
end;
$$;

-- ===========================================================================
-- INVENTORY
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- adjust_stock (SPEC §13)
-- ---------------------------------------------------------------------------
create or replace function public.adjust_stock(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_branch uuid;
  v_product uuid := (p_payload ->> 'product_id')::uuid;
  v_delta numeric(14,3) := coalesce((p_payload ->> 'qty_delta')::numeric, 0);
  v_reason text := p_payload ->> 'reason';
  v_idem text := nullif(p_payload ->> 'idempotency_key', '');
  v_adj_id uuid;
  v_after numeric;
begin
  v_profile := public.require_permission('inventory.adjust');
  v_business := public.current_business_id();
  v_branch := coalesce(nullif(p_payload ->> 'branch_id', '')::uuid, public.current_branch_id());

  if v_branch is null or not public.has_branch_access(v_branch) then
    perform public.raise_app_error('NO_PERMISSION', 'no access to branch');
  end if;
  if v_delta = 0 then
    perform public.raise_app_error('VALIDATION_FAILED', 'qty_delta cannot be zero');
  end if;
  if coalesce(trim(v_reason), '') = '' then
    perform public.raise_app_error('VALIDATION_FAILED', 'a reason is required');
  end if;
  if not exists (select 1 from public.products p
                  where p.id = v_product and p.business_id = v_business) then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'unknown product');
  end if;

  insert into public.inventory_adjustments (
    business_id, branch_id, product_id, qty_delta, reason, note, idempotency_key, created_by
  ) values (
    v_business, v_branch, v_product, v_delta, v_reason,
    p_payload ->> 'note', v_idem, v_profile
  ) returning id into v_adj_id;

  v_after := public.apply_stock_delta(
    v_business, v_branch, v_product, v_delta, 'adjustment',
    'inventory_adjustments', v_adj_id, v_reason, v_profile);

  perform public.write_audit(v_business, v_branch, 'stock.adjust', 'inventory_adjustments', v_adj_id,
    null, jsonb_build_object('product_id', v_product, 'qty_delta', v_delta, 'reason', v_reason));

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'adjustment_id', v_adj_id, 'qty_after', v_after));
end;
$$;

-- ---------------------------------------------------------------------------
-- start_stock_count / submit_stock_count / approve_stock_count (SPEC §13)
-- ---------------------------------------------------------------------------
create or replace function public.start_stock_count(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_branch uuid;
  v_count_id uuid;
begin
  v_profile := public.require_permission('inventory.count');
  v_business := public.current_business_id();
  v_branch := coalesce(nullif(p_payload ->> 'branch_id', '')::uuid, public.current_branch_id());

  if v_branch is null or not public.has_branch_access(v_branch) then
    perform public.raise_app_error('NO_PERMISSION', 'no access to branch');
  end if;

  insert into public.stock_counts (business_id, branch_id, status, note, started_by)
  values (v_business, v_branch, 'draft', p_payload ->> 'note', v_profile)
  returning id into v_count_id;

  insert into public.stock_count_items (stock_count_id, product_id, system_qty)
  select v_count_id, i.product_id, i.on_hand
    from public.inventories i
   where i.branch_id = v_branch
  on conflict do nothing;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object('stock_count_id', v_count_id));
end;
$$;

create or replace function public.submit_stock_count(p_stock_count_id uuid, p_items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_count public.stock_counts%rowtype;
  v_line jsonb;
begin
  v_profile := public.require_permission('inventory.count');
  v_business := public.current_business_id();

  select * into v_count from public.stock_counts where id = p_stock_count_id for update;
  if not found or v_count.business_id <> v_business then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'stock count not found');
  end if;
  if v_count.status <> 'draft' then
    perform public.raise_app_error('VALIDATION_FAILED', 'stock count is not in draft state');
  end if;

  for v_line in select value from jsonb_array_elements(coalesce(p_items, '[]'::jsonb)) loop
    update public.stock_count_items
       set counted_qty = (v_line ->> 'counted_qty')::numeric,
           delta = (v_line ->> 'counted_qty')::numeric - system_qty
     where stock_count_id = p_stock_count_id
       and product_id = (v_line ->> 'product_id')::uuid;
  end loop;

  update public.stock_counts
     set status = 'submitted', submitted_at = now()
   where id = p_stock_count_id;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'stock_count_id', p_stock_count_id, 'status', 'submitted'));
end;
$$;

create or replace function public.approve_stock_count(p_stock_count_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_count public.stock_counts%rowtype;
  v_item record;
  v_adjustments integer := 0;
begin
  v_profile := public.require_permission('inventory.count_approve');
  v_business := public.current_business_id();

  select * into v_count from public.stock_counts where id = p_stock_count_id for update;
  if not found or v_count.business_id <> v_business then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'stock count not found');
  end if;
  if v_count.status = 'approved' then
    perform public.raise_app_error('COUNT_ALREADY_APPROVED', 'stock count already approved');
  end if;
  if v_count.status <> 'submitted' then
    perform public.raise_app_error('VALIDATION_FAILED', 'stock count must be submitted first');
  end if;

  for v_item in
    select sci.product_id, sci.delta
      from public.stock_count_items sci
     where sci.stock_count_id = p_stock_count_id
       and sci.counted_qty is not null
       and coalesce(sci.delta, 0) <> 0
     order by sci.product_id
  loop
    perform public.apply_stock_delta(
      v_business, v_count.branch_id, v_item.product_id, v_item.delta,
      'count_correction', 'stock_counts', p_stock_count_id, 'stock count correction', v_profile);
    v_adjustments := v_adjustments + 1;
  end loop;

  update public.stock_counts
     set status = 'approved', approved_at = now(), approved_by = v_profile
   where id = p_stock_count_id;

  perform public.write_audit(v_business, v_count.branch_id, 'stock_count.approve',
    'stock_counts', p_stock_count_id, null, jsonb_build_object('adjustments', v_adjustments));

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'stock_count_id', p_stock_count_id, 'status', 'approved', 'adjustments', v_adjustments));
end;
$$;

-- ---------------------------------------------------------------------------
-- transfer_stock / receive_transfer (SPEC §13)
-- ---------------------------------------------------------------------------
create or replace function public.transfer_stock(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_from uuid := coalesce(nullif(p_payload ->> 'from_branch_id', '')::uuid, public.current_branch_id());
  v_to uuid := nullif(p_payload ->> 'to_branch_id', '')::uuid;
  v_transfer uuid;
  v_number text;
  v_line jsonb;
begin
  v_profile := public.require_permission('inventory.transfer');
  v_business := public.current_business_id();

  if v_from is null or v_to is null or v_from = v_to then
    perform public.raise_app_error('VALIDATION_FAILED', 'from and to branches must differ');
  end if;
  if not public.has_branch_access(v_from) then
    perform public.raise_app_error('NO_PERMISSION', 'no access to source branch');
  end if;
  if not exists (select 1 from public.branches b
                  where b.id = v_to and b.business_id = v_business) then
    perform public.raise_app_error('VALIDATION_FAILED', 'destination branch not found');
  end if;
  if jsonb_array_length(coalesce(p_payload -> 'items', '[]'::jsonb)) = 0 then
    perform public.raise_app_error('CART_EMPTY', 'no items to transfer');
  end if;

  v_number := public.generate_invoice_number(v_business, v_from, 'transfer');

  insert into public.stock_transfers (
    business_id, from_branch_id, to_branch_id, status, note, idempotency_key, created_by
  ) values (
    v_business, v_from, v_to, 'in_transit', p_payload ->> 'note',
    nullif(p_payload ->> 'idempotency_key', ''), v_profile
  ) returning id into v_transfer;

  for v_line in select value from jsonb_array_elements(p_payload -> 'items') order by (value ->> 'product_id') loop
    insert into public.stock_transfer_items (transfer_id, product_id, qty)
    values (v_transfer, (v_line ->> 'product_id')::uuid, (v_line ->> 'qty')::numeric);

    perform public.apply_stock_delta(
      v_business, v_from, (v_line ->> 'product_id')::uuid,
      -(v_line ->> 'qty')::numeric, 'transfer_out', 'stock_transfers', v_transfer,
      'transfer ' || v_number, v_profile);
  end loop;

  perform public.write_audit(v_business, v_from, 'transfer.create', 'stock_transfers', v_transfer,
    null, jsonb_build_object('to_branch_id', v_to));

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'transfer_id', v_transfer, 'status', 'in_transit'));
end;
$$;

create or replace function public.receive_transfer(p_transfer_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_tr public.stock_transfers%rowtype;
  v_item record;
begin
  v_profile := public.require_permission('inventory.transfer');
  v_business := public.current_business_id();

  select * into v_tr from public.stock_transfers where id = p_transfer_id for update;
  if not found or v_tr.business_id <> v_business then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'transfer not found');
  end if;
  if v_tr.status <> 'in_transit' then
    perform public.raise_app_error('TRANSFER_NOT_IN_TRANSIT', 'transfer is not in transit');
  end if;
  if not public.has_branch_access(v_tr.to_branch_id) then
    perform public.raise_app_error('NO_PERMISSION', 'no access to destination branch');
  end if;

  for v_item in
    select sti.product_id, sti.qty from public.stock_transfer_items sti
     where sti.transfer_id = p_transfer_id order by sti.product_id
  loop
    perform public.apply_stock_delta(
      v_business, v_tr.to_branch_id, v_item.product_id, v_item.qty,
      'transfer_in', 'stock_transfers', p_transfer_id, 'transfer received', v_profile);
  end loop;

  update public.stock_transfers
     set status = 'received', received_at = now(), received_by = v_profile
   where id = p_transfer_id;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'transfer_id', p_transfer_id, 'status', 'received'));
end;
$$;

-- ===========================================================================
-- PURCHASING
-- ===========================================================================

create or replace function public.create_purchase_order(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_branch uuid := coalesce(nullif(p_payload ->> 'branch_id', '')::uuid, public.current_branch_id());
  v_supplier uuid := (p_payload ->> 'supplier_id')::uuid;
  v_po uuid;
  v_number text;
  v_line jsonb;
  v_subtotal numeric(14,2) := 0;
  v_tax numeric(14,2) := 0;
begin
  v_profile := public.require_permission('purchases.create');
  v_business := public.current_business_id();

  if v_branch is null or not public.has_branch_access(v_branch) then
    perform public.raise_app_error('NO_PERMISSION', 'no access to branch');
  end if;
  if not exists (select 1 from public.suppliers s
                  where s.id = v_supplier and s.business_id = v_business) then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'supplier not found');
  end if;
  if jsonb_array_length(coalesce(p_payload -> 'items', '[]'::jsonb)) = 0 then
    perform public.raise_app_error('CART_EMPTY', 'no items on the order');
  end if;

  v_number := public.generate_invoice_number(v_business, v_branch, 'purchase');

  insert into public.purchase_orders (
    business_id, branch_id, supplier_id, po_number, status, expected_at, note, created_by
  ) values (
    v_business, v_branch, v_supplier, v_number, 'draft',
    nullif(p_payload ->> 'expected_at', '')::date, p_payload ->> 'note', v_profile
  ) returning id into v_po;

  for v_line in select value from jsonb_array_elements(p_payload -> 'items') loop
    v_subtotal := v_subtotal + round((v_line ->> 'qty')::numeric * (v_line ->> 'unit_cost')::numeric, 2);
    v_tax := v_tax + round(
      (v_line ->> 'qty')::numeric * (v_line ->> 'unit_cost')::numeric *
      coalesce((v_line ->> 'tax_rate')::numeric, 0) / 100.0, 2);

    insert into public.purchase_order_items (
      purchase_order_id, product_id, qty, unit_cost, tax_rate, line_total
    ) values (
      v_po, (v_line ->> 'product_id')::uuid, (v_line ->> 'qty')::numeric,
      (v_line ->> 'unit_cost')::numeric, coalesce((v_line ->> 'tax_rate')::numeric, 0),
      round((v_line ->> 'qty')::numeric * (v_line ->> 'unit_cost')::numeric, 2)
    );
  end loop;

  update public.purchase_orders
     set subtotal = v_subtotal, tax_total = v_tax, total = v_subtotal + v_tax
   where id = v_po;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'purchase_order_id', v_po, 'po_number', v_number, 'status', 'draft'));
end;
$$;

create or replace function public.approve_purchase_order(p_po_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_po public.purchase_orders%rowtype;
begin
  v_profile := public.require_permission('purchases.approve');
  v_business := public.current_business_id();

  select * into v_po from public.purchase_orders where id = p_po_id for update;
  if not found or v_po.business_id <> v_business then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'purchase order not found');
  end if;
  if v_po.status <> 'draft' then
    perform public.raise_app_error('PO_NOT_APPROVED', 'only a draft order can be approved');
  end if;

  update public.purchase_orders
     set status = 'approved', approved_by = v_profile, approved_at = now(), updated_at = now()
   where id = p_po_id;

  perform public.write_audit(v_business, v_po.branch_id, 'po.approve', 'purchase_orders', p_po_id,
    jsonb_build_object('status', 'draft'), jsonb_build_object('status', 'approved'));

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'purchase_order_id', p_po_id, 'status', 'approved'));
end;
$$;

-- ---------------------------------------------------------------------------
-- receive_purchase (SPEC §12, §55) — stock in + weighted-average cost.
-- ---------------------------------------------------------------------------
create or replace function public.receive_purchase(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_branch uuid;
  v_po public.purchase_orders%rowtype;
  v_supplier uuid;
  v_purchase uuid;
  v_line jsonb;
  v_product uuid;
  v_qty numeric(14,3);
  v_cost numeric(14,2);
  v_tax_rate numeric(6,3);
  v_on_hand numeric(14,3);
  v_wac numeric(14,4);
  v_new_wac numeric(14,4);
  v_subtotal numeric(14,2) := 0;
  v_tax numeric(14,2) := 0;
  v_po_item public.purchase_order_items%rowtype;
  v_fully_received boolean;
  v_idem text := nullif(p_payload ->> 'idempotency_key', '');
  v_existing uuid;
  v_batch_no text;
  v_expiry date;
begin
  v_profile := public.require_permission('purchases.receive');
  v_business := public.current_business_id();

  if v_idem is not null then
    select pu.id into v_existing from public.purchases pu
     where pu.business_id = v_business and pu.idempotency_key = v_idem;
    if v_existing is not null then
      return jsonb_build_object('ok', true, 'data', jsonb_build_object(
        'purchase_id', v_existing, 'duplicate', true));
    end if;
  end if;

  if nullif(p_payload ->> 'purchase_order_id', '') is not null then
    select * into v_po from public.purchase_orders
     where id = (p_payload ->> 'purchase_order_id')::uuid for update;
    if not found or v_po.business_id <> v_business then
      perform public.raise_app_error('PRODUCT_NOT_FOUND', 'purchase order not found');
    end if;
    if v_po.status not in ('approved','partially_received') then
      perform public.raise_app_error('PO_NOT_APPROVED', 'purchase order must be approved first');
    end if;
    v_branch := v_po.branch_id;
    v_supplier := v_po.supplier_id;
  else
    v_branch := coalesce(nullif(p_payload ->> 'branch_id', '')::uuid, public.current_branch_id());
    v_supplier := (p_payload ->> 'supplier_id')::uuid;
  end if;

  if v_branch is null or not public.has_branch_access(v_branch) then
    perform public.raise_app_error('NO_PERMISSION', 'no access to branch');
  end if;
  if jsonb_array_length(coalesce(p_payload -> 'items', '[]'::jsonb)) = 0 then
    perform public.raise_app_error('CART_EMPTY', 'nothing received');
  end if;

  insert into public.purchases (
    business_id, branch_id, supplier_id, purchase_order_id, bill_number, status,
    idempotency_key, received_by, due_at, note
  ) values (
    v_business, v_branch, v_supplier, v_po.id,
    coalesce(nullif(p_payload ->> 'bill_number', ''), public.generate_invoice_number(v_business, v_branch, 'purchase')),
    'unpaid', v_idem, v_profile, nullif(p_payload ->> 'due_at', '')::date, p_payload ->> 'note'
  ) returning id into v_purchase;

  for v_line in select value from jsonb_array_elements(p_payload -> 'items') order by (value ->> 'product_id') loop
    v_product := (v_line ->> 'product_id')::uuid;
    v_qty := (v_line ->> 'qty')::numeric;
    v_cost := (v_line ->> 'unit_cost')::numeric;
    v_tax_rate := coalesce((v_line ->> 'tax_rate')::numeric, 0);

    if v_qty <= 0 then
      perform public.raise_app_error('VALIDATION_FAILED', 'received qty must be > 0');
    end if;

    -- lock the inventory row so the WAC maths is race-free (§55)
    perform set_config('app.stock_write', 'on', true);
    select i.on_hand, i.wac into v_on_hand, v_wac
      from public.inventories i
     where i.product_id = v_product and i.branch_id = v_branch
     for update;

    if not found then
      insert into public.inventories (product_id, branch_id, business_id, on_hand, reserved, wac)
      values (v_product, v_branch, v_business, 0, 0, 0) on conflict do nothing;
      select i.on_hand, i.wac into v_on_hand, v_wac
        from public.inventories i
       where i.product_id = v_product and i.branch_id = v_branch for update;
    end if;

    v_on_hand := coalesce(v_on_hand, 0);
    v_wac := coalesce(v_wac, 0);

    -- WAC rule (SPEC §55)
    if v_on_hand <= 0 then
      v_new_wac := v_cost;
    else
      v_new_wac := ((v_on_hand * v_wac) + (v_qty * v_cost)) / (v_on_hand + v_qty);
    end if;

    update public.inventories
       set wac = round(v_new_wac, 4), updated_at = now()
     where product_id = v_product and branch_id = v_branch;

    insert into public.purchase_items (purchase_id, product_id, qty, unit_cost, tax_rate, line_total)
    values (v_purchase, v_product, v_qty, v_cost, v_tax_rate, round(v_qty * v_cost, 2));

    v_subtotal := v_subtotal + round(v_qty * v_cost, 2);
    v_tax := v_tax + round(v_qty * v_cost * v_tax_rate / 100.0, 2);

    -- stock in (+ movement)
    perform public.apply_stock_delta(
      v_business, v_branch, v_product, v_qty, 'purchase',
      'purchases', v_purchase, 'goods received', v_profile);

    -- batch / expiry rows when tracked
    if exists (select 1 from public.products p where p.id = v_product and p.track_batch) then
      v_batch_no := coalesce(nullif(v_line ->> 'batch_no', ''), 'B-' || to_char(now(), 'YYYYMMDD'));
      v_expiry := nullif(v_line ->> 'expiry_date', '')::date;
      insert into public.product_batches (
        business_id, branch_id, product_id, batch_no, expiry_date, qty
      ) values (v_business, v_branch, v_product, v_batch_no, v_expiry, v_qty);
    end if;

    -- update the PO line's received qty when receiving against a PO
    if v_po.id is not null then
      select * into v_po_item from public.purchase_order_items
       where purchase_order_id = v_po.id and product_id = v_product for update;
      if found then
        if v_po_item.received_qty + v_qty > v_po_item.qty then
          perform public.raise_app_error('VALIDATION_FAILED', 'received qty exceeds ordered qty',
            jsonb_build_object('product_id', v_product, 'ordered', v_po_item.qty));
        end if;
        update public.purchase_order_items
           set received_qty = received_qty + v_qty
         where id = v_po_item.id;
      end if;
    end if;
  end loop;

  update public.purchases
     set subtotal = v_subtotal, tax_total = v_tax, total = v_subtotal + v_tax, updated_at = now()
   where id = v_purchase;

  if v_po.id is not null then
    select not exists (
      select 1 from public.purchase_order_items poi
       where poi.purchase_order_id = v_po.id and poi.received_qty < poi.qty
    ) into v_fully_received;

    update public.purchase_orders
       set status = case when v_fully_received then 'received' else 'partially_received' end,
           updated_at = now()
     where id = v_po.id;
  end if;

  perform public.write_audit(v_business, v_branch, 'purchase.receive', 'purchases', v_purchase,
    null, jsonb_build_object('total', v_subtotal + v_tax, 'supplier_id', v_supplier));

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'purchase_id', v_purchase, 'total', v_subtotal + v_tax, 'duplicate', false));
end;
$$;

create or replace function public.pay_supplier(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_supplier uuid := (p_payload ->> 'supplier_id')::uuid;
  v_purchase uuid := nullif(p_payload ->> 'purchase_id', '')::uuid;
  v_amount numeric(14,2) := coalesce((p_payload ->> 'amount')::numeric, 0);
  v_branch uuid := coalesce(nullif(p_payload ->> 'branch_id', '')::uuid, public.current_branch_id());
  v_payment uuid;
  v_paid numeric(14,2);
  v_total numeric(14,2);
begin
  v_profile := public.require_permission('suppliers.pay');
  v_business := public.current_business_id();

  if v_amount <= 0 then
    perform public.raise_app_error('VALIDATION_FAILED', 'payment amount must be > 0');
  end if;
  if not exists (select 1 from public.suppliers s
                  where s.id = v_supplier and s.business_id = v_business) then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'supplier not found');
  end if;

  if v_purchase is not null then
    select pu.total, pu.paid_total into v_total, v_paid
      from public.purchases pu
     where pu.id = v_purchase and pu.business_id = v_business
     for update;
    if not found then
      perform public.raise_app_error('PRODUCT_NOT_FOUND', 'purchase bill not found');
    end if;
    if v_paid + v_amount > v_total then
      perform public.raise_app_error('VALIDATION_FAILED', 'payment exceeds the bill balance',
        jsonb_build_object('total', v_total, 'already_paid', v_paid));
    end if;
  end if;

  insert into public.supplier_payments (
    business_id, branch_id, supplier_id, purchase_id, method, amount, reference, note,
    idempotency_key, paid_by
  ) values (
    v_business, v_branch, v_supplier, v_purchase,
    coalesce(p_payload ->> 'method', 'cash'), v_amount,
    p_payload ->> 'reference', p_payload ->> 'note',
    nullif(p_payload ->> 'idempotency_key', ''), v_profile
  ) returning id into v_payment;

  if v_purchase is not null then
    update public.purchases
       set paid_total = paid_total + v_amount,
           status = case when paid_total + v_amount >= total then 'paid' else 'partially_paid' end,
           updated_at = now()
     where id = v_purchase;
  end if;

  perform public.write_audit(v_business, v_branch, 'supplier.pay', 'supplier_payments', v_payment,
    null, jsonb_build_object('supplier_id', v_supplier, 'amount', v_amount));

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'payment_id', v_payment, 'amount', v_amount));
end;
$$;

-- ===========================================================================
-- SHIFTS & CASH
-- ===========================================================================

create or replace function public.open_shift(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_branch uuid := coalesce(nullif(p_payload ->> 'branch_id', '')::uuid, public.current_branch_id());
  v_shift uuid;
  v_float numeric(14,2) := coalesce((p_payload ->> 'opening_float')::numeric, 0);
begin
  v_profile := public.require_permission('shifts.open');
  v_business := public.current_business_id();

  if v_branch is null or not public.has_branch_access(v_branch) then
    perform public.raise_app_error('NO_PERMISSION', 'no access to branch');
  end if;
  if v_float < 0 then
    perform public.raise_app_error('VALIDATION_FAILED', 'opening float cannot be negative');
  end if;

  if exists (select 1 from public.pos_shifts s
              where s.branch_id = v_branch and s.opened_by = v_profile and s.status = 'open') then
    perform public.raise_app_error('SHIFT_ALREADY_OPEN', 'you already have an open shift');
  end if;

  insert into public.pos_shifts (
    business_id, branch_id, terminal_id, opened_by, opening_float, status
  ) values (
    v_business, v_branch, nullif(p_payload ->> 'terminal_id', '')::uuid, v_profile, v_float, 'open'
  ) returning id into v_shift;

  insert into public.cash_movements (business_id, shift_id, type, amount, note, created_by)
  values (v_business, v_shift, 'float', v_float, 'opening float', v_profile);

  return jsonb_build_object('ok', true, 'data', jsonb_build_object('shift_id', v_shift, 'status', 'open'));
end;
$$;

create or replace function public.record_cash_movement(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_shift public.pos_shifts%rowtype;
  v_type text := p_payload ->> 'type';
  v_amount numeric(14,2) := coalesce((p_payload ->> 'amount')::numeric, 0);
  v_id uuid;
begin
  v_profile := public.require_permission('cash.move');
  v_business := public.current_business_id();

  select * into v_shift from public.pos_shifts
   where id = (p_payload ->> 'shift_id')::uuid for update;
  if not found or v_shift.business_id <> v_business then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'shift not found');
  end if;
  if v_shift.status <> 'open' then
    perform public.raise_app_error('SHIFT_NOT_OPEN', 'shift is closed');
  end if;
  if v_type not in ('drawer_in','drawer_out') then
    perform public.raise_app_error('VALIDATION_FAILED', 'type must be drawer_in or drawer_out');
  end if;
  if v_amount <= 0 then
    perform public.raise_app_error('VALIDATION_FAILED', 'amount must be > 0');
  end if;

  insert into public.cash_movements (business_id, shift_id, type, amount, note, created_by)
  values (v_business, v_shift.id, v_type, v_amount, p_payload ->> 'note', v_profile)
  returning id into v_id;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object('cash_movement_id', v_id));
end;
$$;

-- ---------------------------------------------------------------------------
-- close_shift (SPEC §14) — expected cash = float + cash sales - cash refunds
--                              + drawer_in - drawer_out
-- ---------------------------------------------------------------------------
create or replace function public.close_shift(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid;
  v_shift public.pos_shifts%rowtype;
  v_expected numeric(14,2) := 0;
  v_counted numeric(14,2) := coalesce((p_payload ->> 'closing_counted')::numeric, 0);
  v_variance numeric(14,2);
  v_tolerance numeric(14,2);
begin
  v_profile := public.require_permission('shifts.close');
  v_business := public.current_business_id();

  select * into v_shift from public.pos_shifts
   where id = (p_payload ->> 'shift_id')::uuid for update;
  if not found or v_shift.business_id <> v_business then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'shift not found');
  end if;
  if v_shift.status <> 'open' then
    perform public.raise_app_error('SHIFT_ALREADY_OPEN', 'shift is already closed');
  end if;

  select coalesce(sum(
    case cm.type
      when 'float' then cm.amount
      when 'sale' then cm.amount
      when 'drawer_in' then cm.amount
      when 'refund' then -cm.amount
      when 'drawer_out' then -cm.amount
      else 0
    end), 0)
    into v_expected
    from public.cash_movements cm
   where cm.shift_id = v_shift.id;

  v_variance := v_counted - v_expected;

  select coalesce((b.settings ->> 'shift_variance_tolerance')::numeric, 0)
    into v_tolerance from public.businesses b where b.id = v_business;

  if abs(v_variance) > coalesce(v_tolerance, 0)
     and coalesce(trim(p_payload ->> 'variance_reason'), '') = '' then
    perform public.raise_app_error('VALIDATION_FAILED', 'variance reason is required',
      jsonb_build_object('variance', v_variance, 'tolerance', v_tolerance));
  end if;

  update public.pos_shifts
     set status = 'closed', closed_by = v_profile, closed_at = now(),
         closing_counted = v_counted, expected_cash = v_expected,
         variance = v_variance, variance_reason = p_payload ->> 'variance_reason'
   where id = v_shift.id;

  if v_variance <> 0 then
    insert into public.notifications (business_id, branch_id, user_id, type, title, body, data)
    values (v_business, v_shift.branch_id, v_profile, 'SHIFT_VARIANCE',
            'Shift cash variance', format('Variance %s', v_variance),
            jsonb_build_object('shift_id', v_shift.id, 'variance', v_variance));
  end if;

  perform public.write_audit(v_business, v_shift.branch_id, 'shift.close', 'pos_shifts', v_shift.id,
    jsonb_build_object('status', 'open'),
    jsonb_build_object('status', 'closed', 'expected', v_expected, 'counted', v_counted));

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'shift_id', v_shift.id, 'expected_cash', v_expected,
    'closing_counted', v_counted, 'variance', v_variance));
end;
$$;

-- ===========================================================================
-- Grants: business RPCs are authenticated-only (BACKEND_SETUP.md Part D3.7).
-- Internal helpers keep PUBLIC execute because they are invoked from inside
-- other SECURITY DEFINER functions (checked against the definer, not the caller).
-- ===========================================================================
revoke all on function public.create_business_with_owner(jsonb, jsonb) from public, anon;
revoke all on function public.complete_sale(jsonb)                      from public, anon;
revoke all on function public.cancel_sale(uuid, text)                  from public, anon;
revoke all on function public.return_sale(jsonb)                       from public, anon;
revoke all on function public.redeem_loyalty_points(jsonb)             from public, anon;
revoke all on function public.apply_promotion(uuid, numeric, numeric)  from public, anon;
revoke all on function public.calculate_product_price(uuid, numeric)   from public, anon;
revoke all on function public.adjust_stock(jsonb)                      from public, anon;
revoke all on function public.start_stock_count(jsonb)                 from public, anon;
revoke all on function public.submit_stock_count(uuid, jsonb)          from public, anon;
revoke all on function public.approve_stock_count(uuid)                from public, anon;
revoke all on function public.transfer_stock(jsonb)                    from public, anon;
revoke all on function public.receive_transfer(uuid)                   from public, anon;
revoke all on function public.create_purchase_order(jsonb)             from public, anon;
revoke all on function public.approve_purchase_order(uuid)             from public, anon;
revoke all on function public.receive_purchase(jsonb)                  from public, anon;
revoke all on function public.pay_supplier(jsonb)                      from public, anon;
revoke all on function public.open_shift(jsonb)                        from public, anon;
revoke all on function public.record_cash_movement(jsonb)              from public, anon;
revoke all on function public.close_shift(jsonb)                       from public, anon;

grant execute on function public.create_business_with_owner(jsonb, jsonb) to authenticated;
grant execute on function public.complete_sale(jsonb)                      to authenticated;
grant execute on function public.cancel_sale(uuid, text)                  to authenticated;
grant execute on function public.return_sale(jsonb)                       to authenticated;
grant execute on function public.redeem_loyalty_points(jsonb)             to authenticated;
grant execute on function public.apply_promotion(uuid, numeric, numeric)  to authenticated;
grant execute on function public.calculate_product_price(uuid, numeric)   to authenticated;
grant execute on function public.adjust_stock(jsonb)                      to authenticated;
grant execute on function public.start_stock_count(jsonb)                 to authenticated;
grant execute on function public.submit_stock_count(uuid, jsonb)          to authenticated;
grant execute on function public.approve_stock_count(uuid)                to authenticated;
grant execute on function public.transfer_stock(jsonb)                    to authenticated;
grant execute on function public.receive_transfer(uuid)                   to authenticated;
grant execute on function public.create_purchase_order(jsonb)             to authenticated;
grant execute on function public.approve_purchase_order(uuid)             to authenticated;
grant execute on function public.receive_purchase(jsonb)                  to authenticated;
grant execute on function public.pay_supplier(jsonb)                      to authenticated;
grant execute on function public.open_shift(jsonb)                        to authenticated;
grant execute on function public.record_cash_movement(jsonb)              to authenticated;
grant execute on function public.close_shift(jsonb)                       to authenticated;

-- ===========================================================================
-- migrate:down
--   drop function if exists public.close_shift(jsonb);
--   ... (see individual function names; forward-fix only in production)
-- ===========================================================================