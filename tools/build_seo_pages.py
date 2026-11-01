#!/usr/bin/env python3
"""Genera le pagine SEO statiche di PitLap (schede + hub) in app/web/.

Perche' esiste: la web app Flutter non espone testo nell'HTML, quindi Google
vede solo index.html. Qui leggiamo da Supabase (chiave anon/publishable, solo
righe che la RLS rende pubbliche) e scriviamo HTML puro, senza JavaScript,
con JSON-LD schema.org, Open Graph, hreflang it/en, sitemap.xml e robots.txt.
Stesso approccio di tools/build_legal_pages.py: Cloudflare Pages serve i file
reali prima della catch-all SPA di app/web/_redirects.

Uso (dalla root del repo):
    python tools/build_seo_pages.py                 # legge app/config/prod.json
    python tools/build_seo_pages.py --config app/config/dev.json --out C:/tmp/seo

Nessuna dipendenza esterna. Va rilanciato prima di ogni build web di
produzione (build_web_prod.bat lo fa da solo).

URL generate (nessuna collide con le route Flutter /track, /shop, /spot, /event):
    IT  /piste/<slug>/  /negozi/<slug>/  /spot-rc/<slug>/  /eventi/<slug-id>/
        /modellismo-rc/<paese>/[<regione>/]<citta>/
    EN  /en/tracks/<slug>/  /en/shops/<slug>/  /en/spots/<slug>/  /en/events/<slug-id>/
        /en/rc/<country>/[<region>/]<city>/
"""
from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import math
import re
import shutil
import sys
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_OUT = ROOT / "app" / "web"
DEFAULT_CONFIG = ROOT / "app" / "config" / "prod.json"
SITE = "https://pitlap.app"
# IndexNow (Bing, Yandex...): chiave pubblica, il file <chiave>.txt viene pubblicato in radice.
INDEXNOW_KEY = "a6551df831b7256855d12000a9e69c95"
DEFAULT_IMAGE = SITE + "/icons/Icon-512.png"
MARKER = ".generated-seo"  # solo le cartelle con questo file vengono ripulite

# Cartelle interamente generate da questo script (ripulite a ogni run).
GEN_DIRS = ["piste", "negozi", "spot-rc", "eventi", "modellismo-rc", "piste-rc", "en"]

EVENT_PAST_DAYS = 180   # eventi passati tenuti online (poi escono dalla sitemap)
NEARBY_KM = 60
NEARBY_MAX = 6
CITY_HUB_MIN = 2        # sotto questa soglia niente pagina citta' (thin content)

# ---------------------------------------------------------------------------
# Dati geografici
# ---------------------------------------------------------------------------

REGIONS = {  # regione IT -> (nome IT, nome EN, sigle province)
    "piemonte": ("Piemonte", "Piedmont", "TO VC NO CN AT AL BI VB"),
    "valle-d-aosta": ("Valle d'Aosta", "Aosta Valley", "AO"),
    "lombardia": ("Lombardia", "Lombardy", "VA CO SO MI BG BS PV CR MN LC LO MB"),
    "trentino-alto-adige": ("Trentino-Alto Adige", "Trentino-South Tyrol", "BZ TN"),
    "veneto": ("Veneto", "Veneto", "VR VI BL TV VE PD RO"),
    "friuli-venezia-giulia": ("Friuli-Venezia Giulia", "Friuli Venezia Giulia", "UD GO TS PN"),
    "liguria": ("Liguria", "Liguria", "IM SV GE SP"),
    "emilia-romagna": ("Emilia-Romagna", "Emilia-Romagna", "PC PR RE MO BO FE RA FC RN"),
    "toscana": ("Toscana", "Tuscany", "MS LU PT FI LI PI AR SI GR PO"),
    "umbria": ("Umbria", "Umbria", "PG TR"),
    "marche": ("Marche", "Marche", "PU AN MC AP FM"),
    "lazio": ("Lazio", "Lazio", "VT RI RM LT FR"),
    "abruzzo": ("Abruzzo", "Abruzzo", "AQ TE PE CH"),
    "molise": ("Molise", "Molise", "CB IS"),
    "campania": ("Campania", "Campania", "CE BN NA AV SA"),
    "puglia": ("Puglia", "Apulia", "FG BA TA BR LE BT"),
    "basilicata": ("Basilicata", "Basilicata", "PZ MT"),
    "calabria": ("Calabria", "Calabria", "CS CZ RC KR VV"),
    "sicilia": ("Sicilia", "Sicily", "TP PA ME AG CL EN CT RG SR"),
    "sardegna": ("Sardegna", "Sardinia", "SS NU CA OR SU OT OG VS CI"),
}
PROV_TO_REGION = {p: k for k, (_, _, ps) in REGIONS.items() for p in ps.split()}
REGION_EN_SLUG = {k: None for k in REGIONS}  # riempito sotto con slugify(nome EN)

COUNTRIES = {  # codice -> (IT, EN)
    "IT": ("Italia", "Italy"), "DE": ("Germania", "Germany"), "FR": ("Francia", "France"),
    "ES": ("Spagna", "Spain"), "GB": ("Regno Unito", "United Kingdom"),
    "US": ("Stati Uniti", "United States"), "CA": ("Canada", "Canada"),
    "AU": ("Australia", "Australia"), "NZ": ("Nuova Zelanda", "New Zealand"),
    "NL": ("Paesi Bassi", "Netherlands"), "BE": ("Belgio", "Belgium"),
    "CH": ("Svizzera", "Switzerland"), "AT": ("Austria", "Austria"),
    "SE": ("Svezia", "Sweden"), "PL": ("Polonia", "Poland"),
    "CZ": ("Repubblica Ceca", "Czech Republic"), "PT": ("Portogallo", "Portugal"),
    "ZA": ("Sudafrica", "South Africa"), "MY": ("Malesia", "Malaysia"),
    "SG": ("Singapore", "Singapore"), "AE": ("Emirati Arabi Uniti", "United Arab Emirates"),
    "IE": ("Irlanda", "Ireland"), "DK": ("Danimarca", "Denmark"), "NO": ("Norvegia", "Norway"),
    "FI": ("Finlandia", "Finland"), "JP": ("Giappone", "Japan"), "SI": ("Slovenia", "Slovenia"),
    "HR": ("Croazia", "Croatia"), "SM": ("San Marino", "San Marino"),
}

SPOT_TAGS = {  # chiave -> (IT, EN)
    "grass": ("erba", "grass"), "dirt": ("terra", "dirt"), "gravel": ("ghiaia", "gravel"),
    "mud": ("fango", "mud"), "water": ("acqua", "water"), "concrete": ("cemento", "concrete"),
    "rock": ("roccia", "rock"), "asphalt": ("asfalto", "asphalt"), "sand": ("sabbia", "sand"),
    "snow": ("neve", "snow"), "bashing": ("bashing", "bashing"), "buggy": ("buggy", "buggy"),
    "scaler": ("scaler", "scaler"), "crawler": ("crawler", "crawler"), "drift": ("drift", "drift"),
    "fpv": ("FPV", "FPV"), "drone": ("droni", "drones"), "short_course": ("short course", "short course"),
    "free": ("libero", "free"), "paid": ("a pagamento", "paid"), "private": ("privato", "private"),
    "all_year": ("tutto l'anno", "all year"), "spring": ("primavera", "spring"),
    "summer": ("estate", "summer"), "autumn": ("autunno", "autumn"), "winter": ("inverno", "winter"),
}

MONTHS_IT = ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio",
             "agosto", "settembre", "ottobre", "novembre", "dicembre"]

# ---------------------------------------------------------------------------
# Testi IT / EN
# ---------------------------------------------------------------------------

