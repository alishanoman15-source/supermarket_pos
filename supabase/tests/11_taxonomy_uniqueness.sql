-- =============================================================================
-- 11_taxonomy_uniqueness.sql — pgTAP
-- Proves the per-business taxonomy indexes that back the product form's
-- type-and-create flow:
--   * categories_business_name_uq (business_id, lower(name)) where deleted_at is null
--   * brands_business_name_uq     (business_id, lower(name)) where deleted_at is null
--   * units_business_key_uq       (business_id, key)
--
-- Runs as a single transaction and rolls back, so it never leaves data
-- behind. Run with `supabase test db`, or against the linked project through
-- scripts/run_backend_tests.sh / `scripts/sql.sh < supabase/tests/...`.
-- =============================================================================

begin;

select no_plan();

-- ---------------------------------------------------------------------------
-- Fixture: one auth user (the trigger creates the profile), onboarded
-- through the real RPC — same pattern as suite 01.
-- ---------------------------------------------------------------------------
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values
  ('eeeeeeee-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'taxonomy-e@test.local',
   crypt('password', gen_salt('bf')), now(), now(), now(), '{}',
   '{"full_name":"Tax E"}');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"eeeeeeee-0000-0000-0000-000000000001"}', true);

select lives_ok(
  $$select public.create_business_with_owner(
      '{"name":"Taxonomy Biz","currency":"PKR"}', '{"name":"Main"}')$$,
  'owner can onboard');

-- ---------------------------------------------------------------------------
-- Categories: unique per business, case-insensitive.
-- ---------------------------------------------------------------------------
select lives_ok(
  $$insert into public.categories (business_id, name)
    select public.current_business_id(), 'Snacks'$$,
  'a category can be created');

select throws_ok(
  $$insert into public.categories (business_id, name)
    select public.current_business_id(), 'snacks'$$,
  '23505', null,
  'duplicate category name (any case) is rejected');

-- Soft-deleting frees the name: the product form archives instead of
-- deleting, so a re-create must not hit the index.
select lives_ok(
  $$update public.categories
       set status = 'inactive', deleted_at = now()
     where business_id = public.current_business_id()
       and lower(name) = 'snacks'$$,
  'the category can be archived');

select lives_ok(
  $$insert into public.categories (business_id, name)
    select public.current_business_id(), 'Snacks'$$,
  'the same name can be re-created after a soft delete');

-- ---------------------------------------------------------------------------
-- Brands: same rule.
-- ---------------------------------------------------------------------------
select lives_ok(
  $$insert into public.brands (business_id, name)
    select public.current_business_id(), 'PepsiCo'$$,
  'a brand can be created');

select throws_ok(
  $$insert into public.brands (business_id, name)
    select public.current_business_id(), 'pepsico'$$,
  '23505', null,
  'duplicate brand name (any case) is rejected');

-- ---------------------------------------------------------------------------
-- Units: the stable key derived from the typed name is unique per business.
-- ---------------------------------------------------------------------------
select lives_ok(
  $$insert into public.units (business_id, key, name, abbreviation)
    select public.current_business_id(), 'bottle', 'Bottle', 'btl'$$,
  'a business unit can be created');

select throws_ok(
  $$insert into public.units (business_id, key, name)
    select public.current_business_id(), 'bottle', 'Bottles'$$,
  '23505', null,
  'a duplicate unit key is rejected');

reset role;

select * from finish();
rollback;
