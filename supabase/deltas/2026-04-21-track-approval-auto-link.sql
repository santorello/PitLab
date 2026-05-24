-- Delta: 2026-04-21 - Auto-link track_managers on track approval
-- Quando un admin approva una pista (approval_status → 'approved'),
-- questo trigger crea automaticamente il record in track_managers
-- per chi ha inviato la pista, in modo che appaia nel pannello Gestione.

create or replace function public.auto_link_track_manager_on_approval()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Agire solo quando approval_status passa a 'approved' da uno stato diverso
  if NEW.approval_status = 'approved' and OLD.approval_status <> 'approved' then
    -- Solo se esiste un submitter (potrebbe essere null se la pista è stata creata da admin direttamente)
    if NEW.submitted_by is not null then
      insert into public.track_managers (track_id, user_id)
      values (NEW.id, NEW.submitted_by)
      on conflict do nothing;  -- evita duplicati se già registrato manualmente
    end if;
  end if;
  return NEW;
end;
$$;

-- Rimuovi il trigger se esiste già (idempotente)
drop trigger if exists trg_auto_link_track_manager on public.tracks;

create trigger trg_auto_link_track_manager
  after update on public.tracks
  for each row
  execute function public.auto_link_track_manager_on_approval();

-- Nota: il trigger usa SECURITY DEFINER per poter scrivere in track_managers
-- anche quando l'operazione di UPDATE viene eseguita da un admin (che non è il submitter).
