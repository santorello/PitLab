# Protocollo di test locale — PitLap v0.1.9+

*Da eseguire dopo hot restart pulito (non hot reload).*
*Dispositivo: Chrome (web) + emulatore Android o device fisico.*

---

## Setup

```bash
cd app
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://mqieterttnqdtdguaqoe.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<anon_key>
```

Oppure su Android:
```bash
flutter run -d <device_id> \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=...
```

---

## 1. Utente non autenticato

| # | Azione | Atteso | OK? |
|---|---|---|---|
| 1.1 | Apri l'app | Home con lista piste (Parma, Modena, Lainate, RE, Mantova) | |
| 1.2 | Cerca "Parma" nella barra di ricerca | Solo pista Parma visibile | |
| 1.3 | Filtra per categoria "buggy" | Solo piste buggy | |
| 1.4 | Apri dropdown Città → seleziona "Modena" | Solo pista Modena | |
| 1.5 | Resetta tutti i filtri | Tutte e 5 le piste | |
| 1.6 | Clicca su una pista | Schermata dettaglio con meteo 3 giorni | |
| 1.7 | Verifica che il meteo mostri badge "live" (non "stima") per piste con coordinate | Badge presente | |
| 1.8 | Premi Back → clicca "Spots" nel nav | Lista spot | |
| 1.9 | Clicca "Mappa" | Mappa unificata con marker arancio (piste) e blu/grafite (spot) | |
| 1.10 | Tocca un marker pista | Pannello destro mostra nome pista, città, stato, bottone "Apri pista" | |
| 1.11 | Tocca un marker spot | Pannello destro mostra dettaglio spot, bottone "Apri spot" | |
| 1.12 | Toggle "Piste" → disabilita | Marker piste spariscono dalla mappa | |
| 1.13 | Toggle "Spot" → disabilita | Marker spot spariscono dalla mappa | |
| 1.14 | "Adatta vista" | Mappa si centra sui marker visibili | |
| 1.15 | Naviga a `/questa-route-non-esiste` | Pagina 404 on-brand con bottone "Torna alla home" | |
| 1.16 | Clicca "Torna alla home" dalla 404 | Torna alla home senza errori | |
| 1.17 | Prova ad accedere a `/garage` senza login | Redirect a `/login` | |
| 1.18 | Prova ad accedere a `/admin` senza login | Redirect a `/login` | |

---

## 2. Login

| # | Azione | Atteso | OK? |
|---|---|---|---|
| 2.1 | Clicca login | Schermata login | |
| 2.2 | Login con Google | Redirect corretto, nessun errore di callback | |
| 2.3 | **Verifica chiave**: dopo il login, la nav bar si aggiorna (Garage, Profilo appaiono) **senza** richiedere un secondo tap | Aggiornamento immediato | |
| 2.4 | Il ruolo nell'header è corretto (user / track_organizer / admin) | Sì | |

> ⚠️ **2.3 è il test più importante** — verifica che il fix GoRouter `refreshListenable` funzioni. Nella versione precedente serviva un tap extra dopo il login.

---

## 3. Flusso pilota — Pista & Arrivals

| # | Azione | Atteso | OK? |
|---|---|---|---|
| 3.1 | Apri dettaglio pista Parma | Schermata dettaglio completa | |
| 3.2 | Premi "Sto arrivando" | Dialog / bottom sheet arrivo | |
| 3.3 | Seleziona stato (es. "In arrivo") e conferma | Check-in salvato, contatore presenze aggiornato | |
| 3.4 | Apri la stessa pista da un'altra scheda browser | Verificare che il contatore rifletta il check-in (fetch sincrono — per ora non realtime) | |
| 3.5 | Premi "Non ci vado più" / annulla | Stato rimosso | |

---

## 4. Garage

| # | Azione | Atteso | OK? |
|---|---|---|---|
| 4.1 | Naviga a Garage | Lista build da Supabase | |
| 4.2 | Aggiungi una build | Appare in lista con ID temporaneo poi UUID Supabase | |
| 4.3 | Modifica visibility (pubblica/privata) | Cambia senza ricaricare | |
| 4.4 | Elimina build | Rimossa dalla lista e da Supabase | |

