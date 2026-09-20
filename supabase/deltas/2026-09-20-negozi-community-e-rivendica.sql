-- 2026-09-20 — Negozi: schede "segnalate dalla community" + rivendica del titolare.
-- Specchio esatto di 2026-09-19-piste-community-e-rivendica.sql, per i negozi.
-- Una scheda community nasce con submitted_by NULL: i trigger legati a
-- submitted_by (auto-gestore, PitCoin) non scattano.
-- Idempotente. Sostituisce admin_dashboard() del delta 2026-09-19.

alter table public.shops
  add column if not exists is_community boolean not null default false;

create table if not exists public.shop_claims (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  message text,
  contact text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references public.profiles(id)
);
create unique index if not exists shop_claims_open_unique
  on public.shop_claims (shop_id, user_id) where status = 'pending';
create index if not exists shop_claims_shop_idx on public.shop_claims (shop_id);

alter table public.shop_claims enable row level security;
drop policy if exists "shop claims insert own" on public.shop_claims;
create policy "shop claims insert own" on public.shop_claims
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists "shop claims read own or admin" on public.shop_claims;
create policy "shop claims read own or admin" on public.shop_claims
  for select to authenticated using (user_id = (select auth.uid()) or public.is_admin());
drop policy if exists "shop claims admin manage" on public.shop_claims;
create policy "shop claims admin manage" on public.shop_claims
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

revoke all on public.shop_claims from anon, authenticated;
grant select, insert, update on public.shop_claims to authenticated;

create or replace function public.admin_shop_claims()
returns jsonb language sql stable security definer set search_path = public as $$
  select case when not public.is_admin() then '[]'::jsonb else coalesce(
    (select jsonb_agg(jsonb_build_object(
        'id', c.id, 'shop_id', c.shop_id, 'shop_name', s.name, 'shop_slug', s.slug,
        'user_id', c.user_id, 'user_name', coalesce(p.display_name, 'Utente'),
        'message', c.message, 'contact', c.contact, 'created_at', c.created_at)
      order by c.created_at)
     from shop_claims c
     join shops s on s.id = c.shop_id
     left join profiles p on p.id = c.user_id
     where c.status = 'pending'), '[]'::jsonb) end;
$$;

create or replace function public.admin_resolve_shop_claim(p_claim_id uuid, p_approve boolean)
returns void language plpgsql security definer set search_path = public as $$
declare v_shop uuid; v_user uuid;
begin
  if not public.is_admin() then raise exception 'Solo admin' using errcode = '42501'; end if;
  select shop_id, user_id into v_shop, v_user from shop_claims where id = p_claim_id and status = 'pending';
  if v_shop is null then return; end if;

  update shop_claims
     set status = case when p_approve then 'approved' else 'rejected' end,
         resolved_at = now(), resolved_by = auth.uid()
   where id = p_claim_id;

  if p_approve then
    insert into shop_managers (shop_id, user_id, granted_by)
    values (v_shop, v_user, auth.uid()) on conflict do nothing;
    update shops set is_community = false where id = v_shop;
    update profiles set role = 'shop_owner' where id = v_user and role = 'user';
  end if;
end $$;

create or replace function public.admin_create_community_shop(
  p_name text, p_city text, p_address text default null,
  p_latitude double precision default null, p_longitude double precision default null,
  p_website text default null, p_hours text default null,
  p_short_description text default null, p_map_url text default null,
  p_phone text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_slug text; v_id uuid;
begin
  if not public.is_admin() then raise exception 'Solo admin' using errcode = '42501'; end if;
  v_slug := regexp_replace(lower(trim(p_name) || '-' || trim(p_city)), '[^a-z0-9]+', '-', 'g');
  v_slug := trim(both '-' from v_slug);
  if exists (select 1 from shops where slug = v_slug) then
    v_slug := v_slug || '-' || substr(md5(random()::text), 1, 4);
  end if;

  insert into shops(slug, name, city, country, address, latitude, longitude,
                    website_url, hours, short_description, external_map_url, phone,
                    is_public, approval_status, is_community, submitted_by)
  values (v_slug, trim(p_name), trim(p_city), 'IT', nullif(trim(coalesce(p_address,'')),''),
          p_latitude, p_longitude, nullif(trim(coalesce(p_website,'')),''),
          nullif(trim(coalesce(p_hours,'')),''), nullif(trim(coalesce(p_short_description,'')),''),
          nullif(trim(coalesce(p_map_url,'')),''), nullif(trim(coalesce(p_phone,'')),''),
          true, 'approved', true, null)
  returning id into v_id;
  return v_id;
end $$;

revoke execute on function public.admin_shop_claims(),
                          public.admin_resolve_shop_claim(uuid, boolean),
                          public.admin_create_community_shop(text,text,text,double precision,double precision,text,text,text,text,text) from public, anon;
grant execute on function public.admin_shop_claims(),
                         public.admin_resolve_shop_claim(uuid, boolean),
                         public.admin_create_community_shop(text,text,text,double precision,double precision,text,text,text,text,text) to authenticated;

-- ── Dashboard: rivendicazioni negozi in coda e conteggio negozi community ──
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
      'shop_claims', (select count(*) from shop_claims where status = 'pending'),
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
      'shops', (select count(*) from shops where approval_status = 'approved'),
      'shops_community', (select count(*) from shops where approval_status = 'approved' and is_community),
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

-- Verifica (atteso: 1 colonna, 1 tabella, 3 funzioni)
select (select count(*) from information_schema.columns where table_name='shops' and column_name='is_community') as colonna,
       (select count(*) from information_schema.tables where table_name='shop_claims') as tabella,
       (select count(*) from pg_proc where proname in ('admin_shop_claims','admin_resolve_shop_claim','admin_create_community_shop')) as funzioni;
