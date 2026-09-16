-- 2026-09-16 B — Colonne private del profilo: niente lettura diretta per anon/authenticated.
-- SU PROD: eseguire SOLO DOPO il deploy della build che usa my_profile_private() (delta A),
-- altrimenti la build vecchia perde la città/posizione di casa.
-- Private: preferred_city, home_city, home_country, home_latitude, home_longitude,
--          user_interests, deletion_requested_at. Le funzioni SECURITY DEFINER non sono toccate.
-- INSERT/UPDATE invariati (privilegi separati).
revoke select on public.profiles from anon, authenticated;
grant select (id, display_name, avatar_url, preferred_language, role, created_at, updated_at,
              onboarding_completed_at, public_slug, is_public, onboarding_completed)
  on public.profiles to anon, authenticated;

-- Verifica (atteso: anon 11, authenticated 11)
select grantee, count(*) from information_schema.column_privileges
where table_schema = 'public' and table_name = 'profiles' and privilege_type = 'SELECT'
  and grantee in ('anon', 'authenticated') group by grantee;
