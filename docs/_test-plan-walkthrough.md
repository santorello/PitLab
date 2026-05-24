# Test Plan - Walkthrough Admin (2026-05-07)

Data: 2026-05-07  
Versione: v0.1.9  
Scope: Walkthrough manuale admin logged-in  
Target: Fuori console errors, permessi coerenti, flussi core funzionanti

## Setup

- **Run**: `run_dev.bat` oppure `flutter run -d chrome --dart-define-from-file=./config/dev.local.json`
- **Backend**: Supabase dev (mqieterttnqdtdguaqoe.supabase.co)
- **Browser**: Chrome desktop
- **User**: Admin loggato (beppe.nino@gmail.com o admin test account)
- **Viewport test**: 1280px (desktop) + 760px (tablet/mobile)
- **Console**: DevTools aperta, monitorare `Tried to read uninitialized provider` e errori Supabase non gestiti

---

## Trasversali — verifica su tutte le pagine

### Header e Navigation
- [ ] ContentScaffoldHeader visibile: logo PitLap + tagline pill
- [ ] Voce "Accedi/Profilo" aggiornata post-login (no secondo tap necessario)
- [ ] Ruolo visibile in header (user/track_organizer/admin)
- [ ] Nav rail desktop: Home, Tracks, Shops, Events, Nearby, Spots, Garage (auth), Profilo (auth), Manager (organizzatori), Admin (admin)
- [ ] Bottom nav mobile: Home, Shops, Spots, Garage, Profilo (collapsate e togglabili)
- [ ] Banner impersonificazione visibile per admin (solo UI, JWT invariato)
- [ ] Lingua switchabile: IT/EN nel profilo, riapplicata su reload

### States e UX
- [ ] Loading state spinner durante fetch
- [ ] Empty state visibile se lista vuota (non crash)
- [ ] Error state visibile con messaggio e pulsante "Riprova" (no console exception)
- [ ] PlaceCard ricalcolata: avatar + nome luogo + stat inline + servizi/categorie + CTA (Sto arrivando, Modifica, Preferiti coerenti)

---

## / — Community Home

**MVP promesso**: Dashboard leggera con ultimi posti aggiornati, statistiche, CTA principali.

**Smoke:**
- [ ] Pagina carica senza console error
- [ ] Se non autenticato: Menu pubblico visibile, niente Garage/Profilo
- [ ] Se autenticato: Menu aggiornato, Profilo + Garage visibili
- [ ] Titolo e sottotitolo visibili (non placeholder)

**Funzionali:**
- [ ] Link/CTA verso `/tracks` funziona
- [ ] Link/CTA verso `/shops` funziona
- [ ] Link/CTA verso `/events` funziona
- [ ] Login CTA redirige a `/login`
- [ ] Statistiche (es. "XXX piste", "YYY evento") coerenti con dati Supabase (o marcate come "da collegare")

**Permessi:**
- Guest: sola lettura, niente area privata
- User: accesso base
- Admin: stessa visione + accesso `/admin`

---

## /tracks — Track Home

**MVP promesso**: Home piste con ricerca, filtri, lista card piste, stato attuale visibile.

**Smoke:**
- [ ] Lista carica con almeno 3 piste (Parma, Modena, …)
- [ ] Card piste visibili con nome, città, stato (open/wet/closed)
- [ ] Ricerca funziona: inserire "Parma" filtra la lista
- [ ] Ricerca chiara: tasto X resetta

**Funzionali:**
- [ ] Click su corpo card pista apre dettaglio
- [ ] Click su pista con stato visibile (es. "Aperta", "Bagnata")
- [ ] Filtro categoria: selezionare "Buggy" mostra solo buggy
- [ ] Filtro città: selezionare "Modena" mostra solo Modena
- [ ] Combinazione ricerca + categoria + città: logica AND funziona
- [ ] Chip categoria sulla card visibili e accurati
- [ ] Contatore "Sto arrivando" aggiornato se autenticato

**Permessi:**
- Guest: lista pubblica, niente "Sto arrivando"
- User: "Sto arrivando" abilitato, redirect login se cliccato da guest
- Admin: accesso pieno + visione piste draft/pending

---

## /track/:slug — Track Detail

**MVP promesso**: Dettaglio pista con stato, servizi, presenze, meteo, CTA arrivo.

**Smoke:**
- [ ] Hero pista carica: immagine, nome, città
- [ ] Badge stato visibile (Aperta, Bagnata, Chiusa)
- [ ] Sezione "Oggi in pista" visibile con conteggio aggregato
- [ ] Meteo badge visibile ("Live" per coordinate, "Stima" per fallback)

