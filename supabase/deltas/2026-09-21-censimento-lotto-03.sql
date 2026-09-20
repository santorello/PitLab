-- Censimento lotto 03 — volo, mini 4wd, mini-z, on-road.
-- Dati verificati il 2026-09-21: siti ufficiali dei club per descrizioni e contatti,
-- schede Google Maps per coordinate, indirizzi e stato di attivita'.
-- Schede "segnalate dalla community": submitted_by null, is_community true.
-- Idempotente: on conflict do nothing ovunque.

-- ── Nuova categoria: i campi di volo non avevano una chiave propria ──────────
-- (c'era solo 'fpv', che e' un'altra cosa: un campo di aeromodellismo non e' una
--  pista FPV). Senza questa riga i 5 club restavano senza filtro.
insert into public.track_categories(key, label_it, label_en, sort_order)
values ('volo', 'Volo / Aeromodellismo', 'RC flying', 100)
on conflict (key) do nothing;

-- ── Piste ────────────────────────────────────────────────────────────────────
insert into public.tracks(slug, name, city, country, address, latitude, longitude,
  website_url, hours, short_description, external_map_url, image_url, phone,
  is_public, approval_status, is_community, submitted_by)
values
 ('miniautodromo-leno', 'Miniautodromo di Leno', 'Leno', 'IT',
  'Via O. Rosai, 25024 Leno (BS)', 45.3746026, 10.2097665,
  'https://www.lenorc.it/', null,
  'Circuito on road pavimentato da 290 m con rettilineo di 65 m e larghezza 5 m, per 1/8, 1/10 e 1/8 GT. Box coperti con 220V, aria compressa, tavoli piloti, tribune, bar e parcheggio camper. Gestito dal Gruppo Lenese Automodellismo ASD.',
  'https://www.google.com/maps/search/?api=1&query=45.3746026,10.2097665',
  'https://www.lenorc.it/wp-content/uploads/2021/04/IMG-20210410-WA0007.jpg',
  '+39 333 8099012', true, 'approved', true, null),

 ('aecbg-campo-volo-grassobbio', 'Aero Club Aeromodellisti Bergamo - Campo di volo', 'Grassobbio', 'IT',
  'Campo di volo, 24050 Grassobbio (BG)', 45.646156, 9.7342793,
  'https://www.aeromodellistiaecbg.eu/',
  'Estate (15/5-15/9): feriali 15:00-tramonto, weekend e festivi 9:00-12:30 e 15:00-tramonto. Inverno (16/9-14/5): feriali 14:00-tramonto, weekend e festivi 9:00-12:30 e 14:00-tramonto',
  'Campo di volo per aeromodelli con parcheggio e area picnic, scuola di volo certificata AeCI (teoria, costruzione e pilotaggio) e un calendario di gare ed eventi lungo tutto l''anno.',
  'https://www.google.com/maps/search/?api=1&query=45.646156,9.7342793',
  null, '+39 347 604 8020', true, 'approved', true, null),

 ('ali-azzurre-cermenate', 'Campo Volo Ali Azzurre', 'Cermenate', 'IT',
  'Via Caio Plinio, 29, 22072 Cermenate (CO)', 45.7138661, 9.0899765,
  'https://www.aliazzurre.it/', 'Sabato e domenica pomeriggio',
  'Pista in erba 120x30 m con campo circolare a 360 gradi, per volo di riproduzione e acrobatico. Cascinotto attrezzi, manica a vento, tavoli e pannelli solari per ricaricare le batterie; scuola di volo con cavo allievo-maestro e iscrizione annuale con assicurazione.',
  'https://www.google.com/maps/search/?api=1&query=45.7138661,9.0899765',
  null, null, true, 'approved', true, null),

 ('gabe-busnago', 'G.A.B.E. - Gruppo Aeromodellisti Brianza Est', 'Busnago', 'IT',
  'Cascina Corte Anna, 20874 Busnago (MB)', 45.6100, 9.4785,
  'http://www.gabebusnago.it/', 'Nel fine settimana dalle 14:00',
  'Campo erboso per trainer, riproduzioni, acrobatici, alianti elettrici e jet elettrici; non sono ammessi turbine, pulsojet, elicotteri e multirotori. Corso di pilotaggio a doppio comando.',
  'https://www.google.com/maps/search/?api=1&query=45.61,9.4785',
  null, null, true, 'approved', true, null),

 ('gam-asd-desio', 'Campo Volo GAM ASD', 'Desio', 'IT',
  'Via Giorgio Ambrosoli, 20832 Desio (MB)', 45.5995476, 9.2133547,
  'https://www.gamasd.it/', null,
  'Campo volo alle porte di Milano per aeroplani, elicotteri e droni, gestito dal GAM ASD (sede a Cusano Milanino). Il club organizza feste ed eventi sociali.',
  'https://www.google.com/maps/search/?api=1&query=45.5995476,9.2133547',
  null, '+39 377 174 9502', true, 'approved', true, null),

 ('gruppo-falchi-bergamo', 'Gruppo Aeromodellistico Falchi Bergamo', 'Zanica', 'IT',
  'Sede: Via Fratelli Calvi, 3, 24050 Zanica (BG). Campo di volo lungo la ex SS573 tra Palosco e Calcinate',
  null, null,
  'https://www.gruppofalchi.com/', null,
  'Campo erboso 300x80 m certificato ENAC, modelli fino a 25 kg, impianto fotovoltaico con prese 12V per ricaricare le batterie in campo e scuola di volo.',
  null, null, null, true, 'approved', true, null)
