-- Lotto 06b — 4 spot drone dall'inventario YouTube (foglio "Lotto 10").
-- Stessa impostazione dello spot "Greto del Ticino" gia' in produzione:
-- category 'Droni', best_for_tags ['fpv_drone'], nota con l'avviso ENAC/d-flight.
-- Copertine: fotogramma del video di Giuseppe (i.ytimg.com), materiale suo.
-- Coordinate e stato verificati su Google Maps il 2026-09-22. Idempotente.
--
-- NON inclusi, in attesa di un punto preciso: Parco delle Groane (comune e percorso
-- da identificare), piazzale Forum Assago (piazzale esatto e uso consentito),
-- Cava di Verbania (cava e proprieta' da identificare).

insert into public.spots(slug, title, city, address, latitude, longitude, category,
  best_for_tags, surface_tags, access_type, best_season, note, video_url, image_urls, is_custom)
values
 ('santuario-madonna-del-sangue-re-drone', 'Santuario della Madonna del Sangue - Re', 'Re',
  'Via Locarno, 4, 28856 Re (VB)', 46.1302841, 8.5450207, 'Droni',
  array['fpv_drone'], array['mixed'], 'permission', 'all_year',
  'Santuario in Valle Vigezzo ripreso dall''alto: fondovalle stretto e pareti, panorama d''effetto. La posizione e'' il punto d''interesse, non un punto di decollo autorizzato: verificare la mappa d-flight e i permessi del luogo prima di ogni volo.',
  'https://youtu.be/XuRVBbzN1yk', array['https://i.ytimg.com/vi/XuRVBbzN1yk/sddefault.jpg'], false),

 ('camping-hermitage-craveggia-drone', 'Camping Hermitage - Craveggia', 'Craveggia',
  'Via Melezzo Siberia, 43, 28852 Craveggia (VB)', 46.1370356, 8.4787674, 'Droni',
  array['fpv_drone'], array['grass','water','mixed'], 'private', 'all_year',
  'Campeggio in Valle Vigezzo tra prati e torrente, ripreso in piu'' video dall''alto. Struttura privata: chiedere il consenso al gestore e verificare la mappa d-flight prima di volare.',
  'https://youtu.be/8VW-cLMK9Tc', array['https://i.ytimg.com/vi/8VW-cLMK9Tc/maxresdefault.jpg'], false),

 ('tabiano-castello-drone', 'Tabiano Castello - panorama drone', 'Salsomaggiore Terme',
  'Via Castello, 43039 Tabiano, Salsomaggiore Terme (PR)', 44.7921554, 10.0240814, 'Droni',
  array['fpv_drone'], array['mixed'], 'permission', 'all_year',
  'Borgo e castello sulle colline parmensi, ripresi dall''alto. Luogo privato: la posizione e'' il punto d''interesse, il decollo va fatto da un punto lecito e dopo la verifica d-flight.',
  'https://youtu.be/H9cUqZ2DkXg', array['https://i.ytimg.com/vi/H9cUqZ2DkXg/maxresdefault.jpg'], false),

 ('spiaggia-varcaro-drone', 'Spiaggia di Varcaro - drone', 'Monte Sant''Angelo',
  'Localita'' Varcaro, frazione Macchia, 71037 Monte Sant''Angelo (FG)', 41.6631326, 15.9905322, 'Droni',
  array['fpv_drone'], array['sand','rock'], 'permission', 'summer',
  'Baia del Gargano tra sabbia e roccia, ripresa dall''alto. Area costiera: controllare affollamento, concessioni balneari, tutela ambientale e mappa d-flight prima di volare.',
  'https://youtu.be/ktYBHL-fAt0', array['https://i.ytimg.com/vi/ktYBHL-fAt0/maxresdefault.jpg'], false)
on conflict (slug) do nothing;

select slug, city, category, access_type, best_season, (image_urls is not null) img, (latitude is not null) coord
from public.spots where category = 'Droni' order by slug;
