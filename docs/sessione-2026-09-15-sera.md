# Sessione del 2026-09-15 (sera) — prod allineato, feedback online su prod

Seguito di `sessione-2026-09-15.md`. Eseguito da Claude via MCP Supabase, con via libera di Giuseppe.

## Applicato su pitlap-prod (klfjvyytubiorqzfisdu)

| Migrazione | Origine | Esito |
|---|---|---|
| `20260914_identita_utente` | `2026-09-14-identita-utente.sql` | OK — 0 profili senza nome |
| `20260915_timbro_revisore` | `2026-09-15-timbro-revisore.sql` | OK |
| `20260915_pista_collegata_al_creatore` | `2026-09-15-pista-collegata-al-creatore.sql` | OK — 2 righe in `track_managers` |
| `20260915_conservazione_dati` | `2026-09-15-conservazione-dati.sql` (**non citato nel verbale del pomeriggio**, trovato confrontando le funzioni) | OK |
| `20260915_grant_hardening_nuove_funzioni` | nuovo, applicato **anche su dev** | OK |

`begin;`/`commit;` rimossi perché `apply_migration` è già transazionale.

### Nuovo: grant delle funzioni nate il 14-15 settembre

Su dev `trg_stamp_review_author`, `auto_link_track_manager_on_insert` e `complete_onboarding`
avevano ancora EXECUTE a PUBLIC/anon (default Postgres di `create function`). Allineati a regola:

```sql
revoke execute on function public.trg_stamp_review_author() from public, anon, authenticated;
revoke execute on function public.auto_link_track_manager_on_insert() from public, anon, authenticated;
revoke execute on function public.complete_onboarding(text, text, text[], text, text, double precision, double precision, text) from public, anon;
grant  execute on function public.complete_onboarding(text, text, text[], text, text, double precision, double precision, text) to authenticated;
```

**Regola da ricordare:** ogni `create function` nuova nasce con EXECUTE a PUBLIC. Ogni delta
che crea una funzione deve chiudere con il suo `revoke`/`grant` esplicito.

## Edge Function

- `submit-feedback` pubblicata su **prod** (v1, ACTIVE, `verify_jwt: false` come su dev).
- **Manca:** secret `RESEND_API_KEY` (+ `FEEDBACK_TO`, `FEEDBACK_FROM` dopo la verifica del
  dominio su Resend). Senza chiave il feedback viene salvato ma non arriva nessuna email.

## Verifica

- Funzioni (codice normalizzato + ACL): impronta **identica** dev/prod.
- Trigger: 54 su entrambe.
- Advisor sicurezza prod: nessun ERROR. Solo WARN attesi (helper SECURITY DEFINER delle RLS;
  `cleanup_expired_arrivals` eseguibile da anon **per scelta**, vedi commento nel delta).
- Differenze residue note, non funzionali: policy `keepalive` SELECT = `(id = true)` su prod,
  `true` su dev (prod più restrittivo).

## Stato del dominio

`pitlap.app` **non risolve** (DNS: "Name or service not known") alle 19:10 del 15/09.
Nessun sito collegato: anche le pagine `/legal/*` non sono raggiungibili.

## Nota per il futuro

`submit-feedback` si fida di `userId` passato dal client (è falsificabile). Impatto basso
(solo attribuzione di un feedback); da sistemare leggendo l'utente dal JWT quando presente.

---

## GO-LIVE WEB — completato alle 19:55 del 15/09

| Passo | Esito |
|---|---|
| Build prod (`build_web_prod.bat`) | ✅ verificata: URL prod presente, 0 riferimenti a dev, `DONATION_URL` presente, 0.3.0+30 |
| Cloudflare Pages, progetto `pitlap` (upload diretto, 42 file) | ✅ `pitlap.pages.dev` |
| Domini personalizzati `pitlap.app` e `www.pitlap.app` | ✅ Active, SSL enabled |
| Pagine legali `/legal/*.html` senza login | ✅ (Cloudflare toglie `.html` con un redirect: gli URL `/legal/privacy-policy` funzionano) |
| Rotte profonde (`/tracks`) con `_redirects` | ✅ |
| Supabase prod: Redirect URL | ✅ aggiunti `https://pitlap.app/**`, `https://www.pitlap.app/**`, `io.pitlap.app://login-callback` (Site URL era già `https://pitlap.app`) |
| Supabase prod: SMTP Resend | ✅ era già configurato (noreply@pitlap.app, smtp.resend.com:465) |
| Resend: dominio pitlap.app | ✅ già verificato, regione Irlanda (coerente con privacy §8) |
| Supabase prod: 6 template email PitLap | ✅ incollati e verificati dopo ricarica |
| `submit-feedback` su prod | ✅ test reale: riga salvata con user_agent, poi cancellata |

