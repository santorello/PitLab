# Cookie Policy e utilizzo del local storage

**Versione: 1.0 — in vigore dal 2026-06-03**
**Ultimo aggiornamento: 2026-06-03**

---

## 1. Premessa

La presente Cookie Policy descrive l'utilizzo di cookie e tecnologie equivalenti nell'ambito di PitLap (pitlap.app).

Per "tecnologie equivalenti" si intendono, in questa sede, anche strumenti come il `localStorage` del browser, utilizzati nelle applicazioni web per memorizzare o leggere informazioni sul dispositivo dell'utente.

PitLap adotta un approccio **minimalista**: vengono utilizzati esclusivamente gli strumenti tecnici strettamente necessari al funzionamento del servizio. Non sono attivi cookie di analytics né di marketing o profilazione.

---

## 2. Inventario degli strumenti attivi

### 2.1 Token di sessione Supabase (tecnico-necessario)

| Attributo | Valore |
|---|---|
| Nome / chiave | `sb-[project-ref]-auth-token` (localStorage) |
| Fornitore | Supabase (gestito da PitLap) |
| Tipo | Tecnico-necessario |
| Finalità | Mantenimento della sessione autenticata dell'utente |
| Dati memorizzati | Token di accesso e refresh token cifrati |
| Durata | Durata della validità del token di sessione; viene rinnovato automaticamente fino al logout esplicito |
| Lato | Client (web browser / WebView dell'app Android) |
| Trasferimento a terzi | No — il token viene inviato esclusivamente al backend Supabase di PitLap |

Questo strumento è strettamente necessario per erogare il servizio autenticato richiesto dall'utente. Non è richiesto il consenso separato per questo elemento (art. 122 D.Lgs. 196/2003, recepimento della Direttiva ePrivacy).

### 2.2 MapTiler — mappe e geocoding (funzionale, lato client)

| Attributo | Valore |
|---|---|
| Fornitore | MapTiler AG, Svizzera |
| Tipo | Funzionale (necessario per le funzionalità di mappa e ricerca luoghi) |
| Finalità | Rendering delle mappe interattive, ricerca di luoghi e geocoding |
| Dati trasmessi al fornitore | Indirizzo IP del dispositivo, query geografica testuale o coordinate |
| Durata | Richieste in tempo reale; MapTiler può impostare cookie tecnici propri |
| Lato | Client (le richieste partono direttamente dal dispositivo dell'utente) |
| Privacy policy fornitore | [https://www.maptiler.com/privacy-policy/](https://www.maptiler.com/privacy-policy/) |
| Termini di utilizzo | [https://www.maptiler.com/cloud/pricing/](https://www.maptiler.com/cloud/pricing/) |

MapTiler è una società svizzera; la Svizzera beneficia di una decisione di adeguatezza della Commissione europea. L'uso del servizio implica che l'indirizzo IP dell'utente sia trasmesso ai server di MapTiler al momento dell'utilizzo delle funzionalità di mappa. Per maggiori dettagli, si rinvia alla privacy policy di MapTiler.

---

## 3. Strumenti non attivi

### 3.1 Analytics

PitLap non utilizza al momento alcun strumento di analytics. Se in futuro verranno introdotti strumenti di analisi dell'utilizzo, questa policy verrà aggiornata indicando: fornitore, dati raccolti, finalità, durata, base giuridica e meccanismo di consenso.

### 3.2 Marketing e profilazione

PitLap non utilizza cookie o strumenti equivalenti per marketing, retargeting o profilazione. Tale categoria non verrà attivata senza: una valutazione preventiva del perimetro, un consenso valido separato e revocabile, un meccanismo di gestione delle preferenze adeguato e un aggiornamento della presente policy e dell'Informativa Privacy.

### 3.3 Sentry (crash reporting)

Sentry non è attualmente attivo. Qualora venisse attivato per la raccolta di segnalazioni di crash e log di errore, questa policy e l'Informativa Privacy verranno aggiornate con i relativi dettagli.

---

## 4. Banner cookie

Poiché PitLap utilizza esclusivamente strumenti tecnico-necessari e uno strumento funzionale direttamente collegato alla funzionalità di mappa richiesta dall'utente, **non è attualmente presente un banner di consenso cookie**. Questa scelta è conforme alle Linee Guida del Garante per la protezione dei dati personali del 10 giugno 2021 e alle indicazioni del Gruppo di Lavoro "Articolo 29".

Qualora venissero introdotti strumenti che richiedono consenso preventivo (analytics, marketing), verrà implementato un layer informativo con centro preferenze.

---

## 5. Come gestire o disabilitare gli strumenti

L'utente può cancellare in qualsiasi momento i dati memorizzati nel localStorage tramite le impostazioni del proprio browser (sezione "Cancella dati di navigazione" o equivalente) o tramite gli strumenti di sviluppo del browser.

La cancellazione del token di sessione comporta il logout automatico dall'applicazione.

---

## 6. Aggiornamenti

La presente policy verrà aggiornata in caso di modifiche ai fornitori, introduzione di nuovi strumenti di analytics o marketing, o cambiamenti rilevanti nel funzionamento dell'applicazione.

---

*PitLap — pitlap.app*
*Versione: 1.0 — in vigore dal 2026-06-03*
*Ultimo aggiornamento: 2026-06-03*
