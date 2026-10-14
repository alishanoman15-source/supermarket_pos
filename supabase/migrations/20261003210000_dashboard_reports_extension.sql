-- =============================================================================
-- 130_dashboard_reports_extension
-- Full admin dashboard (product spec §7) + the remaining report RPCs
-- (§49: expense / supplier / customer / product performance) and reorder
-- suggestions (§103 "reorder suggestions").
--
-- All aggregations stay server-side, permission-gated and RLS-independent
-- (SECURITY DEFINER + has_permission), matching BACKEND_SETUP.md Part 4.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- dashboard_kpis — extended to the full KPI set. Signature unchanged so the
-- existing Flutter caller and grants keep working; every previously returned
-- key is preserved.
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
  v_cogs numeric(14,2);
  v_gross_profit numeric(14,2);
  v_expenses numeric(14,2);
  v_low_stock integer;
  v_out_stock integer;
  v_total_products integer;
  v_total_units numeric(14,3);
  v_sales_today numeric(14,2);
  v_sales_yesterday numeric(14,2);
  v_sales_week numeric(14,2);
  v_sales_month numeric(14,2);
  v_sales_total numeric(14,2);
  v_orders jsonb;
  v_stock_alerts jsonb;
  v_by_day jsonb;
  v_by_month jsonb;
  v_by_category jsonb;
  v_payment_methods jsonb;
  v_top jsonb;
