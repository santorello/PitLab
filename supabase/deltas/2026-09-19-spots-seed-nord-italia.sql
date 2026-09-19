-- Delta: 2026-09-19 — Seed spots Nord Italia (batch 1, 9 spot)
-- Fonte primaria: playlist YouTube "Modellismo" di Giuseppe (99 video, località riprese sul campo)
-- Fonte coordinate: OpenStreetMap / Nominatim (centro della località o del parco)
-- ATTENZIONE: coordinate a livello di parco/comune, NON del punto esatto di run.
--             Vedi colonna "confidence" nel CSV allegato: prima di importare in prod
--             conviene rifinire lat/lon sui 4 spot marcati MEDIUM/LOW.
-- ESCLUSO: parco-della-madonnina-lainate, gia' presente in prod (inserito dall'app il 2026-09-16)
-- is_custom = false → catalogo ufficiale, owner_id = null
-- Immagini: thumbnail dei video di Giuseppe (hotlink i.ytimg.com). Per spostarle su Storage
--            vedi la UPDATE commentata in fondo.
-- Idempotente (on conflict do nothing su slug). Eseguire prima su dev.

begin;

insert into public.spots (
  slug, title, city, category, best_for, surface, note,
  image_accent, photo_count, address, latitude, longitude,
  image_urls, video_url, best_for_tags, surface_tags, access_type, best_season, is_custom
) values

-- [HIGH] Bashing monster, fondo misto
('parco-delle-cave-milano', 'Parco delle Cave', 'Milano', 'Bashing',
 '', '',
 'Grande parco urbano con ampi spazi aperti e dislivelli naturali. Adatto a sessioni veloci, occhio ai frequentatori del parco nei weekend.',
 -2571610, 1, 'Parco delle Cave, Milano', 45.46821, 9.09954,
 array['https://i.ytimg.com/vi/ymhGTVlalfw/maxresdefault.jpg']::text[], 'https://youtu.be/ymhGTVlalfw',
 array['bashing','buggy']::text[], array['grass','dirt','gravel']::text[], 'free', 'all_year', false),

-- [HIGH] Bashing + skatepark jump + scaler mud/water
('parco-lambro-milano', 'Parco Lambro', 'Milano', 'Bashing',
 '', '',
 'Spot molto versatile: salti sullo skatepark per il bashing e sponde fangose del fiume per scaler e guadi.',
 -2571610, 1, 'Parco Lambro, Milano', 45.49683, 9.25052,
 array['https://i.ytimg.com/vi/nOYmUhLp0xQ/maxresdefault.jpg']::text[], 'https://youtu.be/nOYmUhLp0xQ',
 array['bashing','buggy','scaler','crawler']::text[], array['grass','mud','water','concrete']::text[], 'free', 'all_year', false),

-- [HIGH] Collina artificiale, salite e sessioni notturne
('monte-stella-milano', 'Monte Stella', 'Milano', 'Bashing',
 '', '',
 'Collina artificiale con salite e discese continue: ottima per prove di trazione e per sessioni notturne con i fari.',
 -2571610, 1, 'Monte Stella, Milano', 45.49088, 9.13448,
 array['https://i.ytimg.com/vi/K4iRJgmnggk/maxresdefault.jpg']::text[], 'https://youtu.be/K4iRJgmnggk',
 array['bashing','scaler','crawler']::text[], array['dirt','gravel','grass']::text[], 'free', 'all_year', false),

-- [MEDIUM] coordinate = centro comune, punto esatto da rifinire
('erve-scaler-trail', 'Trail di Erve', 'Erve', 'Scaler',
 '', '',
 'Valle stretta con roccia e acqua, terreno tecnico adatto a uscite lente. Punto di partenza da concordare con chi conosce la zona.',
 -14148093, 1, 'Erve (LC)', 45.82158, 9.45285,
 array['https://i.ytimg.com/vi/NFoxUtBOz0Y/maxresdefault.jpg']::text[], 'https://youtu.be/NFoxUtBOz0Y',
 array['scaler','crawler']::text[], array['rock','gravel','water']::text[], 'free', 'avoid_after_rain', false),