**Funzionali:**
- [ ] "Sto arrivando" button: click apre dialog/bottom sheet
- [ ] Dialog arrivo: stato "In arrivo", "Forse", "Annulla" disponibili
- [ ] Conferma arrivo salva su Supabase, "Oggi in pista" aggiornato
- [ ] Stato personale visible: orario registrazione visibile
- [ ] Click su categoria chip naviga con filtro applicato
- [ ] Servizi chip visibili (parcheggio, bar, ristoro, …)
- [ ] Indirizzo tappabile → mappa esterna (Google Maps)
- [ ] Link esterni (YouTube, sito) tappabili
- [ ] Timeline "Ultimi aggiornamenti" visibile se admin/owner

**Meteo:**
- [ ] Badge "Live" per piste con coordinate reali
- [ ] Forecast 3 giorni via Open-Meteo
- [ ] Attribuzione visibile: "Dati meteo forniti da Open-Meteo"
- [ ] Fallback se provider non risponde (no crash)

**Permessi:**
- Guest: sola lettura
- User: "Sto arrivando" attivo
- Track organizer: pulsante "Modifica pista" visible
- Admin: "Modifica pista" + modifica stato + cronologia

---

## /nearby — Discovery (Vicino a te)

**MVP promesso**: Ricerca geografica semplice di piste e negozi, distanza stimata.

**Smoke:**
- [ ] Pagina carica senza error
- [ ] Lista piste e negozi visibili (mix o tab separati)
- [ ] Card con nome, città, distanza

**Funzionali:**
- [ ] Ricerca filtra lista (inserire nome pista/negozio)
- [ ] Ricerca chiara (tasto X resetta)
- [ ] Click su pista → apre dettaglio pista
- [ ] Click su negozio → apre dettaglio negozio
- [ ] "Apri su mappa" → mappa esterna Google Maps
- [ ] Nessun dato hardcoded (confrontare con DB reale)
- [ ] Nessun negozio demo fisso mostrato

**Permessi:**
- Guest: lista pubblica, link mappa esterni

---

## /spots — Spots List

**MVP promesso**: Elenco spot (bashing, scaler, droni) con card, possibilità segnala nuovo.

**Smoke:**
- [ ] Lista spot carica (almeno 1-2 default)
- [ ] Card spot: nome, città, tipo (bashing/scaler/droni)
- [ ] "Segnala spot" CTA visibile

**Funzionali:**
- [ ] Click su card spot apre dettaglio
- [ ] Click "Segnala spot" apre form (auth required per user, redirect login se guest)
- [ ] Form spot: nome, tipo, descrizione, coordinate (mappa preview), foto locale (optional)
- [ ] Salvataggio spot: redirect a dettaglio appena salvato
- [ ] Spot nuovo visibile in lista dopo refresh
- [ ] Modifica spot: owner vede pulsante "Modifica", admin sempre può modificare
- [ ] Cancellazione spot: owner/admin può eliminare

**Permessi:**
- Guest: lista pubblica, "Segnala spot" → login
- User: "Segnala spot" disponibile, modifica solo propri spot
- Admin: modifica tutti gli spot

---

## /spot/:slug — Spot Detail

**Smoke:**
- [ ] Dettaglio carica: nome, descrizione, tipo, immagini
- [ ] Coordinate su mappa preview se disponibili

**Funzionali:**
- [ ] "Modifica spot" button visible se owner/admin
- [ ] Click modifica apre editor precompilato
- [ ] "Apri su mappa" → Google Maps
- [ ] Numero immagini coerente (massimo 3-5 per spot)

**Permessi:**
- Guest: sola lettura
- Owner: modifica disponibile
- Admin: modifica sempre disponibile

---

## /spots/map — Mappa Unificata Spot

**Smoke:**
- [ ] Mappa carica: layer PitLap con marker spot
- [ ] Toggle "Piste" / "Spot" funzionano
- [ ] Pulsante "Adatta vista" centra i marker visibili

**Funzionali:**
- [ ] Click marker spot: pannello dettaglio a destra con nome, città, bottone "Apri spot"
- [ ] "Apri spot" naviga a dettaglio
- [ ] Toggle disabilita/abilita marker categoria

**Permessi:**
- Guest: accesso pubblico

---

## /shops — Shops List

**MVP promesso**: Catalogo negozi con cover, servizi, contatti essenziali.

