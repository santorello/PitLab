-- ============================================================================
-- PitLap — Prod alignment delta (2026-06-10)
-- Replica su pitlap-prod (klfjvyytubiorqzfisdu) dei fix validati su pitlap-dev
-- durante il test E2E organizzatore del 2026-06-07.
-- Contenuto: D01, D05, D10, D11 (vedi qa-temp/e2e-test-organizer-2026-06-07.md)
-- Idempotente: ri-eseguibile senza effetti collaterali.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- D01 — complete_onboarding: rimozione overload ambigui + canonico a 7 arg
-- Causa: PGRST203 "Could not choose the best candidate function".
-- ----------------------------------------------------------------------------

drop function if exists public.complete_onboarding(text);
drop function if exists public.complete_onboarding(text, text[]);
drop function if exists public.complete_onboarding(text, text[], text, text, double precision, double precision);

create or replace function public.complete_onboarding(
  p_preferred_city text default ''::text,
  p_user_interests text[] default '{}'::text[],
  p_home_city text default null::text,
  p_home_country text default null::text,
  p_home_latitude double precision default null::double precision,
  p_home_longitude double precision default null::double precision,
  p_role text default null::text
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_current_role public.app_role;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select role into v_current_role from public.profiles where id = auth.uid();

  update public.profiles
  set
    preferred_city = coalesce(nullif(trim(p_preferred_city), ''), preferred_city),
    home_city = coalesce(nullif(trim(p_home_city), ''), home_city),
    home_country = coalesce(nullif(trim(p_home_country), ''), home_country),
    home_latitude = coalesce(p_home_latitude, home_latitude),
    home_longitude = coalesce(p_home_longitude, home_longitude),
    user_interests = case
      when array_length(p_user_interests, 1) > 0 then p_user_interests
      else user_interests
    end,
    -- Imposta il ruolo solo se valido (no self-admin) e senza declassare un admin.
    role = case
      when v_current_role = 'admin' then role
      when p_role in ('user', 'shop_owner', 'track_organizer') then p_role::public.app_role
      else role
    end,
    onboarding_completed = true,
    onboarding_completed_at = coalesce(onboarding_completed_at, now()),
    updated_at = now()
  where id = auth.uid();
end;
$function$;

revoke execute on function public.complete_onboarding(text, text[], text, text, double precision, double precision, text) from public, anon;
grant execute on function public.complete_onboarding(text, text[], text, text, double precision, double precision, text) to authenticated;

-- ----------------------------------------------------------------------------
-- D05 — ripristino EXECUTE sui role helper SECURITY DEFINER
-- Causa: hardening 2026-06-02 aveva revocato EXECUTE da PUBLIC senza
-- ri-concederlo a authenticated/anon. Gli helper sono usati dentro RLS policy
-- e view: senza grant l'intera esperienza autenticata fallisce con 42501.
-- ----------------------------------------------------------------------------

grant execute on function public.is_admin() to authenticated, anon;
grant execute on function public.is_shop_manager(uuid) to authenticated, anon;
grant execute on function public.is_track_manager(uuid) to authenticated, anon;

-- ----------------------------------------------------------------------------
-- D10 — policy RLS gestori su track_category_links
-- Causa: la tabella aveva solo "admins can manage": un track_organizer non
-- poteva salvare le categorie della propria pista.
-- ----------------------------------------------------------------------------

drop policy if exists "track managers can manage track category links" on public.track_category_links;
create policy "track managers can manage track category links"
  on public.track_category_links
  for all
  to authenticated
  using (is_track_manager(track_id) or is_admin())
  with check (is_track_manager(track_id) or is_admin());

-- ----------------------------------------------------------------------------
-- D11 — policy UPDATE per gestori su tracks approvate + guard moderazione
-- Causa: tracks non aveva una policy UPDATE per i gestori (track_managers)
-- sulle piste approvate: l'update della scheda falliva silenziosamente (0 righe).
-- Il guard trigger impedisce ai non-admin di alterare le colonne di moderazione
-- (approval_status / is_public / submitted_by), preservando il flusso
-- draft->pending del submitter.
-- ----------------------------------------------------------------------------

create or replace function public.guard_track_moderation_columns()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin() then
    -- visibility is admin-only
    new.is_public := old.is_public;
    new.submitted_by := old.submitted_by;
    -- moderation status: only draft<->pending allowed for non-admins
    if old.approval_status not in ('draft','pending')
       or new.approval_status not in ('draft','pending') then
      new.approval_status := old.approval_status;
    end if;
  end if;
  return new;
end;
$function$;

revoke execute on function public.guard_track_moderation_columns() from public, anon, authenticated;

drop trigger if exists trg_guard_track_moderation on public.tracks;
create trigger trg_guard_track_moderation
  before update on public.tracks
  for each row execute function public.guard_track_moderation_columns();

drop policy if exists "track managers update managed track" on public.tracks;
create policy "track managers update managed track"
  on public.tracks
  for update
  to authenticated
  using (is_track_manager(id))
  with check (is_track_manager(id));

commit;

-- ----------------------------------------------------------------------------
-- Post-applicazione (manuale, dashboard):
-- 1. Auth > Settings: abilitare "Leaked password protection" (dev e prod).
-- 2. Verificare advisor Supabase: i 42501 su is_admin/is_*_manager devono sparire.
-- ----------------------------------------------------------------------------
