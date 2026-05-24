create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to anon, authenticated, service_role;

create or replace function private.is_spot_owned_by_current_user(target_spot_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.spots s
      where s.id = target_spot_id
        and s.owner_id = auth.uid()
    );
$$;

revoke execute on function private.is_spot_owned_by_current_user(uuid) from public;
grant execute on function private.is_spot_owned_by_current_user(uuid)
to anon, authenticated, service_role;

create or replace view public.public_spots
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
  private.is_spot_owned_by_current_user(s.id) as is_owned_by_current_user
from public.spots s;

revoke all on public.public_spots from public;
revoke all on public.public_spots from anon;
revoke all on public.public_spots from authenticated;
revoke all on public.public_spots from service_role;
grant select on public.public_spots to anon, authenticated, service_role;

revoke all on public.spots from public, anon, authenticated;
grant select (
  id, slug, title, city, category, best_for, surface, note, image_accent,
  photo_count, address, latitude, longitude, image_urls, video_url,
  is_custom, created_at, updated_at
) on public.spots to anon, authenticated;
grant insert (
  slug, title, city, category, best_for, surface, note, image_accent,
  photo_count, address, latitude, longitude, image_urls, video_url,
  is_custom, owner_id
) on public.spots to authenticated;
grant update (
  title, city, category, best_for, surface, note, image_accent,
  photo_count, address, latitude, longitude, image_urls, video_url
) on public.spots to authenticated;
grant delete on public.spots to authenticated;

revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.is_track_manager(uuid) from public, anon;
revoke execute on function public.is_shop_manager(uuid) from public, anon;
grant execute on function public.is_admin() to authenticated, service_role;
grant execute on function public.is_track_manager(uuid) to authenticated, service_role;
grant execute on function public.is_shop_manager(uuid) to authenticated, service_role;

revoke insert, update, delete, truncate, references, trigger
on all tables in schema public
from anon;

revoke truncate, references, trigger
on all tables in schema public
from authenticated;