begin
  if not public.has_permission('reports.dashboard.view') then
    perform public.raise_app_error('NO_PERMISSION', 'missing reports.dashboard.view');
  end if;
  if v_business is null then
    perform public.raise_app_error('NO_BUSINESS', 'caller has no business');
  end if;

  -- Period figures (revenue / transactions / gross profit / COGS / expenses).
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

  select coalesce(sum(si.qty * si.cost_at_sale), 0),
         coalesce(sum(si.line_total - si.tax_amount - (si.qty * si.cost_at_sale)), 0)
    into v_cogs, v_gross_profit
    from public.sale_items si
    join public.sales s on s.id = si.sale_id
   where s.business_id = v_business
     and s.status <> 'cancelled'
     and s.sold_at between v_from and v_to
     and (v_branch is null or s.branch_id = v_branch);

  select coalesce(sum(e.amount), 0) into v_expenses
    from public.expenses e
   where e.business_id = v_business
     and e.status = 'active'
     and e.paid_at between v_from and v_to
     and (v_branch is null or e.branch_id = v_branch);

  -- Headline sales windows (today / yesterday / week / month / all time).
  select coalesce(sum(s.grand_total) filter (where s.sold_at >= date_trunc('day', now())), 0),
         coalesce(sum(s.grand_total) filter (
           where s.sold_at >= date_trunc('day', now() - interval '1 day')
             and s.sold_at <  date_trunc('day', now())), 0),
         coalesce(sum(s.grand_total) filter (where s.sold_at >= date_trunc('day', now()) - interval '6 days'), 0),
         coalesce(sum(s.grand_total) filter (where s.sold_at >= date_trunc('month', now())), 0),
         coalesce(sum(s.grand_total), 0)
    into v_sales_today, v_sales_yesterday, v_sales_week, v_sales_month, v_sales_total
    from public.sales s
   where s.business_id = v_business
     and s.status <> 'cancelled'
     and (v_branch is null or s.branch_id = v_branch);

  -- Order counts for the selected period, by lifecycle status.
  select jsonb_build_object(
           'total', count(*),
           'completed', count(*) filter (where s.status = 'completed'),
           'returned', count(*) filter (where s.status in ('returned', 'partially_returned')),
           'cancelled', count(*) filter (where s.status = 'cancelled')
         )
    into v_orders
    from public.sales s
   where s.business_id = v_business
     and s.sold_at between v_from and v_to
     and (v_branch is null or s.branch_id = v_branch);

  -- Inventory health (whole business / branch scope when given).
  select count(*) into v_total_products
    from public.products p
   where p.business_id = v_business
     and p.status = 'active'
     and p.deleted_at is null;

  select coalesce(sum(i.on_hand), 0) into v_total_units
    from public.inventories i
   where i.business_id = v_business
     and (v_branch is null or i.branch_id = v_branch);

  select count(*) filter (where i.on_hand <= p.reorder_level and i.on_hand > 0),
         count(*) filter (where i.on_hand <= 0)
    into v_low_stock, v_out_stock
    from public.inventories i
    join public.products p on p.id = i.product_id
   where i.business_id = v_business
     and p.status = 'active'
     and p.reorder_level > 0
     and (v_branch is null or i.branch_id = v_branch);

  select jsonb_build_object(
           'expired', count(*) filter (where b.expiry_date < current_date),
           'within_7_days', count(*) filter (
             where b.expiry_date >= current_date and b.expiry_date <= current_date + 7),
           'within_30_days', count(*) filter (
             where b.expiry_date >= current_date and b.expiry_date <= current_date + 30)
         )
    into v_stock_alerts
    from public.product_batches b
   where b.business_id = v_business
     and b.qty > 0
     and b.expiry_date is not null
     and (v_branch is null or b.branch_id = v_branch);

  -- Charts -------------------------------------------------------------------
  select coalesce(jsonb_agg(g order by g.day), '[]'::jsonb) into v_by_day
    from (
      select d::date as day,
             count(s.id)::int as transactions,
             coalesce(sum(s.grand_total), 0) as revenue
        from generate_series(date_trunc('day', now()) - interval '13 days',
                             date_trunc('day', now()), interval '1 day') d
        left join public.sales s
          on s.sold_at >= d and s.sold_at < d + interval '1 day'
         and s.business_id = v_business
         and s.status <> 'cancelled'
         and (v_branch is null or s.branch_id = v_branch)
       group by d
    ) g;

  select coalesce(jsonb_agg(g order by g.month), '[]'::jsonb) into v_by_month
    from (
      select date_trunc('month', d)::date as month,
             count(s.id)::int as transactions,
             coalesce(sum(s.grand_total), 0) as revenue
        from generate_series(date_trunc('month', now()) - interval '11 months',
                             date_trunc('month', now()), interval '1 month') d
        left join public.sales s
          on s.sold_at >= d and s.sold_at < d + interval '1 month'
         and s.business_id = v_business
         and s.status <> 'cancelled'
         and (v_branch is null or s.branch_id = v_branch)
       group by d
    ) g;

  select coalesce(jsonb_agg(t order by t.revenue desc), '[]'::jsonb) into v_top
    from (
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
       limit 10
    ) t;

  select coalesce(jsonb_agg(t order by t.revenue desc), '[]'::jsonb) into v_by_category
    from (
      select coalesce(c.name, 'Uncategorised') as category,
             sum(si.qty) as qty_sold,
             sum(si.line_total) as revenue
        from public.sale_items si
        join public.sales s on s.id = si.sale_id
        left join public.products p on p.id = si.product_id
        left join public.categories c on c.id = p.category_id
       where s.business_id = v_business
         and s.status <> 'cancelled'
         and s.sold_at between v_from and v_to
         and (v_branch is null or s.branch_id = v_branch)
       group by coalesce(c.name, 'Uncategorised')
    ) t;

  select coalesce(jsonb_agg(t order by t.amount desc), '[]'::jsonb) into v_payment_methods
    from (
      select sp.method,
             sum(sp.amount) as amount,
             count(*)::int as payments
        from public.sale_payments sp
        join public.sales s on s.id = sp.sale_id
       where s.business_id = v_business
         and s.status <> 'cancelled'
         and s.sold_at between v_from and v_to
         and (v_branch is null or s.branch_id = v_branch)
       group by sp.method
    ) t;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'from', v_from, 'to', v_to, 'branch_id', v_branch,
    -- period financials (pre-existing keys first)
    'revenue', v_revenue,
    'previous_revenue', v_prev_revenue,
    'transactions', v_txns,
    'gross_profit', v_gross_profit,
    'low_stock_count', v_low_stock,
    'top_products', v_top,
    -- spec §7 additions
    'sales', jsonb_build_object(
      'today', v_sales_today, 'yesterday', v_sales_yesterday,
      'week', v_sales_week, 'month', v_sales_month, 'total', v_sales_total),
    'orders', v_orders,
    'inventory', jsonb_build_object(
      'total_products', v_total_products,
      'total_stock_units', v_total_units,
      'low_stock_count', v_low_stock,
      'out_of_stock_count', v_out_stock,
      'expiring', v_stock_alerts),
    'financials', jsonb_build_object(
      'revenue', v_revenue,
      'cost_of_goods', v_cogs,
      'gross_profit', v_gross_profit,
      'expenses', v_expenses,
      'net_profit', v_gross_profit - v_expenses),
    'charts', jsonb_build_object(
      'sales_by_day', v_by_day,
      'sales_by_month', v_by_month,
      'top_products', v_top,
      'sales_by_category', v_by_category,
      'payment_methods', v_payment_methods)
  ));
