# Registro dei consensi (Consent Register)

**Versione: 1.0 — in vigore dal 2026-06-03**
**Ultimo aggiornamento: 2026-06-03**

---

## Scopo del documento

Questo documento definisce:
- quali consensi e prese visione esistono nel servizio PitLap
- la distinzione tra elementi necessari al servizio ed elementi facoltativi
- le modalità di tracciatura tecnica su database
- lo stato operativo durante la fase di beta chiusa

---

## 1. Elementi tracciati al primo accesso

### 1.1 Accettazione dei Termini di Servizio (`terms_accepted`)

| Attributo | Valore |
|---|---|
| Tipo | Condizione necessaria al servizio (non è un "consenso" ai sensi dell'art. 6 §1 lett. a GDPR, ma un atto di accettazione contrattuale) |
| Obbligatorio | Sì — senza accettazione non è possibile utilizzare il servizio autenticato |
| Pre-selezionato | No — richiede azione attiva dell'utente |
| Revocabile | Sì, tramite cancellazione dell'account |
| Versione tracciata | Sì |
| Timestamp tracciato | Sì |
| Origine tracciata | Sì (`source`) |

### 1.2 Presa visione dell'Informativa Privacy (`privacy_notice_seen`)

| Attributo | Valore |
|---|---|
| Tipo | Presa visione (non è un consenso al trattamento; la base giuridica del trattamento essenziale è l'esecuzione del contratto) |
| Obbligatorio | Sì — la presa visione viene registrata al primo accesso |
| Pre-selezionato | No — richiede azione attiva dell'utente |
| Revocabile | N/A (la presa visione è un fatto storico; l'utente può esercitare i diritti previsti dal GDPR) |
| Versione tracciata | Sì |
| Timestamp tracciato | Sì |
| Origine tracciata | Sì (`source`) |

---

## 2. Consensi facoltativi

### 2.1 Consenso marketing via email (`marketing_email_opt_in`)

| Attributo | Valore |
|---|---|
| Tipo | Consenso facoltativo (art. 6 §1 lett. a GDPR) |
| Obbligatorio | No — non condiziona la creazione o l'uso dell'account |
| Pre-selezionato | No |
| **Stato durante la beta chiusa** | **SOSPESO: l'opt-in marketing non viene raccolto e nessuna email promozionale viene inviata.** Questo approccio soddisfa by design l'obbligo di revoca facile previsto dall'art. 7 §3 GDPR. |
| Revocabile | Sì — in qualsiasi momento tramite funzione in-app (da implementare prima dell'attivazione del marketing) |
| Versione tracciata | Sì |
| Timestamp tracciato | Sì |
| Origine tracciata | Sì |

**Nota operativa:** quando il marketing verrà attivato, sarà obbligatorio implementare la revoca in-app nel flusso del profilo utente prima del go-live. Il campo `marketing_email_opt_in` è già presente nello schema del database ma deve rimanere non raccolto finché il canale marketing non è operativo.

---

## 3. Struttura tecnica di tracciatura

Ogni riga nella tabella `public.user_consents` deve contenere i seguenti campi:

| Campo | Tipo | Descrizione |
|---|---|---|
| `user_id` | UUID | Identificativo utente |
| `consent_type` | text | Tipo di consenso/presa visione (vedi § 4) |
| `accepted` | boolean | Stato: `true` = accettato/visionato, `false` = rifiutato/revocato |
| `document_version` | text | Versione del documento accettato (es. `"1.0"`) |
| `timestamp` | timestamptz | Data e ora dell'azione |
| `source` | text | Origine (es. `"onboarding_web"`, `"onboarding_android"`, `"profile_settings"`) |

La struttura è **versionata e append-only**: ogni modifica dello stato di un consenso produce una nuova riga, consentendo l'audit trail completo.

---

## 4. Tipi di consenso/presa visione definiti

| `consent_type` | Descrizione | Obbligatorio |
|---|---|---|
| `terms_accepted` | Accettazione Termini di Servizio | Sì |
| `privacy_notice_seen` | Presa visione Informativa Privacy | Sì |
| `marketing_email_opt_in` | Consenso email marketing | No (sospeso in beta) |

---

## 5. Stato di implementazione

| Elemento | Implementato | Note |
|---|---|---|
| Tabella `public.user_consents` | Sì | |
| Tracciatura `terms_accepted` | Sì | |
| Tracciatura `privacy_notice_seen` | Sì | |
| Tracciatura `document_version` | Sì | |
| Tracciatura `source` | Sì | |
| Riepilogo consensi nel profilo utente | Sì | |
| Revoca `marketing_email_opt_in` in-app | Da completare | Prima dell'attivazione del marketing |
| Opt-in marketing (raccolta) | Non attivo — sospeso in beta | |

---

## 6. Principi di governance

- I consensi facoltativi non condizionano mai l'accesso alle funzionalità essenziali del servizio.
- L'interfaccia di onboarding distingue chiaramente gli elementi obbligatori (accettazione ToS + presa visione Privacy) dagli elementi facoltativi.
- Nessun consenso facoltativo è pre-selezionato.
- La revoca di un consenso facoltativo deve essere altrettanto semplice della sua raccolta (art. 7 §3 GDPR).
- I dati dei consensi vengono conservati per tutta la durata dell'account e per il periodo necessario a dimostrare la conformità (almeno 5 anni a fini difensivi).

---

*PitLap — pitlap.app*
*Versione: 1.0 — in vigore dal 2026-06-03*
*Ultimo aggiornamento: 2026-06-03*
