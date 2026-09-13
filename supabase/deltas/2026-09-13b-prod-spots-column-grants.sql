-- ============================================================================
-- PitLap — Ripristino grant di COLONNA su public.spots (2026-09-13)
--
-- CORREGGE UNA REGRESSIONE INTRODOTTA DA 2026-09-13-prod-grants-alignment.sql.
--
-- Cosa e' successo: quel delta inizia con
--     revoke all on all tables in schema public from anon, authenticated;
-- che azzera anche i privilegi concessi a livello di COLONNA. Le ri-concessioni
-- successive erano tutte a livello di tabella, piu' il solo grant di colonna
-- del keepalive. `spots` e' l'unica tabella dello schema i cui permessi su dev
-- sono definiti per colonna e non per tabella, quindi e' rimasta senza NULLA:
-- su prod ne' anon ne' authenticated potevano piu' nemmeno leggerla, e la
-- feature Spot sarebbe risultata vuota o in errore.
--
-- Verificato dopo l'incidente: confrontando tutti i privilegi di colonna di
-- dev e prod, `spots` era l'unica differenza. Nessun'altra tabella colpita.
--
-- Perche' su spots i grant sono per colonna: `owner_id` e' deliberatamente
-- ESCLUSO dal SELECT (chi ha creato uno spot non e' informazione pubblica) ma
-- INCLUSO nell'INSERT (serve a scrivere la proprieta' alla creazione).
-- Le colonne gestite dal database — id, created_at, updated_at, slug — sono
-- fuori dall'UPDATE. Da qui i tre insiemi diversi: 18 / 16 / 13.
--
-- Idempotente.
-- ============================================================================

begin;

-- SELECT: tutte le colonne tranne owner_id.
grant select (
  address, best_for, category, city, created_at, id, image_accent, image_urls,
  is_custom, latitude, longitude, note, photo_count, slug, surface, title,
  updated_at, video_url
) on public.spots to anon, authenticated;

-- INSERT: include owner_id e slug, esclude i timestamp e l'id generati dal DB.
grant insert (
  address, best_for, category, city, image_accent, image_urls, is_custom,
  latitude, longitude, note, owner_id, photo_count, slug, surface, title,
  video_url
) on public.spots to authenticated;

-- UPDATE: solo i campi di contenuto. Niente owner_id, slug, id o timestamp.
grant update (
  address, best_for, category, city, image_accent, image_urls, latitude,
  longitude, note, photo_count, surface, title, video_url
) on public.spots to authenticated;

commit;

-- ----------------------------------------------------------------------------
-- Il DELETE di tabella per authenticated e' gia' stato concesso dal delta
-- precedente e non va ripetuto.
--
-- LEZIONE, per i prossimi allineamenti: `revoke all on all tables` cancella
-- anche i grant di colonna, che NON compaiono in information_schema
-- .role_table_grants (solo in .column_privileges). Un allineamento generato
-- leggendo solo i grant di tabella li perde silenziosamente.
-- ----------------------------------------------------------------------------
