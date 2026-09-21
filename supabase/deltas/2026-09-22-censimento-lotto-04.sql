-- Censimento lotto 04 — mini 4wd, slot car, fermodellismo, on-road, off-road.
-- Piu' completamenti del lotto 03 (coordinate Falchi, copertina GAM).
-- Dati verificati il 2026-09-22: schede Google Maps (coordinate, indirizzi, orari,
-- stato) e siti/pagine ufficiali (descrizioni, contatti). Copertine guardate una per una.
-- Idempotente.

-- ── Tassonomia: due specialita' nuove chieste dall'utente ────────────────────
insert into public.track_categories(key, label_it, label_en, sort_order) values
  ('slot',  'Slot car',     'Slot cars',       110),
  ('treni', 'Fermodellismo','Model railways',  120)
on conflict (key) do nothing;

-- ── Nuove schede ─────────────────────────────────────────────────────────────
insert into public.tracks(slug, name, city, country, address, latitude, longitude,
  website_url, hours, short_description, external_map_url, image_url, phone, contact_email,
  is_public, approval_status, is_community, submitted_by)
values
 ('il-tempio-delle-mini4wd-malalbergo', 'Il Tempio delle Mini4WD', 'Malalbergo', 'IT',
  'Via Minghetti, 15/L, 40051 Altedo, Malalbergo (BO)', 44.6763086, 11.4881905,
  'https://iltempiodellemini4wd.it/',
  'Lun, mar e sab 10:30-13:00 e 16:00-19:30; mer-ven 10:30-13:00 e 16:00-23:30; domenica chiuso',
  'Negozio Tamiya Mini 4WD con pista a 5 corsie in stile Japan Cup, con scambio di corsia, installata nel negozio. Vende modelli e ricambi, aiuta con il setup e ospita la Tamiya Italian Cup.',
  'https://www.google.com/maps/search/?api=1&query=44.6763086,11.4881905',
  null, '+39 388 6288884', 'info@iltempiodellemini4wd.it', true, 'approved', true, null),

 ('toys-world-sant-angelo-lodigiano', 'Toys World - Il Mondo dei Giochi', 'Sant''Angelo Lodigiano', 'IT',
  'Piazza Lorenzo Perosi, 10, 26866 Sant''Angelo Lodigiano (LO)', 45.2326088, 9.4098063,
  'http://www.toysworld.it/',
  'Mar-sab 9:00-12:15 e 15:00-19:30, dom 9:00-12:30, lunedi'' chiuso',
  'Negozio di giocattoli con pista Mini 4WD; il Team Toys World organizza gare ed e'' tra gli organizzatori elencati da mini4wditalia.it.',
  'https://www.google.com/maps/search/?api=1&query=45.2326088,9.4098063',
  null, '+39 0371 90688', null, true, 'approved', true, null),

 ('brianza-slot-club-villasanta', 'Brianza Slot Club', 'Villasanta', 'IT',
  'Via Alfonso La Marmora, 7, 20852 Villasanta (MB)', 45.6021703, 9.3101616,
  'http://www.brianzaslotclub.it/', 'Giovedi'' 19:30-23:30',
  'Club di slot car con pista a 8 corsie da 45 m in un locale seminterrato, cronometraggio computerizzato e area box. Campionato sociale con Gruppo C, GT3, Hypercar, classiche e F1.',
  'https://www.google.com/maps/search/?api=1&query=45.6021703,9.3101616',
  'https://files.supersite.aruba.it/media/2479_e9ddc9bd122c0d3caa7f36409524008b9261f594.jpeg/v1/x_0,y_0,w_930,h_680,dpr_2/pista%20con%20logo.webp',
  '+39 347 923 1125', null, true, 'approved', true, null),

 ('fermodellisti-greco-pirelli-milano', 'Fermodellisti Greco-Pirelli Milano', 'Milano', 'IT',
  'Via Staro, 1 (ingresso da via Ronchi), 20131 Milano (MI)', 45.4886033, 9.2371839,
  'https://associazionefgpm.wixsite.com/fgpmilano', 'Gio e ven 21:00-23:00, sab 15:00-18:00',
  'Associazione di fermodellismo con plastico sociale in scala H0 su 80 mq: tre tracciati (corrente continua, corrente alternata e scartamento ridotto H0m) con comando digitale DCC o analogico.',
  'https://www.google.com/maps/search/?api=1&query=45.4886033,9.2371839',
  'https://static.wixstatic.com/media/211ee7_df9f2799091a46c58f827da70b2e4496~mv2_d_6000_4000_s_4_2.jpg/v1/fill/w_1600,h_1067,al_c,q_80/plastico.jpg',
  null, null, true, 'approved', true, null),

 ('nuova-games-segrate', 'Nuova G.A.M.E.S. Segrate', 'Segrate', 'IT',
  'Viale Europa, 428, 20054 Segrate (MI)', 45.4930013, 9.3036574,
  'https://www.nuovagamesegrate.com/', 'Aperta ai soci tutti i giorni',
  'Pista per automodelli elettrici in scala 1/10 con gare di Touring, Hypercar, GT3 e F1.',
  'https://www.google.com/maps/search/?api=1&query=45.4930013,9.3036574',
  'https://static.wixstatic.com/media/171a37_0e6a182c38e2436ea358b6af6e1e3d5e~mv2.jpeg/v1/fill/w_1600,h_944,al_c,q_80/pista.jpg',
  '+39 347 2638315', 'pistasegraterc@gmail.com', true, 'approved', true, null),

 ('rc-off-road-volandia', 'RC Off Road Volandia', 'Somma Lombardo', 'IT',
  'Via per Tornavento, 15, 21019 Somma Lombardo (VA)', 45.6303782, 8.7052529,
  'https://www.facebook.com/RCVolandia/', null,
  'Tracciato off road per automodelli in scala 1/8 e 1/10 nell''area di Volandia.',
  'https://www.google.com/maps/search/?api=1&query=45.6303782,8.7052529',
  null, null, null, true, 'approved', true, null)
