-- ============================================================================
-- CATCH-UP PROD — PARTE B di 2  (2026-09-12)
--
-- ESEGUIRE DOPO 2026-09-12-catchup-A-enums.sql.
-- Concatenazione, nell'ordine corretto di dipendenza, dei delta mai applicati
-- su pitlap-prod. Ogni blocco conserva il proprio begin/commit originale:
-- se uno fallisce, solo quel blocco viene annullato, i precedenti restano.
--
-- NON incluso qui: 2026-09-12-keepalive-table.sql (gia' applicato).
-- ============================================================================


-- ############################################################################
-- ### SORGENTE: 2026-06-10-prod-alignment.sql
-- ############################################################################

-- ============================================================================
-- PitLap — Prod alignment delta (2026-06-10)
-- Replica su pitlap-prod (klfjvyytubiorqzfisdu) dei fix validati su pitlap-dev
-- durante il test E2E organizzatore del 2026-06-07.
-- Contenuto: D01, D05, D10, D11 (vedi qa-temp/e2e-test-organizer-2026-06-07.md)
-- Idempotente: ri-eseguibile senza effetti collaterali.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- D01 — complete_onboarding: rimozione overload ambigui + canonico a 7 arg
-- Causa: PGRST203 "Could not choose the best candidate function".
-- ----------------------------------------------------------------------------

drop function if exists public.complete_onboarding(text);
drop function if exists public.complete_onboarding(text, text[]);
drop function if exists public.complete_onboarding(text, text[], text, text, double precision, double precision);

create or replace function public.complete_onboarding(
  p_preferred_city text default ''::text,
  p_user_interests text[] default '{}'::text[],
  p_home_city text default null::text,
  p_home_country text default null::text,
  p_home_latitude double precision default null::double precision,
  p_home_longitude double precision default null::double precision,
  p_role text default null::text
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_current_role public.app_role;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select role into v_current_role from public.profiles where id = auth.uid();

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
    -- Imposta il ruolo solo se valido (no self-admin) e senza declassare un admin.
    role = case
      when v_current_role = 'admin' then role
      when p_role in ('user', 'shop_owner', 'track_organizer') then p_role::public.app_role
      else role
    end,
    onboarding_completed = true,
    onboarding_completed_at = coalesce(onboarding_completed_at, now()),
    updated_at = now()
  where id = auth.uid();
end;
$function$;

revoke execute on function public.complete_onboarding(text, text[], text, text, double precision, double precision, text) from public, anon;
grant execute on function public.complete_onboarding(text, text[], text, text, double precision, double precision, text) to authenticated;

-- ----------------------------------------------------------------------------
-- D05 — ripristino EXECUTE sui role helper SECURITY DEFINER
-- Causa: hardening 2026-06-02 aveva revocato EXECUTE da PUBLIC senza
-- ri-concederlo a authenticated/anon. Gli helper sono usati dentro RLS policy
-- e view: senza grant l'intera esperienza autenticata fallisce con 42501.
-- ----------------------------------------------------------------------------

grant execute on function public.is_admin() to authenticated, anon;
grant execute on function public.is_shop_manager(uuid) to authenticated, anon;
grant execute on function public.is_track_manager(uuid) to authenticated, anon;

-- ----------------------------------------------------------------------------
-- D10 — policy RLS gestori su track_category_links
-- Causa: la tabella aveva solo "admins can manage": un track_organizer non
-- poteva salvare le categorie della propria pista.
-- ----------------------------------------------------------------------------

drop policy if exists "track managers can manage track category links" on public.track_category_links;
create policy "track managers can manage track category links"
  on public.track_category_links
  for all
  to authenticated
  using (is_track_manager(track_id) or is_admin())
  with check (is_track_manager(track_id) or is_admin());

-- ----------------------------------------------------------------------------
-- D11 — policy UPDATE per gestori su tracks approvate + guard moderazione
-- Causa: tracks non aveva una policy UPDATE per i gestori (track_managers)
-- sulle piste approvate: l'update della scheda falliva silenziosamente (0 righe).
-- Il guard trigger impedisce ai non-admin di alterare le colonne di moderazione
-- (approval_status / is_public / submitted_by), preservando il flusso
-- draft->pending del submitter.
-- ----------------------------------------------------------------------------

create or replace function public.guard_track_moderation_columns()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin() then
    -- visibility is admin-only
    new.is_public := old.is_public;
    new.submitted_by := old.submitted_by;
    -- moderation status: only draft<->pending allowed for non-admins
    if old.approval_status not in ('draft','pending')
       or new.approval_status not in ('draft','pending') then
      new.approval_status := old.approval_status;
    end if;
  end if;
  return new;
end;
$function$;

revoke execute on function public.guard_track_moderation_columns() from public, anon, authenticated;

drop trigger if exists trg_guard_track_moderation on public.tracks;
create trigger trg_guard_track_moderation
  before update on public.tracks
  for each row execute function public.guard_track_moderation_columns();

drop policy if exists "track managers update managed track" on public.tracks;
create policy "track managers update managed track"
  on public.tracks
  for update
  to authenticated
  using (is_track_manager(id))
  with check (is_track_manager(id));

commit;

-- ----------------------------------------------------------------------------
-- Post-applicazione (manuale, dashboard):
-- 1. Auth > Settings: abilitare "Leaked password protection" (dev e prod).
-- 2. Verificare advisor Supabase: i 42501 su is_admin/is_*_manager devono sparire.
-- ----------------------------------------------------------------------------


-- ############################################################################
-- ### SORGENTE: 2026-06-10-rls-consolidation.sql
-- ############################################################################

-- ============================================================================
-- PitLap — RLS consolidation + index hardening (2026-06-10)
-- Obiettivo: eliminare le "multiple permissive policies" segnalate dall'advisor
-- Supabase (108 lint) consolidando per ciascuna azione una sola policy con OR,
-- e aggiungere indici sulle 3 FK scoperte.
-- Semantica permessi INVARIATA (verificata contro le policy precedenti).
-- NOTA: le policy di `tracks` sono lasciate intatte di proposito (flusso
-- gestore appena stabilizzato con il delta prod-alignment).
-- Idempotente. Applicare su dev, poi su prod insieme a prod-alignment.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- spots — prima: admin ALL + owner insert/update/delete custom + public read
-- ----------------------------------------------------------------------------

drop policy if exists "spots: admins manage all" on public.spots;
drop policy if exists "spots: owner deletes custom" on public.spots;
drop policy if exists "spots: owner inserts custom" on public.spots;
drop policy if exists "spots: public reads all" on public.spots;
drop policy if exists "spots: owner updates custom" on public.spots;

create policy "spots select" on public.spots
  for select using (true);

create policy "spots insert" on public.spots
  for insert with check (
    ((is_custom = true) and (owner_id = (select auth.uid())) and ((select auth.uid()) is not null))
    or is_admin()
  );

create policy "spots update" on public.spots
  for update
  using (((is_custom = true) and (owner_id = (select auth.uid()))) or is_admin())
  with check (((is_custom = true) and (owner_id = (select auth.uid()))) or is_admin());

create policy "spots delete" on public.spots
  for delete using (((is_custom = true) and (owner_id = (select auth.uid()))) or is_admin());

-- ----------------------------------------------------------------------------
-- external_links — prima: admin ALL + owner per-cmd + public reads public
-- ----------------------------------------------------------------------------

drop policy if exists "external_links: admins manage all" on public.external_links;
drop policy if exists "external_links: owner deletes" on public.external_links;
drop policy if exists "external_links: owner inserts" on public.external_links;
drop policy if exists "external_links: owner reads own" on public.external_links;
drop policy if exists "external_links: public reads public" on public.external_links;
drop policy if exists "external_links: owner updates" on public.external_links;

create policy "external_links select" on public.external_links
  for select using (
    (is_public = true) or (owner_id = (select auth.uid())) or is_admin()
  );

create policy "external_links insert" on public.external_links
  for insert with check (
    ((owner_id = (select auth.uid())) and ((select auth.uid()) is not null)) or is_admin()
  );

create policy "external_links update" on public.external_links
  for update
  using ((owner_id = (select auth.uid())) or is_admin())
  with check ((owner_id = (select auth.uid())) or is_admin());

create policy "external_links delete" on public.external_links
  for delete using ((owner_id = (select auth.uid())) or is_admin());

-- ----------------------------------------------------------------------------
-- community_events — prima: admin ALL + author per-cmd + public read (true)
-- ----------------------------------------------------------------------------

drop policy if exists "community_events: admins manage all" on public.community_events;
drop policy if exists "community_events: author deletes" on public.community_events;
drop policy if exists "community_events: author inserts" on public.community_events;
drop policy if exists "community_events: author reads own" on public.community_events;
drop policy if exists "community_events: public read" on public.community_events;
drop policy if exists "community_events: author updates" on public.community_events;

create policy "community_events select" on public.community_events
  for select using (true);

create policy "community_events insert" on public.community_events
  for insert with check (
    ((author_id = (select auth.uid())) and ((select auth.uid()) is not null)) or is_admin()
  );

create policy "community_events update" on public.community_events
  for update
  using ((author_id = (select auth.uid())) or is_admin())
  with check ((author_id = (select auth.uid())) or is_admin());

create policy "community_events delete" on public.community_events
  for delete using ((author_id = (select auth.uid())) or is_admin());

-- ----------------------------------------------------------------------------
-- user_builds — prima: admin ALL + owner per-cmd + public reads public
-- ----------------------------------------------------------------------------

drop policy if exists "admins can manage all user builds" on public.user_builds;
drop policy if exists "user_builds: owner deletes" on public.user_builds;
drop policy if exists "user_builds: owner inserts" on public.user_builds;
drop policy if exists "user_builds: owner reads all" on public.user_builds;
drop policy if exists "user_builds: public reads public" on public.user_builds;
drop policy if exists "user_builds: owner updates" on public.user_builds;

create policy "user_builds select" on public.user_builds
  for select using (
    (is_public = true) or (owner_id = (select auth.uid())) or is_admin()
  );

create policy "user_builds insert" on public.user_builds
  for insert with check ((owner_id = (select auth.uid())) or is_admin());

create policy "user_builds update" on public.user_builds
  for update
  using ((owner_id = (select auth.uid())) or is_admin())
  with check ((owner_id = (select auth.uid())) or is_admin());

create policy "user_builds delete" on public.user_builds
  for delete using ((owner_id = (select auth.uid())) or is_admin());

-- ----------------------------------------------------------------------------
-- profiles — prima: 4 SELECT sovrapposte, 3 UPDATE duplicate, admin ALL
-- Semantica conservata: gli utenti loggati leggono tutti i profili (necessario
-- per card community/leaderboard), i guest solo quelli pubblici.
-- ----------------------------------------------------------------------------

drop policy if exists "admins can manage profiles" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Users can read own profile" on public.profiles;
drop policy if exists "profiles are readable by signed in users" on public.profiles;
drop policy if exists "profiles: guest reads public" on public.profiles;
drop policy if exists "profiles: owner reads own" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "profiles: owner updates own" on public.profiles;
drop policy if exists "users manage own profile" on public.profiles;

create policy "profiles select anon" on public.profiles
  for select to anon using (is_public = true);

create policy "profiles select authenticated" on public.profiles
  for select to authenticated using (true);

create policy "profiles insert" on public.profiles
  for insert to authenticated
  with check (((select auth.uid()) = id) or is_admin());

create policy "profiles update" on public.profiles
  for update to authenticated
  using (((select auth.uid()) = id) or is_admin())
  with check (((select auth.uid()) = id) or is_admin());

create policy "profiles delete" on public.profiles
  for delete to authenticated using (is_admin());

-- ----------------------------------------------------------------------------
-- track_category_links — admin ALL incluso nella policy manager: per-cmd
-- ----------------------------------------------------------------------------

drop policy if exists "admins can manage track category links" on public.track_category_links;
drop policy if exists "public can read track category links" on public.track_category_links;
drop policy if exists "track managers can manage track category links" on public.track_category_links;

create policy "track_category_links select" on public.track_category_links
  for select using (
    exists (select 1 from public.tracks t where t.id = track_category_links.track_id and t.is_public = true)
    or is_track_manager(track_id) or is_admin()
  );

create policy "track_category_links insert" on public.track_category_links
  for insert to authenticated
  with check (is_track_manager(track_id) or is_admin());

create policy "track_category_links update" on public.track_category_links
  for update to authenticated
  using (is_track_manager(track_id) or is_admin())
  with check (is_track_manager(track_id) or is_admin());

create policy "track_category_links delete" on public.track_category_links
  for delete to authenticated
  using (is_track_manager(track_id) or is_admin());

-- ----------------------------------------------------------------------------
-- Indici su FK scoperte (advisor: unindexed_foreign_keys)
-- ----------------------------------------------------------------------------

create index if not exists event_rsvps_user_id_idx on public.event_rsvps (user_id);
create index if not exists track_category_links_category_id_idx on public.track_category_links (category_id);
create index if not exists track_services_service_type_id_idx on public.track_services (service_type_id);

commit;


-- ############################################################################
-- ### SORGENTE: 2026-06-10-draft-taxonomy-policies.sql
-- ############################################################################

-- ============================================================================
-- PitLap — Policy RLS per tassonomie su bozze pista (D08/D09)
-- 2026-06-10
--
-- Problema: track_services e track_category_links consentono la scrittura
-- solo a is_track_manager(track_id) OR is_admin().
-- is_track_manager usa la tabella track_managers, che viene popolata dal
-- trigger trg_auto_link_track_manager SOLO quando la pista viene approvata.
-- Quindi il submitter NON può scrivere servizi/categorie su una bozza:
-- non esiste ancora un record in track_managers per lui.
--
-- Soluzione: aggiungere su entrambe le tabelle una policy separata che
-- autorizza il submitter originale mentre la pista è in stato draft/pending.
-- Condizione: tracks.submitted_by = auth.uid()
--             AND tracks.approval_status IN ('draft','pending')
--
-- NOTA RLS: le policy permissive vengono valutate con OR tra di loro;
-- aggiungere questa policy non altera le policy esistenti per i gestori.
--
-- Idempotente: DROP POLICY IF EXISTS prima di CREATE.
-- NON applicare automaticamente: questo file viene eseguito manualmente
-- dall'operatore DB dopo revisione.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- track_services — policy per il submitter su bozze/pending
-- ----------------------------------------------------------------------------

drop policy if exists "submitter can manage own draft track services" on public.track_services;

create policy "submitter can manage own draft track services"
  on public.track_services
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.tracks t
      where t.id = track_services.track_id
        and t.submitted_by = (select auth.uid())
        and t.approval_status in ('draft', 'pending')
    )
  )
  with check (
    exists (
      select 1
      from public.tracks t
      where t.id = track_services.track_id
        and t.submitted_by = (select auth.uid())
        and t.approval_status in ('draft', 'pending')
    )
  );

