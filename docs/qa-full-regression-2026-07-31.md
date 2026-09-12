# QA Full Regression — PitLap (Flutter web) — 2026-07-31

**Ambiente:** http://localhost:8080 — build dev v0.3.0+
**Utente:** santorello (admin, `g.santoro90@live.it`) — sessione già attiva, nessun logout eseguito
**Browser:** Chrome (MCP), viewport 1280–1456 px + prova responsive a 700 px
**Esito sintetico:** 5 PASS · 10 PARZIALE · 1 FAIL · 0 errori JavaScript in console

---

## 1. Tabella esiti (16 punti del piano)

| # | Area | Esito | Note |
|---|------|-------|------|
| 1 | HOME (`/`) | **PASS** | Saldo PitCoin reale (0 PC), streak, azioni rapide, meteo 4 piste, mappa "20 luoghi", build della settimana, pista del giorno, trending, **classifica PitCoin visibile** (empty state "Classifica in partenza"), feed community. Console pulita. Note: badge `Featured` in inglese, date feed miste IT/EN, banner "Pista del giorno" con ~120 px vuoti sopra il titolo. |
| 2 | PISTE (`/tracks`) | **PARZIALE** | Card "stile A" corrette: overline `BOLOGNA · PISTA RC`, stat row quieta (stato + presenze + discipline), banner ~168 px, CTA arancione **"Sto arrivando"**, cuore preferiti. Filtri città e disciplina OK, ricerca OK. Dettaglio pista: stato, servizi, meteo, presenze, commenti, condividi, preferiti (toggle e un-toggle OK, contatore aggiornato). **Manca la CTA "Sto arrivando" sul dettaglio** e la label disciplina `movimento_terra` è uno slug grezzo. Commento `[QA-REG] test` pubblicato e visibile. |
| 3 | CHECK-IN | **PARZIALE** | Da card → `?intent=arrival`: snackbar "Confermo registrato per oggi", Presenze 0→1, stato personale "Confermato: stai arrivando", orario registrazione. **Nessun controllo per ritirare/annullare l'arrivo** dall'UI (si azzera solo il giorno dopo). |
| 4 | NEGOZI / VICINO A TE / SPOT | **PARZIALE** | Funzionalmente OK (lista, dettaglio per slug, contatti, link e canali, commenti, segui/preferiti, mappa unificata con filtri Piste/Spot/Negozi). Layout card molto diverso da "stile A" e con ampi vuoti; pill **"Shop"** in inglese su card italiane; `1 servizi` (concordanza); marker mappa sovrapposti. |
| 5 | EVENTI (`/events`) | **PARZIALE** | Overline `PARMA · EVENTO` corretto, **nessun tofu nei titoli di sezione della lista**, eventi passati collassati (7). Creato `[QA-REG] Evento regressione` (7 ago, pubblico) → compare in "Prossimi eventi pubblici", condivisione → "Link evento copiato". **"In evidenza" resta "Nessun evento in programma" anche con eventi futuri pubblici presenti.** Sul dettaglio evento compaiono **tofu (▯)** al primo paint. |
| 6 | GARAGE / BUILDS / PROFILES | **PARZIALE** | `/garage` OK (build, foto, azioni). `/builds` mostra 12 build ma la **griglia è disallineata** (banner mancante/di altezza diversa, titoli fuori baseline). `/profiles` OK con ruoli corretti. Concordanze errate: "1 modelli in vetrina", "1 build pubbliche". |
| 7 | PROFILO (`/profile`) | **PARZIALE** | PitCoin card con copy corretto *"Accumulali finché puoi: prima o poi ti serviranno."* ✔; `/profile/activity` carica senza errori (storico vuoto, coerente con 0 PC); panoramica account; preferiti piste → **navigano per slug** ✔. **Assenti su questa pagina: sezione badge, elenco negozi preferiti navigabile e impostazioni di visibilità del profilo pubblico.** |
| 8 | PROFILO PUBBLICO altrui | **PARZIALE** | **Nessun saldo PitCoin** ✔; badge sotto titolo **"Riconoscimenti"** ✔; garage con **icona vettoriale** (non emoji) ✔; ruolo **"Gestore negozio"** ✔ (non "Pilota"). Ma l'header della pagina dice **"Profilo pilota"** anche per uno shop_owner e **l'URL resta `/profiles`** (profilo non deep-linkabile). |
| 9 | NOTIFICHE | **PASS** | `/notifications` carica subito, nessuno spinner infinito, **nessun errore 42703**, console pulita. Tap sulla notifica → naviga alla scheda pista corretta (`/track/pista-collaudo-modena`). |
| 10 | ADMIN (`/admin`) | **PARZIALE** | Dashboard (12 utenti / 13 piste / 8 negozi / 20 eventi / 10 categorie / 0 da approvare), **chip contatore "1 feedback"** ✔, banner "Hai 1 feedback da leggere" ✔, **sezione "Feedback utenti" presente col feedback esistente** ✔, coda approvazioni, gestione utenti/piste/negozi/eventi, categorie. Nessun ruolo modificato. **Deep link diretto a `/admin` reindirizza alla home**; molte label grezze in inglese/DB. |
| 11 | MANAGER (`/manager`) | **PARZIALE** | Pannello gestore OK con piste assegnate, preset rapidi, toggle servizi. Cambio stato **APERTA → BAGNATA → APERTA** eseguito e salvato (snackbar "Aggiornamento pista salvato"); l'aggiornamento **compare nel feed home** ("scheda aggiornata · 1 min fa") ⇒ notifica ai follower generata. **La timeline "Ultimi aggiornamenti" non registra i due salvataggi** (mostra ancora solo l'entry del 27 mag). |
| 12 | FEEDBACK | **PASS** | Pulsante globale in sidebar → dialog "Invia feedback" con email precompilata; inviato `[QA-REG] regression test` → snackbar **"Grazie per il feedback!"** e messaggio presente in Admin › Feedback utenti (con pagina e timestamp). |
| 13 | LEGALE | **PASS** | `/legal/privacy` → **Titolare Giuseppe Santoro (Rho, MI)** ✔ + **sezione "Età minima" (14 anni, art. 8 GDPR)** ✔ + responsabili, trasferimenti extra-UE, conservazione, sicurezza. `/legal/terms` e `/legal/cookies` completi e coerenti. |
| 14 | LOGIN (`/login`) | **PASS** | Magic link + gating consensi (ToS obbligatorio, Privacy obbligatorio, marketing facoltativo), tipo account iniziale, link ai 3 documenti, e **"Continua con Google" sotto il magic link** ✔ (OAuth non avviato). |
| 15 | LAYOUT / ESTETICA | **FAIL** | Vedi §3: doppio header, header incoerente tra pagine, chip filtri tagliati in mobile, bottom nav con 10 voci, griglia /builds disallineata, emoji/tofu diffusi, accenti resi con apostrofo. |
| 16 | DEEP LINK | **PARZIALE** | `/tracks` ✔, `/legal/privacy` ✔, `/profiles` ✔, `/shops` ✔, `/spots` ✔, `/events` ✔, `/notifications` ✔, `/profile` ✔, `/manager` ✔. **`/admin` ✘ → redirect a `/`.** |

