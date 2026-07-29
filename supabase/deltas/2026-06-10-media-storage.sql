-- ============================================================================
-- PitLap — Supabase Storage per media upload system (2026-06-10)
-- Bucket pubblico `media` + policy owner-based su storage.objects.
-- Convenzione path: <user_id>/<entity_type>/<filename>
--   es. 42bb15da-.../tracks/cover-1718000000.webp
-- Limite 5MB, solo immagini (jpeg/png/webp/gif).
-- Applicato su dev (migration media_storage_bucket_and_policies).
-- Da applicare su prod insieme agli altri delta del 2026-06-10.
-- Idempotente.
-- ============================================================================

begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('media', 'media', true, 5242880, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- NOTA: nessuna policy SELECT volutamente — il bucket e' public e le object URL
-- funzionano senza; una SELECT broad permetterebbe il listing di tutti i file
-- (advisor: public_bucket_allows_listing).
drop policy if exists "media public read" on storage.objects;

drop policy if exists "media owner insert" on storage.objects;
create policy "media owner insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "media owner update" on storage.objects;
create policy "media owner update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'media'
    and ((storage.foldername(name))[1] = (select auth.uid())::text or is_admin())
  )
  with check (
    bucket_id = 'media'
    and ((storage.foldername(name))[1] = (select auth.uid())::text or is_admin())
  );

drop policy if exists "media owner delete" on storage.objects;
create policy "media owner delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'media'
    and ((storage.foldername(name))[1] = (select auth.uid())::text or is_admin())
  );

commit;
