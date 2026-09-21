-- Allinea track_categories di DEV a PROD (solo dev: su prod e' gia' cosi').
-- Idempotente. Le chiavi contano, gli id possono differire.
insert into track_categories (id, key, label_it, label_en, sort_order) values
  ('4e529ac8-2664-4472-9fc7-0e233dfdb3c1','fpv','FPV','FPV',405009),
  ('b1bbf5f5-f578-442c-85cf-2e64b481fb0b','navale','Navale','Navale',454674),
  ('69e63632-0468-4889-b0dc-1064405d6da8','rally','Rally','Rally',429075)
on conflict (key) do nothing;

update track_categories set label_it='Fermodellismo', label_en='Model railways', sort_order=120 where key='treni';
update track_categories set label_en='On-Road', sort_order=425752 where key='on_road';

-- Francobolli: eliminata su prod da Giuseppe il 15/09
delete from track_category_links where category_id in (select id from track_categories where key='francobolli');
delete from track_categories where key='francobolli';

select key, label_it from track_categories order by key;