**Smoke:**
- [ ] Lista negozi carica (almeno 3 demo: Parma, Modena, Bologna)
- [ ] Card negozio: cover, nome, città, tipo (es. "Ricambi RC")
- [ ] "Crea negozio" CTA visibile se shop_owner/admin

**Funzionali:**
- [ ] Click su card negozio apre dettaglio
- [ ] Ricerca filtra lista
- [ ] Ricerca chiara (tasto X)
- [ ] "Crea negozio" → login se guest, form editor se autenticato
- [ ] Draft negozio visibile in lista dopo salvataggio
- [ ] Negozi pubblici non contaminati da draft locali
- [ ] Contatori follower se disponibili

**Permessi:**
- Guest: lista pubblica, niente modifica
- Shop owner: pulsante "Modifica negozio" visible
- Admin: modifica tutti i negozi, toggle visibilità

---

## /shop/:slug — Shop Detail

**MVP promesso**: Scheda negozio con cover, galleria, orari, contatti, servizi.

**Smoke:**
- [ ] Hero carica: cover immagine, nome, città
- [ ] Badge tipo negozio visibile
- [ ] Galleria foto visibile (se almeno 1 immagine)

**Funzionali:**
- [ ] Contatti: tap-to-call (telefono), tap-to-email
- [ ] Link mappa: "Apri su mappa" → Google Maps
- [ ] Servizi chip visibili (Ricambi, Batterie, Servizio, …)
- [ ] Orari compilati se disponibili
- [ ] Link esterni (sito, YouTube) tappabili
- [ ] Pulsante "Modifica negozio" visible se owner/admin
- [ ] Galleria fullscreen viewer (swipe tra immagini)

**Permessi:**
- Guest: sola lettura
- Owner: pulsante "Modifica negozio" visible
- Admin: pulsante "Modifica negozio" visible

---

## /shop/:slug/edit — Shop Editor

**Smoke:**
- [ ] Form carica precompilato se modifica, vuoto se creazione
- [ ] Tutte le sezioni visibili: Dati base, Servizi, Orari, Contatti, Cover, Galleria, Link

