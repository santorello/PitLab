-- Lotto 04b — Toys in Fabula (club con pista Mini 4WD, Cinisello Balsamo).
-- Fonti: scheda Google Maps (indirizzo, coordinate, orari, telefono) e conferma
-- dell'utente che frequenta il posto (pista Mini 4WD aperta da poco).
-- SottoFrutta Mini4WD (Muggio') NON si inserisce: e' un club privato.
insert into public.tracks(slug, name, city, country, address, latitude, longitude,
  website_url, hours, short_description, external_map_url, phone,
  is_public, approval_status, is_community, submitted_by)
values
 ('toys-in-fabula-club-cinisello-balsamo', 'Toys in Fabula - Club', 'Cinisello Balsamo', 'IT',
  'Via Carlo Martinelli, 37, 20092 Cinisello Balsamo (MI)', 45.551312, 9.2187815,
  'https://www.toysinfabula.it/', 'Sabato 8:30-12:30 e 14:00-18:00',
  'Club di modellismo aperto di recente dal negozio Toys in Fabula, con pista Mini 4WD.',
  'https://www.google.com/maps/search/?api=1&query=45.551312,9.2187815',
  '+39 340 828 4505', true, 'approved', true, null)
on conflict (slug) do nothing;

insert into public.track_category_links(track_id, category_id)
select t.id, c.id from public.tracks t, public.track_categories c
where t.slug = 'toys-in-fabula-club-cinisello-balsamo' and c.key = 'mini4wd'
on conflict do nothing;

select slug, city, (select string_agg(c.key, ',') from public.track_category_links l
  join public.track_categories c on c.id = l.category_id where l.track_id = t.id) categorie
from public.tracks t where slug = 'toys-in-fabula-club-cinisello-balsamo';