on conflict (slug) do nothing;

-- ── Categorie: solo quelle che la fonte dichiara alla lettera ────────────────
insert into public.track_category_links(track_id, category_id)
select t.id, c.id from public.tracks t, public.track_categories c
where (t.slug, c.key) in (
  ('miniautodromo-leno', 'on_road'),
  ('aecbg-campo-volo-grassobbio', 'volo'),
  ('ali-azzurre-cermenate', 'volo'),
  ('gabe-busnago', 'volo'),
  ('gam-asd-desio', 'volo'),
  ('gruppo-falchi-bergamo', 'volo')
)
on conflict do nothing;

-- ── Servizi dichiarati ───────────────────────────────────────────────────────
insert into public.track_services(track_id, service_type_id, is_available)
select t.id, s.id, true from public.tracks t, public.service_types s
where (t.slug, s.key) in (
  ('miniautodromo-leno', 'power_220v'),
  ('miniautodromo-leno', 'compressed_air'),
  ('miniautodromo-leno', 'tables'),
  ('miniautodromo-leno', 'food'),
  ('miniautodromo-leno', 'toilets'),
  ('ali-azzurre-cermenate', 'tables')
)
-- Le righe dei servizi possono gia' esistere a false (vengono create con la
-- pista): un semplice "do nothing" le lascerebbe spente.
on conflict (track_id, service_type_id) do update set is_available = true;

-- NOTA: dev e prod hanno tassonomie divergenti. Su dev mancano on_road, fpv,
-- navale e rally e ci sono 'francobolli' e 'treni' che su prod non esistono.
-- Su dev la riga on_road va creata prima di lanciare questo delta.

-- Verifica
select t.slug, t.city, (t.latitude is not null) as coord,
       (select string_agg(c.key, ',') from public.track_category_links l
          join public.track_categories c on c.id = l.category_id where l.track_id = t.id) as categorie,
       (select count(*) from public.track_services s where s.track_id = t.id and s.is_available) as servizi
from public.tracks t
where t.slug in ('miniautodromo-leno','aecbg-campo-volo-grassobbio','ali-azzurre-cermenate',
                 'gabe-busnago','gam-asd-desio','gruppo-falchi-bergamo')
order by t.slug;