end;
$$;

-- ---------------------------------------------------------------------------
-- report_inventory — same signature, now also returns reorder suggestions
-- (7-day lead time, 90-day average daily sales).
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
  v_reorder jsonb;
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

  -- Reorder suggestions: average daily sales over 90 days × 7 day lead time,
  -- topped up to the reorder level. Products at/below reorder level only.
  select coalesce(jsonb_agg(r order by r.suggested_qty desc), '[]'::jsonb) into v_reorder
    from (
      select p.id as product_id, p.name, p.sku, i.on_hand, p.reorder_level,
             round(coalesce(a.avg_daily, 0), 3) as avg_daily_sales,
             greatest(0, ceil(coalesce(a.avg_daily, 0) * 7 + p.reorder_level - i.on_hand))::numeric
               as suggested_qty
        from public.inventories i
        join public.products p on p.id = i.product_id
        left join lateral (
          select sum(si.qty) / 90.0 as avg_daily
            from public.sale_items si
            join public.sales s on s.id = si.sale_id
           where si.product_id = p.id
             and s.status <> 'cancelled'
             and s.sold_at >= now() - interval '90 days'
        ) a on true
       where i.business_id = v_business
         and p.status = 'active'
         and p.reorder_level > 0
         and i.on_hand <= p.reorder_level
         and (v_branch is null or i.branch_id = v_branch)
       limit 50
    ) r;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'branch_id', v_branch,
    'value_at_cost', v_value_at_cost,
    'value_at_retail', v_value_at_retail,
    'margin_value', v_value_at_retail - v_value_at_cost,
    'low_stock_count', v_low,
    'out_of_stock_count', v_out,
    'dead_stock', v_dead,
    'expiring', v_expiring,
    'reorder_suggestions', v_reorder
  ));
end;
$$;