**Attenzione per i prossimi deploy:** `run_dev.bat build` usa `dev.json`. Per la produzione usare SEMPRE `build_web_prod.bat`.

## Pulizia dati di prova su prod (decisa da Giuseppe)

Cancellati: pista `[QA] Pista di test PitLap` (con dipendenze in cascata) + 1 notifica, spot QA, 2 eventi community QA,
build QA, commento QA, categorie `francobolli` / `treni` / `qa_test_categoria`. Slug profilo `qa-test-pitlap` azzerato.
La presenza QA era già stata rimossa dalla pulizia giornaliera. **Pistona** resa non pubblica (non cancellata).
Negozio "di Beppe" era già `draft` e non pubblico: non toccato.

**Lezione:** `guard_track_moderation_columns` ripristina in silenzio `is_public` se la sessione non è admin, anche
per le query SQL da MCP/SQL Editor (`auth.uid()` nullo). Per cambiare visibilità da SQL: in transazione
`select set_config('request.jwt.claims','{"sub":"<id admin>","role":"authenticated"}', true);` e poi l'update.

## Ancora aperto

- [ ] **Secret `RESEND_API_KEY` su prod** (Edge Functions → Secrets). Senza, il feedback viene salvato ma l'email non parte. Facoltativi `FEEDBACK_FROM=PitLap Feedback <noreply@pitlap.app>`, `FEEDBACK_TO`.
- [ ] **Gate E2E** negozio + organizzatore su prod: serve il login con magic link, quindi la tua casella email. Profili di prova già presenti su prod: `Pilota 7ffa` (shop_owner), `Pilota c56a` (track_organizer).
- [ ] Testi legali: la privacy dichiara **v1.2** in testa ma il piè di pagina dice ancora "Versione 1.0 — 2026-06-03"; `legalDocumentVersion` nell'app è `'1.1'`. §3.5 dice "log 90 giorni", §9 dice "nessun log proprio". Allineare, rigenerare e rideployare.
- [ ] Verificare che la GitHub Action giornaliera (keepalive + `cleanup_expired_arrivals`) punti anche a **prod**.
- [ ] Android: keystore, build, Play Console (URL privacy da usare: `https://pitlap.app/legal/privacy-policy`).
- [ ] Commit: `git add docs/sessione-2026-09-15-sera.md && git commit -m "docs: go-live web 15/09" && git push`

---

## Dopo il go-live — header uniforme + login Google (15/09, sera)

**Header (codice, NON ancora compilato):** nuovo `core/widgets/language_toggle.dart`; `HeaderAccountActions` (ex `_HeaderActions`) ora
pubblico, include sempre il selettore IT/EN ed è allineato a destra; la Home usa lo stesso componente al posto dell'icona sola;
rimosso il selettore duplicato da `tracks_home_screen.dart`. Da fare: `run_dev.bat analyze` → `build_web_prod.bat` → nuovo deploy su Cloudflare (Pages → pitlap → Create deployment).

**Login Google su prod: provider DISABILITATO.** Su dev è attivo con Client ID `269462898998-j6poup49ujla8etuk7pa934ml1dtu65c.apps.googleusercontent.com`.
Passi (Giuseppe): Supabase prod → Sign In / Providers → Google → Enable, stesso Client ID + Client Secret → Save.
Google Cloud Console → Credenziali → client OAuth → aggiungere redirect `https://klfjvyytubiorqzfisdu.supabase.co/auth/v1/callback`
e origine JS `https://pitlap.app` (+ `https://www.pitlap.app`). Schermata consenso: se in "Testing" pubblicarla ("In production").

## Verifica branding Google + legali allineati (15/09, sera)

