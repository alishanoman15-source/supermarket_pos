-- =============================================================================
-- 03_purchasing_wac.sql — pgTAP
-- Covers SPEC §55, §77, §97: purchase receive → stock in + weighted-average
-- cost, purchase-order lifecycle (draft → approved → partial → received),
-- over-receive rejection, receive idempotency, batch creation for tracked
-- products, and supplier payment accounting.
--
-- Single transaction, rolled back. Run with `supabase test db` or through
-- scripts/run_backend_tests.sh (linked project, no Docker).
-- =============================================================================
begin;

select no_plan();

-- ---------------------------------------------------------------------------
-- Fixtures
-- ---------------------------------------------------------------------------
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values
  ('cccccccc-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'owner-c@test.local', crypt('password', gen_salt('bf')),
   now(), now(), now(), '{}', '{"full_name":"Owner C"}');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"cccccccc-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.create_business_with_owner('{"name":"Business C","currency":"PKR"}','{"name":"Main C"}')$$,
  'owner C can onboard a business');
select lives_ok(
  $$insert into public.suppliers (business_id, name, phone)
    values (public.current_business_id(), 'Acme Supplies', '0300-1234567')$$,
  'owner can create a supplier');
select lives_ok(
  $$insert into public.products (business_id, name, sku, purchase_price, selling_price, tax_rate, reorder_level)
    values (public.current_business_id(), 'Sugar 1kg', 'SUG-1', 50.00, 70.00, 0, 5)$$,
  'owner can create a product');
select lives_ok(
  $$insert into public.products (business_id, name, sku, purchase_price, selling_price, tax_rate, reorder_level, track_batch)
    values (public.current_business_id(), 'Milk 1L', 'MILK-1', 100.00, 130.00, 0, 5, true)$$,
  'owner can create a batch-tracked product');
reset role;

select set_config('test.business_id',
  (select id::text from public.businesses where name = 'Business C'), false);
select set_config('test.branch_id',
  (select id::text from public.branches
    where business_id = current_setting('test.business_id')::uuid limit 1), false);
select set_config('test.supplier_id',
  (select id::text from public.suppliers where name = 'Acme Supplies'), false);
select set_config('test.product_id',
  (select id::text from public.products where sku = 'SUG-1'), false);
select set_config('test.batch_product_id',
  (select id::text from public.products where sku = 'MILK-1'), false);

-- ---------------------------------------------------------------------------
-- Direct receipt #1: 10 @ 50.00 → WAC becomes the unit cost (on_hand was 0)
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"cccccccc-0000-0000-0000-000000000001"}', true);
create temp table recv1 as
select public.receive_purchase(jsonb_build_object(
  'supplier_id', current_setting('test.supplier_id')::uuid,
  'branch_id', current_setting('test.branch_id')::uuid,
  'bill_number', 'BILL-1',
  'idempotency_key', 'recv-1',
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', current_setting('test.product_id')::uuid,
    'qty', 10, 'unit_cost', 50.00, 'tax_rate', 0))
)) as res;
select is((select res -> 'data' ->> 'total' from recv1), '500.00',
  'first receipt total = qty x unit cost');
select is((select res -> 'data' ->> 'duplicate' from recv1), 'false',
  'first receipt is not a duplicate');
reset role;

select set_config('test.bill1',
  (select res -> 'data' ->> 'purchase_id' from recv1), false);

select is((select on_hand from public.inventories
            where product_id = current_setting('test.product_id')::uuid),
  10.000::numeric, 'first receipt set on_hand to 10');
select is((select wac from public.inventories
            where product_id = current_setting('test.product_id')::uuid),
  50.0000::numeric, 'first receipt sets WAC to the unit cost');
select is((select count(*) from public.stock_movements
            where product_id = current_setting('test.product_id')::uuid
              and movement_type = 'purchase'),
  1::bigint, 'first receipt wrote exactly one purchase movement');

-- ---------------------------------------------------------------------------
-- Direct receipt #2: 5 @ 80.00 → WAC = (10*50 + 5*80) / 15 = 60.0000
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"cccccccc-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.receive_purchase(jsonb_build_object(
      'supplier_id', current_setting('test.supplier_id')::uuid,
      'branch_id', current_setting('test.branch_id')::uuid,
      'bill_number', 'BILL-2',
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid,
        'qty', 5, 'unit_cost', 80.00, 'tax_rate', 0))))$$,
  'a second receipt is accepted');
reset role;

select is((select on_hand from public.inventories
            where product_id = current_setting('test.product_id')::uuid),
  15.000::numeric, 'second receipt added 5 to on-hand');
select is((select wac from public.inventories
            where product_id = current_setting('test.product_id')::uuid),
  60.0000::numeric, 'weighted-average cost is (10*50 + 5*80) / 15 = 60');

-- ---------------------------------------------------------------------------
-- Receive idempotency: replaying the key never doubles the stock
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"cccccccc-0000-0000-0000-000000000001"}', true);
create temp table recv2_replay as
select public.receive_purchase(jsonb_build_object(
  'supplier_id', current_setting('test.supplier_id')::uuid,
  'branch_id', current_setting('test.branch_id')::uuid,
  'idempotency_key', 'recv-1',
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', current_setting('test.product_id')::uuid,
    'qty', 10, 'unit_cost', 50.00))
)) as res;
select is((select res -> 'data' ->> 'duplicate' from recv2_replay), 'true',
  'a replayed receipt idempotency key is reported as duplicate');
reset role;
select is((select on_hand from public.inventories
            where product_id = current_setting('test.product_id')::uuid),
  15.000::numeric, 'replayed receipt did not add stock again');

