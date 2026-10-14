-- =============================================================================
-- seed.sql — SYSTEM DATA ONLY (BACKEND_SETUP.md Part B16, §3)
-- Permission catalogue, system units, system expense categories.
-- No business/demo/fixture data. Idempotent.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Permission catalogue (SPEC §67, Part E). Keys are stable — never rename.
-- ---------------------------------------------------------------------------
insert into public.permissions (key, description, category) values
  ('business.manage',          'Edit business profile and settings',      'business'),
  ('branches.manage',          'Create and edit branches',               'business'),
  ('branches.access_all',      'See data from every branch',              'business'),
  ('users.manage',             'Invite and manage staff accounts',       'business'),
  ('roles.manage',             'Create roles and change permissions',     'business'),
  ('products.view',            'View the product catalogue',              'catalog'),
  ('products.create',          'Create products',                         'catalog'),
  ('products.update',          'Edit products',                           'catalog'),
  ('products.deactivate',      'Archive or deactivate products',          'catalog'),
  ('products.view_cost',       'View purchase price and cost data',       'catalog'),
  ('pricing.override',         'Override a line price at POS',            'pricing'),
  ('pricing.discount',         'Apply a line discount',                   'pricing'),
  ('pricing.discount_cart',    'Apply a cart-level discount',             'pricing'),
  ('inventory.view',           'View stock levels and movements',         'inventory'),
  ('inventory.adjust',         'Adjust stock manually',                   'inventory'),
  ('inventory.transfer',       'Transfer stock between branches',         'inventory'),
  ('inventory.count',          'Run stock counts',                        'inventory'),
  ('inventory.count_approve',  'Approve a submitted stock count',         'inventory'),
  ('purchases.view',           'View purchase orders and supplier data',  'purchasing'),
  ('purchases.create',         'Create purchase orders',                  'purchasing'),
  ('purchases.approve',        'Approve purchase orders',                 'purchasing'),
  ('purchases.receive',        'Receive goods and update stock cost',     'purchasing'),
  ('suppliers.manage',         'Create and edit suppliers',               'purchasing'),
  ('suppliers.pay',            'Record supplier payments',                'purchasing'),
  ('pos.sell',                 'Use the POS terminal',                    'pos'),
  ('pos.sell_offline',         'Complete POS sales while offline',         'pos'),
  ('pos.hold',                 'Hold and resume carts',                   'pos'),
  ('sales.view',               'View sales',                              'sales'),
  ('sales.view_all',           'View sales from every cashier',           'sales'),
  ('sales.cancel',             'Void a completed sale',                   'sales'),
  ('returns.process',          'Process returns and refunds',             'sales'),
  ('refund.large',             'Approve refunds above the threshold',     'sales'),
  ('customers.manage',         'Create and edit customers',               'customers'),
  ('loyalty.manage',           'Adjust customer loyalty points',          'customers'),
  ('expenses.manage',          'Record and manage expenses',              'finance'),
  ('shifts.open',              'Open a cash shift',                       'finance'),
  ('shifts.close',             'Close a cash shift',                      'finance'),
  ('cash.move',                'Record drawer cash in/out',               'finance'),
  ('reports.dashboard.view',   'View dashboard KPIs',                     'reports'),
  ('reports.sales.view',       'View the sales report',                   'reports'),
  ('reports.profit.view',      'View profit and costing reports',         'reports'),
  ('reports.inventory.view',   'View the inventory report',               'reports'),
  ('reports.purchases.view',   'View the purchases report',               'reports'),
  ('reports.cash.view',        'View the cash and shifts report',         'reports'),
  ('reports.shift.self',       'View your own shift summary',             'reports'),
  ('promotions.manage',        'Create and edit promotions',              'marketing'),
  ('notifications.view',       'Receive in-app notifications',            'system'),
  ('audit.view',               'View the audit log',                      'system'),
  ('settings.manage',          'Change business settings',                'system'),
  ('data.import',              'Import data from CSV/XLSX',               'system'),
  ('data.export',              'Export data to CSV/XLSX/PDF',             'system')
on conflict (key) do update
  set description = excluded.description,
      category    = excluded.category;

-- ---------------------------------------------------------------------------
-- System units (SPEC §5). business_id NULL = shared system unit.
-- ---------------------------------------------------------------------------
insert into public.units (business_id, key, name, abbreviation, decimals_allowed, is_system)
values
  (null, 'pcs', 'Piece',      'pcs', 0, true),
  (null, 'kg',  'Kilogram',   'kg',  3, true),
  (null, 'g',   'Gram',       'g',   0, true),
  (null, 'l',   'Litre',      'L',   3, true),
  (null, 'ml',  'Millilitre', 'mL',  0, true),
  (null, 'box', 'Box',        'box', 0, true),
  (null, 'pack','Pack',       'pack',0, true)
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- System expense categories (SPEC §17)
-- ---------------------------------------------------------------------------
insert into public.expense_categories (business_id, name, is_system)
values
  (null, 'Rent',            true),
  (null, 'Utilities',       true),
  (null, 'Salaries',        true),
  (null, 'Transport',       true),
  (null, 'Maintenance',     true),
  (null, 'Marketing',       true),
  (null, 'Packaging',       true),
  (null, 'Other',           true)
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- Seed verification (helps CI prove the catalogue landed)
-- ---------------------------------------------------------------------------
do $$
declare
  v_perms integer;
  v_units integer;
begin
  select count(*) into v_perms from public.permissions;
  select count(*) into v_units from public.units where business_id is null;
  raise notice 'seed: % permissions, % system units', v_perms, v_units;
  if v_perms < 50 then
    raise exception 'seed incomplete: expected the full permission catalogue';
  end if;
end $$;
