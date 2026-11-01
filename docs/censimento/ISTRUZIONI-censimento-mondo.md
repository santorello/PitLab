# Censimento PitLap nel mondo: istruzioni per l'agente

PitLap (https://pitlap.app) è una app per il modellismo RC: piste, spot e negozi.
Il tuo compito è trovare **piste RC e negozi di modellismo RC reali, aperti oggi**, fuori dall'Italia,
e scriverli in un CSV. Non scrivi mai su database, non generi SQL, non tocchi il codice.

## Regola che vale più di tutte

**Mai inventare un dato.** Un campo che non trovi su una fonte verificabile resta vuoto.
Meglio una riga con tre campi veri che una con dieci verosimili.
Non stimare coordinate, non ricostruire indirizzi, non "completare" orari, non tradurre a senso
un nome proprio. Se non sei sicuro, lascia vuoto e scrivilo in `note`.

## Cosa cercare

- **Obiettivo:** 10-15 schede per paese, mix di piste e negozi (circa metà e metà dove possibile).
- **Pista:** circuito RC fisso (on-road, off-road, buggy, crawler/scaler, mini-z, drift, FPV, ecc.),
  di un club, di un'associazione o commerciale.
- **Negozio:** negozio fisico che vende davvero RC (automodelli, ricambi, elettronica RC).
  Negozi solo di treni, solo di kit statici o solo giocattoli: **no**. Solo online: no.
- **Qualità prima della quantità:** preferisci posti con sito o pagina ufficiale attiva
  e con attività recente (ultimi 12-18 mesi).

## Dove prendere i dati

- **Fonti valide:** sito ufficiale, pagina Facebook/Instagram ufficiale, scheda Google Maps,
  federazioni nazionali (es. BRCA UK, ROAR USA, DMC Germania, FFVRC Francia, AECAR Spagna)
  e calendari gara ufficiali.
- **Solo come spunto, mai come fonte:** forum, directory generiche, elenchi "top 10", Reddit.
- **Scarta subito**, annotando il motivo, i posti che Google Maps indica come "chiuso definitivamente"
  o "chiuso temporaneamente", e quelli senza traccia recente.
- **Duplicati:** prima di aggiungere una riga controlla che nome + città non siano già nel CSV.

## Campi, uno per uno

| Colonna | Cosa mettere |
|---|---|
| tipo | `pista` oppure `negozio` |
| paese | codice ISO a 2 lettere maiuscolo (`DE`, `FR`, `US`, `GB`...) |
| slug | `<nome>-<citta>`: minuscolo, solo a-z 0-9 e trattini, niente accenti (`rc-car-center-muenchen`) |
| nome | nome esatto come lo scrive il posto |
| citta | città in grafia locale (`München`, `Kraków`) |
| regione | stato/regione/contea se disponibile |
| indirizzo | indirizzo completo come da fonte, con CAP |
| lat, lon | decimali con il punto, almeno 6 cifre. **Solo da una scheda Google Maps o dal sito ufficiale.** Se non li hai letti da lì: vuoti |
| external_map_url | `https://www.google.com/maps/search/?api=1&query=<lat>,<lon>` solo se hai lat/lon |
| website_url | sito o pagina ufficiale (https) |
| phone | telefono pubblico del posto, formato internazionale (`+49 ...`). Mai cellulari personali, salvo che il posto li pubblichi come recapito |
| email | email pubblica del posto, se pubblicata |
| hours | **in inglese**, formato `Mon-Fri 10:00-19:00; Sat 10:00-13:00; Sun closed`. Solo da fonte ufficiale o Google Maps con la settimana intera; altrimenti vuoto |
| short_description | **in inglese**, 1-2 frasi concrete (max ~250 caratteri), scritte da te sulla base della fonte, senza copiarla. Pista: superficie, lunghezza, scale, tipo di tracciato, servizi. Negozio: cosa vende davvero, marche, assistenza, se ha una pista. Niente aggettivi promozionali |
| categorie_pista | solo piste, separate da virgola, **solo se la fonte lo dice letteralmente**: `bashing, buggy, fpv, indoor, militare, mini_z, mini4wd, movimento_terra, navale, on_road, rally, scaler` |
| servizi_pista | solo piste, stessa regola: `chairs, compressed_air, food, power_220v, tables, toilets` |
| service_labels | solo negozi, testo libero separato da `|`, con le parole del negozio (marche trattate, "repairs", "own track") |
| image_url | URL diretto di una **foto vera del posto**, orizzontale, idealmente ≥ 1200 px, dal sito ufficiale. Niente loghi, locandine, banner con scritte, foto stock. Nel dubbio: vuoto |
| fonte_dati | URL della fonte principale usata |
| fonte_coordinate | `google_maps` o `sito_ufficiale` oppure vuoto |
| fonte_foto | URL della pagina da cui viene la foto |
| verificato_il | data in cui hai controllato (AAAA-MM-GG) |
| stato | `candidato` (dati raccolti) oppure `scartato` |
| note | cosa manca e perché ("orari non pubblicati"), o motivo dello scarto |

### Esempi di tag leciti e non leciti

- **Leciti:**
  - "1/8 off-road dirt track" → `buggy`
  - "carpet on-road circuit" → `indoor, on_road`
  - "pit area with 230V sockets" → `power_220v`
- **Non lecito:**
  - "beginner friendly" → `mini_z`: è una deduzione, non la fonte.

## Formato del file

- **File di uscita:** `docs/censimento/mondo-censimento.csv`. Se non esiste crealo;
  se esiste aggiungi righe in fondo, senza modificare le righe già presenti.
- UTF-8, separatore `;`, prima riga di intestazione esattamente:

```
tipo;paese;slug;nome;citta;regione;indirizzo;lat;lon;external_map_url;website_url;phone;email;hours;short_description;categorie_pista;servizi_pista;service_labels;image_url;fonte_dati;fonte_coordinate;fonte_foto;verificato_il;stato;note
```

- Metti tra virgolette doppie i campi che contengono `;` o a capo.
- **Non modificare** altri file del repository.

## Come procedere

1. Lavora **un paese alla volta**, nell'ordine indicato nel prompt.
2. Per ogni paese salva il CSV appena finito, poi scrivi un riepilogo di 3 righe:
   - quante schede candidate e quante scartate;
   - quali campi mancano più spesso;
   - eventuali dubbi.
3. Se in un paese non trovi 10 posti affidabili, fermati a quelli che hai: non riempire.