-- ---------------------------------------------------------------------------
-- Purchase order lifecycle: draft → approved → partial → received
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"cccccccc-0000-0000-0000-000000000001"}', true);
create temp table po1 as
select public.create_purchase_order(jsonb_build_object(
  'supplier_id', current_setting('test.supplier_id')::uuid,
  'branch_id', current_setting('test.branch_id')::uuid,
  'expected_at', (current_date + 7)::text,
  'items', jsonb_build_array(jsonb_build_object(
    'product_id', current_setting('test.product_id')::uuid,
    'qty', 20, 'unit_cost', 55.00, 'tax_rate', 0))
)) as res;
select is((select res -> 'data' ->> 'status' from po1), 'draft',
  'a new purchase order starts as draft');
select set_config('test.po_id',
  (select res -> 'data' ->> 'purchase_order_id' from po1), false);
select lives_ok(
  $$select public.approve_purchase_order(current_setting('test.po_id')::uuid)$$,
  'a draft purchase order can be approved');
reset role;

select is((select status from public.purchase_orders
            where id = current_setting('test.po_id')::uuid),
  'approved', 'purchase order status is approved');

-- Partial receipt of 5 units.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"cccccccc-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.receive_purchase(jsonb_build_object(
      'purchase_order_id', current_setting('test.po_id')::uuid,
      'idempotency_key', 'recv-po-1',
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid,
        'qty', 5, 'unit_cost', 55.00))))$$,
  'goods can be received against an approved purchase order');
reset role;

select is((select status from public.purchase_orders
            where id = current_setting('test.po_id')::uuid),
  'partially_received', 'partial receipt marks the order partially received');
select is((select received_qty from public.purchase_order_items
            where purchase_order_id = current_setting('test.po_id')::uuid),
  5.000::numeric, 'PO line received_qty tracks the partial receipt');

-- Receiving more than ordered is rejected.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"cccccccc-0000-0000-0000-000000000001"}', true);
select throws_like(
  $$select public.receive_purchase(jsonb_build_object(
      'purchase_order_id', current_setting('test.po_id')::uuid,
      'idempotency_key', 'recv-po-over',
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid,
        'qty', 20, 'unit_cost', 55.00))))$$,
  '%VALIDATION_FAILED%', 'receiving more than the ordered quantity is rejected');

-- Receive the remaining 15 → fully received.
select lives_ok(
  $$select public.receive_purchase(jsonb_build_object(
      'purchase_order_id', current_setting('test.po_id')::uuid,
      'idempotency_key', 'recv-po-2',
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.product_id')::uuid,
        'qty', 15, 'unit_cost', 55.00))))$$,
  'the remaining ordered quantity can be received');
reset role;

select is((select status from public.purchase_orders
            where id = current_setting('test.po_id')::uuid),
  'received', 'a fully received purchase order is marked received');

-- ---------------------------------------------------------------------------
-- Batch/expiry rows are written only for tracked products
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"cccccccc-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.receive_purchase(jsonb_build_object(
      'supplier_id', current_setting('test.supplier_id')::uuid,
      'branch_id', current_setting('test.branch_id')::uuid,
      'items', jsonb_build_array(jsonb_build_object(
        'product_id', current_setting('test.batch_product_id')::uuid,
        'qty', 12, 'unit_cost', 100.00,
        'batch_no', 'BATCH-1',
        'expiry_date', (current_date + 40)::text))))$$,
  'a tracked product can be received with a batch and expiry date');
reset role;

select is((select count(*) from public.product_batches
            where product_id = current_setting('test.batch_product_id')::uuid
              and batch_no = 'BATCH-1'),
  1::bigint, 'a batch row is created for a tracked product');
select is((select count(*) from public.product_batches
            where product_id = current_setting('test.product_id')::uuid),
  0::bigint, 'no batch rows are created for an untracked product');

-- ---------------------------------------------------------------------------
-- Supplier payment accounting
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"cccccccc-0000-0000-0000-000000000001"}', true);
select lives_ok(
  $$select public.pay_supplier(jsonb_build_object(
      'supplier_id', current_setting('test.supplier_id')::uuid,
      'purchase_id', current_setting('test.bill1')::uuid,
      'amount', 100.00,
      'method', 'cash',
      'idempotency_key', 'pay-1'))$$,
  'owner can record a partial supplier payment');
reset role;

select is((select paid_total from public.purchases
            where id = current_setting('test.bill1')::uuid),
  100.00::numeric, 'bill paid_total reflects the payment');
select is((select status from public.purchases
            where id = current_setting('test.bill1')::uuid),
  'partially_paid', 'a partly paid bill is marked partially_paid');
select is((select count(*) from public.supplier_payments
            where idempotency_key = 'pay-1'),
  1::bigint, 'exactly one supplier payment row exists');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"cccccccc-0000-0000-0000-000000000001"}', true);
select throws_like(
  $$select public.pay_supplier(jsonb_build_object(
      'supplier_id', current_setting('test.supplier_id')::uuid,
      'purchase_id', current_setting('test.bill1')::uuid,
      'amount', 500.00,
      'method', 'cash'))$$,
  '%VALIDATION_FAILED%', 'paying more than the bill balance is rejected');
reset role;

select is((select paid_total from public.purchases
            where id = current_setting('test.bill1')::uuid),
  100.00::numeric, 'a rejected payment leaves paid_total unchanged');

do $$
begin
  if (select num_failed()) > 0 then
    raise exception 'PGTAP: % test(s) failed', (select num_failed());
  end if;
end $$;

select * from finish();
rollback;
