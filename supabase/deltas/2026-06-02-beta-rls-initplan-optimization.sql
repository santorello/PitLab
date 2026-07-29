-- =============================================================================
-- Migration: beta_rls_initplan_optimization
-- Date: 2026-06-02
-- Project: pitlap-dev (mqieterttnqdtdguaqoe)
-- Status: ALREADY APPLIED ON DEV
-- =============================================================================
-- Scopo: corregge il lint auth_rls_initplan su 47 policy RLS.
-- Problema: chiamate dirette a auth.uid() / auth.jwt() / auth.role() nelle
--   espressioni USING / WITH CHECK vengono rivalutate per ogni riga scansionata,
--   causando overhead su tabelle grandi.
-- Fix (semanticamente identico, raccomandato ufficialmente da Supabase):
--   wrappare ogni chiamata in una subquery scalare:
--     auth.uid()  ->  (select auth.uid())
--   Il planner PostgreSQL ottimizza la subquery come InitPlan eseguito una
--   sola volta per statement, anziche per ogni riga.
-- Tabelle coinvolte (47 policy su 20 tabelle):
--   approval_requests, arrivals, community_events, event_rsvps,
--   external_links, notification_recipients, organization_memberships,
--   organizations, pitcoin_transactions, profiles, shop_follows, shops,
--   spots, track_follows, tracks, user_badges, user_build_votes,
--   user_builds, user_consents, user_pitcoin_balances
-- =============================================================================

ALTER POLICY "submitters can read approval requests" ON public.approval_requests
  USING (((submitted_by = (select auth.uid())) OR is_admin()));

ALTER POLICY "users can manage own arrivals" ON public.arrivals
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "community_events: admins manage all" ON public.community_events
  USING ((EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = (select auth.uid())) AND (profiles.role = 'admin'::app_role)))));

ALTER POLICY "community_events: author deletes" ON public.community_events
  USING ((author_id = (select auth.uid())));

ALTER POLICY "community_events: author inserts" ON public.community_events
  WITH CHECK (((author_id = (select auth.uid())) AND ((select auth.uid()) IS NOT NULL)));

ALTER POLICY "community_events: author reads own" ON public.community_events
  USING ((author_id = (select auth.uid())));

ALTER POLICY "community_events: author updates" ON public.community_events
  USING ((author_id = (select auth.uid())))
  WITH CHECK ((author_id = (select auth.uid())));

ALTER POLICY "users can manage own event rsvps" ON public.event_rsvps
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "users can read own event rsvps" ON public.event_rsvps
  USING ((((select auth.uid()) = user_id) OR is_admin()));

ALTER POLICY "external_links: admins manage all" ON public.external_links
  USING ((EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = (select auth.uid())) AND (profiles.role = 'admin'::app_role)))));

ALTER POLICY "external_links: owner deletes" ON public.external_links
  USING ((owner_id = (select auth.uid())));

ALTER POLICY "external_links: owner inserts" ON public.external_links
  WITH CHECK (((owner_id = (select auth.uid())) AND ((select auth.uid()) IS NOT NULL)));

ALTER POLICY "external_links: owner reads own" ON public.external_links
  USING ((owner_id = (select auth.uid())));

ALTER POLICY "external_links: owner updates" ON public.external_links
  USING ((owner_id = (select auth.uid())))
  WITH CHECK ((owner_id = (select auth.uid())));

ALTER POLICY "users read own notification inbox" ON public.notification_recipients
  USING (((user_id = (select auth.uid())) OR is_admin()));

ALTER POLICY "memberships visible to related users and admins" ON public.organization_memberships
  USING ((is_admin() OR (user_id = (select auth.uid())) OR (EXISTS ( SELECT 1
   FROM organization_memberships current_membership
  WHERE ((current_membership.organization_id = organization_memberships.organization_id) AND (current_membership.user_id = (select auth.uid())) AND (current_membership.status = 'active'::organization_membership_status))))));

ALTER POLICY "organizations visible to active members and admins" ON public.organizations
  USING ((is_admin() OR (EXISTS ( SELECT 1
   FROM organization_memberships
  WHERE ((organization_memberships.organization_id = organizations.id) AND (organization_memberships.user_id = (select auth.uid())) AND (organization_memberships.status = 'active'::organization_membership_status))))));

ALTER POLICY "pitcoin_transactions: owner reads own" ON public.pitcoin_transactions
  USING ((user_id = (select auth.uid())));

ALTER POLICY "Users can insert own profile" ON public.profiles
  WITH CHECK (((select auth.uid()) = id));

ALTER POLICY "Users can read own profile" ON public.profiles
  USING (((select auth.uid()) = id));

