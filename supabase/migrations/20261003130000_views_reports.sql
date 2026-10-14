-- =============================================================================
-- 120_views_reports
-- Reporting views + aggregation RPCs (SPEC §49–55, BACKEND_SETUP.md Part F).
-- All reports are permission-gated and server-side aggregated.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- dashboard_kpis (SPEC §49, §31)
-- ---------------------------------------------------------------------------
create or replace function public.dashboard_kpis(
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_branch uuid default null
) returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_business uuid := public.current_business_id();
  v_from timestamptz := coalesce(p_from, date_trunc('day', now()));
  v_to timestamptz := coalesce(p_to, now());
  v_prev_from timestamptz := v_from - (v_to - v_from);
  v_branch uuid := coalesce(p_branch, public.current_branch_id_or_all());
  v_revenue numeric(14,2);
  v_prev_revenue numeric(14,2);
  v_txns integer;
  v_gross_profit numeric(14,2);
  v_low_stock integer;
  v_top jsonb;
begin
  if not public.has_permission('reports.dashboard.view') then
    perform public.raise_app_error('NO_PERMISSION', 'missing reports.dashboard.view');
  end if;
  if v_business is null then
    perform public.raise_app_error('NO_BUSINESS', 'caller has no business');
  end if;

  select coalesce(sum(s.grand_total), 0), count(*)
    into v_revenue, v_txns
    from public.sales s
   where s.business_id = v_business
     and s.status <> 'cancelled'
     and s.sold_at between v_from and v_to
     and (v_branch is null or s.branch_id = v_branch);

  select coalesce(sum(s.grand_total), 0) into v_prev_revenue
    from public.sales s
   where s.business_id = v_business
     and s.status <> 'cancelled'
     and s.sold_at between v_prev_from and v_from
     and (v_branch is null or s.branch_id = v_branch);

  select coalesce(sum(si.line_total - si.tax_amount - (si.qty * si.cost_at_sale)), 0)
    into v_gross_profit
    from public.sale_items si
    join public.sales s on s.id = si.sale_id
   where s.business_id = v_business
     and s.status <> 'cancelled'
     and s.sold_at between v_from and v_to
     and (v_branch is null or s.branch_id = v_branch);

  select count(*) into v_low_stock
    from public.inventories i
    join public.products p on p.id = i.product_id
   where i.business_id = v_business
     and p.status = 'active'
     and p.reorder_level > 0
     and i.on_hand <= p.reorder_level
     and (v_branch is null or i.branch_id = v_branch);

  select coalesce(jsonb_agg(t), '[]'::jsonb) into v_top from (
    select si.product_id, si.name_snapshot as name,
           sum(si.qty) as qty_sold, sum(si.line_total) as revenue
      from public.sale_items si
      join public.sales s on s.id = si.sale_id
     where s.business_id = v_business
       and s.status <> 'cancelled'
       and s.sold_at between v_from and v_to
       and (v_branch is null or s.branch_id = v_branch)
     group by si.product_id, si.name_snapshot
     order by revenue desc
     limit 5
  ) t;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'from', v_from, 'to', v_to, 'branch_id', v_branch,
    'revenue', v_revenue,
    'previous_revenue', v_prev_revenue,
    'transactions', v_txns,
    'gross_profit', v_gross_profit,
    'low_stock_count', v_low_stock,
    'top_products', v_top
  ));
end;
$$;

-- ---------------------------------------------------------------------------
-- report_sales (SPEC §50)
-- ---------------------------------------------------------------------------
create or replace function public.report_sales(
  p_from timestamptz,
  p_to timestamptz,
  p_branch uuid default null,
  p_group_by text default 'day'
) returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_business uuid := public.current_business_id();
  v_branch uuid := coalesce(p_branch, public.current_branch_id_or_all());
  v_bucket text;
  v_rows jsonb;
  v_totals jsonb;
