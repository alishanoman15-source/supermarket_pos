-- =============================================================================
-- 09_dashboard_reports.sql — pgTAP
-- Covers the extended dashboard KPI payload (product spec §7) and the report
-- RPCs added in migration 130_dashboard_reports_extension: expenses, suppliers,
-- customers, product performance, plus reorder suggestions on the inventory
-- report. Also proves a cashier is denied every management report.
--
-- Fixture ids are captured with `reset role` (the connection role may read
-- public.products; `authenticated` may not — cost protection).
--
-- Single transaction, rolled back. Run through scripts/run_backend_tests.sh.
-- =============================================================================
begin;

select no_plan();

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values
  ('99999999-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'owner-r@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Owner R"}'),
  ('99999999-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'cashier-r@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Cashier R"}');

-- ---------------------------------------------------------------------------
-- Owner onboards and creates the catalogue / party fixtures
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"99999999-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.create_business_with_owner('{"name":"Reports Store","currency":"PKR"}','{"name":"Main R"}')$$,
  'owner R onboards a business');
select lives_ok(
  $$insert into public.categories (business_id, name)
    values (public.current_business_id(), 'Beverages')$$,
  'owner creates a category');
select lives_ok(
  $$insert into public.products (business_id, name, sku, purchase_price,
                                 selling_price, tax_rate, reorder_level)
    values (public.current_business_id(), 'Reports Cola', 'RPT-A',
            40.00, 100.00, 0, 200)$$,
  'owner creates a product with a high reorder level');
select lives_ok(
  $$insert into public.suppliers (business_id, name)
    values (public.current_business_id(), 'Reports Supplier')$$,
  'owner creates a supplier');
select lives_ok(
  $$insert into public.customers (business_id, name, phone)
    values (public.current_business_id(), 'Reports Customer', '0300-1111111')$$,
  'owner creates a customer');
select lives_ok(
  $$insert into public.expense_categories (business_id, name)
    values (public.current_business_id(), 'Reports Utilities')$$,
  'owner creates an expense category');
reset role;

-- Fixture ids (connection role can read every table).
select set_config('test.business_id',
  (select id::text from public.businesses where name = 'Reports Store'), false);
select set_config('test.branch_id',
  (select b.id::text from public.branches b
    where b.business_id = current_setting('test.business_id')::uuid limit 1), false);
select set_config('test.product_id',
  (select id::text from public.products where sku = 'RPT-A'), false);
select set_config('test.category_id',
  (select id::text from public.categories
    where business_id = current_setting('test.business_id')::uuid
      and name = 'Beverages'), false);
select set_config('test.customer_id',
  (select id::text from public.customers
    where business_id = current_setting('test.business_id')::uuid
      and name = 'Reports Customer'), false);
select set_config('test.supplier_id',
  (select id::text from public.suppliers where name = 'Reports Supplier'), false);
select set_config('test.expense_cat',
  (select id::text from public.expense_categories
    where business_id = current_setting('test.business_id')::uuid
      and name = 'Reports Utilities'), false);

update public.products
   set category_id = current_setting('test.category_id')::uuid
 where id = current_setting('test.product_id')::uuid;

-- ---------------------------------------------------------------------------
-- Owner records an expense, receives stock (WAC = 40) and sells 5 units
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"99999999-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$insert into public.expenses (business_id, branch_id, category_id, amount, payment_method, note)
    values (current_setting('test.business_id')::uuid,
            current_setting('test.branch_id')::uuid,
            current_setting('test.expense_cat')::uuid,
            300.00, 'cash', 'reports electricity')$$,
  'owner records an expense');

create temp table rpt_recv as
select public.receive_purchase(jsonb_build_object(
  'supplier_id', current_setting('test.supplier_id')::uuid,
  'branch_id', current_setting('test.branch_id')::uuid,
  'bill_number', 'BILL-R-0',
  'idempotency_key', 'rpt-recv-1',
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', current_setting('test.product_id')::uuid,
    'qty', 100, 'unit_cost', 40.00, 'tax_rate', 0)))) as res;

select lives_ok(
  $$select public.open_shift('{"opening_float":500}')$$,
  'owner opens a shift');

create temp table rpt_sale as
select public.complete_sale(jsonb_build_object(
  'idempotency_key', 'rpt-sale-1',
  'customer_id', current_setting('test.customer_id')::uuid,
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', current_setting('test.product_id')::uuid, 'qty', 5)),
  'payments', jsonb_build_array(jsonb_build_object('method','cash','amount',500)))) as res;
reset role;

select is((select res -> 'data' ->> 'grand_total' from rpt_sale), '500.00',
  'the fixture sale totals 500.00');
select is((select res -> 'data' ->> 'total' from rpt_recv), '4000.00',
  'the fixture receipt cost 4000.00 (100 × 40)');
select set_config('test.purchase_id',
  (select res -> 'data' ->> 'purchase_id' from rpt_recv), false);

