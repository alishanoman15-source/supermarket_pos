-- =============================================================================
-- 170_fix_inclusive_sale_total
-- `complete_sale` charged tax twice whenever a business enabled tax-inclusive
-- pricing (SPEC §30): `v_subtotal` already embeds the tax in that mode, so
-- adding `v_tax_total` inflated `grand_total` (and the computed change).
-- This replaces the function with the corrected grand-total formula; behaviour
-- for exclusive pricing is unchanged. Shipped as a new migration (not an edit of
-- 100_functions_rpc) so an already-provisioned project receives the fix on
-- `supabase db push`.
-- =============================================================================

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

  -- Inclusive prices already contain tax; add it on top only for
  -- exclusive pricing, otherwise the tax would be charged twice (§30).
  v_grand := v_subtotal - v_discount_total - v_cart_discount
             + (case when v_inclusive then 0 else v_tax_total end);
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
