-- Controllo duplicati per piste, negozi e spot (task 18, ondata 0).
-- L'app chiama find_similar_places() prima di salvare un nuovo luogo e,
-- se trova candidati, chiede "Esiste gia'?".
-- Regola: stesso tipo di luogo e
--   (a) entro 300 m, oppure
--   (b) nome simile (trigram >= 0.35) entro 15 km, oppure
--   (c) senza coordinate: nome simile nella stessa citta'.
-- Il nome viene ripulito dalle parole generiche (pista, minipista, rc, club...)
-- prima del confronto, altrimenti "Pista RC X" e "Pista RC Y" sembrerebbero uguali.
-- Restituisce anche i luoghi in attesa di approvazione (flag is_pending), ma
-- solo nome, citta' e distanza: niente dati di chi li ha proposti.
-- Idempotente.

create extension if not exists pg_trgm with schema extensions;

create or replace function public.normalize_place_name(p text)
returns text
language sql
immutable
set search_path = ''
as $$
  select trim(regexp_replace(
    regexp_replace(
      lower(translate(coalesce(p, ''),
        'àáâäèéêëìíîïòóôöùúûüç''’', 'aaaaeeeeiiiioooouuuuc  ')),
      '\m(pista|piste|minipista|minicircuito|circuito|autodromo|miniautodromo|rc|asd|a\.s\.d\.|club|model|modellismo|modelli|team|gruppo|associazione|di|del|della|dei|delle|il|la|lo|le|i|gli|the)\M',
      ' ', 'g'),
    '\s+', ' ', 'g'))
$$;

create or replace function public.find_similar_places(
  p_kind text,
  p_name text,
  p_city text default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_exclude_id uuid default null
)
returns table (
  kind text,
  id uuid,
  slug text,
  name text,
  city text,
  distance_m integer,
  name_score real,
  is_pending boolean
)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_norm text := public.normalize_place_name(p_name);
begin
  if p_kind not in ('track', 'shop', 'spot') or length(trim(coalesce(p_name, ''))) < 3 then
    return;
  end if;

  return query
  with candidates as (
    select 'track'::text as kind, t.id, t.slug, t.name, t.city, t.latitude, t.longitude,
           (t.approval_status <> 'approved') as is_pending
      from tracks t
     where p_kind = 'track' and t.approval_status in ('approved', 'pending', 'draft')
    union all
    select 'shop', s.id, s.slug, s.name, s.city, s.latitude, s.longitude,
           (s.approval_status <> 'approved')
      from shops s
     where p_kind = 'shop' and s.approval_status in ('approved', 'pending', 'draft')
    union all
    select 'spot', sp.id, sp.slug, sp.title, sp.city, sp.latitude, sp.longitude, false
      from spots sp
     where p_kind = 'spot'
  ),
  scored as (
    select c.*,
           case when p_lat is not null and p_lng is not null
                     and c.latitude is not null and c.longitude is not null
                then (2 * 6371000 * asin(sqrt(
                       power(sin(radians(c.latitude - p_lat) / 2), 2)
                       + cos(radians(p_lat)) * cos(radians(c.latitude))
                       * power(sin(radians(c.longitude - p_lng) / 2), 2))))::integer
           end as dist,
           similarity(public.normalize_place_name(c.name), v_norm) as score
      from candidates c
     where p_exclude_id is null or c.id <> p_exclude_id
  )
  select s.kind, s.id, s.slug, s.name, s.city, s.dist, s.score, s.is_pending
    from scored s
   where (s.dist is not null and s.dist <= 300)
      or (s.dist is not null and s.dist <= 15000 and s.score >= 0.35)
      or (s.dist is null and s.score >= 0.35
          and p_city is not null and lower(trim(s.city)) = lower(trim(p_city)))
      or (s.score >= 0.7)
   order by (s.dist is not null and s.dist <= 300) desc, s.score desc, s.dist nulls last
   limit 5;
end;
$$;

revoke execute on function public.find_similar_places(text, text, text, double precision, double precision, uuid) from public, anon;
grant execute on function public.find_similar_places(text, text, text, double precision, double precision, uuid) to authenticated;