begin
  if not public.has_permission('reports.sales.view') then
    perform public.raise_app_error('NO_PERMISSION', 'missing reports.sales.view');
  end if;

  v_bucket := case p_group_by
                when 'hour' then 'hour'
                when 'month' then 'month'
                when 'week' then 'week'
                else 'day'
              end;

  select coalesce(jsonb_agg(r), '[]'::jsonb) into v_rows from (
    select date_trunc(v_bucket, s.sold_at) as bucket,
           count(*) as transactions,
           sum(s.subtotal) as gross_sales,
           sum(s.discount_total) as discounts,
           sum(s.subtotal - s.discount_total) as net_sales,
           sum(s.tax_total) as tax_collected,
           sum(s.grand_total) as revenue,
           round(avg(s.grand_total), 2) as avg_basket
      from public.sales s
     where s.business_id = v_business
       and s.status <> 'cancelled'
       and s.sold_at between p_from and p_to
       and (v_branch is null or s.branch_id = v_branch)
     group by 1
     order by 1
  ) r;

  select jsonb_build_object(
           'transactions', count(*),
           'gross_sales', coalesce(sum(s.subtotal), 0),
           'discounts', coalesce(sum(s.discount_total), 0),
           'net_sales', coalesce(sum(s.subtotal - s.discount_total), 0),
           'tax_collected', coalesce(sum(s.tax_total), 0),
           'revenue', coalesce(sum(s.grand_total), 0),
           'items_per_txn', round(coalesce((
             select sum(si.qty) from public.sale_items si
              join public.sales s2 on s2.id = si.sale_id
             where s2.business_id = v_business
               and s2.status <> 'cancelled'
               and s2.sold_at between p_from and p_to
               and (v_branch is null or s2.branch_id = v_branch)
           ), 0) / greatest(count(*), 1), 2)
         )
    into v_totals
    from public.sales s
   where s.business_id = v_business
     and s.status <> 'cancelled'
     and s.sold_at between p_from and p_to
     and (v_branch is null or s.branch_id = v_branch);

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'group_by', v_bucket, 'rows', v_rows, 'totals', v_totals));
end;
$$;

-- ---------------------------------------------------------------------------
-- report_profit (SPEC §51, §55)
-- ---------------------------------------------------------------------------
create or replace function public.report_profit(
  p_from timestamptz,
  p_to timestamptz,
  p_branch uuid default null
) returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_business uuid := public.current_business_id();
  v_branch uuid := coalesce(p_branch, public.current_branch_id_or_all());
  v_revenue numeric(14,2);
  v_cogs numeric(14,2);
  v_refunds numeric(14,2);
  v_expenses numeric(14,2);
  v_tax numeric(14,2);
begin
  if not public.has_permission('reports.profit.view') then
    perform public.raise_app_error('NO_PERMISSION', 'missing reports.profit.view');
  end if;

  select coalesce(sum(s.subtotal - s.discount_total), 0), coalesce(sum(s.tax_total), 0)
    into v_revenue, v_tax
    from public.sales s
   where s.business_id = v_business
     and s.status <> 'cancelled'
     and s.sold_at between p_from and p_to
     and (v_branch is null or s.branch_id = v_branch);

  select coalesce(sum(si.qty * si.cost_at_sale), 0)
    into v_cogs
    from public.sale_items si
    join public.sales s on s.id = si.sale_id
   where s.business_id = v_business
     and s.status <> 'cancelled'
     and s.sold_at between p_from and p_to
     and (v_branch is null or s.branch_id = v_branch);

  select coalesce(sum(r.total_refund), 0)
    into v_refunds
    from public.sale_returns r
   where r.business_id = v_business
     and r.created_at between p_from and p_to
     and (v_branch is null or r.branch_id = v_branch);

  select coalesce(sum(e.amount), 0)
    into v_expenses
    from public.expenses e
   where e.business_id = v_business
     and e.paid_at between p_from and p_to
     and (v_branch is null or e.branch_id = v_branch);

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'from', p_from, 'to', p_to, 'branch_id', v_branch,
    'revenue', v_revenue,
    'tax_collected', v_tax,
    'cogs', v_cogs,
    'gross_profit', v_revenue - v_cogs,
    'refunds', v_refunds,
    'expenses', v_expenses,
    'operating_profit', v_revenue - v_cogs - v_refunds - v_expenses
  ));
end;
$$;

-- ---------------------------------------------------------------------------
-- report_inventory (SPEC §52)
-- ---------------------------------------------------------------------------
create or replace function public.report_inventory(
  p_branch uuid default null,
  p_dead_stock_days integer default 60
) returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_business uuid := public.current_business_id();
  v_branch uuid := coalesce(p_branch, public.current_branch_id_or_all());
  v_value_at_cost numeric(14,2);
  v_value_at_retail numeric(14,2);
  v_low integer;
  v_out integer;
  v_dead jsonb;
  v_expiring jsonb;
