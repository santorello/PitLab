-- PitLap bots (Pit & Lap) — SOLO PROD (klfjvyytubiorqzfisdu), applicato 2026-11-01 via MCP.
-- Migrazioni prod: pitlap_bots, pitlap_bots_accounts, pitlap_bot_run.
--  * tabella privata public.pitlap_bots (profile_id, handle)
--  * 2 account auth senza password: pit@bot.pitlap.app = Reginaldo90 (/u/reginaldo90), lap@bot.pitlap.app = bootstrap68 (/u/bootstrap68) — rinominati 2026-11-01 (migrazione pitlap_bots_rename)
--  * testi riscritti naturali senza emoji, negozio del giorno solo RC (migrazione pitlap_bots_natural_texts); nessun riferimento "bot" visibile agli utenti
--  * award_pitcoin: return se l'utente e' in pitlap_bots
--  * public.pitlap_bot_run('pit'|'lap')  -> sorgente: select pg_get_functiondef('public.pitlap_bot_run(text)'::regprocedure);
--  * cron: pitlap_bot_tick ogni 10 min -> pitlap_bot_tick(): Reginaldo90 una volta tra 8:00-11:00, bootstrap68 tra 17:30-21:30 (ora Roma, orario da hash(handle,data), colonna pitlap_bots.last_run_on)
--  * like: Reginaldo90 ~70%, bootstrap68 ~50% delle build vere (decisione fissa per build), max 1 per giro; bootstrap68 mette like sempre alla build che commenta

-- DA ESEGUIRE (in sospeso): togliere i 2x20 PitCoin profile_made_public presi prima del blocco bot
delete from public.pitcoin_transactions where user_id in (select profile_id from public.pitlap_bots);
delete from public.user_badges          where user_id in (select profile_id from public.pitlap_bots);
delete from public.user_pitcoin_balances where user_id in (select profile_id from public.pitlap_bots);

-- Pausa:    select cron.unschedule('pitlap_bot_tick');
-- Prova:    select public.pitlap_bot_run('pit'); select public.pitlap_bot_run('lap');
-- ROLLBACK totale (prima cancellare community_events, entity_comments, user_builds con author_id/owner_id dei bot se le FK non sono ON DELETE CASCADE):
--   select cron.unschedule('pitlap_bot_tick'); drop function public.pitlap_bot_tick();
--   delete from auth.users where id in (select profile_id from public.pitlap_bots);
--   drop function public.pitlap_bot_run(text); drop table public.pitlap_bots;  -- poi rimuovere la riga bot da award_pitcoin
