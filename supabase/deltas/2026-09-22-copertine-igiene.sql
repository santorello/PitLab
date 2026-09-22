-- Igiene copertine (2026-09-22).
-- Melzo: era il thumbnail Wix da 320x213 (sgranato sulla card). Stessa foto aerea,
-- versione originale 800x533 dal sito del club. Idempotente.
update public.tracks set
  image_url = 'https://static.wixstatic.com/media/018b37_bd601b2724c74906ae135d34208b5621.jpg',
  updated_at = timezone('utc', now())
where slug = 'pista-melzorc-melzo';

-- ATTENZIONE, non risolvibile da qui: due copertine puntano a Facebook (scontent.*.fbcdn.net)
-- e quegli URL scadono. Parametro oe= nelle due righe:
--   trial-attack-racing-team-rescaldina  -> scade il 2026-09-25
--   team-model-corsico                   -> scade il 2026-09-26
-- Dopo quella data le card restano senza immagine. Servono foto sostitutive
-- (dal titolare, o una foto propria) da caricare nello Storage.

select slug, image_url from public.tracks where slug = 'pista-melzorc-melzo';
