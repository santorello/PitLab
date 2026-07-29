# Informativa sul trattamento dei dati personali (Privacy Policy)

**Versione: 1.0 — in vigore dal 2026-06-03**
**Ultimo aggiornamento: 2026-06-03**

---

## 1. Titolare del trattamento

Il titolare del trattamento dei dati personali raccolti tramite PitLap è:

**Giuseppe [COGNOME — DA COMPLETARE]**
Comune di Rho (MI), Italia
Email privacy: privacy@pitlap.app

**Responsabile della Protezione dei Dati (DPO):** non nominato. La nomina di un DPO non è obbligatoria per la presente scala di trattamento ai sensi dell'art. 37 del Regolamento (UE) 2016/679 (GDPR). Il punto di contatto per qualunque questione relativa alla protezione dei dati personali è l'indirizzo email indicato sopra.

---

## 2. Ambito del servizio

PitLap (pitlap.app) è una piattaforma digitale dedicata alla community del modellismo radiocomandato (RC). Il servizio è attualmente in fase di **beta chiusa su invito** e comprende:

- consultazione di piste, negozi, eventi e contenuti informativi
- accesso utente tramite email e magic link
- profilo utente con nickname, città di riferimento, foto e preferenze
- check-in "Sto arrivando": segnalazione della presenza giornaliera in pista
- garage personale con build, modelli e foto
- sistema di reputazione PitCoin
- follow di altri utenti
- contenuti pubblici creati dagli utenti (build, spot, eventi, link)

---

## 3. Categorie di dati trattati

### 3.1 Dati account

- Indirizzo email (necessario per accesso tramite magic link)
- Identificativo utente tecnico (UUID generato da Supabase Auth)
- Data di creazione dell'account e metadati di sessione

### 3.2 Dati profilo

