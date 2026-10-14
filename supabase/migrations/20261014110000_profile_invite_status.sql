-- =============================================================================
-- 122_profile_invite_status
--
-- Staff invites were indistinguishable from accepted members:
--   * profiles_status_chk only allowed ('active','suspended') while the Team
--     screen writes 'inactive' — so deactivating a member always failed with a
--     check-constraint violation;
--   * the staff-invite function marks the profile 'active' the moment the
--     invite is sent, so an invite nobody ever accepted still looked active.
--
-- This migration adds an 'invited' state, keeps it until the person accepts
-- the email (auth.users.email_confirmed_at) and backfills pending invites.
-- migrate:up
-- =============================================================================

alter table public.profiles drop constraint if exists profiles_status_chk;
alter table public.profiles
  add constraint profiles_status_chk
  check (status in ('active', 'suspended', 'inactive', 'invited'));

-- Flip 'invited' -> 'active' the moment the invite link is accepted.
create or replace function public.mark_profile_invited_active()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.profiles
     set status = 'active',
         updated_at = now()
   where auth_user_id = new.id
     and status = 'invited';
  return new;
end;
$$;

drop trigger if exists trg_profile_invite_accepted on auth.users;
create trigger trg_profile_invite_accepted
  after update on auth.users
  for each row
  when (old.email_confirmed_at is null
        and new.email_confirmed_at is not null)
  execute function public.mark_profile_invited_active();

-- Repair existing rows: an auth user still holding an unaccepted invite.
update public.profiles p
   set status = 'invited',
       updated_at = now()
  from auth.users u
 where u.id = p.auth_user_id
   and u.invited_at is not null
   and u.email_confirmed_at is null
   and p.status = 'active';

-- migrate:down
--   drop trigger if exists trg_profile_invite_accepted on auth.users;
--   drop function if exists public.mark_profile_invited_active();
--   update public.profiles set status = 'active' where status = 'invited';
--   alter table public.profiles drop constraint if exists profiles_status_chk;
--   alter table public.profiles add constraint profiles_status_chk
--     check (status in ('active','suspended'));