-- A partial supplier payment against the received bill.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"99999999-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.pay_supplier(jsonb_build_object(
      'supplier_id', current_setting('test.supplier_id')::uuid,
      'purchase_id', current_setting('test.purchase_id')::uuid,
      'amount', 400.00, 'method', 'cash',
      'idempotency_key', 'rpt-pay-1'))$$,
  'owner pays 400 against the bill');

-- Make the second user a cashier of the same business.
reset role;
update public.profiles
   set business_id = current_setting('test.business_id')::uuid,
       branch_id   = current_setting('test.branch_id')::uuid,
       role_id     = (select id from public.roles
                       where business_id = current_setting('test.business_id')::uuid
                         and key = 'cashier')
 where id = '99999999-0000-0000-0000-000000000002';

-- ---------------------------------------------------------------------------
-- Extended dashboard payload (product spec §7)
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"99999999-0000-0000-0000-000000000001"}', true);

create temp table rpt_dash as
select public.dashboard_kpis(now() - interval '30 days', now(), null) as res;

select ok((select res -> 'data' ? 'sales' from rpt_dash),
  'dashboard returns the sales block');
select is((select (res -> 'data' -> 'sales' ->> 'today')::numeric from rpt_dash), 500.00::numeric,
  'today''s sales equal the fixture sale');
select is((select (res -> 'data' -> 'sales' ->> 'total')::numeric from rpt_dash), 500.00::numeric,
  'lifetime sales equal the fixture sale');
select ok((select (res -> 'data' -> 'sales' ->> 'yesterday')::numeric from rpt_dash) >= 0,
  'yesterday''s sales are reported');
select ok((select (res -> 'data' -> 'sales' ->> 'week')::numeric from rpt_dash) >= 0,
  'weekly sales are reported');
select ok((select (res -> 'data' -> 'sales' ->> 'month')::numeric from rpt_dash) >= 0,
  'monthly sales are reported');

select is((select (res -> 'data' -> 'orders' ->> 'total')::int from rpt_dash), 1,
  'one invoice in the period');
select is((select (res -> 'data' -> 'orders' ->> 'completed')::int from rpt_dash), 1,
  'the invoice is completed');
select is((select (res -> 'data' -> 'orders' ->> 'cancelled')::int from rpt_dash), 0,
  'no cancelled invoices');
select is((select (res -> 'data' -> 'orders' ->> 'returned')::int from rpt_dash), 0,
  'no returned invoices');

select is((select (res -> 'data' -> 'inventory' ->> 'total_products')::int from rpt_dash), 1,
  'one active product');
select is((select (res -> 'data' -> 'inventory' ->> 'total_stock_units')::numeric from rpt_dash),
  95.000::numeric, '95 units remain after the sale');
select is((select (res -> 'data' -> 'inventory' ->> 'low_stock_count')::int from rpt_dash), 1,
  'the product is below its reorder level of 200');
select is((select (res -> 'data' -> 'inventory' ->> 'out_of_stock_count')::int from rpt_dash), 0,
  'nothing is out of stock');
select ok((select res -> 'data' -> 'inventory' -> 'expiring' from rpt_dash) is not null,
  'expiry buckets are reported');

select is((select (res -> 'data' -> 'financials' ->> 'revenue')::numeric from rpt_dash), 500.00::numeric,
  'financials revenue matches the sale');
select is((select (res -> 'data' -> 'financials' ->> 'cost_of_goods')::numeric from rpt_dash),
  200.00::numeric, 'COGS = 5 units × WAC 40');
select is((select (res -> 'data' -> 'financials' ->> 'gross_profit')::numeric from rpt_dash),
  300.00::numeric, 'gross profit = 500 - 200');
select is((select (res -> 'data' -> 'financials' ->> 'expenses')::numeric from rpt_dash), 300.00::numeric,
  'financials include the recorded expense');
select is((select (res -> 'data' -> 'financials' ->> 'net_profit')::numeric from rpt_dash), 0.00::numeric,
  'net profit = gross profit (300) - expenses (300)');

select is((select jsonb_array_length(res -> 'data' -> 'charts' -> 'sales_by_day') from rpt_dash), 14,
  'sales_by_day returns a 14-day series');
select is((select jsonb_array_length(res -> 'data' -> 'charts' -> 'sales_by_month') from rpt_dash), 12,
  'sales_by_month returns a 12-month series');
select is((select jsonb_array_length(res -> 'data' -> 'charts' -> 'top_products') from rpt_dash), 1,
  'top products lists the sold product');
select is((select jsonb_array_length(res -> 'data' -> 'charts' -> 'sales_by_category') from rpt_dash), 1,
  'sales are grouped by category');
select is((select res -> 'data' -> 'charts' -> 'payment_methods' -> 0 ->> 'method' from rpt_dash),
  'cash', 'payment method distribution reports cash');

