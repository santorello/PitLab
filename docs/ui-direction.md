# UI Direction

Direzione visiva e UX iniziale per PitLap.

Obiettivo:

- definire un'identita' coerente prima del design system
- evitare una grafica generica o incoerente con il pubblico
- guidare future scelte di logo, palette, typography e componenti

## Profilo del pubblico

Pubblico iniziale prevalente:

- uomini adulti
- appassionati tecnici
- nerd del dettaglio
- meccanici, modellisti, organizzatori, frequentatori dei box

Tratti rilevanti:

- amano ordine, precisione, affidabilita'
- premiano i prodotti che sembrano strumenti seri
- tollerano poca confusione visiva
- leggono velocemente informazioni pratiche
- apprezzano carattere e identita', ma non il rumore estetico

## Posizionamento estetico

PitLap deve comunicare:

- precisione tecnica
- credibilita'
- passione curata
- concretezza da paddock

PitLap non deve comunicare:

- social network generico
- app da hobby infantile
- dashboard enterprise fredda
- look gaming pieno di neon ed effetti

## Direzione raccomandata

Definizione sintetica:

- `industrial premium`

Traduzione pratica:

- base visiva pulita e tecnica
- materiali evocati: alluminio, carbonio, gomma, asfalto, pannelli da officina
- una sola nota energica da motorsport o segnaletica
- interfaccia asciutta, veloce e autorevole

## Principi UI

### 1. Information first

La UI deve dare precedenza ai segnali operativi:

- stato pista
- localita'
- servizi
- presenze
- eventi vicini

### 2. Blocchi compatti e leggibili

Le card devono sembrare moduli tecnici ordinati, non post social.

### 3. Contrasto e gerarchia

Le informazioni principali devono essere leggibili in esterno, in box e in movimento.

### 4. Pochi accenti

Gli elementi forti devono essere pochi e intenzionali.

### 5. Motion contenuta

Animazioni brevi, secche e funzionali:

- reveal iniziale
- feedback di cambio stato
- aggiornamento presenze

## Palette concettuale

Base consigliata:

- grafite
- antracite
- acciaio
- off-white caldo

Accento consigliato:

- arancio segnaletico oppure rosso racing

Colori di stato:

- aperta: verde tecnico pulito
- bagnata: blu freddo controllato
- chiusa: rosso netto
- attenzione: ambra

Nota:

- il colore di stato deve restare semantico, non decorativo

## Light e dark mode

Decisione raccomandata:

- il brand non deve dipendere solo dalla dark mode
- la dark mode deve esistere ed essere curata
- la modalita' chiara deve restare molto leggibile per uso diurno e outdoor

Conclusione:

- design system duale, con identita' coerente in entrambe le modalita'

## Tipografia

La typography dovrebbe risultare:

- solida
- condensata o semi-condensata per titoli, senza diventare aggressiva
- pulita e molto leggibile per dati e label

Indicazione di tono:

- titoli con carattere tecnico
- corpo testo semplice e chiaro
- numeri, stati e chip molto leggibili

## Componenti chiave

### Card pista

Deve mostrare subito:

- nome pista
- citta'
- stato corrente
- servizi principali
- presenze della giornata

Regole operative:

- una sola CTA primaria per card
- il `follow/preferiti` non deve precedere visivamente stato e localita'
- il colore di stato deve comparire anche come segnale strutturale, non solo come badge
- i servizi devono essere compatti e scansionabili come chip o conteggio breve
- le presenze devono essere reali o assenti con fallback sobrio, mai placeholder di promessa

Ordine consigliato nella card:

- nome pista
- localita'
- stato + presenza sintetica della giornata
- servizi confermati
- nota breve del gestore o stato operativo
- eventuale stato personale dell'utente
- CTA primaria

Scelta CTA:

- la card home deve avere una sola azione dominante
- se l'obiettivo della schermata e' esplorare, la CTA primaria apre il dettaglio pista
- `Sto arrivando` resta importante ma deve vivere come secondaria o come azione nel dettaglio, salvo casi d'uso molto specifici
- evitare due pulsanti percepiti come ugualmente primari sulla stessa riga in mobile

Nota emersa dal mockup UX:

- la grammatica giusta per PitLap non e' `card ricca di bottoni`
- la grammatica giusta e' `pannello operativo compatto`

### Header scheda pista

Deve dare la sensazione di un pannello tecnico:

- nome forte
- badge stato grande
- localita'
- azione primaria `Sto arrivando`

Regole operative:

- titolo molto forte e leggibile
- localita' subito sotto, con tono piu' quieto
- stato visibile entro il primo colpo d'occhio
- messaggio del gestore presente ma subordinato allo stato
- azioni principali poche: massimo una primaria e una o due secondarie compatte
- il blocco hero non deve sembrare marketing, ma dashboard editoriale

Ordine consigliato:

- back/breadcrumb leggero
- nome pista
- localita'
- stato + messaggio operativo
- quick facts davvero utili
- CTA primaria
- eventuale share/map/follow come secondarie

### Sezione servizi

