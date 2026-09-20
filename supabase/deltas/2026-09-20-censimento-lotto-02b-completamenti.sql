-- Completamenti lotto 02 — orari presi dalle schede Google Maps il 2026-09-20
-- e prima copertina disponibile. Solo update: non crea nulla.

update public.tracks set
  hours = 'Lun-gio 8:00-18:00, ven-dom 8:00-20:00',
  image_url = 'https://www.srboffroad.it/wp-content/uploads/2024/09/460624765_857851353079590_186937425199971133_n.jpg',
  updated_at = timezone('utc', now())
where slug = 'srb-offroad-nembro';

update public.tracks set
  hours = 'Sab 10:30-17:30, dom 10:30-12:30 e 14:30-17:30 (lun-ven chiuso)',
  updated_at = timezone('utc', now())
where slug = 'trial-attack-racing-team-rescaldina';

update public.shops set
  hours = 'Lun-ven 16:00-19:15, sab 10:00-12:30 e 15:00-19:15, domenica chiuso',
  updated_at = timezone('utc', now())
where slug = 'team-model-corsico';

update public.shops set
  hours = 'Mar-ven 14:30-19:00, sab 10:00-13:00, dom e lun chiuso',
  updated_at = timezone('utc', now())
where slug = 'modellismo-fioroni-casarile';

update public.shops set
  hours = 'Lun 15:30-19:15, mar-sab 9:30-12:00 e 15:30-19:15, domenica chiuso',
  updated_at = timezone('utc', now())
where slug = 'modeltecnic-lissone';

-- Verifica: quante schede restano senza orari o senza copertina
select 'piste senza orari' v, count(*) from public.tracks where is_community and hours is null
union all select 'piste senza copertina', count(*) from public.tracks where is_community and image_url is null
union all select 'negozi senza orari', count(*) from public.shops where is_community and hours is null
union all select 'negozi senza copertina', count(*) from public.shops where is_community and image_url is null;
