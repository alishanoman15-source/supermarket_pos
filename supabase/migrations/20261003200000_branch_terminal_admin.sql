-- =============================================================================
-- 20261003200000_branch_terminal_admin.sql
-- Branch & POS terminal administration (SPEC §6 multi-branch, §86 screens 58–59).
--
-- `branches` already allowed create/update to holders of `branches.manage`, but
-- `pos_terminals` was SELECT-only: counters and terminals could only be added
-- with the service_role key, which must never live in a client (SPEC §56).
-- Grant INSERT/UPDATE on terminals to the same permission so the app can manage
-- them. Additive and idempotent; re-appliable.
-- ============================================================================

drop policy if exists pos_terminals_insert on public.pos_terminals;
create policy pos_terminals_insert on public.pos_terminals
  for insert to authenticated
  with check (business_id = public.current_business_id()
              and public.has_permission('branches.manage'));

drop policy if exists pos_terminals_update on public.pos_terminals;
create policy pos_terminals_update on public.pos_terminals
  for update to authenticated
  using (business_id = public.current_business_id()
         and public.has_permission('branches.manage'))
  with check (business_id = public.current_business_id());
