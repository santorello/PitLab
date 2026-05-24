# Backend Baseline

Baseline tecnica per il backend iniziale di PitLap.

Obiettivo:

- rendere eseguibile il bootstrap Supabase
- fissare un modello dati MVP estendibile
- chiarire permessi, ambienti e flussi principali

## Stato

Data: `2026-05-17`

Stato:

- baseline raccomandata per avvio implementazione
- alcuni punti restano marcati come dubbi controllati

## Stack confermato

Backend iniziale:

- `Supabase Auth`
- `Supabase Postgres`
- `Supabase Realtime`
- `Supabase Storage`

Da rimandare salvo necessita' concreta:

- Edge Functions
- queue e job strutturati
- full text search avanzata
- analytics dedicate

## Principi architetturali

- lettura pubblica semplice per dati pista pubblici
- lettura pubblica ampia per la discovery guest
- scrittura protetta da ruoli e ownership
- modello relazionale leggibile
- campi audit presenti fin dall'inizio
- estensibilita' senza overengineering

Aggiornamento operativo:

- il principio prodotto non e' piu' "ridurre il pubblico", ma "mantenere ampia la discovery e stringere solo dettagli sensibili e azioni dispositive"
- quando una tabella pubblica contiene anche campi non necessari al guest, il backend deve preferire una superficie pubblica esplicita
- esempio adottato:
  - view `public.public_spots` per il client guest
  - dati di discovery esposti
  - metadato `owner_id` non esposto
  - flag `is_owned_by_current_user` calcolato per sostenere la UI senza leak di ownership
  - grant diretti su `public.spots` limitati per colonna: `owner_id` resta usabile in insert autenticato e nel calcolo DB, ma non e' selezionabile da `anon`/`authenticated`
  - helper di ownership spot collocato nello schema non esposto `private`, coerente con la raccomandazione Supabase di non mettere funzioni privilegiate negli schema API quando non devono essere RPC pubbliche

## Ambienti

Ambienti minimi iniziali:

- `dev`
- `prod`

Regola:

- usare due progetti Supabase distinti
- evitare staging iniziale finche' non serve davvero

## Modello auth

### Identita'

Scelta raccomandata MVP:

- autenticazione email con magic link o OTP email

Motivazione:

- riduce attrito rispetto a password classica
- evita subito gestione password custom
- e' sufficiente per un MVP con pubblico iniziale ristretto

Evoluzioni future possibili:

- Google login
- Apple login
- login social di nicchia solo se richiesto da adozione reale

### Profili

Non usare una tabella `users` separata come fonte primaria applicativa.

Scelta raccomandata:

- usare `auth.users` come sorgente auth
- creare tabella applicativa `profiles`

Campi iniziali `profiles`:

- `id` uuid primary key references `auth.users.id`
- `display_name`
- `avatar_url`
- `preferred_language`
- `role`
- `created_at`
- `updated_at`

Ruoli iniziali da modellare:

- `guest` come stato applicativo non persistito
- `user` per il modellista registrato standard
- `shop_owner` per chi gestisce un negozio
- `track_organizer` per chi gestisce una pista
- `admin` per controllo completo del sistema

Nota:

- `guest` non vive in tabella ma nella logica applicativa
- `shop_owner` e `track_organizer` vanno collegati anche a ownership esplicite
- `admin` e' un ruolo globale, mentre negozi e piste richiedono anche relazioni di ownership

Enum database raccomandato `app_role`:

- `user`
- `shop_owner`
- `track_organizer`
- `admin`

### Matrice permessi iniziale

- `guest`: puo' leggere contenuti pubblici come piste, negozi ed eventi
- `user`: puo' creare profilo, garage, preferiti, presenze ed eventi
- `shop_owner`: come `user`, piu' gestione del proprio negozio o dei propri negozi
- `track_organizer`: come `user`, piu' gestione della propria pista o delle proprie piste
- `admin`: puo' creare, modificare, eliminare e moderare utenti, negozi, piste, eventi, garage, immagini, categorie hobby e categorie label

### Pannelli operativi

- `manager panel`: focalizzato su ownership specifica di pista o negozio
- `admin panel`: pannello globale per amministrazione completa senza dipendere da query SQL
- `admin dashboard`: vista personale di monitoraggio, da definire con metriche e alert utili

## Modello dati MVP

### 1. `tracks`

Scopo:

- anagrafica pubblica della pista

Campi iniziali:

- `id`
- `slug`
- `name`
- `short_description`
- `description`
- `address`
- `city`
- `country`
- `latitude`
- `longitude`
- `external_map_url`
- `is_public`
- `created_at`
- `updated_at`

Vincoli:

- `slug` univoco
- `is_public` default `true`

### 2. `track_categories`

Scopo:

- tassonomia riusabile delle categorie

Campi:

- `id`
- `key`
- `label_it`
- `label_en`
- `sort_order`

### 3. `track_category_links`

Scopo:

- relazione molti-a-molti tra pista e categoria

Campi:

- `track_id`
- `category_id`

Vincoli:

- chiave composta univoca

### 4. `track_status_current`

Scopo:

- stato corrente della pista ottimizzato per lettura rapida

Campi:

- `track_id`
- `status`
- `message`
- `updated_by`
- `updated_at`

Valori iniziali `status`:

- `open`
- `wet`
- `closed`
- `unknown`

Nota:

- `unknown` e' utile per piste non ancora aggiornate senza forzare un falso stato

### 5. `track_status_history`

Scopo:

- storico degli aggiornamenti di stato

Campi:

- `id`
- `track_id`
- `status`
- `message`
- `updated_by`
- `updated_at`

Scelta:

- l'app legge principalmente `track_status_current`
- ogni update scrive anche su `track_status_history`

### 6. `service_types`

Scopo:

- dizionario servizi disponibili nel sistema

Campi:

- `id`
- `key`
- `label_it`
- `label_en`
- `icon_key`
- `sort_order`

Valori iniziali raccomandati:

- `power_220v`
- `compressed_air`
- `tables`
- `chairs`
- `toilets`
- `food`

### 7. `track_services`

Scopo:

- disponibilita' dei servizi per singola pista

Campi:

- `id`
- `track_id`
- `service_type_id`
- `is_available`
- `notes`
- `updated_at`

Vincoli:

- una sola riga per coppia `track_id` + `service_type_id`

### 8. `arrivals`

Scopo:

- intenzione di presenza su una data specifica

Campi:

- `id`
- `track_id`
- `user_id`
- `arrival_date`
- `status`
- `note`
- `created_at`
- `updated_at`

Nota di confine:

- `arrivals` resta separata da ogni concetto di preferito persistente
- serve per sapere chi pensa di essere presente in una giornata/sessione

### 9. `track_follows`

Scopo:

- legame persistente tra utente e pista
- base per `Preferiti`, `Segui pista` e notifiche future

Campi iniziali:

- `track_id`
- `user_id`
- `created_at`

Vincoli:

- chiave primaria composta `track_id` + `user_id`

Scelta raccomandata:

- non riusare `arrivals` per preferiti o notifiche
- tenere separati il gesto operativo `Sto arrivando` e il rapporto stabile `Segui pista`
- partire con il solo concetto di follow/favorito
- aggiungere `notifications_enabled` solo quando il modulo notifiche sara' reale

Estensione prevista:

- esporre contatori aggregati di preferiti per pista
- introdurre un analogo modello `shop_follows` o equivalente per i negozi
- decidere se i contatori sono pubblici o visibili solo ad utenti autenticati

### 10. `user_consents`

Scopo:

- tracciare consenso e prese visione legate a login, termini e privacy
- distinguere chiaramente elementi obbligatori del servizio e marketing opzionale

Campi:

- `user_id`
- `consent_type`
- `accepted`
- `document_version`
- `source`
- `created_at`
- `updated_at`

Valori iniziali `consent_type`:

- `terms_accepted`
- `privacy_notice_seen`
- `marketing_email_opt_in`

Scelta raccomandata:

- non salvare questi dati in `profiles`
- usare una tabella dedicata per mantenere versioni documento, sorgente e stato del consenso in modo chiaro

Valori iniziali `status`:

- `coming`
- `maybe`
- `cancelled`

Vincoli raccomandati:

- una sola riga attiva per `track_id` + `user_id` + `arrival_date`

### 11. `events`

Scopo:

- eventi pubblici visibili in pista

Campi:

- `id`
- `track_id`
- `title`
- `description`
- `start_at`
- `end_at`
- `visibility`
- `rsvp_enabled`
- `created_by`
- `created_at`
- `updated_at`

Valori iniziali `visibility`:

- `public`
- `hidden`

Estensione prevista:

- distinguere eventi attivi, futuri, chiusi e archiviati
- permettere una consultazione storica per utente, negozio e organizzatore pista
- supportare una "biblioteca eventi" navigabile nel tempo

### 12. `event_rsvps`

Scopo:

- adesione semplice agli eventi

Campi:

- `id`
- `event_id`
- `user_id`
- `status`
- `created_at`
- `updated_at`

Valori iniziali `status`:

- `going`
- `maybe`
- `cancelled`

### 13. `track_managers`

Scopo:

- autorizzazioni per gestire una o piu' piste

Campi:

- `id`
- `track_id`
- `user_id`
- `granted_by`
- `created_at`

Vincoli:

- una sola riga per coppia `track_id` + `user_id`

### 14. `shops`

Scopo:

- anagrafica pubblica del negozio

Campi iniziali raccomandati:

