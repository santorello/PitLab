# Censimento piste e negozi

Come si aggiungono a PitLap piste e negozi "segnalati dalla community": schede create
da noi, senza proprietario, che il titolare poi rivendica. Scritto dopo i lotti 01-05
(settembre 2026), con gli errori già fatti e come evitarli.

**Regola unica: mai inventare un dato.** Campo non trovato = `null`. Meglio una scheda
con tre campi veri che una con dieci verosimili. Nel dubbio si lascia vuoto e si annota.

---

## 0 · Prima di iniziare

| Cosa | Dove |
|---|---|
| Elenco vivo (censiti, scartati, candidati, motivo) | `docs/censimento-piste-negozi.csv` |
| Delta dei lotti precedenti (modello da copiare) | `supabase/deltas/*-censimento-lotto-*.sql` |
| DB di prova | Supabase **dev** `mqieterttnqdtdguaqoe` |
| DB reale | Supabase **prod** `klfjvyytubiorqzfisdu` (lo lancia Giuseppe) |

Strumenti:
- **Siti e Google Maps si aprono dal Chrome di Giuseppe** (Claude in Chrome). Il sandbox
  cloud e la shell locale non raggiungono i siti esterni (il proxy risponde 403).
  La ricerca web va bene per trovare i nomi, non per verificare.
- Prima di tutto controllare che il posto non sia già a DB, su **prod**:
  ```sql
  select slug, name from tracks where name ilike '%parola%'
  union all select slug, name from shops where name ilike '%parola%';
  ```

Un **lotto** = 5-10 schede. Di più diventa impossibile guardare ogni dato.

---

## 1 · Trovare i candidati

1. Rileggere il CSV: le righe `CANDIDATA` e `DA TROVARE` vengono prima dei nomi nuovi.
2. Nomi nuovi: ricerca web per zona e specialità ("pista automodellismo Cremona",
   "negozio modellismo Bergamo"...). Forum, directory ed elenchi di piste servono
   **solo come spunto**: la fonte deve essere il sito del club/negozio o la sua scheda Maps.
3. Scartare subito, scrivendo il motivo nel CSV (`SCARTATA`):
   - Google Maps dice "Chiuso definitivamente" o "Chiuso temporaneamente";
   - nessuna attività recente (sito fermo da anni, solo vecchi thread di forum);
   - fonti in conflitto che non si riescono a risolvere (es. due città diverse);
   - non è una sede: organizzatori di gare itineranti, club privati, posti riconvertiti;
   - non è modellismo (es. aviosuperfici per aerei veri).
4. Fuori Lombardia: si mette come `CANDIDATA` e si chiede a Giuseppe.

Mini-Z, Mini 4WD e movimento terra vivono di eventi senza sede fissa: si coprono col
calendario eventi, non con le piste.

---

## 2 · Raccogliere i dati

Per ogni scheda: nome esatto, città, indirizzo completo, coordinate, sito, orari,
telefono, email (solo piste), descrizione, copertina, categorie/servizi (piste) o
etichette (negozi).

