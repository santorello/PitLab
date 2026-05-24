# Architettura

## Obiettivo architetturale

Costruire una piattaforma unica con una codebase Flutter condivisa tra Android e Web, appoggiata a un backend gestito per ridurre il carico operativo iniziale.

## Target di distribuzione (requisito confermato)

PitLap viene distribuito su **due canali simultanei**:

- **Web** — Flutter web buildata su hosting statico (Vercel / Firebase Hosting)
- **Android nativo** — App pubblicata sul Play Store

Questi non sono obiettivi futuri opzionali: entrambi sono target di lancio. Ogni decisione di architettura, layout e codice deve tenere conto di entrambi. Vedere `best-practices.md` per le regole operative derivate da questo vincolo.

## Scelte iniziali proposte

### Frontend

- Flutter come unica codebase
- target **confermati e simultanei**: Android nativo e Web
- approccio responsive per adattare le viste da mobile a desktop; mobile-first come direzione di design
- supporto i18n per italiano e inglese con selezione lingua lato utente

### Backend

- Supabase come backend principale

Motivazioni:

- autenticazione pronta
- database PostgreSQL
- storage integrato
- realtime disponibile
- buona velocita' di bootstrap per un team di una persona

### Hosting

Opzione proposta:

- Webapp Flutter buildata e pubblicata su hosting statico

Possibili candidati:

- Vercel
- Firebase Hosting
- hosting statico compatibile

### Servizi esterni

Da introdurre solo quando servono davvero:

- mappe
- meteo
- notifiche push avanzate

## Architettura logica

### Client

- App Android Flutter
- Webapp Flutter

### Backend services

- Auth
- Database
- Storage
- Realtime subscriptions

### Media pipeline

Per evitare degrado progressivo con la crescita degli utenti:

- resize client-side prima dell'upload
- upload su Supabase Storage
- registro asset su tabella dedicata `media_assets`
- thumbnail per card e liste
- preview ottimizzate per dettaglio
- originali o versioni ottimizzate mai usate direttamente nelle liste
- ownership e RLS per upload, lettura e cancellazione
- moderazione admin per media pubblici

### Place system condiviso

Dal 2026-04-21 PitLap introduce una base condivisa per gestione luoghi:

- `PlaceSelection` come modello canonico applicativo
- provider astratto di ricerca luogo
- implementazione attiva `MapTiler` per fase non commerciale
- widget riusabili `PlacePickerField` e `PlaceMapPreviewCard`

Obiettivo:

- evitare logiche geocoding duplicate
- salvare selezioni luogo con coordinate, provider e label canonica
- permettere cambio provider senza riscrivere le schermate

### Domini funzionali

- utenti
- piste
- servizi pista
- stato pista
- presenze
- eventi
- ruoli gestore
- media e gallerie
- link social/canali esterni

## Principi tecnici

- partire semplice
- evitare microservizi e complessita' prematura
- separare bene dominio, UI e accesso dati
- progettare subito le entita' principali, non tutte le feature future
- progettare i testi in ottica multilingua fin dall'inizio

## Struttura applicativa proposta

Da confermare in fase bootstrap:

- `lib/app`
- `lib/features`
- `lib/shared`
- `lib/services`
- `lib/models`
- `lib/l10n`

## Ambienti

Minimo indispensabile:

- local/dev
- production

Staging opzionale in una fase successiva.

## Sicurezza e accessi

Ruoli iniziali:

- utente anonimo/visitatore web
- utente autenticato
- gestore pista
- amministratore

Regole base:

- i dati pubblici delle piste devono essere leggibili senza attrito
- le modifiche allo stato pista devono essere riservate a ruoli autorizzati
- le informazioni personali devono essere ridotte al minimo necessario
- i media pubblici devono avere owner, limiti, possibilita' di rimozione e tracciamento
- i link esterni devono essere validati e gestibili dall'admin

## Flusso dati: Supabase-first (aggiornato aprile 2026)

Dall'aprile 2026, PitLap ha abbandonato qualsiasi stato locale (SharedPreferences) per i dati condivisi tra dispositivi. Tutte le entità che devono essere visibili all'admin, ad altri utenti o tra sessioni diverse devono risiedere esclusivamente su Supabase.

### Entità migrate da SharedPreferences → Supabase

- **Piste inviate da organizzatori** (`tracks`): lo stato locale `ManagerTrackDraft` è stato rimosso. Il file `manager_track_drafts_providers.dart` non esiste più. Tutte le submission passano per `TracksRepository.insertSubmittedTrack` e `updateSubmittedTrack`, con `approval_status = 'draft' | 'pending'`. Il flusso di approvazione admin legge da Supabase tramite `AdminRepository.fetchPendingTrackSubmissions`.
- **Garage personale** (`user_builds`): la tabella `user_builds` con RLS garantisce che i build privati siano visibili solo al proprietario. Lo schermo garage usa `GarageController` (Riverpod Notifier) con aggiornamenti ottimistici.

### Invarianti architetturali risultanti

- `isPublishedTrackId(id)` è il guard UUID usato in tutto il codice per evitare di passare slug locali a Supabase.
- Nessun widget accede direttamente a Supabase: tutto passa per repository (`TracksRepository`, `GarageRepository`, `AdminRepository`).
- Il provider `managerTrackDraftsProvider` è stato eliminato. Usare `submittedTracksProvider` (`FutureProvider<List<SubmittedTrack>>`) per leggere le piste inviate dall'organizzatore corrente.
- Il provider `adminApprovalQueueProvider` è un `FutureProvider` che legge da Supabase sia le piste sia i negozi in approvazione.
- Il flusso `shops` è ora `remote-first`: salvataggio bozza e invio approvazione passano da `shops`, con fallback locale solo quando Supabase non è proprio disponibile.
- Le submission `shops` creano automaticamente la relazione `shop_managers`, così l'owner continua a poter gestire la scheda anche dopo il primo insert.

## Decisioni ancora aperte

- login obbligatorio o facoltativo per alcune funzioni web
- strategia precisa di deploy web
- uso di realtime puro o refresh periodico in alcune schermate
- integrazione mappe nella fase 1 o successiva
- lingua iniziale predefinita da browser/device o da preferenza salvata utente
- scelta definitiva tra thumbnail generate da Supabase Image Transformations o pipeline custom
- momento esatto in cui estendere la persistenza coordinate a tutte le entita' applicative