**Funzionali:**
- [ ] Modifica nome/descrizione salva
- [ ] Caricamento cover: preview inline, salvataggio persiste dopo reload
- [ ] Caricamento galleria: massimo 10 immagini totali, massimo 3 per upload
- [ ] Aggiunta link sito/YouTube: normalizzazione URL (aggiunge https:// se manca)
- [ ] Rimozione link da sezione "Link e canali"
- [ ] Badge "Modifiche non salvate" se form dirty
- [ ] Pulsante "Salva bozza" o "Salva": feedback visibile durante invio
- [ ] Timeout invio: messaggio errore con "Riprova"
- [ ] Riapertura form: valori persistiti correttamente

**Permessi:**
- Shop owner: modifica solo negozi assegnati via `shop_managers`
- Admin: modifica tutti

---

## /events — Events List

**MVP promesso**: Calendario eventi con card, filtri, creazione evento.

**Smoke:**
- [ ] Lista eventi carica (almeno 1-2 demo se seed presente)
- [ ] Card evento: immagine, nome, data, luogo
- [ ] "Crea evento" CTA visibile

**Funzionali:**
- [ ] Click su card evento apre dettaglio
- [ ] "Crea evento" → login se guest, form se autenticato
- [ ] Form evento: nome, data/ora, luogo, descrizione, immagine locale
- [ ] Salvataggio evento: appear in list dopo refresh
- [ ] Ricerca filtra lista
- [ ] Immagine evento max 5 MB (resize se necessario, rifiuta se > 5MB)

**Permessi:**
- Guest: lista pubblica, "Crea evento" → login
- User: "Crea evento" disponibile

---

## /event/:eventId — Event Detail

**Smoke:**
- [ ] Dettaglio carica: nome, data, luogo, immagine (se caricata)

**Funzionali:**
- [ ] Data/ora formattata leggibile
- [ ] Luogo/indirizzo visibile
- [ ] "Apri su mappa" → Google Maps se indirizzo disponibile
- [ ] Pulsante "Condividi" copia link negli appunti
- [ ] Snackbar conferma copia link
- [ ] Link format: `/#/event/<eventId>`

**Permessi:**
- Guest: sola lettura
- User: accesso pieno

---

## /garage — Garage Personale

**MVP promesso**: Elenco build personali con foto, visibilità pubblica/privata.

**Smoke:**
- [ ] Lista build carica (se almeno 1 build creata)
- [ ] Card build: nome, foto preview, badge pubblico/privato

**Funzionali:**
- [ ] "Aggiungi build" button disponibile
- [ ] Form build: nome, descrizione, foto preview locale, toggle pubblico/privato
- [ ] Foto preview inline, avviso "Non persistita in beta" visibile
- [ ] Salvataggio build: appear in list
- [ ] Toggle visibilità pubblico/privato aggiorna card badge
- [ ] Modifica build: pre-compila form
- [ ] Cancellazione build: rimossa da lista

**Avviso media:**
- [ ] Warning prominente: "Le foto sono solo preview locale, non salvate nel DB"
- [ ] Pulsante "Anteprima foto" (non "Carica foto")

**Permessi:**
- Auth required: redirect `/login` se guest

---

## /profile — Profilo Utente

**MVP promesso**: Profilo base con dati account, consensi, link social.

**Smoke:**
- [ ] Hero profilo carica: nome visibile, avatar (se URL valido)
- [ ] Sezione account: email, ruolo
- [ ] Sezione consensi: termini, privacy, marketing (con data versione)

**Funzionali:**
- [ ] Modifica nome visibile: salva, hero aggiornato
- [ ] Cambio lingua: IT/EN salvato, UI aggiornata
- [ ] URL avatar valido: preview visibile
- [ ] URL avatar non caricabile: fallback avatar neutro (no crash)
- [ ] Cambio email: magic link inviato, conferma necessaria
- [ ] Reset accesso: magic link richiesta, email inviata
- [ ] Cancellazione account: dialog conferma 2-step, RPC request_account_deletion
- [ ] Aggiunta link esterno (Instagram, YouTube): URL normalizzato
- [ ] Rimozione link da sezione "Link e canali"
- [ ] Link tappabili aprono URL esterno

**Consensi:**
- [ ] Termini versione e data visibili
- [ ] Privacy versione e data visibili
- [ ] Marketing toggle presente
- [ ] Riepilogo date persistito

**Permessi:**
- Auth required: redirect `/login` se guest

---

## /u/:publicSlug — Profilo Pubblico

**Smoke:**
- [ ] Profilo pubblico carica da slug pubblico
- [ ] Avatar, nome visibili se profilo è pubblico

**Funzionali:**
- [ ] Garage pubblico visibile se settato (no crash se privato)
- [ ] Link esterni visibili
- [ ] Nessun pulsante modifica per utente guest

**Permessi:**
- Guest: accesso se profilo è `is_public = true`
- Owner: modifica disponibile dal `/profile`

---

## /manager — Manager Hub (Track Organizer)

**MVP promesso**: Panel gestore piste con lista assegnate, editor stato, timeline, approvazioni.

**Smoke:**
- [ ] Lista piste assegnate carica (se `track_managers` ha relazioni)
- [ ] Card pista: nome, città, stato draft/active/pending
- [ ] "Crea nuova pista" CTA visibile

**Funzionali:**
- [ ] Click su pista apre editor
- [ ] "Crea nuova pista" apre form vuoto
- [ ] Preset rapido stato: "Pronta gara", "Bagnata ma aperta", "Chiusa manutenzione"
- [ ] Salvataggio stato: `track_status_current` aggiornato, timeline visibile
- [ ] Badge "Modifiche non salvate" se form dirty
- [ ] Pulsante "Salva": disabled durante invio, feedback "Salvataggio..." visibile
- [ ] Dopo salvataggio: "Ultimo invio HH:MM" visibile
- [ ] Timeline "Ultimi aggiornamenti": righe ordinate recente → meno recente
- [ ] Pulsante "Ricarica dati"/"Riprova": refresh timeline
- [ ] Voce menu visibile solo se `canManageTracks` true

**Permessi:**
- Auth + track organizer/admin required: redirect `/` se utente normale

---

## /manager/tracks/new — Crea Pista (Submission)

**Smoke:**
- [ ] Form carica vuoto
- [ ] Sezioni visibili: Dati base, Categorie, Cover, Servizi, Link, Checklist

**Funzionali:**
- [ ] Nome, slug auto-generato opzionale
- [ ] Selezione categorie: Buggy, Mini-Z, Touring, Indoor, Outdoor
- [ ] Caricamento cover URL: preview inline
- [ ] Aggiunta servizi: selezione da chip
- [ ] Aggiunta link externos: sito, YouTube, Instagram
- [ ] Progress checklist: requisiti minimi visibili
- [ ] Pulsante "Invia approvazione": disabilitato finché checklist incompleta
- [ ] Invio: crea `pending` submission, salva in `tracks` con `approval_status = pending`
- [ ] Dopo invio: redirect a `/manager` con feedback success

**Permessi:**
- Auth + track organizer/admin required

---

## /manager/tracks/:slug/edit — Modifica Pista (Managed)

**Smoke:**
- [ ] Form precompilato con dati pista
- [ ] Tutte le sezioni caricano

**Funzionali:**
- [ ] Modifica dati base: nome, slug, descrizione salva
- [ ] Modifica categorie: aggiunta/rimozione synch `track_category_links`
- [ ] Modifica cover: URL normalizzato, preview
- [ ] Preset rapido stato: salva in `track_status_current`, timestamp aggiornato
- [ ] Aggiunta link esterni: sito, YouTube (normalizza URL)
- [ ] Rimozione link
- [ ] Timeline aggiornata dopo salvataggio
- [ ] Coerenza cross-page: modifica visibile in home piste + dettaglio pista

**Permessi:**
- Track organizer su piste assegnate via `track_managers`
- Admin: accesso pieno

---

## /submit-place — Segnala Spot / Luogo

**MVP promesso**: Form segnalazione nuovi spot con luogo, tipo, foto.

**Smoke:**
- [ ] Form carica: selezione tipo (track/spot), ricerca luogo, mappa preview

**Funzionali:**
- [ ] Ricerca luogo: autocomplete funziona con indirizzo/città
- [ ] Mappa preview aggiorna con coordinate selezionate
- [ ] Aggiunta foto locale: caricamento, preview
- [ ] Descrizione compilabile
- [ ] Invio: crea riga in `place_submissions` (o `spots` se spot)
- [ ] Dopo invio: feedback success, redirect a dettaglio appena creato

**Permessi:**
- Auth required: redirect `/login` se guest

---

## /onboarding — Onboarding Post-Registrazione

**MVP promesso**: Setup 3-step: tipo account, città, riepilogo.

**Smoke:**
- [ ] Step 1 carica: selezione tipo account (Modellista, Gestore pista, Gestore negozio)
- [ ] Step 2 carica: selezione città preferita
- [ ] Step 3 carica: riepilogo scelte

**Funzionali:**
- [ ] Progres bar animata
- [ ] Step 1: click tipo → Step 2
- [ ] Step 2: selezione città, click continua → Step 3
- [ ] Step 3: riepilogo dati, click "Completa" → RPC `complete_onboarding`
- [ ] Post-completamento: `onboarding_completed_at` aggiornato, redirect `/`
- [ ] Nessun testo falso: "Il tuo feed personalizzato è pronto" rimosso

**Permessi:**
- Auth required: redirect `/login` se guest

---

## /login — Login Screen

**Smoke:**
- [ ] Form carica: email input, magic link button
- [ ] CTA "Accedi con Google" (se attivo)

**Funzionali:**
- [ ] Inserimento email valida: click "Invia link magico"
- [ ] Messaggio success: "Link inviato a [email]"
- [ ] Click link da email: callback Supabase gestito
- [ ] Post-login: sessione autenticata, nav aggiornato
- [ ] Post-login con redirect param: ritorna alla route originale (es. `/track/parma?intent=arrival`)
- [ ] No secondo tap necessario per aggiornare nav (refreshListenable funziona)
- [ ] Consensi: checkboxes termini/privacy/marketing, salvataggio in `user_consents`

**Permessi:**
- Guest: accesso diretto a `/login`
- Auth: redirect a `/` se gia' loggato

---

## /legal/privacy, /legal/terms, /legal/cookies — Pagine Legali

**Smoke:**
- [ ] Pagine caricano senza crash
- [ ] Testo leggibile, formattazione coerente

**Funzionali:**
- [ ] Privacy: contenuto GDPR-completo visibile
- [ ] Terms: contenuto completo visibile
- [ ] Cookies: contenuto completo visibile
- [ ] Accessibility: contrasto sufficiente, heading gerarchico
- [ ] Nessun testo "TODO" o placeholder

**Permessi:**
- Guest: accesso pubblico

---

## /admin — Admin Settings Dashboard

**Smoke:**
- [ ] Dashboard carica: Overview, Categorie, Impersonifica, Monitoraggio
- [ ] Sezioni caricate correttamente

**Funzionali:**

### Overview
- [ ] Contatori utenti, piste, negozi, eventi (dati reali o marcati "Da collegare")
- [ ] Nessun placeholder tecnico o `TODO`

### Categorie
- [ ] Categorie track visible (Buggy, Mini-Z, …)
- [ ] Nessun placeholder fisso

### Utenti
- [ ] Lista utenti paginata
- [ ] Modifica ruolo: dropdown user/track_organizer/shop_owner/admin
- [ ] Modifica display name: campo input
- [ ] Toggle icona "Osserva" (impersonificazione UI, not JWT)
- [ ] Tooltip: "Solo UI — JWT e RLS invariati"
- [ ] Banner impersonificazione appears con bottone "Stop"
- [ ] Stop ripristina ruolo reale

### Piste
- [ ] Lista piste con stato (draft/pending/approved/published)
- [ ] Bottone "Apri" per draft/pending
- [ ] Bottone "Approva"/"Rifiuta" per pending
- [ ] Bottone "Modifica" per ogni pista
- [ ] Bottone "Elimina" se soft delete supportato
- [ ] Label coerente con stato reale (non "Bozza gestore" fisso)

### Negozi
- [ ] Lista negozi con toggle visibilità pubblica
- [ ] Bottone "Modifica" per ogni negozio

### Eventi
- [ ] Lista eventi con toggle visibilità/elimina
- [ ] Testo "su Supabase" non "locale"

### Settings
- [ ] Sezione Garage: "su Supabase" (non locale)
- [ ] Sezione Community Events: "su Supabase"
- [ ] Sezione Link esterni: "su Supabase"

**Permessi:**
- Admin required: redirect `/login` se guest, redirect `/` se non admin

---

## 404 Not Found

**Smoke:**
- [ ] Rotta inesistente (es. `/questa-rotta-non-esiste`): pagina 404 visibile
- [ ] Nessun crash

**Funzionali:**
- [ ] Copy on-brand visibile
- [ ] Pulsante "Torna alla home" funziona: redirect `/`

---

## Trasversali — Edge Case & Regressioni

### Auth & Sessione
- [ ] Logout → Garage → Login: no "uninitialized provider" exception
- [ ] Logout → Admin → Login: no exception
- [ ] Logout → navigazione rapida tra pagine: no crash

### Cross-page Consistency
- [ ] Modifica pista in `/manager` → visibile in `/` home
- [ ] Modifica pista in `/manager` → visibile in `/track/:slug`
- [ ] Modifica negozio in editor → visibile in `/shops` + `/shop/:slug`
- [ ] Modifica profilo → visibile in `/profile` + `/u/:slug` (pubblico)
- [ ] Arrivo registrato → "Oggi in pista" aggiornato (fetch richiesto, non realtime)

### Network Instability
- [ ] Throttle rete (DevTools): fetch completa con backoff leggero
- [ ] Errore temporaneo su write: snackbar messaggio + "Riprova"
- [ ] Timeout invio: no freeze UI, pulsante disabilitato → riabilitato

### Media & Upload
- [ ] Foto local: preview inline, salvataggio URL esterno persiste
- [ ] Foto > 5 MB: resize/rifiuto con messaggo utente (no crash)
- [ ] Drag-drop immagini: supportato se implementato, fallback upload picker

### Layout Responsiveness
- [ ] Desktop 1280px: nav rail visibile, layout multi-colonna
- [ ] Tablet 760px: transizione fluid, nav rail hidden, bottom nav visibile
- [ ] Mobile < 600px: full-width mobile first, touch target >= 48x48 dp
- [ ] Orientamento: portrait → landscape senza crash

### Console Cleanliness
- [ ] No `Tried to read the state of an uninitialized provider`
- [ ] No `RenderFlex overflowed` o exception layout
- [ ] No Supabase 401/403 inattese (auth guard funziona)
- [ ] No GoRouter redirect loop

---

## Riepilogo Esito

| Area | Status | Note |
|---|---|---|
| Home / Community | | |
| Tracks home + filtri | | |
| Track detail + arrivals | | |
| Nearby discovery | | |
| Spots list + detail | | |
| Shops list + detail | | |
| Shop editor | | |
| Events + creation | | |
| Garage | | |
| Profilo + consensi | | |
| Public profile | | |
| Manager piste | | |
| Track creation/edit | | |
| Submit place | | |
| Onboarding | | |
| Login + auth | | |
| Admin dashboard | | |
| Legale (privacy/terms) | | |
| Navigation + header | | |
| Permessi enforced | | |
| Cross-page consistency | | |
| Network resilience | | |
| Layout responsive | | |
| Console cleanliness | | |

---

*Test plan generato per PitLap v0.1.9 · 2026-05-07*
