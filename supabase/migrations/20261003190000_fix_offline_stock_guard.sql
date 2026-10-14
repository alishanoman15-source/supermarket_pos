-- =============================================================================
-- 190_fix_offline_stock_guard
-- The offline-sales migration (180) taught `apply_stock_delta` to let the
-- offline RPC drive stock below zero. It computed:
--
--   v_offline_allowed := current_setting('app.offline_sale', true) = 'on'
--                        and public.has_permission('pos.sell_offline');
--
-- When `app.offline_sale` is unset (every ordinary online sale) the first
-- comparison is NULL, so `v_offline_allowed` is NULL and the guard
--
--   if v_after < 0 and not allow_negative_stock(...) and not v_offline_allowed
--
-- evaluates to NULL -> the branch never fires -> the negative-stock policy is
-- silently ignored and ordinary sales can oversell (SPEC §8 / §60). This
-- replaces the function with a NULL-safe flag so the guard fails closed.
--
-- Shipped as a new migration (not an edit of 180) so an already-provisioned
-- project receives the fix on `supabase db push`.
-- =============================================================================

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
    coalesce(current_setting('app.offline_sale', true), '') = 'on'
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
     and not coalesce(v_offline_allowed, false) then
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