T = {
    "it": {
        "locale": "it_IT", "hub_root": "/modellismo-rc/", "hub_title": "Modellismo RC",
        "kind": {"track": "Pista RC", "shop": "Negozio di modellismo", "spot": "Spot RC", "event": "Evento RC"},
        "plural": {"track": "Piste RC", "shop": "Negozi di modellismo", "spot": "Spot RC", "event": "Eventi RC"},
        "path": {"track": "/piste/", "shop": "/negozi/", "spot": "/spot-rc/", "event": "/eventi/"},
        "address": "Indirizzo", "city": "Citta'", "cats": "Categorie", "hours": "Orari",
        "phone": "Telefono", "web": "Sito web", "org": "Gestione", "services": "Servizi",
        "surface": "Superficie", "bestfor": "Adatto a", "access": "Accesso", "season": "Periodo",
        "when": "Quando", "where": "Dove", "video": "Video",
        "open": "Apri in PitLap", "map": "Mappa (OpenStreetMap)", "directions": "Indicazioni stradali",
        "open_track": "Stato della pista in tempo reale, chi sta arrivando oggi ed eventi: tutto nell'app.",
        "open_shop": "Segui il negozio, vedi novita' ed eventi nella community PitLap.",
        "open_spot": "Foto, commenti e build viste qui: tutto nell'app PitLap.",
        "open_event": "Partecipa, vedi chi viene e ricevi aggiornamenti su PitLap.",
        "nearby": "Nei dintorni", "km": "km", "lang_other": "English", "see_all": "Vedi tutti",
        "upcoming": "Prossimi eventi", "past": "Eventi passati", "areas": "Zone",
        "other_countries": "Altri paesi", "by_cat": "Piste per categoria", "foot": "PitLap - dove il modellismo si incontra",
        "privacy": "Privacy", "terms": "Termini", "claim": "Gestisci questo posto? Rivendica la scheda da PitLap per aggiornarla.",
        "online": "Online",
    },
    "en": {
        "locale": "en_GB", "hub_root": "/en/rc/", "hub_title": "RC directory",
        "kind": {"track": "RC track", "shop": "Hobby shop", "spot": "RC spot", "event": "RC event"},
        "plural": {"track": "RC tracks", "shop": "Hobby shops", "spot": "RC spots", "event": "RC events"},
        "path": {"track": "/en/tracks/", "shop": "/en/shops/", "spot": "/en/spots/", "event": "/en/events/"},
        "address": "Address", "city": "City", "cats": "Categories", "hours": "Opening hours",
        "phone": "Phone", "web": "Website", "org": "Run by", "services": "Services",
        "surface": "Surface", "bestfor": "Good for", "access": "Access", "season": "Season",
        "when": "When", "where": "Where", "video": "Video",
        "open": "Open in PitLap", "map": "Map (OpenStreetMap)", "directions": "Directions",
        "open_track": "Live track status, who is coming today and events: all in the app.",
        "open_shop": "Follow the shop and see news and events in the PitLap community.",
        "open_spot": "Photos, comments and builds seen here: all in the PitLap app.",
        "open_event": "Join, see who is coming and get updates on PitLap.",
        "nearby": "Nearby", "km": "km", "lang_other": "Italiano", "see_all": "See all",
        "upcoming": "Upcoming events", "past": "Past events", "areas": "Areas",
        "other_countries": "Other countries", "by_cat": "Tracks by category", "foot": "PitLap - where RC modelling meets",
        "privacy": "Privacy", "terms": "Terms", "claim": "Do you run this place? Claim the listing in PitLap to keep it up to date.",
        "online": "Online",
    },
}
APP_PATH = {"track": "/track/", "shop": "/shop/", "spot": "/spot/", "event": "/event/"}
SCHEMA_TYPE = {"track": "SportsActivityLocation", "shop": "HobbyShop", "spot": "Place"}


def slugify(s: str) -> str:
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-") or "x"


for _k, (_it, _en, _) in REGIONS.items():
    REGION_EN_SLUG[_k] = slugify(_en)


def esc(s) -> str:
    return html.escape(str(s or ""), quote=True)


def clip(s: str, n: int = 158) -> str:
    s = re.sub(r"\s+", " ", s or "").strip()
    if len(s) <= n:
        return s
    return s[: n - 3].rsplit(" ", 1)[0].rstrip(",.;:-") + "..."


def country_name(code: str, lang: str) -> str:
    c = (code or "").upper()
    return COUNTRIES.get(c, (c, c))[0 if lang == "it" else 1]


def country_slug(code: str, lang: str) -> str:
    return slugify(country_name(code, lang))


def region_name(key: str, lang: str) -> str:
    return REGIONS[key][0 if lang == "it" else 1]


def region_slug(key: str, lang: str) -> str:
    return key if lang == "it" else REGION_EN_SLUG[key]


def km(a, b) -> float:
    la1, lo1, la2, lo2 = map(math.radians, (a["lat"], a["lon"], b["lat"], b["lon"]))
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 6371 * 2 * math.asin(math.sqrt(h))


# ---------------------------------------------------------------------------
# Lettura Supabase (PostgREST, solo chiave pubblica)
# ---------------------------------------------------------------------------

class Supa:
    def __init__(self, url: str, key: str):
        self.url, self.key = url.rstrip("/"), key

    def get(self, table: str, select: str, filters=()) -> list[dict]:
        rows, start, step = [], 0, 1000
        while True:
            qs = urllib.parse.urlencode([("select", select), *filters])
            headers = {"apikey": self.key, "Accept": "application/json",
                       "Range-Unit": "items", "Range": f"{start}-{start + step - 1}"}
            if self.key.startswith("eyJ"):  # chiave anon legacy (JWT)
                headers["Authorization"] = "Bearer " + self.key
            req = urllib.request.Request(f"{self.url}/rest/v1/{table}?{qs}", headers=headers)
            with urllib.request.urlopen(req, timeout=60) as r:
                batch = json.load(r)
            rows += batch
            if len(batch) < step:
                return rows
            start += step


def load(cfg_path: Path) -> dict:
    cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
    sb = Supa(cfg["SUPABASE_URL"], cfg.get("SUPABASE_PUBLISHABLE_KEY") or cfg["SUPABASE_ANON_KEY"])
    pub = [("is_public", "eq.true"), ("approval_status", "eq.approved"), ("order", "slug")]
    since = (dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=EVENT_PAST_DAYS)).isoformat()
    return {
        "tracks": sb.get("tracks", "id,slug,name,short_description,description,address,city,country,"
                         "latitude,longitude,image_url,phone,website_url,hours,organization_name,updated_at,"
                         "track_category_links(track_categories(key,label_it,label_en,sort_order))", pub),
        "shops": sb.get("shops", "id,slug,name,subtitle,short_description,description,address,city,country,"
                        "latitude,longitude,image_url,phone,website_url,hours,service_labels,updated_at", pub),
        # is_custom = spot creati dagli utenti: restano solo nell'app (possono essere luoghi privati).
        "spots": sb.get("spots", "slug,title,city,category,note,address,latitude,longitude,image_urls,"
                        "video_url,best_for_tags,surface_tags,access_type,best_season,updated_at",
                        [("is_custom", "eq.false"), ("order", "slug")]),
        "events": sb.get("events", "id,title,description,start_at,end_at,updated_at,"
                         "tracks(slug,name,city,address,country,latitude,longitude)",
                         [("visibility", "eq.public"), ("start_at", "gte." + since)]),
        "cevents": sb.get("community_events", "id,title,location,venue,note,image_urls,starts_at,ends_at,"
                          "latitude,longitude,updated_at", [("starts_at", "gte." + since)]),
    }


# ---------------------------------------------------------------------------
# Modello
# ---------------------------------------------------------------------------

def province_of(address: str):
    m = re.findall(r"\(([A-Z]{2})\)", address or "")
    return m[-1] if m else None


