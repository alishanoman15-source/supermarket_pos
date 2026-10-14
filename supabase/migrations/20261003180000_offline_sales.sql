-- Offline sales may use the price captured at checkout and may temporarily
-- drive stock below zero. Only callers with pos.sell_offline can use this RPC.
insert into public.permissions (key, description, category)
values (
  'pos.sell_offline',
  'Complete offline POS sales at their captured price, including negative stock',
  'pos'
)
on conflict (key) do nothing;

-- New and existing cashier roles receive the explicit offline-sale permission.
insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
  from public.roles r
  join public.permissions p on p.key = 'pos.sell_offline'
 where r.key = 'cashier'
on conflict do nothing;

create or replace function public.grant_cashier_offline_sale_permission()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (
    select 1
      from public.roles r
      join public.permissions p on p.id = new.permission_id
     where r.id = new.role_id
       and r.key = 'cashier'
       and p.key = 'pos.sell'
  ) then
    insert into public.role_permissions (role_id, permission_id)
    select new.role_id, p.id
      from public.permissions p
     where p.key = 'pos.sell_offline'
    on conflict do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists cashier_offline_sale_permission on public.role_permissions;
create trigger cashier_offline_sale_permission
after insert on public.role_permissions
for each row execute function public.grant_cashier_offline_sale_permission();

alter table public.sales
  add column if not exists offline_mode boolean not null default false;

-- A price snapshot is an override only within the transaction-local context
-- established by complete_offline_sale. Clients cannot set this context via
-- PostgREST; the wrapper checks the dedicated permission first.
create or replace function public.has_permission(p_key text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.profiles pr
      join public.role_permissions rp on rp.role_id = pr.role_id
      join public.permissions pm on pm.id = rp.permission_id
     where pr.auth_user_id = auth.uid()
       and pr.status = 'active'
       and pm.key = p_key
  ) or (
    p_key = 'pricing.override'
    and current_setting('app.offline_sale', true) = 'on'
    and exists (
      select 1
        from public.profiles pr
        join public.role_permissions rp on rp.role_id = pr.role_id
        join public.permissions pm on pm.id = rp.permission_id
       where pr.auth_user_id = auth.uid()
         and pr.status = 'active'
         and pm.key = 'pos.sell_offline'
    )
  )
$$;

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
  v_offline_allowed boolean :=
    current_setting('app.offline_sale', true) = 'on'
    and public.has_permission('pos.sell_offline');
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

  if v_after < 0
     and not public.allow_negative_stock(p_business)
     and not v_offline_allowed then
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

create or replace function public.complete_offline_sale(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_result jsonb;
  v_sale_id uuid;
begin
  if not public.has_permission('pos.sell_offline') then
    perform public.raise_app_error(
      'NO_PERMISSION',
      'missing permission pos.sell_offline',
      jsonb_build_object('permission', 'pos.sell_offline')
    );
  end if;

  perform set_config('app.offline_sale', 'on', true);
  v_result := public.complete_sale(p_payload);
  v_sale_id := nullif(v_result #>> '{data,sale_id}', '')::uuid;
  if v_sale_id is not null then
    update public.sales set offline_mode = true where id = v_sale_id;
  end if;
  return v_result;
end;
$$;

revoke all on function public.complete_offline_sale(jsonb) from public, anon;
grant execute on function public.complete_offline_sale(jsonb) to authenticated;
