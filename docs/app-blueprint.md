# App Blueprint

Blueprint iniziale per l'app Flutter di PitLap.

Obiettivo:

- definire una struttura applicativa scalabile ma leggera
- allineare navigazione, feature e design system all'MVP
- evitare un bootstrap caotico

## Stato

Data: `2026-04-02`

Stato:

- blueprint raccomandato e parzialmente implementato nella codebase

Gia' presenti in app:

- shell con `go_router`
- stato e dependency injection con `flutter_riverpod`
- localizzazione base
- feature `tracks` collegata a Supabase per home e dettaglio
- layout responsive con navigazione laterale su desktop

## Target iniziali

- Android
- Web

## Principi applicativi

- una sola codebase Flutter
- mobile first, ma web leggibile e credibile
- architettura a feature, non per layer puramente tecnici
- dominio separato da UI e infrastruttura
- design system centrale e riusabile
- localizzazione prevista da subito

## Stack Flutter raccomandato

Scelte raccomandate:

- `flutter_riverpod` per stato e dependency injection
- `go_router` per routing
- `intl` e `flutter_localizations` per i18n

Scelte opzionali da valutare solo se utili:

- generatori di modelli
- librerie di form validation
- librerie di caching locale

Nota:

- l'obiettivo non e' avere lo stack piu' trendy, ma uno stack leggibile e stabile

## Struttura cartelle raccomandata

```text
lib/
  app/
    bootstrap/
    navigation/
    theme/
    l10n/
  core/
    constants/
    errors/
    utils/
    widgets/
  features/
    auth/
    discovery/
    tracks/
    shops/
    arrivals/
    events/
    garage/
    manager/
    submissions/
    profile/
  shared/
    models/
    services/
    repositories/
```

## Logica per feature

Ogni feature dovrebbe contenere, dove serve:

- `domain`
- `application`
- `infrastructure`
- `presentation`

Obiettivo:

- tenere vicini use case, repository e schermate della stessa feature

## Navigazione MVP

Struttura iniziale raccomandata:

1. home piste
2. dettaglio pista
3. login
4. profilo utente
5. area gestore
6. eventi
7. discovery vicino a te
8. negozi
9. garage
10. segnalazioni

Rotta chiave:

- `/`
- `/track/:slug`
- `/login`
- `/profile`
- `/manager`
- `/nearby`
- `/shops`
- `/shop/:slug`
- `/garage`
- `/u/:publicSlug`
- `/submit-place`

## Schermate prioritarie MVP

### 1. Home piste

Deve mostrare:

- ricerca
- filtri base
- card pista
- stato corrente
- presenze della giornata

Stato attuale:

- ricerca e filtri base prototipali presenti
- card pista e stato corrente collegati a Supabase
- presenze ancora placeholder

### 2. Dettaglio pista

Deve mostrare:

- header pista
- stato
- servizi
- presenze
- eventi vicini
- informazioni descrittive

Stato attuale:

- header, stato, servizi e informazioni descrittive gia' collegati a Supabase
- indirizzo e link mappa esterno attivi
- `Sto arrivando` ha un primo salvataggio reale su backend
- presenze aggregate ed eventi ancora da completare

### 3. Login

Deve essere:

- corto
- chiaro
- senza distrazioni

### 4. Area gestore

Deve consentire:

- aggiornamento stato pista
- modifica messaggio rapido
- aggiornamento servizi essenziali
- gestione eventi base

### 5. Negozi

Deve mostrare:

- elenco negozi
- distanza o localita'
- categorie principali
- contatti essenziali

### 6. Garage

Deve consentire:

- elenco modelli personali
- aggiunta foto
- visibilita' pubblica opzionale

### 7. Profilo pubblico

Deve mostrare:

- identita' base del pilota
- eventuale garage pubblico
- gallery pubblica opzionale

### 8. Segnala luogo

Deve consentire:

- scelta tipologia luogo
- inserimento dati minimi
- coordinate o posizione
- allegato foto opzionale
- invio per revisione

## Stato e sincronizzazione

Strategia raccomandata:

- stato server come fonte di verita'
- cache locale leggera solo dove migliora UX
- optimistic update solo su azioni semplici e reversibili

Usare optimistic update per:

- `Sto arrivando`
- RSVP evento semplice

Evitare optimistic update inizialmente per:

- update gestore di dati sensibili
- flussi multi-step

## Repository e dati

Ogni feature dovrebbe esporre repository chiari.

Esempi:

- `TracksRepository`
- `ArrivalsRepository`
- `EventsRepository`
- `ManagerRepository`
- `SubmissionsRepository`

Regola:

- i widget non parlano direttamente con Supabase
- Supabase resta confinato nell'infrastructure layer

## Design system

Il design system deve nascere dentro `app/theme`.

Elementi da definire subito:

- color tokens
- spacing scale
- radius scale
- typography scale
- button styles
- chip e badge di stato
- card base

Componenti prioritari:

- `TrackCard`
- `ShopCard`
- `StatusBadge`
- `ServiceChip`
- `PrimaryActionButton`
- `EmptyState`
- `ModelCard`
- `WeatherStrip`

## Responsive strategy

Approccio raccomandato:

- layout mobile first
- breakpoint semplice per tablet e desktop
- stessa grammatica visiva tra mobile e web

Da evitare:

- creare due prodotti visivamente scollegati
- home web impostata come dashboard enterprise pesante

## Localizzazione

Lingue iniziali:

- italiano
- inglese

Regole:

- chiavi i18n fin dal primo giorno
- niente testo hardcoded nei widget principali
- stato e label sempre localizzati lato app

## Accessibilita' e leggibilita'

Punti minimi obbligatori:

- contrasto alto per badge e testo
- target touch comodi
- tipografia leggibile anche in esterno
- icone sempre accompagnate da testo quando critico

## Observability minima

Prima dell'MVP pubblico prevedere:

- logging errori client
- logging eventi chiave di flusso
- strumenti minimi per capire schermate piu' usate e punti di abbandono

## Sequenza di bootstrap consigliata

1. creare shell app con tema, router e l10n
2. collegare Supabase e configurazione ambienti
3. implementare home piste
4. implementare dettaglio pista
5. implementare auth
6. implementare `Sto arrivando`
7. implementare area gestore minima
8. implementare eventi base
9. implementare negozi
10. implementare garage e profilo pubblico
11. implementare discovery geografica e meteo contestuale
12. implementare segnalazioni utente con moderazione

## Dubbi da tenere evidenti

### Dubbio 1. Web experience

Ipotesi attuale:

- stessa codebase e stessi componenti

Rischio:

- alcune schermate potrebbero chiedere piu' respiro su desktop

Decisione pratica:

- mantenere una sola grammatica UI, adattando layout e densita'

### Dubbio 2. State management scope

Ipotesi attuale:

- Riverpod come standard

Rischio:

- se la codebase resta molto piccola potrebbe sembrare piu' strutturato del necessario

Decisione pratica:

- adottarlo subito per coerenza e crescita futura

### Dubbio 3. Offline

Ipotesi attuale:

- supporto offline non prioritario nel primo bootstrap

Rischio:

- alcuni contesti pista possono avere connessione debole

Decisione pratica:

- non fare offline vero in fase 1
- progettare senza impedire un caching mirato piu' avanti

## Criterio di qualita'

La struttura e' corretta se:

- una nuova feature puo' essere aggiunta senza caos
- i componenti visivi restano coerenti
- il codice non mescola UI, query e logica di dominio
