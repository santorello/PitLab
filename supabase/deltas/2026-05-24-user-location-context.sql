-- User location context for localized Home, weather and nearby discovery.
-- Stores only the user's chosen home area, not live GPS traces.

alter table public.profiles
  add column if not exists home_city text,
  add column if not exists home_country text,
  add column if not exists home_latitude double precision,
  add column if not exists home_longitude double precision;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_home_latitude_range'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_home_latitude_range
      check (home_latitude is null or home_latitude between -90 and 90)
      not valid;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_home_longitude_range'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_home_longitude_range
      check (home_longitude is null or home_longitude between -180 and 180)
      not valid;
  end if;
end $$;

alter table public.profiles validate constraint profiles_home_latitude_range;
alter table public.profiles validate constraint profiles_home_longitude_range;

create index if not exists profiles_home_location_idx
  on public.profiles (home_country, home_city)
  where home_city is not null;

create or replace function public.complete_onboarding(
  p_preferred_city text default ''::text,
  p_user_interests text[] default '{}'::text[],
  p_home_city text default null::text,
  p_home_country text default null::text,
  p_home_latitude double precision default null::double precision,
  p_home_longitude double precision default null::double precision
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  update public.profiles
  set
    preferred_city = coalesce(nullif(trim(p_preferred_city), ''), preferred_city),
    home_city = coalesce(nullif(trim(p_home_city), ''), home_city),
    home_country = coalesce(nullif(trim(p_home_country), ''), home_country),
    home_latitude = coalesce(p_home_latitude, home_latitude),
    home_longitude = coalesce(p_home_longitude, home_longitude),
    user_interests = case
      when array_length(p_user_interests, 1) > 0 then p_user_interests
      else user_interests
    end,
    onboarding_completed = true,
    onboarding_completed_at = coalesce(onboarding_completed_at, now()),
    updated_at = now()
  where id = auth.uid();
end;
$$;

revoke execute on function public.complete_onboarding(
  text,
  text[],
  text,
  text,
  double precision,
  double precision
) from public, anon;

grant execute on function public.complete_onboarding(
  text,
  text[],
  text,
  text,
  double precision,
  double precision
) to authenticated, service_role;

comment on column public.profiles.home_city is
  'User-selected home city used for localized discovery.';
comment on column public.profiles.home_country is
  'User-selected home country used for localized discovery.';
comment on column public.profiles.home_latitude is
  'Latitude of the user-selected home area. Not live GPS.';
comment on column public.profiles.home_longitude is
  'Longitude of the user-selected home area. Not live GPS.';
