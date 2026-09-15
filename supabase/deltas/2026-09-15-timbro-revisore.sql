-- ============================================================================
-- PitLap — Chi ha deciso l'approvazione viene registrato (2026-09-15)
--
-- PROBLEMA (difetto A-27 dell'audit): approvando una scheda che l'admin aveva
-- inviato lui stesso, l'admin riceveva una notifica di approvazione da se'
-- stesso. Inoltre nessuna notifica di approvazione aveva `created_by`
-- valorizzato, quindi si perdeva la traccia di chi aveva deciso.
--
-- CAUSA: `updateTrackApproval` / `updateShopApproval` nel client scrivono solo
-- `approval_status` (e `is_public`). `reviewed_by` e `reviewed_at` restavano
-- NULL. Il trigger trg_notify_approval_decided usa `new.reviewed_by` sia come
-- autore della notifica sia nella guardia
--   `new.submitted_by is not distinct from new.reviewed_by`
-- che serve proprio a non notificare chi ha deciso da solo. Con reviewed_by
-- NULL la guardia non scattava mai e l'autore risultava sconosciuto.
--
-- SOLUZIONE: timbrare revisore e data a database, non nel client. Cosi' vale
-- per ogni percorso di scrittura (UI admin, SQL manuale, futuri endpoint) e
-- non e' falsificabile dal client.
--
-- Il trigger e' BEFORE UPDATE, mentre trg_notify_approval_decided e' AFTER:
-- quando la notifica viene costruita, reviewed_by e' gia' valorizzato.
--
-- Idempotente.
-- ============================================================================

begin;

create or replace function public.trg_stamp_review_author()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.approval_status is distinct from old.approval_status
     and new.approval_status in ('approved', 'rejected') then
    -- Se il chiamante ha gia' indicato esplicitamente il revisore lo si
    -- rispetta; altrimenti si usa l'utente della sessione.
    if new.reviewed_by is not distinct from old.reviewed_by then
      new.reviewed_by := auth.uid();
    end if;
    if new.reviewed_at is not distinct from old.reviewed_at then
      new.reviewed_at := now();
    end if;
  end if;
  return new;
end;
$function$;

drop trigger if exists trg_stamp_review_author on public.tracks;
create trigger trg_stamp_review_author
  before update on public.tracks
  for each row execute function public.trg_stamp_review_author();

drop trigger if exists trg_stamp_review_author on public.shops;
create trigger trg_stamp_review_author
  before update on public.shops
  for each row execute function public.trg_stamp_review_author();

commit;

-- ----------------------------------------------------------------------------
-- Verificato su dev il 2026-09-15:
--   · approvazione di una scheda altrui  → reviewed_by = admin, notifica al
--     proprietario, created_by valorizzato
--   · approvazione di una scheda propria → nessuna notifica creata
-- ----------------------------------------------------------------------------
