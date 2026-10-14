-- =============================================================================
-- 07_extended_modules.sql — pgTAP
-- End-to-end smoke over the modules the earlier suites do not exercise:
--   loyalty earn + redeem, promotions / calculate_product_price, stock count
--   (start → submit → approve), stock transfer (in-transit → received),
--   cash movements + shift close, expenses, and every reporting RPC.
--
-- One transaction, rolled back. Run through scripts/run_backend_tests.sh.
-- =============================================================================
begin;

select no_plan();

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values
  ('77777777-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'ext-owner@test.local',
   crypt('password', gen_salt('bf')), now(), now(), now(), '{}', '{"full_name":"Ext Owner"}');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"77777777-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.create_business_with_owner('{"name":"Extended Store","currency":"PKR"}','{"name":"Main Ext"}')$$,
  'owner onboards an extended business');
select lives_ok(
  $$insert into public.products (business_id, name, sku, barcode, purchase_price, selling_price, tax_rate, reorder_level)
    values (public.current_business_id(), 'Ext Cola', 'EXT-A', '4006381333931', 40.00, 100.00, 0, 5),
           (public.current_business_id(), 'Ext Chips', 'EXT-B', '4006381333948', 20.00, 50.00, 0, 5)$$,
  'owner creates two products');
reset role;

select set_config('test.business_id',
  (select id::text from public.businesses where name = 'Extended Store'), false);
select set_config('test.branch_id',
  (select b.id::text from public.branches b
    where b.business_id = current_setting('test.business_id')::uuid limit 1), false);
select set_config('test.product_a',
  (select id::text from public.products where sku = 'EXT-A'), false);
select set_config('test.product_b',
  (select id::text from public.products where sku = 'EXT-B'), false);

-- A second branch for transfer testing (RLS bypassed as the connection role).
insert into public.branches (business_id, name)
values (current_setting('test.business_id')::uuid, 'Second Ext');
select set_config('test.branch2_id',
  (select id::text from public.branches
    where business_id = current_setting('test.business_id')::uuid and name = 'Second Ext'), false);

-- Loyalty earns at 1 point per currency unit sold.
update public.businesses
   set settings = coalesce(settings, '{}'::jsonb) || '{"loyalty_earn_rate": 1}'::jsonb
 where id = current_setting('test.business_id')::uuid;

-- A customer for the sale / loyalty flow.
insert into public.customers (business_id, name, phone)
values (current_setting('test.business_id')::uuid, 'Walk-in Loyal', '0300-0000000');
select set_config('test.customer_id',
  (select id::text from public.customers
    where business_id = current_setting('test.business_id')::uuid and name = 'Walk-in Loyal'), false);

-- Stock in 100 of product A.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"77777777-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.adjust_stock(jsonb_build_object(
      'product_id', current_setting('test.product_a')::uuid,
      'qty_delta', 100, 'reason', 'opening stock'))$$,
  'owner stocks in 100 units');

-- Open the shift the sale below will be attached to.
create temp table ext_shift as
select public.open_shift('{"opening_float":1000}') as res;
reset role;
select set_config('test.shift_id',
  (select res -> 'data' ->> 'shift_id' from ext_shift), false);
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"77777777-0000-0000-0000-000000000001"}', true);

-- ---------------------------------------------------------------------------
-- Loyalty: sell to a customer, earn points, then redeem some
-- ---------------------------------------------------------------------------
create temp table ext_sale as
select public.complete_sale(jsonb_build_object(
  'idempotency_key', 'ext-sale-1',
  'customer_id', current_setting('test.customer_id')::uuid,
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', current_setting('test.product_a')::uuid, 'qty', 5)),
  'payments', jsonb_build_array(jsonb_build_object('method','cash','amount',500)))) as res;
reset role;

select is((select res -> 'data' ->> 'grand_total' from ext_sale), '500.00',
  'sale computes a 500.00 grand total');
