-- Lotto 06a — Pista RC Crespi (Brembate/Crespi d'Adda, BG).
-- Nasce dalla verifica del candidato "HB Racing ASD Trezzo" dell'inventario YouTube:
-- HB.RACING risulta CHIUSA DEFINITIVAMENTE su Google Maps (Via Fernando Santi 3A, Trezzo).
-- A ~2 km c'e' Pista RC Crespi, attiva: pagina Facebook ufficiale con calendario gare 2026
-- (rally 29/03, 26/04, 24/05; buggy 1/8) e recensioni Maps di 1 e 5 mesi fa.
-- Verificato il 2026-09-22. Idempotente.

insert into public.tracks(slug, name, city, country, address, latitude, longitude,
  website_url, hours, short_description, external_map_url, image_url, phone, contact_email,
  is_public, approval_status, is_community, submitted_by)
values
 ('pista-rc-crespi-brembate', 'Pista RC Crespi', 'Brembate', 'IT',
  'Via Pista Crespi, 115, 24041 Brembate (BG) - localita'' Crespi d''Adda', 45.5983619, 9.5396556,
  'https://www.facebook.com/PistaRcCrespi/', null,
  'Pista off road per buggy 1/8 e rally in scala 1/10, 1/14 e 1/16, come la descrive il club. Calendario gare rally e buggy 1/8 per il 2026.',
  'https://www.google.com/maps/search/?api=1&query=45.5983619,9.5396556',
  null, null, 'pistarccrespi@gmail.com', true, 'approved', true, null)
on conflict (slug) do nothing;

insert into public.track_category_links(track_id, category_id)
select t.id, c.id from public.tracks t, public.track_categories c
where (t.slug, c.key) in (
  ('pista-rc-crespi-brembate', 'buggy'),
  ('pista-rc-crespi-brembate', 'rally')
)
on conflict do nothing;

select t.slug, t.city, (t.latitude is not null) coord, (t.image_url is not null) img,
  (select string_agg(c.key, ',') from public.track_category_links l
     join public.track_categories c on c.id = l.category_id where l.track_id = t.id) categorie
from public.tracks t where t.slug = 'pista-rc-crespi-brembate';