---

## 2. Finding numerati

### Blocker
Nessuno. L'app è navigabile end-to-end, nessun crash, nessun errore JS.

### Major

| ID | Pagina | Descrizione | Impatto |
|----|--------|-------------|---------|
| **FR-01** | `/admin` | Aprendo l'URL `/admin` direttamente (o con refresh) l'app reindirizza alla home. Il pannello è raggiungibile **solo** cliccando la voce di sidebar. Probabile race tra il boot del router e il caricamento del ruolo utente. | major |
| **FR-02** | `/events` | La sezione **"In evidenza"** mostra sempre *"Nessun evento in programma al momento"* anche quando esistono eventi pubblici futuri (verificato subito dopo la creazione di `[QA-REG] Evento regressione`, correttamente elencato in "Prossimi eventi pubblici"). | major |
| **FR-03** | Profilo pubblico | Aprendo un profilo da `/profiles` **l'URL non cambia** (resta `/profiles`): il profilo pubblico non è deep-linkabile né condivisibile e il tasto Indietro del browser non ha uno stato coerente. | major |
| **FR-04** | `/builds` | La griglia delle build è **visivamente rotta**: alcune card non hanno banner, altre hanno banner di altezze diverse, i titoli non sono allineati sulla stessa baseline nella stessa riga. | major |
| **FR-05** | `/track/<slug>` | Sul **dettaglio pista manca la CTA "Sto arrivando"** al primo accesso (compare "Iscrivimi"); la sezione "Oggi in pista" dichiara "Non hai ancora segnalato la tua presenza" **senza offrire alcun controllo per farlo**. Il check-in è possibile solo dalla card di lista. | major |
| **FR-06** | `/track/<slug>` | Una volta registrata la presenza **non esiste alcun modo di ritirarla/annullarla** dall'interfaccia. | major |
| **FR-07** | Mobile ~700 px | La **bottom nav espone 10 voci** (Home, Piste, Vicino a te, Spot, Eventi, Negozi, Gestione, Garage, Profilo, Admin) con label a ~10 px: target di tocco sotto la soglia usabile. Va ridotta a 4–5 voci + "Altro". | major |
| **FR-08** | Mobile ~700 px, `/tracks` | La **riga dei chip disciplina viene tagliata a metà** dall'header sticky (testo mozzato) e il campo di ricerca non è visibile: il contenuto scorre sotto l'header senza padding-top adeguato. Stesso difetto attenuato a 1280 px (label "Città" clippata). | major |
| **FR-09** | Tutte le pagine ≠ Home | Esistono **due header diversi**: la Home ha logo-tile + avatar; tutte le altre pagine hanno "PitLap + tagline + IT + `Accesso attivo g.santoro90@live…` + Profilo". Il secondo **espone l'email dell'utente** in chiaro nella chrome dell'app ed è incoerente. In mobile i due header si sommano (doppio "PitLap"). | major |
| **FR-10** | `/manager` | Dopo due salvataggi di stato pista (BAGNATA, poi APERTA) la card **"Ultimi aggiornamenti" non si aggiorna**: continua a mostrare solo l'entry del 27 mag. Il feed home invece riflette correttamente il cambiamento. | major |

