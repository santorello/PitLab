# Development Checklist

Checklist operativa viva per PitLap.

Scopo:

- tenere in un solo posto tutto cio' che e' gia' fatto
- rendere visibili i punti sospesi emersi durante lo sviluppo
- evitare di perdere dettagli tecnici o UX da riprendere
- dare un ordine pratico ai prossimi passi

## Stato

Data aggiornamento: `2026-05-05`

Stato:

- documento operativo attivo
- da aggiornare a ogni blocco di lavoro rilevante

## Priorita' operative

Legenda:

- `P0`: blocco critico o quasi bloccante per il flusso principale
- `P1`: alta priorita', impatta direttamente MVP e percezione qualita'
- `P2`: media priorita', migliora struttura e coerenza
- `P3`: evoluzione futura o non urgente

Legenda impatto:

- `Prodotto`: esperienza utente, chiarezza, retention, valore percepito
- `Tecnico`: architettura, mantenibilita', dati, stabilita'
- `Legale`: consensi, documenti, compliance, fiducia
- `Operativo`: facilità di gestione, moderazione, contenuti, rollout

## Beta readiness — Audit 2026-05-05

Blocchi identificati durante l'audit pre-beta. L'obiettivo è portare il prodotto da pre-alpha a beta pubblica eliminando refusi, feature false, funzionalità non collegate al DB e promesse non mantenute nell'UI.

### 🔴 Bloccanti — da risolvere prima di qualsiasi utente reale

- ~~**Testo onboarding falso**~~: ✅ corretto (2026-05-05) — "Il tuo feed personalizzato è pronto" → "Sei dentro — esplora la community"; righe "Feed aggiornato in base ai tuoi interessi" rimosse. (`onboarding_screen.dart`)
  Impatto: `Prodotto`, `Tecnico`

- ~~**Immagini garage non persistenti**~~ ✅ gestito (2026-05-05): strategia beta scelta = warning prominente vicino al pulsante. Il pulsante rinominato da "Carica foto" a "Anteprima foto"; avviso con icona info spostato subito sotto il pulsante upload (era in fondo al form, invisibile). Solo URL esterni vengono persistiti a DB. Supabase Storage rinviato a post-beta. (`garage_screen.dart`)
  Impatto: `Prodotto`, `Tecnico`

### 🟡 UX cleanup — importanti per percepire il prodotto come reale

- ~~**Rimuovere card "Principio di governance"**~~ ✅ già assente (2026-05-05): le chiavi `managerGovernanceTitle/Body` esistono in ARB ma non sono mai referenziate nel codice della schermata. Nessuna azione necessaria.
  Impatto: `Prodotto`

- ~~**Redesign sezione "Operazioni Principali"**~~ ✅ fatto (2026-05-05): la card con 3 `_ManagerActionCard` descrittive sostituita con card "Azioni rapide" con 3 bottoni reali: Modifica scheda pista, Gestisci eventi, Vedi scheda pubblica. (`manager_screen.dart`)
  Impatto: `Prodotto`

- **Fix mappa "Vicino a te"** — la mappa mostra tiles e dati Google Maps invece del layer PitLap con marker piste/spot. I marker PitLap non sono visibili o sono sovrapposti a dati Google che non appartengono al prodotto.
  Impatto: `Prodotto`, `Tecnico`

- ~~**Hardcoded IT/EN in `nearby_screen.dart`**~~ ✅ fatto (2026-05-05): aggiunte 9 nuove chiavi ARB (`nearbyNearMeButton`, `nearbyOpenInMap`, `nearbyOpenTrack`, `nearbyOpenShop`, `nearbyNoServices`, `nearbyServicesCount`, `nearbyShopGeneric`, `nearbyStatusUpdating`), aggiornati i 3 file generati, rimossa la funzione helper `_localeText`. Tutti i testi passano ora per il sistema `l10n`.
  Impatto: `Prodotto`, `Tecnico`

### 🟢 Funzionalità mancanti — aggiungere dopo i bloccanti

- **"Vicino a te" — aggiungere Spot, Eventi, Garage**: la sezione attualmente mostra solo piste. Aggiungere tab o sezioni per Spot e Eventi. Garage può arrivare dopo ma va pianificato ora.
  Impatto: `Prodotto`

- **Ricerca globale con filtri per tipo**: oggi non esiste una ricerca trasversale tra piste, spot, negozi ed eventi. Progettare e implementare prima di invitare utenti reali.
  Impatto: `Prodotto`, `Tecnico`

- **Redesign bottom nav** (ROADMAP R07): Home · Mappa · Piste · Garage · Profilo — la struttura attuale non riflette la nuova architettura community-first.
  Impatto: `Prodotto`

### 🔧 Pulizia tecnica — da fare in parallelo

- ~~**Marcare i provider KYC dormanti**~~ ✅ fatto (2026-05-05): `personalizedFeedProvider`, `hasUserInterestsProvider`, `_userInterestsProvider` marcati con `// DORMANT — beta` e `// ignore: unused_element`. (`activity_feed_provider.dart`)
  Impatto: `Tecnico`

- **Fix `updated_at` su `track_status_current`** (ROADMAP R11): il timestamp non si aggiorna sull'upsert — dati inconsistenti nella timeline Gestione pista.
  Impatto: `Tecnico`

- **Fix `fetchManagedTrackBySlug`** (ROADMAP R10, bug 406): query invertita già scritta, da verificare in produzione e correggere se ancora presente.
  Impatto: `Tecnico`

---

