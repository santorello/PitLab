-- Home dashboard read contracts.
-- Centralizza gli aggregati usati dalla home: nessun numero calcolato nella UI.

create or replace view public.home_overview_stats
with (security_invoker = true)
as
select
  1 as id,
  (
    select count(*)
    from public.tracks t
    join public.track_status_current s on s.track_id = t.id
    where t.is_public = true
      and t.approval_status = 'approved'::public.approval_status
      and s.status = 'open'::public.track_status_kind
  )::integer as open_tracks,
  (
    select count(*)
    from public.events e
    join public.tracks t on t.id = e.track_id
    where t.is_public = true
      and t.approval_status = 'approved'::public.approval_status
      and e.visibility = 'public'::public.event_visibility
      and e.start_at >= timezone('utc', now())
      and e.start_at < timezone('utc', now()) + interval '30 days'
  )::integer as events_next_30_days,
  (
    select count(*)
    from public.public_spots s
    where s.created_at >= timezone('utc', now()) - interval '30 days'
  )::integer as new_spots_30_days,
  (
    select count(*)
    from public.shops sh
    where sh.is_public = true
      and sh.approval_status = 'approved'::public.approval_status
  )::integer as public_shops,
  (
    select count(*)
    from public.shops sh
    where sh.is_public = true
      and sh.approval_status = 'approved'::public.approval_status
      and sh.latitude is not null
      and sh.longitude is not null
  )::integer as geocoded_shops,
  (
    select count(*)
    from public.user_builds b
    where b.is_public = true
  )::integer as public_builds;

revoke all on public.home_overview_stats from public;
grant select on public.home_overview_stats to anon, authenticated, service_role;


create or replace view public.home_trending_tracks
with (security_invoker = true)
as
with events_30d as (
  select
    e.track_id,
    count(*)::integer as events_30d
  from public.events e
  where e.visibility = 'public'::public.event_visibility
    and e.start_at >= timezone('utc', now())
    and e.start_at < timezone('utc', now()) + interval '30 days'
  group by e.track_id
),
updates_14d as (
  select
    h.track_id,
    count(*)::integer as updates_14d
  from public.track_status_history h
  where h.updated_at >= timezone('utc', now()) - interval '14 days'
  group by h.track_id
)
select
  t.id,
  t.slug,
  t.name,
  t.city,
  t.short_description,
  coalesce(s.status::text, 'unknown') as status,
  coalesce(arrivals.arrivals_today, 0) as arrivals_today,
  coalesce(e.events_30d, 0) as events_30d,
  public.get_track_follower_count(t.id)::integer as followers_count,
  coalesce(u.updates_14d, 0) as updates_14d,
  (
    case coalesce(s.status::text, 'unknown')
      when 'open' then 30
      when 'wet' then 10
      else 0
    end
    + coalesce(arrivals.arrivals_today, 0) * 5
    + coalesce(e.events_30d, 0) * 4
    + public.get_track_follower_count(t.id)::integer
    + coalesce(u.updates_14d, 0) * 2
  )::integer as trend_score
from public.tracks t
left join public.track_status_current s on s.track_id = t.id
left join events_30d e on e.track_id = t.id
left join updates_14d u on u.track_id = t.id
left join lateral (
  select (summary.coming_count + summary.maybe_count)::integer as arrivals_today
  from public.get_public_track_arrival_summary(
    t.id,
    timezone('Europe/Rome', now())::date
  ) summary
) arrivals on true
where t.is_public = true
  and t.approval_status = 'approved'::public.approval_status;

revoke all on public.home_trending_tracks from public;
grant select on public.home_trending_tracks to anon, authenticated, service_role;


create or replace view public.home_featured_track
with (security_invoker = true)
as
select *
from public.home_trending_tracks
order by trend_score desc, name asc
limit 1;

revoke all on public.home_featured_track from public;
grant select on public.home_featured_track to anon, authenticated, service_role;


create or replace view public.pitcoin_public_leaderboard
with (security_invoker = true)
as
select
  dense_rank() over (
    order by p.total_points desc, lower(coalesce(p.display_name, p.public_slug)) asc
  )::integer as rank,
  p.user_id,
  p.public_slug,
  p.display_name,
  p.avatar_url,
  p.total_points,
  p.lifetime_earned,
  p.last_action_at
from public.public_user_pitcoin p
order by p.total_points desc, lower(coalesce(p.display_name, p.public_slug)) asc;

revoke all on public.pitcoin_public_leaderboard from public;
grant select on public.pitcoin_public_leaderboard to anon, authenticated, service_role;


create or replace function public.get_my_pitcoin_streak()
returns integer
language plpgsql
stable
set search_path = public, pg_catalog
as $$
declare
  v_user_id uuid := auth.uid();
  v_cursor date;
  v_streak integer := 0;
begin
  if v_user_id is null then
    return 0;
  end if;

  if exists (
    select 1
    from public.pitcoin_transactions pt
    where pt.user_id = v_user_id
      and timezone('Europe/Rome', pt.awarded_at)::date = timezone('Europe/Rome', now())::date
  ) then
    v_cursor := timezone('Europe/Rome', now())::date;
  elsif exists (
    select 1
    from public.pitcoin_transactions pt
    where pt.user_id = v_user_id
      and timezone('Europe/Rome', pt.awarded_at)::date = timezone('Europe/Rome', now())::date - 1
  ) then
    v_cursor := timezone('Europe/Rome', now())::date - 1;
  else
    return 0;
  end if;

  loop
    exit when not exists (
      select 1
      from public.pitcoin_transactions pt
      where pt.user_id = v_user_id
        and timezone('Europe/Rome', pt.awarded_at)::date = v_cursor
    );

    v_streak := v_streak + 1;
    v_cursor := v_cursor - 1;
  end loop;

  return v_streak;
end;
$$;

revoke execute on function public.get_my_pitcoin_streak() from public, anon;
grant execute on function public.get_my_pitcoin_streak() to authenticated, service_role;
