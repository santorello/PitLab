-- 2026-09-16 — Eventi community: coordinate del luogo (prima solo testo).
-- Grant di tabella (non per colonna) → nessun grant extra. Idempotente.
-- Eseguibile su prod anche prima del deploy: la build vecchia non usa le colonne.
alter table public.community_events
  add column if not exists latitude  double precision,
  add column if not exists longitude double precision;

-- Verifica (atteso: 2)
select count(*) from information_schema.columns
where table_schema = 'public' and table_name = 'community_events'
  and column_name in ('latitude', 'longitude');