-- ----------------------------------------------------------------------------
-- track_category_links — policy per il submitter su bozze/pending
-- ----------------------------------------------------------------------------

drop policy if exists "submitter can manage own draft track category links" on public.track_category_links;

create policy "submitter can manage own draft track category links"
  on public.track_category_links
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.tracks t
      where t.id = track_category_links.track_id
        and t.submitted_by = (select auth.uid())
        and t.approval_status in ('draft', 'pending')
    )
  )
  with check (
    exists (
      select 1
      from public.tracks t
      where t.id = track_category_links.track_id
        and t.submitted_by = (select auth.uid())
        and t.approval_status in ('draft', 'pending')
    )
  );

commit;


-- ############################################################################
-- ### SORGENTE: 2026-06-10-media-storage.sql
-- ############################################################################

-- ============================================================================
-- PitLap — Supabase Storage per media upload system (2026-06-10)
-- Bucket pubblico `media` + policy owner-based su storage.objects.
-- Convenzione path: <user_id>/<entity_type>/<filename>
--   es. 42bb15da-.../tracks/cover-1718000000.webp
-- Limite 5MB, solo immagini (jpeg/png/webp/gif).
-- Applicato su dev (migration media_storage_bucket_and_policies).
-- Da applicare su prod insieme agli altri delta del 2026-06-10.
-- Idempotente.
-- ============================================================================

begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('media', 'media', true, 5242880, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- NOTA: nessuna policy SELECT volutamente — il bucket e' public e le object URL
-- funzionano senza; una SELECT broad permetterebbe il listing di tutti i file
-- (advisor: public_bucket_allows_listing).
drop policy if exists "media public read" on storage.objects;

drop policy if exists "media owner insert" on storage.objects;
create policy "media owner insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "media owner update" on storage.objects;
create policy "media owner update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'media'
    and ((storage.foldername(name))[1] = (select auth.uid())::text or is_admin())
  )
  with check (
    bucket_id = 'media'
    and ((storage.foldername(name))[1] = (select auth.uid())::text or is_admin())
  );

drop policy if exists "media owner delete" on storage.objects;
create policy "media owner delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'media'
    and ((storage.foldername(name))[1] = (select auth.uid())::text or is_admin())
  );

commit;


-- ############################################################################
-- ### SORGENTE: 2026-06-10-entity-comments.sql
-- ############################################################################

-- ============================================================================
-- PitLap — Sistema commenti polimorfici + segnalazioni (2026-06-10)
-- Tabelle: entity_comments, entity_comment_reports
-- View: entity_comment_counts (security_invoker)
-- RPC: report_comment(uuid, text)
-- PitCoin: azione comment_posted (5 punti, daily_cap 50, cooldown 60s) + trigger
-- Moderazione: is_hidden/hidden_reason/hidden_by solo admin (guard trigger)
-- Applicato su dev (migration entity_comments_system). Da applicare su prod.
-- Idempotente.
-- ============================================================================

