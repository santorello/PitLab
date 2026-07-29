-- =============================================================================
-- Migration: beta_drop_duplicate_index
-- Date: 2026-06-02
-- Project: pitlap-dev (mqieterttnqdtdguaqoe)
-- Status: ALREADY APPLIED ON DEV
-- =============================================================================
-- Scopo: rimuove l'indice duplicato su community_events.author_id.
-- Situazione trovata: due indici identici (stessa colonna, stesso metodo btree):
--   - community_events_author_id_idx  ON public.community_events (author_id)
--   - community_events_author_idx     ON public.community_events (author_id)
-- Droppato: community_events_author_id_idx (ridondante)
-- Mantenuto: community_events_author_idx
-- =============================================================================

DROP INDEX IF EXISTS public.community_events_author_id_idx;
