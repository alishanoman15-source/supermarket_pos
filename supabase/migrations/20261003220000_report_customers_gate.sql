-- =============================================================================
-- 140_report_customers_gate
-- Forward fix for `report_customers`: gate on a single, UI-expressible token.
--
-- The first version required `customers.manage AND sales.view_all`, which the
-- route policy layer cannot express (it matches any token in a list). Both
-- sides now agree on `sales.view_all`: the report aggregates revenue across
-- every cashier's sales, so it needs cross-cashier read access, and a cashier
-- never holds that key (pgTAP 09 keeps proving the denial).
-- =============================================================================

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
  if not public.has_permission('sales.view_all') then
    perform public.raise_app_error('NO_PERMISSION', 'missing sales.view_all');
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

revoke all on function public.report_customers(timestamptz, timestamptz, integer) from public, anon;
grant execute on function public.report_customers(timestamptz, timestamptz, integer) to authenticated;

-- migrate:down
--   restore report_customers from 130_dashboard_reports_extension
-- ---------------------------------------------------------------------------
