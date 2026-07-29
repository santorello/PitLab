-- 2026-06-02 — Beta hardening: revoke EXECUTE inherited via PUBLIC
-- STATO: già applicato su pitlap-dev (migration: beta_security_revoke_public_execute)
--
-- Root cause: la migration 2026-05-23b aveva revocato EXECUTE da anon/authenticated
-- esplicitamente sui 19 trigger PitCoin, MA il GRANT di default a PUBLIC era rimasto,
-- quindi anon/authenticated lo ereditavano comunque (il linter Supabase continuava a
-- segnalare anon/authenticated_security_definer_function_executable).
-- Fix corretto: REVOKE ... FROM PUBLIC. I trigger non necessitano EXECUTE diretto:
-- vengono eseguiti come owner della tabella, non come il chiamante.
--
-- Inoltre: is_admin/is_shop_manager/is_track_manager sono helper usati SOLO nelle policy
-- RLS (0 chiamate RPC dal client Flutter, verificato via grep) -> revocati anche da authenticated.
-- get_public_track_arrival_summary resta callable da anon (guest-facing, intenzionale).

DO $$
DECLARE fn record;
BEGIN
  FOR fn IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname LIKE 'trg_pitcoin%'
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon, authenticated;', fn.sig);
  END LOOP;
END $$;

REVOKE EXECUTE ON FUNCTION public.is_admin() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.is_shop_manager(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.is_track_manager(uuid) FROM PUBLIC, anon, authenticated;
