-- Delta: 2026-05-24 - Build della settimana
-- Contratto:
--   - user_build_votes registra voti reali sulle build pubbliche.
--   - weekly_featured_builds congela una sola build per settimana ISO.
--   - private.refresh_current_build_of_week() seleziona la build con piu' voti
--     negli ultimi 7 giorni; a parita' o senza voti usa random().
--   - il premio PitCoin e' idempotente tramite award_pitcoin + source_id.

create schema if not exists private;
grant usage on schema private to service_role;

create table if not exists public.user_build_votes (
  id uuid primary key default gen_random_uuid(),
  build_id uuid not null references public.user_builds (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  value int not null default 1 check (value = 1),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (build_id, user_id)
);

create index if not exists user_build_votes_build_created_idx
  on public.user_build_votes (build_id, created_at desc);
create index if not exists user_build_votes_user_idx
  on public.user_build_votes (user_id, created_at desc);

drop trigger if exists user_build_votes_set_updated_at on public.user_build_votes;
create trigger user_build_votes_set_updated_at
  before update on public.user_build_votes
  for each row execute function public.set_updated_at();

alter table public.user_build_votes enable row level security;

drop policy if exists "user_build_votes: public reads" on public.user_build_votes;
create policy "user_build_votes: public reads"
  on public.user_build_votes for select
  using (true);

drop policy if exists "user_build_votes: authenticated votes" on public.user_build_votes;
create policy "user_build_votes: authenticated votes"
  on public.user_build_votes for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.user_builds b
      where b.id = build_id
        and b.is_public = true
        and b.owner_id is distinct from auth.uid()
    )
  );

drop policy if exists "user_build_votes: owner removes own vote" on public.user_build_votes;
create policy "user_build_votes: owner removes own vote"
  on public.user_build_votes for delete
  to authenticated
  using (auth.uid() = user_id);

create table if not exists public.weekly_featured_builds (
  id uuid primary key default gen_random_uuid(),
  week_start date not null unique,
  build_id uuid not null references public.user_builds (id) on delete cascade,
  owner_id uuid not null references public.profiles (id) on delete cascade,
  weekly_votes int not null default 0,
  awarded_points int not null default 75,
  selected_at timestamptz not null default timezone('utc', now()),
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists weekly_featured_builds_build_idx
  on public.weekly_featured_builds (build_id, selected_at desc);

alter table public.weekly_featured_builds enable row level security;

drop policy if exists "weekly_featured_builds: public reads" on public.weekly_featured_builds;
create policy "weekly_featured_builds: public reads"
  on public.weekly_featured_builds for select
  using (true);

insert into public.pitcoin_action_definitions (
  action_key, name_it, name_en, description_it, description_en,
  category, base_points, daily_cap, per_entity_cap, lifetime_cap,
  cooldown_seconds, requires_approval, enabled
)
values (
  'build_of_week',
  'Build della settimana',
  'Build of the week',
  'La tua build e'' stata scelta come build della settimana',
  'Your build was selected as build of the week',
  'garage',
  75,
  null,
  1,
  null,
  null,
  false,
  true
)
on conflict (action_key) do update
set name_it = excluded.name_it,
    name_en = excluded.name_en,
    description_it = excluded.description_it,
    description_en = excluded.description_en,
    category = excluded.category,
    base_points = excluded.base_points,
    per_entity_cap = excluded.per_entity_cap,
    enabled = excluded.enabled,
    updated_at = timezone('utc', now());

create or replace function private.refresh_current_build_of_week()
returns uuid
language plpgsql
security definer
set search_path = public, private, pg_catalog
as $$
declare
  v_week_start date := date_trunc('week', timezone('Europe/Rome', now()))::date;
  v_featured public.weekly_featured_builds%rowtype;
  v_candidate record;
begin
  select * into v_featured
  from public.weekly_featured_builds
  where week_start = v_week_start;

  if found then
    return v_featured.id;
  end if;

  select
    b.id as build_id,
    b.owner_id,
    b.title,
    coalesce(sum(v.value) filter (
      where v.created_at >= timezone('utc', now()) - interval '7 days'
    ), 0)::int as weekly_votes
  into v_candidate
  from public.user_builds b
  left join public.user_build_votes v on v.build_id = b.id
  where b.is_public = true
    and b.owner_id is not null
  group by b.id, b.owner_id, b.title
  order by weekly_votes desc, random()
  limit 1;

  if v_candidate.build_id is null then
    return null;
  end if;

  insert into public.weekly_featured_builds (
    week_start,
    build_id,
    owner_id,
    weekly_votes,
    awarded_points,
    metadata
  )
  values (
    v_week_start,
    v_candidate.build_id,
    v_candidate.owner_id,
    v_candidate.weekly_votes,
    75,
    jsonb_build_object('title', v_candidate.title)
  )
  returning * into v_featured;

  perform public.award_pitcoin(
    v_featured.owner_id,
    'build_of_week',
    'weekly_featured_builds',
    v_featured.id,
    jsonb_build_object(
      'build_id', v_featured.build_id,
      'week_start', v_featured.week_start,
      'weekly_votes', v_featured.weekly_votes
    )
  );

  return v_featured.id;
end;
$$;

revoke execute on function private.refresh_current_build_of_week() from public;
grant execute on function private.refresh_current_build_of_week() to service_role;

create or replace view public.home_build_of_week
with (security_invoker = true)
as
select
  b.id,
  b.owner_id,
  b.title,
  b.meta,
  b.image_urls,
  null::text as author_display_name,
  null::text as author_public_slug,
  coalesce(w.weekly_votes, 0) as weekly_votes,
  0::int as comment_count,
  coalesce(w.awarded_points, 0) as awarded_points,
  w.week_start,
  w.selected_at
from public.weekly_featured_builds w
join public.user_builds b on b.id = w.build_id
where b.is_public = true
order by w.week_start desc, w.selected_at desc
limit 1;

revoke all on public.home_build_of_week from public;
revoke all on public.home_build_of_week from anon;
revoke all on public.home_build_of_week from authenticated;
revoke all on public.home_build_of_week from service_role;
grant select on public.home_build_of_week to anon, authenticated, service_role;

-- Eseguire una volta dopo la migration, e poi schedulare settimanalmente:
-- select private.refresh_current_build_of_week();
