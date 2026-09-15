-- ============================================================================
-- PitLap — Identita' utente: nome visibile sempre valorizzato (2026-09-14)
--
-- PROBLEMA: su prod tutti i profili avevano display_name NULL. La lista utenti
-- admin mostrava "(senza nome)" e le notifiche cadevano sul fallback
-- "Un utente". Su dev i nomi c'erano solo perche' arrivavano dai seed o da
-- modifiche manuali: nessun percorso di codice li scriveva.
--
-- CAUSA: handle_new_user inseriva solo l'id, e complete_onboarding non
-- toccava mai il nome. Il campo restava NULL per sempre.
--
-- COSA FA QUESTO DELTA:
--   1. handle_new_user legge nome e avatar dai metadati del provider (Google
--      riempie full_name / name e avatar_url / picture) e, se non ci sono,
--      assegna un nome neutro "Pilota <4 caratteri dell'id>".
--   2. complete_onboarding accetta p_display_name, cosi' l'onboarding puo'
--      chiedere Nome/Soprannome e salvarlo.
--   3. riempie i profili esistenti rimasti senza nome.
--
-- VINCOLO DA NON VIOLARE: display_name e' PUBBLICO (compare nei profili
-- pubblici, nei commenti, nelle notifiche). Non va MAI derivato dalla parte
-- locale dell'email, che esporrebbe l'indirizzo dell'utente.
--
-- Idempotente.
-- ============================================================================

begin;

-- ── 1. Nome e avatar alla creazione dell'utente ──────────────────────────────

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_name text;
  v_avatar text;
begin
  -- Google popola full_name/name e avatar_url/picture. Altri provider
  -- possono usare solo una delle due chiavi: le proviamo tutte.
  v_name := nullif(trim(coalesce(
    v_meta ->> 'full_name',
    v_meta ->> 'name',
    ''
  )), '');

  v_avatar := nullif(trim(coalesce(
    v_meta ->> 'avatar_url',
    v_meta ->> 'picture',
    ''
  )), '');

  -- Fallback neutro. NON usare split_part(new.email, '@', 1): display_name e'
  -- pubblico e l'email dell'utente non deve finire in chiaro nel profilo.
  if v_name is null then
    v_name := 'Pilota ' || substr(replace(new.id::text, '-', ''), 1, 4);
  end if;

  insert into public.profiles (id, display_name, avatar_url)
  values (new.id, v_name, v_avatar)
  on conflict (id) do nothing;

  return new;
end;
$function$;

-- ── 2. L'onboarding puo' salvare il nome ────────────────────────────────────

-- La vecchia firma a 7 argomenti va rimossa esplicitamente: aggiungendo un
-- parametro con default resterebbero due overload e ogni chiamata diventerebbe
-- ambigua ("function is not unique").
drop function if exists public.complete_onboarding(
  text, text[], text, text, double precision, double precision, text
);

create or replace function public.complete_onboarding(
  p_display_name text default null,
  p_preferred_city text default '',
  p_user_interests text[] default '{}',
  p_home_city text default null,
  p_home_country text default null,
  p_home_latitude double precision default null,
  p_home_longitude double precision default null,
  p_role text default null
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
    -- Solo se l'utente ha scritto qualcosa: un campo lasciato vuoto non deve
    -- cancellare il nome gia' presente.
    display_name = coalesce(
      nullif(trim(p_display_name), ''),
      display_name
    ),
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

grant execute on function public.complete_onboarding(
  text, text, text[], text, text, double precision, double precision, text
) to authenticated;

-- ── 3. Profili gia' esistenti rimasti senza nome ────────────────────────────

update public.profiles p
set display_name = coalesce(
      nullif(trim(coalesce(
        u.raw_user_meta_data ->> 'full_name',
        u.raw_user_meta_data ->> 'name',
        ''
      )), ''),
      'Pilota ' || substr(replace(p.id::text, '-', ''), 1, 4)
    ),
    updated_at = now()
from auth.users u
where u.id = p.id
  and coalesce(trim(p.display_name), '') = '';

commit;
