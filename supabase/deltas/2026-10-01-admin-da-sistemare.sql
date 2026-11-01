-- 2026-10-01 — Admin: elenco "Da sistemare" + eventi scaduti fuori dal conteggio.
-- 1) admin_content_to_fix(): le righe che compongono `content_to_fix`.
--    Stessi filtri della dashboard: numero ed elenco restano allineati.
--    Uno spot senza coordinate e senza foto compare due volte (due motivi),
--    come viene contato due volte nel numero.
-- 2) Gli eventi finiti NON sono più "da sistemare": l'app li toglie già da
--    "In evidenza" e li mostra tra i passati (lo storico di PitLap).
--    admin_dashboard() differisce tra dev e prod: invece di riscriverla tutta
--    si toglie solo quella riga dalla definizione già installata.
-- Idempotente.

create or replace function public.admin_content_to_fix()
returns table (kind text, id text, slug text, title text, reason text, ref_at timestamptz)
language sql stable security definer set search_path = public as $$
  select * from (
    select 'spot'::text as k, s.id::text as i, s.slug as sl, s.title as t, 'no_coords'::text as rs, s.created_at as ts
      from spots s where s.latitude is null or s.longitude is null
    union all
    select 'spot', s.id::text, s.slug, s.title, 'no_photo', s.created_at
      from spots s where coalesce(array_length(s.image_urls, 1), 0) = 0
  ) r
  where public.is_admin()
  order by k, ts;
$$;

revoke execute on function public.admin_content_to_fix() from public, anon;
grant execute on function public.admin_content_to_fix() to authenticated;

do $$
declare
  d text := pg_get_functiondef('public.admin_dashboard()'::regprocedure);
  n text := replace(d,
    E'\n      + (select count(*) from community_events where coalesce(ends_at, starts_at) < now() - interval ''7 days''))',
    ')');
begin
  if n <> d then execute n; end if;  -- già tolta: niente da fare
end $$;