- Nome visibile / nickname
- Città di riferimento
- Coordinate geografiche "home" (opzionali, fornite dall'utente)
- Foto avatar, cover e immagini del garage (caricate volontariamente dall'utente)

### 3.3 Contenuti pubblicati dall'utente

- Build e descrizioni del garage
- Piste, negozi, spot e eventi inseriti o proposti
- Link pubblicati
- Contenuti testuali e fotografici resi pubblici su scelta dell'utente

### 3.4 Dati di utilizzo del servizio

- Check-in "Sto arrivando" (pista + data)
- Relazioni di follow tra utenti
- Preferiti e contenuti salvati

### 3.5 Dati tecnici e di sicurezza

- Log tecnici applicativi (rotazione automatica, conservati per 90 giorni)
- Informazioni necessarie alla sicurezza, all'integrità del sistema e alla prevenzione di abusi

### 3.6 Dati relativi ai consensi

- Accettazione dei Termini di Servizio (con timestamp e versione documento)
- Presa visione della presente Informativa Privacy (con timestamp e versione documento)
- Eventuale consenso marketing via email (attualmente non raccolto durante la beta — vedi § 11)

---

## 4. Finalità del trattamento

### 4.1 Creazione e gestione dell'account

Consentire l'accesso al servizio, la gestione della sessione e la configurazione dell'account.
**Base giuridica:** esecuzione di un contratto o misure precontrattuali (art. 6 §1 lett. b GDPR).

### 4.2 Erogazione delle funzionalità richieste

Mostrare contenuti, gestire il profilo, il garage, i check-in, il sistema di follow e le funzionalità community.
**Base giuridica:** esecuzione di un contratto (art. 6 §1 lett. b GDPR).

### 4.3 Sicurezza, manutenzione e prevenzione degli abusi

Monitorare il corretto funzionamento, prevenire utilizzi impropri e proteggere l'integrità della piattaforma.
**Base giuridica:** legittimo interesse del titolare (art. 6 §1 lett. f GDPR).

### 4.4 Adempimenti documentali e di conformità

Tracciare consensi e prese visione per dimostrare la conformità normativa.
**Base giuridica:** obbligo legale (art. 6 §1 lett. c GDPR) e legittimo interesse.

### 4.5 Comunicazioni marketing via email (sospese durante la beta)

Per inviare aggiornamenti, novità o comunicazioni promozionali relative a PitLap. **Questa finalità è attualmente sospesa: durante la beta chiusa nessuna email marketing viene inviata e il relativo opt-in non viene raccolto.** Quando il marketing verrà attivato, sarà richiesto un consenso separato, specifico e revocabile in qualsiasi momento.
**Base giuridica (futura):** consenso dell'interessato (art. 6 §1 lett. a GDPR).

---

## 5. Conferimento dei dati

Il conferimento dell'indirizzo email e dei dati tecnici di sessione è necessario per accedere al servizio. Il mancato conferimento rende impossibile la creazione dell'account.

I dati di profilo aggiuntivi (nickname, città, coordinate home, foto), i contenuti del garage e le altre informazioni facoltative possono essere conferiti in modo progressivo su scelta dell'utente.

---

## 6. Profilo pubblico, garage e visibilità

PitLap adotta un approccio di privacy by default:

- Il profilo pubblico è disattivato di default; l'utente può renderlo visibile esplicitamente.
- Il garage rimane privato di default; singole build possono essere rese pubbliche su scelta.
- I contenuti pubblici possono essere visibili agli utenti autenticati secondo le regole di visibilità del prodotto.
- I check-in "Sto arrivando" sono visibili agli utenti autenticati per la giornata corrente.

---

## 7. Destinatari dei dati e sub-responsabili del trattamento

I dati personali possono essere comunicati ai seguenti fornitori che operano come responsabili del trattamento (art. 28 GDPR):

| Fornitore | Ruolo | Paese/Sede | Garanzia di trasferimento |
|---|---|---|---|
| **Supabase** | Backend: autenticazione, database Postgres, storage immagini | Germania (eu-central-1, Francoforte) — **UE** | Dati ospitati nell'UE; nessun trasferimento extra-SEE per il progetto pitlap-prod |
| **MapTiler** | Mappe interattive e geocoding (richieste lato dispositivo dell'utente) | Svizzera | Paese terzo con decisione di adeguatezza della Commissione UE; ove applicabile: Clausole Contrattuali Standard (SCC) |
| **Open-Meteo** | Previsioni meteo per le piste outdoor; riceve coordinate o nome della città | Austria — **UE** | Dati ospitati nell'UE |
| **Sentry** (crash reporting) | Eventuale: non ancora attivo. Sarà incluso in un aggiornamento di questa informativa se e quando attivato. | — | — |

MapTiler riceve l'indirizzo IP del dispositivo dell'utente e la query geografica direttamente dal client al momento della visualizzazione delle mappe o del geocoding. Si applicano le [condizioni di utilizzo](https://www.maptiler.com/cloud/pricing/) e la privacy policy di MapTiler.

Open-Meteo riceve coordinate geografiche o il nome della città per restituire le previsioni meteo. Si applicano i [termini di Open-Meteo](https://open-meteo.com/en/terms).

---

## 8. Trasferimenti di dati extra-SEE

I dati archiviati su Supabase risiedono nella regione UE (Francoforte, Germania) e non vengono trasferiti al di fuori dello Spazio Economico Europeo.

MapTiler è una società svizzera: la Svizzera beneficia di una decisione di adeguatezza della Commissione europea. Ove applicabile, il trasferimento è ulteriormente garantito da Clausole Contrattuali Standard.

Open-Meteo opera in Austria, Paese UE: nessun trasferimento extra-SEE.

---

## 9. Periodi di conservazione

| Categoria di dati | Periodo di conservazione |
|---|---|
| Dati account e profilo | Per tutta la durata dell'account attivo + 30 giorni dalla richiesta di cancellazione |
| Foto e contenuti pubblicati | Finché pubblicati o fino alla cancellazione da parte dell'utente (o dell'account) |
| Check-in "Sto arrivando" | Storicizzati e ripuliti automaticamente tramite upsert giornaliero; il dato corrente viene sostituito ogni giorno |
| Log tecnici | 90 giorni (rotazione automatica) |
| Dati dei consensi | Per tutta la durata dell'account + il tempo necessario a dimostrare la conformità (almeno 5 anni a fini difensivi) |
| Dati di sessione (token) | Durata della validità del token di sessione Supabase |

---

## 10. Minori

PitLap è riservato a utenti che abbiano compiuto **14 anni di età**. Questa soglia è stabilita in conformità all'art. 8 del GDPR e all'art. 2-quinquies del D.Lgs. 196/2003 (Codice Privacy italiano, come modificato dal D.Lgs. 101/2018).

Nella fase di **beta chiusa**, l'accesso avviene esclusivamente su invito; gli inviti sono riservati a persone maggiori di 14 anni.

Se il titolare dovesse accertare che un utente è minore di 14 anni, l'account sarà sospeso e i dati cancellati senza indugio.

---

## 11. Marketing via email

Le comunicazioni marketing sono facoltative e non necessarie per creare o utilizzare l'account.

**Durante la fase di beta chiusa il marketing via email è sospeso: nessuna email promozionale viene inviata e l'opt-in non viene raccolto.** Questo approccio garantisce il rispetto dell'art. 7 §3 GDPR by design.

Quando il marketing verrà attivato:
- sarà richiesto un consenso separato, specifico, non preselezionato e revocabile;
- sarà possibile revocare il consenso in qualsiasi momento tramite l'apposita funzione in-app;
- il consenso sarà tracciato con stato, timestamp, versione del documento e origine.

---

## 12. Diritti dell'interessato

L'utente può esercitare, in qualsiasi momento, i seguenti diritti ai sensi degli artt. 15–22 GDPR:

- **Accesso** ai propri dati personali
- **Rettifica** dei dati inesatti o incompleti
- **Cancellazione** ("diritto all'oblio"), nei casi previsti — disponibile in-app tramite la funzione "Richiedi cancellazione account" (`request_account_deletion`)
- **Limitazione** del trattamento
- **Opposizione** al trattamento basato su legittimo interesse
- **Portabilità** dei dati, ove applicabile
- **Revoca del consenso** in qualsiasi momento, senza pregiudicare la liceità del trattamento basato sul consenso prestato prima della revoca

Per esercitare questi diritti, l'utente può scrivere a: **privacy@pitlap.app**

L'utente ha inoltre il diritto di proporre **reclamo al Garante per la protezione dei dati personali** (Autorità di controllo italiana): [www.garanteprivacy.it](https://www.garanteprivacy.it)

---

## 13. Decisioni automatizzate e profilazione

PitLap non effettua processi decisionali automatizzati con effetti giuridici o analogamente significativi nei confronti dell'utente. Il sistema PitCoin è un indicatore di reputazione comunitaria basato su interazioni esplicite dell'utente, non su profilazione comportamentale automatizzata.

Se in futuro venissero introdotti elementi di profilazione rilevante, questa sezione verrà aggiornata con le informazioni previste dall'art. 22 GDPR.

---

## 14. Aggiornamenti dell'informativa

La presente informativa può essere aggiornata nel tempo. Le modifiche rilevanti saranno comunicate agli utenti tramite avviso in-app o email, ove opportuno. Ogni versione riporta la data di efficacia e il numero di versione.

Lo storico delle versioni è disponibile su richiesta scrivendo a privacy@pitlap.app.

---

*PitLap — pitlap.app*
*Versione: 1.0 — in vigore dal 2026-06-03*
*Ultimo aggiornamento: 2026-06-03*
