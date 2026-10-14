-- =============================================================================
-- 130_storage
-- Private buckets + business-scoped storage policies (SPEC §64, Part G4).
-- Object path convention: {business_id}/{entity}/{file}
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('product-images', 'product-images', false, 2097152,
    array['image/png','image/jpeg','image/webp','image/gif']),
  ('business-assets', 'business-assets', false, 5242880,
    array['image/png','image/jpeg','image/webp','image/svg+xml','application/pdf']),
  ('receipts', 'receipts', false, 5242880,
    array['application/pdf','image/png','image/jpeg','text/plain']),
  ('imports', 'imports', false, 10485760,
    array['text/csv','application/vnd.ms-excel',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- product-images / business-assets: read + write for members of the business
-- ---------------------------------------------------------------------------
drop policy if exists product_images_select on storage.objects;
create policy product_images_select on storage.objects
  for select to authenticated
  using (
    bucket_id in ('product-images','business-assets')
    and (storage.foldername(name))[1] = public.current_business_id()::text
  );

drop policy if exists product_images_insert on storage.objects;
create policy product_images_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id in ('product-images','business-assets')
    and (storage.foldername(name))[1] = public.current_business_id()::text
    and public.has_permission('products.update')
  );

drop policy if exists product_images_update on storage.objects;
create policy product_images_update on storage.objects
  for update to authenticated
  using (
    bucket_id in ('product-images','business-assets')
    and (storage.foldername(name))[1] = public.current_business_id()::text
    and public.has_permission('products.update')
  )
  with check (
    bucket_id in ('product-images','business-assets')
    and (storage.foldername(name))[1] = public.current_business_id()::text
  );

drop policy if exists product_images_delete on storage.objects;
create policy product_images_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id in ('product-images','business-assets')
    and (storage.foldername(name))[1] = public.current_business_id()::text
    and public.has_permission('products.update')
  );

-- ---------------------------------------------------------------------------
-- receipts: owner/manager read, any POS user may write their own receipt
-- ---------------------------------------------------------------------------
drop policy if exists receipts_select on storage.objects;
create policy receipts_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = public.current_business_id()::text
    and (public.has_permission('sales.view_all') or public.has_permission('sales.view'))
  );

drop policy if exists receipts_insert on storage.objects;
create policy receipts_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = public.current_business_id()::text
    and public.has_permission('pos.sell')
  );

-- ---------------------------------------------------------------------------
-- imports: read for data.import holders; writes come from the Edge Function
-- (service role bypasses RLS) so no client insert policy is granted.
-- ---------------------------------------------------------------------------
drop policy if exists imports_select on storage.objects;
create policy imports_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'imports'
    and (storage.foldername(name))[1] = public.current_business_id()::text
    and public.has_permission('data.import')
  );

-- ---------------------------------------------------------------------------
-- migrate:down
--   drop policy if exists imports_select on storage.objects;
--   drop policy if exists receipts_insert on storage.objects;
--   drop policy if exists receipts_select on storage.objects;
--   drop policy if exists product_images_delete on storage.objects;
--   drop policy if exists product_images_update on storage.objects;
--   drop policy if exists product_images_insert on storage.objects;
--   drop policy if exists product_images_select on storage.objects;
--   delete from storage.buckets where id in
--     ('product-images','business-assets','receipts','imports');
-- ---------------------------------------------------------------------------