### Dal sito ufficiale
Descrizione, servizi, contatti, segni di attività (news, calendario gare dell'anno).
In Chrome, `get_page_text` sulla pagina basta quasi sempre. Per leggere più pagine dello
stesso sito senza navigarle una per una, dal tab aperto:
```js
const h = await fetch('/contatti.html').then(r => r.text());
const d = new DOMParser().parseFromString(h, 'text/html');
d.querySelectorAll('script,style').forEach(e => e.remove());
d.body.textContent.replace(/\s+/g, ' ').replace(/https?:\S+/g, '').slice(0, 2000)
```
(Togliere gli URL dall'output: se contengono `?` e `=` lo strumento blocca la risposta.)

### Da Google Maps (coordinate, orari, stato)
Aprire `https://www.google.com/maps/search/<nome>+<indirizzo>`, aspettare 4-5 secondi,
poi leggere tutto dalla pagina:
```js
const m = location.href.match(/!3d([\d.]+)!4d([\d.]+)/) || location.href.match(/@([\d.]+),([\d.]+)/);
const t = document.body.innerText;
document.title + ' ' + (m ? m[1] + ',' + m[2] : 'none')
 + ' | chiuso:' + /chiuso (definitivamente|temporaneamente)/i.test(t) + ' | '
 + [...document.querySelectorAll('[aria-label]')].map(e => e.getAttribute('aria-label'))
     .filter(x => /lunedì|martedì|mercoledì|giovedì|venerdì|sabato|domenica|Indirizzo|Telefono|Sito/i.test(x))
     .join(' || ')
```
- Se le coordinate escono `none`, la pagina non ha ancora finito: rilanciare lo script.
- Controllare che il **titolo** sia il posto giusto (una volta è uscita una SRL diversa,
  chiusa definitivamente: era il vecchio negozio).
- Orari: gli `aria-label` dei giorni danno la settimana intera; "apre lun alle 9" da solo
  non basta. Se Maps non ha orari → `null`.
- `chiuso:true` → scartare.
- Guardare il satellite: se il segnaposto non sta sul tracciato, annotarlo nel CSV
  (Stradivari: pin ~130 m a sud). Si usano comunque le coordinate di Maps, non stime a occhio.

### Quando sito e Maps non coincidono
Per orari e telefono vale il **sito del titolare**; la differenza si scrive nel CSV.

### Privacy
Cellulari personali solo se il club/negozio li pubblica come proprio recapito.

---

## 3 · Tag: categorie, servizi, etichette

Un tag filtra i risultati: se è sbagliato, il filtro mente. **Solo ciò che la fonte dice.**

**Categorie pista** (`track_categories` → `track_category_links`):
`bashing, buggy, fpv, indoor, militare, mini_z, mini4wd, movimento_terra, navale,
on_road, rally, scaler, slot, treni, volo`.
Controllare sempre l'elenco vero su prod (`select key from track_categories`): cambia.

**Servizi pista** (`service_types` → `track_services`):
`chairs, compressed_air, food, power_220v, tables, toilets`.

| La fonte dice | Tag |
|---|---|
| "tracciato 1/8 in terra", "buggy" | `buggy` |
| classi Touring, GT, SGT, Formula; "on road" | `on_road` (precedente: Nuova G.A.M.E.S., Mantova, Stradivari) |
| "corrente", "presa per ogni tavolo" | `power_220v` |
| "aria compressa", "compressore", "aria" | `compressed_air` |
| "bagni", "servizi igienici" | `toilets` |
| "punto ristoro", "zona ristoro" | `food` |
| "per ogni tavolo" | `tables` |

Non lecito: "adatta ai principianti" → `mini_z`; foto di asfalto → "in asfalto" nella
descrizione. Si scrive quello che è scritto, non quello che si vede.

**Negozi**: `shops.service_labels` è testo libero. Parole del negozio stesso: marche
trattate, "Riparazioni", "Setup auto RC", "Pista propria"...

---

## 4 · Copertine

Obiettivo: foto **orizzontale del posto vero**, idealmente ≥ 1200 px, sotto ~600 KB.

1. **Siti WordPress**: l'elenco dei media con le dimensioni, dal tab del sito:
   ```js
   const all = [];
   for (let p = 1; p <= 4; p++) {
     const r = await fetch('/wp-json/wp/v2/media?per_page=100&page=' + p + '&_fields=source_url,media_details')
       .then(r => r.ok ? r.json() : []);
     if (!r.length) break; all.push(...r);
   }
   window.V = all.filter(m => m.media_details?.width >= 1000 && m.media_details.width > m.media_details.height);
   V.map((m, i) => i + ' ' + m.media_details.width + 'x' + m.media_details.height + ' ' + m.source_url.split('uploads/')[1]).join('\n')
   ```
   Per negozi con migliaia di foto prodotto: `?search=negozio` (o `pista`, `sede`, `vetrina`).
2. **Altri siti**: le immagini già caricate nella pagina:
   ```js
   [...document.images].filter(i => i.naturalWidth >= 700)
     .map(i => i.naturalWidth + 'x' + i.naturalHeight + ' ' + i.src.split('?')[0]).join('\n')
   ```
3. **Guardarle tutte in una griglia**, in un colpo solo (poi screenshot):
   ```js
   const L = V.slice(0, 30).map(m => m.source_url);
   document.body.innerHTML = '<div style="display:flex;flex-wrap:wrap;background:#222">' +
     L.map((u, i) => '<div style="width:20%;position:relative"><img src="' + u +
       '" style="width:100%;height:120px;object-fit:cover"><b style="position:absolute;left:2px;top:1px;background:#000;color:#ff0">' +
       i + '</b></div>').join('') + '</div>';
   ```
4. Peso del file scelto: `(await fetch(url, {method:'HEAD'})).headers.get('content-length')`.

**Scartare**: loghi; locandine; banner con scritte (anche se fotografici); slide con
citazioni; foto di prodotti generici o stock; foto di gruppo d'epoca; PNG da diversi MB
senza versione ridotta; link a Facebook/Instagram (scadono); foto di un evento altrove
(es. raduno sul lago invece del campo). Nel dubbio sul luogo, controllare a quale
articolo/galleria appartiene la foto.

Si usa l'hotlink al sito del titolare (lo Storage costa egress). Funziona anche senza
CORS grazie a `webHtmlElementStrategy.fallback` in `AdaptiveImage`.
**Nessuna copertina è meglio di una sbagliata**: il segnaposto è dignitoso, e la foto
vera arriva con la rivendica.

---

## 5 · Completezza

Prima del delta, per ogni scheda, elencare cosa manca e perché:
nome · città · indirizzo · coordinate · sito · orari · telefono · descrizione · copertina · tag.
"Orari non pubblicati" è una risposta valida. Va nel CSV e nel resoconto.

---

## 6 · Delta SQL

Un file per lotto: `supabase/deltas/AAAA-MM-GG-censimento-lotto-NN.sql`.
Copiare la struttura del lotto precedente. Punti fissi:

- insert diretta su `tracks` / `shops` con `on conflict (slug) do nothing`;
- slug `<nome>-<citta>`, minuscolo, trattini, niente accenti;
- `country = 'IT'`, `is_public = true`, `approval_status = 'approved'`,
  `is_community = true`, `submitted_by = null`;
- `external_map_url = 'https://www.google.com/maps/search/?api=1&query=<lat>,<lng>'`;
- apostrofi raddoppiati (`'Sant''Alessandro'`);
- colonne diverse: le piste hanno `contact_email`, i negozi no (hanno `service_labels`);
- servizi con `on conflict (track_id, service_type_id) do update set is_available = true`
  (le righe possono già esistere a `false`);
- completamenti di schede vecchie con `update ... where slug = ... and <campo> is null`,
  così non si sovrascrive quello che ha messo un titolare;
- in fondo una `select` di verifica (coordinate, copertina, orari, tag).

Non usare `admin_create_community_track` / `admin_create_community_shop` dal SQL: controllano
`is_admin()` via `auth.uid()` e rispondono "Solo admin".

**Prova su dev.** Attenzione: `execute_sql` via MCP gira in un'unica transazione, quindi
un errore annulla tutto il blocco. Se dev e prod hanno tassonomie diverse, i link alle
categorie mancanti spariscono in silenzio: controllare la select finale.

Su prod il delta lo lancia **Giuseppe**. Claude scrive su prod solo se gli viene chiesto.

---

## 7 · Collaudo su prod

Dopo il lancio del delta e il deploy, nel Chrome di Giuseppe loggato da admin:
- lista piste/negozi: card, città, descrizione, copertina (non grigia);
- dettaglio: fascia "Segnalata dalla community" e pulsante di rivendica, orari non troncati,
  sito cliccabile, mappa, meteo (solo piste);
- filtri piste: le categorie nuove compaiono (sono lette dalla tassonomia usata);
- pannello admin: le schede sono nelle liste e i contatori di "Da fare ora" tornano;
- editor: un gestore deve poter caricare la copertina dal dispositivo;
- a DB, non solo a video: `select` sulle schede del lotto su prod.

---

## 8 · Chiusura

1. CSV aggiornato: `lotto NN` per i censiti (con cosa manca), `SCARTATA` + motivo,
   `CANDIDATA` per quello che aspetta una decisione.
2. Commit di delta e CSV. Dalla shell locale git lascia `.git/index.lock` e
   `.git/HEAD.lock`: rimuoverli subito, altrimenti il push successivo si blocca.
3. Resoconto a Giuseppe: cosa è entrato, cosa manca per ogni scheda, cosa è stato
   scartato e perché, cosa deve decidere.
4. Proporre i contatti ai titolari: una scheda già compilata è l'amo per la rivendica,
   e chi rivendica porta foto e orari veri. Prima le schede più complete.
