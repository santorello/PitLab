-- 2026-09-16 — P1 sicurezza: blocca l'auto-promozione di ruolo su public.profiles
-- Problema (verificato su dev E prod): policy UPDATE "id = auth.uid()" + grant UPDATE su tutte
-- le colonne → un utente loggato può fare PATCH /rest/v1/profiles {role:'admin'} sulla propria riga
-- e is_admin() lo considera admin.
-- Regole del guard (solo per chiamate dirette dei ruoli client anon/authenticated):
--   * admin: può cambiare qualunque ruolo (pannello Admin).
--   * non-admin: unica transizione ammessa 'user' -> 'shop_owner' | 'track_organizer'
--     (intenzione di ruolo alla registrazione, come complete_onboarding).
--   * INSERT non-admin: ruolo ammesso solo user/shop_owner/track_organizer.
-- Le funzioni SECURITY DEFINER (complete_onboarding, handle_new_user) girano come owner
-- e non sono toccate dal guard. Idempotente. Da eseguire su dev e poi su prod.

create or replace function public.guard_profile_role()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if current_user not in ('anon', 'authenticated') then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.role::text not in ('user', 'shop_owner', 'track_organizer') and not public.is_admin() then
      raise exception 'Ruolo non consentito' using errcode = '42501';
    end if;
    return new;
  end if;

  if new.role is distinct from old.role and not public.is_admin() then
    if not (old.role::text = 'user' and new.role::text in ('shop_owner', 'track_organizer')) then
      raise exception 'Cambio di ruolo non consentito' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

revoke execute on function public.guard_profile_role() from public, anon, authenticated;

drop trigger if exists trg_guard_profile_role on public.profiles;
create trigger trg_guard_profile_role
  before insert or update of role on public.profiles
  for each row execute function public.guard_profile_role();

-- Verifica (atteso: 1 riga)
select tgname from pg_trigger
where tgrelid = 'public.profiles'::regclass and tgname = 'trg_guard_profile_role';
