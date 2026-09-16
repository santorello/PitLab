-- 2026-09-16 A — Colonne private del profilo: RPC per leggere SOLO i propri dati.
-- Innocuo: eseguibile subito, prima del deploy della nuova build.
create or replace function public.my_profile_private()
returns table (
  preferred_city text, home_city text, home_country text,
  home_latitude double precision, home_longitude double precision,
  user_interests text[], deletion_requested_at timestamptz
)
language sql stable security definer set search_path = public
as $$
  select p.preferred_city, p.home_city, p.home_country,
         p.home_latitude::double precision, p.home_longitude::double precision,
         p.user_interests::text[], p.deletion_requested_at
  from public.profiles p
  where p.id = auth.uid();
$$;
revoke execute on function public.my_profile_private() from public, anon;
grant execute on function public.my_profile_private() to authenticated;
