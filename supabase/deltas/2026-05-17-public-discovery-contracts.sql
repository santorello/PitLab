-- Delta: 2026-05-17 - Public discovery contracts
-- Obiettivo:
-- - mantenere ampia la discovery pubblica
-- - evitare leak di metadati sensibili non necessari ai client guest
-- - allineare alcune policy pubbliche al requisito "solo entita' pubbliche e approvate"

drop view if exists public.public_spots;

create view public.public_spots
with (security_invoker = true)
as
select
  s.id,
  s.slug,
  s.title,
  s.city,
  s.category,
  s.best_for,
  s.surface,
  s.note,
  s.image_accent,
  s.photo_count,
  s.address,
  s.latitude,
  s.longitude,
  s.image_urls,
  s.video_url,
  s.is_custom,
  s.created_at,
  (auth.uid() is not null and s.owner_id = auth.uid()) as is_owned_by_current_user
from public.spots s;

revoke all on public.public_spots from public;
revoke all on public.public_spots from anon;
revoke all on public.public_spots from authenticated;
grant select on public.public_spots to anon, authenticated;

drop policy if exists "public can read current track status" on public.track_status_current;
create policy "public can read current track status"
on public.track_status_current
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.tracks
    where tracks.id = track_status_current.track_id
      and tracks.is_public = true
      and tracks.approval_status = 'approved'
  )
);

drop policy if exists "public can read track status history" on public.track_status_history;
create policy "public can read track status history"
on public.track_status_history
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.tracks
    where tracks.id = track_status_history.track_id
      and tracks.is_public = true
      and tracks.approval_status = 'approved'
  )
);

drop policy if exists "public can read public events" on public.events;
create policy "public can read public events"
on public.events
for select
to anon, authenticated
using (
  visibility = 'public'
  and exists (
    select 1
    from public.tracks
    where tracks.id = events.track_id
      and tracks.is_public = true
      and tracks.approval_status = 'approved'
  )
);

revoke execute on function public.auto_link_shop_manager_on_insert() from public, anon, authenticated;
revoke execute on function public.auto_link_track_manager_on_approval() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