## Backlog prioritizzato

## Vincolo trasversale: cross-platform Android + Web

PitLap viene distribuito **su entrambe le piattaforme in parallelo**: Web (Flutter web su hosting statico) e Android nativo (Play Store). Questo non e' un obiettivo futuro. Ogni schermata e componente deve essere progettato e verificato su entrambi. Regole operative dettagliate in `docs/best-practices.md` → sezione "Regola cross-platform".

Checklist cross-platform da tenere attiva su ogni nuova schermata o componente:

- touch target >= 48x48 dp ovunque (dito su Android, click su Web)
- nessuna interazione hover-only senza equivalente su tap
- layout testato a tre breakpoint: < 600, 600-1024, > 1024
- nessuna dipendenza da API browser-only senza guard `kIsWeb`
- CTA primaria raggiungibile con il pollice su mobile

### P0

- completare verifica end-to-end auth web e callback magic link (codice completo — da testare runtime)
  Impatto: `Prodotto`, `Tecnico`, `Legale`

### P1

- ~~separare chiaramente rotta e schermata pubblica `shop detail` da `shop editor`~~ ✅ fatto (2026-04-17): ShopDetailScreen riscritta, ShopEditorScreen separata su /shop/:slug/edit
  Impatto: `Prodotto`, `Tecnico`
- aprire il profilo pubblico agli utenti guest quando marcato pubblico
  Impatto: `Prodotto`, `Tecnico`
- riallineare `TrackCard` e hero pista alla grammatica UI definita dal mockup UX approvato
  Impatto: `Prodotto`
- rifinire home piste eliminando ridondanze, migliorando gerarchia visiva e CTA
  Impatto: `Prodotto`
- ridurre o rimuovere sezioni placeholder dal menu e dalle schermate pubbliche prima dell'alpha
  Impatto: `Prodotto`
- completare localizzazione UI residua e allineamento IT/EN
  Impatto: `Prodotto`, `Tecnico`
- aggiungere accesso diretto con Google come alternativa al magic link email
  Impatto: `Prodotto`, `Tecnico`
- introdurre mappa comune per `Piste`, `Vicino a te`, `Spot`, `Eventi` e `Negozi` con marker tipizzati, clustering e apertura scheda al tap
  Impatto: `Prodotto`, `Tecnico`
- trasformare `Spot` da vetrina demo a flusso reale con persistenza, foto e moderazione/pubblicazione
  Impatto: `Prodotto`, `Tecnico`, `Operativo`
- ~~progettare onboarding post-registrazione in 2 step leggeri~~ ✅ fatto (2026-04-17): OnboardingScreen interattiva a 3 step (tipo account, città, riepilogo) con salvataggio via RPC complete_onboarding
  Impatto: `Prodotto`
- propagare `preferred_language` nel bootstrap profilo al primo signup, non solo dopo accesso
  Impatto: `Prodotto`, `Tecnico`
- collegare completamente `Preferiti / Segui pista` a persistenza reale e rollout schema remoto
  Impatto: `Prodotto`, `Tecnico`
- ~~evolvere `Oggi in pista` con presenza aggregata, conteggi e distinzione presenza personale/totale~~ ✅ fatto (2026-04-17): RPC `get_public_track_arrival_summary` attiva; sezione Oggi in pista mostra conteggi aggregati (coming/maybe/cancelled) e stato personale separato con orario registrazione
  Impatto: `Prodotto`, `Tecnico`
- ~~completare profilo/account con azioni vere per cambio email, reset accesso e chiusura account~~ ✅ fatto (2026-04-17): cambio email reale via Supabase updateUser, reset accesso via magic link, eliminazione account via RPC con conferma GDPR
  Impatto: `Prodotto`, `Legale`
- ~~consolidare documenti legali fino a stato pubblicabile~~ ✅ fatto (2026-04-17): Privacy, ToS e Cookie completati con contenuto GDPR-completo
  Impatto: `Legale`, `Prodotto`
- rendere usabili e testabili filtri home, foto profilo e primi caricamenti contenuto
  Impatto: `Prodotto`, `Tecnico`
- introdurre aggiornamento live o quasi-live su `arrivals` in home e dettaglio pista senza dover dipendere solo da invalidate manuale post-save
  Impatto: `Prodotto`, `Tecnico`
- completare la verifica runtime del nuovo flusso `shops` remote-first su localhost: draft, pending, approvazione admin e riapertura dati da nuova sessione
  Impatto: `Prodotto`, `Tecnico`
- standardizzare progressione upload immagini e migrare gradualmente i flussi principali verso controller condiviso
  Impatto: `Prodotto`, `Tecnico`
- completare rollout `place system` condiviso su editor piste, editor negozi ed eventi dopo i primi ingressi in onboarding e submit-place
  Impatto: `Prodotto`, `Tecnico`
- aggiungere logging errori client e criterio minimo di osservabilita' per alpha
  Impatto: `Tecnico`, `Prodotto`
- iniziare test automatici sui flussi critici: arrivals, follow/unfollow e routing guards
  Impatto: `Tecnico`, `Prodotto`
- selezionare e contattare `3-5` piste campione con relativo onboarding gestore
  Impatto: `Operativo`, `Prodotto`
- definire metrica iniziale alpha: attivazione gestori, aggiornamenti settimanali e uso dei flussi core
  Impatto: `Operativo`, `Prodotto`

### P2

- dettaglio pista: cover reale, categorie, eventi, ruolo finale del meteo
  Impatto: `Prodotto`, `Operativo`
