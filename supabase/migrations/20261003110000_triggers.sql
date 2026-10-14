-- =============================================================================
-- 100_triggers
-- updated_at, auth.users → profiles sync, price history, stock-write guard,
-- immutability guards and low-stock notifications (BACKEND_SETUP.md Part G1).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- updated_at on every table that carries the column
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
begin
  for r in
    select c.relname
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      join pg_attribute a on a.attrelid = c.oid
     where n.nspname = 'public'
       and c.relkind = 'r'
       and a.attname = 'updated_at'
       and a.attnum > 0
       and not a.attisdropped
  loop
    execute format('drop trigger if exists set_updated_at_trg on public.%I', r.relname);
    execute format(
      'create trigger set_updated_at_trg before update on public.%I
         for each row execute function public.set_updated_at()', r.relname);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- auth.users → profiles: create the profile row on signup (SPEC §66).
--   The dashboard created profiles with `id` as PK and a nullable
--   `auth_user_id`; both are populated here so the documented helper
--   functions keep working verbatim.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, auth_user_id, name, phone, status)
  values (
    new.id,
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
      split_part(new.email, '@', 1)
    ),
    new.raw_user_meta_data ->> 'phone',
    'active'
  )
  on conflict (id) do update
     set auth_user_id = excluded.auth_user_id,
         name = coalesce(nullif(public.profiles.name, ''), excluded.name);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill any auth users that predate the trigger.
insert into public.profiles (id, auth_user_id, name, status)
select u.id, u.id,
       coalesce(nullif(trim(u.raw_user_meta_data ->> 'full_name'), ''), split_part(u.email, '@', 1)),
       'active'
  from auth.users u
 where not exists (select 1 from public.profiles p where p.id = u.id);

-- ---------------------------------------------------------------------------
-- price_history on products price change (SPEC §72)
-- ---------------------------------------------------------------------------
create or replace function public.handle_product_price_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.selling_price is distinct from old.selling_price
     or new.purchase_price is distinct from old.purchase_price then
    insert into public.price_history (
      business_id, product_id, old_selling_price, new_selling_price,
      old_purchase_price, new_purchase_price, changed_by
    ) values (
      new.business_id, new.id, old.selling_price, new.selling_price,
      old.purchase_price, new.purchase_price, public.current_profile_id()
    );

    perform public.write_audit(new.business_id, null, 'product.price_change', 'products', new.id,
      jsonb_build_object('selling_price', old.selling_price, 'purchase_price', old.purchase_price),
      jsonb_build_object('selling_price', new.selling_price, 'purchase_price', new.purchase_price));
  end if;
  return new;
end;
$$;

drop trigger if exists products_price_history_trg on public.products;
create trigger products_price_history_trg
  after update on public.products
  for each row execute function public.handle_product_price_change();

-- ---------------------------------------------------------------------------
-- Stock-write guard: clients may never write inventories directly (SPEC §73).
--   apply_stock_delta() sets app.stock_write = 'on' inside its transaction.
-- ---------------------------------------------------------------------------
create or replace function public.guard_inventory_write()
returns trigger
language plpgsql
as $$
begin
  if coalesce(current_setting('app.stock_write', true), 'off') <> 'on' then
    raise exception 'USE_RPC: inventory may only change through a business RPC'
      using errcode = 'P0001';
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists inventories_guard_trg on public.inventories;
create trigger inventories_guard_trg
  before insert or update or delete on public.inventories
  for each row execute function public.guard_inventory_write();

-- stock_movements is append-only
create or replace function public.guard_append_only()
returns trigger
language plpgsql
as $$
begin
  raise exception 'USE_RPC: % is append-only', tg_table_name using errcode = 'P0001';
end;
$$;

drop trigger if exists stock_movements_append_trg on public.stock_movements;
create trigger stock_movements_append_trg
  before update or delete on public.stock_movements
  for each row execute function public.guard_append_only();

drop trigger if exists audit_logs_append_trg on public.audit_logs;
create trigger audit_logs_append_trg
  before update or delete on public.audit_logs
  for each row execute function public.guard_append_only();

drop trigger if exists loyalty_transactions_append_trg on public.loyalty_transactions;
create trigger loyalty_transactions_append_trg
  before update or delete on public.loyalty_transactions
  for each row execute function public.guard_append_only();

-- ---------------------------------------------------------------------------
-- sale_items of a completed sale are immutable (SPEC §76)
-- ---------------------------------------------------------------------------
create or replace function public.guard_sale_item_immutable()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status text;
begin
  select s.status into v_status from public.sales s where s.id = old.sale_id;
  if v_status is not null and v_status <> 'cancelled' then
    raise exception 'USE_RPC: sale items of a completed sale are immutable'
      using errcode = 'P0001';
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists sale_items_immutable_trg on public.sale_items;
create trigger sale_items_immutable_trg
  before update or delete on public.sale_items
  for each row execute function public.guard_sale_item_immutable();

-- ---------------------------------------------------------------------------
-- Low-stock / out-of-stock notifications after a stock movement (SPEC §19)
-- ---------------------------------------------------------------------------
create or replace function public.handle_stock_notification()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_reorder numeric(14,3);
  v_name text;
  v_type text;
  v_title text;
begin
  select p.reorder_level, p.name into v_reorder, v_name
    from public.products p where p.id = new.product_id;
  if not found then
    return new;
  end if;

  if new.qty_after <= 0 then
    v_type := 'OUT_OF_STOCK';
    v_title := coalesce(v_name, 'Product') || ' is out of stock';
  elsif v_reorder > 0 and new.qty_after <= v_reorder then
    v_type := 'LOW_STOCK';
    v_title := coalesce(v_name, 'Product') || ' is low on stock';
  else
    return new;
  end if;

  -- deduplicate: skip when the same unread alert already exists for this product
  if exists (
    select 1 from public.notifications n
     where n.business_id = new.business_id
       and n.type = v_type
       and n.is_read = false
       and (n.data ->> 'product_id') = new.product_id::text
  ) then
    return new;
  end if;

  insert into public.notifications (business_id, branch_id, user_id, type, title, body, data)
  select new.business_id, new.branch_id, pr.id, v_type, v_title,
         format('On hand %s (reorder at %s)', new.qty_after, v_reorder),
         jsonb_build_object('product_id', new.product_id, 'branch_id', new.branch_id,
                            'on_hand', new.qty_after)
    from public.profiles pr
   where pr.business_id = new.business_id
     and pr.status = 'active'
     and pr.role_id in (
       select r.id from public.roles r
        join public.role_permissions rp on rp.role_id = r.id
        join public.permissions pm on pm.id = rp.permission_id
       where pm.key = 'inventory.view'
     );

  return new;
end;
$$;

drop trigger if exists stock_movements_notify_trg on public.stock_movements;
create trigger stock_movements_notify_trg
  after insert on public.stock_movements
  for each row execute function public.handle_stock_notification();

-- ---------------------------------------------------------------------------
-- migrate:down
--   drop trigger if exists stock_movements_notify_trg on public.stock_movements;
--   drop trigger if exists sale_items_immutable_trg on public.sale_items;
--   drop trigger if exists loyalty_transactions_append_trg on public.loyalty_transactions;
--   drop trigger if exists audit_logs_append_trg on public.audit_logs;
--   drop trigger if exists stock_movements_append_trg on public.stock_movements;
--   drop trigger if exists inventories_guard_trg on public.inventories;
--   drop trigger if exists products_price_history_trg on public.products;
--   drop trigger if exists on_auth_user_created on auth.users;
-- ---------------------------------------------------------------------------