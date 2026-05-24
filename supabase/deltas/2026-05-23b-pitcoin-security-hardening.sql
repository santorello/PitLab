-- ────────────────────────────────────────────────────────────────────────────
-- 2026-05-23 (b) — PitCoin: security hardening dei trigger SECURITY DEFINER
-- ────────────────────────────────────────────────────────────────────────────
-- Riferimento: docs/pitcoin-system.md §6 + advisor Supabase
--               anon_security_definer_function_executable.
--
-- Cosa fa:
--   Revoca EXECUTE da anon e authenticated su tutte le 19 trigger function
--   PitCoin (`trg_pitcoin_*`). Sono SECURITY DEFINER perche' devono scrivere
--   nel ledger bypassando RLS, ma il loro return type e' `trigger`: non sono
--   richiamabili come RPC da PostgREST. Il default GRANT EXECUTE a
--   anon/authenticated era dunque privilegio inutile (defense in depth).
--
-- Cosa NON fa:
--   - Non tocca le funzioni core (award_pitcoin, check_badge_unlocks,
--     recompute_user_balance, award_pitcoin_backfill) — gia' blindate nel
--     delta primario `2026-05-23-pitcoin-system.sql`.
--   - Non altera RLS, tabelle o seed.
--
-- Applicato 2026-05-23 a pitlap-dev via MCP apply_migration con nome
-- "pitcoin_security_hardening_revoke_trigger_exec". Idempotente.
-- ────────────────────────────────────────────────────────────────────────────

revoke execute on function public.trg_pitcoin_after_ledger_insert()              from anon, authenticated;
revoke execute on function public.trg_pitcoin_arrivals_after_insert()            from anon, authenticated;
revoke execute on function public.trg_pitcoin_community_events_after_insert()    from anon, authenticated;
revoke execute on function public.trg_pitcoin_event_rsvps_after_insert()         from anon, authenticated;
revoke execute on function public.trg_pitcoin_events_after_insert()              from anon, authenticated;
revoke execute on function public.trg_pitcoin_external_links_after_insert()      from anon, authenticated;
revoke execute on function public.trg_pitcoin_profiles_after_update()            from anon, authenticated;
revoke execute on function public.trg_pitcoin_shop_follows_after_insert()        from anon, authenticated;
revoke execute on function public.trg_pitcoin_shops_after_insert()               from anon, authenticated;
revoke execute on function public.trg_pitcoin_shops_after_update()               from anon, authenticated;
revoke execute on function public.trg_pitcoin_spots_after_insert()               from anon, authenticated;
revoke execute on function public.trg_pitcoin_track_follows_after_insert()       from anon, authenticated;
revoke execute on function public.trg_pitcoin_track_services_after_update()      from anon, authenticated;
revoke execute on function public.trg_pitcoin_track_status_history_after_insert() from anon, authenticated;
revoke execute on function public.trg_pitcoin_tracks_after_insert()              from anon, authenticated;
revoke execute on function public.trg_pitcoin_tracks_after_update()              from anon, authenticated;
revoke execute on function public.trg_pitcoin_user_builds_after_insert()         from anon, authenticated;
revoke execute on function public.trg_pitcoin_user_builds_after_update()         from anon, authenticated;
revoke execute on function public.trg_pitcoin_user_consents_after_change()       from anon, authenticated;
