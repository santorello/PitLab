# API Registry

Registro operativo delle API e dei servizi esterni usati da PitLap.

Obiettivo:

- tenere traccia di cosa usiamo davvero
- sapere dove appare ogni dato nel prodotto
- non perdere i requisiti di attribuzione, privacy e licensing
- preparare in anticipo crediti, pagine legali e note in-app/webapp

## Stato

Data aggiornamento: `2026-05-17`

## Regola di progetto

Ogni nuova API o servizio terzo va registrato qui con:

- nome
- funzione nel prodotto
- schermate o feature coinvolte
- documentazione ufficiale
- condizioni di utilizzo/licenza
- eventuale attribuzione da mostrare
- note privacy/legali

## API e servizi attivi

### 1. Supabase

Funzione:

- autenticazione email con magic link
- database Postgres
- Row Level Security
- persistenza profili, consensi, presenze e contenuti applicativi

Punti del prodotto:

- login
- profilo
- consensi
- piste
- presenza in pista
- dati pubblici di base

Documentazione ufficiale:

- [Supabase](https://supabase.com/)
- [Supabase Docs](https://supabase.com/docs)

Attribution in-app:

- non e' normalmente richiesta una citazione pubblica in UI come per una fonte dati editoriale
- va invece tracciata in documentazione tecnica e documenti privacy come fornitore infrastrutturale

Note privacy/legali:

- da citare in Privacy Policy come fornitore/backend platform
- da includere nel registro fornitori/sub-processors del progetto
- da verificare sempre rispetto a: auth, database, storage, log e retention

Note architetturali aggiornate:

- PitLap adotta una strategia di `public discovery`
- per i client guest non basta affidarsi alla sola RLS di tabella: quando una tabella contiene anche metadati sensibili o di ownership, e' preferibile esporre una view pubblica dedicata
- primo contratto esplicito adottato: `public.public_spots`
  - mantiene la scoperta pubblica degli spot
  - evita di esporre `owner_id`
  - espone invece un segnale UI sicuro `is_owned_by_current_user`
  - dal 2026-05-19 `owner_id` non e' piu' selezionabile direttamente da `anon`/`authenticated` su `public.spots`; il flag e' calcolato tramite helper DB nello schema `private`

### 2. Open-Meteo

Funzione:

- forecast meteo per la scheda pista
- geocoding testuale per suggerimenti localita in onboarding

Punti del prodotto:

- dettaglio pista
- card meteo
- eventuali evoluzioni future su home, eventi o notifiche meteo
- onboarding (`citta o provincia` con suggerimenti localita)

Documentazione ufficiale:

- [Open-Meteo Forecast API](https://open-meteo.com/en/docs)
- [Open-Meteo Terms](https://open-meteo.com/en/terms)
- [Open-Meteo Licence](https://open-meteo.com/en/licence)

Licenza / uso:

- i dati API sono dichiarati sotto `CC BY 4.0`
- il piano gratuito e' descritto come `non-commercial use`
- per uso commerciale o con volumi elevati va verificato eventuale piano a pagamento

Attribution in-app:

- tenere pronta una nota del tipo:
  `Dati meteo forniti da Open-Meteo`
- se necessario, aggiungere link alla licenza e indicazione che i dati possono essere stimati / non garantiti
- per geocoding, tenere tracciata in documentazione l'origine dei dati localita basata su GeoNames come indicato nella documentazione Open-Meteo

Note privacy/legali:

- nel free tier Open-Meteo dichiara raccolta di informazioni tecniche non personali e log tecnici per finalita' operative
- da citare in Privacy Policy / documenti terze parti se la feature meteo resta attiva in produzione
- va verificato il modello di licensing definitivo prima del rilascio pubblico/commerciale
- per il geocoding, uso adatto alla fase pre-alpha / non commerciale; prima di rollout commerciale o ad alto traffico va rivalutato il piano o un provider dedicato

### 3. MapTiler

Funzione:

- ricerca luogo canonica con autocomplete
- geocoding forward per luoghi selezionati
- tile map per preview mappa e mappe client-side

Punti del prodotto:

- onboarding (`citta o provincia`)
- `submit-place` spot
- preview mappa riusabili del nuovo `place system`
- base del futuro layer mappa unico

Dettagli implementativi attuali:

- configurazione client via `MAPTILER_API_KEY`
- `PlacePickerField` per autocomplete condiviso
- `PlaceMapPreviewCard` per preview mappa coerente tra flussi

Documentazione ufficiale:

- [MapTiler Cloud Pricing](https://www.maptiler.com/cloud/pricing/)
- [MapTiler Geocoding API](https://docs.maptiler.com/cloud/api/geocoding/)
- [MapTiler Maps API](https://docs.maptiler.com/cloud/api/maps/)

Licenza / uso:

- il piano `Free` e' coerente con la fase attuale non commerciale / pre-alpha
- un eventuale rollout commerciale richiedera' revisione piano/provider

Attribution in-app:

- la mappa deve mantenere attribution coerente al provider e ai dati base

Note privacy/legali:

- da citare come provider terzo per servizi mappe / geocoding se la feature resta attiva in produzione

## API e servizi previsti

### Storage immagini profilo / garage / negozi

Candidato naturale:

- Supabase Storage

Uso previsto:

- avatar profilo
- immagini build garage
- cover e gallerie negozi
- cover e gallerie piste
- immagini eventi

Da definire:

- bucket separati o bucket unico con path strutturati
- policy accesso basate su ownership e ruoli
- immagini pubbliche vs private
- thumbnail e preview
- trasformazioni e dimensioni
- moderazione e rimozione media
- pulizia immagini orfane

Limiti prodotto iniziali:

- negozi: 10 immagini galleria + 1 cover
- piste: 10 immagini galleria + 1 cover
- build garage: 5 immagini
- eventi: 5 immagini + 1 cover

Attribution in-app:

- non e' normalmente richiesta una citazione pubblica distinta se usato come storage infrastrutturale
- da citare nella documentazione privacy/fornitori come parte dei servizi Supabase

Nota tecnica:

- Supabase Image Transformations puo' essere utile per thumbnail e preview, ma va verificato il piano/costo prima del rilascio

### Link social e canali esterni

Stato:

- non ancora integrato come API strutturata
- previsto come dato editoriale validato, non come integrazione API piena

Canali candidati:

- sito web
- Instagram
- Facebook
- YouTube
- TikTok
- WhatsApp / Telegram se utili a negozi e piste

Da definire:

- allowlist provider
- validazione URL
- moderazione admin
- policy privacy e responsabilita' sui link esterni

### Mappe / geocoding

Stato:

- integrazione mappa client-side attiva per `Spot`
- nuovo `place system` condiviso avviato con provider astratto e implementazione attiva `MapTiler`

Stato operativo attuale:

- `/spots/map` usa una prima mappa reale client-side con tile raster OpenStreetMap e marker derivati da coordinate degli spot
- questa scelta va considerata base tecnica iniziale / ambiente di sviluppo, non soluzione definitiva per produzione ad alto traffico
- onboarding e `submit-place` convergono sul nuovo flusso di selezione luogo canonica con preview mappa
- prima del rollout commerciale va rivalutato piano/provider mappe

## Attribuzioni da prevedere in prodotto

Possibili punti UI:

- footer web
- pagina `Credits / Fonti dati`
- sezione `Informazioni legali`
- nota nella card meteo o nel dettaglio pista

Bozza minima consigliata:

- `Dati meteo forniti da Open-Meteo`
- `Servizi infrastrutturali gestiti tramite Supabase`

## Checklist prima del rilascio

- verificare che ogni API usata compaia qui
- verificare termini/licenza aggiornati
- verificare se l'uso e' commerciale o non commerciale
- decidere dove mostrare l'attribuzione in UI
- allineare Privacy Policy e documenti legali
- allineare eventuale pagina `Credits`

## Nota operativa

Le nuove feature dati come contatori preferiti, storico eventi e biblioteca digitale non introducono per ora nuove API esterne.
Continuano ad appoggiarsi a:

- `Supabase` per dati, ruoli, ownership e persistenza
- `Open-Meteo` solo per il modulo meteo pista