on conflict (slug) do nothing;

-- ── Categorie: solo quelle dichiarate ────────────────────────────────────────
insert into public.track_category_links(track_id, category_id)
select t.id, c.id from public.tracks t, public.track_categories c
where (t.slug, c.key) in (
  ('il-tempio-delle-mini4wd-malalbergo', 'mini4wd'),
  ('il-tempio-delle-mini4wd-malalbergo', 'indoor'),
  ('toys-world-sant-angelo-lodigiano', 'mini4wd'),
  ('brianza-slot-club-villasanta', 'slot'),
  ('brianza-slot-club-villasanta', 'indoor'),
  ('fermodellisti-greco-pirelli-milano', 'treni'),
  ('nuova-games-segrate', 'on_road')
)
on conflict do nothing;

-- ── Completamenti lotto 03 ───────────────────────────────────────────────────
-- Il campo dei Falchi: coordinate pubblicate dal club nella pagina "Il campo di volo".
update public.tracks set latitude = 45.6009, longitude = 9.8207,
  external_map_url = 'https://www.google.com/maps/search/?api=1&query=45.6009,9.8207',
  updated_at = timezone('utc', now())
where slug = 'gruppo-falchi-bergamo' and latitude is null;

-- GAM Desio: la pista d'erba all'alba, dalla galleria del club.
update public.tracks set
  image_url = 'https://www.gamasd.it/wp-content/uploads/2025/08/WhatsApp-Image-2025-07-15-at-06.02.15.jpeg',
  updated_at = timezone('utc', now())
where slug = 'gam-asd-desio' and image_url is null;

-- Verifica
select t.slug, (t.latitude is not null) coord, (t.image_url is not null) img, (t.hours is not null) orari,
  (select string_agg(c.key, ',') from public.track_category_links l
     join public.track_categories c on c.id = l.category_id where l.track_id = t.id) categorie
from public.tracks t where t.is_community order by t.created_at;
