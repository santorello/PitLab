# PitLap — Test Globale Live QA

**Data:** 2026-07-30
**Ambiente:** Flutter web dev, `http://localhost:8080` (app già avviata dall'utente)
**Strumento:** Chrome MCP (browser automation)
**Sessione:** utente **NON loggato** (`user=null` nei log AuthFlow) → i punti che richiedono una sessione autenticata sono testati per quanto possibile e annotati.
**Viewport testati:** desktop ~1487px CSS e mobile 500px CSS (larghezza minima imposta da Chrome; target 390px non raggiungibile, ma layout mobile/bottom-nav pienamente attivo).

---

## 1. Tabella esito (8 punti)

| # | Punto | Esito | Note |
|---|-------|-------|------|
| 1 | Icone / Logo (favicon + header) | **PASS** | Favicon `/favicon.png` 64×64: 94,2% pixel scuri, ~1,3% arancio, **0% azzurro Flutter**, ~0,8% bianco (fulmine). Header brand = nuova gomma RC (quadrato scuro, gomma tassellata, razze arancioni, fulmine bianco). Nessuna traccia del logo Flutter azzurro né del vecchio quadrato arancione. |
| 2 | Card stile A (Piste/Negozi/Eventi/Spot/Vicino a te) | **PASS** | Overline "CITTÀ · TIPO" + titolo + riga statistiche quieta + CTA verificati su Piste, Negozi, Eventi, Spot. Banner media ~164px (target ~168px). CTA pista = **"Sto arrivando"**. |
| 3 | Bleed transizioni | **PASS** | Navigazione Home→Piste→Negozi→Eventi→Spot→/profiles→profilo pubblico→Home: nessun riquadro bianco fantasma dietro il contenuto. |
| 4 | Legale (privacy/terms/cookies) | **PASS** | "Titolare del trattamento" = **Giuseppe Santoro, Comune di Rho (MI)** + contatto **beppe.apps@gmail.com** (NON "progetto in fase pre-lancio"). Sezione **"Età minima" (14 anni, art. 8 GDPR / art. 2-quinquies D.Lgs. 196/2003)** presente. `/legal/terms` e `/legal/cookies` si aprono correttamente. |
| 5 | Login (Google + gating consensi) | **PASS** | Bottone **"Continua con Google"** presente oltre al magic link ("Ricevi link di accesso"). Consensi Termini + Privacy richiesti (marketing facoltativo). Gating verificato: click su Google senza consensi → snackbar *"Per continuare devi accettare i Termini di Servizio e confermare la presa visione dell'Informativa Privacy"* e **nessun avvio del flusso OAuth**. |
| 6 | Onboarding gate | **NON TESTABILE (parziale)** | Sessione non autenticata: il redirect "utente senza onboarding → /onboarding" non è esercitabile. Verificato però che il guard funziona: `#/onboarding` da loggato-out reindirizza a `#/login?redirect=/onboarding` (param di redirect preservato). |
| 7 | Privacy PitCoin su profilo pubblico | **PASS** | Profilo pubblico ("Marco Rossi 2", /profiles): mostra nome, ruolo, follower, "Segui", sezione Garage con le build. **Nessun saldo PitCoin visibile.** In Home la sezione "Classifica PitCoin" è presente e pubblica (attualmente empty state "Classifica in partenza" per assenza di punti reali) — coerente con il comportamento voluto. |
| 8 | Notifiche (spinner + errore 42703) | **PASS (con caveat)** | `/notifications` carica l'empty state "Nessuna notifica" senza spinner infinito. **Nessun errore `notification_recipients.id does not exist` (42703)** in console. Caveat: da loggato-out il path di query autenticato su `notification_recipients` non viene esercitato; il fix risulta comunque già applicato (task QA-LIVE-01). |

**Riepilogo:** 6 PASS · 1 PASS con caveat (#8) · 1 non testabile (#6). Nessun FAIL.

---

## 2. Errori console

- **Nessun errore JS / PostgREST / eccezione** rilevato durante l'intera sessione (sweep `onlyErrors` finale: "No console errors").
- In particolare **nessun 42703** sulla pagina Notifiche.
- Log presenti solo informativi: init Supabase, `[AuthFlow]`/`[ConsentFlow]` skip con `user=null`, warning Flutter sul `<meta viewport>` (standard, innocuo).

---

## 3. Finding numerati

| ID | Severità | Pagina / area | Descrizione |
|----|----------|---------------|-------------|
| GT-01 | Media | Routing globale | I deep-link **per path** non risolvono: digitare `http://localhost:8080/tracks` (o altri path) carica la **Home**, non la pagina target. L'app usa **hash routing** (`#/tracks`, `#/shops`, `#/legal/privacy`…). Impatto su link condivisibili/SEO e su eventuali bookmark. Da valutare se è comportamento atteso per la build dev o se serve fallback path→hash. |
| GT-02 | Bassa | Spot (seed dev) | La prima card Spot ("Claudia Ferri Luogo", overline "CLAUDIA FERRI CITTÀ · COMMUNITY") mostra come foto pubblica **l'immagine di un documento cartaceo con dati personali** (nome, indirizzo, dichiarazione, date). È dato di seed dev, ma è materiale sensibile esposto pubblicamente: rimuovere/sostituire il fixture prima di qualsiasi ambiente condiviso. |
| GT-03 | Bassa (cosmetico) | Eventi | Durante il caricamento, le emoji dei titoli sezione ("✨ In evidenza", "🎉 Gare & Appuntamenti") appaiono per un istante come glifo mancante (tofu) prima che il font emoji sia pronto. Si risolve da solo a caricamento completato; race puramente estetica. |
| GT-04 | Bassa | Card Eventi | L'overline delle card Evento è solo **"EVENTO"** (senza città), mentre Piste ("BOLOGNA · PISTA RC") e Negozi ("MILANO · NEGOZIO") usano il pattern "CITTÀ · TIPO". La città sull'evento è comunque nella riga statistiche. Piccola incoerenza rispetto alla specifica dell'overline. |

---

## 4. Giudizio estetico

Impianto visivo coerente e maturo. Palette scura/arancio ben applicata; la nuova gomma RC come marchio funziona sia nel favicon sia nell'header e dà identità immediata.

- **Card stile A:** ottima leggibilità. L'overline discreto + riga statistiche "quieta" (pallino stato colorato + presenze + discipline) elimina la vecchia "zuppa di pill" e rende la gerarchia chiara. I tag ameniti (Tavoli, 220V, Ristoro…) restano solo overlay sul banner, scelta pulita. Banner ~164px ben bilanciato.
- **Stato colorato:** pallino/etichetta APERTA (verde) / BAGNATA (blu) leggibile a colpo d'occhio.
- **Mobile (500px):** bottom-nav a 6 voci, pill azioni scorrevoli orizzontalmente, card meteo affiancate — nessun overflow, nessun troncamento problematico.
- **Legale:** pagine ben strutturate a card, testo leggibile, gerarchia titoli chiara.
- **Login:** flusso a card centrata, gerarchia buona; il gating con snackbar è chiaro.

### Ritocchi suggeriti (non bloccanti)
1. **GT-04** — uniformare l'overline degli eventi a "CITTÀ · TIPO" (es. "PARMA · EVENTO") per coerenza con Piste/Negozi.
2. **GT-03** — precaricare/riservare lo spazio del glifo emoji nei titoli sezione Eventi per evitare il flash del tofu.
3. **GT-02** — sostituire il fixture Spot con dati/immagini non sensibili.
4. Valutare un fallback di routing (GT-01) così che i path condivisi (`/tracks`, `/legal/privacy`) atterrino sulla pagina corretta anziché in Home.

---

## 5. Note di metodo / limiti sessione
- Test eseguito **da utente non autenticato**: i punti 6 (redirect onboarding) e 8 (query notifiche autenticata) non sono pienamente esercitabili; verificato tutto ciò che è osservabile lato guest + guard di routing.
- Rilevata instabilità del `resize_window` del tool (viewport che oscillava tra desktop e mobile): artefatto di automazione, **non** un bug dell'app. Larghezza minima finestra Chrome ~500px, quindi il target 390px non è stato raggiunto ma il layout mobile era comunque attivo.
- Nessun dato modificato durante il test (solo lettura/navigazione).
