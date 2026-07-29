-- ============================================================================
-- PitLap — Policy RLS per tassonomie su bozze pista (D08/D09)
-- 2026-06-10
--
-- Problema: track_services e track_category_links consentono la scrittura
-- solo a is_track_manager(track_id) OR is_admin().
-- is_track_manager usa la tabella track_managers, che viene popolata dal
-- trigger trg_auto_link_track_manager SOLO quando la pista viene approvata.
-- Quindi il submitter NON può scrivere servizi/categorie su una bozza:
-- non esiste ancora un record in track_managers per lui.
--
-- Soluzione: aggiungere su entrambe le tabelle una policy separata che
-- autorizza il submitter originale mentre la pista è in stato draft/pending.
-- Condizione: tracks.submitted_by = auth.uid()
--             AND tracks.approval_status IN ('draft','pending')
--
-- NOTA RLS: le policy permissive vengono valutate con OR tra di loro;
-- aggiungere questa policy non altera le policy esistenti per i gestori.
--
-- Idempotente: DROP POLICY IF EXISTS prima di CREATE.
-- NON applicare automaticamente: questo file viene eseguito manualmente
-- dall'operatore DB dopo revisione.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- track_services — policy per il submitter su bozze/pending
-- ----------------------------------------------------------------------------

drop policy if exists "submitter can manage own draft track services" on public.track_services;

create policy "submitter can manage own draft track services"
  on public.track_services
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.tracks t
      where t.id = track_services.track_id
        and t.submitted_by = (select auth.uid())
        and t.approval_status in ('draft', 'pending')
    )
  )
  with check (
    exists (
      select 1
      from public.tracks t
      where t.id = track_services.track_id
        and t.submitted_by = (select auth.uid())
        and t.approval_status in ('draft', 'pending')
    )
  );

-- ----------------------------------------------------------------------------
-- track_category_links — policy per il submitter su bozze/pending
-- ----------------------------------------------------------------------------

drop policy if exists "submitter can manage own draft track category links" on public.track_category_links;

create policy "submitter can manage own draft track category links"
  on public.track_category_links
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.tracks t
      where t.id = track_category_links.track_id
        and t.submitted_by = (select auth.uid())
        and t.approval_status in ('draft', 'pending')
    )
  )
  with check (
    exists (
      select 1
      from public.tracks t
      where t.id = track_category_links.track_id
        and t.submitted_by = (select auth.uid())
        and t.approval_status in ('draft', 'pending')
    )
  );

commit;