-- ---------------------------------------------------------------------------
-- report_expenses (spec §49 expense report)
-- ---------------------------------------------------------------------------
create or replace function public.report_expenses(
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
  v_from timestamptz := coalesce(p_from, date_trunc('month', now()));
  v_to timestamptz := coalesce(p_to, now());
  v_branch uuid := coalesce(p_branch, public.current_branch_id_or_all());
  v_totals jsonb;
  v_by_category jsonb;
  v_by_method jsonb;
  v_by_day jsonb;
begin
  if not public.has_permission('expenses.manage') then
    perform public.raise_app_error('NO_PERMISSION', 'missing expenses.manage');
  end if;
  if v_business is null then
    perform public.raise_app_error('NO_BUSINESS', 'caller has no business');
  end if;

  select jsonb_build_object(
           'count', count(*),
           'total', coalesce(sum(e.amount), 0),
           'avg', round(coalesce(avg(e.amount), 0), 2))
    into v_totals
    from public.expenses e
   where e.business_id = v_business
     and e.status = 'active'
     and e.paid_at between v_from and v_to
     and (v_branch is null or e.branch_id = v_branch);

  select coalesce(jsonb_agg(r order by r.amount desc), '[]'::jsonb) into v_by_category
    from (
      select coalesce(c.name, 'Uncategorised') as category,
             count(*)::int as entries,
             sum(e.amount) as amount
        from public.expenses e
        left join public.expense_categories c on c.id = e.category_id
       where e.business_id = v_business
         and e.status = 'active'
         and e.paid_at between v_from and v_to
         and (v_branch is null or e.branch_id = v_branch)
       group by coalesce(c.name, 'Uncategorised')
    ) r;

  select coalesce(jsonb_agg(r order by r.amount desc), '[]'::jsonb) into v_by_method
    from (
      select e.payment_method as method, sum(e.amount) as amount, count(*)::int as entries
        from public.expenses e
       where e.business_id = v_business
         and e.status = 'active'
         and e.paid_at between v_from and v_to
         and (v_branch is null or e.branch_id = v_branch)
       group by e.payment_method
    ) r;

  select coalesce(jsonb_agg(r order by r.day), '[]'::jsonb) into v_by_day
    from (
      select e.paid_at::date as day, sum(e.amount) as amount, count(*)::int as entries
        from public.expenses e
       where e.business_id = v_business
         and e.status = 'active'
         and e.paid_at between v_from and v_to
         and (v_branch is null or e.branch_id = v_branch)
       group by e.paid_at::date
    ) r;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'from', v_from, 'to', v_to, 'branch_id', v_branch,
    'totals', v_totals,
    'by_category', v_by_category,
    'by_payment_method', v_by_method,
    'by_day', v_by_day
  ));
end;
$$;

-- ---------------------------------------------------------------------------
-- report_suppliers (spec §49 supplier report / §27 supplier reports)
-- ---------------------------------------------------------------------------
create or replace function public.report_suppliers(
  p_from timestamptz default null,
  p_to timestamptz default null
) returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_business uuid := public.current_business_id();
  v_from timestamptz := coalesce(p_from, date_trunc('month', now()));
  v_to timestamptz := coalesce(p_to, now());
  v_rows jsonb;
  v_totals jsonb;
begin
  if not public.has_permission('purchases.view') then
    perform public.raise_app_error('NO_PERMISSION', 'missing purchases.view');
  end if;
  if v_business is null then
    perform public.raise_app_error('NO_BUSINESS', 'caller has no business');
  end if;

  select coalesce(jsonb_agg(r order by r.balance_due desc, r.purchases_total desc), '[]'::jsonb)
    into v_rows
    from (
      select s.id as supplier_id, s.name, s.phone,
             coalesce(pt.purchases_total, 0) as purchases_total,
             coalesce(pt.purchases_count, 0) as purchases_count,
             coalesce(pp.paid_total, 0) as paid_total,
             coalesce(bt.purchases_total, 0) - coalesce(bt.paid_total, 0) as balance_due
        from public.suppliers s
        left join lateral (
          select sum(pu.total) as purchases_total, count(*)::int as purchases_count
            from public.purchases pu
           where pu.supplier_id = s.id
             and pu.status <> 'cancelled'
             and pu.received_at between v_from and v_to
        ) pt on true
        left join lateral (
          select sum(sp.amount) as paid_total
            from public.supplier_payments sp
           where sp.supplier_id = s.id
             and sp.paid_at between v_from and v_to
        ) pp on true
        left join lateral (
          select sum(pu.total) filter (where pu.status <> 'cancelled') as purchases_total,
                 sum(pu.paid_total) filter (where pu.status <> 'cancelled') as paid_total
            from public.purchases pu
           where pu.supplier_id = s.id
        ) bt on true
       where s.business_id = v_business
         and s.deleted_at is null
    ) r;

  select jsonb_build_object(
           'suppliers', coalesce((select count(*) from public.suppliers
                                   where business_id = v_business and deleted_at is null), 0),
           'purchases', coalesce((select sum(pu.total) from public.purchases pu
                                   where pu.business_id = v_business
                                     and pu.status <> 'cancelled'
                                     and pu.received_at between v_from and v_to), 0),
           'paid', coalesce((select sum(sp.amount) from public.supplier_payments sp
                              where sp.business_id = v_business
                                and sp.paid_at between v_from and v_to), 0),
           'balance_due', coalesce((select sum(pu.total) - sum(pu.paid_total)
                                      from public.purchases pu
                                     where pu.business_id = v_business
                                       and pu.status <> 'cancelled'), 0))
    into v_totals;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'from', v_from, 'to', v_to, 'totals', v_totals, 'rows', v_rows));
