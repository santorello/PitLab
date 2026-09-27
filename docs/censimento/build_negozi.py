# -*- coding: utf-8 -*-
import csv, re, unicodedata, json, os
BASE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def slugify(s):
    s=unicodedata.normalize('NFKD',s).encode('ascii','ignore').decode()
    s=re.sub(r"[^a-zA-Z0-9]+",'-',s).strip('-').lower()
    return re.sub(r'-+','-',s)

DAYS=[('lun','lun'),('mar','mar'),('mer','mer'),('gio','gio'),('ven','ven'),('sab','sab'),('dom','dom')]
def parse_hours(h):
    if not h: return ''
    part={}
    for chunk in h.split('|'):
        chunk=chunk.strip()
        m=re.match(r'^(dom|lun|mar|mer|gio|ven|sab)(.*)$',chunk)
        if not m: continue
        d,rest=m.group(1),m.group(2)
        if '24h' in rest: part[d]='00:00-24:00'
        elif 'chiuso' in rest.lower(): part[d]='chiuso'
        else:
            rs=re.findall(r'(\d{1,2}(?::\d{2})?)[–-](\d{1,2}(?::\d{2})?)',rest)
            fix=lambda t: t if ':' in t else t+':00'
            part[d]=', '.join(f"{fix(a)}-{fix(b)}" for a,b in rs) or ''
    out=[f"{lbl} {part[d]}" for d,lbl in DAYS if part.get(d)]
    return '; '.join(out)

def split_addr(a):
    # "Via X, 1, 20100 Milano MI" -> (via, cap, citta, prov)
    cap=citta=prov=''
    m=re.search(r'(\d{5})\s+(.+?)\s+([A-Z]{2})$',a)
    if m:
        cap,citta,prov=m.group(1),m.group(2),m.group(3)
        via=a[:m.start()].rstrip(', ')
    else:
        via=a
    return via,cap,citta,prov

# email dal CSV marketing
mail={}
for r in csv.DictReader(open(os.path.join(ROOT,'..','marketing','negozi_modellismo_italia.csv'),encoding='utf-8-sig'),delimiter=';'):
    if r['email'].strip(): mail[slugify(r['nome'])]=r['email'].strip()

NOTE={
 'EliShop':'Maps restituisce Biz Model Distribution allo stesso indirizzo: verificare se e il distributore o il negozio',
 'La Casa del Modellismo Cesate':'omonimia con casadelmodellismo.com (e-commerce): verificare che siano la stessa attivita',
 'DP Modellismo':'stesso indirizzo restituito anche cercando Top Modellismo: verificare le due insegne',
 'Padova Modellismo':'Maps: Tommasin Modellismo Padova allo stesso indirizzo, probabile stessa attivita',
 'Steel Models':'Romeo Models risulta allo stesso indirizzo (stesso gruppo)',
 'Hobby Modellismo e Giocattoli Messina':'censito partendo da ME 262 modellismo, stessa via: insegna cambiata',
 'AMT Modellismo Torino':'censito partendo da Amati Modellismo: indirizzo diverso da OSM',
 'Zerio Modellismo':'censito partendo da Z-Model Vazzola: Maps porta a Treviso, verificare',
 'Jonny Modellismo':'censito partendo da Shop del modellismo Pinerolo',
 'Modellismo e Hobbystica':'Modelworld 10 risulta chiuso e reindirizza qui: verificare',
}
rows=[]
for line in open(os.path.join(BASE,'_maps_raw.psv'),encoding='utf-8'):
    line=line.rstrip('\n')
    if not line.strip(): continue
    f=line.split('|')+['']*10
    key,name,addr,tel,site,cat,closed=f[:7]
    g=line.split('|')
    lat,lon=(g[-2],g[-1]) if len(g)>=10 else ('','')
    hours='|'.join(g[7:-2]) if len(g)>=10 else ''
    via,cap,citta,prov=split_addr(addr)
    if closed=='CHIUSO':
        stato,note='SCARTATA','Google Maps: chiuso definitivamente/temporaneamente (verifica 2026-09-27)'
    elif not addr or not lat:
        stato,note='DA VERIFICARE','manca '+', '.join(x for x,v in [('indirizzo',addr),('coordinate',lat)] if not v)
    else:
        stato,note='CENSIBILE',''
    if key in NOTE: note=(note+'; ' if note else '')+NOTE[key]
    rows.append(dict(
      slug=slugify(name+'-'+citta) if citta else slugify(name),
      nome=name, citta=citta, provincia=prov, indirizzo=(via+(', '+cap if cap else '')).strip(', '),
      lat=lat, lon=lon,
      external_map_url=(f"https://www.google.com/maps/search/?api=1&query={lat},{lon}" if lat else ''),
      website_url=('https://'+site if site and not site.startswith('http') else site),
      phone=tel, email=mail.get(slugify(key),'') or mail.get(slugify(name),''),
      hours=parse_hours(hours), categoria_maps=cat,
      short_description='', image_url='', service_labels='',
      stato=stato, fonte_dati='Google Maps 2026-09-27 + OSM/Scalemates', note=note))

# dedup: gia a DB prod o nel censimento esistente
esistenti={slugify(x) for x in ['ASI Model','Milan Model Modellismo','Milan Model','Modelberg','Modellismo Fioroni',
 "Modellismo Sant'Alessandro",'Modellismo Varesino','Modeltecnic','Team Model di Alberto Poli','Al Parma Model']}
for r in rows:
    if slugify(r['nome']) in esistenti and r['stato']=='CENSIBILE':
        r['stato']='SCARTATA'; r['note']='duplicato: scheda gia presente a DB o nel censimento'

cols=['slug','nome','citta','provincia','indirizzo','lat','lon','external_map_url','website_url','phone','email','hours','categoria_maps','short_description','image_url','service_labels','stato','fonte_dati','note']
out=os.path.join(BASE,'negozi-censimento-2026-09-27.csv')
with open(out,'w',newline='',encoding='utf-8-sig') as fh:
    w=csv.DictWriter(fh,fieldnames=cols,delimiter=';'); w.writeheader()
    for r in sorted(rows,key=lambda x:(x['stato'],x['nome'])): w.writerow(r)

from collections import Counter
print(Counter(r['stato'] for r in rows))
print('totale',len(rows),'| con email',sum(1 for r in rows if r['email']),'| con orari',sum(1 for r in rows if r['hours']))
print(out)