begin;

create table if not exists public.entity_comments (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null check (entity_type in ('track','shop','event','community_event','spot','user_build')),
  entity_id uuid not null,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 2000),
  is_hidden boolean not null default false,
  hidden_reason text,
  hidden_by uuid references public.profiles(id),
  reported_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists entity_comments_entity_idx on public.entity_comments (entity_type, entity_id, created_at desc);
create index if not exists entity_comments_author_idx on public.entity_comments (author_id);

alter table public.entity_comments enable row level security;

drop policy if exists "entity_comments select" on public.entity_comments;
create policy "entity_comments select" on public.entity_comments
  for select using (
    (is_hidden = false) or (author_id = (select auth.uid())) or is_admin()
  );

drop policy if exists "entity_comments insert" on public.entity_comments;
create policy "entity_comments insert" on public.entity_comments
  for insert to authenticated
  with check (author_id = (select auth.uid()) and is_hidden = false);

drop policy if exists "entity_comments update" on public.entity_comments;
create policy "entity_comments update" on public.entity_comments
  for update to authenticated
  using ((author_id = (select auth.uid())) or is_admin())
  with check ((author_id = (select auth.uid())) or is_admin());

drop policy if exists "entity_comments delete" on public.entity_comments;
create policy "entity_comments delete" on public.entity_comments
  for delete to authenticated
  using ((author_id = (select auth.uid())) or is_admin());

create or replace function public.guard_comment_moderation_columns()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.is_admin() then
    new.is_hidden := old.is_hidden;
    new.hidden_reason := old.hidden_reason;
    new.hidden_by := old.hidden_by;
    new.reported_count := old.reported_count;
    new.author_id := old.author_id;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

revoke execute on function public.guard_comment_moderation_columns() from public, anon, authenticated;

drop trigger if exists trg_guard_comment_moderation on public.entity_comments;
create trigger trg_guard_comment_moderation
  before update on public.entity_comments
  for each row execute function public.guard_comment_moderation_columns();