- applicare il mini design system comune a `Negozi`, `Eventi`, `Gestione` e sezioni informative
  Impatto: `Prodotto`
- collegare davvero `Eventi` ai dati reali con lista e dettaglio coerenti
  Impatto: `Prodotto`, `Tecnico`
- allineare layout `Eventi` alla grammatica visiva moderna introdotta in `Negozi`, mantenendo gerarchia editoriale distinta
  Impatto: `Prodotto`
- introdurre `deleted_at` o strategia equivalente di soft delete per entita' principali
  Impatto: `Tecnico`, `Operativo`
- DB multilingua per contenuti pista e messaggi stato
  Impatto: `Tecnico`, `Prodotto`
- galleria reale collegata a media
  Impatto: `Prodotto`, `Operativo`
- strategia media production-ready con storage, limiti, thumbnail e moderazione
  Impatto: `Tecnico`, `Operativo`, `Prodotto`
- usare miniature low-res nelle card di garage/build per mostrare subito la presenza di piu' immagini senza caricare asset pesanti
  Impatto: `Prodotto`, `Tecnico`
- profilo pubblico e garage con regole chiare di visibilita'
  Impatto: `Prodotto`, `Tecnico`
- negozi con schede piu' ricche ma sobrie
  Impatto: `Prodotto`
- tassonomia negozi reale, inclusi tag/categorie analoghi alle piste se confermati di prodotto
  Impatto: `Prodotto`, `Tecnico`
- tabella e workflow `place_submissions` per contributi community, se confermati nel perimetro alpha+
  Impatto: `Prodotto`, `Tecnico`, `Operativo`
- SMTP custom e deliverability email
  Impatto: `Operativo`, `Legale`, `Prodotto`
- landing pubblica minima orientata SEO locale e supporto lancio
  Impatto: `Prodotto`, `Operativo`

### P3

- ricerca garage pubblici e profili pubblici
  Impatto: `Prodotto`
- badge e reputazione utenti
  Impatto: `Prodotto`
- feed/vetrina community piu' ampia
  Impatto: `Prodotto`

## Completato

