# PitLap — kit di contatto negozi, shop online e piste RC

## 1. Come usare il CSV

File: `negozi_modellismo_italia.csv` (separatore `;`, UTF-8 con BOM → si apre direttamente in Excel).

| Colonna | Contenuto |
|---|---|
| nome | ragione sociale / nome insegna |
| tipo | `negozio` \| `shop online` \| `pista/club` |
| citta, provincia, indirizzo | dati anagrafici quando disponibili |
| email | email pubblica trovata sul sito o nei dati OSM |
| telefono | numero pubblico |
| sito | sito web ufficiale |
| maps | link diretto a Google Maps (coordinate o ricerca per nome) |
| priorita | punteggio 0–100 (pista/club +40, rilevanza RC +30, email presente +20, sito presente +10) |
| fascia | Alta (≥60) / Media (≥30) / Bassa |
| fonte | OpenStreetMap, Scalemates, RCBazar/HobbyMedia, Ricerca web |

**Ordine di contatto consigliato:** fascia Alta → Media → Bassa. Le piste/club sono in testa perché portano utenti finali a PitLap, non solo vendite.

## 2. Template email — negozi e shop online

> **Oggetto:** PitLap — l'app gratuita per i vostri clienti in pista
>
> Buongiorno,
>
> mi chiamo Giuseppe e ho sviluppato **PitLap**, un'app gratuita per chi corre con automodelli RC in pista: gestione dei propri modelli, setup, sessioni, piste e risultati in un unico posto.
>
> Vi scrivo perché siete un punto di riferimento per i modellisti della vostra zona: se pensate che possa essere utile ai vostri clienti, sarei felice di inviarvi il link per provarla e, se vi va, di segnalare il vostro negozio all'interno dell'app.
>
> L'app è gratuita e senza pubblicità. Nessun impegno: se non vi interessa, basta non rispondere e non riceverete altri messaggi.
>
> Un saluto,
> Giuseppe — PitLap
> [link all'app] · [email di contatto]
>
> *Ricevi questa email perché l'indirizzo è pubblicato sul vostro sito come contatto aziendale. Per non essere più contattati, rispondete con "CANCELLAMI".*

## 3. Template email — piste e club

> **Oggetto:** PitLap — app gratuita per i piloti della vostra pista
>
> Buongiorno,
>
> sono Giuseppe, sviluppatore di **PitLap**, app gratuita per automodellismo RC in pista: i piloti registrano modelli, setup, sessioni e tempi, e possono associarli alla pista su cui girano.
>
> Mi piacerebbe inserire la vostra pista nell'elenco dell'app (dati, posizione, eventuali eventi) e, se lo ritenete utile, farla conoscere ai vostri iscritti.
>
> Se mi confermate nome ufficiale, indirizzo e un contatto, provvedo io all'inserimento. Nessun costo e nessun impegno.
>
> Grazie e buone gare,
> Giuseppe — PitLap
> [link all'app] · [email di contatto]
>
> *Ricevi questa email perché l'indirizzo è pubblicato come contatto dell'associazione. Per non essere più contattati, rispondete con "CANCELLAMI".*

## 4. Regole pratiche GDPR (B2B)

- Contatta solo indirizzi **aziendali pubblici** (info@, negozio@) — mai email di persone fisiche identificabili se puoi evitarlo.
- Ogni email deve avere: chi sei, perché scrivi, dove hai preso il contatto, come cancellarsi.
- Tieni una lista "CANCELLAMI" e rispettala: chi chiede di non essere ricontattato va rimosso dal CSV.
- Non usare mailing massivi da Gmail: oltre ~50 invii/giorno rischi il blocco. Meglio 20–30 al giorno, personalizzati con il nome del negozio.
- Conserva il CSV come "registro trattamento" minimo: fonte del dato + data di raccolta (settembre 2026).

## 5. Limiti di questa versione e come estenderla

- **Copertura**: 162 record da fonti gratuite. La lista completa dei negozi di modellismo italiani è realisticamente 3–5 volte più grande — la parte mancante è quasi tutta su Google Maps, che richiede la Places API (chiave + costo) per essere estratta in modo pulito.
- **Email**: 42 su 162. Le restanti hanno solo form di contatto o social. Opzioni: (a) secondo giro mirato sulle pagine "Contatti" dei siti rimasti; (b) contatto via Facebook/Instagram Messenger per chi non pubblica email; (c) telefono per i più importanti.
- **Piste**: l'elenco viene da fonti community (HobbyMedia/RCBazar) e va verificato — alcune piste potrebbero essere chiuse. L'elenco ufficiale AMSCI delle società affiliate è la fonte migliore per un aggiornamento.
