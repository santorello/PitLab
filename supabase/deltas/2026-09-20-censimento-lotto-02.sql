-- Censimento lotto 02 — 3 piste + 5 negozi "segnalati dalla community".
-- Dati verificati il 2026-09-20: sito ufficiale per descrizione/contatti,
-- scheda Google Maps per coordinate, indirizzo e stato di attivita'.
-- submitted_by null + is_community true: nessun proprietario, nessun PitCoin,
-- la scheda si rivendica dal dettaglio.
-- Richiede: 2026-09-20-negozi-community-e-rivendica.sql (colonna shops.is_community).

-- ── Piste ────────────────────────────────────────────────────────────────────
insert into public.tracks(slug, name, city, country, address, latitude, longitude,
  website_url, hours, short_description, external_map_url, phone,
  is_public, approval_status, is_community, submitted_by)
values
 ('pista-melzorc-melzo', 'Pista MelzoRC', 'Melzo', 'IT',
  'Via Primo Maggio, 31, 20066 Melzo (MI)', 45.4920616, 9.4072942,
  'https://www.pistamelzo.com/',
  'Outdoor: lun-gio e sab-dom 9:00-19:00 (in inverno fino alle 18:00). Indoor: ven 19:00-23:00, sab-dom 14:00-18:00, su prenotazione',
  'Circuito on road in asfalto da 340 m con carreggiata di 5 m, piu'' un tracciato indoor: 1/8 pista, 1/10 touring, 1/8 GT e 1/28. Box, cronometraggio, aria compressa e punto ristoro.',
  'https://www.google.com/maps/search/?api=1&query=45.4920616,9.4072942',
  '+39 366 1535845', true, 'approved', true, null),

 ('srb-offroad-nembro', 'S.R.B. OffRoad - Sport Race Bergamo', 'Nembro', 'IT',
  'Via Luigi Carrara, 49, 24027 Nembro (BG)', 45.7484441, 9.7778444,
  'https://www.srboffroad.it/', null,
  'Circuito off road 1/8 nitro e brushless da 340 m per 4 di larghezza, omologato ACI grado A, con cronometraggio MyLaps e un percorso dedicato agli scale crawler.',
  'https://www.google.com/maps/search/?api=1&query=45.7484441,9.7778444',
  '+39 340 477 0604', true, 'approved', true, null),

 ('nitro-buggy-genzone', 'Nitro Buggy Genzone', 'Genzone', 'IT',
  'Via Garibaldi, 39 (SP31), 27010 Genzone (PV)', 45.1821666, 9.3440223,
  'http://nitrobuggygenzone.altervista.org/', null,
  'Pista off road per modelli nitro ed elettrici in scala 1/8 e 1/10, attiva dal 2014.',
  'https://www.google.com/maps/search/?api=1&query=45.1821666,9.3440223',
  '+39 331 1397659', true, 'approved', true, null)
on conflict (slug) do nothing;

-- ── Negozi ───────────────────────────────────────────────────────────────────
insert into public.shops(slug, name, city, country, address, latitude, longitude,
  website_url, hours, short_description, external_map_url, phone,
  is_public, approval_status, is_community, submitted_by)
values
 ('milan-model-novate-milanese', 'Milan Model Modellismo', 'Novate Milanese', 'IT',
  'Via Cascina del Sole, 20, 20026 Novate Milanese (MI)', 45.532806, 9.1421261,
  'https://www.modellismomilano.it/',
  'Lun-sab 9:30-13:00 e 15:30-19:30 (lunedi'' mattina chiuso)',
  'Modellismo statico e dinamico con automodelli, elicotteri, droni e motoscafi RC, laboratorio interno per assistenza e riparazioni e pista off road propria.',
  'https://www.google.com/maps/search/?api=1&query=45.532806,9.1421261',
  '+39 02 23054659', true, 'approved', true, null),

 ('modellismo-varesino-castronno', 'Modellismo Varesino', 'Castronno', 'IT',
  'Via Lombardia, 6, 21040 Castronno (VA)', 45.7539262, 8.8098737,
  'https://www.modellismovaresino.it/',
  'Mar-sab 9:30-12:30 e 15:30-19:30, lunedi'' mattina chiuso',
  'Modellismo dinamico: auto, camion, aerei, elicotteri, droni e imbarcazioni RC, piu'' fermodellismo; i modelli si possono provare in negozio.',
  'https://www.google.com/maps/search/?api=1&query=45.7539262,8.8098737',
  '+39 0332 892467', true, 'approved', true, null),

 ('team-model-corsico', 'Team Model di Alberto Poli', 'Corsico', 'IT',
  'Via Giuseppe Garibaldi, 47, 20094 Corsico (MI)', 45.4307376, 9.1085735,
  'https://www.teammodel.it/', null,
  'Modellismo statico e dinamico con auto RC elettriche e a scoppio, droni, elicotteri e barche; esegue riparazione, restauro e messa a punto dei modelli.',
  'https://www.google.com/maps/search/?api=1&query=45.4307376,9.1085735',
  '+39 02 45100439', true, 'approved', true, null),

 ('modellismo-fioroni-casarile', 'Modellismo Fioroni', 'Casarile', 'IT',
  'Via Vincenzo Monti, 4, 20059 Casarile (MI)', 45.3136507, 9.1050938,
  'https://www.modellismofioroni.com/', null,
  'Specializzato in automodelli RC elettrici e a scoppio dalla scala 1:8 alla 1:18, con ricambi, elettronica, motori, gomme e cerchi.',
  'https://www.google.com/maps/search/?api=1&query=45.3136507,9.1050938',
  '+39 02 90096362', true, 'approved', true, null),

 ('modeltecnic-lissone', 'Modeltecnic', 'Lissone', 'IT',
  'Via Martiri della Liberta'', 74/C, 20851 Lissone (MB)', 45.6191571, 9.2463739,
  'https://www.modeltecnic.it/', null,
  'Negozio storico di modellismo dinamico e statico: aeromodellismo, automodellismo RC e slot.',
  'https://www.google.com/maps/search/?api=1&query=45.6191571,9.2463739',
  '+39 039 4669028', true, 'approved', true, null)
on conflict (slug) do nothing;

select 'piste' as tipo, count(*) from public.tracks where is_community
union all
select 'negozi', count(*) from public.shops where is_community;
