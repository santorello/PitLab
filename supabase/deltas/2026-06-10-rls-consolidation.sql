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