create table if not exists public.entity_comment_reports (
  comment_id uuid not null references public.entity_comments(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text,
  created_at timestamptz not null default now(),
  primary key (comment_id, reporter_id)
);

alter table public.entity_comment_reports enable row level security;

drop policy if exists "comment_reports select" on public.entity_comment_reports;
create policy "comment_reports select" on public.entity_comment_reports
  for select to authenticated
  using ((reporter_id = (select auth.uid())) or is_admin());

create or replace function public.report_comment(p_comment_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  insert into public.entity_comment_reports (comment_id, reporter_id, reason)
  values (p_comment_id, auth.uid(), nullif(trim(coalesce(p_reason,'')), ''))
  on conflict do nothing;
  update public.entity_comments c
  set reported_count = (select count(*) from public.entity_comment_reports r where r.comment_id = c.id)
  where c.id = p_comment_id;
end;
$$;

revoke execute on function public.report_comment(uuid, text) from public, anon;
grant execute on function public.report_comment(uuid, text) to authenticated;

create or replace view public.entity_comment_counts
with (security_invoker = true) as
select entity_type, entity_id, count(*)::integer as comment_count
from public.entity_comments
where is_hidden = false
group by entity_type, entity_id;

insert into public.pitcoin_action_definitions (action_key, name_it, name_en, description_it, description_en, category, base_points, daily_cap, per_entity_cap, lifetime_cap, cooldown_seconds, requires_approval, enabled)
values ('comment_posted', 'Commento pubblicato', 'Comment posted',
        'Hai commentato un contenuto della community.', 'You commented on a community item.',
        'engagement', 5, 50, null, null, 60, false, true)
on conflict (action_key) do nothing;

create or replace function public.trg_pitcoin_comment_after_insert()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  begin
    perform public.award_pitcoin(new.author_id, 'comment_posted', 'entity_comments', new.id, null);
  exception when others then
    null;
  end;
  return new;
end;
$$;

revoke execute on function public.trg_pitcoin_comment_after_insert() from public, anon, authenticated;

drop trigger if exists trg_pitcoin_comment_after_insert on public.entity_comments;
create trigger trg_pitcoin_comment_after_insert
  after insert on public.entity_comments
  for each row execute function public.trg_pitcoin_comment_after_insert();

commit;


-- ############################################################################
-- ### SORGENTE: 2026-06-10-profile-follows-notifications.sql (solo Parte B)
-- ###          La Parte A e' nel file 2026-09-12-catchup-A-enums.sql
-- ############################################################################

-- ---- Parte B ----------------------------------------------------------------

begin;

create table if not exists public.profile_follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  followed_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followed_id),
  check (follower_id <> followed_id)
);

create index if not exists profile_follows_followed_idx on public.profile_follows (followed_id);

alter table public.profile_follows enable row level security;

drop policy if exists "profile_follows select" on public.profile_follows;
create policy "profile_follows select" on public.profile_follows
  for select to authenticated
  using (follower_id = (select auth.uid()) or followed_id = (select auth.uid()) or is_admin());

drop policy if exists "profile_follows insert" on public.profile_follows;
create policy "profile_follows insert" on public.profile_follows
  for insert to authenticated
  with check (
    follower_id = (select auth.uid())
    and exists (select 1 from public.profiles p where p.id = followed_id and p.is_public = true)
  );

drop policy if exists "profile_follows delete" on public.profile_follows;
create policy "profile_follows delete" on public.profile_follows
  for delete to authenticated
  using (follower_id = (select auth.uid()) or is_admin());

create or replace function public.get_profile_follower_count(profile_uuid uuid)
returns integer
language sql
security definer
set search_path to 'public'
as $$
  select count(*)::integer from public.profile_follows where followed_id = profile_uuid;
$$;

grant execute on function public.get_profile_follower_count(uuid) to authenticated, anon;

drop policy if exists "recipients read own notifications" on public.notifications;
create policy "recipients read own notifications" on public.notifications
  for select to authenticated
  using (
    exists (
      select 1 from public.notification_recipients r
      where r.notification_id = notifications.id and r.user_id = (select auth.uid())
    )
  );

