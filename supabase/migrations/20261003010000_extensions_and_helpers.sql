-- =============================================================================
-- 000_extensions_and_helpers
-- Extensions, shared helper functions and the updated_at trigger function.
-- Idempotent-safe (BACKEND_SETUP.md §2).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions (BACKEND_SETUP.md Part A5)
-- ---------------------------------------------------------------------------
create extension if not exists pgcrypto;   -- gen_random_uuid(), hashing
create extension if not exists pg_trgm;    -- fast partial product-name search
create extension if not exists pg_cron;    -- scheduled jobs (expiry / low stock)
create extension if not exists unaccent;   -- search normalisation

-- ---------------------------------------------------------------------------
-- Shared trigger function: keep updated_at fresh on every table that has it
-- (BACKEND_SETUP.md Part C).
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

comment on function public.set_updated_at() is
  'BEFORE UPDATE trigger: stamps updated_at = now(). Attached per table in 100_triggers.';

-- ---------------------------------------------------------------------------
-- migrate:down
--   drop function if exists public.set_updated_at();
--   -- extensions are intentionally NOT dropped (other objects may depend on them)
-- ---------------------------------------------------------------------------
