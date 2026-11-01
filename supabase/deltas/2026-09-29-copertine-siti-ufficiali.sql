-- Copertine dal SITO UFFICIALE del posto (niente foto Google Maps), guardate una per una in griglia.
-- Scartate: loghi, locandine, banner con testo, foto prodotto/stock, immagini condivise da directory.
-- Aggiorna solo le schede ancora senza copertina: non tocca foto caricate dai titolari. Idempotente.

update public.shops x set image_url = v.u, updated_at = timezone('utc', now())
from (values
  ('bhm-neder-over-heembeek', 'https://primary.jwwb.nl/public/o/j/r/temp-vwlxgaicjglytydlyviz/268652388_2985458005047662_4880092387702386665_n-standard.jpg?enable-io=true&enable=upscale&crop=960%2C480%2Cx0%2Cy120%2Csafe'),
  ('frankton-model-shop-hamilton', 'https://franktonmodels.co.nz/cdn/shop/files/IMG_8402.jpg?v=1729807868&width=1400'),
  ('hobby-action-store-chandler', 'https://cdn.shoplightspeed.com/shops/660520/themes/16959/v/518307/assets/promo-1.jpg?20220621214256'),
  ('hobby-models-bcn-barcelona', 'https://hobbymodelsbcn.com/wp-content/uploads/2026/01/Tienda-hobby-models-bcn-02.jpg'),
  ('lcrc-raceway-hobby-shop-oakland-mills', 'https://cdn.shopify.com/s/files/1/0178/9640/7104/files/2024_Mugen_Overhead.jpg?v=1770836752'),
  ('lichtblitz-pfeiffer-wendelstein', 'https://shop.lichtblitz-pfeiffer.de/img/cms/RCfachgesch%C3%A4ft.jpg'),
  ('mb-models-oulton', 'https://images.rccarshop.co.uk/branding/store.jpg?w=700'),
  ('mob-rc-modellbau-berlin', 'https://www.mob-rc.de/wp-content/uploads/2023/07/laden-cut-1400.jpg'),
  ('modelisme-33-merignac', 'https://modelisme33.net/wp-content/uploads/2019/10/cropped-IMG_8461-2-scaled.jpg'),
  ('rc-garage-hobby-shop-boronia', 'https://cdn.shopify.com/s/files/1/0053/8932/0263/files/shopphotoBWwide.jpg?v=1557118808'),
  ('rc-planet-malaysia-shah-alam', 'https://www.rcplanet.com.my/wp-content/uploads/2023/07/shop.jpg'),
  ('rc-tank-legion-shop-shah-alam', 'https://cdn.store-assets.com/s/119476/f/17583605.jpg'),
  ('select-models-shop-lyon', 'https://www.selectmodels.shop/wp-content/uploads/2025/11/DSC8455-scaled.jpg'),
  ('skane-hobby-bjarred', 'https://skanehobby.se/wp-content/uploads/2026/08/IMG_8286-scaled-1.webp'),
  ('the-track-r-c-racing-hobby-shop-gaithersburg', 'https://static.wixstatic.com/media/a04eda_227a0d8986b6473f8c06ad9573e05c95~mv2.jpg/v1/fill/w_806,h_256,al_c/a04eda_227a0d8986b6473f8c06ad9573e05c95~mv2.jpg'),
  ('wetronic-nieuwegein', 'https://rc-world.nl/wp-content/uploads/2024/09/wetronic-winkel-nieuwegein-buiten_bewerkt.jpg'),
  ('power-toys-atvidaberg', 'https://d1da7yrcucvk6m.cloudfront.net/sites/1519/media/3063012_original_IMG_3907.JPG')
) as v(slug, u)
where x.slug = v.slug and coalesce(x.image_url,'') = '';

