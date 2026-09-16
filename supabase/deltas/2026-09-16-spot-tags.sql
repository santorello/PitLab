-- 2026-09-16 — Spot: scelte guidate (ideale per, terreno, accesso, periodo).
-- Chiavi fisse in DB, etichette IT/EN nell'app (spot_tags.dart).
-- ATTENZIONE: spots usa grant PER COLONNA → le nuove colonne vanno concesse esplicitamente.
-- Idempotente. Eseguire su dev e prod (su prod anche PRIMA del deploy: la build vecchia non le usa).

alter table public.spots
  add column if not exists best_for_tags text[] not null default '{}',
  add column if not exists surface_tags  text[] not null default '{}',
  add column if not exists access_type   text,
  add column if not exists best_season   text;

alter table public.spots drop constraint if exists spots_best_for_tags_check;
alter table public.spots add constraint spots_best_for_tags_check check (best_for_tags <@ array[
  'scaler','crawler','bashing','buggy','drift','onroad','mini','fpv_drone','rc_plane','rc_boat','rc_tank','family'
]::text[]);
alter table public.spots drop constraint if exists spots_surface_tags_check;
alter table public.spots add constraint spots_surface_tags_check check (surface_tags <@ array[
  'dirt','rock','grass','sand','mud','gravel','asphalt','concrete','water','indoor','mixed'
]::text[]);
alter table public.spots drop constraint if exists spots_access_type_check;
alter table public.spots add constraint spots_access_type_check
  check (access_type is null or access_type in ('free','permission','private'));
alter table public.spots drop constraint if exists spots_best_season_check;
alter table public.spots add constraint spots_best_season_check
  check (best_season is null or best_season in ('all_year','avoid_after_rain','summer'));

grant select (best_for_tags, surface_tags, access_type, best_season) on public.spots to anon, authenticated;
grant insert (best_for_tags, surface_tags, access_type, best_season),
      update (best_for_tags, surface_tags, access_type, best_season) on public.spots to authenticated;

create or replace view public.public_spots with (security_invoker = true) as
select s.id, s.slug, s.title, s.city, s.category, s.best_for, s.surface, s.note,
       s.image_accent, s.photo_count, s.address, s.latitude, s.longitude,
       s.image_urls, s.video_url, s.is_custom, s.created_at,
       private.is_spot_owned_by_current_user(s.id) as is_owned_by_current_user,
       s.best_for_tags, s.surface_tags, s.access_type, s.best_season
from public.spots s;

-- Via i testi segnaposto scritti dal vecchio modulo (non erano dati reali).
update public.spots set best_for = '' where best_for in ('Spot condiviso dagli utenti', 'Community-submitted spot');
update public.spots set surface  = '' where surface  in ('Dettagli da confermare', 'Details to be confirmed');

-- Verifica (atteso: 4)
select count(*) from information_schema.columns
where table_schema = 'public' and table_name = 'public_spots'
  and column_name in ('best_for_tags','surface_tags','access_type','best_season');