- shell Flutter responsive con navigazione desktop e mobile
- menu laterale desktop richiudibile con animazione leggera
- localizzazione base app attiva
- integrazione Supabase client via `--dart-define`
- schema Supabase e seed demo disponibili
- home piste collegata a dati reali Supabase
- dettaglio pista live per `slug`
- mappa esterna apribile dalla scheda pista
- hero dettaglio pista piu' editoriale e strutturata
- sezione galleria placeholder collegata dal pulsante `Galleria`
- primo flusso UI `Sto arrivando`
- persistenza `arrivals` per la data odierna lato utente autenticato
- login screen con invio magic link
- redirect post-login verso la pista richiesta con intent di arrivo
- persistenza sessione e lingua preferita utente tra login e nuove tab
- template email PitLap iniziale aggiornato
- pagine legali pubbliche collegate dall'accesso
- raccolta consensi base in login con struttura pronta a persistenza
- primo modulo account nel profilo con logout, snapshot account e riepilogo consensi
- prima UI distinta per `Preferiti / Segui pista`
- primo contesto UX su pagine secondarie come `Vicino a te`, `Eventi`, `Gestione` e `Segnala luogo`
- prima bozza UX e documentale dell'onboarding post-registrazione
- prima area `Admin` con overview, tassonomie e monitoraggio da evolvere in pannello reale
- gating iniziale per ruoli sensibili attivo su `Admin`, `Gestione pista` e `Modifica negozio`
- `Gestione pista` agganciata alla relazione reale `track_managers` per lettura delle piste assegnate
- `Gestione pista` preparata al salvataggio reale su `track_status_current`, `track_status_history` e `track_services`
- prima sezione pubblica `Spot` introdotta come area dedicata a luoghi non convenzionali per bashing, scaler e droni
- `Vicino a te` ripulita da blocchi descrittivi demo e collegata alle piste lette dal provider pubblico
- `Crea evento` esteso con luogo operativo, immagine locale, ownership visibile dell'utente/ruolo creatore e visibilita' pubblica nella lista eventi
- introdotta prima CTA `Condividi` evento con copia link come base del futuro pannello share
- `Negozi` estesi con bozza cover e galleria immagini testabile via caricamento locale
- `Garage` esteso con caricamento immagine locale sulle build e preview piu' robusta
- aggiunta pipeline temporanea di ridimensionamento immagini locali per ridurre pressione su CanvasKit in web
- introdotti `PlaceSelection`, `PlacePickerField` e `PlaceMapPreviewCard` come base del nuovo sistema condiviso luoghi
- onboarding collegato a selezione luogo canonica con preview mappa
- `submit-place` spot collegato a ricerca luogo condivisa con coordinate e preview mappa
- introdotto `MediaUploadController` condiviso con stage di preparazione/processamento per rendere il feedback upload meno brusco
- `ImageTransferProgressCard` evoluta con stato, dettaglio e animazione di progressione
- home piste estesa con filtro citta' reale combinabile con ricerca e categoria
- `shop editor` migrato a persistenza reale su Supabase: draft e pending scrivono in `shops`
- applicata migrazione remota `shop_submitters_and_auto_manager` con auto-link del submitter a `shop_managers`
- coda approvazioni admin dei negozi letta da `shops` su Supabase invece che da bozze locali
- flusso `spots` reso piu' rigoroso: se Supabase non e' disponibile, il form segnala che non esiste salvataggio permanente
- hardening DB applicato ai flussi attivi con indici su `shops.submitted_by`, `community_events.author_id` ed `external_links(owner_id, entity_type, entity_id, sort_order)`
- corretta sezione admin eventi per leggere sia `events` sia `community_events`
- corretto overflow `Spots` su `image_accent` verso Postgres integer signed
- evitato `QuotaExceededError` web sulla cache eventi locale escludendo `data:image` dalla persistenza locale
- documentata strategia media con limiti iniziali: 10 immagini per negozi, 10 per piste, 5 per build e 5 per eventi
- applicato primo limite galleria negozio in UI: massimo 10 immagini totali e massimo 3 selezionate per volta
- documentata futura gestione link social/canali esterni per profili, piste e negozi
- aggiunta prima UI locale per link esterni/social su profilo utente e scheda negozio, con provider allowlist e URL normalizzati
- allineamento richiesto del tipo enum `app_role` su database remoto con `shop_owner` e `track_organizer`
- ownership negozio in preparazione tramite `shops` e `shop_managers`
- introdotto delta SQL incrementale per rollout `shops` e `shop_managers`
- introdotta la base schema per `shop_follows` e il relativo delta incrementale
- introdotta una prima distinzione UI tra eventi attivi e storico locale
- aggiunto accesso guest diretto a Google Maps da `Vicino a te` (vista area + apertura mappa per singola card)
- corretto contrasto pulsanti outlined nelle hero scure di `Spot` e `Mappa Spot`
- avviata rotta di editing ownership-based per scheda pista (`/manager/tracks/:slug/edit`) come base del pannello gestore reale
- consolidata la summary `arrivals` su endpoint aggregato dedicato, senza fallback lettura raw tabella
- resa esplicita in UI la separazione `dati aggregati pubblici` vs `stato personale` nel blocco `Oggi in pista`
- aggiunta pulizia automatica degli `arrivals` storici per utente durante aggiornamento presenza giornaliera
- introdotto retry con backoff leggero nel repository Supabase per letture e operazioni idempotenti (`arrivals`, `track_follows`)
- `Gestione pista` potenziata in ottica operativa con preset rapidi stato/servizi, feedback salvataggio robusto e timeline aggiornamenti da `track_status_history`
- sistemato flusso approvazioni pista lato admin per apertura submission `pending` e corretta label stato nelle card bozza gestore
- migliorata pagina `/manager/tracks/new` con checklist requisiti, progress readiness e invio approvazione guidato
- aggiunto edit spot per owner/admin riusando `submit-place`, con cover dalla prima immagine caricata
- avviato il perimetro `Gestione negozi` con card `I tuoi negozi`, editor esteso ai servizi e visibilita' immediata delle bozze
- riallineate le card piste verso il linguaggio visuale di `Spot`/`Negozi` con media panel e servizi visibili
- risolto overflow `RenderFlex` nella login screen avvolgendo il `Column` in `SingleChildScrollView`
- pannello admin completamente riscritto con CRUD reale: lista utenti completa con modifica ruolo e display name, lista piste con approva/rifiuta/editor/elimina, lista negozi con toggle visibilità pubblica, lista eventi con toggle visibilità/elimina, sezione informativa Spot & Garage (dati locali)
- `TrackDetail` model esteso con `categoryKeys: List<String>` reali da join `track_category_links → track_categories`
- `fetchPublicTrackBySlug` e `fetchManagedTrackBySlug` aggiornati con join categorie
- categorie pista mostrate nell'hero del dettaglio pista come chip colorati per categoria (`_CategoryTag`)
- badge debug `Layout V2` rimosso dalla home piste
- stato personale `Oggi in pista` con orario registrazione: già implementato e confermato (UI: `arrivalRegisteredAt`, modello: `updatedAt`)
- `user_consents` confermata presente sul DB live; salvataggio consensi e visibilità nel profilo già completamente operativi
- corrette funzioni helper RLS (`is_admin`, `is_track_manager`, `is_shop_manager`) con `SECURITY DEFINER` per eliminare ricorsione infinita nelle policy
- introdotte RPC `get_track_follower_count` e `get_shop_follower_count` con `SECURITY DEFINER` per conteggio follower corretto (senza filtro RLS user-scoped)
- applicata migrazione `get_public_track_arrival_summary` al DB live e verificata funzionante
- aggiunta colonna `image_url` alla tabella `shops` sul DB remoto
- eliminata policy RLS che esponeva `arrivals` grezzo (con `user_id`) a tutti i guest; accesso aggregato ora solo via RPC dedicata
- seeding `track_managers` per le due piste demo con i due account organizzatori
- seeding di 3 negozi demo (rc-parts-parma, miniz-shop-modena, track-store-bologna)
- `TrackListItem` esteso con `categoryKeys: List<String>` reali da join `track_category_links → track_categories`
- `fetchPublicTracks` aggiornato con join categorie e filtro `approval_status = approved`
- filtri home piste (`_matchesFilters`) migrati da string-matching su blob a `categoryKeys.contains(key)` reali
- rimossa pill "Aperto ora" hardcoded dalla card pubblica negozio (nessun dato orari disponibile)
- pagine legali Privacy, ToS e Cookie rielaborate con contenuto GDPR-completo e multi-sezione (IT+EN)
- gallery/foto pista: documentato gap infrastrutturale (tabella track_media vuota, nessun bucket Supabase Storage)
- corretto bug approvazione pista admin: updateTrackApproval ora sincronizza is_public con approval_status
- rimossa pill "Zona & dintorni" hardcoded dalla schermata Vicino a te
- ottimizzato layout home piste: soglia compact ridotta, rimossa duplicazione titolo/città nel media panel, refactoring _CardStats con servizi e follower inline
- shop editor riscritto: rimossa dark card preview + toggle Modifica/Annulla, form sempre visibile con cover preview inline e sezioni chiare
- managed track editor completato: aggiunta selezione categorie (Buggy, Mini-Z, Touring, Indoor, Outdoor) con FilterChip, campo cover image URL, ExternalLinksSection, anteprima card su sfondo graphite
- repository updateManagedTrackDetails esteso con categoryKeys: delete + reinsert su track_category_links
- chiave externalLinksTrackBody aggiunta in IT+EN (arb, astratta, implementazioni)
- migrazione DB: colonne ricche shops (subtitle, organization_name, service_labels, hours, contacts, notes, gallery_images) e profiles (preferred_city, onboarding_completed_at, deletion_requested_at); RPC complete_onboarding e request_account_deletion; RPC update_shop_rich_fields
- ShopDetailScreen riscritta come pagina pubblica professionale: cover hero, badge tipo+città, servizi con chip, orari strutturati, contatti con tap-to-call e tap-to-maps, galleria con fullscreen viewer, ExternalLinksSection
- PublicShop model esteso con tutti i campi ricchi; repository aggiornato con campo select completo
- schema.sql allineato alle nuove colonne di shops e profiles
- profilo account: cambio email reale via Supabase updateUser con dialog e conferma; reset accesso via magic link; eliminazione account GDPR con dialog di conferma a doppio step e RPC request_account_deletion
- OnboardingScreen riscritta come setup interattivo a 3 step: selezione tipo account (modellista/gestore pista/gestore negozio), città preferita, riepilogo; salvataggio via RPC complete_onboarding; progress bar animata
- vincolo cross-platform Android + Web confermato e documentato in best-practices.md e architecture.md; checklist operativa aggiunta nel checklist
- rimossa sezione gallery placeholder dal dettaglio pista (infrastruttura track_media non disponibile); rimosso pulsante galleria dall'hero
- filtro _matchesFilters home piste: rimossa logica cross-categoria hardcoded (indoor↔mini_z, outdoor↔buggy); ora ogni filtro corrisponde esattamente al categoryKey DB
- presenze aggregate Oggi in pista: confermate già operative via RPC get_public_track_arrival_summary (condizione Gate Alpha ✅)