update public.tracks x set image_url = v.u, updated_at = timezone('utc', now())
from (values
  ('400-rc-compound-springwater', 'https://assets.cdn.filesafe.space/a9lOaGs50dOfUcY6KIN8/media/65a02889a5f28a621a97e671.jpeg'),
  ('association-modeliste-occitane-montpellier', 'https://amo-montpellier.fr/images/amo_piste.webp'),
  ('auckland-radio-control-car-club-auckland', 'https://res.cloudinary.com/nzrca/image/upload/c_fill,h_630,q_80,w_1200/v1/clubs/heroImage/rrajapx6zllkk2hkmc98.jpg'),
  ('buggittre-racing-haut-ittre', 'https://buggittre.be/wp-content/uploads/2025/03/2025-2.jpg'),
  ('camrc-coquitlam', 'https://i.vimeocdn.com/video/1758261715-f7be814f4ca93e54f0c6e7d50dd21cd895f4b9a50ca05ee39d76f5aa4257ece5-d_1280x720?r=pad'),
  ('canterbury-radio-control-car-club-christchurch', 'https://res.cloudinary.com/nzrca/image/upload/c_fill,h_630,q_80,w_1200/v1/clubs/heroImage/mbnmsvlsd0no1ukrzpi0.jpg'),
  ('castle-hill-rc-on-road-castle-hill', 'https://www.castlehillrc.com.au/images/chrc-home.jpg'),
  ('draha-rc-mcc-brno-brno', 'https://www.rcautomodely.com/fotky/CIMG0451.JPG'),
  ('efac-hohenems-hohenems', 'https://www.efac-hohenems.at/wp-content/uploads/2021/08/Strecke_2019_1.jpg'),
  ('harewood-radio-control-car-club-christchurch', 'https://res.cloudinary.com/nzrca/image/upload/c_fill,h_630,q_80,w_1200/v1/clubs/heroImage/pnfx6c0dn7e1lqkumqg5.jpg'),
  ('hobby-action-rc-raceway-chandler', 'https://cdn.shoplightspeed.com/shops/660520/themes/16959/v/518307/assets/promo-1.jpg?20220621214256'),
  ('john-grant-international-raceway-moorebank', 'https://www.nswrcrcc.org.au/wp-content/uploads/2025/01/IMG_5546-scaled-e1740300814999-1024x511.jpeg'),
  ('lcrc-raceway-oakland-mills', 'https://cdn.shopify.com/s/files/1/0178/9640/7104/files/2022_Mugen_Overhead.jpg?v=1770836690'),
  ('mac-amstetten-greinsfurth', 'https://mac-amstetten.at/images/IMG-20260429-WA0007.jpg'),
  ('mainland-model-racers-rolleston', 'https://res.cloudinary.com/nzrca/image/upload/c_fill,h_630,q_80,w_1200/v1/clubs/heroImage/y6mduvh4frvlkl7odvsu.jpg'),
  ('model-auto-club-heemstede-heemstede', 'https://www.machheemstede.nl/wp-content/uploads/2020/03/Track-Picture-become-a-member.jpg'),
  ('model-race-genk-genk', 'https://www-static.modelracegenk.be/wp-content/uploads/2019/02/18485978_1325555994158530_2630867447527019240_n.jpg'),
  ('power-toys-raceway-atvidaberg', 'https://d1da7yrcucvk6m.cloudfront.net/sites/1519/media/3284017_large_IMG_6874.webp'),
  ('race-palace-oberaach', 'https://www.race-palace.ch/wp-content/uploads/2019/11/cropped-Piste_rechts-3.jpg'),
  ('racing-club-roeselare-roeselare', 'https://www.racingclubroeselare.be/wp-content/uploads/sites/10/2024/05/Track1.jpg'),
  ('raco2000-utrecht', 'https://www.raco2000.nl/wp-content/uploads/2019/09/cropped-header3.png'),
  ('rc-arena-kostrzyn-kostrzyn', 'https://rckostrzyn.com/wp-content/uploads/2024/05/dji_fly_20240320_161022_273_1710957236991_photo-scaled.jpg'),
  ('rc-banan-hos-skane-hobby-bjarred', 'https://stage.skanehobby.se/wp-content/uploads/2026/06/IMG_8261.webp'),
  ('rc-cars-wernigerode-wernigerode', 'https://rc-car-wr.de/wp-content/uploads/2026/04/20250927_142136-2048x1153.jpg'),
  ('rc-indoor-bleiswijk-bleiswijk', 'https://www.rcindoorbleiswijk.nl/assets/images/processed/img_0687-1024x576-general.webp'),
  ('rc-tank-legion-battlefield-shah-alam', 'https://cdn.store-assets.com/s/119476/f/17583607.jpg'),
  ('silver-dollar-rc-raceway-chico', 'https://amaintracks.com/wp-content/uploads/2016/11/track-drivers-stand.jpg'),
  ('storm-raceway-kavlinge', 'https://japtuning.se/wp-content/uploads/2025/07/Dronarbild.jpg'),
  ('swiss-micro-racer-affeltrangen', 'https://swissmicroracer.ch/clubdesk/fileservlet?type=image&id=1000307&s=djEtRTATudGycDRo0FURleX2whwJ-9UkcOC7Qzhq5mFdQCk=&imageFormat=_2048x2048'),
  ('the-track-gaithersburg', 'https://static.wixstatic.com/media/a04eda_227a0d8986b6473f8c06ad9573e05c95~mv2.jpg/v1/fill/w_806,h_256,al_c/a04eda_227a0d8986b6473f8c06ad9573e05c95~mv2.jpg'),
  ('toys-world-sant-angelo-lodigiano', 'https://www.toysworld.it/wp-content/uploads/2024/10/pista.toysworld.2024-scaled.jpg')
) as v(slug, u)
where x.slug = v.slug and coalesce(x.image_url,'') = '';

-- Verifica
select 'shops' t, count(*) filter (where coalesce(image_url,'')<>'') con_cover, count(*) tot from public.shops where is_public
union all select 'tracks', count(*) filter (where coalesce(image_url,'')<>''), count(*) from public.tracks where is_public;
