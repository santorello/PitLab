-- Censimento lotto 05 — 3 piste (on-road Mantova e Cremona, mini off-road Novate)
-- e 3 negozi (Bergamo x2, Desenzano). Piu' due copertine mancanti dei lotti 02-03.
-- Dati verificati il 2026-09-23: schede Google Maps (coordinate, indirizzi, orari,
-- stato) e siti ufficiali (descrizioni, servizi, contatti). Copertine guardate una per una.
-- Idempotente.

-- ── Piste ────────────────────────────────────────────────────────────────────
insert into public.tracks(slug, name, city, country, address, latitude, longitude,
  website_url, hours, short_description, external_map_url, image_url, phone, contact_email,
  is_public, approval_status, is_community, submitted_by)
values
 ('model-club-mantova-circuito-matteo-priori', 'Model Club Mantova - Circuito Matteo Priori', 'Mantova', 'IT',
  'Strada del Trincerone, 7d, 46100 Mantova (MN)', 45.1352824, 10.782744,
  'https://www.pistadimantova.it/', null,
  'Lo storico tracciato del Trincerone, gestito dal Model Club Mantova. Gare 1/10 e 1/8 a scoppio, 1/10 elettrico, 1/8 GT e SGT. Palco piloti, box coperti, bagni, acqua, compressore, corrente elettrica, cronometraggio e zona ristoro all''ombra.',
  'https://www.google.com/maps/search/?api=1&query=45.1352824,10.782744',
  'https://www.pistadimantova.it/img/pista/005.jpg',
  '+39 339 409 9430', 'andrea@pistadimantova.it', true, 'approved', true, null),

 ('miniautodromo-stradivari-cremona', 'Miniautodromo Stradivari', 'Cremona', 'IT',
  'All''uscita del casello autostradale, 26100 Cremona (CR)', 45.1369417, 10.0693985,
  'https://www.circuitostradivari.it/', null,
  'Circuito di 336 m (larghezza minima 4,80 m) su un''area recintata di 6200 mq, gestito dal Gruppo Automodellistico Cremonese. Palco guida alto, box coperti con aria compressa, acqua e una presa di corrente per ogni tavolo, servizi igienici, zona ristoro e area camper. Gare 1/10 Touring, 1/8 GT e SGT, 1/5 GT e Formula.',
  'https://www.google.com/maps/search/?api=1&query=45.1369417,10.0693985',
  'https://www.circuitostradivari.it/images/pista.jpg',
  null, 'info@circuitostradivari.it', true, 'approved', true, null),

 ('milan-model-mini-off-road-novate-milanese', 'Milan Model Mini Off-Road', 'Novate Milanese', 'IT',
  'Via Cascina del Sole, 6, 20026 Novate Milanese (MI)', 45.5324215, 9.1418414,
  'https://www.modellismomilano.it/', null,
  'La pista off road del negozio Milan Model: 130 m di tracciato per buggy e monster in scala 1/10 e 1/16, adatta ai principianti, con area box, corrente e aria. Info in negozio.',
  'https://www.google.com/maps/search/?api=1&query=45.5324215,9.1418414',
  null, '+39 02 23054659', null, true, 'approved', true, null)
on conflict (slug) do nothing;

-- Categorie: solo quelle dichiarate (le classi Touring/GT/Formula valgono on_road,
-- come per Nuova G.A.M.E.S. nel lotto 04).
insert into public.track_category_links(track_id, category_id)
select t.id, c.id from public.tracks t, public.track_categories c
where (t.slug, c.key) in (
  ('model-club-mantova-circuito-matteo-priori', 'on_road'),
  ('miniautodromo-stradivari-cremona', 'on_road'),
  ('milan-model-mini-off-road-novate-milanese', 'buggy')
)
on conflict do nothing;

-- Servizi: solo quelli scritti sul sito del club/negozio.
insert into public.track_services(track_id, service_type_id, is_available)
select t.id, s.id, true from public.tracks t, public.service_types s
where (t.slug, s.key) in (
  ('model-club-mantova-circuito-matteo-priori', 'toilets'),
  ('model-club-mantova-circuito-matteo-priori', 'compressed_air'),
  ('model-club-mantova-circuito-matteo-priori', 'power_220v'),
  ('model-club-mantova-circuito-matteo-priori', 'food'),
  ('miniautodromo-stradivari-cremona', 'compressed_air'),
  ('miniautodromo-stradivari-cremona', 'power_220v'),
  ('miniautodromo-stradivari-cremona', 'tables'),
  ('miniautodromo-stradivari-cremona', 'toilets'),
  ('miniautodromo-stradivari-cremona', 'food'),
  ('milan-model-mini-off-road-novate-milanese', 'power_220v'),
  ('milan-model-mini-off-road-novate-milanese', 'compressed_air')
)
on conflict (track_id, service_type_id) do update set is_available = true;