- `id`
- `slug`
- `name`
- `short_description`
- `description`
- `address`
- `city`
- `country`
- `latitude`
- `longitude`
- `external_map_url`
- `website_url`
- `phone`
- `is_public`
- `created_at`
- `updated_at`

### 15. `shop_managers`

Scopo:

- ownership e gestione dei dati del negozio

Campi:

- `id`
- `shop_id`
- `user_id`
- `granted_by`
- `created_at`

Vincoli:

- una sola riga per coppia `shop_id` + `user_id`

### 16. `shop_follows`

Scopo:

- legame persistente tra utente e negozio
- base per `Preferiti negozio`, contatori e notifiche future

Campi iniziali:

- `shop_id`
- `user_id`
- `created_at`

Vincoli:

- chiave primaria composta `shop_id` + `user_id`

### 17. `track_media`

Scopo:

- immagini o asset base della pista

Campi:

- `id`
- `track_id`
- `storage_path`
- `media_type`
- `alt_it`
- `alt_en`
- `sort_order`
- `created_at`

Uso iniziale:

- copertina o immagine principale
- eventuale logo pista

## Estensioni di dominio gia' previste

Queste aree non devono rompere il backend iniziale quando verranno aggiunte.

### 18. `shop_categories`

Scopo:

- classificare i negozi per tipologia o specializzazione

Esempi:

- `rc_general`
- `mini4wd`
- `crawler`
- `electronics`
- `parts`

### 19. `shop_category_links`

Scopo:

- relazione molti-a-molti tra negozio e categoria

### 20. `shop_media`

Scopo:

- logo, copertina e immagini base del negozio

### 21. `garage_models`

Scopo:

- garage personale del pilota

Campi iniziali raccomandati:

- `id`
- `user_id`
- `display_name`
- `category_key`
- `brand`
- `model_name`
- `scale`
- `notes`
- `is_public`
- `created_at`
- `updated_at`

### 22. `garage_model_media`

Scopo:

- immagini dei modelli nel garage

### 23. `public_profiles`

Scopo:

- controlli di visibilita' del profilo pubblico pilota

Campi iniziali raccomandati:

- `user_id`
- `public_slug`
- `bio`
- `city`
- `country`
- `is_public`
- `show_garage`
- `show_gallery`
- `updated_at`

Nota:

- questa tabella puo' anche essere assorbita in `profiles`, ma tenerla separata semplifica la privacy e le evoluzioni future

### 24. `profile_media`

Scopo:

- gallery pubblica opzionale dell'utente

### 25. `place_submissions`

Scopo:

- segnalazioni utente di nuovi luoghi, piste, spot o negozi

Campi iniziali raccomandati:

- `id`
- `submitted_by`
- `submission_type`
- `name`
- `description`
- `address`
- `city`
- `country`
- `latitude`
- `longitude`
- `external_map_url`
- `contact_name`
- `contact_phone`
- `contact_email`
- `status`
- `review_notes`
- `approved_entity_type`
- `approved_entity_id`
- `created_at`
- `updated_at`

Valori iniziali `submission_type`:

- `track`
- `spot`
- `shop`

Valori iniziali `status`:

- `pending`
- `approved`
- `rejected`
- `needs_review`

Nota:

- `approved_entity_type` e `approved_entity_id` servono a collegare la segnalazione all'entita' effettivamente creata o approvata

### 26. `place_submission_media`

Scopo:

- foto o riferimenti visivi allegati alla segnalazione

## Query e letture principali MVP

Le query principali che il modello deve servire bene sono:

1. elenco piste pubbliche con stato corrente e servizi principali
2. scheda pista con stato, servizi, info base, arrivi di oggi, eventi vicini
3. elenco eventi per pista
4. arrivo dell'utente per oggi
5. area gestore per aggiornare stato e servizi

Query importanti di fase successiva vicina:

6. negozi pubblici vicini alla posizione utente
7. profilo pubblico pilota
8. garage modelli personale
9. gallery pubblica opzionale
10. discovery mista piste + negozi su base geografica
11. elenco segnalazioni utente in attesa di revisione
12. creazione di nuova segnalazione luogo
13. conteggi aggregati di follow per pista e negozio
14. storico eventi per attore (`utente`, `negozio`, `organizzatore pista`)
15. viste archivio per la futura biblioteca digitale

## Realtime

Abilitare realtime inizialmente per:

- `track_status_current`
- `arrivals`

Valutare dopo il primo uso reale:

- `events`

Regola:

- niente subscription globale inutile
- sottoscrizioni solo su pista o vista aperta

## Storage

Bucket iniziali:

- `track-media`
- `avatars`

Bucket da prevedere presto:

- `shop-media`
- `garage-media`
- `profile-media`
- `submission-media`

Regole:

- lettura pubblica per media pubblici di pista
- scrittura autenticata e filtrata da policy

## Policy e sicurezza