-- ---------------------------------------------------------------------------
-- Report RPCs
-- ---------------------------------------------------------------------------
create temp table rpt_exp as
select public.report_expenses(now() - interval '30 days', now(), null) as res;
select is((select (res -> 'data' -> 'totals' ->> 'total')::numeric from rpt_exp), 300.00::numeric,
  'expense report totals the recorded expense');
select is((select jsonb_array_length(res -> 'data' -> 'by_category') from rpt_exp), 1,
  'expense report groups by category');
select is((select res -> 'data' -> 'by_payment_method' -> 0 ->> 'method' from rpt_exp), 'cash',
  'expense report groups by payment method');
select ok((select jsonb_array_length(res -> 'data' -> 'by_day') from rpt_exp) >= 1,
  'expense report returns a daily series');

create temp table rpt_sup as
select public.report_suppliers(now() - interval '30 days', now()) as res;
select is((select res -> 'data' -> 'rows' -> 0 ->> 'name' from rpt_sup), 'Reports Supplier',
  'supplier report lists the supplier');
select is((select (res -> 'data' -> 'rows' -> 0 ->> 'purchases_total')::numeric from rpt_sup),
  4000.00::numeric, 'supplier report totals period purchases');
select is((select (res -> 'data' -> 'rows' -> 0 ->> 'paid_total')::numeric from rpt_sup),
  400.00::numeric, 'supplier report totals period payments');
select is((select (res -> 'data' -> 'rows' -> 0 ->> 'balance_due')::numeric from rpt_sup),
  3600.00::numeric, 'supplier balance due = 4000 - 400');

create temp table rpt_cust as
select public.report_customers(now() - interval '30 days', now(), 100) as res;
select is((select res -> 'data' -> 'rows' -> 0 ->> 'name' from rpt_cust), 'Reports Customer',
  'customer report lists the customer');
select is((select (res -> 'data' -> 'rows' -> 0 ->> 'invoices')::int from rpt_cust), 1,
  'one invoice attributed to the customer');
select is((select (res -> 'data' -> 'rows' -> 0 ->> 'revenue')::numeric from rpt_cust), 500.00::numeric,
  'customer revenue matches the sale');

create temp table rpt_prod as
select public.report_products(now() - interval '30 days', now(), null, 100) as res;
select is((select res -> 'data' -> 'rows' -> 0 ->> 'name' from rpt_prod), 'Reports Cola',
  'product performance lists the sold product');
select is((select (res -> 'data' -> 'rows' -> 0 ->> 'qty_sold')::numeric from rpt_prod), 5.000::numeric,
  '5 units sold');
select is((select (res -> 'data' -> 'rows' -> 0 ->> 'profit')::numeric from rpt_prod), 300.00::numeric,
  'product profit = revenue - cost');
select ok((select (res -> 'data' -> 'rows' -> 0 ->> 'margin_pct')::numeric from rpt_prod) > 0,
  'product margin is reported');

create temp table rpt_inv as
select public.report_inventory(null, 60) as res;
select ok((select res -> 'data' ? 'reorder_suggestions' from rpt_inv),
  'inventory report returns reorder suggestions');
select is((select res -> 'data' -> 'reorder_suggestions' -> 0 ->> 'product_id' from rpt_inv),
  current_setting('test.product_id'),
  'the below-reorder-level product is suggested');
select ok((select (res -> 'data' -> 'reorder_suggestions' -> 0 ->> 'suggested_qty')::numeric
             from rpt_inv) > 0,
  'a positive reorder quantity is suggested');

reset role;

-- ---------------------------------------------------------------------------
-- Cashier denial: no management reports
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"99999999-0000-0000-0000-000000000002"}', true);

select ok(not public.has_permission('reports.dashboard.view'),
  'cashier has no dashboard permission');
select throws_like(
  $$select public.dashboard_kpis(now() - interval '7 days', now(), null)$$,
  '%NO_PERMISSION%', 'cashier cannot read the dashboard');
select throws_like(
  $$select public.report_expenses(now() - interval '7 days', now(), null)$$,
  '%NO_PERMISSION%', 'cashier cannot read the expense report');
select throws_like(
  $$select public.report_suppliers(now() - interval '7 days', now())$$,
  '%NO_PERMISSION%', 'cashier cannot read the supplier report');
select throws_like(
  $$select public.report_customers(now() - interval '7 days', now(), 10)$$,
  '%NO_PERMISSION%', 'cashier cannot read the customer report');
select throws_like(
  $$select public.report_products(now() - interval '7 days', now(), null, 10)$$,
  '%NO_PERMISSION%', 'cashier cannot read the product performance report');
select throws_like(
  $$select public.report_inventory(null, 60)$$,
  '%NO_PERMISSION%', 'cashier cannot read the inventory report');
reset role;

do $$
begin
  if (select num_failed()) > 0 then
    raise exception 'PGTAP: % test(s) failed', (select num_failed());
  end if;
end $$;

select * from finish();
rollback;