### Minor

| ID | Pagina | Descrizione |
|----|--------|-------------|
| **FR-11** | Trasversale | **Accenti resi con apostrofo** in decine di stringhe: `attivita'`, `Identita'`, `arrivera'`, `dovra'`, `gia'`, `Finalita' del trattamento` (privacy), `conformita'` (cookie), `c'e movimento` (eventi). Alcune schermate usano invece l'accento corretto ("Età minima", "Storico attività"): resa incoerente. |
| **FR-12** | `/track/<slug>` | Copy `"1 persone hanno gia' segnalato una presenza possibile per oggi."` — concordanza singolare/plurale errata. Stessa classe: `1 servizi` (/nearby), `1 modelli in vetrina` e `1 build pubbliche` (/garage). |
| **FR-13** | `/track/<slug>` | Chip disciplina: `movimento_terra` mostrato come **slug grezzo**; alcune discipline hanno un'emoji-icona (Buggy, Mini-Z, Scaler, Treni, Bashing) e altre no (francobolli, militare, mini4wd) → set di icone incompleto e incoerente. |
| **FR-14** | `/track/<slug>` | Header pista mostra **"Torino, Italy"** (nome paese in inglese). |
| **FR-15** | `/shops` | La pill sulla card dice **"Shop"** mentre l'overline della stessa card dice `MILANO · NEGOZIO`. Inoltre la CTA "Apri scheda" è nera mentre la CTA piste è arancione: colore primario incoerente tra le liste. |
| **FR-16** | `/nearby` | Overline `BOLOGNA · 🏁 PISTE` — emoji dentro l'overline e plurale, contro lo standard `CITTÀ · PISTA RC` delle card piste. |
| **FR-17** | `/shops`, `/nearby`, `/spots` | Le card orizzontali hanno un'immagine placeholder alta ~220 px che detta l'altezza della card, lasciando **ampie aree vuote** a destra e sotto il blocco testo. |
| **FR-18** | `/admin` | Le label dei ruoli sono **valori DB grezzi** (`user`, `track_organizer`, `shop_owner`, `admin`, chip filtro `track_org`) mentre `/profiles` usa correttamente "Pilota / Organizzatore pista / Gestore negozio". Stessa cosa per gli stati `approved`, `pub`, `public` e per il tipo `Community event` (inglese) accanto a `Evento ufficiale` (italiano). |
| **FR-19** | `/manager` | Le card pista mostrano il **path di routing grezzo** (`/track/pista-rc-test-lorenzo`) e lo **stato in inglese minuscolo** (`open - Pronta per sessioni libere.`). |
| **FR-20** | Profilo pubblico | Titolo della pagina **"Profilo pilota"** anche quando il profilo è di un `shop_owner`/`track_organizer`. |
| **FR-21** | `/event/<uuid>` | Gli eventi sono instradati per **UUID** mentre piste, negozi e spot usano slug leggibili: routing incoerente e URL non condivisibili in modo pulito. |
| **FR-22** | `/spot/<slug>` | Sotto l'H1 (nome dello spot) resta il **sottotitolo generico della pagina lista** ("Mappa sociale dei posti informali…") invece di una descrizione contestuale. |
| **FR-23** | `/profile` | Il campo "Foto profilo (URL)" mostra un **data-URI base64 lunghissimo** nel placeholder, illeggibile. |
| **FR-24** | `/admin` | Il pannello espone in chiaro all'utente **note tecniche di implementazione** (nomi di tabelle Supabase, `is_custom=true`, `owner_id`, view `public_spots`, SharedPreferences). |
| **FR-25** | `/admin` | La lista "Feedback utenti" **non si aggiorna in tempo reale**: il feedback appena inviato è comparso solo dopo aver ricaricato la pagina. |
| **FR-26** | `/shop/<slug>` | Il toggle "segui/preferito" negozio **non mostra snackbar** di conferma, mentre l'equivalente su pista sì. |
| **FR-27** | `/login` | Un utente **già autenticato può raggiungere `/login`** senza redirect. Il pulsante Google mostra una "G" testuale invece del logo Google. |
| **FR-28** | Trasversale | La voce di sidebar attiva **non si aggiorna** su `/builds`, `/notifications`, `/legal/*` e sul profilo pubblico: resta evidenziata "Home". |
| **FR-29** | `/tracks` (1280 px) | Il menu a tendina "Città" si apre a **larghezza piena e viene tagliato dal bordo destro** del viewport. |
| **FR-30** | `/spots/map` | Le etichette dei marker si **sovrappongono** pesantemente e una è troncata dal bordo della mappa. |