Deve essere una checklist visiva pulita:

- icona
- etichetta
- disponibilita'

### Eventi

Gli eventi non devono dominare il layout.

Devono apparire come informazione utile, non come feed.

### Search e filtri

Regole operative:

- il selettore lingua non deve vivere dentro la search bar
- la search deve restare una funzione pulita e dedicata
- i filtri devono essere orizzontali, rapidi e con stato attivo immediato
- evitare filtri fake o hardcoded esposti all'utente

### Bottom navigation

Regole operative:

- icona + label sempre presenti
- attivo visibile con accento leggero, non urlato
- struttura semplice e stabile tra le schermate
- niente overload di tab nella prima versione

### Section pattern

Per i blocchi sotto l'hero usare un pattern ricorrente:

- card bianca o superficie chiara
- titolo sezione in uppercase piccolo
- corpo dati compatto
- una sola idea per sezione
- spazio interno costante e ombre discrete

### Presence pattern

La presenza giornaliera deve essere rappresentata in due livelli:

- livello pubblico: aggregato, conteggio, eventuali stati sintetici
- livello personale: stato dell'utente autenticato separato e chiaramente distinto

Da evitare:

- mischiare presenza personale e totale nello stesso badge
- mostrare dati nominali pubblici senza una decisione esplicita di privacy
- usare copy placeholder tipo `disponibile presto` su una promessa core

### Component grammar

Regola generale emersa dal mockup:

- componenti sobri
- angoli moderati
- peso visivo concentrato nei dati e nei badge
- pochi elementi decorativi
- accento arancione usato per attivazione, non per riempimento

Schema base dei componenti:

- `Badge`: piccolo, semantico, fortemente leggibile
- `Chip`: neutro o tonale, usato per servizi e filtri
- `Card`: bordo/top signal o titolo forte, contenuto scansionabile, una CTA dominante
- `Section title`: uppercase piccolo, tracking ampio, tono tecnico
- `Primary action`: piena, netta, usata con parsimonia
- `Secondary action`: tonale o outline, mai in competizione con la primaria

## Sistema operativo raccomandato

Direzione da adottare come base comune di prodotto:

- `industrial premium` come tono generale
- `operational clarity` come regola di layout
- `one primary action` come default per i componenti principali
- `real data over promises` come criterio di qualita' UX

Applicazione consigliata:

- `70-80%` schermate sulla grammatica tecnica comune
- `20-30%` schermate con tono piu' accogliente o narrativo dove serve onboarding, vuoti, login e profilo

## Bozzetto concettuale

Home mobile, schema base:

```text
+--------------------------------------------------+
| PitLap                                         |
| Dove vuoi andare oggi?                           |
| [ Cerca pista...                         ] [IT]  |
+--------------------------------------------------+
| FILTRI: [Buggy] [Mini-Z] [Indoor] [Outdoor]      |
+--------------------------------------------------+
| PISTA: OFFROAD PARMA                             |
| Parma                                            |
| [ APERTA ]     7 arrivi oggi                     |
| 220V  Aria  Tavoli  Bagni                         |
| Fondo asciutto, buona trazione                   |
| [ Vedi pista ]            [ Sto arrivando ]      |
+--------------------------------------------------+
| PISTA: MINIZ HUB MODENA                          |
| Modena                                           |
| [ BAGNATA ]    2 arrivi oggi                     |
| Tavoli  Sedie  Bagni                              |
| Sessione serale confermata                       |
| [ Vedi pista ]            [ Sto arrivando ]      |
+--------------------------------------------------+
```

Scheda pista, schema base:

```text
+--------------------------------------------------+
| OFFROAD PARMA                                    |
| Parma, Italia                     [ APERTA ]     |
| Fondo asciutto, grip medio-alto                  |
| [ Sto arrivando ]   [ Condividi ]                |
+--------------------------------------------------+
| SERVIZI                                          |
| 220V   Aria compressa   Tavoli   Bagni           |
+--------------------------------------------------+
| OGGI IN PISTA                                    |
| 7 arrivi confermati                              |
| Luca, Marco, Ale, ...                            |
+--------------------------------------------------+
| EVENTI                                           |
| Domenica 7 Aprile - Prova libera                 |
+--------------------------------------------------+
| INFO                                             |
| Descrizione, accesso, orari, note del gestore    |
+--------------------------------------------------+
```

## Indicazioni per logo e brand

Il logo dovrebbe seguire questi criteri:

- semplice
- netto
- riconoscibile anche piccolo
- piu' vicino a un marchio tecnico che a una mascotte

Elementi possibili:

- monogramma `TH`
- traccia astratta di circuito
- segno che richiama hub, connessione o traiettoria

Da evitare:

- loghi troppo illustrativi
- auto miniature disegnate in modo letterale
- eccesso di dettagli sottili

## Regola finale

Se una schermata e' bella ma non fa capire rapidamente cosa c'e' in pista, non e' la schermata giusta per PitLap.

## Riferimenti

- [Design System](design-system.md) — implementazione concreta dei principi qui descritti