-- [LOW] località citata nel video ma punto non georeferenziato: VERIFICARE
('erba-scaler-autunno', 'Scaler Trail di Erba', 'Erba', 'Scaler',
 '', '',
 'Percorso naturale in zona collinare, molto fotogenico in autunno. Posizione indicativa: il punto esatto va confermato sul posto.',
 -14148093, 1, 'Erba (CO)', 45.81622, 9.22025,
 array['https://i.ytimg.com/vi/gZvmnDXW6Wc/maxresdefault.jpg']::text[], 'https://youtu.be/gZvmnDXW6Wc',
 array['scaler','crawler']::text[], array['rock','dirt']::text[], 'free', 'all_year', false),

-- [MEDIUM] scaler + riprese drone
('olgiate-comasco-offroad', 'Offroad di Olgiate Comasco', 'Olgiate Comasco', 'Scaler',
 '', '',
 'Area aperta che unisce percorsi 4x4 lenti e spazio libero sopra per riprese aeree.',
 -14148093, 1, 'Olgiate Comasco (CO)', 45.78533, 8.96777,
 array['https://i.ytimg.com/vi/pdGOzGgXqKc/maxresdefault.jpg']::text[], 'https://youtu.be/pdGOzGgXqKc',
 array['scaler','crawler','fpv_drone']::text[], array['dirt','grass','gravel']::text[], 'free', 'all_year', false),

-- [MEDIUM] guadi e roccia, coordinate a livello di valle
('val-vigezzo-fiume', 'Fiume in Val Vigezzo', 'Santa Maria Maggiore', 'Scaler',
 '', '',
 'Greto di fiume alpino con massi e passaggi in acqua: spot severo, consigliato solo a modelli impermeabilizzati.',
 -14148093, 1, 'Val Vigezzo, Santa Maria Maggiore (VB)', 46.13511, 8.46887,
 array['https://i.ytimg.com/vi/H97cQkAWfII/maxresdefault.jpg']::text[], 'https://youtu.be/H97cQkAWfII',
 array['scaler','crawler']::text[], array['rock','water','gravel']::text[], 'free', 'summer', false),

-- [MEDIUM] bashing, coordinate = centro comune
('arese-bashing', 'Bashing Area Arese', 'Arese', 'Bashing',
 '', '',
 'Spianata con spazio per sessioni veloci e salti improvvisati. Fondo che si compatta bene a secco.',
 -2571610, 1, 'Arese (MI)', 45.54991, 9.07829,
 array['https://i.ytimg.com/vi/vz8epuwDP2g/maxresdefault.jpg']::text[], 'https://youtu.be/vz8epuwDP2g',
 array['bashing','buggy']::text[], array['dirt','gravel']::text[], 'free', 'avoid_after_rain', false),

-- [MEDIUM] area fluviale ampia, adatta anche al volo
('ticino-somma-lombardo', 'Greto del Ticino', 'Somma Lombardo', 'Droni',
 '', '',
 'Ampia area fluviale con visuale libera: buona per il volo FPV e per guadi e sabbia con i modelli terrestri. Verificare sempre le restrizioni di volo ENAC prima di alzarsi.',
 -16154521, 1, 'Greto del Ticino, Somma Lombardo (VA)', 45.68362, 8.70709,
 array['https://i.ytimg.com/vi/KoBF0ICUgiM/maxresdefault.jpg']::text[], 'https://youtu.be/KoBF0ICUgiM',
 array['fpv_drone','bashing','scaler']::text[], array['sand','gravel','water','grass']::text[], 'free', 'all_year', false)

on conflict (slug) do nothing;

commit;

-- Verifica (atteso: 9)
select count(*) from public.spots
where slug in (
  'parco-della-madonnina-lainate','parco-delle-cave-milano','parco-lambro-milano',
  'monte-stella-milano','erve-scaler-trail','erba-scaler-autunno',
  'olgiate-comasco-offroad','val-vigezzo-fiume','arese-bashing','ticino-somma-lombardo'
);

-- OPZIONALE — passaggio a Supabase Storage (bucket 'media', pubblico):
-- 1. carica i 9 jpg in media/catalog/spots/<slug>.jpg
-- 2. poi:
-- update public.spots
--   set image_urls = array['https://klfjvyytubiorqzfisdu.supabase.co/storage/v1/object/public/media/catalog/spots/'||slug||'.jpg']::text[]
--   where is_custom = false and slug in (select unnest(array[
--     'parco-delle-cave-milano','parco-lambro-milano','monte-stella-milano','erve-scaler-trail',
--     'erba-scaler-autunno','olgiate-comasco-offroad','val-vigezzo-fiume','arese-bashing','ticino-somma-lombardo']));