begin
  if not public.has_permission('reports.inventory.view') then
    perform public.raise_app_error('NO_PERMISSION', 'missing reports.inventory.view');
  end if;

  select coalesce(sum(i.on_hand * i.wac), 0), coalesce(sum(i.on_hand * p.selling_price), 0)
    into v_value_at_cost, v_value_at_retail
    from public.inventories i
    join public.products p on p.id = i.product_id
   where i.business_id = v_business
     and (v_branch is null or i.branch_id = v_branch);

  select count(*) filter (where i.on_hand <= p.reorder_level and i.on_hand > 0),
         count(*) filter (where i.on_hand <= 0)
    into v_low, v_out
    from public.inventories i
    join public.products p on p.id = i.product_id
   where i.business_id = v_business
     and p.status = 'active'
     and (v_branch is null or i.branch_id = v_branch);

  select coalesce(jsonb_agg(d), '[]'::jsonb) into v_dead from (
    select p.id as product_id, p.name, i.on_hand, i.wac,
           (select max(s.sold_at) from public.sale_items si
              join public.sales s on s.id = si.sale_id
             where si.product_id = p.id and s.status <> 'cancelled') as last_sold_at
      from public.inventories i
      join public.products p on p.id = i.product_id
     where i.business_id = v_business
       and i.on_hand > 0
       and (v_branch is null or i.branch_id = v_branch)
       and not exists (
         select 1 from public.sale_items si
           join public.sales s on s.id = si.sale_id
          where si.product_id = p.id
            and s.status <> 'cancelled'
            and s.sold_at >= now() - make_interval(days => p_dead_stock_days)
       )
     order by i.on_hand * i.wac desc
     limit 50
  ) d;

  select coalesce(jsonb_agg(e), '[]'::jsonb) into v_expiring from (
    select b.id as batch_id, b.product_id, p.name, b.batch_no, b.expiry_date, b.qty
      from public.product_batches b
      join public.products p on p.id = b.product_id
     where b.business_id = v_business
       and b.qty > 0
       and b.expiry_date is not null
       and b.expiry_date <= (now() + interval '30 days')::date
       and (v_branch is null or b.branch_id = v_branch)
     order by b.expiry_date
     limit 100
  ) e;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'branch_id', v_branch,
    'value_at_cost', v_value_at_cost,
    'value_at_retail', v_value_at_retail,
    'margin_value', v_value_at_retail - v_value_at_cost,
    'low_stock_count', v_low,
    'out_of_stock_count', v_out,
    'dead_stock', v_dead,
    'expiring', v_expiring
  ));
end;
$$;

-- ---------------------------------------------------------------------------
-- report_purchases (SPEC §53)
-- ---------------------------------------------------------------------------
create or replace function public.report_purchases(
  p_from timestamptz,
  p_to timestamptz,
  p_branch uuid default null
) returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_business uuid := public.current_business_id();
  v_branch uuid := coalesce(p_branch, public.current_branch_id_or_all());
  v_by_supplier jsonb;
  v_unpaid jsonb;
  v_ageing jsonb;
  v_total numeric(14,2);
begin
  if not public.has_permission('reports.purchases.view') then
    perform public.raise_app_error('NO_PERMISSION', 'missing reports.purchases.view');
  end if;

  select coalesce(sum(pu.total), 0) into v_total
    from public.purchases pu
   where pu.business_id = v_business
     and pu.received_at between p_from and p_to
     and (v_branch is null or pu.branch_id = v_branch);

  select coalesce(jsonb_agg(x), '[]'::jsonb) into v_by_supplier from (
    select s.id as supplier_id, s.name, count(*) as bills, sum(pu.total) as total
      from public.purchases pu
      join public.suppliers s on s.id = pu.supplier_id
     where pu.business_id = v_business
       and pu.received_at between p_from and p_to
       and (v_branch is null or pu.branch_id = v_branch)
     group by s.id, s.name
     order by total desc
  ) x;

  select coalesce(jsonb_agg(u), '[]'::jsonb) into v_unpaid from (
    select pu.id, pu.bill_number, s.name as supplier_name, pu.total, pu.paid_total,
           (pu.total - pu.paid_total) as balance, pu.due_at
      from public.purchases pu
      join public.suppliers s on s.id = pu.supplier_id
     where pu.business_id = v_business
       and pu.status in ('unpaid','partially_paid')
       and (v_branch is null or pu.branch_id = v_branch)
     order by pu.due_at nulls last
     limit 200
  ) u;

  select coalesce(jsonb_agg(a), '[]'::jsonb) into v_ageing from (
    select s.id as supplier_id, s.name,
           sum(case when pu.due_at is null or pu.due_at >= current_date - 30
                    then pu.total - pu.paid_total else 0 end) as bucket_0_30,
           sum(case when pu.due_at < current_date - 30 and pu.due_at >= current_date - 60
                    then pu.total - pu.paid_total else 0 end) as bucket_30_60,
           sum(case when pu.due_at < current_date - 60 and pu.due_at >= current_date - 90
                    then pu.total - pu.paid_total else 0 end) as bucket_60_90,
           sum(case when pu.due_at < current_date - 90
                    then pu.total - pu.paid_total else 0 end) as bucket_90_plus
      from public.purchases pu
      join public.suppliers s on s.id = pu.supplier_id
     where pu.business_id = v_business
       and pu.status in ('unpaid','partially_paid')
       and (v_branch is null or pu.branch_id = v_branch)
     group by s.id, s.name
     order by s.name
  ) a;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'total_purchases', v_total,
    'by_supplier', v_by_supplier,
    'unpaid_bills', v_unpaid,
    'supplier_ageing', v_ageing
  ));
