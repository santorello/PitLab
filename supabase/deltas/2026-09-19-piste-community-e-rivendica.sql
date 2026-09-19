-- 2026-09-19 — Piste: schede "segnalate dalla community" + rivendica del gestore.
-- Scelta di prodotto: la scheda nasce senza proprietario (come fanno Google/Yelp),
-- il gestore se la prende e solo allora ottiene "Gestita dal titolare".
-- Una scheda community si crea con submitted_by NULL: così i trigger esistenti
-- (auto-gestore e PitCoin, entrambi legati a submitted_by) NON scattano.
-- Idempotente. Sostituisce admin_dashboard() del delta 2026-09-19-admin-fase2.

alter table public.tracks
  add column if not exists website_url text,
  add column if not exists hours text,
  add column if not exists is_community boolean not null default false;

create table if not exists public.track_claims (
  id uuid primary key default gen_random_uuid(),
  track_id uuid not null references public.tracks(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  message text,
  contact text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references public.profiles(id)
);
create unique index if not exists track_claims_open_unique
  on public.track_claims (track_id, user_id) where status = 'pending';
create index if not exists track_claims_track_idx on public.track_claims (track_id);

alter table public.track_claims enable row level security;
drop policy if exists "track claims insert own" on public.track_claims;
create policy "track claims insert own" on public.track_claims
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists "track claims read own or admin" on public.track_claims;
create policy "track claims read own or admin" on public.track_claims
  for select to authenticated using (user_id = (select auth.uid()) or public.is_admin());
drop policy if exists "track claims admin manage" on public.track_claims;
create policy "track claims admin manage" on public.track_claims
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

revoke all on public.track_claims from anon, authenticated;
grant select, insert, update on public.track_claims to authenticated;

create or replace function public.admin_track_claims()
returns jsonb language sql stable security definer set search_path = public as $$
  select case when not public.is_admin() then '[]'::jsonb else coalesce(
    (select jsonb_agg(jsonb_build_object(
        'id', c.id, 'track_id', c.track_id, 'track_name', t.name, 'track_slug', t.slug,
        'user_id', c.user_id, 'user_name', coalesce(p.display_name, 'Utente'),
        'message', c.message, 'contact', c.contact, 'created_at', c.created_at)
      order by c.created_at)
     from track_claims c
     join tracks t on t.id = c.track_id
     left join profiles p on p.id = c.user_id
     where c.status = 'pending'), '[]'::jsonb) end;
$$;

create or replace function public.admin_resolve_track_claim(p_claim_id uuid, p_approve boolean)
returns void language plpgsql security definer set search_path = public as $$
declare v_track uuid; v_user uuid;
begin
  if not public.is_admin() then raise exception 'Solo admin' using errcode = '42501'; end if;
  select track_id, user_id into v_track, v_user from track_claims where id = p_claim_id and status = 'pending';
  if v_track is null then return; end if;

  update track_claims
     set status = case when p_approve then 'approved' else 'rejected' end,
         resolved_at = now(), resolved_by = auth.uid()
   where id = p_claim_id;

  if p_approve then
    insert into track_managers (track_id, user_id, granted_by)
    values (v_track, v_user, auth.uid()) on conflict do nothing;
    update tracks set is_community = false where id = v_track;
    update profiles set role = 'track_organizer' where id = v_user and role = 'user';
  end if;
end $$;

revoke execute on function public.admin_track_claims(),
                          public.admin_resolve_track_claim(uuid, boolean) from public, anon;
grant execute on function public.admin_track_claims(),
                         public.admin_resolve_track_claim(uuid, boolean) to authenticated;
-- ── Dashboard: aggiunge le rivendicazioni in coda e le piste community ──────
create or replace function public.admin_dashboard()
returns jsonb language sql stable security definer set search_path = public as $$
  select case when not public.is_admin() then jsonb_build_object('error', 'forbidden') else jsonb_build_object(
    'generated_at', now(),
    'todo', jsonb_build_object(
      'pending_tracks', (select count(*) from tracks where approval_status = 'pending'),
      'pending_shops',  (select count(*) from shops  where approval_status = 'pending'),
      'oldest_pending_days', (
        select coalesce(max(extract(day from now() - created_at))::int, 0)
        from (select created_at from tracks where approval_status = 'pending'
              union all select created_at from shops where approval_status = 'pending') p),
      'track_claims', (select count(*) from track_claims where status = 'pending'),
      'reported_comments', (select count(*) from entity_comments
                            where reported_count > 0 and not is_hidden and reports_cleared_at is null),
      'feedback', (select count(*) from feedback where handled_at is null),
      'deletion_requests', (select count(*) from profiles
                            where deletion_requested_at is not null and deletion_handled_at is null),
      'deletion_oldest_days', (
        select coalesce(max(extract(day from now() - deletion_requested_at))::int, 0)
        from profiles where deletion_requested_at is not null and deletion_handled_at is null),
      'content_to_fix', (
        (select count(*) from spots where latitude is null or longitude is null)
      + (select count(*) from spots where coalesce(array_length(image_urls, 1), 0) = 0)
      + (select count(*) from community_events where coalesce(ends_at, starts_at) < now() - interval '7 days'))
    ),
    'health', jsonb_build_object(
      'keepalive_at', (select max(checked_at) from keepalive),
      'last_signup_at', (select max(created_at) from profiles),
      'last_content_at', (
        select max(t) from (
          select max(created_at) t from spots
          union all select max(created_at) from community_events
          union all select max(created_at) from user_builds
          union all select max(created_at) from entity_comments) c),
      'consents_current', (select count(distinct user_id) from user_consents where accepted and document_version = '1.2'),
      'email_sender_is_default', true
    ),
    'counts', jsonb_build_object(
      'users', (select count(*) from profiles),
      'users_7d', (select count(*) from profiles where created_at >= now() - interval '7 days'),
      'users_prev_7d', (select count(*) from profiles where created_at >= now() - interval '14 days' and created_at < now() - interval '7 days'),
      'onboarding_done', (select count(*) from profiles where onboarding_completed),
      'tracks', (select count(*) from tracks where approval_status = 'approved'),
      'tracks_community', (select count(*) from tracks where approval_status = 'approved' and is_community),
      'tracks_open', (select count(*) from track_status_current where status = 'open'),
      'spots', (select count(*) from spots),
      'events_future', (
        (select count(*) from community_events where coalesce(ends_at, starts_at) >= now())
      + (select count(*) from events where visibility = 'public' and coalesce(end_at, start_at) >= now()))
    ),
    'created_7d', jsonb_build_object(
      'spots',    (select count(*) from spots            where created_at >= now() - interval '7 days'),
      'events',   (select count(*) from community_events where created_at >= now() - interval '7 days'),
      'builds',   (select count(*) from user_builds      where created_at >= now() - interval '7 days'),
      'comments', (select count(*) from entity_comments  where created_at >= now() - interval '7 days')
    ),
    'signups_30d', (
      select coalesce(jsonb_agg(jsonb_build_object('d', d::date, 'n', n) order by d), '[]'::jsonb)
      from (
        select g.d, (select count(*) from profiles p where p.created_at >= g.d and p.created_at < g.d + interval '1 day') n
        from generate_series(date_trunc('day', now()) - interval '29 days', date_trunc('day', now()), interval '1 day') g(d)
      ) s
    )
  ) end;
$$;

-- Verifica (atteso: 3 colonne, tabella presente, 2 funzioni)
select (select count(*) from information_schema.columns where table_name='tracks'
          and column_name in ('website_url','hours','is_community')) as colonne,
       (select count(*) from information_schema.tables where table_name='track_claims') as tabella,
       (select count(*) from pg_proc where proname in ('admin_track_claims','admin_resolve_track_claim')) as funzioni;