### Note / dati

| ID | Descrizione |
|----|-------------|
| **FR-31** | **Emoji tofu (▯) al primo paint** su dettaglio evento (`▯ Community`, `▯ Panoramica evento`), chip admin (`▯ Dashboard`, `▯ Approvazioni`…) e `▯ Build recenti` in Garage. Si risolvono dopo ~2–3 s (font emoji caricato in ritardo) ma sono visibili all'utente. |
| **FR-32** | **Emoji ancora presenti** in: header login 🏁, campo Email ✉, "Tipo di account iniziale" 👤, chip admin 📊✅👥🏁🏪📅, "Gestione negozio" 🏪, "Ingressi rapidi" ⚡, "Meteo pista" 🌤/🌞, "Oggi in pista" 🏁, "Operazioni principali" 📡, "Ultimi aggiornamenti" 📝, "Piste assegnate" 🏁, card Panoramica profilo 🏁🛒📅🔧, "PitCoin" 🪙, "Profilo" 👤, "Informativa Privacy" 🔐, filtri /nearby 🌐🏁🏪, "Featured" ⭐, titoli feed 🎉🟢. |
| **FR-33** | Nessun PitCoin accreditato per check-in e commento eseguiti in sessione (saldo resta 0, storico vuoto). Da verificare se è comportamento voluto. |
| **FR-34** | Dati sporchi in DB dev: negozio "Negozione di Moretti Davide" città **"Parermo"**; spot con città **"Claudia Ferri Città"**; spot "432" con descrizione *"Nuovo spot condiviso dalla community **TrackHub**"* (branding precedente); tag `bashing,buggy` senza spazio; utente "(senza nome)"; disciplina "francobolli"; handle profilo `@91u2e09ada`. |
| **FR-35** | Home: stat "Eventi 0 / 30 giorni" e "Nuovi spot 0 / 30 giorni" restano a 0 anche dopo la creazione di un evento pubblico (finestra temporale probabilmente retrospettiva — da confermare). |
| **FR-36** | Eventi archiviati mostrano solo giorno/mese ("Dom 14 Giu") senza anno. |
| **FR-37** | Formati data misti nel feed home: `27/5/2026`, `05 Aug 2026`, `31 May 2026` (mesi in inglese). |

---

## 3. Layout ed estetica — sintesi

**Coerente e riuscito**
- Card piste "stile A": overline maiuscolo tenue, titolo forte, stat row quieta a icone, banner ~168 px, CTA arancione a larghezza piena, cuore separato. È il pattern migliore dell'app.
- Palette: fondo avorio, superfici bianche, accento arancio, hero scuri. Contrasti dei testi principali adeguati.
- Logo "gomma RC A·bolt" su fondo arancione ben leggibile in header e favicon.
- Pagine legali: tipografia pulita, card ariose, nessun overflow.
- Empty state curati ("Classifica in partenza", "Nessun commento ancora", "Nessun elemento in approvazione").