### Letture pubbliche

Consentire in lettura anonima:

- `tracks` pubbliche
- `track_status_current`
- `track_categories`
- `track_category_links`
- `service_types`
- `track_services`
- `events` pubblici
- `track_media`

### Scritture utente autenticato

Consentire al proprietario:

- update del proprio `profiles`
- create/update/delete delle proprie `arrivals`
- create/update/delete delle proprie `event_rsvps`

### Scritture gestore

Consentire a chi e' in `track_managers` per quella pista:

- update di `track_status_current`
- insert in `track_status_history`
- update di `track_services`
- create/update eventi della propria pista
- upload media autorizzati

Consentire a chi e' in `shop_managers` per quel negozio:

- update del proprio `shops`
- gestione futura di media, contatti, orari e note del negozio

### Scritture admin

Consentire all'admin:

- gestione completa del catalogo
- assegnazione manager
- correzione dati globali

## Indici raccomandati

Creare subito indici su:

- `tracks.slug`
- `tracks.is_public`
- `track_status_current.track_id`
- `arrivals.track_id`
- `arrivals.user_id`
- `arrivals.arrival_date`
- `events.track_id`
- `events.start_at`
- `track_managers.track_id`
- `track_managers.user_id`

## Naming e convenzioni

Convenzioni raccomandate:

- tabelle al plurale
- colonne `created_at`, `updated_at` uniformi
- `id` uuid come chiave primaria quasi ovunque
- valori enum in inglese, UI localizzata lato app

## Seed iniziale

Seed minimo raccomandato:

- 5 piste pilota
- categorie base
- service types base
- almeno 2 eventi demo
- 1 admin
- 1 o 2 manager reali su piste selezionate

## Dubbi da tenere evidenti

### Dubbio 1. Login iniziale

Ipotesi attuale:

- email magic link

Rischio:

- alcuni utenti potrebbero preferire Google per velocita'

Decisione pratica:

- partire con magic link
- rivalutare dopo i primi test reali

### Dubbio 2. RSVP eventi

Ipotesi attuale:

- modello leggero `going / maybe / cancelled`

Rischio:

- se i club chiedono entry list piu' rigide, servira' un modello gara diverso

Decisione pratica:

- non complicare l'MVP

### Dubbio 3. Geolocalizzazione

Ipotesi attuale:

- coordinate opzionali e mappe esterne

Rischio:

- in alcune discipline outdoor la posizione precisa puo' diventare presto critica

Decisione pratica:

- tenere i campi pronti ma non costruire la feature mappa ora

### Dubbio 4. Privacy delle presenze

Ipotesi attuale:

- la funzione `Sto arrivando` deve permettere di capire chi ci sara'

Rischio:

- esporre troppo presto nomi e profili in modo troppo aperto puo' creare attrito o problemi privacy

Decisione pratica:

- partire con visibilita' semplice ma controllata
- rivalutare presto se mostrare nome pieno, alias o conteggio aggregato agli utenti non autenticati

### Dubbio 5. Privacy dei profili pubblici

Ipotesi attuale:

- il profilo pilota pubblico e la gallery devono essere opzionali

Rischio:

- se i controlli di visibilita' non sono chiari, gli utenti potrebbero non fidarsi del sistema

Decisione pratica:

- tutto cio' che e' pubblico deve essere opt-in esplicito
- separare bene dati account, garage privato e profilo pubblico

### Dubbio 6. Mappa e geodiscovery

Ipotesi attuale:

- la mappa serve per il "vicino a te", ma non come vista primaria

Rischio:

- se la mappa entra troppo presto nel flusso principale, puo' rallentare UX e sviluppo

Decisione pratica:

- preparare coordinate e query geografiche
- introdurre la vista mappa dopo il core list/detail

### Dubbio 7. Meteo

Ipotesi attuale:

- meteo indicativo 5 giorni utile soprattutto per outdoor

Rischio:

- dipendenza esterna con costi, rate limit e rischio di sovraesposizione in UI

Decisione pratica:

- trattarlo come modulo accessorio di contesto
- non farne una dipendenza critica per il core prodotto

### Dubbio 8. Moderazione segnalazioni

Ipotesi attuale:

- la segnalazione utente deve essere mediata e non pubblicata in automatico

Rischio:

- senza moderazione, il catalogo puo' degradare rapidamente

Decisione pratica:

- prevedere stato `pending` e revisione amministrativa o manageriale
- evitare pubblicazione automatica nel catalogo pubblico

## Criterio di successo tecnico

La baseline e' corretta se consente di costruire senza rifare il backend quando aggiungeremo:

- storico piu' ricco
- piu' categorie
- piu' manager
- media e gallery
- notifiche e automazioni future
- contatori aggregati e pagine archivio
- una biblioteca digitale trasversale di attori, eventi e contenuti