end;
$$;

-- ---------------------------------------------------------------------------
-- report_customers (spec §49 customer report)
-- ---------------------------------------------------------------------------
create or replace function public.report_customers(
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_limit integer default 100
) returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_business uuid := public.current_business_id();
  v_from timestamptz := coalesce(p_from, date_trunc('month', now()));
  v_to timestamptz := coalesce(p_to, now());
  v_rows jsonb;
  v_totals jsonb;
begin
  -- The customer report aggregates revenue per customer (cross-cashier sales),
  -- so it needs both customer administration and the right to read every sale.
  -- A cashier holds `customers.manage` but not `sales.view_all` → denied.
  if not public.has_permission('customers.manage')
     or not public.has_permission('sales.view_all') then
    perform public.raise_app_error('NO_PERMISSION', 'missing customers.manage + sales.view_all');
  end if;
  if v_business is null then
    perform public.raise_app_error('NO_BUSINESS', 'caller has no business');
  end if;

  select coalesce(jsonb_agg(r order by r.revenue desc), '[]'::jsonb) into v_rows
    from (
      select c.id as customer_id, c.name, c.phone, c.loyalty_points,
             coalesce(a.invoices, 0) as invoices,
             coalesce(a.revenue, 0) as revenue,
             coalesce(a.outstanding, 0) as outstanding
        from public.customers c
        left join lateral (
          select count(*)::int as invoices,
                 coalesce(sum(s.grand_total), 0) as revenue,
                 coalesce(sum(greatest(s.grand_total - s.amount_paid, 0)), 0) as outstanding
            from public.sales s
           where s.customer_id = c.id
             and s.status <> 'cancelled'
             and s.sold_at between v_from and v_to
        ) a on true
       where c.business_id = v_business
         and c.deleted_at is null
       order by revenue desc
       limit greatest(p_limit, 1)
    ) r;

  select jsonb_build_object(
           'customers', coalesce((select count(*) from public.customers
                                   where business_id = v_business and deleted_at is null), 0),
           'invoices', coalesce((select count(*) from public.sales
                                  where business_id = v_business
                                    and customer_id is not null
                                    and status <> 'cancelled'
                                    and sold_at between v_from and v_to), 0),
           'revenue', coalesce((select sum(grand_total) from public.sales
                                 where business_id = v_business
                                   and customer_id is not null
                                   and status <> 'cancelled'
                                   and sold_at between v_from and v_to), 0),
           'loyalty_points', coalesce((select sum(loyalty_points) from public.customers
                                        where business_id = v_business and deleted_at is null), 0))
    into v_totals;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'from', v_from, 'to', v_to, 'totals', v_totals, 'rows', v_rows));
end;
$$;

