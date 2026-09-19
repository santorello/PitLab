-- 2026-09-19 — Control room fase 2: "segnato come gestito" + fix contatore segnalazioni.
-- Senza queste colonne feedback, segnalazioni e richieste di cancellazione restavano
-- contati per sempre. Scritture solo via RPC riservate all'admin. Idempotente.
-- Sostituisce admin_dashboard() del delta 2026-09-18.

alter table public.feedback
  add column if not exists handled_at timestamptz,
  add column if not exists handled_by uuid references public.profiles(id);

-- Segnalazione "respinta": il commento resta, ma non conta più fra le cose da fare.
alter table public.entity_comments
  add column if not exists reports_cleared_at timestamptz;

alter table public.profiles
  add column if not exists deletion_handled_at timestamptz;
grant select (deletion_handled_at) on public.profiles to authenticated;

-- ── FIX: il contatore delle segnalazioni tornava sempre a zero ───────────────
-- guard_comment_moderation_columns ripristinava reported_count per chiunque non
-- fosse admin, quindi anche per report_comment() (che gira con l'identità di chi
-- segnala): nessuna segnalazione arrivava mai in coda. Ora il contatore può
-- cambiare solo se corrisponde alle segnalazioni davvero registrate.
create or replace function public.guard_comment_moderation_columns()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    new.is_hidden := old.is_hidden;
    new.hidden_reason := old.hidden_reason;
    new.hidden_by := old.hidden_by;
    new.author_id := old.author_id;
    new.reports_cleared_at := old.reports_cleared_at;
    if new.reported_count is distinct from (
         select count(*) from public.entity_comment_reports r where r.comment_id = new.id) then
      new.reported_count := old.reported_count;
    end if;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

-- ── Azioni admin ─────────────────────────────────────────────────────────────

create or replace function public.admin_mark_feedback_handled(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Solo admin' using errcode = '42501'; end if;
  update public.feedback set handled_at = now(), handled_by = auth.uid() where id = p_id;
end $$;

create or replace function public.admin_resolve_comment_report(p_comment_id uuid, p_hide boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Solo admin' using errcode = '42501'; end if;
  update public.entity_comments
     set reports_cleared_at = now(),
         is_hidden = case when p_hide then true else is_hidden end,
         hidden_reason = case when p_hide then 'Nascosto dall''admin dopo segnalazione' else hidden_reason end,
         hidden_by = case when p_hide then auth.uid() else hidden_by end
   where id = p_comment_id;
end $$;

create or replace function public.admin_mark_deletion_handled(p_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Solo admin' using errcode = '42501'; end if;
  update public.profiles set deletion_handled_at = now() where id = p_user_id;
end $$;

create or replace function public.admin_reported_comments()
returns jsonb language sql stable security definer set search_path = public as $$
  select case when not public.is_admin() then '[]'::jsonb else coalesce(
    (select jsonb_agg(jsonb_build_object(
       'id', c.id, 'body', c.body, 'entity_type', c.entity_type,
       'reported_count', c.reported_count, 'created_at', c.created_at,
       'author', coalesce(p.display_name, 'Utente'),
       'reasons', (select coalesce(jsonb_agg(distinct r.reason), '[]'::jsonb)
                   from entity_comment_reports r where r.comment_id = c.id))
       order by c.reported_count desc, c.created_at desc)
     from entity_comments c
     left join profiles p on p.id = c.author_id
     where c.reported_count > 0 and not c.is_hidden and c.reports_cleared_at is null),
    '[]'::jsonb) end;
$$;

revoke execute on function public.admin_mark_feedback_handled(uuid),
                          public.admin_resolve_comment_report(uuid, boolean),
                          public.admin_mark_deletion_handled(uuid),
                          public.admin_reported_comments() from public, anon;
grant execute on function public.admin_mark_feedback_handled(uuid),
                         public.admin_resolve_comment_report(uuid, boolean),
                         public.admin_mark_deletion_handled(uuid),
                         public.admin_reported_comments() to authenticated;

-- ── Dashboard: conta solo ciò che non è ancora gestito ───────────────────────
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

-- L'elenco richieste cancellazione salta quelle già gestite.
create or replace function public.admin_pending_account_deletions()
returns table(user_id uuid, display_name text, requested_at timestamptz, giorni_trascorsi integer)
language sql security definer set search_path to 'public' as $function$
  select p.id,
         coalesce(nullif(trim(p.display_name), ''), 'Senza nome'),
         p.deletion_requested_at,
         extract(day from (now() - p.deletion_requested_at))::integer
  from public.profiles p
  where p.deletion_requested_at is not null
    and p.deletion_handled_at is null
    and public.is_admin()
  order by p.deletion_requested_at;
$function$;

-- Verifica (atteso: 3 colonne nuove + 4 funzioni)
select
  (select count(*) from information_schema.columns
    where table_schema='public'
      and (table_name, column_name) in (('feedback','handled_at'),
                                        ('entity_comments','reports_cleared_at'),
                                        ('profiles','deletion_handled_at'))) as colonne,
  (select count(*) from pg_proc where proname in ('admin_mark_feedback_handled',
    'admin_resolve_comment_report','admin_mark_deletion_handled','admin_reported_comments')) as funzioni;
