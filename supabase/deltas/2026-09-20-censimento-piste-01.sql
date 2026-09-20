-- Censimento piste "Segnalata dalla community" - lotto 01
-- Fonti verificate il 2026-09-20: sito ufficiale pistaoffroadrc.it + scheda Google Maps.
-- submitted_by null + is_community true: scheda senza proprietario, niente auto-gestore
-- e niente PitCoin; il titolare puo' rivendicarla dal dettaglio pista.
-- Nota: l'RPC admin_create_community_track richiede una sessione admin, quindi qui
-- si replica la sua insert (stesso slug/format) per poterla lanciare dal SQL editor.
insert into public.tracks(slug, name, city, country, address, latitude, longitude,
  website_url, hours, short_description, external_map_url, image_url, phone,
  organization_name, is_public, approval_status, is_community, submitted_by)
values (
  'new-track-baruccana-offroad-seveso',
  'New Track Baruccana Offroad',
  'Seveso', 'IT',
  'Via della Roggia, 20822 Seveso (MB)',
  45.6465667, 9.1578846,
  'https://pistaoffroadrc.it/',
  'Mar, gio, sab e dom 9:00-18:00 (lun, mer, ven chiuso)',
  'Pista off road del Club M.A.C.: tracciato 1/8 in terra battuta (290 m) e 1/10 in erba sintetica (200 m), box coperti con 220V, banco lavaggio e cronometraggio con transponder.',
  'https://www.google.com/maps/search/?api=1&query=45.6465667,9.1578846',
  'https://pistaoffroadrc.it/wp-content/uploads/2024/11/DJI_0070-scaled.jpg',
  '+39 347 793 6565',
  'Club M.A.C. - Mini Auto Club',
  true, 'approved', true, null)
on conflict (slug) do nothing;

-- Copertina: ripresa drone dall'archivio del club (2560x1440), non il banner
-- "PISTA 1/8" della prima versione. Se la riga esiste gia', allinea l'immagine.
update public.tracks
set image_url = 'https://pistaoffroadrc.it/wp-content/uploads/2024/11/DJI_0070-scaled.jpg',
    updated_at = timezone('utc', now())
where slug = 'new-track-baruccana-offroad-seveso';

select slug, name, city, latitude, longitude, hours, image_url, is_community
from public.tracks where slug = 'new-track-baruccana-offroad-seveso';
