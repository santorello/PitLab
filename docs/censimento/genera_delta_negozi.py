# -*- coding: utf-8 -*-
"""Genera i delta SQL dei negozi censiti il 2026-09-27 (lotti 07-14).
Fonte: docs/censimento/negozi-censimento-2026-09-27.csv (solo stato CENSIBILE)."""
import csv, re, unicodedata, os
ROOT=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC=os.path.join(ROOT,'docs','censimento','negozi-censimento-2026-09-27.csv')
OUT=os.path.join(ROOT,'supabase','deltas')

# Nome d'insegna: la ragione sociale di Maps non va in vetrina.
NOME={
 'AMT Modellismo Torino':'AMT Modellismo','Astromodel Sas':'Astromodel','Big Shop - Model Treno':'Big Shop Model Treno',
 'Bsm Modellismo':'BSM Modellismo','CM MODELLISMO':'CM Modellismo',"Car's Show Modellismo Brugherio":"Car's Show Modellismo",
 'Cdf Modellismo':'CDF Modellismo','D.P Modellismo':'D.P. Modellismo','Electronic Dreams sas':'Electronic Dreams',
 'Fontana treni':'Fontana Treni','G.P. Modellismo di Pierini Gabriele':'G.P. Modellismo','Granda Models Cuneo - G.M.C.':'Granda Models',
 'H0 modellismo':'H0 Modellismo','Hobbitalia 2 sas di Federico Barthel & C.':'Hobbitalia 2',
 'Hobby Modellismo Villanova Di Castenaso':'Hobby Modellismo','ISACCO ...i treni':'Isacco i Treni','Il Principe Del Mare':'Il Principe del Mare',
 'Marklin Shop Di Umberto Rossi':'Märklin Shop','Mary S.A.S. Di Asaro Francesco & C.':'Mary Modellismo','Mdmodel Snc di Gaudenzi & C':'MDModel',
 'Model Kit Planet Modellismo Cagliari':'Model Kit Planet','Model Marris modellismo & Lego':'Model Marris',
 'Modellismo Bartoli Severi Giovanni':'Modellismo Bartoli','Modellismo E Hobbystica di Renzetti Vincenzo':'Modellismo e Hobbystica',
 'Modellismo Edomodel':'Edomodel','Modellismo F. Baracca':'Modellismo Baracca','Modellismo Ferroviario Portigliatti':'Modellismo Portigliatti',
 'Modellismo Marily Di Semeria Monica':'Modellismo Marily','Modellismo Negri Giordano':'Modellismo Negri',
 'Modellismo Riccione Di Angelini Chiara':'Modellismo Riccione','Modellismo Santomartino Marco':'Modellismo Santomartino',
 'Modeltecnica Sas - Modellismo':'Modeltecnica','Modeltoy Melzo':'Modeltoy','Pieri Model':'Pieri Model Racing',
 'Sintex Plastici di Edoardo Marcucci':'Sintex Plastici','Steel Models Srl':'Steel Models','TRENTO TRENO modellismo':'Trento Treno Modellismo',
 'Tiny Cars di Sardini Enrico Maria':'Tiny Cars','Tommasin Modellismo Padova':'Tommasin Modellismo','Trenidea S.A.S di Daniele Buttafava':'Trenidea',
}
# Fuori da questa pubblicazione (motivo nel report)
ESCLUSI={'Biz Model Distribution S.r.l.':'match Maps dubbio: e il distributore, non il negozio EliShop',
         'RcPro - ONLINE STORE':'solo online, nessun punto vendita da mettere in mappa'}

def slugify(s):
    s=unicodedata.normalize('NFKD',s).encode('ascii','ignore').decode()
    return re.sub(r'-+','-',re.sub(r"[^a-zA-Z0-9]+",'-',s).strip('-').lower())

GIORNI=['lun','mar','mer','gio','ven','sab','dom']
def orari(h):
    if not h: return None
    d={}
    for part in h.split(';'):
        part=part.strip()
        m=re.match(r'(lun|mar|mer|gio|ven|sab|dom)\s+(.*)$',part)
        if m: d[m.group(1)]=m.group(2).strip()
    def fmt(v):
        if v=='chiuso': return 'chiuso'
        v=re.sub(r'\b0(\d):',r'\1:',v)
        return v.replace(', ',' e ')
    groups=[]
    for g in GIORNI:
        if g not in d: continue
        if groups and groups[-1][2]==d[g] and GIORNI.index(groups[-1][1])==GIORNI.index(g)-1:
            groups[-1][1]=g
        else: groups.append([g,g,d[g]])
    out=[]
    for a,b,v in groups:
        if a==b=='dom' and v=='chiuso': out.append('domenica chiuso'); continue
        lab=a if a==b else f'{a}-{b}'
        out.append(f'{lab} {fmt(v)}')
    s='; '.join(out)
    return s[:1].upper()+s[1:] if s else None