select is((select c.loyalty_points from public.customers c
            where c.id = current_setting('test.customer_id')::uuid),
  500.00::numeric, 'customer earned 500 loyalty points (1 per unit)');
select is((select count(*) from public.loyalty_transactions
            where customer_id = current_setting('test.customer_id')::uuid and type = 'earn'),
  1::bigint, 'one loyalty earn ledger row was written');
select is((select on_hand from public.inventories
            where product_id = current_setting('test.product_a')::uuid
              and branch_id = current_setting('test.branch_id')::uuid),
  95.000::numeric, 'stock fell to 95 after selling 5');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"77777777-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.redeem_loyalty_points(jsonb_build_object(
      'customer_id', current_setting('test.customer_id')::uuid, 'points', 200))$$,
  'owner redeems 200 loyalty points');
reset role;
select is((select c.loyalty_points from public.customers c
            where c.id = current_setting('test.customer_id')::uuid),
  300.00::numeric, 'loyalty balance is 300 after redemption');

-- ---------------------------------------------------------------------------
-- Promotions: percent_off on product A is applied by calculate_product_price
-- ---------------------------------------------------------------------------
insert into public.promotions (business_id, name, promo_type, value, status)
values (current_setting('test.business_id')::uuid, 'Ext 10% off', 'percent_off', 10, 'active');
select set_config('test.promo_id',
  (select id::text from public.promotions
    where business_id = current_setting('test.business_id')::uuid and name = 'Ext 10% off'), false);
insert into public.promotion_items (promotion_id, product_id)
values (current_setting('test.promo_id')::uuid, current_setting('test.product_a')::uuid);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"77777777-0000-0000-0000-000000000001"}', true);
create temp table ext_price as
select public.calculate_product_price(current_setting('test.product_a')::uuid, 2) as res;
select is((select (res ->> 'discount')::numeric from ext_price), 20.00::numeric,
  'calculate_product_price applies the active 10% promotion to 2 units (20.00)');
select is((select (res ->> 'unit_price')::numeric from ext_price), 100.00::numeric,
  'percent_off leaves the unit price unchanged');

-- ---------------------------------------------------------------------------
-- Stock count: draft → submitted → approved adjusts stock by the variance
-- ---------------------------------------------------------------------------
create temp table ext_count as
select public.start_stock_count('{"note":"ext count"}') as res;
reset role;
select set_config('test.count_id',
  (select res -> 'data' ->> 'stock_count_id' from ext_count), false);
select is((select status from public.stock_counts where id = current_setting('test.count_id')::uuid),
  'draft', 'stock count starts in draft');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"77777777-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.submit_stock_count(
      current_setting('test.count_id')::uuid,
      jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_a')::uuid, 'counted_qty', 90)))$$,
  'physical count of 90 is submitted (system expects 95)');
select lives_ok(
  $$select public.approve_stock_count(current_setting('test.count_id')::uuid)$$,
  'manager approves the stock count');
reset role;
select is((select on_hand from public.inventories
            where product_id = current_setting('test.product_a')::uuid
              and branch_id = current_setting('test.branch_id')::uuid),
  90.000::numeric, 'approving the count corrected stock from 95 to 90 (-5 variance)');
select is((select count(*) from public.stock_movements
            where product_id = current_setting('test.product_a')::uuid
              and movement_type = 'count_correction'),
  1::bigint, 'the count correction wrote one stock movement');