drop policy if exists "users update own notification inbox" on public.notification_recipients;
create policy "users update own notification inbox" on public.notification_recipients
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create or replace function public.create_notification(
  p_kind public.notification_kind,
  p_entity_type public.approval_entity_type,
  p_entity_id uuid,
  p_title text,
  p_body text,
  p_payload jsonb,
  p_created_by uuid,
  p_recipients uuid[]
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
begin
  if p_recipients is null or array_length(p_recipients, 1) is null then
    return;
  end if;
  insert into public.notifications (kind, entity_type, entity_id, title, body, payload, created_by)
  values (p_kind, p_entity_type, p_entity_id, p_title, p_body, coalesce(p_payload, '{}'::jsonb), p_created_by)
  returning id into v_id;
  insert into public.notification_recipients (notification_id, user_id)
  select v_id, unnest(p_recipients)
  on conflict do nothing;
end;
$$;

revoke execute on function public.create_notification(public.notification_kind, public.approval_entity_type, uuid, text, text, jsonb, uuid, uuid[]) from public, anon, authenticated;

create or replace function public.trg_notify_new_follower()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_name text;
begin
  select coalesce(nullif(display_name,''), 'Un utente') into v_name from public.profiles where id = new.follower_id;
  perform public.create_notification(
    'new_follower'::public.notification_kind,
    'profile'::public.approval_entity_type,
    new.follower_id,
    v_name || ' ha iniziato a seguirti',
    null,
    jsonb_build_object('follower_id', new.follower_id),
    new.follower_id,
    array[new.followed_id]
  );
  return new;
end;
$$;

revoke execute on function public.trg_notify_new_follower() from public, anon, authenticated;

drop trigger if exists trg_notify_new_follower on public.profile_follows;
create trigger trg_notify_new_follower
  after insert on public.profile_follows
  for each row execute function public.trg_notify_new_follower();

create or replace function public.trg_notify_followers_build_published()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_name text;
  v_recipients uuid[];
begin
  if (tg_op = 'INSERT' and new.is_public)
     or (tg_op = 'UPDATE' and new.is_public and not coalesce(old.is_public, false)) then
    select array_agg(follower_id) into v_recipients from public.profile_follows where followed_id = new.owner_id;
    if v_recipients is not null then
      select coalesce(nullif(display_name,''), 'Un utente') into v_name from public.profiles where id = new.owner_id;
      perform public.create_notification(
        'followed_activity'::public.notification_kind,
        'user_build'::public.approval_entity_type,
        new.id,
        v_name || ' ha pubblicato una nuova build',
        new.title,
        jsonb_build_object('owner_id', new.owner_id, 'build_id', new.id),
        new.owner_id,
        v_recipients
      );
    end if;
  end if;
  return new;
end;
$$;

revoke execute on function public.trg_notify_followers_build_published() from public, anon, authenticated;

drop trigger if exists trg_notify_followers_build_published on public.user_builds;
create trigger trg_notify_followers_build_published
  after insert or update on public.user_builds
  for each row execute function public.trg_notify_followers_build_published();

create or replace function public.trg_notify_followers_event_created()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_name text;
  v_recipients uuid[];
begin
  select array_agg(follower_id) into v_recipients from public.profile_follows where followed_id = new.author_id;
  if v_recipients is not null then
    select coalesce(nullif(display_name,''), 'Un utente') into v_name from public.profiles where id = new.author_id;
    perform public.create_notification(
      'followed_activity'::public.notification_kind,
      'community_event'::public.approval_entity_type,
      new.id,
      v_name || ' ha creato un nuovo evento',
      new.title,
      jsonb_build_object('author_id', new.author_id, 'event_id', new.id),
      new.author_id,
      v_recipients
    );
  end if;
  return new;
end;
$$;

revoke execute on function public.trg_notify_followers_event_created() from public, anon, authenticated;

drop trigger if exists trg_notify_followers_event_created on public.community_events;
create trigger trg_notify_followers_event_created
  after insert on public.community_events
  for each row execute function public.trg_notify_followers_event_created();

insert into public.pitcoin_action_definitions (action_key, name_it, name_en, description_it, description_en, category, base_points, daily_cap, per_entity_cap, lifetime_cap, cooldown_seconds, requires_approval, enabled)
values ('profile_followed', 'Profilo seguito', 'Profile followed',
        'Hai iniziato a seguire un profilo della community.', 'You started following a community profile.',
        'engagement', 2, 20, 1, null, 0, false, true)
on conflict (action_key) do nothing;

create or replace function public.trg_pitcoin_profile_follow_after_insert()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  begin
    perform public.award_pitcoin(new.follower_id, 'profile_followed', 'profile_follows', new.followed_id, null);
  exception when others then
    null;
  end;
  return new;
end;
$$;

revoke execute on function public.trg_pitcoin_profile_follow_after_insert() from public, anon, authenticated;

drop trigger if exists trg_pitcoin_profile_follow_after_insert on public.profile_follows;
create trigger trg_pitcoin_profile_follow_after_insert
  after insert on public.profile_follows
  for each row execute function public.trg_pitcoin_profile_follow_after_insert();

commit;


-- ############################################################################
-- ### SORGENTE: 2026-06-18-enable-keepalive-timestamp-update.sql
-- ############################################################################

revoke update on table public.keepalive from anon;
grant update (checked_at) on table public.keepalive to anon;

drop policy if exists "Allow anonymous keepalive update" on public.keepalive;

create policy "Allow anonymous keepalive update"
on public.keepalive
for update
to anon
using (id = true)
with check (id = true);


-- ############################################################################
-- ### SORGENTE: 2026-07-29-operational-notifications.sql
-- ############################################################################

-- Notifiche operative (2026-07-29)
-- Aggiunge notifiche per gli eventi che contano nel loop PitLap, oltre a
-- new_follower/followed_activity gia' esistenti:
--   1. cambio stato pista            -> follower della pista (track_follows)
--   2. commento su una tua entita'   -> proprietario (v1: pista/negozio via submitted_by)
--   3. esito approvazione            -> chi ha inviato la bozza (submitted_by)
--
-- Riusa public.create_notification(kind, entity_type, entity_id, title, body,
-- payload, created_by, recipients[]) gia' definita nel delta 2026-06-10.
-- Tutte le funzioni sono SECURITY DEFINER con EXECUTE revocato (chiamate solo da trigger).

-- Parte A (i due ALTER TYPE) spostata nel file 2026-09-12-catchup-A-enums.sql

-- Parte B: funzioni trigger + trigger.

-- 1) Cambio stato pista -> follower (escluso chi aggiorna).
create or replace function public.trg_notify_track_status_changed()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_track_name text;
  v_track_slug text;
  v_recipients uuid[];