**Da correggere**
1. **Due sistemi di header** (Home vs resto) e, in mobile, doppio blocco di branding sovrapposto (FR-09).
2. **Chrome che espone l'email** dell'utente in ogni pagina (FR-09).
3. **Tre linguaggi di card** convivono: "stile A" (piste), card orizzontale con placeholder (negozi/spot/nearby), card a griglia (builds/profili). Colori CTA incoerenti (arancio vs nero).
4. **Emoji come icone di sezione** in gran parte dell'app, con tofu al primo render: sostituire con l'icon set vettoriale già usato altrove (FR-31, FR-32).
5. **Content scrolling sotto header sticky** senza padding: label e chip tagliati a metà, sia a 700 px sia a 1280 px (FR-08).
6. **Bottom nav a 10 voci** in mobile (FR-07).
7. **Griglia /builds** non allineata (FR-04).
8. **Vuoti strutturali**: banner "Pista del giorno" con ~120 px liberi sopra il titolo; card negozio/spot con metà destra vuota; `/profile/activity` con testo centrato in una pagina altrimenti vuota.
9. **Accenti resi con apostrofo** in tutta l'app, incluse le pagine legali (FR-11).
10. Snackbar a piena larghezza che scorrono anche sotto la sidebar.

---

## 4. Errori console

`read_console_messages(onlyErrors: true)` eseguito dopo **ogni** pagina (home, tracks, dettaglio pista, shops, dettaglio negozio, nearby, mappa, spots, dettaglio spot, events, dettaglio evento, garage, builds, profiles, profile, profile/activity, notifications, admin, manager, legal ×3, login):

> **Nessun errore o eccezione rilevata su nessuna pagina.**
> In particolare: **nessun errore 42703** su `/notifications` (regressione precedente chiusa), nessun errore su salvataggio stato pista, invio commento, check-in, creazione evento e invio feedback.

---

## 5. Dati di test creati ([QA-REG]) — da ripulire

| # | Tipo | Contenuto | Dove |
|---|------|-----------|------|
| 1 | Commento pista | `[QA-REG] test` — autore santorello | `/track/drift-park-torino` (tabella commenti) |
| 2 | Evento pubblico | `[QA-REG] Evento regressione` — Bologna, 7 ago 2026, nota "Test regressione QA" — UUID `43f55c7a-0918-40eb-ae4f-a617abd85a54` | `community_events` |
| 3 | Feedback | `[QA-REG] regression test` — 31/07/2026 22:42, da `g.santoro90@live.it`, pagina `/manager` | tabella feedback (visibile in Admin › Feedback utenti) |
| 4 | Presenza pista | Check-in "confermato" su **Drift Park Torino** del 31/07/2026 | si azzera automaticamente il giorno successivo — nessuna pulizia necessaria |
| 5 | Stato pista | **Pista RC Test Lorenzo**: APERTA → BAGNATA → **APERTA (ripristinato)** — 2 notifiche ai follower generate | stato già riportato all'originale |
| 6 | Preferiti | Drift Park Torino rimosso e **ri-aggiunto** ai preferiti; RC Parts Parma seguito e **rimosso** | stato originale ripristinato |

---

## Layer tecnico (audit DB/infra, 2026-07-31)

**Advisor security:**
- **ERROR risolto in sessione**: `public_user_pitcoin` era tornata SECURITY DEFINER (il CREATE OR REPLACE del delta privacy aveva perso `security_invoker`). Corretta con `alter view … set (security_invoker = on)` — applicata su dev e aggiunta al delta `2026-07-29-pitcoin-privacy.sql`.
- WARN sui SECURITY DEFINER esposti (is_admin, follower counts, complete_onboarding, report_comment, ecc.): tutti **intenzionali**, censiti in `db-hardening-2026-06-10.md`.
- **Leaked Password Protection ancora OFF** — TODO dashboard (dev+prod).

**Edge function `submit-feedback`:** 3 invocazioni POST, tutte 200 (787–1640 ms), zero errori Resend nei log. Secret attivo (deploy v2).

**Tabella `feedback`:** insert guest e autenticato verificati; riga QA del giro precedente ripulita.

