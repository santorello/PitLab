create or replace function public.get_track_follower_count(track_uuid uuid)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select count(*) from public.track_follows where track_id = track_uuid;
$$;

create or replace function public.get_shop_follower_count(shop_uuid uuid)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select count(*) from public.shop_follows where shop_id = shop_uuid;
$$;

grant execute on function public.get_track_follower_count(uuid) to anon, authenticated;
grant execute on function public.get_shop_follower_count(uuid)  to anon, authenticated;
