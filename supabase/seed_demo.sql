with inserted_tracks as (
  insert into public.tracks (
    slug,
    name,
    short_description,
    description,
    address,
    city,
    country,
    latitude,
    longitude,
    external_map_url,
    is_public
  )
  values
    (
      'offroad-parma',
      'Offroad Parma',
      'Pista outdoor con focus offroad e giornate prova.',
      'Pista demo PitLap per validare stato pista, servizi e presenza utenti.',
      'Via Demo 1',
      'Parma',
      'Italy',
      44.8015,
      10.3279,
      'https://maps.google.com/?q=44.8015,10.3279',
      true
    ),
    (
      'miniz-hub-modena',
      'MiniZ Hub Modena',
      'Pista indoor compatta per Mini-Z e sessioni serali.',
      'Pista demo PitLap per validare scenari indoor e discovery locale.',
      'Via Demo 2',
      'Modena',
      'Italy',
      44.6471,
      10.9252,
      'https://maps.google.com/?q=44.6471,10.9252',
      true
    )
  on conflict (slug) do update
  set
    name = excluded.name,
    short_description = excluded.short_description,
    description = excluded.description,
    address = excluded.address,
    city = excluded.city,
    country = excluded.country,
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    external_map_url = excluded.external_map_url,
    is_public = excluded.is_public,
    updated_at = timezone('utc', now())
  returning id, slug
),
category_links as (
  insert into public.track_category_links (track_id, category_id)
  select t.id, c.id
  from inserted_tracks t
  join public.track_categories c
    on (t.slug = 'offroad-parma' and c.key = 'buggy')
    or (t.slug = 'miniz-hub-modena' and c.key = 'mini_z')
  on conflict do nothing
  returning track_id
),
status_upsert as (
  insert into public.track_status_current (
    track_id,
    status,
    message,
    updated_at
  )
  select
    id,
    case
      when slug = 'offroad-parma' then 'open'::public.track_status_kind
      else 'wet'::public.track_status_kind
    end,
    case
      when slug = 'offroad-parma' then 'Fondo asciutto, buona trazione'
      else 'Sessione serale confermata'
    end,
    timezone('utc', now())
  from inserted_tracks
  on conflict (track_id) do update
  set
    status = excluded.status,
    message = excluded.message,
    updated_at = excluded.updated_at
  returning track_id
)
insert into public.track_services (
  track_id,
  service_type_id,
  is_available,
  notes
)
select
  t.id,
  s.id,
  case
    when t.slug = 'offroad-parma' and s.key in ('power_220v', 'compressed_air', 'tables', 'toilets') then true
    when t.slug = 'miniz-hub-modena' and s.key in ('tables', 'chairs', 'toilets') then true
    else false
  end,
  null
from inserted_tracks t
cross join public.service_types s
on conflict (track_id, service_type_id) do update
set
  is_available = excluded.is_available,
  notes = excluded.notes,
  updated_at = timezone('utc', now());