*Report generato al termine della sessione di regressione del 31/07/2026 (browser agent + audit tecnico).*

---

## Correzioni applicate (2026-07-31)

Intervento client-only (Flutter/Dart). Nessuna modifica a DB/RLS. Dopo le modifiche agli ARB è NECESSARIO che l'utente lanci `run_dev.bat gen-l10n` (vedi chiavi nuove in fondo): i getter generati non esistono finché non viene rigenerato.

### Funzionale
- **FR-01 — FIXED.** Race router↔ruolo su deep-link `/admin`. Aggiunto `roleLoadedProvider` (`features/auth/application/auth_providers.dart`) e i guard `requireAdmin/requireTrackManager/requireShopManager` non reindirizzano più finché il ruolo non è noto (`app/navigation/app_router.dart`).
- **FR-02 — FIXED.** "In evidenza" vuota: gli eventi creati dagli utenti vivono in `community_events` (senza colonna visibility), mentre il provider leggeva solo `events`. `fetchUpcomingPublicEvents` ora unisce anche i `community_events` futuri (`features/events/application/public_events_provider.dart`).
- **FR-05 — FIXED.** CTA dettaglio pista: la label era invertita (mostrava "Iscrivimi"). Ora è "Sto arrivando" finché non si segnala la presenza, e "Arrivo segnato" quando è già `coming` (`features/tracks/presentation/track_detail_screen.dart`).
- **FR-06 — FIXED.** L'annullamento presenza era già disponibile nel bottom sheet ("Annulla" → status `cancelled`); ora è raggiungibile perché la CTA riapre il sheet nello stato corretto. Stesso file.
- **FR-10 — FIXED.** Timeline "Ultimi aggiornamenti" non aggiornata: l'insert in `track_status_history` ometteva `updated_at`; con l'ordinamento `updated_at DESC NULLS LAST` le righe nuove finivano oltre il `limit(8)`. Ora l'insert valorizza `updated_at` (`features/tracks/infrastructure/supabase_tracks_repository.dart`). L'`invalidate` del provider era già presente.
- **FR-26 — FIXED.** Snackbar di conferma sul toggle segui/preferito negozio, allineato alla pista (`features/shops/presentation/shop_detail_screen.dart` + chiavi ARB `followShopSaved/followShopRemoved`).
- **FR-27 — FIXED.** Utente autenticato su `/login` reindirizzato a `redirect` o `/` (`app/navigation/app_router.dart`); icona pulsante Google `Icons.g_mobiledata` → `Icons.login` (`features/auth/presentation/login_screen.dart`).
- **FR-28 — FIXED.** Mapping voce sidebar attiva esteso: `/builds`→Garage, `/profiles` e `/u/`→Profilo; per rotte senza voce (`/notifications`, `/legal/*`) il NavigationRail non evidenzia più "Home" (`core/widgets/app_scaffold.dart`).

### Privacy / UX header
- **FR-09 — FIXED.** Rimossa l'email utente in chiaro dall'header secondario; resta solo la pill "Accesso attivo" (`core/widgets/content_scaffold_header.dart`).
- **FR-20 — FIXED.** Titolo profilo pubblico dinamico sul ruolo (Organizzatore / Gestore negozio / Staff / Pilota) (`features/profile/presentation/public_profile_screen.dart`).
- **FR-03 — DEFERRED.** Profilo pubblico non deep-linkabile (URL resta `/profiles`): richiede refactor del routing (navigazione da lista a `/u/:publicSlug`). Non affrontato per non introdurre regressioni di routing.

