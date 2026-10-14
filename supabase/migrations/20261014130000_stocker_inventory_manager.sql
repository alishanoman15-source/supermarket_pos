-- =============================================================================
-- 123_stocker_inventory_manager
--
-- SPEC §3.5 "Inventory Manager": products, stock, transfers, adjustments,
-- **purchase receiving** and **inventory reports**. The seeded stocker role
-- covered everything except receiving and the inventory report, so the role's
-- navigation offered no Purchases / Inventory report entry (§87).
--
-- Idempotent: only ever adds the missing grants.
-- migrate:up
-- =============================================================================
insert into public.role_permissions (role_id, permission_id)
select r.id, pm.id
from public.roles r
cross join public.permissions pm
where r.key = 'stocker'
  and coalesce(r.is_system, false)
  and pm.key in ('purchases.view', 'purchases.receive', 'reports.inventory.view')
on conflict do nothing;

-- migrate:down
--   delete from public.role_permissions rp
--   using public.roles r, public.permissions pm
--   where rp.role_id = r.id and rp.permission_id = pm.id
--     and r.key = 'stocker' and r.is_system
--     and pm.key in ('purchases.view','purchases.receive','reports.inventory.view');
