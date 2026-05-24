# Design Brief

Brief operativo per identita' visiva e design system iniziale di PitLap.

Obiettivo:

- trasformare la direzione UI in scelte piu' concrete
- guidare logo, palette, typography e componenti
- mantenere coerenza tra branding e prodotto

## Posizionamento

PitLap deve sembrare:

- tecnico
- affidabile
- contemporaneo
- curato
- essenziale

PitLap non deve sembrare:

- giocattoloso
- tamarro
- confuso
- troppo corporate
- troppo gaming

## Brand keywords

Parole guida:

- precisione
- pista
- box
- setup
- affidabilita'
- community concreta

## Mood consigliato

Definizione sintetica:

- `industrial premium`

Riferimenti astratti:

- pannelli tecnici
- officina pulita
- asfalto e cordoli
- alluminio spazzolato
- strumenti ben costruiti

## Palette proposta A

Base:

- `Graphite` `#1F2329`
- `Steel` `#4B5563`
- `Concrete` `#D6D9DE`
- `Warm White` `#F6F4EF`

Accento:

- `Signal Orange` `#F97316`

Stati:

- `Open Green` `#1F9D55`
- `Wet Blue` `#2563EB`
- `Closed Red` `#D14343`
- `Warning Amber` `#D97706`

Uso consigliato:

- accento forte solo per CTA e highlight
- stati sempre semanticamente coerenti

## Palette proposta B

Base:

- `Midnight Slate` `#182028`
- `Gunmetal` `#334155`
- `Fog` `#DCE2E8`
- `Paper` `#FAF8F3`

Accento:

- `Racing Red` `#D92D20`

Nota:

- questa variante e' piu' aggressiva e motorsport
- da usare solo se vogliamo un'identita' piu' forte e meno neutra

## Tipografia proposta

Direzione raccomandata:

- titoli: `Barlow Semi Condensed`
- corpo e interfaccia: `IBM Plex Sans`

Motivazione:

- combinazione tecnica ma leggibile
- buona resa su UI e dati
- abbastanza carattere senza diventare caricaturale

Fallback di tono simile:

- `Rajdhani` per titoli, se vogliamo piu' energia
- `Public Sans` per corpo, se vogliamo piu' neutralita'

## Sistema visivo

### Forme

Preferire:

- angoli moderatamente netti
- card solide
- badge compatti
- linee divisorie leggere ma presenti

Evitare:

- rotondita' eccessiva
- ombre morbide stile app lifestyle
- vetri, blur e glow invasivi

Indicazioni operative derivate dal mockup UX:

- raggio card medio, non morbido
- raggio badge molto alto
- raggio chip compatto
- card con struttura chiara e bordo/segnale di stato quando utile
- ombre basse e corte, piu' da strumento fisico che da app editoriale

### Iconografia

L'iconografia deve essere:

- semplice
- pulita
- tecnica
- coerente nello spessore

### Texture e sfondi

Consentiti con moderazione:

- trame sottili
- pattern ispirati a griglie tecniche
- gradienti leggeri e controllati

Da evitare:

- fondi piatti senza carattere
- texture pesanti
- carbonio finto ovunque

Uso raccomandato:

- sfondi base chiari e caldi per leggibilita' outdoor
- hero scuri solo dove danno vera gerarchia
- gradienti controllati soprattutto in hero e superfici introduttive
- superfici dei contenuti quasi sempre semplici e pulite

## Componenti chiave da disegnare bene

Priorita' assoluta:

- barra ricerca
- `TrackCard`
- badge stato
- pulsante `Sto arrivando`
- checklist servizi
- header scheda pista

Percezione desiderata:

- ogni componente deve sembrare parte di uno stesso strumento

### Regole di gerarchia componenti

`TrackCard`:

- nome pista in alto, forte
- localita' subito sotto
- riga stato + presenze come cuore informativo
- servizi come chip o conteggio compatto
- nota breve, mai paragrafo lungo
- una sola CTA primaria visibile
- `Segui` o `Preferiti` come azione secondaria leggera