def build_entities(raw: dict) -> tuple[list[dict], list[dict]]:
    places: list[dict] = []
    for r in raw["tracks"]:
        cats = sorted((l["track_categories"] for l in r.get("track_category_links") or [] if l.get("track_categories")),
                      key=lambda c: c.get("sort_order") or 0)
        places.append(dict(kind="track", slug=r["slug"], name=r["name"], sd=r.get("short_description"),
                           desc=r.get("description"), address=r.get("address"), city=r.get("city"),
                           country=(r.get("country") or "IT").upper(), lat=r.get("latitude"), lon=r.get("longitude"),
                           image=r.get("image_url"), phone=r.get("phone"), web=r.get("website_url"),
                           hours=r.get("hours"), org=r.get("organization_name"), updated=r.get("updated_at"),
                           cats_it=[c["label_it"] for c in cats], cats_en=[c["label_en"] for c in cats],
                           cats=[(c["key"], c["label_it"], c["label_en"]) for c in cats]))
    for r in raw["shops"]:
        places.append(dict(kind="shop", slug=r["slug"], name=r["name"], sd=r.get("short_description") or r.get("subtitle"),
                           desc=r.get("description"), address=r.get("address"), city=r.get("city"),
                           country=(r.get("country") or "IT").upper(), lat=r.get("latitude"), lon=r.get("longitude"),
                           image=r.get("image_url"), phone=r.get("phone"), web=r.get("website_url"),
                           hours=r.get("hours"), services=[s for s in r.get("service_labels") or [] if s],
                           updated=r.get("updated_at")))
    for r in raw["spots"]:
        imgs = [u for u in r.get("image_urls") or [] if u]
        places.append(dict(kind="spot", slug=r["slug"], name=r["title"], sd=None, desc=r.get("note"),
                           address=r.get("address"), city=r.get("city"), country="IT",  # la tabella spots non ha paese
                           lat=r.get("latitude"), lon=r.get("longitude"), image=imgs[0] if imgs else None,
                           category=r.get("category"), video=r.get("video_url"),
                           bestfor=r.get("best_for_tags") or [], surface=r.get("surface_tags") or [],
                           access=r.get("access_type"), season=r.get("best_season"), updated=r.get("updated_at")))
    places = [p for p in places if p["slug"]]

    # Regione (solo Italia): sigla provincia nell'indirizzo, poi stessa citta', poi luogo piu' vicino.
    for p in places:
        p["region"] = PROV_TO_REGION.get(province_of(p["address"])) if p["country"] == "IT" else None
        p["prov"] = province_of(p["address"])
    city_region = {(p["city"] or "").casefold(): p["region"] for p in places if p["region"]}
    for p in places:
        if p["country"] == "IT" and not p["region"]:
            p["region"] = city_region.get((p["city"] or "").casefold())
            if not p["region"] and p["lat"] is not None:
                near = [(km(p, q), q) for q in places if q["region"] and q["lat"] is not None]
                if near:
                    d, q = min(near, key=lambda x: x[0])
                    if d < 50:
                        p["region"] = q["region"]

    events: list[dict] = []
    for r in raw["events"]:
        t = r.get("tracks") or {}
        events.append(dict(kind="event", id=r["id"], name=r["title"], desc=r.get("description"),
                           start=r.get("start_at"), end=r.get("end_at"), updated=r.get("updated_at"),
                           venue=t.get("name"), address=t.get("address"), city=t.get("city"),
                           country=(t.get("country") or "IT").upper(), lat=t.get("latitude"), lon=t.get("longitude"),
                           image=None, track_slug=t.get("slug")))
    for r in raw["cevents"]:
        imgs = [u for u in r.get("image_urls") or [] if u]
        events.append(dict(kind="event", id=r["id"], name=r["title"], desc=r.get("note"),
                           start=r.get("starts_at"), end=r.get("ends_at"), updated=r.get("updated_at"),
                           venue=r.get("venue"), address=None, city=r.get("location"), country=None,
                           lat=r.get("latitude"), lon=r.get("longitude"), image=imgs[0] if imgs else None,
                           track_slug=None))
    for e in events:
        e["slug"] = f"{slugify(e['name'])[:60].strip('-')}-{e['id'][:8]}"
        e["online"] = bool(re.search(r"youtube|youtu\.be|twitch|online|streaming", " ".join(
            str(x or "") for x in (e["city"], e["venue"], e["desc"])), re.I)) and e["lat"] is None
        # Collega l'evento alla zona del luogo piu' vicino (per gli hub).
        e["region"] = e["group_of"] = None
        if e["lat"] is not None:
            near = [(km(e, q), q) for q in places if q["lat"] is not None]
            if near:
                d, q = min(near, key=lambda x: x[0])
                if d < 25:
                    e["group_of"] = q
                    e["country"] = e["country"] or q["country"]
    return places, events


# ---------------------------------------------------------------------------
# Hub: paese -> (regione) -> citta'
# ---------------------------------------------------------------------------

def hub_paths(country: str, region, city, lang: str) -> list[tuple[str, str]]:
    """Catena di breadcrumb (nome, path) dall'hub radice fino alla citta'."""
    t = T[lang]
    out = [(t["hub_title"], t["hub_root"])]
    base = t["hub_root"] + country_slug(country, lang) + "/"
    out.append((country_name(country, lang), base))
    if region:
        base += region_slug(region, lang) + "/"
        out.append((region_name(region, lang), base))
    if city:
        out.append((city, base + slugify(city) + "/"))
    return out


def group_hubs(places, events):
    """Ritorna dict key->hub con key = (country, region|None, city|None)."""
    hubs: dict = {}

    def add(key, item):
        h = hubs.setdefault(key, {"key": key, "items": [], "children": set()})
        if item is not None:
            h["items"].append(item)

    for p in places:
        c, r, city = p["country"], p["region"], (p["city"] or "").strip() or None
        p["city_key"] = (c, r, city) if city else None
        add((None, None, None), p)
        add((c, None, None), p)
        if r:
            add((c, r, None), p)
        if city:
            add((c, r, city), p)
    for e in events:
        q = e["group_of"]
        if not q:
            continue
        add((None, None, None), e)
        add((q["country"], None, None), e)
        if q["region"]:
            add((q["country"], q["region"], None), e)
        if q["city_key"]:
            add(q["city_key"], e)
    # Scarta le citta' troppo povere (restano elencate nell'hub padre).
    # ...e le citta'-stato (Singapore) che duplicherebbero l'hub del paese.
    for key in [k for k, h in hubs.items() if k[2] and (
            sum(1 for i in h["items"] if i["kind"] != "event") < CITY_HUB_MIN
            or slugify(k[2]) in (country_slug(k[0], "it"), country_slug(k[0], "en")))]:
        del hubs[key]
    for (c, r, city) in list(hubs):
        if city:
            hubs[(c, r, None)]["children"].add((c, r, city)) if (c, r, None) in hubs else None
        elif r:
            hubs[(c, None, None)]["children"].add((c, r, None))
        elif c:
            hubs[(None, None, None)]["children"].add((c, None, None))
    # In paesi senza regioni le citta' sono figlie dirette del paese.
    for (c, r, city) in list(hubs):
        if city and not r:
            hubs[(c, None, None)]["children"].add((c, None, city))
    return hubs


def hub_url(key, lang) -> str:
    c, r, city = key
    if not c:
        return T[lang]["hub_root"]
    return hub_paths(c, r, city, lang)[-1][1]


def hub_label(key, lang) -> str:
    c, r, city = key
    if city:
        return city
    if r:
        return region_name(r, lang)
    if c:
        return country_name(c, lang)
    return T[lang]["hub_title"]