end;
$$;

-- ---------------------------------------------------------------------------
-- report_cash (SPEC §54)
-- ---------------------------------------------------------------------------
create or replace function public.report_cash(
  p_from timestamptz,
  p_to timestamptz,
  p_branch uuid default null
) returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_business uuid := public.current_business_id();
  v_branch uuid := coalesce(p_branch, public.current_branch_id_or_all());
  v_shifts jsonb;
  v_variances jsonb;
  v_by_cashier jsonb;
begin
  if not public.has_permission('reports.cash.view') then
    perform public.raise_app_error('NO_PERMISSION', 'missing reports.cash.view');
  end if;

  select coalesce(jsonb_agg(s), '[]'::jsonb) into v_shifts from (
    select sh.id, sh.opened_at, sh.closed_at, sh.opening_float, sh.expected_cash,
           sh.closing_counted, sh.variance, sh.status,
           pr.name as cashier_name, b.name as branch_name
      from public.pos_shifts sh
      left join public.profiles pr on pr.id = sh.opened_by
      left join public.branches b on b.id = sh.branch_id
     where sh.business_id = v_business
       and sh.opened_at between p_from and p_to
       and (v_branch is null or sh.branch_id = v_branch)
     order by sh.opened_at desc
     limit 200
  ) s;

  select coalesce(jsonb_agg(v), '[]'::jsonb) into v_variances from (
    select sh.id, sh.opened_at, sh.variance, sh.variance_reason, pr.name as cashier_name
      from public.pos_shifts sh
      left join public.profiles pr on pr.id = sh.opened_by
     where sh.business_id = v_business
       and sh.status = 'closed'
       and coalesce(sh.variance, 0) <> 0
       and sh.opened_at between p_from and p_to
       and (v_branch is null or sh.branch_id = v_branch)
     order by abs(coalesce(sh.variance, 0)) desc
     limit 100
  ) v;

  select coalesce(jsonb_agg(c), '[]'::jsonb) into v_by_cashier from (
    select s.cashier_id, pr.name as cashier_name, count(*) as transactions,
           sum(s.grand_total) as revenue
      from public.sales s
      left join public.profiles pr on pr.id = s.cashier_id
     where s.business_id = v_business
       and s.status <> 'cancelled'
       and s.sold_at between p_from and p_to
       and (v_branch is null or s.branch_id = v_branch)
     group by s.cashier_id, pr.name
     order by revenue desc
  ) c;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'shifts', v_shifts, 'variances', v_variances, 'by_cashier', v_by_cashier));
end;
$$;

-- ---------------------------------------------------------------------------
-- report_costing (SPEC §55) — WAC history + margin per product
-- ---------------------------------------------------------------------------
create or replace function public.report_costing(
  p_branch uuid default null,
  p_limit integer default 100
) returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_business uuid := public.current_business_id();
  v_branch uuid := coalesce(p_branch, public.current_branch_id_or_all());
  v_products jsonb;
  v_wac_history jsonb;
begin
  if not public.has_permission('reports.profit.view') then
    perform public.raise_app_error('NO_PERMISSION', 'missing reports.profit.view');
  end if;

  select coalesce(jsonb_agg(p), '[]'::jsonb) into v_products from (
    select p.id as product_id, p.name, p.selling_price, i.wac, i.on_hand,
           case when p.selling_price > 0
                then round(((p.selling_price - i.wac) / p.selling_price) * 100, 2)
                else 0 end as margin_pct,
           round((p.selling_price - i.wac) * i.on_hand, 2) as potential_profit
      from public.inventories i
      join public.products p on p.id = i.product_id
     where i.business_id = v_business
       and (v_branch is null or i.branch_id = v_branch)
     order by potential_profit desc
     limit greatest(p_limit, 1)
  ) p;

  select coalesce(jsonb_agg(h), '[]'::jsonb) into v_wac_history from (
    select ph.product_id, p.name, ph.old_purchase_price, ph.new_purchase_price,
           ph.old_selling_price, ph.new_selling_price, ph.created_at
      from public.price_history ph
      join public.products p on p.id = ph.product_id
     where ph.business_id = v_business
     order by ph.created_at desc
     limit greatest(p_limit, 1)
  ) h;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'products', v_products, 'price_history', v_wac_history));