begin
  -- Solo se lo stato cambia davvero (INSERT o UPDATE dello status).
  if tg_op = 'UPDATE' and new.status is not distinct from old.status then
    return new;
  end if;

  select name, slug into v_track_name, v_track_slug from public.tracks where id = new.track_id;

  select array_agg(user_id) into v_recipients
  from public.track_follows
  where track_id = new.track_id
    and user_id is distinct from new.updated_by;

  perform public.create_notification(
    'track_status_changed'::public.notification_kind,
    'track'::public.approval_entity_type,
    new.track_id,
    coalesce(v_track_name, 'Pista'),
    'Nuovo stato: ' || new.status::text
      || case when coalesce(new.message, '') <> '' then ' · ' || new.message else '' end,
    jsonb_build_object('status', new.status::text, 'slug', v_track_slug),
    new.updated_by,
    v_recipients
  );
  return new;
end;
$$;
revoke execute on function public.trg_notify_track_status_changed() from public, anon, authenticated;

drop trigger if exists trg_notify_track_status_changed on public.track_status_current;
create trigger trg_notify_track_status_changed
  after insert or update on public.track_status_current
  for each row execute function public.trg_notify_track_status_changed();

-- 2) Commento su una tua entita' -> proprietario (v1: track/shop).
-- ponytail: solo track/shop (submitted_by, colonne certe). spot/user_build/
-- community_event/event: aggiungere quando serve, risolvendo l'owner per tipo.
create or replace function public.trg_notify_comment_received()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_owner uuid;
  v_name text;
  v_slug text;
begin
  if new.entity_type = 'track' then
    select submitted_by, name, slug into v_owner, v_name, v_slug from public.tracks where id = new.entity_id;
  elsif new.entity_type = 'shop' then
    select submitted_by, name, slug into v_owner, v_name, v_slug from public.shops where id = new.entity_id;
  else
    return new; -- tipi non ancora gestiti
  end if;

  -- Niente notifica se non c'e' owner o se commenti sulla tua entita'.
  if v_owner is null or v_owner = new.author_id then
    return new;
  end if;

  perform public.create_notification(
    'comment_received'::public.notification_kind,
    new.entity_type::public.approval_entity_type,
    new.entity_id,
    coalesce(v_name, 'La tua scheda'),
    'Nuovo commento: ' || left(coalesce(new.body, ''), 120),
    jsonb_build_object('comment_id', new.id, 'slug', v_slug),
    new.author_id,
    array[v_owner]
  );
  return new;
end;
$$;
revoke execute on function public.trg_notify_comment_received() from public, anon, authenticated;

drop trigger if exists trg_notify_comment_received on public.entity_comments;
create trigger trg_notify_comment_received
  after insert on public.entity_comments
  for each row execute function public.trg_notify_comment_received();

-- 3) Esito approvazione (approvato/rifiutato) -> chi ha inviato la bozza.
-- Un'unica funzione per tracks e shops, distingue via TG_TABLE_NAME.
create or replace function public.trg_notify_approval_decided()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_kind_entity public.approval_entity_type;
begin
  if new.approval_status not in ('approved','rejected')
     or new.approval_status is not distinct from old.approval_status
     or new.submitted_by is null
     or new.submitted_by is not distinct from new.reviewed_by then
    return new;
  end if;

  v_kind_entity := case tg_table_name when 'shops' then 'shop' else 'track' end::public.approval_entity_type;

  perform public.create_notification(
    'approval_decided'::public.notification_kind,
    v_kind_entity,
    new.id,
    new.name,
    case new.approval_status::text
      when 'approved' then 'La tua richiesta è stata approvata.'
      else 'La tua richiesta non è stata approvata.'
        || case when coalesce(new.review_notes,'') <> '' then ' · ' || new.review_notes else '' end
    end,
    jsonb_build_object('approval_status', new.approval_status::text, 'slug', new.slug),
    new.reviewed_by,
    array[new.submitted_by]
  );
  return new;
end;
$$;
revoke execute on function public.trg_notify_approval_decided() from public, anon, authenticated;