## In corso

### Localizzazione

- completare la migrazione dei testi UI residui verso `l10n`
- rigenerare `gen-l10n` dopo ogni aggiunta di nuove chiavi
- verificare home, dettaglio pista, login e schermate placeholder in IT e EN
- verificare che il chip lingua cambi davvero tutta la UI e non solo alcune label
- usare gia' dove possibile i campi DB bilingua esistenti come `label_it` / `label_en`
- persistere `preferred_language` nel profilo utente e riapplicarla su nuove sessioni/tab

### Auth web

- verificare end-to-end il callback web con `exchangeCodeForSession`
- confermare che la sessione resti disponibile dopo il click da email
- verificare il rientro automatico sulla pista dopo login
- verificare aggiornamento reale del blocco `Oggi in pista`

### Arrivi

- verificare lettura dello stato personale odierno da `arrivals`
- mostrare in modo coerente `coming`, `maybe`, `cancelled`
- decidere se la CTA principale deve cambiare label dopo conferma
- mostrare orario ultima registrazione in `Oggi in pista`
- modello applicato lato prodotto: pubblico aggregato + stato personale autenticato, senza nominativi pubblici
- verificare allineamento policy remoto al modello applicato in UI/repository
- testare resilienza `arrivals` in condizioni di rete instabile e retry client

## Da riprendere presto

### Home piste

- rivedere la parte iniziale della pagina home
- migliorare gerarchia visiva above the fold
- rivedere ricerca e filtri, oggi ancora prototipali
- definire comportamento finale della CTA pista-specifica dopo iscrizione
- rimuovere il filtro `Vicino a te` hardcoded e sostituirlo con criterio reale o nasconderlo fino a disponibilita'
- chiarire la gerarchia tra `Vedi pista` e `Sto arrivando` nella card mobile

### Onboarding e preferenze

- progettare onboarding del primo accesso dopo registrazione/login
- capire quali dati chiedere subito, quali rimandare e quali rendere facoltativi
- valutare se l'onboarding debba essere progressivo in 2-3 step leggeri
- raccogliere gia' in login il tipo account iniziale (`modellista`, `negozio`, `organizzatore pista`) e applicarlo in modo sicuro al profilo
- progettare onboarding del primo accesso web app
- raccogliere e storicizzare preferenze utente come hobby/interessi
- valutare tassonomia iniziale hobby: buggy, droni, treni e categorie affini
- usare in futuro queste preferenze per discovery, negozi e personalizzazione dati
- decidere se le preferenze sono modificabili liberamente o con storico revisioni
- applicare subito almeno lingua preferita e profilo base al momento della creazione account
- definire i tre profili operativi del prodotto:
  modellista, negozio, organizzatore pista
- capire relazioni e sovrapposizioni tra profilo negozio e profilo organizzatore pista

### Preferiti e notifiche pista

