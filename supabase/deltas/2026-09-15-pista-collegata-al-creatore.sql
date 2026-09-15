-- ============================================================================
-- PitLap — La pista appena inviata risulta subito del suo creatore (2026-09-15)
--
-- PROBLEMA (difetto A-14 dell'audit): un gestore che crea una pista da
-- "Gestione" vede "Nessuna pista assegnata" finche' un admin non la approva.
-- Non puo' quindi rientrare nella scheda per correggerla o completarla.
--
-- CAUSA: il collegamento in `track_managers` veniva creato solo dal trigger
-- `trg_auto_link_track_manager`, che e' AFTER UPDATE e scatta esclusivamente
-- al passaggio ad 'approved'. La schermata Gestione legge le piste tramite
-- `track_managers`, quindi in stato pending non c'e' nulla da mostrare.
--
-- Da notare che i NEGOZI facevano gia' la cosa giusta: esiste
-- `shops_auto_link_manager_on_insert`, AFTER INSERT. Le due entita' erano
-- semplicemente incoerenti.
--
-- SOLUZIONE: stesso trigger AFTER INSERT anche per le piste, piu' un
-- riallineamento delle piste gia' inviate e rimaste scollegate.
--
-- Nota sui permessi: essere in track_managers non permette di auto-approvarsi.
-- `guard_track_moderation_columns` continua a impedire ai non-admin di
-- modificare is_public, submitted_by e approval_status fuori da draft/pending.
--
-- Il vecchio trigger sull'approvazione resta: copre il caso di una pista
-- inserita senza submitted_by e valorizzata in un secondo momento.
--
-- Idempotente.
-- ============================================================================

begin;

create or replace function public.auto_link_track_manager_on_insert()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.submitted_by is not null then
    insert into public.track_managers (track_id, user_id, granted_by)
    values (new.id, new.submitted_by, new.submitted_by)
    on conflict do nothing;
  end if;
  return new;
end;
$function$;

drop trigger if exists trg_auto_link_track_manager_on_insert on public.tracks;
create trigger trg_auto_link_track_manager_on_insert
  after insert on public.tracks
  for each row execute function public.auto_link_track_manager_on_insert();

-- Riallineamento delle piste gia' presenti.
insert into public.track_managers (track_id, user_id, granted_by)
select t.id, t.submitted_by, t.submitted_by
from public.tracks t
where t.submitted_by is not null
  and not exists (
    select 1 from public.track_managers m
    where m.track_id = t.id and m.user_id = t.submitted_by
  )
on conflict do nothing;

commit;

-- ----------------------------------------------------------------------------
-- Verificato su dev il 2026-09-15: inserita una pista 'pending' con
-- submitted_by valorizzato, il collegamento in track_managers c'era subito.
-- Pista di prova poi eliminata.
-- ----------------------------------------------------------------------------
