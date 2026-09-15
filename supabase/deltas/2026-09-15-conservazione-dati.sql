-- ============================================================================
-- PitLap — Conservazione dei dati: i check-in vengono davvero cancellati
--          e le richieste di cancellazione account diventano visibili
--          (2026-09-15)
--
-- PROBLEMA: l'informativa privacy dichiarava tre periodi di conservazione che
-- nessun meccanismo applicava.
--
--   1. "Le presenze in pista vengono rimosse automaticamente dopo 1 giorno":
--      falso. Su dev c'erano check-in del 12 aprile, cinque mesi prima. Le
--      query li filtrano con arrival_date = oggi, quindi SPARISCONO DALLA VISTA
--      il giorno dopo, ma la riga resta a database per sempre. Chi ha scritto
--      il testo ha descritto cio' che vede l'utente, non cio' che succede al
--      dato.
--
--   2. "I dati personali vengono eliminati entro 30 giorni dalla richiesta":
--      request_account_deletion si limita a scrivere deletion_requested_at.
--      Niente cancella e, soprattutto, niente avvisa il titolare che esiste una
--      richiesta da evadere. Obbligo dell'art. 17 GDPR, di fatto inapplicato.
--
--   3. "Log tecnici: 90 giorni": PitLap non ha log propri. Quelli di
--      piattaforma li conserva Supabase secondo il piano. Corretto nei testi.
--
-- Nessuna delle due estensioni pg_cron / pg_net e' installata sul progetto,
-- quindi la pulizia periodica viene chiamata dalla GitHub Action giornaliera
-- che gia' esiste per il keepalive.
--
-- Idempotente.
-- ============================================================================

begin;

-- ── 1. Pulizia dei check-in scaduti ─────────────────────────────────────────

-- Cancella i check-in riferiti a giorni passati. Un check-in di oggi
-- sopravvive fino a domani: e' esattamente cio' che l'informativa promette.
--
-- NOTA SUI PERMESSI, da leggere prima di modificare: la funzione e'
-- eseguibile da `anon` perche' viene chiamata dalla GitHub Action giornaliera,
-- che usa la anon key (la stessa gia' usata per il keepalive) ed evita cosi' di
-- tenere una service role key nei secret di CI.
--
-- E' sicura solo perche' NON HA PARAMETRI e il predicato e' fisso: puo'
-- cancellare unicamente righe con arrival_date < current_date, cioe' dati che
-- secondo l'informativa non dovrebbero piu' esistere e che l'app non mostra
-- comunque. Chiamarla mille volte non fa danno ed e' idempotente.
--
-- NON aggiungere un parametro "giorni" e NON allargare il predicato: con un
-- parametro, chiunque abbia la anon key (che e' pubblica, sta nel bundle web)
-- potrebbe cancellare i check-in di oggi.
create or replace function public.cleanup_expired_arrivals()
returns integer
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_deleted integer;
begin
  delete from public.arrivals
   where arrival_date < current_date;
  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$function$;

revoke all on function public.cleanup_expired_arrivals() from public;
grant execute on function public.cleanup_expired_arrivals() to anon, authenticated;

-- Riallineamento: rimuove lo storico accumulato finora.
select public.cleanup_expired_arrivals();

-- ── 2. Le richieste di cancellazione account diventano visibili all'admin ────

-- Senza questa, una richiesta ex art. 17 restava un campo in una tabella che
-- nessuno guardava. Ora compare nella dashboard admin con i giorni trascorsi,
-- cosi' il titolare sa cosa deve evadere ed entro quando.
create or replace function public.admin_pending_account_deletions()
returns table (
  user_id uuid,
  display_name text,
  requested_at timestamptz,
  giorni_trascorsi integer
)
language sql
security definer
set search_path to 'public'
as $function$
  select
    p.id,
    coalesce(nullif(trim(p.display_name), ''), 'Senza nome'),
    p.deletion_requested_at,
    extract(day from (now() - p.deletion_requested_at))::integer
  from public.profiles p
  where p.deletion_requested_at is not null
    and public.is_admin()
  order by p.deletion_requested_at;
$function$;

revoke all on function public.admin_pending_account_deletions() from public, anon;
grant execute on function public.admin_pending_account_deletions() to authenticated;

commit;

-- ----------------------------------------------------------------------------
-- La cancellazione vera e propria dell'account resta un'operazione manuale del
-- titolare: rimuovere la riga in auth.users richiede la Admin API, non
-- raggiungibile dal client. Questo delta rende la richiesta VISIBILE e
-- databile; l'informativa descrive correttamente un intervento del titolare
-- entro 30 giorni.
--
-- Verificato su dev il 2026-09-15.
-- ----------------------------------------------------------------------------