-- ── Negozi ───────────────────────────────────────────────────────────────────
insert into public.shops(slug, name, city, country, address, latitude, longitude,
  website_url, hours, short_description, external_map_url, image_url, phone, service_labels,
  is_public, approval_status, is_community, submitted_by)
values
 ('modellismo-sant-alessandro-bergamo', 'Modellismo Sant''Alessandro', 'Bergamo', 'IT',
  'Via San Pio X, 15, 24125 Bergamo (BG) - quartiere Celadina', 45.6927925, 9.7086843,
  'https://www.modelsantalessandro.com/',
  'Lun 15:00-19:30; mar, mer, ven e sab 9:00-12:30 e 15:00-19:30; gio 15:00-19:30; domenica chiuso',
  'Negozio di modellismo dal 1970: statico, dinamico, ferroviario, navale, die-cast, colori e ricambi. Assistenza tecnica, riparazioni, tuning, carburazioni e setup auto RC; restauro velieri e servizio di montaggio e pittura.',
  'https://www.google.com/maps/search/?api=1&query=45.6927925,9.7086843',
  'https://www.modelsantalessandro.com/img/vetrina-ingresso.jpg',
  '+39 035 210127',
  array['Riparazioni modellismo dinamico','Setup auto RC','Restauro velieri','Servizio pittura','Fermodellismo'],
  true, 'approved', true, null),

 ('modelberg-bergamo', 'Modelberg', 'Bergamo', 'IT',
  'Via G.B. Moroni, 38, 24122 Bergamo (BG)', 45.6917185, 9.6630657,
  'https://www.modelberg.it/',
  'Lun 15:00-19:30; mar-sab 9:00-12:30 e 15:00-19:30; domenica chiuso',
  'Negozio di modellismo attivo dal 1961: aerei, elicotteri, barche e auto RC, treni, modelli statici, radiocomandi, batterie e motorizzazioni. Laboratorio per montaggio, riparazione e messa a punto dei modelli e conversione dei radiocomandi d''epoca ai 2,4 GHz.',
  'https://www.google.com/maps/search/?api=1&query=45.6917185,9.6630657',
  null, '+39 035 248442',
  array['Laboratorio riparazioni','Aeromodellismo','Automodellismo','Treni','Modellismo statico'],
  true, 'approved', true, null),

 ('asimodel-desenzano-del-garda', 'ASI Model', 'Desenzano del Garda', 'IT',
  'Via Ettore De Andreis, 41, 25015 Desenzano del Garda (BS)', 45.4688152, 10.5271106,
  'https://www.asimodel.it/',
  'Lun-ven 8:30-12:30 e 14:00-18:00; sabato e domenica chiuso',
  'Negozio di modellismo dinamico: buggy, truggy e monster 1/8 e 1/10, on road e drift, crawler, barche, droni FPV e mezzi da cantiere in scala. Diagnosi al banco, ricambi a magazzino, montaggio e riparazioni. Marchi tra cui Traxxas, ARRMA, HPI, Tamiya.',
  'https://www.google.com/maps/search/?api=1&query=45.4688152,10.5271106',
  null, '+39 030 912 1578',
  array['Traxxas','ARRMA','HPI Racing','Tamiya','Diagnosi al banco','Riparazioni'],
  true, 'approved', true, null)
on conflict (slug) do nothing;

-- ── Copertine mancanti dei lotti precedenti ─────────────────────────────────
-- Fioroni: l'interno del negozio (scaffali di automodelli), 1280x720, 260 KB.
update public.shops set
  image_url = 'https://www.modellismofioroni.com/wp-content/uploads/2024/02/Negozio-di-modellismo-a-Pavia.jpg',
  updated_at = timezone('utc', now())
where slug = 'modellismo-fioroni-casarile' and image_url is null;

-- AECBG: aerei sul prato del campo alla festa di inizio stagione, 1280x960, 270 KB.
update public.tracks set
  image_url = 'https://aeromodellistiaecbg.eu/wp-content/uploads/2025/10/2017-04-30-12.00.37.jpg',
  updated_at = timezone('utc', now())
where slug = 'aecbg-campo-volo-grassobbio' and image_url is null;

-- Verifica
select 'pista' tipo, t.slug, (t.latitude is not null) coord, (t.image_url is not null) img, (t.hours is not null) orari,
  (select string_agg(c.key, ',') from public.track_category_links l
     join public.track_categories c on c.id = l.category_id where l.track_id = t.id) categorie,
  (select count(*) from public.track_services s where s.track_id = t.id and s.is_available)::text servizi
from public.tracks t where t.is_community
union all
select 'negozio', s.slug, (s.latitude is not null), (s.image_url is not null), (s.hours is not null),
  array_to_string(s.service_labels, ','), null
from public.shops s where s.is_community
order by 1, 2;
