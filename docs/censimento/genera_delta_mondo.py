# -*- coding: utf-8 -*-
"""Delta SQL unico per il censimento estero (fonte ChatGPT, revisione Google Maps 2026-09-28).
Solo righe stato=verificato di mondo-censimento-revisionato.csv. Idempotente."""
import csv, os
ROOT=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC=os.path.join(ROOT,'docs','censimento','mondo-censimento-revisionato.csv')
OUT=os.path.join(ROOT,'supabase','deltas','2026-09-28-censimento-mondo-UNICO.sql')
rows=[r for r in csv.DictReader(open(SRC,encoding='utf-8-sig'),delimiter=';') if r['stato']=='verificato']
assert len({r['slug'] for r in rows})==len(rows)
q=lambda v:'null' if v in (None,'') else "'"+str(v).strip().replace("'","''")+"'"
def arr(s):
    ls=[x.strip() for x in s.split('|') if x.strip()]
    return 'null' if not ls else 'array['+','.join(q(x) for x in ls)+']'
def vals(r,extra):
    return ("("+", ".join([q(r['slug']),q(r['nome']),q(r['citta']),q(r['paese'])])+",\n  "+q(r['indirizzo'])+f", {float(r['lat'])}, {float(r['lon'])},\n  "
      +", ".join([q(r['website_url']),q(r['hours'])])+",\n  "+q(r['short_description'])+",\n  "+q(r['external_map_url'])+", null, "+q(r['phone'])+", "+extra
      +", true, 'approved', true, null)")
T=[r for r in rows if r['tipo']=='pista']; S=[r for r in rows if r['tipo']=='negozio']
L=["-- Censimento estero: "+f"{len(T)} piste + {len(S)} negozi in "+str(len({r['paese'] for r in rows}))+" paesi.",
   "-- Raccolta: ChatGPT (fonti ufficiali). Revisione 2026-09-28: coordinate, telefono e orari dalla scheda",
   "-- Google Maps del posto; esclusi i chiusi definitivamente e i risultati Maps non corrispondenti.",
   "-- Descrizioni e orari in inglese. Copertine: nessuna, arrivano con un delta dedicato. Idempotente.","",
   "insert into public.tracks(slug, name, city, country, address, latitude, longitude,",
   "  website_url, hours, short_description, external_map_url, image_url, phone,",
   "  organization_name, is_public, approval_status, is_community, submitted_by)","values",
   ',\n'.join(vals(r,'null') for r in T),"on conflict (slug) do nothing;","",
   "insert into public.shops(slug, name, city, country, address, latitude, longitude,",
   "  website_url, hours, short_description, external_map_url, image_url, phone, service_labels,",
   "  is_public, approval_status, is_community, submitted_by)","values",
   ',\n'.join(vals(r,arr(r['service_labels'])) for r in S),"on conflict (slug) do nothing;",""]
cats=[(r['slug'],c.strip()) for r in T for c in r['categorie_pista'].split(',') if c.strip()]
svcs=[(r['slug'],c.strip()) for r in T for c in r['servizi_pista'].split(',') if c.strip()]
L+=["-- Categorie e servizi: solo quelli dichiarati alla lettera dalla fonte",
    "insert into public.track_category_links(track_id, category_id)",
    "select t.id, c.id from public.tracks t, public.track_categories c where (t.slug, c.key) in (",
    ',\n'.join(f"  ({q(a)}, {q(b)})" for a,b in cats)+")","on conflict do nothing;","",
    "insert into public.track_services(track_id, service_type_id, is_available)",
    "select t.id, s.id, true from public.tracks t, public.service_types s where (t.slug, s.key) in (",
    ',\n'.join(f"  ({q(a)}, {q(b)})" for a,b in svcs)+")",
    "on conflict (track_id, service_type_id) do update set is_available = true;","",
    "-- Verifica",
    "select 'tracks' tipo, country, count(*) from public.tracks where slug in ("+", ".join(q(r['slug']) for r in T)+") group by country",
    "union all",
    "select 'shops', country, count(*) from public.shops where slug in ("+", ".join(q(r['slug']) for r in S)+") group by country",
    "order by 1, 2;"]
open(OUT,'w',encoding='utf-8',newline='\n').write('\n'.join(L)+'\n')
print(OUT, len(T), len(S), len(cats), len(svcs))
