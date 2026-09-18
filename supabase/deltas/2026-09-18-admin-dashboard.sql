-- 2026-09-18 — Control room admin: un'unica funzione con tutti i numeri della dashboard.
-- Prima erano ~12 query separate dal client. Solo admin. Idempotente.
create or replace function public.admin_dashboard()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case when not public.is_admin() then jsonb_build_object('error', 'forbidden') else jsonb_build_object(
    'generated_at', now(),

    'todo', jsonb_build_object(
      'pending_tracks', (select count(*) from tracks where approval_status = 'pending'),
      'pending_shops',  (select count(*) from shops  where approval_status = 'pending'),
      'oldest_pending_days', (
        select coalesce(max(extract(day from now() - created_at))::int, 0)
        from (select created_at from tracks where approval_status = 'pending'
              union all select created_at from shops where approval_status = 'pending') p),
      'reported_comments', (select count(*) from entity_comments where reported_count > 0 and not is_hidden),
      'feedback', (select count(*) from feedback),
      'deletion_requests', (select count(*) from profiles where deletion_requested_at is not null),
      'deletion_oldest_days', (
        select coalesce(max(extract(day from now() - deletion_requested_at))::int, 0)
        from profiles where deletion_requested_at is not null),
      'content_to_fix', (
        (select count(*) from spots where latitude is null or longitude is null)
      + (select count(*) from spots where coalesce(array_length(image_urls, 1), 0) = 0)
      + (select count(*) from community_events
         where coalesce(ends_at, starts_at) < now() - interval '7 days'))
    ),

    'health', jsonb_build_object(
      'keepalive_at', (select max(checked_at) from keepalive),
      'last_signup_at', (select max(created_at) from profiles),
      -- "silenzio": ultimo contenuto pubblicato da chiunque (l'app esclude poi l'admin corrente)
      'last_content_at', (
        select max(t) from (
          select max(created_at) t from spots
          union all select max(created_at) from community_events
          union all select max(created_at) from user_builds
          union all select max(created_at) from entity_comments) c),
      'consents_current', (
        select count(distinct user_id) from user_consents
        where accepted and document_version = '1.2'),
      'email_sender_is_default', true
    ),

    'counts', jsonb_build_object(
      'users', (select count(*) from profiles),
      'users_7d', (select count(*) from profiles where created_at >= now() - interval '7 days'),
      'users_prev_7d', (select count(*) from profiles
                        where created_at >= now() - interval '14 days'
                          and created_at <  now() - interval '7 days'),
      'onboarding_done', (select count(*) from profiles where onboarding_completed),
      'tracks', (select count(*) from tracks where approval_status = 'approved'),
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

    -- Serie per il grafico: una riga per giorno, zeri compresi.
    'signups_30d', (
      select coalesce(jsonb_agg(jsonb_build_object('d', d::date, 'n', n) order by d), '[]'::jsonb)
      from (
        select g.d, (select count(*) from profiles p
                     where p.created_at >= g.d and p.created_at < g.d + interval '1 day') n
        from generate_series(date_trunc('day', now()) - interval '29 days',
                             date_trunc('day', now()), interval '1 day') g(d)
      ) s
    )
  ) end;
$$;

revoke execute on function public.admin_dashboard() from public, anon;
grant execute on function public.admin_dashboard() to authenticated;

-- Verifica (da admin: oggetto pieno; da utente normale: {"error":"forbidden"})
select jsonb_pretty(public.admin_dashboard());
