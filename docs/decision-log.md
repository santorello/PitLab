# Decision Log

Documento operativo per chiudere le principali decisioni aperte di PitLap.

Obiettivo:

- ridurre l'ambiguita' prima del bootstrap tecnico
- evitare ripensamenti costosi nelle prime fasi
- fissare una direzione coerente tra prodotto, architettura e UX

## Stato del documento

Data di consolidamento iniziale: `2026-04-02`

Stato:

- decisioni raccomandate e adottate come baseline di lavoro
- punti futuri esplicitamente segnati come da rivalutare

Aggiornamento operativo piu' recente: `2026-05-17`

## Principi guida

- partire con un MVP pubblico, chiaro e leggero
- abbassare l'attrito per chi consulta
- mantenere il backend e il modello dati scalabili
- privilegiare flussi utili in pista rispetto a feature "wow" premature
- costruire un prodotto con tono tecnico, affidabile e professionale

## Decisioni chiuse

### 1. Nome progetto

Decisione:

- il nome di riferimento del progetto e' `PitLap`

Motivazione:

- e' gia' il nome principale della documentazione attiva
- e' piu' ampio e scalabile del vecchio working title `PitLane Hub`
- funziona bene sia per app sia per piattaforma

Impatto:

- tutti i nuovi documenti e asset devono riferirsi a `PitLap`

### 2. Accesso e login

Decisione:

- la consultazione pubblica delle piste deve essere disponibile senza login
- il login e' richiesto per `Sto arrivando`, registrazioni, preferenze e area gestore

Motivazione:

- riduce l'attrito del primo utilizzo
- migliora la diffusione della webapp pubblica
- preserva le azioni personali o sensibili dietro autenticazione

Impatto:

- il prodotto deve avere un'esperienza guest completa per le informazioni pubbliche

### 2b. Discovery pubblica e dettagli sensibili

Decisione:

- non togliere contenuti pubblici di discovery a guest
- restringere invece campi sensibili, metadati interni e azioni dispositive

Motivazione:

- PitLap deve funzionare come hub pubblico di scoperta e condivisione per il modellismo
- un utente non registrato deve capire rapidamente piste, negozi, eventi, spot e community vicine
- il rischio corretto da mitigare non e' la visibilita' del contenuto, ma l'esposizione inutile di ownership, review o superfici di scrittura

Impatto:

- preferire view pubbliche esplicite o select minimali per i client guest
- evitare di esporre identificativi come `owner_id` quando basta un segnale derivato lato UI

### 3. Backend principale

Decisione:

- `Supabase` e' il backend iniziale confermato

Motivazione:

- offre auth, PostgreSQL, storage e realtime in un'unica base semplice
- accelera il bootstrap per un progetto gestito da una persona
- lascia spazio a crescita futura senza migrazioni precoci

Impatto:

- il modello dati va pensato in modo relazionale fin dall'inizio
- le policy di accesso devono essere previste da subito

### 4. Hosting web

Decisione:

- la webapp Flutter verra' pubblicata inizialmente su hosting statico
- candidato operativo iniziale: `Firebase Hosting`

Motivazione:

- deployment lineare per output statici
- adatto a una prima pubblicazione semplice e robusta
- separa bene hosting frontend e backend

Da rivalutare:

- eventuale passaggio o affiancamento a `Vercel` in caso di preview environments o sito marketing separato

### 5. Strategia realtime

Decisione:

- usare realtime solo dove genera valore immediato

Schermate iniziali da trattare in realtime:

- stato pista
- presenze / `Sto arrivando`
- aggiornamenti rapidi eventi, se necessari

Schermate da lasciare inizialmente a fetch standard:

- elenco piste
- dettaglio servizi
- contenuti statici o semi-statici

Motivazione:

- riduce complessita' e consumo inutile
- mantiene percezione di rapidita' nei punti giusti

### 6. Semantica di "Sto arrivando"

Decisione:

- `Sto arrivando` rappresenta una presenza riferita a una data o finestra temporale precisa
- la presenza deve decadere automaticamente, non restare indefinita

Proposta operativa MVP:

- validita' sulla giornata selezionata
- stati iniziali: `coming`, `maybe`, `cancelled`

Motivazione:

- evita rumore e false presenze
- mantiene il dato leggibile e utile

### 7. Eventi nell'MVP

Decisione:

- per l'MVP gli eventi devono essere semplici

Incluso:

- visualizzazione eventi
- dettaglio base evento
- RSVP o registrazione leggera

Escluso dall'MVP:

- workflow gara complessi
- pagamenti
- liste tecniche avanzate
- gestione campionati articolati

Motivazione:

- tiene corto il perimetro
- copre il bisogno reale senza sovrastrutturare

### 8. Categorie e tassonomia piste

Decisione:

- una pista puo' appartenere a piu' categorie tramite tag multipli

Motivazione:

- evita rigidita' del dominio
- scala meglio verso discipline e usi diversi

Impatto:

- le categorie non vanno modellate come singolo valore obbligatorio

### 9. Stato pista e storico

Decisione:

- il sistema deve mostrare uno stato corrente semplice
- il modello dati deve poter estendere facilmente lo storico aggiornamenti

Motivazione:

- l'MVP non ha bisogno di cronologia complessa
- la piattaforma futura potrebbe beneficiare di audit e timeline

Impatto:

- progettare `TrackStatus` in modo da non bloccare una futura tabella storica

### 10. Mappe

Decisione:

- niente mappe avanzate nell'MVP

Incluso:

- indirizzo
- citta'
- link esterno
- eventuali coordinate

Rimandato:

- mappe embedded
- POI
- percorsi e layer geospaziali

Motivazione:

- evita costi, complessita' e dipendenze premature

Stato operativo attuale:

- nella scheda pista e' attivo il link esterno mappa
- restano rimandate mappe embedded e discovery cartografica avanzata

Aggiornamento 2026-04-21:

- il perimetro si e' evoluto oltre la decisione iniziale MVP
- PitLap adotta ora un `place system` condiviso con provider astratto e implementazione attiva `MapTiler` per la fase non commerciale
- preview mappa e selezione luogo canonica sono ora considerate ammesse quando servono a confermare un luogo o preparare discovery futura

### 11. Strategia lingua

Decisione:

- lingua iniziale rilevata da browser o device
- switch lingua sempre disponibile
- preferenza salvata per utenti autenticati

Motivazione:

- migliora onboarding
- mantiene controllo esplicito lato utente

### 12. Ruoli e permessi

Decisione:

- ruoli iniziali: `visitor`, `user`, `manager`, `admin`

> Aggiornamento 2026-05-10: il ruolo `manager` generico e' stato sostituito da due ruoli specifici (`shop_owner` per i negozi, `track_organizer` per le piste) e dall'ownership reale gestita via tabelle `shop_managers` e `track_managers`. Il modello attuale in `supabase/schema.sql` espone i ruoli `user`, `shop_owner`, `track_organizer`, `admin`. `visitor` non e' un ruolo persistito ma uno stato di sessione non autenticata.

Motivazione:

- chiarisce i livelli di accesso
- consente estensione futura senza ribaltare il modello

Impatto:

- prevedere piu' manager per pista
- tracciare chi aggiorna stato e contenuti

## Decisioni di design prodotto

### 13. Posizionamento

Decisione:

- PitLap non deve sembrare un social generico
- PitLap deve sembrare uno strumento operativo premium per appassionati esigenti

Motivazione:

- il pubblico cerca precisione, affidabilita' e ordine
- la credibilita' del prodotto dipende anche dal tono visivo

### 14. Tono UX

Decisione:

- interfaccia asciutta, chiara, veloce
- microcopy diretto e tecnico

Esempi desiderati:

- `Pista aperta`
- `Bagnata`
- `3 arrivi oggi`
- `Servizi confermati`

Da evitare:

- tono troppo giocoso
- estetica social
- testi lunghi e dispersivi

### 15. Priorita' della home

Decisione:

- la home e la scheda pista devono rispondere in pochi secondi a quattro domande:

1. dove si va
2. com'e' la pista
3. quali servizi ci sono
4. chi c'e' o chi arriva

Motivazione:

- allinea la UI al bisogno reale in mobilita'

### 16. Estensione del dominio prodotto

Decisione:

- PitLap non riguarda solo le piste
- il dominio di prodotto deve includere progressivamente anche `shops` e identita' pilota

Ambiti previsti:

- piste
- negozi
- profilo pilota
- garage modelli
- profilo pubblico opzionale

Motivazione:

- rende il prodotto piu' utile e piu' "ecosistema"
- aumenta valore pratico anche fuori dalla singola giornata in pista
- apre a discovery locale e contenuti personali senza perdere il focus

Regola:

- l'espansione va fatta per cerchi concentrici, senza snaturare l'MVP operativo

### 17. Mappa

Decisione:

- la mappa serve, ma non deve essere il punto di ingresso principale dell'MVP

Approccio raccomandato:

- fase iniziale: coordinate, localita', link esterno mappa e base dati geospaziale pronta
- fase successiva vicina: vista `Trova vicino a te` per piste e negozi
- la lista resta comunque primaria per rapidita' e leggibilita'

Motivazione:

- la mappa diventa utile quando il prodotto include anche negozi e discovery territoriale
- su mobile la lista resta spesso piu' veloce della mappa per scegliere rapidamente

### 18. Meteo

Decisione:

- il meteo indicativo dei prossimi 5 giorni e' utile, ma come layer contestuale e non come feature dominante

Approccio raccomandato:

- meteo sintetico nella scheda pista, soprattutto per piste outdoor
- nessuna dipendenza critica dal meteo nella home principale
- caching lato backend o fetch controllato per evitare chiamate inutili

Motivazione:

- aiuta davvero la decisione "dove vado nei prossimi giorni?"
- evita di trasformare PitLap in una weather app

### 19. Profili pubblici e garage

Decisione:

- ogni utente autenticato deve poter avere un profilo personale
- il `garage` dei modelli e il profilo pubblico devono essere opzionali

Incluso nella direzione prodotto:

- garage con elenco modelli
- immagini del modello
- profilo pilota pubblico facoltativo
- gallery personale pubblica opzionale

Motivazione:

- aumenta identita', retention e valore personale dell'app
- crea motivi per registrarsi oltre alla sola funzione pista

Regola:

- il profilo pubblico deve essere sempre opt-in
- la privacy viene prima della visibilita'

### 20. Segnalazione luoghi da parte degli utenti

Decisione:

- gli utenti potranno segnalare nuovi luoghi, piste o spot
- la segnalazione non pubblica automaticamente il contenuto nel catalogo

Tipologie iniziali da prevedere:

- circuito
- spot bashing
- area crawler o scaler
- luogo generico compatibile con modellismo
- negozio

Motivazione:

- aumenta copertura territoriale senza dipendere solo dagli owner
- rende il prodotto piu' vivo e partecipativo
- permette di scoprire luoghi reali non ancora censiti

Regola:

- tutte le segnalazioni utente devono passare da revisione o approvazione
- il contributo utente non deve compromettere qualita' e affidabilita' del catalogo

### 21. Persistenza reale prima dei fallback locali

Decisione:

- i flussi che l'utente percepisce come "salvati" devono scrivere prima su Supabase
- il fallback locale puo' esistere solo come rete di sicurezza esplicita, non come successo silenzioso

Applicazione concreta:

- `shops` passa a persistenza reale su `public.shops`
- il submitter viene auto-collegato a `shop_managers` al primo insert
- `spots` non devono piu' sembrare permanenti quando il write remoto fallisce

Motivazione:

- i test di consistenza e permanenza devono riflettere il database reale
- la UX non deve mascherare errori di scrittura lato backend

### 22. Design system foundation (P0/P1/P2 consolidati)

Data: `2026-05-06`

Trigger:

- percezione ricorrente di "schermate sconnesse" – il layout e i token funzionavano ma non erano la fonte di verità
- confronto con YouTube: coerenza visiva come prerequisito per professionismo percepito
- blocco progress: ogni nuova schermata reinventava card e spacing, divergenza visiva accelerava

Audit partenza:

- 163 colori hardcoded sparsi (vs 11 token AppColors nominati)
- 7 card indipendenti per entita' simili (track/spot/shop/event/build/nearby/community) con 5 radius diversi
- 299 `EdgeInsets` ad-hoc, nessuna scala formalizzata di spacing
- 39 `TextStyle(...)` inline in 15 file, fuori dal `TextTheme`
- 13 valori di border radius distinti in uso vs 4 nel theme

Decisione:

Introdurre design system foundation consolidato come pre-requisito per Alpha pubblica:

- **P0 Foundation**: estendere `AppColors` con token di fatto (orange family 6 toni, surface scale 5 varianti, border semantici), creare `AppSpacing` (xs=4, sm=8, md=12, lg=16, xl=24, xxl=32), introdurre `AppRadius` (sm=8, md=12, lg=16, xl=24, pill=999), formalizzare `AppBreakpoints` (cardStack=720, navRail=1100, contentMaxWidth=1200)
- **P1 Card System**: creare `PlaceCard` (Stateless) come card base unificata con varianti (standard/compact) e layout responsive uniforme (Column <720, Row >=720)
- **P2 Page Templates**: estrarre `ContentScaffoldHeader` come widget autonomo, tokenizzare i colori hardcoded dentro, garantire il passaggio di tutte le pagine principali per `ContentScaffold`
- **P3 Documentation**: creare `docs/design-system.md` come documento di riferimento canonico, aggiornare `decision-log.md`

Scope esecutivo:

- 5 card refactorate completamente su `PlaceCard`: `_TrackCardV3`, `_SpotCard`, `_ShopCard`, `_EventCard`, `_NearbyPreviewCard`
- 2 card allineate visivamente senza migrazione concettuale: `_BuildCard` (garage) e `_BaseFeedCard` (community) – rimangono widget privati ma rispettano token
- 3 supporting widget creati/stabilizzati: `Pill` (toni semantici), `StatusBadge` (states pista), `MetaRow` (metadata)

Trade-off:

- **Non fatto**: Widgetbook/catalog esterno – rimandato a future work per ridurre scope (interna app o standalone dopo P0/P1/P2)
- **Scala radius deliberatamente ristretta**: 5 valori (sm/md/lg/xl/pill) invece di 7-8, forza coerenza e mappa i 13 usati in codice ai soli 5 semantici
- **Breakpoint card a 720px**: compromesso tra densita' mobile (non 600 per leggibilita') e densita' tablet (non 800 per efficienza layout)
- **Non tokenizzati**: shadow/elevation (M3 di default fornisce gia'), motion (esulano P0)

Impatto:

- percezione "app coerente" risolta strutturalmente – niente piu' 7 card indipendenti
- onboarding feature nuovo dimezzato: card base gia' pronta, slot standardizzati
- ridotto technical debt: ogni nuova schermata inizia da PlaceCard, non reinventa
- coerenza futura: design system become source of truth per ogni PR da qui in avanti

Riferimento:

- Implementazione: `app/lib/app/theme/`, `app/lib/shared/widgets/`, `app/lib/core/widgets/content_scaffold_header.dart`
- Documentazione: `docs/design-system.md` (canonical), `docs/design-system-audit.md` (historical reference)

### 23. Hardening superfici pubbliche spot e feed

Data: `2026-05-19`

Decisione:

- mantenere ampia la discovery guest, senza rimuovere spot o feed pubblici
- usare `public.public_spots` come contratto pubblico degli spot
- calcolare `is_owned_by_current_user` tramite helper nello schema non esposto `private`
- rimuovere `owner_id` dalla lettura diretta `anon`/`authenticated` su `public.spots`
- mantenere insert autenticato di `owner_id` per gli spot custom, protetto da RLS
- normalizzare `public.activity_feed` a `security_invoker = true`, grants solo `SELECT`, e ramo spot basato su `public.public_spots`
- rimuovere privilegi DML da `anon` sulle tabelle `public`
- rimuovere privilegi tecnici `TRIGGER`, `TRUNCATE`, `REFERENCES` da `authenticated`

Motivazione:

- il contratto pubblico deve essere una protezione effettiva, non solo una convenzione frontend
- `owner_id` consente correlazioni di ownership non necessarie alla discovery guest
- le funzioni privilegiate non pensate come RPC pubbliche devono stare fuori dagli schema API quando possibile

Verifica:

- in ruolo `anon`, `public.spots.owner_id` non e' selezionabile
- `public.public_spots` resta visibile e continua a esporre 11 spot
- `public.activity_feed` mantiene i contenuti pubblici esistenti
- `anon` non ha piu' grant tabellari DML nello schema `public`

## Punti ancora aperti ma ridotti

Questi temi restano aperti, ma non bloccano il bootstrap:

- scelta finale del provider hosting dopo prime prove reali di deploy
- livello preciso di RSVP eventi nel primo rilascio tecnico
- naming e tassonomia definitiva delle categorie iniziali
- evoluzione futura verso push notifications e mappe
- livello di visibilita' pubblica dei profili pilota e delle presenze
- livello di moderazione richiesto per segnalazioni utente di luoghi e negozi

## Regola di revisione

Questo documento va aggiornato quando:

- una decisione viene ribaltata
- emerge un vincolo tecnico nuovo
- una scelta di MVP viene promossa a standard stabile