- separare chiaramente `Sto arrivando` da `Segui pista` / `Preferiti`
- introdurre una prima UI dedicata per `Segui pista`, distinta dalla CTA di presenza giornaliera
- introdurre un legame persistente utente <-> pista per interesse stabile
- applicare sul database remoto la tabella `track_follows` e le policy relative
- sincronizzare i preferiti pista autenticati tra app e backend
- introdurre `shop_follows` come gemello di `track_follows`
- decidere se il contatore preferiti debba essere pubblico, solo autenticato o filtrato per ruolo
- usare in futuro le piste seguite per notifiche stato pista, eventi e novita'
- decidere se `Preferiti` e `Notifiche` sono un unico gesto o due controlli distinti
- creare in futuro una sezione `Preferiti` nel profilo utente per raccogliere piste, build di altri utenti, negozi e altri elementi salvati

### Dettaglio pista

- valutare ulteriori rifiniture sopra la piega
- introdurre cover immagine reale gestibile dal gestore pista
- decidere il ruolo finale del meteo nella scheda
- valutare se compattare ancora la sezione meteo
- aggiungere categorie reali della pista
- aggiungere eventi reali della pista
- permettere agli organizzatori di proporre label/tag propri per la pista
- definire flusso di moderazione centrale per approvazione label organizzatori

### DB multilingua

- progettare campi bilingua IT/EN per `tracks.name`, `tracks.short_description`, `tracks.description`
- valutare se rendere bilingua anche `track_status_current.message`
- decidere se `city`, `country` e `address` restano contenuto editoriale singolo o hanno varianti lingua
- allineare seed demo e repository alla futura struttura bilingua

### Galleria

- trasformare la sezione galleria da placeholder a sezione reale
- decidere struttura minima MVP: cover + 2/3 immagini o gallery completa
- collegare in futuro a `track_media`
- sostituire le immagini locali/data URL di test con upload su storage reale e URL persistenti
- definire pipeline immagini definitiva: upload originale, resize/thumbnail, limiti formato e moderazione media
- applicare limiti prodotto iniziali:
  negozi 10 immagini, piste 10 immagini, build garage 5 immagini, eventi 5 immagini
- creare tabella `media_assets` e collegarla a profili, garage, negozi, piste ed eventi
- usare thumbnail nelle card e preview nel dettaglio, evitando originali nelle liste
- aggiungere dashboard admin per media da moderare, rimossi o orfani
- estendere la strategia media anche agli `Spot`, con limiti immagini, preview leggere e validazione lato frontend

### Garage e profilo pubblico

- costruire garage personale come area collezione/creazioni dell'utente
- separare esplicitamente `Garage personale` da `Cerca build`, con `Cerca build` come sotto pagina del garage accessibile solo da utenti registrati
- permettere in `Cerca build` la consultazione delle build pubbliche degli altri utenti con card compatte, preview immagini e accesso al dettaglio build
- definire cosa puo' diventare pubblico del garage personale
- separare visibilita' del garage nel suo insieme e visibilita' della singola build
- collegare garage pubblico al profilo utente in ottica social leggera
- permettere in futuro la ricerca di altri garage pubblici e profili pubblici
- introdurre `Segui profilo`: un utente autenticato puo' seguire un altro profilo pubblico e ricevere notifiche quando quel profilo pubblica attivita' pubbliche rilevanti
- progettare `profile_follows` come relazione user-to-user privacy-safe: niente follow su profili privati, niente auto-follow, blocco duplicati e RLS coerente con visibilita' pubblica
- collegare `Segui profilo` a un sistema notifiche opt-in, iniziando da notifiche interne/in-app e rimandando push/email a una fase successiva
- valutare feed o vetrina profili senza trasformare subito il prodotto in social completo
- mantenere il garage vicino a una vetrina personale con foto e dettagli tecnici leggeri
- evitare tono da social rumoroso: piu' showcase che feed
- aggiungere impostazioni account nel profilo con cambio email, reset password e chiusura profilo
- definire nel profilo una privacy sobria: privato/pubblico per profilo e controllo dedicato per il garage
- prevedere nel profilo un hub unico per contenuti salvati e preferiti trasversali
- correggere la regola di visibilita' per i profili pubblici: se un profilo e' pubblico deve poter essere visto anche da guest
- permettere agli utenti di agganciare link esterni pubblici come sito, Instagram, YouTube e altri canali approvati
- portare i link esterni dal draft locale a tabella `external_links` con ownership e moderazione

## Area legale e consensi

- consolidare Privacy Policy, Terms of Service, Cookie Policy e consent register in forma pubblicabile
- trasformare i documenti legali in pagine pubbliche accessibili dall'app
- versionare termini, privacy e consensi con data efficacia e storico minimo
- salvare in futuro su database l'accettazione dei Termini di Servizio e la presa visione dell'Informativa Privacy
- salvare separatamente il consenso marketing, sempre opzionale e revocabile
- verificare il testo finale dei documenti con revisione legale prima della pubblicazione
- aggiungere nella schermata magic link link cliccabili ai documenti legali e copy piu' trasparente sui consensi raccolti

### Negozi

- mantenere le schede negozio pratiche, locali e professionali
- mostrare subito specializzazioni, contatti, orari e servizi utili
- evitare elementi promozionali invasivi nella prima versione
- progettare profilo `Negozio` con possibilita' di creare e gestire il proprio negozio
- creare un vero flusso `Crea negozio` per il gestore, distinto da `Segnala luogo`, con campi completi per card e dettaglio pubblico
- consentire al gestore negozio di modificare descrizioni, orari, contatti, cover, gallery, categorie e servizi distintivi
- valutare incrocio tra profilo negozio e profilo organizzatore pista
- spostare `Modifica negozio` dal ruolo globale `shop_owner` alla relazione reale `shop_managers`
- separare la navigazione pubblica del negozio dal relativo editor
- portare cover e galleria negozio da draft locale a persistenza reale con ownership e moderazione
- aggiungere link social/canali esterni al profilo negozio con validazione e controllo admin
- rendere i link esterni del negozio persistenti su backend e collegati a ownership reale `shop_managers`

