-- Censimento lotto 14 — 5 negozi (CA, CT, ME, SR).
-- Dati verificati il 2026-09-27: coordinate, indirizzi, telefoni, orari e stato dalla scheda
-- Google Maps del posto; descrizioni e servizi solo dal testo del sito ufficiale (home e chi siamo).
-- Copertine: foto della scheda Maps, guardate in griglia; provvisorie finche il titolare non rivendica.
-- Siti rotti o segnalati non sicuri: link omesso. Idempotente.

insert into public.shops(slug, name, city, country, address, latitude, longitude,
  website_url, hours, short_description, external_map_url, image_url, phone, service_labels,
  is_public, approval_status, is_community, submitted_by)
values
 ('model-kit-planet-cagliari', 'Model Kit Planet', 'Cagliari', 'IT',
  'Via Giuseppe Abba, 37, 09129 Cagliari (CA)', 39.2172505, 9.1200372,
  null, 'Lun-ven 9:30-13:00 e 16:30-20:00; sab 9:30-13:00 e 17:00-19:30; domenica chiuso',
  null,
  'https://www.google.com/maps/search/?api=1&query=39.2172505,9.1200372',
  'https://lh3.googleusercontent.com/gps-cs-s/ANWiy9S_hEo2rkAY9pYIehD6sXNul4MgRaKxrJmKj8rgRewk-AykHFr6rLsV2e5Hbk1is5rI09I1OvtWOTC9bj9Yh_KTHMSSZV2QIQEvP9cI0O8nY74Te9V5pSmTAzAw0vvnq_MNpK4=w1200-h630-k-no',
  '+39 347 623 2331', null, true, 'approved', true, null),
 ('hobby-modellismo-e-giocattoli-messina', 'Hobby Modellismo e Giocattoli', 'Messina', 'IT',
  'Via Nino Bixio, 117, 98123 Messina (ME)', 38.1835562, 15.5518174,
  null, 'Lun-sab 8:30-13:00 e 16:30-20:00; domenica chiuso',
  null,
  'https://www.google.com/maps/search/?api=1&query=38.1835562,15.5518174',
  'https://lh3.googleusercontent.com/gps-cs-s/ANWiy9Q3pWqRtBXKRDtgWREikfgzN9vN8at0RmhOgZ3CH7lZkrudyGX0EKN1EqEIxewrcCJ3KdhnDnB2e20SRxRMMHHJL1Ak9j3ivjtDoaXr9YTO9FeMXXQrkaF-RRKAjs4d_XRS2hC9=w1200-h630-k-no',
  '+39 340 289 3209', null, true, 'approved', true, null),
 ('ideal-model-catania', 'Ideal Model', 'Catania', 'IT',
  'Via Vincenzo Giuffrida, 107, 95127 Catania (CT)', 37.5206867, 15.0912348,
  null, 'Lun-ven 10:00-13:00 e 17:00-20:00; sab-dom chiuso',
  null,
  'https://www.google.com/maps/search/?api=1&query=37.5206867,15.0912348',
  'https://lh3.googleusercontent.com/gps-cs-s/ANWiy9TIoYErisfmXMO1PM2L_MOpFjvVIXILyFOwic4y5q5EdciLnZmq82lCG5L9ETz6Ki8YCGQ-sgqJPIPlTmOoJcq5VIMp4hS5ZrNL4ExcRqJMj3D92uPM8-jQg0Jj8RJVR-L-y8IVwg=w1200-h630-k-no',
  '+39 095 246 4029', null, true, 'approved', true, null),
 ('cdf-modellismo-catania', 'CDF Modellismo', 'Catania', 'IT',
  'Via Firenze, 15, 95129 Catania (CT)', 37.5168657, 15.0979606,
  'https://www.cdfmodellismo.net', 'Lun 16:30-20:00; mar-sab 9:00-13:00 e 16:30-20:00; domenica chiuso',
  'Nel centro storico di Catania, modellismo statico: carri armati, mezzi militari, navi storiche, elicotteri, aerei, moto e auto.',
  'https://www.google.com/maps/search/?api=1&query=37.5168657,15.0979606',
  'https://lh3.googleusercontent.com/gps-cs-s/ANWiy9RILHz2Ix78e-iqYN-TIKJcXMosoLIi0K0Q-6CSV2WgTcSojUX_Knvf-i1ItKfx624fWZLfCjqNIw44ejKBIVa0OhFiO7E671nv-fJgmMYzBGaQkeyhwlIJA8jyCigELP8sZDGsag=w1200-h630-k-no',
  '+39 095 383654', null, true, 'approved', true, null),
 ('centro-model-villasmundo', 'Centro Model', 'Villasmundo', 'IT',
  'Via Vittorio Emanuele, 196, 96010 Villasmundo (SR)', 37.2518232, 15.0887424,
  null, 'Lun-sab 9:30-12:30 e 16:30-20:00; domenica chiuso',
  null,
  'https://www.google.com/maps/search/?api=1&query=37.2518232,15.0887424',
  null,
  '+39 334 193 5780', null, true, 'approved', true, null)
on conflict (slug) do nothing;

-- Verifica
select s.slug, s.name, s.city, (s.latitude is not null) coord, (s.hours is not null) orari,
  (s.short_description is not null) descr, (s.image_url is not null) img, (s.website_url is not null) sito
from public.shops s where s.slug in ('model-kit-planet-cagliari', 'hobby-modellismo-e-giocattoli-messina', 'ideal-model-catania', 'cdf-modellismo-catania', 'centro-model-villasmundo')
order by s.slug;