- `app/web/index.html`: blocco statico `#pitlap-static` (descrizione app, uso dati Google, link a privacy/termini/cookie, contatto),
  leggibile senza JavaScript e nascosto via CSS appena Flutter monta `flutter-view`. Serve alla verifica branding di Google OAuth.
- Legali: piè di pagina portati a **v1.2 — 2026-09-15** (erano 1.0); privacy §3.5 allineata a §9 (nessun log proprio);
  privacy §2 e §3.1 ora citano **Accedi con Google** (solo scope openid/email/profile, uso limitato all'autenticazione).
  `legalDocumentVersion` nell'app era già `'1.2'`. Pagine rigenerate con `tools/build_legal_pages.py`.
- Google Cloud → Branding: problema "home page non registrata a tuo nome" → verificare `pitlap.app` in Search Console
  (proprietà Dominio, TXT su Cloudflare) con lo stesso account del progetto, poi "Ho risolto i problemi".

## Mobile — Fase 1 "Ottimizzato" (scelta di Giuseppe dal mockup, vale per TUTTE le pagine incl. Gestione/Admin)

Mockup di riferimento: artifact "PitLap Mobile a confronto" (oggi / stile Strava / ottimizzato).
Codice (NON compilato, da `analyze`):
- `AppBreakpoints.compactHeader = 600` + `isPhone()`.
- `ContentScaffoldHeader` su telefono: solo titolo (headlineSmall), niente marchio/slogan/lingua/account/descrizione;
  `trailingActions` ancora mostrate se presenti. Banner impersonazione lasciato ad AppScaffold.
- `ContentScaffold` su telefono: margini 16/12 invece di 24.
- `AppScaffold` telefono: barra scura = logo + campanella + menu ⋮ (Profilo/Accedi, Lingua, Invia feedback, Offri un caffè).
  Voce "Altro" in basso ora fissa (non prende più icona/etichetta della pagina aperta).
  Ordine voci: Home, Piste, Spot, Eventi in barra; Vicino a te sposta in "Altro" (anche il rail desktop cambia ordine).
- Home: `_TopBar` nascosta su telefono.
- Mappa: su telefono riquadro "Mappa unificata" ridotto ai soli chip; altezza mappa = min(540, 50% schermo) per non bloccare lo scroll.
- `toggleAppLanguage()` estratta in `language_toggle.dart` e riusata dal menu.
Prossime fasi: 2 (mappa a pieno spazio), 3 (Profilo a schede, Garage compatto), 4 (rifiniture, saluto+PitCoin in una fascia).

## Mobile — Fase 1b: pagine interne + logo in barra

- Barra scura su telefono: aggiunto il logo `PitLapLogo` (30 px) accanto a "PitLap".
- `AppSpacing.card(context, [wide])`: 16 px su telefono, 24 (o valore dato) altrimenti. Sostituiti i 44 `const EdgeInsets.all(24/28)`
  in 13 schermate (admin, login, eventi + dettaglio, garage, gestione, profilo + pubblico, negozi + dettaglio, spot dettaglio, mappa, pista dettaglio).
- `ContentScaffold` su telefono avvolge il contenuto in `_PhoneTypography`: display/headline ridotti (headlineMedium→titleLarge ecc.),
  bodyLarge→bodyMedium. Colori dei singoli `copyWith` preservati.
- Dettaglio pista su telefono: niente breadcrumb, "quick facts" come pillole su una riga (icona+valore, etichetta in tooltip), spaziature ridotte.
- `run_dev.bat mobile`: server locale su 0.0.0.0:8080 per provare dal telefono (config DEV).

## Mobile — ritocchi da prova locale (16/09 notte)
- Spot: tolto il badge "Spot di guida" (su tutti i formati).
- Dettaglio pista: pulsante mappa usa `external_map_url`, altrimenti Google Maps dalle coordinate; se non c'è nessuno dei due non compare più (era icona disabilitata grigia su nero).
- Meteo pista su telefono: 3 giorni in una riga (giorno+data, verdetto colorato, nota), niente icona/sottotitolo/"Meteo live".
- Meteo: nuvoloso con pioggia < 10% ora dice "Nuvoloso, max X°C" invece di "pioggia fino al 0%" (testo IT/EN nel codice, non in ARB).
- ⚠️ Su DEV lo spot "Claudia Ferri Luogo" ha come foto la scansione di una dichiarazione con dati personali/giudiziari: da rimuovere dallo Storage dev.

## Sicurezza profili — review Astra 6 (16/09 sera)
- P1 auto-promozione ruolo CONFERMATO su dev e prod → `2026-09-16-guard-profile-role.sql` (trigger `trg_guard_profile_role`). Applicato e verificato su **dev e prod**.
- P1 colonne private leggibili da tutti CONFERMATO → `2026-09-16-profile-private-A-rpc.sql` (RPC `my_profile_private`) + `...-B-revoke.sql` (SELECT solo su 11 colonne pubbliche). Applicati su **dev** (8/8 prove OK).
  App: `user_location_context_provider` e `activity_feed_provider` leggono via RPC (NON compilato: `run_dev.bat analyze`).
  **Prod, in quest'ordine:** A subito → build + deploy web → B.
- Resta aperto: profili non pubblici ancora visibili (solo colonne pubbliche) agli utenti loggati, serve agli autori dei commenti.
- `run_dev.bat prod` / `mobile-prod`: app locale collegata a pitlap-prod, con conferma.

## Spot a scelte guidate + fix home/build (16/09 sera)
- Delta `2026-09-16-spot-tags.sql`: `best_for_tags`, `surface_tags` (liste), `access_type`, `best_season` con CHECK sulle chiavi, grant PER COLONNA, vista `public_spots` estesa, pulizia testi segnaposto. **Applicato su dev** (4/4 prove OK). Prod: eseguibile anche prima del deploy.
- App: `spots/domain/spot_tags.dart` (chiavi + IT/EN + `SpotTagPicker`), modulo, scheda, mappa, lista con filtro "Ideale per". Avviso ENAC/d-flight per Drone FPV e Aerei RC.
- Home: il feed `new_spot` apriva /track (payload usa `slug`, non `spot_slug`) → corretto.
- Build pubbliche: nome autore sempre visibile ai loggati, link solo se profilo pubblico.

## Luoghi: ricerca automatica se non si sceglie il suggerimento (16/09 notte)
- `resolvePlaceText()` in `shared/places/place_search_service.dart` (primo risultato, preferenza Italia). Usata in onboarding, Crea/Modifica spot, Crea/Modifica evento.
- Eventi community: il luogo ora usa `PlacePickerField` e salva `latitude/longitude` → delta `2026-09-16-community-events-coords.sql` (**applicato su dev**; prod eseguibile prima del deploy).
- Profilo santorello su prod aveva coordinate di Milano con città Rho (vecchie coordinate tenute dal COALESCE di complete_onboarding).
- Coordinate eventi non ancora usate da mappa / "Vicino a te": passo successivo.
- Build della settimana: vista `home_build_of_week` restituiva autore NULL → `2026-09-16-build-of-week-author.sql` (dev applicato).

## Eventi: P1/P2 della review (16/09 notte)
- Dettaglio: `fetchPublicEventById` cerca anche in `community_events` (id non-UUID → null senza errore).
- Salvataggio: `add/update` di `createdEventsProvider` restituiscono bool, niente più record ottimistico; la UI dice "Evento NON salvato" se il server rifiuta.
- Eventi in corso: vetrina = fine (o inizio) non passata, per `events` e `community_events`; archivio include anche gli eventi community. Stessa regola nelle liste locali.
- Test: `app/test/event_contract_test.dart` (2 casi Astra adattati).
- Rimandato: eventi su mappa e in "Vicino a te" (coordinate già salvate).

## Luoghi precisi: Photon + tocco mappa (16/09 notte)
- Ricerca: MapTiler (se key) → **Photon** (photon.komoot.io, OSM: parchi, vie, civici; gratis, uso ragionevole, nessuna garanzia) → Open-Meteo (solo città).
- `PlaceMapPreviewCard(onPointPicked:)`: mappa interattiva (zoom 15), tocco = segnaposto nel punto esatto. Attiva in Crea/Modifica spot e nei dialoghi evento.
- Da verificare in locale: Network → `photon.komoot.io` risponde 200 (CORS) e trova "Parco della Madonnina".

## "Vicino a te" vero + eventi sulla mappa (16/09 notte)
- `nearby_screen.dart`: piste, spot, eventi in programma, negozi; distanza da casa (o GPS con "Vicino a me"), ordinamento per km, raggio 10/25/50/Ovunque (default 50).
- Eventi pista: coordinate prese dalla pista (`tracks(latitude, longitude)` nelle select).
- Mappa: livello Eventi (viola), tocco → dettaglio evento, contatore, "Adatta vista" li include.
- Eventi community creati prima del 16/09 non hanno coordinate: compaiono solo in "Ovunque" (senza km) e non in mappa.

## Revisione pagina admin (18/09)
- **Difetto principale:** nessuna azione admin invalidava le liste pubbliche (in cache per tutta la sessione) → approvazioni/eliminazioni invisibili in Piste/Spot/Eventi/Negozi/Home fino a un reload. Aggiunto `_invalidatePublicCaches()` in admin_settings_screen e richiamato nelle 11 azioni.
- `_updateTrackApproval` non invalidava coda approvazioni e overview: aggiunto.
- Conteggi dashboard: `select('id')` + `.length` → `count(CountOption.exact)` (oltre 1000 righe il numero era sbagliato). Test `app/test/admin_counts_test.dart`.
- Aperti (non toccati): eventi community non si possono nascondere (solo eliminare), `deleteEvent` non chiede conferma extra per gli eventi altrui, nessuna azione admin sulle richieste di cancellazione account (solo elenco).

## Control room admin — fase 1 (18/09)
- Delta `2026-09-18-admin-dashboard.sql`: RPC `admin_dashboard()` SECURITY DEFINER, solo admin (non-admin → `{"error":"forbidden"}`), restituisce todo/health/counts/created_7d/signups_30d in un'unica chiamata. **Applicata e verificata su dev**; da eseguire su prod.
- App: `AdminDashboard` + `adminDashboardProvider` in admin_providers; nuovo `presentation/admin_control_room.dart` (fascia semaforo, 6 numeri, Da fare ora, colonna Salute, grafico 30 giorni). Rimossi `AdminOverviewRecord`, `fetchOverview`, `_count`, `countPending*`, `adminOverviewProvider`, `_AdminOverviewCard`, `_OverviewWrap/_OverviewItem` e i due banner testuali della dashboard.
- Test: `admin_dashboard_test.dart` (una sola chiamata, parsing, caso non-admin) al posto di `admin_counts_test.dart`.
- Mockup di riferimento: artifact "PitLap Control Room — mockup admin", variante C.
- Fase 2 (da fare): colonne "letto/gestito" su feedback, esito su entity_comment_reports, chiusura richieste cancellazione. Fase 3: attivi 7gg da pitcoin_transactions.awarded_at, regola definitiva "contenuti da sistemare".

## Control room fase 2 (19/09)
- Delta `2026-09-19-admin-fase2-gestito.sql` (**applicato su dev**, da eseguire su prod; sostituisce admin_dashboard del 18/09):
  colonne `feedback.handled_at/handled_by`, `entity_comments.reports_cleared_at`, `profiles.deletion_handled_at`;
  RPC `admin_mark_feedback_handled`, `admin_resolve_comment_report(hide)`, `admin_mark_deletion_handled`, `admin_reported_comments`;
  `admin_pending_account_deletions` salta le gestite; dashboard conta solo il non gestito.
- **BUG trovato e corretto (P2 della review, peggiore del previsto):** `guard_comment_moderation_columns` ripristinava
  `reported_count` per chiunque non fosse admin, quindi anche per `report_comment()` → nessuna segnalazione arrivava mai
  in coda, il contatore restava 0 per sempre. Ora il contatore può cambiare solo se coincide con le righe di
  `entity_comment_reports`; provato su dev (segnalazione utente = 1, gonfiaggio manuale bloccato).
- App: nuova sezione **Moderazione** (scheda Contenuti) con "Nascondi commento" / "Respingi segnalazione";
  pulsante "Segna come letto" sui feedback; "Segna gestita" sulle richieste di cancellazione. I pallini delle schede
  contano solo ciò che resta da fare.
