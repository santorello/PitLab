# PitLap

Piattaforma digitale per il modellismo dinamico e statico, con focus iniziale su app Android e webapp pubblica.

## Visione

PitLap nasce per ridurre il disordine informativo oggi distribuito tra WhatsApp, Facebook e comunicazioni sparse, offrendo un punto unico dove piloti, club e gestori possano vedere cosa succede in pista e organizzarsi meglio.

La promessa di valore iniziale e' semplice:

- per i piloti: capire rapidamente dove andare, cosa trovare in pista e chi ci sara'
- per i gestori: aggiornare lo stato del circuito e gestire le informazioni essenziali in modo rapido

## Obiettivo iniziale

Realizzare un primo MVP con:

- app Android sviluppata in Flutter
- webapp pubblica accessibile da browser
- backend serverless per autenticazione, dati e aggiornamenti in tempo reale
- interfaccia disponibile in italiano e inglese

## Stato del progetto

Progetto in pre-alpha con bootstrap tecnico attivo.

Al momento sono gia' operativi:

- documentazione prodotto e tecnica consolidata
- app Flutter con shell responsive Android/Web
- localizzazione base italiano/inglese
- integrazione Supabase client
- home piste collegata a dati reali Supabase
- dettaglio pista live per `slug`
- login email magic link con pagine legali collegate e raccolta consensi base
- persistenza sessione utente e lingua preferita nel flusso web
- primo flusso `Sto arrivando` persistito su Supabase per utenti autenticati
- sezione `Oggi in pista` collegata allo stato personale del giorno con summary pubblica aggregata
- primo modulo account nel profilo con snapshot, logout e consensi
- prime basi UI per `Preferiti / Segui pista`
- persistenza ibrida iniziale per preferiti pista autenticati e persistenza locale per eventi creati e profili negozio in test
- base schema per `shop_follows`, con contatori preferiti e primo storico eventi in evoluzione
- prima integrazione meteo reale con provider esterno e fallback locale
- prima area `Admin` con overview, tassonomie e monitoraggio
- prime pagine secondarie contestualizzate (`Vicino a te`, `Eventi`, `Gestione`, `Segnala luogo`)
- accesso guest migliorato con CTA mappa Google diretta in `Vicino a te` e `Spot`
- hardening affidabilita' Supabase nel repository piste con retry/backoff su letture e operazioni idempotenti
- `Gestione pista` evoluta con preset operativi rapidi, stato salvataggio esplicito e timeline ultimi aggiornamenti
- fix approvazioni admin su piste `pending` e upgrade UX professionale di `/manager/tracks/new` con checklist readiness
- edit spot per owner/admin con prima immagine usata come cover e prime aree `I tuoi negozi` tra `/shops` e `Gestione`
- avvio `place system` condiviso con ricerca luogo canonica, autocomplete e preview mappa
- primo `media upload system` condiviso con progress card animata e stage riusabili tra profilo, piste, negozi, eventi e submit-place
- allineamento admin eventi tra `events` e `community_events`
- home piste estesa con filtro citta' reale, combinabile con ricerca e categoria
- `shop editor` portato su persistenza reale `shops` con policy Supabase dedicate per submitter e auto-link `shop_managers`
- coda approvazioni admin negozi letta dal database, non piu' da bozze locali
- `spots` irrigiditi: nessun falso positivo di salvataggio permanente quando Supabase non risponde
- hardening DB mirato sui flussi attivi (`shops.submitted_by`, `community_events.author_id`, `external_links(owner_id, entity_type, entity_id, sort_order)`)
- schema e seed demo Supabase applicabili in ambiente dev

## Stack proposto

- Frontend: Flutter
- Target: Android + Web
- Backend: Supabase
- Hosting web: da confermare, preferenza attuale verso Supabase + hosting statico
- Mappe e geocoding: `MapTiler` in fase dev/pre-alpha non commerciale tramite layer astratto interno
- Push notifications: previste per Android in una fase successiva all'MVP base
- Localizzazione: italiano e inglese, selezionabili da app e webapp

## Config locale

Per le feature mappe / place search lato client serve una API key `MapTiler`.

Variabile supportata:

- `MAPTILER_API_KEY`

Esempio run Flutter:

```powershell
flutter run -d chrome --dart-define=MAPTILER_API_KEY=la_tua_chiave
```

Nota:

- in questa fase la scelta e' coerente con uso locale / pre-alpha non commerciale
- l'architettura e' stata impostata per poter sostituire il provider in futuro senza rifare le schermate

## Stato implementazione

Codice attivo in:

- [App Flutter](Z:\ProgettiSviluppo\PitLap\app)
- [Schema Supabase](Z:\ProgettiSviluppo\PitLap\supabase\schema.sql)
- [Seed demo Supabase](Z:\ProgettiSviluppo\PitLap\supabase\seed_demo.sql)
- [Delta Supabase shop ownership](Z:\ProgettiSviluppo\PitLap\supabase\deltas\2026-04-09-shop-ownership.sql)
- [Delta Supabase shop follows](Z:\ProgettiSviluppo\PitLap\supabase\deltas\2026-04-10-shop-follows.sql)
- [Delta Supabase shop submitters + auto manager](Z:\ProgettiSviluppo\PitLap\supabase\deltas\2026-04-22-shop-submitters-and-auto-manager.sql)
- [Delta Supabase active flow hardening](Z:\ProgettiSviluppo\PitLap\supabase\deltas\2026-04-22-active-flow-hardening.sql)

## Documentazione

- [Indice struttura](Z:\ProgettiSviluppo\PitLap\PROJECT_STRUCTURE.md)
- [Versioni](Z:\ProgettiSviluppo\PitLap\VERSION.md)
- [MVP](Z:\ProgettiSviluppo\PitLap\docs\mvp.md)
- [Roadmap](Z:\ProgettiSviluppo\PitLap\docs\roadmap.md)
- [Architettura](Z:\ProgettiSviluppo\PitLap\docs\architecture.md)
- [Modello dati](Z:\ProgettiSviluppo\PitLap\docs\data-model.md)
- [Contenuti di lancio](Z:\ProgettiSviluppo\PitLap\docs\content-launch.md)
- [Decision log](Z:\ProgettiSviluppo\PitLap\docs\decision-log.md)
- [Checklist sviluppo](Z:\ProgettiSviluppo\PitLap\docs\development-checklist.md)
- [Direzione UI](Z:\ProgettiSviluppo\PitLap\docs\ui-direction.md)
- [Baseline backend](Z:\ProgettiSviluppo\PitLap\docs\backend-baseline.md)
- [Blueprint app](Z:\ProgettiSviluppo\PitLap\docs\app-blueprint.md)
- [Design brief](Z:\ProgettiSviluppo\PitLap\docs\design-brief.md)
- [Best practices](Z:\ProgettiSviluppo\PitLap\docs\best-practices.md)
- [Onboarding first access](Z:\ProgettiSviluppo\PitLap\docs\onboarding-first-access.md)
- [Registro API](Z:\ProgettiSviluppo\PitLap\docs\api-registry.md)
- [Permissions matrix](Z:\ProgettiSviluppo\PitLap\docs\permissions-matrix.md)
- [Test checklist](Z:\ProgettiSviluppo\PitLap\docs\test-checklist.md)
- [Mockup UI](Z:\ProgettiSviluppo\PitLap\docs\mockup-pitlap.svg)
- [Setup Supabase dev](Z:\ProgettiSviluppo\PitLap\docs\supabase-dev-setup.md)
- [Privacy policy](Z:\ProgettiSviluppo\PitLap\docs\legal\privacy-policy.md)
- [Terms of service](Z:\ProgettiSviluppo\PitLap\docs\legal\terms-of-service.md)
- [Cookie policy](Z:\ProgettiSviluppo\PitLap\docs\legal\cookie-policy.md)
- [Registro consensi](Z:\ProgettiSviluppo\PitLap\docs\legal\consent-register.md)
- [Schema Supabase](Z:\ProgettiSviluppo\PitLap\supabase\schema.sql)
- [Seed demo Supabase](Z:\ProgettiSviluppo\PitLap\supabase\seed_demo.sql)

## Principi guida

- utilita' prima della complessita'
- MVP stretto, dati reali e flusso testabile
- una sola base codice dove possibile
- ogni funzionalita' deve essere utile gia' dal primo utilizzo

## Ipotesi attuali

- il progetto viene portato avanti da una sola persona con supporto operativo di Codex
- il primo target reale sono utenti Android e utenti web da browser mobile/desktop
- il rollout iniziale sara' locale e progressivo, partendo da poche piste selezionate

## Prossimi passi

- rifinire home e dettaglio pista eliminando ridondanze e migliorando gerarchia visiva
- completare onboarding post-registrazione e raccolta preferenze utente
- consolidare `Sto arrivando` in presenza aggregata affidabile tra home e dettaglio, con test regressivi
- completare il rollout remoto di `Preferiti` e relativo schema Supabase
- consolidare documenti legali e consensi fino a livello pubblicabile
- formalizzare ruoli, ownership e futuro pannello admin
- consolidare il rollout del `place system` su piste, negozi ed eventi
- collegare il `media upload system` a Supabase Storage per ottenere progresso reale di rete
- stabilizzare il meteo reale e l'attribuzione dei provider esterni

## Gestione documentale

Per mantenere il contesto sempre leggibile:

- `PROJECT_STRUCTURE.md` contiene l'indice dei documenti e il loro scopo
- `VERSION.md` contiene versione corrente, stato e storico release
- `backup/` e' riservata a snapshot di progetto in momenti chiave