-- ---------------------------------------------------------------------------
-- report_products (spec §52 product performance + §53 best sellers)
-- ---------------------------------------------------------------------------
create or replace function public.report_products(
  p_from timestamptz default null,
  p_to timestamptz default null,
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
  v_from timestamptz := coalesce(p_from, date_trunc('month', now()));
  v_to timestamptz := coalesce(p_to, now());
  v_branch uuid := coalesce(p_branch, public.current_branch_id_or_all());
  v_rows jsonb;
  v_totals jsonb;
begin
  if not public.has_permission('reports.profit.view') then
    perform public.raise_app_error('NO_PERMISSION', 'missing reports.profit.view');
  end if;
  if v_business is null then
    perform public.raise_app_error('NO_BUSINESS', 'caller has no business');
  end if;

  select coalesce(jsonb_agg(r order by r.profit desc), '[]'::jsonb) into v_rows
    from (
      select p.id as product_id, p.name, p.sku, p.selling_price,
             coalesce(a.qty_sold, 0) as qty_sold,
             coalesce(a.revenue, 0) as revenue,
             coalesce(a.cost, 0) as cost,
             coalesce(a.profit, 0) as profit,
             case when coalesce(a.revenue, 0) > 0
                  then round(coalesce(a.profit, 0) / a.revenue * 100, 2)
                  else 0 end as margin_pct,
             coalesce(i.on_hand, 0) as on_hand
        from public.products p
        left join public.inventories i
          on i.product_id = p.id and (v_branch is null or i.branch_id = v_branch)
        left join lateral (
          select sum(si.qty) as qty_sold,
                 sum(si.line_total) as revenue,
                 sum(si.qty * si.cost_at_sale) as cost,
                 sum(si.line_total - si.tax_amount - (si.qty * si.cost_at_sale)) as profit
            from public.sale_items si
            join public.sales s on s.id = si.sale_id
           where si.product_id = p.id
             and s.status <> 'cancelled'
             and s.sold_at between v_from and v_to
             and (v_branch is null or s.branch_id = v_branch)
        ) a on true
       where p.business_id = v_business
         and p.deleted_at is null
       order by profit desc
       limit greatest(p_limit, 1)
    ) r;

  select jsonb_build_object(
           'revenue', coalesce((select sum(si.line_total)
                                  from public.sale_items si
                                  join public.sales s on s.id = si.sale_id
                                 where s.business_id = v_business
                                   and s.status <> 'cancelled'
                                   and s.sold_at between v_from and v_to
                                   and (v_branch is null or s.branch_id = v_branch)), 0),
           'cost', coalesce((select sum(si.qty * si.cost_at_sale)
                               from public.sale_items si
                               join public.sales s on s.id = si.sale_id
                              where s.business_id = v_business
                                and s.status <> 'cancelled'
                                and s.sold_at between v_from and v_to
                                and (v_branch is null or s.branch_id = v_branch)), 0),
           'qty_sold', coalesce((select sum(si.qty)
                                   from public.sale_items si
                                   join public.sales s on s.id = si.sale_id
                                  where s.business_id = v_business
                                    and s.status <> 'cancelled'
                                    and s.sold_at between v_from and v_to
                                    and (v_branch is null or s.branch_id = v_branch)), 0))
    into v_totals;

  return jsonb_build_object('ok', true, 'data', jsonb_build_object(
    'from', v_from, 'to', v_to, 'branch_id', v_branch,
    'totals', v_totals, 'rows', v_rows));
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants (BACKEND_SETUP.md §4.8)
-- ---------------------------------------------------------------------------
revoke all on function public.report_expenses(timestamptz, timestamptz, uuid)   from public, anon;
revoke all on function public.report_suppliers(timestamptz, timestamptz)        from public, anon;
revoke all on function public.report_customers(timestamptz, timestamptz, int)   from public, anon;
revoke all on function public.report_products(timestamptz, timestamptz, uuid, int) from public, anon;

grant execute on function public.report_expenses(timestamptz, timestamptz, uuid)      to authenticated;
grant execute on function public.report_suppliers(timestamptz, timestamptz)           to authenticated;
grant execute on function public.report_customers(timestamptz, timestamptz, integer)  to authenticated;
grant execute on function public.report_products(timestamptz, timestamptz, uuid, integer) to authenticated;

-- migrate:down
--   drop function if exists public.report_products(timestamptz, timestamptz, uuid, integer);
--   drop function if exists public.report_customers(timestamptz, timestamptz, integer);
--   drop function if exists public.report_suppliers(timestamptz, timestamptz);
--   drop function if exists public.report_expenses(timestamptz, timestamptz, uuid);
--   restore dashboard_kpis / report_inventory from migration 120_views_reports
-- ---------------------------------------------------------------------------