ALTER POLICY "Users can update own profile" ON public.profiles
  USING (((select auth.uid()) = id))
  WITH CHECK (((select auth.uid()) = id));

ALTER POLICY "profiles: owner reads own" ON public.profiles
  USING ((id = (select auth.uid())));

ALTER POLICY "profiles: owner updates own" ON public.profiles
  USING ((id = (select auth.uid())))
  WITH CHECK ((id = (select auth.uid())));

ALTER POLICY "users manage own profile" ON public.profiles
  USING (((select auth.uid()) = id))
  WITH CHECK (((select auth.uid()) = id));

ALTER POLICY "users can manage own shop follows" ON public.shop_follows
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "users can read own shop follows" ON public.shop_follows
  USING (((select auth.uid()) = user_id));

ALTER POLICY "shop submitters can insert own shops" ON public.shops
  WITH CHECK ((((select auth.uid()) = submitted_by) AND (is_public = false) AND (approval_status = ANY (ARRAY['draft'::approval_status, 'pending'::approval_status]))));

ALTER POLICY "spots: admins manage all" ON public.spots
  USING ((EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = (select auth.uid())) AND (profiles.role = 'admin'::app_role)))));

ALTER POLICY "spots: owner deletes custom" ON public.spots
  USING (((is_custom = true) AND (owner_id = (select auth.uid()))));

ALTER POLICY "spots: owner inserts custom" ON public.spots
  WITH CHECK (((is_custom = true) AND (owner_id = (select auth.uid())) AND ((select auth.uid()) IS NOT NULL)));

ALTER POLICY "spots: owner updates custom" ON public.spots
  USING (((is_custom = true) AND (owner_id = (select auth.uid()))))
  WITH CHECK (((is_custom = true) AND (owner_id = (select auth.uid()))));

ALTER POLICY "users can manage own track follows" ON public.track_follows
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "users can read own track follows" ON public.track_follows
  USING (((select auth.uid()) = user_id));

ALTER POLICY "tracks: organizer inserts pending" ON public.tracks
  WITH CHECK (((submitted_by = (select auth.uid())) AND (approval_status = ANY (ARRAY['draft'::approval_status, 'pending'::approval_status])) AND (is_public = false) AND (EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = (select auth.uid())) AND (profiles.role = ANY (ARRAY['track_organizer'::app_role, 'admin'::app_role])))))));

ALTER POLICY "tracks: organizer reads own" ON public.tracks
  USING (((submitted_by = (select auth.uid())) AND (EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = (select auth.uid())) AND (profiles.role = ANY (ARRAY['track_organizer'::app_role, 'admin'::app_role])))))));

ALTER POLICY "tracks: organizer updates own draft" ON public.tracks
  USING (((submitted_by = (select auth.uid())) AND (approval_status = ANY (ARRAY['draft'::approval_status, 'pending'::approval_status])) AND (EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = (select auth.uid())) AND (profiles.role = ANY (ARRAY['track_organizer'::app_role, 'admin'::app_role])))))))
  WITH CHECK (((submitted_by = (select auth.uid())) AND (approval_status = ANY (ARRAY['draft'::approval_status, 'pending'::approval_status])) AND (is_public = false)));

ALTER POLICY "user_badges: owner reads own" ON public.user_badges
  USING ((user_id = (select auth.uid())));

ALTER POLICY "user_build_votes: authenticated votes" ON public.user_build_votes
  WITH CHECK ((((select auth.uid()) = user_id) AND (EXISTS ( SELECT 1
   FROM user_builds b
  WHERE ((b.id = user_build_votes.build_id) AND (b.is_public = true) AND (b.owner_id IS DISTINCT FROM (select auth.uid())))))));

ALTER POLICY "user_build_votes: owner removes own vote" ON public.user_build_votes
  USING (((select auth.uid()) = user_id));

ALTER POLICY "user_builds: owner deletes" ON public.user_builds
  USING ((owner_id = (select auth.uid())));

ALTER POLICY "user_builds: owner inserts" ON public.user_builds
  WITH CHECK ((owner_id = (select auth.uid())));

ALTER POLICY "user_builds: owner reads all" ON public.user_builds
  USING ((owner_id = (select auth.uid())));

ALTER POLICY "user_builds: owner updates" ON public.user_builds
  USING ((owner_id = (select auth.uid())))
  WITH CHECK ((owner_id = (select auth.uid())));

ALTER POLICY "Users can insert own consents" ON public.user_consents
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "Users can read own consents" ON public.user_consents
  USING (((select auth.uid()) = user_id));

ALTER POLICY "Users can update own consents" ON public.user_consents
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));

ALTER POLICY "user_pitcoin_balances: owner reads own" ON public.user_pitcoin_balances
  USING ((user_id = (select auth.uid())));
