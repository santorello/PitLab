# Roadmap

## Principio guida

Il progetto ha fondamenta tecniche solide, ma la priorita' non e' aggiungere ampiezza funzionale.
La priorita' e' arrivare a una alpha credibile con:

- dato reale aggiornabile dai gestori
- esperienza utente senza placeholder critici
- policy e permessi coerenti con esposizione pubblica
- primo piano operativo per attivare piste e gestori reali

## Fase 0 - Fondamenta

Obiettivo: definire bene prodotto, stack e dati prima dell'implementazione.

Output:

- documentazione iniziale
- scope MVP confermato
- stack tecnico confermato
- modello dati iniziale

## Fase 1 - Bootstrap tecnico

Obiettivo: creare la base del progetto Flutter e del backend.

Output:

- progetto Flutter configurato per Android e Web
- ambienti dev configurati
- backend iniziale configurato
- autenticazione base
- localizzazione iniziale italiano/inglese impostata
- struttura cartelle e naming condivisi

Stato corrente:

- quasi completata
- restano da chiudere auth reale, rifinitura dipendenze runtime, login Google SSO e consolidamento flusso dev

## Fase 2 - Core MVP pilota

Obiettivo: rendere disponibile il flusso principale lato pilota.

Output:

- elenco piste
- dettaglio pista
- stato pista
- servizi pista
- funzione "Sto arrivando"
- vista presenza utenti

Stato corrente:

- avviata
- `elenco piste`, `dettaglio pista`, `stato pista` e `servizi pista` sono gia' leggibili lato utente su dati demo
- `Sto arrivando` ha un primo flusso persistente per l'utente autenticato
- resta da implementare la vista presenza utenti aggregata
- restano da rimuovere placeholder utente ancora visibili e filtri prototipali non pronti per il lancio

## Fase 3 - Core MVP gestore

Obiettivo: dare ai gestori un pannello semplice ma utile.

Output:

- login gestore
- modifica stato pista
- aggiornamento servizi e note essenziali
- gestione base eventi

Stato corrente:

- impostazione UI presente e collegamento iniziale alle piste assegnate disponibile
- introdotta base operativa per editing scheda pista ownership-based con rotta dedicata gestore
- introdotto step operativo giornaliero V2 con preset rapidi, stato save esplicito e timeline aggiornamenti recenti
- fase da anticipare rispetto ad altre espansioni: senza un pannello gestore realmente operativo il prodotto rischia di apparire statico

## Fase 3.5 - Hardening pre-alpha

Obiettivo: chiudere i gap che rendono fragile o incoerente una prima apertura pubblica.

Output:

- vista presenze aggregate reale in pista
- revisione privacy e policy `arrivals`
- profilo pubblico accessibile anche ai guest quando marcato pubblico
- separazione tra schermate pubbliche e schermate editoriali per negozi
- rimozione filtri hardcoded e fallback demo ancora esposti
- onboarding post-login minimo ma reale
- primi test sui flussi critici e logging errori client

Stato corrente:

- avviata: summary presenze aggregata consolidata in UI/repository con separazione esplicita tra dato pubblico e stato personale
- avviato hardening affidabilita' lato client Supabase con retry/backoff mirato su operazioni idempotenti

## Fase 4 - Ecosistema vicino

Obiettivo: allargare il valore pratico del prodotto oltre la sola pista.

Output:

- elenco negozi
- discovery "vicino a te" per piste e negozi
- base dati geolocalizzata pronta per vista mappa
- meteo sintetico contestuale per piste outdoor
- prima mappa comune con marker per piste, negozi, eventi e spot

Nota:

- questa fase non deve superare in priorita' il completamento del valore core `pista + gestore + presenze`

## Fase 5 - Identita' pilota

Obiettivo: aumentare identita', retention e valore personale dell'app.

Output:

- profilo utente migliorato
- garage personale modelli
- foto modelli
- profilo pubblico opzionale

## Fase 6 - Contributi community controllati

Obiettivo: aumentare copertura e scoperta luoghi senza perdere qualita' del catalogo.

Output:

- form segnalazione luogo o pista
- supporto per spot non ufficiali e bashing
- workflow di revisione
- approvazione o rifiuto segnalazioni
- foto e coordinate reali per spot ed entita' community

## Fase 6.5 - Ownership e gestione ibride

Obiettivo: permettere a uno stesso account di gestire in modo pulito piste, negozi ed entita' collegate.

Output:

- modello capability-based oltre il ruolo singolo
- ownership multiple per `track_managers` e `shop_managers`
- pannello `Gestione` evoluto in hub unico per piste e negozi assegnati
- permessi backend coerenti con ownership reale

## Fase 7 - Webapp pubblica

Obiettivo: rendere il progetto accessibile e consultabile dal web.

Output:

- build web stabile
- deploy pubblico
- pagine consultabili da desktop e mobile
- SEO base e metadati essenziali
- URL pubbliche curate per piste, negozi, eventi e profili pubblici dove previsto

## Fase 8 - Test sul campo

Obiettivo: validare utilizzo reale con pochi utenti selezionati.

Output:

- prime piste popolate
- primi gestori coinvolti
- raccolta feedback
- correzione attriti principali

Nota operativa:

- questa fase va iniziata in parallelo alla chiusura della Fase 3 e non solo dopo
- target iniziale consigliato: almeno `3-5` piste campione con gestori realmente attivi

## Fase 9 - Preparazione rilascio

Obiettivo: stabilizzare il prodotto e preparare la pubblicazione.

Output:

- privacy policy e contenuti store
- asset grafici essenziali
- test principali
- rilascio Android
- landing pubblica minima e kit onboarding per i primi gestori

## Gate Alpha

Prima di considerare PitLap pronto per una alpha pubblica devono essere veri questi punti:

- almeno un flusso gestore reale permette di aggiornare stato pista e servizi
- la vista presenze aggregate e' reale, non placeholder
- le policy `arrivals` non espongono dati personali oltre il livello deciso
- i percorsi pubblici (`track`, `shop`, eventuale `public profile`) sono separati dagli editor
- i filtri home non contengono logiche hardcoded territoriali
- l'onboarding minimo post-login e' presente
- esistono `3-5` piste pilota con dato e ownership reale ✅ (5 piste: Parma, Modena, Lainate, Reggio Emilia, Mantova — aprile 2026)
- e' definita una metrica iniziale di successo del lancio ✅ (vedi sotto)

## Metrica di successo alpha

**Metrica primaria (segnale di utilizzo reale):**
Almeno 3 check-in "Sto arrivando" da utenti distinti sulla stessa pista nello stesso weekend, entro le prime 2 settimane dal lancio pilota.

Questo indica che:
- gli utenti aprono l'app in pista, non solo a casa
- il dato presenze ha valore sociale percepito
- il gestore ha un motivo concreto per aggiornare lo stato

**Metriche secondarie (segnali di salute del prodotto):**
- almeno 2 gestori aggiornano lo stato pista in modo autonomo (senza supporto) entro 2 settimane
- almeno 5 utenti registrati non-admin con almeno 1 check-in nel primo mese
- tasso di ritorno: almeno il 50% degli utenti che fa check-in la prima settimana torna la settimana successiva

**Soglia di fallimento:**
Se dopo 4 settimane nessuna pista ha piu' di 1 check-in in un singolo giorno, il prodotto non sta generando valore operativo e serve una revisione del flusso principale.

## Backlog post-MVP

- notifiche push piu' ricche
- digital setup
- QR code e check-in evoluto
- mappe e POI
- tempi gara e integrazioni esterne
- profili club avanzati
- gamification soft con streak, challenge territoriali e quest opt-in
- monetizzazione e analytics premium per gestori

## Sistema PitCoin & Badge — implementato in v0.2.0 (2026-05-23)

Originariamente annotata 2026-05-09 come "idea futura". Implementata come prima iterazione in v0.2.0.

**Documento canonico:** [`docs/pitcoin-system.md`](pitcoin-system.md)

**Cosa è entrato nella v1:**

- ledger Postgres-first `pitcoin_transactions` (append-only, idempotente)
- catalogo azioni admin-configurabile con ~25 azioni dispositive che generano PitCoin (creazione contenuti, pubblicazione build, check-in, follow, update gestore, eventi, profilo, ecc.)
- catalogo badge con ~25 milestone organizzate in 6 famiglie (identità, contributo catalogo, gestione, engagement, eventi, milestone storiche) con tier bronze/silver/gold/special
- anti-spam: daily_cap, per_entity_cap, lifetime_cap, cooldown_seconds, admin esclusi dall'accumulo
- pattern submission/approval a due fasi (placeholder 0 punti su submission, payout reale su approvazione admin)
- backfill retroattivo di tutte le azioni già compiute durante la pre-alpha 0.1.x
- visibilità: balance pubblico sul profilo opt-in, storico transazioni privato all'owner+admin
- nessuna modifica al codice Flutter esistente: tutto via trigger DB; UI Flutter additive (card balance, schermata storico, vetrina badge)

**Restano backlog per iterazioni successive (rivedere dopo Gate Alpha + 3 mesi di dato reale):**

- premi materiali (sconti negozi partner) — richiede accordi commerciali
- leaderboard pubblica territoriale ("Pista del mese", "Top piloti regionali")
- scadenza punti per evitare hoarding
- gating differenziato per ruolo (shop_owner con metriche separate)
- streak settimanali e quest opt-in più strutturate
- moderazione: `moderation_report_helpful` da abilitare quando partirà il sistema hide-pending AI