### Copy / i18n
- **FR-11 — FIXED.** Passata mirata di correzione accenti resi con apostrofo (attività, identità, già, dovrà, arriverà, finalità, conformità, perché, può, città, ecc.) su ARB e stringhe `.dart`, con word-boundary. (Nota: la passata ha inizialmente rotto alcune stringhe dove l'apostrofo era il delimitatore di stringa / chiave di mappa — tutte individuate e corrette: `Identità`, `novità`, e le chiavi `map['meta']` in home_dashboard/public_builds/public_profile/user_build.)
- **FR-12 — FIXED.** Concordanze singolare/plurale: `garageBuildsCount`, `garagePublicBuildsCount`, `nearbyServicesCount` convertite a ICU plural; presenze pista con forma condizionale (`track_detail_screen.dart`). Il conteggio negozio era già condizionale.
- **FR-13 — FIXED.** `_CategoryTag` (dettaglio pista): fallback slug → title-case, aggiunte discipline mancanti (movimento_terra, militare, mini4wd, francobolli), rimosse emoji dalle label.
- **FR-14 — FIXED.** Header pista: il paese "Italy/Italia" non viene più mostrato (solo città); paese mostrato solo se estero (`track_detail_screen.dart`).
- **FR-15 — FIXED.** Card negozio: pill "Shop"→"Negozio"; CTA "Apri scheda" ora arancione come le piste (`features/shops/presentation/shops_screen.dart`).
- **FR-16 — FIXED.** `/nearby`: overline senza emoji e al singolare ("PISTA RC" / "NEGOZIO" via `nearbyBadgeTrack/Shop`), emoji rimosse dai chip filtro (`features/discovery/presentation/nearby_screen.dart`).
- **FR-18 — FIXED.** `/admin`: etichette leggibili per ruoli/stati/visibilità e tipo evento ("Evento community"), via helper `adminRoleLabel/adminApprovalLabel/adminVisibilityLabel` (`features/admin/presentation/admin_settings_screen.dart`).
- **FR-19 — FIXED.** `/manager`: rimosso il path grezzo `/track/<slug>` dalla card e stato localizzato (non più "open - ...") (`features/manager/presentation/manager_screen.dart`).
- **FR-36 — FIXED.** Anno aggiunto al formato data eventi (`public_events_provider.dart`, `profile_hub_providers.dart`).
- **FR-37 — PARZIALE (client FIXED).** Il formato client (`_relativeTimeLabel`) è ora `gg/mm/aaaa` con zero-padding (`community_home_screen.dart`). I formati inglesi ("05 Aug 2026") provengono da `subtitle` salvati lato DB nel feed: DEFERRED (dato, non client).

### Emoji (FR-31 / FR-32) — FIXED
- Rimosse le emoji-icona in testa alle stringhe di sezione (49 occorrenze in 12 file: admin, manager, profile, events, tracks, shops, submissions, login, garage, pitcoin, content_scaffold_header). Mantenute le ⚠️ dei warning.
- Convertite in `Icon` vettoriali le emoji-icona standalone della card "Panoramica" e dei "Collegamenti" profilo (`profile_screen.dart`).
- Header login "Lap 🏁"→"Lap"; badge "Featured"→"In evidenza" (`community_home_screen.dart`).

### Layout minore
- **FR-22 — FIXED.** `/spot/<slug>`: descrizione contestuale (nota/città) invece del sottotitolo generico (`features/spots/presentation/spot_detail_screen.dart`).
- **FR-23 — FIXED.** `/profile`: il campo "Foto profilo (URL)" non riversa più il data-URI base64; le immagini caricate restano fuori dal campo con nota "Immagine caricata" e anteprima intatta (`profile_screen.dart`).
- **FR-24 — FIXED.** `/admin`: rimossa la card di note tecniche (nomi tabelle, is_custom, owner_id, view public_spots, SharedPreferences) e la classe `_InfoBanner` orfana (`admin_settings_screen.dart`).
- **FR-29 — FIXED.** `/tracks`: dropdown "Città" vincolato a `maxWidth: 360` + `isExpanded` (`tracks_home_screen.dart`).

### Deferiti / non affrontati
- **FR-03** (deep-link profilo pubblico), **FR-04** (griglia builds), **FR-07** (bottom nav 10 voci → overflow), **FR-08** (padding sotto header sticky), **FR-17** (unificazione sistemi card), **FR-21** (routing eventi per slug), **FR-25** (feedback realtime), **FR-30** (overlap marker mappa), **FR-33 / FR-35** (logica PitCoin/statistiche): DEFERRED — richiedono refactor o scelte di prodotto/DB.
- **FR-34 — N/A.** Dati sporchi in DB dev (pulizia dati, non codice).

### Chiavi ARB nuove (richiedono `gen-l10n`)
- `followShopSaved` / `followShopRemoved` (placeholder `shopName`)
- `nearbyBadgeTrack` / `nearbyBadgeShop`
- (`garageBuildsCount` invariato come chiave ma ora con metadata `count:int` + forma plural; `garagePublicBuildsCount` e `nearbyServicesCount` convertite a plural — nessun cambio di firma)

**Validazione ARB:** `app_it.arb` e `app_en.arb` validati come JSON (OK) dopo ogni modifica.