-- ---------------------------------------------------------------------------
-- Stock transfer: branch 1 → branch 2, then receive
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"77777777-0000-0000-0000-000000000001"}', true);
create temp table ext_transfer as
select public.transfer_stock(jsonb_build_object(
  'from_branch_id', current_setting('test.branch_id')::uuid,
  'to_branch_id', current_setting('test.branch2_id')::uuid,
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', current_setting('test.product_a')::uuid, 'qty', 2)))) as res;
reset role;
select set_config('test.transfer_id',
  (select res -> 'data' ->> 'transfer_id' from ext_transfer), false);
select is((select on_hand from public.inventories
            where product_id = current_setting('test.product_a')::uuid
              and branch_id = current_setting('test.branch_id')::uuid),
  88.000::numeric, 'source branch fell to 88 after dispatching 2');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"77777777-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.receive_transfer(current_setting('test.transfer_id')::uuid)$$,
  'destination branch receives the transfer');
reset role;
select is((select on_hand from public.inventories
            where product_id = current_setting('test.product_a')::uuid
              and branch_id = current_setting('test.branch2_id')::uuid),
  2.000::numeric, 'destination branch gained 2 units');
select is((select status from public.stock_transfers where id = current_setting('test.transfer_id')::uuid),
  'received', 'transfer is marked received');

-- ---------------------------------------------------------------------------
-- Cash drawer + shift close
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"77777777-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.record_cash_movement(jsonb_build_object(
      'shift_id', current_setting('test.shift_id')::uuid,
      'type', 'drawer_out', 'amount', 100, 'note', 'petty cash'))$$,
  'owner records a drawer-out movement');
select lives_ok(
  $$select public.close_shift(jsonb_build_object(
      'shift_id', current_setting('test.shift_id')::uuid,
      'closing_counted', 1900, 'variance_reason', 'counted short'))$$,
  'owner closes the shift with a counted amount');
reset role;
select is((select status from public.pos_shifts where id = current_setting('test.shift_id')::uuid),
  'closed', 'shift is closed');

-- ---------------------------------------------------------------------------
-- Expenses
-- ---------------------------------------------------------------------------
insert into public.expense_categories (business_id, name)
values (current_setting('test.business_id')::uuid, 'Ext Utilities');
select set_config('test.expense_cat',
  (select id::text from public.expense_categories
    where business_id = current_setting('test.business_id')::uuid and name = 'Ext Utilities'), false);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"77777777-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$insert into public.expenses (business_id, branch_id, category_id, amount, payment_method, note)
    values (current_setting('test.business_id')::uuid,
            current_setting('test.branch_id')::uuid,
            current_setting('test.expense_cat')::uuid,
            250.00, 'cash', 'ext electricity')$$,
  'owner records an expense');
reset role;
select is((select count(*) from public.expenses
            where business_id = current_setting('test.business_id')::uuid and amount = 250.00),
  1::bigint, 'the expense row is stored');

-- ---------------------------------------------------------------------------
-- Reporting RPCs all return without error
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"77777777-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.dashboard_kpis(now() - interval '30 days', now(), null)$$,
  'dashboard_kpis runs');
select lives_ok(
  $$select public.report_sales(now() - interval '30 days', now(), null, null)$$,
  'report_sales runs');
select lives_ok(
  $$select public.report_profit(now() - interval '30 days', now(), null)$$,
  'report_profit runs');
select lives_ok(
  $$select public.report_inventory(null, 50)$$,
  'report_inventory runs');
select lives_ok(
  $$select public.report_purchases(now() - interval '30 days', now(), null)$$,
  'report_purchases runs');
select lives_ok(
  $$select public.report_cash(now() - interval '30 days', now(), null)$$,
  'report_cash runs');
select lives_ok(
  $$select public.report_costing(null, 50)$$,
  'report_costing runs');

-- ---------------------------------------------------------------------------
-- Audit trail: the sale, adjustment and count approval were all logged
-- ---------------------------------------------------------------------------
reset role;
select ok((select count(*) from public.audit_logs
            where business_id = current_setting('test.business_id')::uuid
              and action in ('sale.complete','stock.adjust','stock_count.approve')) >= 3,
  'sensitive actions were written to the audit log');

do $$
begin
  if (select num_failed()) > 0 then
    raise exception 'PGTAP: % test(s) failed', (select num_failed());
  end if;
end $$;

select * from finish();
rollback;
