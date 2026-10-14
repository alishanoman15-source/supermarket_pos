-- =============================================================================
-- 140_cron_jobs
-- Scheduled jobs (SPEC §84, Part G2). Times are UTC; Pakistan is UTC+5.
--   * expiry alerts          — daily 03:00 UTC (08:00 PKT)
--   * stale imports cleanup  — daily 04:00 UTC
--   * notifications pruning  — weekly, Sunday 05:00 UTC
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Expiry scan: EXPIRING_SOON (within 30 days) and EXPIRED notifications.
-- ---------------------------------------------------------------------------
create or replace function public.job_expiry_alerts()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_batch record;
  v_type text;
  v_title text;
begin
  for v_batch in
    select b.id, b.business_id, b.branch_id, b.batch_no, b.expiry_date, b.qty,
           p.name as product_name
      from public.product_batches b
      join public.products p on p.id = b.product_id
     where b.qty > 0
       and b.expiry_date is not null
       and b.expiry_date <= (now() + interval '30 days')::date
  loop
    if v_batch.expiry_date < current_date then
      v_type := 'EXPIRED';
      v_title := v_batch.product_name || ' batch ' || v_batch.batch_no || ' has expired';
    else
      v_type := 'EXPIRING_SOON';
      v_title := v_batch.product_name || ' batch ' || v_batch.batch_no || ' expires soon';
    end if;

    -- one unread alert per batch
    if exists (
      select 1 from public.notifications n
       where n.business_id = v_batch.business_id
         and n.type = v_type
         and n.is_read = false
         and (n.data ->> 'batch_id') = v_batch.id::text
    ) then
      continue;
    end if;

    insert into public.notifications (business_id, branch_id, user_id, type, title, body, data)
    select v_batch.business_id, v_batch.branch_id, pr.id, v_type, v_title,
           format('Batch %s · qty %s · expiry %s',
                  v_batch.batch_no, v_batch.qty, v_batch.expiry_date),
           jsonb_build_object('batch_id', v_batch.id, 'product_id', v_batch.product_id,
                              'expiry_date', v_batch.expiry_date)
      from public.profiles pr
     where pr.business_id = v_batch.business_id
       and pr.status = 'active'
       and pr.role_id in (
         select r.id from public.roles r
          join public.role_permissions rp on rp.role_id = r.id
          join public.permissions pm on pm.id = rp.permission_id
         where pm.key = 'inventory.view'
       );
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Cleanup helpers
-- ---------------------------------------------------------------------------
create or replace function public.job_cleanup_imports()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  delete from public.imports
   where status in ('failed','completed')
     and created_at < now() - interval '30 days';
end;
$$;

create or replace function public.job_prune_notifications()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  delete from public.notifications
   where is_read = true
     and created_at < now() - interval '90 days';
end;
$$;

-- ---------------------------------------------------------------------------
-- Schedule (idempotent: unschedule then schedule)
-- ---------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from cron.job where jobname = 'expiry-alerts-daily') then
    perform cron.unschedule('expiry-alerts-daily');
  end if;
  perform cron.schedule('expiry-alerts-daily', '0 3 * * *',
                        $cron$ select public.job_expiry_alerts(); $cron$);

  if exists (select 1 from cron.job where jobname = 'cleanup-imports-daily') then
    perform cron.unschedule('cleanup-imports-daily');
  end if;
  perform cron.schedule('cleanup-imports-daily', '0 4 * * *',
                        $cron$ select public.job_cleanup_imports(); $cron$);

  if exists (select 1 from cron.job where jobname = 'prune-notifications-weekly') then
    perform cron.unschedule('prune-notifications-weekly');
  end if;
  perform cron.schedule('prune-notifications-weekly', '0 5 * * 0',
                        $cron$ select public.job_prune_notifications(); $cron$);
exception
  when undefined_table then
    raise notice 'pg_cron is not available; scheduled jobs were skipped';
end $$;

-- ---------------------------------------------------------------------------
-- Realtime (SPEC §63): notifications + stock_movements only
-- ---------------------------------------------------------------------------
do $$
begin
  begin
    alter publication supabase_realtime add table public.notifications;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.stock_movements;
  exception when duplicate_object then null;
  end;
exception
  when undefined_object then
    raise notice 'supabase_realtime publication not found; skipped';
end $$;

-- ---------------------------------------------------------------------------
-- migrate:down
--   select cron.unschedule('expiry-alerts-daily');
--   select cron.unschedule('cleanup-imports-daily');
--   select cron.unschedule('prune-notifications-weekly');
--   drop function if exists public.job_prune_notifications();
--   drop function if exists public.job_cleanup_imports();
--   drop function if exists public.job_expiry_alerts();
-- ---------------------------------------------------------------------------