def breadcrumbs_for(item, lang, hubs) -> list[tuple[str, str]]:
    src = item.get("group_of") if item["kind"] == "event" else item
    if not src:
        t = T[lang]
        return [(t["hub_title"], t["hub_root"]), (t["plural"]["event"], t["path"]["event"])]
    city = src["city"] if src.get("city_key") in hubs else None
    return hub_paths(src["country"], src["region"], city, lang)


# ---------------------------------------------------------------------------
# HTML
# ---------------------------------------------------------------------------

CSS = """
:root{color-scheme:light dark;--fg:#15181c;--bg:#f6f4ef;--card:#fff;--muted:#5b6472;--rule:#dcd8cf;--accent:#c8102e;--chip:#efece5}
@media (prefers-color-scheme:dark){:root{--fg:#e7eaee;--bg:#14171b;--card:#1c2025;--muted:#9aa4b2;--rule:#2c323a;--accent:#ff5c72;--chip:#252a31}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;-webkit-text-size-adjust:100%}
.wrap{max-width:52rem;margin:0 auto;padding:1.25rem 1rem 3rem}
header.site{display:flex;justify-content:space-between;align-items:center;gap:1rem;border-bottom:1px solid var(--rule);padding-bottom:.75rem;margin-bottom:1rem;flex-wrap:wrap}
header.site .brand{color:var(--fg);text-decoration:none;font-weight:800;font-size:1.2rem}
header.site .brand span{color:var(--accent)}
header.site nav a{margin-left:1rem;font-size:.95rem}
a{color:var(--accent)}
nav.crumbs{font-size:.85rem;color:var(--muted);margin-bottom:.5rem}
nav.crumbs a{color:var(--muted)}
.kicker{color:var(--muted);font-size:.95rem;margin:0}
h1{font-size:1.8rem;line-height:1.2;margin:.2rem 0 1rem}
h2{font-size:1.2rem;margin:2rem 0 .75rem}
.hero{width:100%;max-height:22rem;object-fit:cover;border-radius:12px;margin:0 0 1rem;background:var(--chip)}
.lead{font-size:1.08rem}
dl.facts{display:grid;grid-template-columns:max-content 1fr;gap:.35rem 1rem;background:var(--card);border:1px solid var(--rule);border-radius:12px;padding:1rem;margin:1rem 0}
dl.facts dt{color:var(--muted)}
dl.facts dd{margin:0;overflow-wrap:anywhere}
@media (max-width:30rem){dl.facts{grid-template-columns:1fr}dl.facts dd{margin-bottom:.5rem}}
.chips span{display:inline-block;background:var(--chip);border-radius:999px;padding:.1rem .6rem;margin:0 .3rem .3rem 0;font-size:.88rem}
.cta{background:var(--card);border:1px solid var(--rule);border-radius:12px;padding:1rem;margin:1.25rem 0}
.cta p{margin:.25rem 0 .75rem;color:var(--muted)}
.btn{display:inline-block;background:var(--accent);color:#fff;text-decoration:none;font-weight:700;padding:.6rem 1.1rem;border-radius:999px}
.links a{margin-right:1rem}
ul.cards{list-style:none;padding:0;display:grid;grid-template-columns:repeat(auto-fill,minmax(15rem,1fr));gap:.75rem}
ul.cards li{background:var(--card);border:1px solid var(--rule);border-radius:12px;padding:.75rem .9rem}
ul.cards a{font-weight:700;text-decoration:none}
ul.cards small{display:block;color:var(--muted)}
ul.areas{list-style:none;padding:0;columns:2 12rem}
ul.areas li{margin-bottom:.3rem}
footer{border-top:1px solid var(--rule);margin-top:3rem;padding-top:1rem;font-size:.85rem;color:var(--muted)}
footer a{color:var(--muted);margin-right:.75rem}
"""


def jsonld(obj) -> str:
    s = json.dumps(obj, ensure_ascii=False, separators=(",", ":"))
    return '<script type="application/ld+json">' + s.replace("</", "<\\/") + "</script>"


def page(lang, title, desc, path, alt_path, image, body, ld, crumbs, noindex=False) -> str:
    t, other = T[lang], ("en" if lang == "it" else "it")
    it_path, en_path = (path, alt_path) if lang == "it" else (alt_path, path)
    crumbs_ld = {"@context": "https://schema.org", "@type": "BreadcrumbList", "itemListElement": [
        {"@type": "ListItem", "position": i + 1, "name": n, "item": SITE + p} for i, (n, p) in enumerate(crumbs)]}
    crumbs_html = " &rsaquo; ".join(f'<a href="{esc(p)}">{esc(n)}</a>' for n, p in crumbs[:-1])
    if crumbs:
        crumbs_html += (" &rsaquo; " if len(crumbs) > 1 else "") + esc(crumbs[-1][0])
    img = image or DEFAULT_IMAGE
    head = [
        '<!DOCTYPE html>', f'<html lang="{lang}">', '<head>', '<meta charset="utf-8">',
        '<meta name="viewport" content="width=device-width, initial-scale=1">',
        f'<title>{esc(title)}</title>', f'<meta name="description" content="{esc(desc)}">',
        f'<link rel="canonical" href="{SITE}{esc(path)}">',
        f'<link rel="alternate" hreflang="it" href="{SITE}{esc(it_path)}">',
        f'<link rel="alternate" hreflang="en" href="{SITE}{esc(en_path)}">',
        f'<link rel="alternate" hreflang="x-default" href="{SITE}{esc(it_path)}">',
        '<meta name="robots" content="noindex,follow">' if noindex else '',
        '<meta name="theme-color" content="#f6f4ef">', '<link rel="icon" type="image/png" href="/favicon.png">',
        '<meta property="og:site_name" content="PitLap">', '<meta property="og:type" content="website">',
        f'<meta property="og:title" content="{esc(title)}">', f'<meta property="og:description" content="{esc(desc)}">',
        f'<meta property="og:url" content="{SITE}{esc(path)}">', f'<meta property="og:image" content="{esc(img)}">',
        f'<meta property="og:locale" content="{t["locale"]}">',
        f'<meta property="og:locale:alternate" content="{T[other]["locale"]}">',
        f'<meta name="twitter:card" content="{"summary_large_image" if image else "summary"}">',
        f'<meta name="twitter:title" content="{esc(title)}">', f'<meta name="twitter:description" content="{esc(desc)}">',
        f'<meta name="twitter:image" content="{esc(img)}">',
        f'<style>{CSS}</style>', *(jsonld(x) for x in ld), jsonld(crumbs_ld), '</head>', '<body><div class="wrap">',
        '<header class="site"><a class="brand" href="/">Pit<span>Lap</span></a><nav>'
        f'<a href="{t["hub_root"]}">{esc(t["hub_title"])}</a>'
        f'<a href="{esc(alt_path)}" hreflang="{other}" lang="{other}">{t["lang_other"]}</a></nav></header>',
        f'<nav class="crumbs" aria-label="breadcrumb">{crumbs_html}</nav>' if crumbs else '',
        '<main>', body, '</main>',
        f'<footer><p>{esc(t["foot"])}</p><p><a href="/">pitlap.app</a>'
        '<a href="/legal/privacy-policy">' + t["privacy"] + '</a><a href="/legal/termini-di-servizio">' + t["terms"] +
        '</a><a href="/legal/cookie-policy">Cookie</a></p></footer>', '</div></body></html>',
    ]
    return "\n".join(x for x in head if x) + "\n"


def para(text) -> str:
    text = (text or "").strip()
    if not text:
        return ""
    parts = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    return "".join(f"<p>{esc(p).replace(chr(10), '<br>')}</p>" for p in parts)