end;
$$;

-- ---------------------------------------------------------------------------
-- shift_summary (SPEC §54, cashier self-report)
-- ---------------------------------------------------------------------------
create or replace function public.shift_summary(p_shift_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile uuid;
  v_business uuid := public.current_business_id();
  v_shift public.pos_shifts%rowtype;
  v_sales numeric(14,2);
  v_txns integer;
  v_expected numeric(14,2);
begin
  v_profile := public.current_profile_id();
  if v_profile is null then
    perform public.raise_app_error('UNAUTHENTICATED', 'sign in first');
  end if;

  select * into v_shift from public.pos_shifts where id = p_shift_id;
  if not found or v_shift.business_id <> v_business then
    perform public.raise_app_error('PRODUCT_NOT_FOUND', 'shift not found');
  end if;
  if v_shift.opened_by <> v_profile and not public.has_permission('reports.cash.view') then
    perform public.raise_app_error('NO_PERMISSION', 'not your shift');
  end if;

  select coalesce(sum(s.grand_total), 0), count(*) into v_sales, v_txns
    from public.sales s where s.shift_id = p_shift_id and s.status <> 'cancelled';

  select coalesce(sum(
    case cm.type
      when 'float' then cm.amount when 'sale' then cm.amount
      when 'drawer_in' then cm.amount
      when 'refund' then -cm.amount when 'drawer_out' then -cm.amount
      else 0 end), 0)
    into v_expected from public.cash_movements cm where cm.shift_id = p_shift_id;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'shift_id', p_shift_id, 'status', v_shift.status,
    'opening_float', v_shift.opening_float, 'sales_total', v_sales,
    'transactions', v_txns, 'expected_cash', v_expected));
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants: authenticated only (never anon/public) — BACKEND_SETUP.md Part D3.7
-- ---------------------------------------------------------------------------
-- Reporting RPCs are authenticated-only. Internal helpers keep PUBLIC execute
-- because SECURITY DEFINER functions invoke them as the definer.
revoke all on function public.dashboard_kpis(timestamptz, timestamptz, uuid)          from public, anon;
revoke all on function public.report_sales(timestamptz, timestamptz, uuid, text)      from public, anon;
revoke all on function public.report_profit(timestamptz, timestamptz, uuid)           from public, anon;
revoke all on function public.report_inventory(uuid, integer)                         from public, anon;
revoke all on function public.report_purchases(timestamptz, timestamptz, uuid)        from public, anon;
revoke all on function public.report_cash(timestamptz, timestamptz, uuid)             from public, anon;
revoke all on function public.report_costing(uuid, integer)                           from public, anon;
revoke all on function public.shift_summary(uuid)                                     from public, anon;

grant execute on function public.dashboard_kpis(timestamptz, timestamptz, uuid)       to authenticated;
grant execute on function public.report_sales(timestamptz, timestamptz, uuid, text)   to authenticated;
grant execute on function public.report_profit(timestamptz, timestamptz, uuid)        to authenticated;
grant execute on function public.report_inventory(uuid, integer)                      to authenticated;
grant execute on function public.report_purchases(timestamptz, timestamptz, uuid)     to authenticated;
grant execute on function public.report_cash(timestamptz, timestamptz, uuid)          to authenticated;
grant execute on function public.report_costing(uuid, integer)                        to authenticated;
grant execute on function public.shift_summary(uuid)                                  to authenticated;

-- ---------------------------------------------------------------------------
-- migrate:down
--   drop function if exists public.shift_summary(uuid);
--   drop function if exists public.report_costing(uuid, integer);
--   drop function if exists public.report_cash(timestamptz, timestamptz, uuid);
--   drop function if exists public.report_purchases(timestamptz, timestamptz, uuid);
--   drop function if exists public.report_inventory(uuid, integer);
--   drop function if exists public.report_profit(timestamptz, timestamptz, uuid);
--   drop function if exists public.report_sales(timestamptz, timestamptz, uuid, text);
--   drop function if exists public.dashboard_kpis(timestamptz, timestamptz, uuid);
-- ---------------------------------------------------------------------------