def tel(t):
    t=t.strip()
    if not t: return None
    return t if t.startswith('+') else '+39 '+t

def q(v):
    return 'null' if v in (None,'') else "'"+str(v).replace("'","''")+"'"

def arr(labels):
    ls=[x.strip() for x in labels.split('|') if x.strip()]
    if not ls: return 'null'
    return 'array['+','.join(q(x[:1].upper()+x[1:]) for x in ls)+']'

rows=[r for r in csv.DictReader(open(SRC,encoding='utf-8-sig'),delimiter=';') if r['stato']=='CENSIBILE' and r['nome'] not in ESCLUSI]
CITTA={'Villanova':'Villanova di Castenaso',"Reggio nell'Emilia":'Reggio Emilia'}
for r in rows:
    r['citta']=CITTA.get(r['citta'],r['citta'])
    r['_nome']=NOME.get(r['nome'],r['nome'])
    r['_slug']=slugify(r['_nome']+'-'+r['citta'])
    via=r['indirizzo'].strip()
    m=re.match(r'^(.*?),?\s*(\d{5})$',via)
    r['_addr']=(f"{m.group(1)}, {m.group(2)} {r['citta']} ({r['provincia']})" if m else f"{via}, {r['citta']} ({r['provincia']})")
# Nord -> Sud, lotti da 10
rows.sort(key=lambda r:-float(r['lat']))
slugs=[r['_slug'] for r in rows]; assert len(slugs)==len(set(slugs)), 'slug duplicati'
lotti=[rows[i:i+10] for i in range(0,len(rows),10)]
files=[]
for i,lot in enumerate(lotti):
    n=7+i
    prov=sorted({r['provincia'] for r in lot})
    fn=os.path.join(OUT,f'2026-09-27-censimento-lotto-{n:02d}.sql')
    L=[f"-- Censimento lotto {n:02d} — {len(lot)} negozi ({', '.join(prov)}).",
       "-- Dati verificati il 2026-09-27: coordinate, indirizzi, telefoni, orari e stato dalla scheda",
       "-- Google Maps del posto; descrizioni e servizi solo dal testo del sito ufficiale (home e chi siamo).",
       "-- Copertine: foto della scheda Maps, guardate in griglia; provvisorie finche il titolare non rivendica.",
       "-- Siti rotti o segnalati non sicuri: link omesso. Idempotente.","",
       "insert into public.shops(slug, name, city, country, address, latitude, longitude,",
       "  website_url, hours, short_description, external_map_url, image_url, phone, service_labels,",
       "  is_public, approval_status, is_community, submitted_by)","values"]
    vals=[]
    for r in lot:
        vals.append(" ("+", ".join([q(r['_slug']),q(r['_nome']),q(r['citta']),"'IT'"])+",\n  "+q(r['_addr'])+f", {float(r['lat'])}, {float(r['lon'])},\n  "
          +", ".join([q(r['website_url']),q(orari(r['hours']))])+",\n  "+q(r['short_description'] or None)+",\n  "
          +q(f"https://www.google.com/maps/search/?api=1&query={r['lat']},{r['lon']}")+",\n  "+q(r['image_url'] or None)+",\n  "
          +q(tel(r['phone']))+", "+arr(r['service_labels'])+", true, 'approved', true, null)")
    L.append(',\n'.join(vals)); L.append("on conflict (slug) do nothing;"); L.append("")
    L.append("-- Verifica")
    L.append("select s.slug, s.name, s.city, (s.latitude is not null) coord, (s.hours is not null) orari,")
    L.append("  (s.short_description is not null) descr, (s.image_url is not null) img, (s.website_url is not null) sito")
    L.append("from public.shops s where s.slug in ("+", ".join(q(r['_slug']) for r in lot)+")")
    L.append("order by s.slug;")
    open(fn,'w',encoding='utf-8',newline='\n').write('\n'.join(L)+'\n')
    files.append((fn,len(lot)))
import json
json.dump({r['nome']:[7+i,r['_slug']] for i,lot in enumerate(lotti) for r in lot},open(os.path.join(ROOT,'docs','censimento','_lotti.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
for f,n in files: print(os.path.basename(f),n)
print('totale',sum(n for _,n in files))