def fmt_date(iso, lang) -> str:
    if not iso:
        return ""
    d = dt.datetime.fromisoformat(iso.replace("Z", "+00:00"))
    try:
        from zoneinfo import ZoneInfo
        d, tz = d.astimezone(ZoneInfo("Europe/Rome")), ""
    except Exception:  # Windows senza pacchetto tzdata
        d, tz = d.astimezone(dt.timezone.utc), " UTC"
    if lang == "it":
        return f"{d.day} {MONTHS_IT[d.month - 1]} {d.year}, {d:%H:%M}{tz}"
    return f"{d:%d %B %Y, %H:%M}{tz}".lstrip("0")


def place_path(p, lang) -> str:
    return T[lang]["path"][p["kind"]] + p["slug"] + "/"


def item_label(p, lang) -> str:
    loc = p.get("city") or ""
    if p["kind"] != "event" and p.get("prov") and p["country"] == "IT":
        loc += f" ({p['prov']})"
    elif p["kind"] != "event" and p["country"] != "IT" and p.get("country"):
        loc += (", " if loc else "") + country_name(p["country"], lang)
    return loc


def meta_desc(p, lang) -> str:
    t, city = T[lang], item_label(p, lang)
    k = p["kind"]
    if k == "event":
        when = fmt_date(p["start"], lang)
        where = t["online"] if p["online"] else (p["venue"] or p["city"] or "")
        base = f"{p['name']} - {when}" + (f", {where}" if where else "") + ". "
        tail = "Dettagli e partecipanti su PitLap." if lang == "it" else "Details and attendees on PitLap."
        return clip(base + tail)
    lead = (p.get("sd") or p.get("desc") or "").strip()
    if lang == "it":
        tail = {"track": "Indirizzo, orari, categorie e stato della pista in tempo reale su PitLap.",
                "shop": "Indirizzo, orari, contatti e servizi su PitLap.",
                "spot": "Superficie, accesso e consigli della community su PitLap."}[k]
        head = f"{p['name']}: {t['kind'][k].lower()} a {city}. "
    else:
        tail = {"track": "Address, opening hours, categories and live track status on PitLap.",
                "shop": "Address, opening hours, contacts and services on PitLap.",
                "spot": "Surface, access and community tips on PitLap."}[k]
        head = f"{p['name']}: {t['kind'][k]} in {city}. "
    return clip(head + (clip(lead, 80) + " " if lead else "") + tail)


def schema_for(p, lang, path) -> dict:
    if p["kind"] == "event":
        d = {"@context": "https://schema.org", "@type": "Event", "name": p["name"], "url": SITE + path,
             "startDate": p["start"], "eventStatus": "https://schema.org/EventScheduled",
             "image": [p["image"] or DEFAULT_IMAGE]}
        if p["end"]:
            d["endDate"] = p["end"]
        if p["desc"]:
            d["description"] = clip(p["desc"], 300)
        if p["online"]:
            d["eventAttendanceMode"] = "https://schema.org/OnlineEventAttendanceMode"
            link = re.search(r"https?://\S+", p["desc"] or "")
            d["location"] = {"@type": "VirtualLocation", "url": link.group(0) if link else SITE + path}
        else:
            d["eventAttendanceMode"] = "https://schema.org/OfflineEventAttendanceMode"
            loc = {"@type": "Place", "name": p["venue"] or p["city"] or "PitLap",
                   "address": {"@type": "PostalAddress", "streetAddress": p["address"] or p["city"] or "",
                               "addressLocality": p["city"] or ""}}
            if p["country"]:
                loc["address"]["addressCountry"] = p["country"]
            if p["lat"] is not None:
                loc["geo"] = {"@type": "GeoCoordinates", "latitude": p["lat"], "longitude": p["lon"]}
            d["location"] = loc
        d["organizer"] = {"@type": "Organization", "name": "PitLap", "url": SITE}
        return d
    d = {"@context": "https://schema.org", "@type": SCHEMA_TYPE[p["kind"]], "name": p["name"],
         "url": SITE + path, "description": meta_desc(p, lang),
         "address": {"@type": "PostalAddress", "streetAddress": p["address"] or "",
                     "addressLocality": p["city"] or "", "addressCountry": p["country"]}}
    if p.get("prov"):
        d["address"]["addressRegion"] = p["prov"]
    if p["lat"] is not None:
        d["geo"] = {"@type": "GeoCoordinates", "latitude": p["lat"], "longitude": p["lon"]}
        d["hasMap"] = f"https://www.openstreetmap.org/?mlat={p['lat']}&mlon={p['lon']}#map=16/{p['lat']}/{p['lon']}"
    if p.get("image"):
        d["image"] = p["image"]
    if p.get("phone") and p["kind"] != "spot":
        d["telephone"] = p["phone"]
    if p.get("web"):
        d["sameAs"] = [p["web"]]
    if p["kind"] == "spot":
        d["publicAccess"] = p.get("access") in (None, "", "free")
    return d


def tags(keys, lang) -> list[str]:
    return [SPOT_TAGS.get(k, (k, k))[0 if lang == "it" else 1] for k in keys if k]


