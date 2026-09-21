-- Igiene di sicurezza dopo l'audit del 2026-09-22 (advisor Supabase + controlli manuali).
-- Nessuna falla aperta: sono tre riduzioni di superficie.

-- 1. search_path fisso anche su moderation_normalize (unica funzione rimasta senza).
alter function public.moderation_normalize(text) set search_path = public;

-- 2. Le funzioni-trigger della moderazione erano chiamabili come RPC da chiunque.
--    Chiamarle a mano fallisce comunque, ma non c'e' motivo di esporle: i trigger
--    scattano lo stesso, Postgres non controlla EXECUTE quando esegue un trigger.
revoke execute on function public.moderation_guard() from public, anon, authenticated;
revoke execute on function public.moderation_guard_suggestion() from public, anon, authenticated;

-- 3. cleanup_expired_arrivals cancella gli arrivi scaduti ed era invocabile da
--    anonimi via /rest/v1/rpc. Il client non la usa: la tolgo ai ruoli esposti.
revoke execute on function public.cleanup_expired_arrivals() from public, anon, authenticated;

select p.proname, has_function_privilege('anon', p.oid, 'EXECUTE') anon_exec,
       array_to_string(p.proconfig, ',') config
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('moderation_normalize','moderation_guard','moderation_guard_suggestion','cleanup_expired_arrivals');
