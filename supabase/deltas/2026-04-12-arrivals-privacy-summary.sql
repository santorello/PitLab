drop policy if exists "users can read arrivals for public tracks"
on public.arrivals;

create or replace function public.get_public_track_arrival_summary(
  track_uuid uuid,
  target_date date default current_date
)
returns table (
  coming_count bigint,
  maybe_count bigint,
  cancelled_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    count(*) filter (where arrivals.status = 'coming') as coming_count,
    count(*) filter (where arrivals.status = 'maybe') as maybe_count,
    count(*) filter (where arrivals.status = 'cancelled') as cancelled_count
  from public.arrivals
  where arrivals.track_id = track_uuid
    and arrivals.arrival_date = target_date
    and exists (
      select 1
      from public.tracks
      where tracks.id = track_uuid
        and tracks.is_public = true
    );
$$;

grant execute on function public.get_public_track_arrival_summary(uuid, date)
to anon, authenticated;
