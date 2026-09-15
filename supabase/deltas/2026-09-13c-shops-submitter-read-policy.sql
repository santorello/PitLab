-- ============================================================================
-- PitLap — Policy di lettura per chi propone un negozio (2026-09-13)
--
-- DIFETTO CHIUSO (trovato nel gate E2E profilo negozio su prod):
--   "new row violates row-level security policy for table shops" (42501)
--   alla creazione di un negozio da parte di un utente shop_owner.
--
-- CAUSA: il client esegue `.insert(...).select(...).single()`, che diventa un
-- INSERT ... RETURNING. Con la RLS attiva Postgres applica anche le policy di
-- SELECT alla riga restituita. Su `shops` le uniche policy di lettura erano:
--   - "public can read public shops"  -> is_public AND approved
--   - "shop managers can manage shops" -> is_shop_manager(id) OR is_admin()
-- Una bozza appena creata non e' ne' pubblica ne' approvata, e il legame in
-- shop_managers viene creato dal trigger AFTER INSERT, che scatta troppo tardi
-- per la valutazione della RETURNING. Nessuna policy autorizzava la lettura,
-- quindi l'intera istruzione veniva annullata.
--
-- ASIMMETRIA CON tracks: la tabella `tracks` ha gia' "tracks: organizer reads
-- own" (submitted_by = auth.uid()). `shops` non aveva l'equivalente. E' per
-- questo che il difetto non era emerso: il test E2E del 2026-06-07 copriva il
-- profilo organizzatore pista, non quello negozio.
--
-- SECONDO SINTOMO CHIUSO DALLO STESSO FIX: EditableShopsRepository
-- .fetchOwnedAndManaged() filtra con .eq('submitted_by', userId); senza questa
-- policy il proponente non vedeva le proprie bozze nella schermata Gestione.
--
-- SCELTA: la condizione e' il solo `submitted_by = auth.uid()`, senza verifica
-- del ruolo. Chi ha inviato una proposta puo' sempre rileggerla, quale che sia
-- il suo ruolo: cosi' il fix copre anche un utente base che proponga un negozio
-- dal flusso "segnala un luogo". La policy di tracks aggiunge un controllo di
-- ruolo, ma qui sarebbe una restrizione senza guadagno di sicurezza.
--
-- DA APPLICARE SU ENTRAMBE LE ISTANZE: il difetto e' presente su dev e su prod.
-- Idempotente.
-- ============================================================================

begin;

drop policy if exists "shop submitters can read own shops" on public.shops;
create policy "shop submitters can read own shops"
  on public.shops
  for select
  to authenticated
  using (submitted_by = (select auth.uid()));

commit;