### Eventi

- rendere utilizzabile il flusso `Crea un evento`
- permettere a utenti, negozi e organizzatori di condividere eventi aperti ad altri partecipanti
- decidere moderazione, visibilita' e ownership degli eventi creati dalla community
- portare gli eventi creati dal salvataggio locale per utente a tabella remota con ownership esplicita
- mantenere gli eventi creati pubblici di default, con eventuale revisione futura su moderazione/stato pubblicazione
- introdurre `Crea gruppo`: un utente puo' creare un gruppo di amici PitLap per restare aggiornati e ricevere inviti coordinati
- permettere all'owner di un evento di invitare uno o piu' gruppi creati/gestiti da lui, evitando inviti manuali utente-per-utente
- progettare membership gruppo con consenso esplicito degli invitati, ruoli minimi owner/member, uscita libera dal gruppo e privacy visibile ai soli membri
- collegare gruppi e inviti evento a notifiche opt-in: in-app come prima iterazione, push/email solo quando il sistema notifiche sara' maturo
- evolvere `Condividi` da copia link a pannello completo: Web Share API, copia link, QR e canali rapidi se utili al target
- rifinire `Condividi` come esperienza premium e tracciabile, non solo come CTA tecnica di copia-link
- decidere provider/UX per luogo reale: autocomplete indirizzo, mappa di supporto e fallback manuale
- gestire lo storico eventi aperti e chiusi nel tempo per:
  utente, organizzatore pista e negozio
- costruire una libreria consultabile degli eventi passati, non solo di quelli attivi
- introdurre in UI una prima distinzione tra eventi attivi e storico
- uniformare la card evento alla qualita' visiva delle card negozio, con cover, metadata piu' chiari e CTA principali/secondarie coerenti
- usare foto evento con fallback grafico intenzionale quando la cover e' assente o poco adatta

### Spot e luoghi informali

- trasformare `Spot` in una vera entita' backend con persistenza, ownership, moderazione e pubblicazione
- aggiungere coordinate geografiche, citta', tipologia (`bashing`, `scaler`, `droni`, altre future) e note pratiche
- supportare foto spot con limiti iniziali e preview compresse
- decidere flusso `submission -> review -> publish` per gli spot segnalati dagli utenti
- rendere gli spot visibili anche in una futura mappa comune insieme a piste, negozi ed eventi
- introdurre selezione `pin su mappa` per segnalare uno spot puntando direttamente il luogo da una mappa interattiva
- chiarire se gli spot sono sempre pubblici dopo approvazione o se esistono stati intermedi (`draft`, `pending`, `published`, `archived`)

### Profili speciali

