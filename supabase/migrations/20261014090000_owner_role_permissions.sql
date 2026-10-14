-- =============================================================================
-- 121_owner_role_permissions
--
-- The system `owner` role IS the business owner's role: it must always hold
-- every permission in the catalogue (SPEC §67 role templates). If it ever ends
-- up with fewer grants, the whole shell collapses for that account — the
-- navigation hides every permission-gated module (dashboard, POS, catalogue,
-- reports) because the UI only offers what the backend would accept (§87).
--
-- Idempotent repair: safe to run repeatedly and on any environment that lost
-- the grants (a role editor save, a partial restore, ...).
-- migrate:up
-- =============================================================================
insert into public.role_permissions (role_id, permission_id)
select r.id, pm.id
from public.roles r
cross join public.permissions pm
where r.key = 'owner'
  and coalesce(r.is_system, false)
on conflict do nothing;

-- migrate:down
--   delete from public.role_permissions rp
--   using public.roles r
--   where rp.role_id = r.id and r.key = 'owner' and r.is_system;
--   (Deliberately destructive — do not run it: it reproduces the bug this
--    migration repairs.)
