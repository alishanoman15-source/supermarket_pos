-- =============================================================================
-- 150_views_inventory
-- inventory_view: on-hand stock joined to product names for the inventory list
-- (SPEC §35, screen #28).
--
-- Direct SELECT on public.products is revoked for clients (cost protection, Part
-- D3.3), so reads go through a view. Like product_pos_view this view is NOT
-- security_invoker: it reads as its owner and re-applies the business/branch
-- scope explicitly, so cross-tenant data can never leak.
-- =============================================================================

create or replace view public.inventory_view as
select
  i.product_id,
  i.branch_id,
  i.business_id,
  i.on_hand,
  i.reserved,
  i.updated_at,
  p.name,
  p.sku,
  p.barcode,
  p.unit_id,
  p.category_id,
  p.reorder_level,
  p.is_weight_based,
  p.status,
  case when p.reorder_level > 0 and i.on_hand <= p.reorder_level
       then true else false end as is_low
from public.inventories i
join public.products p on p.id = i.product_id
where i.business_id = public.current_business_id()
  and public.can_see_branch(i.business_id, i.branch_id)
  and p.status <> 'archived';

grant select on public.inventory_view to authenticated;

-- Cost protection (PART D3.3 / SPEC §107): `inventories.wac` is a cost figure, so
-- the raw table must not be readable by clients either. Valuation is served by the
-- permission-gated `report_inventory` RPC instead.
revoke select on public.inventories from authenticated, anon;

comment on view public.inventory_view is
  'Branch-scoped on-hand stock with product names for the inventory list; cost columns are never exposed.';

-- migrate:down
--   drop view if exists public.inventory_view;