`Track detail hero`:

- titolo molto leggibile
- status line chiara
- quick facts utili e pochi
- primary CTA dominante
- secondarie compatte e tecniche

`Section blocks`:

- titolo sezione piccolo e uppercase
- contenuto compatto
- niente mix di troppe funzioni nella stessa card

`Bottom nav`:

- icone semplici
- label corte
- stato attivo con accento leggero

### Layout grammar

Regola base:

- il layout deve guidare prima la scansione e poi l'interazione

Traduzione pratica:

- prima i dati
- poi il contesto
- poi l'azione

Ordine da preferire:

- segnale operativo
- contesto
- dettaglio secondario
- azione principale

### CTA policy

Default:

- un solo bottone primario per blocco principale

Da evitare:

- due CTA adiacenti con uguale peso
- CTA primarie che arrivano prima del dato
- azioni secondarie messe in testata quando l'utente deve prima leggere stato e presenze

Applicazione:

- home piste: primaria al dettaglio oppure a `Sto arrivando`, ma una sola dominante
- dettaglio pista: `Sto arrivando` puo' essere primaria
- gestore/admin: primaria contestuale all'azione di salvataggio o aggiornamento

### Dati reali vs placeholder

Regola forte:

- nessun componente core deve basarsi su placeholder che promettono dati futuri

Traduzione pratica:

- se il dato non c'e', mostrare stato vuoto sobrio
- se la funzione non e' pronta, non trattarla come contenuto principale
- le promesse di prodotto core devono essere sostenute da dati o da copy neutro, non da teaser

## Microcopy

Il copy UI deve essere:

- diretto
- sintetico
- concreto

Esempi corretti:

- `Aperta`
- `Bagnata`
- `Chiusa`
- `5 arrivi oggi`
- `Servizi confermati`

Esempi da evitare:

- `La pista sembra essere disponibile`
- `Forse troverai altri utenti`
- `Scopri di piu'`

## Logo direction

Strade possibili:

### 1. Monogramma tecnico

- `TH` compatto
- geometrico
- leggibile anche piccolo

### 2. Traccia astratta

- segno che richiama circuito o traiettoria
- semplice, non illustrativo

### 3. Nodo / hub

- idea di connessione tra piste, persone e dati

Direzione raccomandata:

- monogramma o traccia astratta

Da evitare:

- miniature disegnate
- bandiere a scacchi stereotipate
- troppo dettaglio da logo vecchia scuola

## Bozzetto concettuale rapido

Immagine mentale della home:

- header forte con brand e search
- elenco piste come pannelli tecnici verticali
- badge stato molto chiari
- CTA primaria sempre visibile ma non urlata
- informazioni operative prima di quelle decorative

Evoluzione raccomandata dal mockup UX:

- language switch nell'header, non nella search
- `TrackCard` piu' asciutta, con stato e presenze come primo nucleo
- services presentati come chip o conteggio, non come testo vago
- riduzione del peso visivo di `Preferiti`
- maggiore continuita' tra home e dettaglio pista

## Dubbi da tenere evidenti

### Dubbio 1. Quanto carattere dare al brand

Scelta attuale:

- brand con personalita' chiara ma disciplinata

Rischio:

- se spingiamo troppo sul motorsport diventiamo piu' stretti di quanto PitLap voglia essere

### Dubbio 2. Dark mode come identita'

Scelta attuale:

- dark mode forte ma non dominante

Rischio:

- se il brand vive solo in dark, perde leggibilita' e versatilita'

### Dubbio 3. Tono community vs tool

Scelta attuale:

- prodotto prima di tutto come tool operativo

Rischio:

- se un domani la community pesa di piu', alcuni elementi visivi potrebbero chiedere piu' calore

## Criterio finale

Se il design sembra bello ma non fa sentire PitLap come uno strumento preciso e credibile da usare davvero in pista, la direzione non e' ancora giusta.