drop trigger if exists trg_notify_approval_decided on public.tracks;
create trigger trg_notify_approval_decided
  after update of approval_status on public.tracks
  for each row execute function public.trg_notify_approval_decided();

drop trigger if exists trg_notify_approval_decided on public.shops;
create trigger trg_notify_approval_decided
  after update of approval_status on public.shops
  for each row execute function public.trg_notify_approval_decided();


-- ############################################################################
-- ### SORGENTE: 2026-07-29-advisor-cleanup.sql
-- ############################################################################

-- Advisor cleanup (2026-07-29)
-- Chiude i lint performance introdotti/rimasti dalle feature 0.3.0.

-- 1) Foreign key non indicizzate (advisor: unindexed_foreign_keys)
create index if not exists entity_comment_reports_reporter_id_idx
  on public.entity_comment_reports (reporter_id);
create index if not exists entity_comments_hidden_by_idx
  on public.entity_comments (hidden_by);

-- 2) Multiple permissive policies su track_follows / shop_follows
-- Prima: 3 policy sovrapposte (manage own ALL + read own SELECT + admins read SELECT)
-- → il SELECT veniva valutato da 2-3 policy per riga. Consolido in UNA policy per
-- tabella: owner gestisce le proprie, admin legge/elimina; nessuno puo' forgiare
-- follow altrui (with check ancorato a auth.uid()). Semantica invariata salvo che
-- l'admin ora puo' anche rimuovere un follow (prima solo lettura) — accettabile.
drop policy if exists "users can manage own track follows" on public.track_follows;
drop policy if exists "users can read own track follows" on public.track_follows;
drop policy if exists "admins can read all track follows" on public.track_follows;
create policy "track_follows owner and admin" on public.track_follows
  for all
  using (user_id = (select auth.uid()) or is_admin())
  with check (user_id = (select auth.uid()));

drop policy if exists "users can manage own shop follows" on public.shop_follows;
drop policy if exists "users can read own shop follows" on public.shop_follows;
drop policy if exists "admins can read all shop follows" on public.shop_follows;
create policy "shop_follows owner and admin" on public.shop_follows
  for all
  using (user_id = (select auth.uid()) or is_admin())
  with check (user_id = (select auth.uid()));


-- ############################################################################
-- ### SORGENTE: 2026-07-29-pitcoin-privacy.sql
-- ############################################################################

-- Privacy PitCoin (2026-07-29)
-- Regola di prodotto: i PitCoin di un utente NON sono visibili agli altri.
--
-- La view public.public_user_pitcoin esponeva total_points/lifetime_earned di
-- TUTTI i profili pubblici ad anon/authenticated (le view girano coi privilegi
-- del creatore e bypassano la RLS di user_pitcoin_balances). La ricreo così i
-- valori PitCoin tornano solo al proprietario (auth.uid()), 0 per gli altri.
-- La tabella base user_pitcoin_balances resta protetta da RLS (owner+admin).
--
-- Nota: pitcoin_public_leaderboard espone ancora nome+punti altrui by design;
-- decisione di prodotto separata (rimuovere / anonimizzare) prima del go-live.

create or replace view public.public_user_pitcoin as
select
  p.id as user_id,
  p.public_slug,
  p.display_name,
  p.avatar_url,
  case when p.id = (select auth.uid())
       then coalesce(b.total_points, 0) else 0 end as total_points,
  case when p.id = (select auth.uid())
       then coalesce(b.lifetime_earned, 0) else 0 end as lifetime_earned,
  case when p.id = (select auth.uid())
       then b.last_action_at else null end as last_action_at
from public.profiles p
left join public.user_pitcoin_balances b on b.user_id = p.id
where p.is_public = true and p.public_slug is not null;

-- Il CREATE OR REPLACE riporta la view a SECURITY DEFINER: ripristina invoker
-- (sicuro: i punti sono comunque esposti solo per p.id = auth.uid()).
alter view public.public_user_pitcoin set (security_invoker = on);


-- ############################################################################
-- ### SORGENTE: 2026-07-30-feedback.sql
-- ############################################################################

-- Feedback utenti (2026-07-30)
-- Tabella per raccogliere feedback da chiunque (guest o autenticato).
-- L'alert email al titolare verrà agganciato in un secondo momento (Edge
-- Function + servizio email tipo Resend, su insert).

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  message text not null,
  contact_email text,
  user_id uuid references auth.users(id) on delete set null,
  page text,
  user_agent text,
  created_at timestamptz not null default now()
);

alter table public.feedback enable row level security;

drop policy if exists "anyone can submit feedback" on public.feedback;
create policy "anyone can submit feedback" on public.feedback
  for insert
  to anon, authenticated
  with check (
    char_length(message) between 1 and 5000
    and (user_id is null or user_id = (select auth.uid()))
  );

drop policy if exists "admins read feedback" on public.feedback;
create policy "admins read feedback" on public.feedback
  for select to authenticated
  using (is_admin());

create index if not exists feedback_created_at_idx on public.feedback (created_at desc);