- profilo `Modellista` come base utente standard
- profilo `Negozio` per creare/inserire il proprio negozio
- profilo `Organizzatore pista` per creare/inserire la propria pista
- profilo `Admin` con controllo completo su utenti, negozi, piste, immagini, eventi, garage e profili
- decidere se un singolo account puo' avere ruoli multipli attivi
- evolvere dal ruolo singolo a capability/ownership multiple per supportare account ibridi (`shop_owner` + `track_organizer`)
- modellare l'accoppiata reale `organizzazione/club/societa'` che puo' possedere insieme piste e negozi
- formalizzare una matrice ruoli/permessi con ownership esplicita tra utente, negozio, pista, garage ed eventi
- tracciare regole guest vs registrato vs negozio vs organizzatore pista vs admin
- definire cosa e' visibile, cosa e' editabile e cosa richiede ownership o moderazione
- spostare i permessi sensibili da gating UI a ownership reale con enforcement backend
- prevedere estensione futura della matrice senza rompere i permessi gia' assegnati
- permettere all'admin di aggiungere, togliere e modificare categorie label pista senza passare da query SQL
- permettere all'admin di aggiungere, togliere e modificare categorie hobby senza passare da query SQL
- progettare una dashboard admin personale con monitoraggio delle funzionalita' e delle entita' chiave
- evolvere la nuova area `Admin` in pannello collegato a dati, permessi e azioni reali
- rendere la pagina `Admin` operativa per gestione utenti, piste, negozi, ruoli, ownership e approvazioni
- definire dashboard admin con code di lavoro, contenuti pending, errori operativi, nuovi account speciali e riepilogo attivita'
- far emergere nel prodotto una "biblioteca digitale" degli attori in gioco:
  utenti, negozi, piste, eventi, garage e contenuti storici collegati

### Oggi in pista

- mostrare elenco o conteggio arrivi aggregati
- distinguere chiaramente presenza personale e presenza totale
- decidere livello di visibilita' pubblica e privacy
- mantenere `arrivals` come concetto giornaliero, separato dai preferiti persistenti
- evitare che la promessa di presenza giornaliera resti visibile con copy placeholder al lancio

### Badge e reputazione

- esplorare un sistema badge utenti non invasivo
- valutare badge per attivita', completezza garage, multi-hobby e contributi utili
- definire se i badge sono automatici, moderati o misti
- evitare gamification rumorosa nelle prime fasi MVP

## Auth e email

### Login e sessione

- verificare gli Allowed Redirect URLs Supabase per la porta web fissa di sviluppo
- fissare una porta web stabile in dev
- rifinire UX callback web dopo login
- valutare schermata breve tipo `Accesso completato`
- introdurre `Continua con Google` come login SSO alternativo al magic link
- decidere la convivenza UX tra:
  magic link email, login Google e futuro eventuale SSO aggiuntivo
- verificare mapping profilo iniziale, lingua, consensi e tipo account anche nel flusso Google
- definire gestione account duplicati se la stessa email entra prima via magic link e poi via Google

### Email template

- sostituire il template Supabase generico con template PitLap
- usare copy in italiano coerente con il prodotto
- verificare di stare modificando il template giusto del magic link

### Deliverability

- configurare SMTP personalizzato
- configurare dominio mittente dedicato
- impostare SPF
- impostare DKIM
- impostare DMARC
- verificare miglioramento spam placement dopo SMTP custom

## Pannello gestore

- sostituire il riuso del form `Segnala luogo` per le piste con un vero form `Crea pista` orientato al gestore
- includere nel form pista almeno: nome, slug, citta', descrizione breve, descrizione completa, cover, gallery, stato iniziale, servizi, label/categorie, contatti, eventuale meteo/indirizzo e note operative
- consentire gestione cover hero pista
- consentire aggiornamento stato pista
- consentire aggiornamento messaggio rapido
- consentire gestione servizi essenziali
- consentire al gestore di modificare descrizione breve/lunga, cover, gallery e label specifiche della pista
- consentire al gestore di creare e gestire eventi collegati alla propria pista
- introdurre notifiche operative per organizzatori/gestori pista: nuove iscrizioni o interesse sugli eventi, messaggi/richieste utenti, promemoria evento, modifiche richieste dall'admin e alert su dati pista incompleti
- introdurre notifiche per chi crea un evento, anche se non gestore pista: inviti accettati/rifiutati, aggiornamenti partecipanti, richieste informazioni e reminder pre-evento
- progettare un centro notifiche in-app con preferenze per ruolo (`pilota`, `gestore pista`, `creator evento`, `admin`) prima di abilitare push/email
- decidere la checklist minima di una scheda pista completa per far apparire una card pubblica credibile
- preparare gestione immagini galleria
- distinguere pannello gestore ownership-based e pannello admin globale
- completare il pannello gestore usando ownership reale per aggiornare la pista corretta, non solo mostrare la lista assegnata
- progettare pannello admin completo per utenti, negozi, piste, eventi, garage, immagini, categorie e moderazione

## Approvazioni e moderazione

- creare una sezione `Approvazioni` per gestire spot, piste e negozi in stato `pending`
- definire workflow unico `draft -> pending -> approved/rejected -> published/archived` per entita' approvabili
- distinguere chiaramente cio' che puo' essere creato dal gestore/utente da cio' che diventa pubblico solo dopo approvazione admin
- progettare commenti utenti su negozi, piste, eventi e spot, con modello unico legato a entita' tipizzate e ownership chiara
- dare senso operativo ai pulsanti `Commenti` nelle card community: apertura thread commenti, conteggio reale, stato vuoto e permessi guest/autenticato
- dare senso operativo ai pulsanti `Condividi` nelle card community: link canonico all'entita', Web Share API dove disponibile, copia link fallback e tracking privacy-safe
- definire moderazione commenti: stati `visible`, `pending`, `hidden`, `removed`, segnalazione abuso, audit admin e regole anti-spam
- decidere se i commenti di nuovi utenti vanno in moderazione preventiva o pubblicati con post-moderazione e possibilita' di segnalazione
- collegare i commenti a notifiche operative per owner/gestori/creator, rispettando preferenze utente e privacy
- prevedere notifiche interne o badge operativi quando arrivano nuove entita' da approvare
- decidere canale di notifica iniziale per l'admin: inbox interna, badge `Admin/Approvazioni`, email o combinazione minima
- mostrare in approvazione dati essenziali, media, owner, timestamp e azioni rapide `approva`, `rifiuta`, `richiedi modifiche`
- tracciare storico approvazioni con chi ha approvato/rifiutato e quando

## Alpha readiness

Condizioni minime prima di una alpha pubblica:

- almeno `3-5` piste pilota con ownership reale attiva
- almeno un gestore aggiorna lo stato pista senza passare da SQL
- `Oggi in pista` mostra dati reali aggregati
- le route pubbliche non aprono schermate di editing
- i placeholder non coprono piu' promesse core del prodotto
- esiste una metrica operativa minima per misurare attivazione e retention iniziale

## Meteo

- provider iniziale scelto: `Open-Meteo`
- decidere logica verdetto verde/giallo/rosso
- distinguere indoor vs outdoor
- usare le coordinate della pista per forecast reale
- tenere fallback locale finche' il provider non e' completamente validato

## Pulizia tecnica

- rimuovere file residui non piu' usati se presenti
- passare `flutter analyze` e `flutter test` dopo ogni blocco significativo
- valutare piccoli componenti riusabili per hero facts, weather strip e cards
- mantenere un registro aggiornato delle API e dei servizi esterni usati, con requisiti di attribuzione e note privacy
- documentare la scelta del provider mappa e dei servizi geocoding/tiles prima di portarli a runtime

## Regola operativa

Quando un punto viene chiuso:

- aggiornarlo qui
- aggiornare `README.md` se cambia lo stato del progetto
- aggiornare `VERSION.md` se il blocco rappresenta una milestone o release interna