---

## 5. Profilo

| # | Azione | Atteso | OK? |
|---|---|---|---|
| 5.1 | Naviga a Profilo | Dati da Supabase | |
| 5.2 | Modifica display name | Salvato | |
| 5.3 | Abilita profilo pubblico con slug | Attiva | |
| 5.4 | Naviga a `/u/<tuo-slug>` | Profilo pubblico accessibile anche in incognito | |
| 5.5 | Aggiungi evento community | Appare nella lista con ottimismo UI poi UUID reale | |
| 5.6 | Aggiungi link esterno a un'entità | Salvato su Supabase | |

---

## 6. Spots

| # | Azione | Atteso | OK? |
|---|---|---|---|
| 6.1 | Naviga a Spots → lista | Spot da Supabase (almeno 3 default) | |
| 6.2 | Segnala nuovo spot | Form, salva su Supabase | |
| 6.3 | Spot appare nella lista | Sì | |
| 6.4 | Spot appare nella mappa unificata | Sì, con marker blu | |

---

## 7. Gestione (track_organizer / admin)

| # | Azione | Atteso | OK? |
|---|---|---|---|
| 7.1 | Naviga a Gestione | Lista piste assegnate | |
| 7.2 | Apri editor pista assegnata | Campi precompilati | |
| 7.3 | Modifica stato giornaliero (preset rapido) | Salvato, timeline aggiornata | |
| 7.4 | Pista in stato "draft" ha bottone Modifica | Sì | |
| 7.5 | Crea nuova pista | Form vuoto, submission a Supabase come `pending` | |

---

## 8. Admin

| # | Azione | Atteso | OK? |
|---|---|---|---|
| 8.1 | Naviga a Admin | Dashboard | |
| 8.2 | Apri editor pista **non assegnata all'admin** | Schermata carica correttamente (fix admin fallback) | |
| 8.3 | Apri pannello Utenti | Lista utenti paginata | |
| 8.4 | Hover/tap sull'icona "Osserva" di un utente | Tooltip mostra "⚠️ Solo UI — non modifica JWT né policy RLS" | |
| 8.5 | Clicca "Osserva" su un utente con ruolo diverso | SnackBar con nota "Solo UI, JWT e RLS invariati" (3 s) | |
| 8.6 | Banner impersonificazione appare in alto | Sì, con bottone "Stop" | |
| 8.7 | Premi "Stop" | Banner sparisce, ruolo reale ripristinato | |
| 8.8 | Admin Settings → sezione Garage | Testo "su Supabase" (non "locale") | |
| 8.9 | Admin Settings → sezione Community Events | Presente, "su Supabase" | |
| 8.10 | Admin Settings → sezione Link esterni | Presente, "su Supabase" | |

---

## 9. Edge case & regressioni

| # | Azione | Atteso | OK? |
|---|---|---|---|
| 9.1 | Logout → Garage → Login | Nessuna exception "uninitialized provider" in console | |
| 9.2 | Logout → Admin → Login | Nessuna exception in console | |
| 9.3 | Navigare rapidamente tra tab durante il caricamento | Nessun crash | |
| 9.4 | Aprire mappa con 0 spot visibili (toggle off spot) e toccare un marker pista | Pannello dettaglio mostra la pista correttamente | |
| 9.5 | Navigare a `/track/slug-inesistente` | Schermata errore o 404 (no crash) | |
| 9.6 | Accedere a `/manager` come `user` normale | Redirect a home | |

---

## 10. Verifica console (DevTools)

Apri Chrome DevTools → Console durante i test. **Non devono apparire:**

- `Tried to read the state of an uninitialized provider`
- `RenderFlex overflowed`
- Eccezioni Supabase non gestite (es. 401, 403 inattesi)
- Errori di routing GoRouter

---

## Riepilogo esito

| Area | Stato | Note |
|---|---|---|
| Home + filtri | | |
| Mappa unificata | | |
| 404 | | |
| Login / GoRouter | | |
| Arrivals | | |
| Garage | | |
| Profilo | | |
| Spots | | |
| Gestione | | |
| Admin | | |
| Console pulita | | |

---

*Protocollo generato per PitLap v0.1.9+ · aprile 2026*
