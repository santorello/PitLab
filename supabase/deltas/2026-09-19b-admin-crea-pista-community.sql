-- 2026-09-19b — Mancava nel delta precedente: la funzione che crea la scheda
-- "segnalata dalla community" dal pannello admin (pulsante "Nuova scheda community").
-- submitted_by NULL → nessun gestore automatico e nessun PitCoin. Idempotente.
create or replace function public.admin_create_community_track(
  p_name text, p_city text, p_address text default null,
  p_latitude double precision default null, p_longitude double precision default null,
  p_website text default null, p_hours text default null,
  p_short_description text default null, p_map_url text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_slug text; v_id uuid;
begin
  if not public.is_admin() then raise exception 'Solo admin' using errcode = '42501'; end if;
  v_slug := regexp_replace(lower(trim(p_name) || '-' || trim(p_city)), '[^a-z0-9]+', '-', 'g');
  v_slug := trim(both '-' from v_slug);
  if exists (select 1 from tracks where slug = v_slug) then
    v_slug := v_slug || '-' || substr(md5(random()::text), 1, 4);
  end if;

  insert into tracks(slug, name, city, country, address, latitude, longitude,
                     website_url, hours, short_description, external_map_url,
                     is_public, approval_status, is_community, submitted_by)
  values (v_slug, trim(p_name), trim(p_city), 'IT', nullif(trim(coalesce(p_address,'')),''),
          p_latitude, p_longitude, nullif(trim(coalesce(p_website,'')),''),
          nullif(trim(coalesce(p_hours,'')),''), nullif(trim(coalesce(p_short_description,'')),''),
          nullif(trim(coalesce(p_map_url,'')),''), true, 'approved', true, null)
  returning id into v_id;
  return v_id;
end $$;

revoke execute on function public.admin_create_community_track(text,text,text,double precision,double precision,text,text,text,text) from public, anon;
grant execute on function public.admin_create_community_track(text,text,text,double precision,double precision,text,text,text,text) to authenticated;

-- Verifica (atteso: 1)
select count(*) from pg_proc where proname = 'admin_create_community_track';