def render_item(p, lang, others, hubs) -> tuple[str, str, str, str, list, list]:
    t, k = T[lang], p["kind"]
    other = "en" if lang == "it" else "it"
    path, alt = place_path(p, lang), place_path(p, other)
    label = item_label(p, lang)
    where = (f" a {p['city']}" if lang == "it" else f" in {p['city']}") if p.get("city") and k != "event" else ""
    title = next(x for x in (f"{p['name']} - {t['kind'][k]}{where} | PitLap", f"{p['name']} - {t['kind'][k]} | PitLap",
                             f"{p['name']} | PitLap") if len(x) <= 65 or x.startswith(p["name"] + " |"))
    desc = meta_desc(p, lang)
    b = [f'<p class="kicker">{esc(t["kind"][k])}' + (f" &middot; {esc(label)}" if label else "") + "</p>",
         f"<h1>{esc(p['name'])}</h1>"]
    if p.get("image") and str(p["image"]).startswith("https://"):
        b.append(f'<img class="hero" src="{esc(p["image"])}" alt="{esc(p["name"])}" loading="lazy">')
    if p.get("sd"):
        b.append(f'<p class="lead">{esc(p["sd"])}</p>')
    b.append(para(p.get("desc")))

    facts: list[tuple[str, str]] = []
    if k == "event":
        when = fmt_date(p["start"], lang) + (f" &ndash; {esc(fmt_date(p['end'], lang))}" if p["end"] else "")
        facts.append((t["when"], when))
        if p["online"]:
            facts.append((t["where"], esc(t["online"])))
        elif p.get("track_slug"):
            facts.append((t["where"], f'<a href="{t["path"]["track"]}{esc(p["track_slug"])}/">{esc(p["venue"])}</a>'
                          + (f", {esc(p['city'])}" if p.get("city") else "")))
        elif p.get("venue") or p.get("city"):
            facts.append((t["where"], esc(", ".join(x for x in (p.get("venue"), p.get("city")) if x))))
    if p.get("address"):
        facts.append((t["address"], esc(p["address"])))
    if k == "track" and p.get(f"cats_{lang}"):
        chips = []
        for c in p["cats"]:
            label = esc(c[1] if lang == "it" else c[2])
            key = next((k for k in ((c, p["country"], p["region"]), (c, p["country"], None), (c, None, None))
                        if k in CAT_GROUPS), None)
            chips.append(f'<a href="{esc(cat_path(key, lang))}">{label}</a>' if key else label)
        facts.append((t["cats"], '<span class="chips">' + "".join(f"<span>{c}</span>" for c in chips) + "</span>"))
    if k == "spot":
        if p.get("category"):
            facts.append((t["cats"], esc(p["category"])))
        if p["bestfor"]:
            facts.append((t["bestfor"], esc(", ".join(tags(p["bestfor"], lang)))))
        if p["surface"]:
            facts.append((t["surface"], esc(", ".join(tags(p["surface"], lang)))))
        if p.get("access"):
            facts.append((t["access"], esc(", ".join(tags([p["access"]], lang)))))
        if p.get("season"):
            facts.append((t["season"], esc(", ".join(tags([p["season"]], lang)))))
    if p.get("services"):
        facts.append((t["services"], esc(", ".join(p["services"]))))
    if p.get("hours"):
        facts.append((t["hours"], f'<span lang="it">{esc(p["hours"])}</span>' if lang == "en" else esc(p["hours"])))
    if p.get("org"):
        facts.append((t["org"], esc(p["org"])))
    if p.get("phone") and k != "spot":
        tel = re.sub(r"[^\d+]", "", p["phone"])
        facts.append((t["phone"], f'<a href="tel:{esc(tel)}">{esc(p["phone"])}</a>'))
    if p.get("web") and str(p["web"]).startswith("http"):
        host = urllib.parse.urlparse(p["web"]).netloc.removeprefix("www.")
        facts.append((t["web"], f'<a href="{esc(p["web"])}" rel="noopener" target="_blank">{esc(host)}</a>'))
    if p.get("video") and str(p["video"]).startswith("http"):
        facts.append((t["video"], f'<a href="{esc(p["video"])}" rel="noopener" target="_blank">{esc(p["video"])}</a>'))
    if facts:
        b.append('<dl class="facts">' + "".join(f"<dt>{esc(a)}</dt><dd>{v}</dd>" for a, v in facts) + "</dl>")

    if p.get("lat") is not None:
        lat, lon = p["lat"], p["lon"]
        b.append('<p class="links">'
                 f'<a href="https://www.openstreetmap.org/?mlat={lat}&amp;mlon={lon}#map=16/{lat}/{lon}" rel="noopener" target="_blank">{t["map"]}</a>'
                 f'<a href="https://www.google.com/maps/dir/?api=1&amp;destination={lat},{lon}" rel="noopener" target="_blank">{t["directions"]}</a></p>')

    app_id = p["id"] if k == "event" else p["slug"]
    b.append(f'<div class="cta"><p>{esc(t["open_" + k])}</p>'
             f'<a class="btn" href="{APP_PATH[k]}{esc(app_id)}">{esc(t["open"])}</a></div>')
    if k in ("track", "shop"):
        b.append(f'<p class="kicker">{esc(t["claim"])}</p>')

    if p.get("lat") is not None and k != "event":
        near = sorted(((km(p, q), q) for q in others if q is not p and q.get("lat") is not None), key=lambda x: x[0])
        near = [(d, q) for d, q in near if d <= NEARBY_KM][:NEARBY_MAX]
        if near:
            b.append(f"<h2>{esc(t['nearby'])}</h2><ul class=\"cards\">" + "".join(
                f'<li><a href="{esc(place_path(q, lang))}">{esc(q["name"])}</a>'
                f'<small>{esc(t["kind"][q["kind"]])} &middot; {esc(q.get("city") or "")} &middot; {d:.0f} {t["km"]}</small></li>'
                for d, q in near) + "</ul>")

    crumbs = breadcrumbs_for(p, lang, hubs)
    if crumbs:
        hub_name, hub_p = crumbs[-1]
        b.append(f'<p><a href="{esc(hub_p)}">{esc(t["see_all"])}: {esc(hub_name)} &rarr;</a></p>')
    crumbs = crumbs + [(p["name"], path)]
    return path, alt, title, desc, [schema_for(p, lang, path)], crumbs, "\n".join(x for x in b if x)


def cards(items, lang) -> str:
    return '<ul class="cards">' + "".join(
        f'<li><a href="{esc(place_path(i, lang))}">{esc(i["name"])}</a>'
        f'<small>{esc(fmt_date(i["start"], lang) if i["kind"] == "event" else item_label(i, lang))}</small>'
        + (f'<small>{esc(clip(i.get("sd") or "", 90))}</small>' if i.get("sd") else "") + "</li>"
        for i in items) + "</ul>"


def sort_items(items):
    return sorted(items, key=lambda i: (i.get("city") or "", i["name"].casefold()))


def split_events(evs):
    now = dt.datetime.now(dt.timezone.utc).isoformat()
    up = sorted([e for e in evs if (e["end"] or e["start"] or "") >= now], key=lambda e: e["start"] or "")
    past = sorted([e for e in evs if e not in up], key=lambda e: e["start"] or "", reverse=True)
    return up, past


def item_list_ld(items, lang, path, name) -> dict:
    return {"@context": "https://schema.org", "@type": "CollectionPage", "name": name, "url": SITE + path,
            "mainEntity": {"@type": "ItemList", "numberOfItems": len(items), "itemListElement": [
                {"@type": "ListItem", "position": n + 1, "url": SITE + place_path(i, lang), "name": i["name"]}
                for n, i in enumerate(items[:200])]}}


def render_hub(key, hub, lang, hubs):
    t = T[lang]
    other = "en" if lang == "it" else "it"
    path, alt = hub_url(key, lang), hub_url(key, other)
    where = hub_label(key, lang)
    if key[2] and key[0] != "IT" and slugify(key[2]) != country_slug(key[0], lang):
        where = f"{where}, {country_name(key[0], lang)}"
    items = hub["items"]
    by = {k: sort_items([i for i in items if i["kind"] == k]) for k in ("track", "shop", "spot")}
    up, past = split_events([i for i in items if i["kind"] == "event"])
    n = {k: len(v) for k, v in by.items()}
    root = key == (None, None, None)
    if lang == "it":
        title = ("Piste RC, negozi di modellismo e spot | PitLap" if root
                 else f"Piste RC e negozi di modellismo a {where} | PitLap" if key[2]
                 else f"Piste RC e negozi di modellismo in {where} | PitLap")
        prep = "" if root else (f"A {where} " if key[2] else f"In {where} ")
        intro = (f"{prep}PitLap elenca {n['track']} piste RC, {n['shop']} negozi di modellismo e {n['spot']} spot"
                 " per auto radiocomandate. Apri una scheda per indirizzo, orari e stato della pista in tempo reale.")
    else:
        title = ("RC tracks, hobby shops and spots | PitLap" if root
                 else f"RC tracks and hobby shops in {where} | PitLap")
        prep = "" if root else f"In {where} "
        intro = (f"{prep}PitLap lists {n['track']} RC tracks, {n['shop']} hobby shops and {n['spot']} spots"
                 " for radio-controlled cars. Open a listing for address, opening hours and live track status.")
    h1 = (t["hub_title"] if root else
          (f"Modellismo RC a {where}" if key[2] else f"Modellismo RC in {where}") if lang == "it"
          else f"RC in {where}")
    b = [f"<h1>{esc(h1)}</h1>", f'<p class="lead">{esc(intro[0].upper() + intro[1:])}</p>']
    kids = sorted(hub["children"], key=lambda k: hub_label(k, lang).casefold())
    if kids:
        b.append(f"<h2>{esc(t['areas'])}</h2><ul class=\"areas\">" + "".join(
            f'<li><a href="{esc(hub_url(c, lang))}">{esc(hub_label(c, lang))}</a> '
            f'<small>({sum(1 for i in hubs[c]["items"] if i["kind"] != "event")})</small></li>' for c in kids) + "</ul>")
    if key[2] is None:
        cat_keys = sorted((k for k in CAT_GROUPS if k[1:] == key[:2]), key=lambda k: -len(CAT_GROUPS[k]))
        if cat_keys:
            b.append(f"<h2>{esc(t['by_cat'])}</h2><ul class=\"areas\">" + "".join(
                f'<li><a href="{esc(cat_path(k, lang))}">{esc(cat_title(k, lang))}</a> '
                f'<small>({len(CAT_GROUPS[k])})</small></li>' for k in cat_keys) + "</ul>")
    # Nell'hub radice e nei paesi grandi non ripetiamo l'elenco completo: bastano le zone.
    show_all = key[2] is not None or key[1] is not None or len([i for i in items if i["kind"] != "event"]) <= 40
    if show_all:
        for k in ("track", "shop", "spot"):
            if by[k]:
                b.append(f"<h2>{esc(t['plural'][k])} ({len(by[k])})</h2>" + cards(by[k], lang))
    if up:
        b.append(f"<h2>{esc(t['upcoming'])}</h2>" + cards(up, lang))
    if past and show_all:
        b.append(f"<h2>{esc(t['past'])}</h2>" + cards(past[:10], lang))
    if root:
        b.append("<h2>" + esc(t["see_all"]) + "</h2><p class=\"links\">" + "".join(
            f'<a href="{t["path"][k]}">{esc(t["plural"][k])}</a>' for k in ("track", "shop", "spot", "event")) + "</p>")
    crumbs = hub_paths(key[0], key[1], key[2], lang) if not root else [(t["hub_title"], path)]
    listed = [i for i in items if i["kind"] != "event"] if show_all else []
    ld = [item_list_ld(sort_items(listed) + up, lang, path, h1)]
    desc = clip(intro)
    return path, alt, title, desc, ld, crumbs, "\n".join(b)


