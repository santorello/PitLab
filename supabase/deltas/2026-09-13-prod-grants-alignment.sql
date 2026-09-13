-- ============================================================================
-- PitLap — Allineamento grant di tabella su prod (2026-09-13)
--
-- TROVATO DAL CONFRONTO dev<->prod del 2026-09-13. Struttura (tabelle, viste,
-- funzioni, policy, trigger, indici, enum) risultava identica: impronte md5
-- coincidenti su tutte e sette le categorie. I GRANT di tabella no.
--
-- Su prod 48 oggetti su 49 avevano ancora i grant di DEFAULT di Supabase, cioe'
--   anon, authenticated: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE
-- mentre su dev l'hardening di giugno 2026 li aveva ristretti (anon in sola
-- lettura sulle tabelle core, viste SELECT-only). La baseline di prod e' del
-- 2026-06-02 e quell'hardening non e' mai stato replicato.
--
-- Impatto reale: la RLS resta la difesa primaria e continuava a proteggere i
-- dati; questo ripristina il secondo strato (privilegio) che dev aveva e prod
-- no. Rilevante soprattutto su profiles / tracks / shops / user_consents, dove
-- anon aveva privilegi di scrittura a livello di GRANT.
--
-- Metodo: revoca totale e ri-concessione esatta di cio' che e' stato letto da
-- pitlap-dev, cosi' le due istanze finiscono bit per bit sullo stesso profilo.
--
-- NOTA: dev non e' uniforme — gli oggetti nati DOPO l'hardening di giugno
-- (entity_comments, feedback, profile_follows, user_build_votes,
-- weekly_featured_builds, pitcoin_*_definitions, home_*) hanno ancora i grant
-- larghi anche li'. Questo file replica dev com'e', inconsistenza inclusa:
-- e' un'operazione di PARITA', non una riprogettazione della sicurezza.
-- Stringere anche quelli e' un intervento separato, da fare su entrambe le
-- istanze e da testare. Vedi docs/go-live-checklist.md.
--
-- Idempotente.
-- ============================================================================

begin;

revoke all on all tables in schema public from anon, authenticated;

grant SELECT on public.activity_feed to anon;
grant SELECT on public.activity_feed to authenticated;
grant SELECT on public.approval_requests to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.approval_requests to authenticated;
grant SELECT on public.arrivals to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.arrivals to authenticated;
grant SELECT on public.community_events to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.community_events to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.entity_comment_counts to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.entity_comment_counts to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.entity_comment_reports to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.entity_comment_reports to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.entity_comments to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.entity_comments to authenticated;
grant SELECT on public.event_rsvps to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.event_rsvps to authenticated;
grant SELECT on public.events to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.events to authenticated;
grant SELECT on public.external_links to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.external_links to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.feedback to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.feedback to authenticated;
grant SELECT on public.home_build_of_week to anon;
grant SELECT on public.home_build_of_week to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.home_featured_track to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.home_featured_track to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.home_overview_stats to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.home_overview_stats to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.home_trending_tracks to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.home_trending_tracks to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE on public.keepalive to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.keepalive to authenticated;
grant SELECT on public.notification_recipients to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.notification_recipients to authenticated;
grant SELECT on public.notifications to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.notifications to authenticated;
grant SELECT on public.organization_memberships to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.organization_memberships to authenticated;
grant SELECT on public.organizations to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.organizations to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.pitcoin_action_definitions to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.pitcoin_action_definitions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.pitcoin_badge_definitions to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.pitcoin_badge_definitions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.pitcoin_public_leaderboard to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.pitcoin_public_leaderboard to authenticated;
grant REFERENCES, SELECT, TRIGGER, TRUNCATE on public.pitcoin_transactions to anon;
grant REFERENCES, SELECT, TRIGGER, TRUNCATE on public.pitcoin_transactions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_follows to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_follows to authenticated;
grant SELECT on public.profiles to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.profiles to authenticated;
grant SELECT on public.public_spots to anon;
grant SELECT on public.public_spots to authenticated;
grant SELECT on public.public_user_badges to anon;
grant SELECT on public.public_user_badges to authenticated;
grant SELECT on public.public_user_pitcoin to anon;
grant SELECT on public.public_user_pitcoin to authenticated;
grant SELECT on public.service_types to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.service_types to authenticated;
grant SELECT on public.shop_follows to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.shop_follows to authenticated;
grant SELECT on public.shop_managers to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.shop_managers to authenticated;
grant SELECT on public.shops to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.shops to authenticated;
grant DELETE on public.spots to authenticated;
grant SELECT on public.track_categories to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.track_categories to authenticated;
grant SELECT on public.track_category_links to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.track_category_links to authenticated;
grant SELECT on public.track_follows to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.track_follows to authenticated;
grant SELECT on public.track_managers to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.track_managers to authenticated;
grant SELECT on public.track_media to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.track_media to authenticated;
grant SELECT on public.track_services to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.track_services to authenticated;
grant SELECT on public.track_status_current to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.track_status_current to authenticated;
grant SELECT on public.track_status_history to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.track_status_history to authenticated;
grant SELECT on public.tracks to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.tracks to authenticated;
grant REFERENCES, SELECT, TRIGGER, TRUNCATE on public.user_badges to anon;
grant REFERENCES, SELECT, TRIGGER, TRUNCATE on public.user_badges to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_build_votes to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_build_votes to authenticated;
grant SELECT on public.user_builds to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.user_builds to authenticated;
grant SELECT on public.user_consents to anon;
grant DELETE, INSERT, SELECT, UPDATE on public.user_consents to authenticated;
grant REFERENCES, SELECT, TRIGGER, TRUNCATE on public.user_pitcoin_balances to anon;
grant REFERENCES, SELECT, TRIGGER, TRUNCATE on public.user_pitcoin_balances to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.weekly_featured_builds to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.weekly_featured_builds to authenticated;

-- Grant di COLONNA: la GitHub Action di keepalive aggiorna solo checked_at con
-- la anon key. Va ri-concesso esplicitamente perche' il revoke all lo azzera.
grant update (checked_at) on public.keepalive to anon;

commit;