CAT_ROOT = {"it": "/piste-rc/", "en": "/en/rc-tracks/"}
CAT_GROUPS: dict = {}  # (cat, paese|None, regione|None) -> piste; riempito in main()


def cat_groups(places) -> dict:
    """Piste per categoria x zona (tutto il mondo, paese, regione IT). Solo gruppi con >= CITY_HUB_MIN piste."""
    g: dict = {}
    for p in places:
        if p["kind"] != "track":
            continue
        for c in p["cats"]:
            keys = [(c, None, None), (c, p["country"], None)] + ([(c, p["country"], p["region"])] if p["region"] else [])
            for k in keys:
                g.setdefault(k, []).append(p)
    g = {k: v for k, v in g.items() if len(v) >= CITY_HUB_MIN}
    # Niente pagine gemelle: una zona con le stesse piste della zona sopra sparisce (resta quella sopra).
    for k in sorted(g, key=lambda k: (k[1] is not None, k[2] is not None)):  # mondo, poi paesi, poi regioni
        if k[1] and len(g[k]) == len(g[cat_parent(k, g)]):
            del g[k]
    return g


def cat_parent(key, groups):
    """Zona esistente immediatamente sopra (regione -> paese -> mondo)."""
    c, country, region = key
    if region and (c, country, None) in groups:
        return (c, country, None)
    return (c, None, None)


def cat_path(key, lang) -> str:
    c, country, region = key
    path = CAT_ROOT[lang] + slugify(c[1] if lang == "it" else c[2]) + "/"
    if country:
        path += country_slug(country, lang) + "/"
    if region:
        path += region_slug(region, lang) + "/"
    return path


def cat_title(key, lang) -> str:
    c, country, region = key
    where = region_name(region, lang) if region else country_name(country, lang) if country else ""
    if lang == "it":
        return f"Piste {c[1]}" + (f" in {where}" if where else "")
    return f"{c[2]} RC tracks" + (f" in {where}" if where else "")


def render_cat(key, items, lang):
    t = T[lang]
    other = "en" if lang == "it" else "it"
    c, country, region = key
    path, alt, h1 = cat_path(key, lang), cat_path(key, other), cat_title(key, lang)
    label = c[1] if lang == "it" else c[2]
    where = region_name(region, lang) if region else country_name(country, lang) if country else ""
    if lang == "it":
        intro = (f"{len(items)} piste RC per {label}" + (f" in {where}" if where else " nel mondo") +
                 " su PitLap: indirizzi, orari, contatti e stato della pista in tempo reale.")
    else:
        intro = (f"{len(items)} RC tracks for {label}" + (f" in {where}" if where else " worldwide") +
                 " on PitLap: address, opening hours, contacts and live track status.")
    b = [f"<h1>{esc(h1)}</h1>", f'<p class="lead">{esc(intro)}</p>']
    # sotto-zone: dal mondo ai paesi, dal paese alle regioni
    kids = sorted((k for k in CAT_GROUPS if k[1] and cat_parent(k, CAT_GROUPS) == key),
                  key=lambda k: -len(CAT_GROUPS[k]))
    if kids:
        b.append(f"<h2>{esc(t['areas'])}</h2><ul class=\"areas\">" + "".join(
            f'<li><a href="{esc(cat_path(k, lang))}">{esc(region_name(k[2], lang) if k[2] else country_name(k[1], lang))}</a> '
            f'<small>({len(CAT_GROUPS[k])})</small></li>' for k in kids) + "</ul>")
    lst = sort_items(items)
    b.append(f"<h2>{esc(t['plural']['track'])} ({len(lst)})</h2>" + cards(lst, lang))
    crumbs = [(t["hub_title"], t["hub_root"]), (cat_title((c, None, None), lang), cat_path((c, None, None), lang))]
    if country and (c, country, None) in CAT_GROUPS:
        crumbs.append((cat_title((c, country, None), lang), cat_path((c, country, None), lang)))
    if region:
        crumbs.append((h1, path))
    title = h1 + " | PitLap"
    return path, alt, title, clip(intro), [item_list_ld(lst, lang, path, h1)], crumbs, "\n".join(b)


def render_kind_index(kind, items, lang):
    t = T[lang]
    other = "en" if lang == "it" else "it"
    path, alt = t["path"][kind], T[other]["path"][kind]
    b = [f"<h1>{esc(t['plural'][kind])}</h1>"]
    if kind == "event":
        up, past = split_events(items)
        if up:
            b.append(f"<h2>{esc(t['upcoming'])}</h2>" + cards(up, lang))
        if past:
            b.append(f"<h2>{esc(t['past'])}</h2>" + cards(past, lang))
        ordered = up + past
    else:
        ordered = []
        by_c: dict = {}
        for i in items:
            by_c.setdefault(i["country"], []).append(i)
        for c in sorted(by_c, key=lambda c: (c != "IT", country_name(c, lang))):
            lst = sort_items(by_c[c])
            ordered += lst
            b.append(f"<h2>{esc(country_name(c, lang))} ({len(lst)})</h2>" + cards(lst, lang))
    title = f"{t['plural'][kind]} - " + ("elenco completo" if lang == "it" else "full list") + " | PitLap"
    desc = clip((f"Tutti i {t['plural'][kind].lower()} su PitLap, divisi per paese e citta'."
                 if lang == "it" else f"All {t['plural'][kind]} on PitLap, by country and city."))
    crumbs = [(t["hub_title"], t["hub_root"]), (t["plural"][kind], path)]
    return path, alt, title, desc, [item_list_ld(ordered, lang, path, t["plural"][kind])], crumbs, "\n".join(b)


# ---------------------------------------------------------------------------
# Scrittura
# ---------------------------------------------------------------------------

def clean(out: Path):
    for d in GEN_DIRS:
        p = out / d
        if p.exists():
            if not (p / MARKER).exists():
                sys.exit(f"ERRORE: {p} esiste ma non e' stata generata da questo script: non la tocco.")
            shutil.rmtree(p)


def write(out: Path, url_path: str, content: str):
    f = out / url_path.strip("/") / "index.html"
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text(content, encoding="utf-8", newline="\n")


def indexnow_payload(sitemap_xml: str) -> dict:
    urls = [html.unescape(u) for u in re.findall(r"<loc>(.*?)</loc>", sitemap_xml)]
    return {"host": urllib.parse.urlparse(SITE).netloc, "key": INDEXNOW_KEY,
            "keyLocation": f"{SITE}/{INDEXNOW_KEY}.txt", "urlList": urls[:10000]}  # limite del protocollo


def ping_indexnow(out: Path) -> None:
    # ponytail: invia sempre tutta la sitemap (~800 URL, ben sotto il limite di 10.000);
    # passare al solo delta (lastmod cambiati) se le schede diventano decine di migliaia.
    payload = indexnow_payload((out / "sitemap.xml").read_text(encoding="utf-8"))
    req = urllib.request.Request("https://api.indexnow.org/indexnow", data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json; charset=utf-8"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            print(f"IndexNow: {len(payload['urlList'])} URL inviati, risposta HTTP {r.status}")
    except urllib.error.HTTPError as e:  # 403 = file chiave non ancora online, 422 = URL fuori dominio
        sys.exit(f"IndexNow: errore HTTP {e.code} {e.read().decode(errors='replace')[:200]}")


def llms_txt(places, events, hubs) -> str:
    """Indice per gli assistenti AI (proposta llmstxt.org): cosa e' PitLap e dove sono i dati, con i numeri."""
    n = {k: sum(1 for p in places if p["kind"] == k) for k in ("track", "shop", "spot")}
    it_n = {k: sum(1 for p in places if p["kind"] == k and p["country"] == "IT") for k in ("track", "shop")}
    L = ["# PitLap", "",
         f"> PitLap (https://pitlap.app) e' la community del modellismo radiocomandato (RC): directory di {n['track']} piste RC, "
         f"{n['shop']} negozi di modellismo e {n['spot']} spot in {len({p['country'] for p in places})} paesi "
         f"(Italia: {it_n['track']} piste, {it_n['shop']} negozi), con stato delle piste in tempo reale, eventi e community. "
         "Pagine in italiano e inglese. Dati aggiornati a ogni pubblicazione del sito "
         f"(ultimo aggiornamento {dt.date.today().isoformat()}).", "",
         "## Directory", "",
         f"- [Modellismo RC, per paese e regione (IT)]({SITE}/modellismo-rc/)",
         f"- [RC directory by country and region (EN)]({SITE}/en/rc/)",
         f"- [Tutte le piste RC]({SITE}/piste/), [negozi]({SITE}/negozi/), [spot]({SITE}/spot-rc/), [eventi]({SITE}/eventi/)",
         "", "## Paesi e regioni italiane", ""]
    for key in sorted((k for k in hubs if k[0] and not k[2]), key=lambda k: (k[0] != "IT", k[1] is not None, hub_label(k, "it"))):
        cnt = sum(1 for i in hubs[key]["items"] if i["kind"] != "event")
        L.append(f"- [{hub_label(key, 'it')}]({SITE}{hub_url(key, 'it')}): {cnt} luoghi")
    L += ["", "## Piste per categoria", ""]
    for key in sorted((k for k in CAT_GROUPS if not k[1]), key=lambda k: -len(CAT_GROUPS[k])):
        L.append(f"- [{cat_title(key, 'it')}]({SITE}{cat_path(key, 'it')}): {len(CAT_GROUPS[key])} piste")
    L += ["", "## Optional", "", f"- [Sitemap completa]({SITE}/sitemap.xml)",
          f"- [Privacy]({SITE}/legal/privacy-policy)", ""]
    return "\n".join(L)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--data", type=Path, help="JSON gia' scaricato (chiavi tracks/shops/spots/events/cevents), per test offline")
    ap.add_argument("--indexnow", action="store_true",
                    help="NON rigenera: invia a IndexNow gli URL della sitemap gia' generata. Da lanciare DOPO il deploy.")
    args = ap.parse_args()
    if args.indexnow:
        return ping_indexnow(args.out)

    raw = json.loads(args.data.read_text(encoding="utf-8")) if args.data else load(args.config)
    raw = {k: raw.get(k) or [] for k in ("tracks", "shops", "spots", "events", "cevents")}
    places, events = build_entities(raw)
    hubs = group_hubs(places, events)
    CAT_GROUPS.update(cat_groups(places))
    out: Path = args.out
    out.mkdir(parents=True, exist_ok=True)
    clean(out)

    sitemap: list[tuple[str, str, str | None]] = []  # (it_path, en_path, lastmod)
    stats = {"pagine": 0}

    def emit(lang, res, lastmod=None):
        path, alt, title, desc, ld, crumbs, body = res
        image = None
        write(out, path, page(lang, title, desc, path, alt, image, body, ld, crumbs))
        stats["pagine"] += 1
        if lang == "it":
            sitemap.append((path, alt, lastmod))

    for lang in ("it", "en"):
        for p in places + events:
            path, alt, title, desc, ld, crumbs, body = render_item(p, lang, places, hubs)
            write(out, path, page(lang, title, desc, path, alt, p.get("image") if str(p.get("image") or "").startswith("https://") else None,
                                  body, ld, crumbs))
            stats["pagine"] += 1
            if lang == "it":
                sitemap.append((path, alt, (p.get("updated") or "")[:10] or None))
        for key, hub in hubs.items():
            emit(lang, render_hub(key, hub, lang, hubs))
        for key, items in CAT_GROUPS.items():
            emit(lang, render_cat(key, items, lang))
        for kind in ("track", "shop", "spot", "event"):
            lst = [p for p in places if p["kind"] == kind] if kind != "event" else events
            if lst:
                emit(lang, render_kind_index(kind, lst, lang))

    for d in GEN_DIRS:
        if (out / d).exists():
            (out / d / MARKER).write_text("Cartella generata da tools/build_seo_pages.py: non modificare a mano.\n",
                                          encoding="utf-8")

    # sitemap.xml con alternate hreflang (ogni URL elenca entrambe le lingue)
    today = dt.date.today().isoformat()
    urls = [("/", "/", today)] + sitemap
    lines = ['<?xml version="1.0" encoding="UTF-8"?>',
             '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">']
    for it_p, en_p, lastmod in urls:
        for loc in dict.fromkeys((it_p, en_p)):
            lines.append("<url><loc>%s</loc>%s" % (esc(SITE + loc), f"<lastmod>{lastmod}</lastmod>" if lastmod else ""))
            if it_p != en_p:
                lines += [f'<xhtml:link rel="alternate" hreflang="it" href="{esc(SITE + it_p)}"/>',
                          f'<xhtml:link rel="alternate" hreflang="en" href="{esc(SITE + en_p)}"/>',
                          f'<xhtml:link rel="alternate" hreflang="x-default" href="{esc(SITE + it_p)}"/>']
            lines.append("</url>")
    for legal in ("privacy-policy", "termini-di-servizio", "cookie-policy"):
        lines.append(f"<url><loc>{SITE}/legal/{legal}</loc></url>")
    lines.append("</urlset>")
    (out / "sitemap.xml").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")

    (out / f"{INDEXNOW_KEY}.txt").write_text(INDEXNOW_KEY, encoding="utf-8")
    (out / "llms.txt").write_text(llms_txt(places, events, hubs), encoding="utf-8", newline="\n")
    (out / "robots.txt").write_text(
        "# Generato da tools/build_seo_pages.py\n"
        "User-agent: *\n"
        "Allow: /\n"
        "Disallow: /admin\n"
        "Disallow: /manager\n"
        "Disallow: /garage\n"
        "Disallow: /onboarding\n"
        "Disallow: /profile$\n"
        "Disallow: /profile/\n"
        "Disallow: /shops/new\n"
        "\n"
        f"Sitemap: {SITE}/sitemap.xml\n", encoding="utf-8", newline="\n")

    n = {k: sum(1 for p in places if p["kind"] == k) for k in ("track", "shop", "spot")}
    print(f"Schede: {n['track']} piste, {n['shop']} negozi, {n['spot']} spot, {len(events)} eventi")
    print(f"Hub: {len(hubs)} per lingua | pagine totali: {stats['pagine']} | URL in sitemap: "
          f"{sum(1 for l in lines if l.startswith('<url>'))}")
    print(f"Output: {out}")


if __name__ == "__main__":
    main()
