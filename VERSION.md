# Versioning

## Versione corrente

- `project_name`: PitLap
- `current_version`: 0.3.0
- `status`: pre-alpha
- `release_date`: 2026-06-10

## Regola operativa

Questo file deve essere aggiornato a ogni nuova release.

Aggiornare sempre:

- versione corrente
- data release
- stato del progetto
- changelog sintetico

## Convenzione proposta

Formato versione:

- `major.minor.patch`

Linee guida:

- `major`: cambiamenti strutturali o release importanti
- `minor`: nuove funzionalita' o milestone rilevanti
- `patch`: correzioni, piccoli miglioramenti o allineamenti

## Changelog

### 0.3.0 - 2026-06-10

Stato:

- pre-alpha

Contenuto:

- **Fix QA gestore (E2E 2026-06-07)**: chiusi D07 (sezione "Bozze e in approvazione" sempre visibile in Gestione via `submitted_by`), D08/D09 (editor "Crea pista" allineato alle tassonomie DB `service_types`/`track_categories`, servizi e categorie persistiti già al salva-bozza). Nuovo delta `2026-06-10-draft-taxonomy-policies.sql` (policy RLS submitter su bozze, applicato su dev)
- **Delta prod-ready** `2026-06-10-prod-alignment.sql`: replica per prod dei fix D01/D05/D10/D11 validati su dev (complete_onboarding canonico, GRANT role helpers, policy gestori su track_category_links e tracks + guard trigger moderazione). DA APPLICARE SU PROD
- **Hardening DB** (cfr. `docs/db-hardening-2026-06-10.md`): consolidate le multiple permissive policies su spots/external_links/community_events/user_builds/profiles/track_category_links (advisor da 108 lint ai soli residui voluti su tracks), indici su 3 FK scoperte, censimento 32 indici inutilizzati (non rimossi), ACL SECURITY DEFINER documentate. Delta `2026-06-10-rls-consolidation.sql` applicato su dev
- **Media upload reale**: bucket Storage pubblico `media` (5MB, immagini, path `<user_id>/<entity_type>/<file>`, policy owner-based, niente listing), `MediaUploadService` con resize 1600px + WebP q82 + EXIF fix, progress per stage reale, errori visibili con retry. Migrati avatar, cover pista/negozio, gallerie negozio, eventi, spot, submit-place e build: addio `data:image` e QuotaExceededError. Delta `2026-06-10-media-storage.sql`
- **Commenti reali**: tabella `entity_comments` polimorfica (track/shop/event/community_event/spot/user_build) con RLS, guard moderazione admin-only, segnalazioni via RPC `report_comment`, view conteggi `entity_comment_counts`, azione PitCoin `comment_posted` (+5). Feature Flutter `features/comments/` con `CommentsSection` montata su dettaglio pista/negozio/evento/spot, conteggi batch sulle card community (zero N+1). Delta `2026-06-10-entity-comments.sql`
- **Condividi reale**: helper `shareEntity` condiviso con link canonici dalle rotte go_router, copia negli appunti + snackbar, collegato a card e pagine dettaglio
- **Segui profilo + notifiche in-app**: tabella `profile_follows` (RLS opt-in solo verso profili pubblici), contatore `get_profile_follower_count`, pulsante Segui sul profilo pubblico, azione PitCoin `profile_followed` (+2). Centro notifiche: completamento RLS su `notifications`/`notification_recipients`, trigger nuovi follower + attività dei seguiti (build pubblicata, evento creato), campanella con badge unread in AppScaffold (polling 2 min), schermata `/notifications` con mark-read e navigazione contestuale. Delta `2026-06-10-profile-follows-notifications.sql`
- **Polish UI**: titoli sezione home uniformati, gap condizionali sezioni vuote, hero detail coerenti, micro-animazioni toggle follow/preferiti, fade-in immagini in `AdaptiveImage`, `EmptyStatePanel` condiviso (garage, gestione), fix contrasti outlined su hero scure, colori hardcoded → token AppColors/AppSpacing/AppRadius
- nota operativa: per il go-live prod applicare in ordine i delta `2026-06-10-prod-alignment.sql`, `2026-06-10-rls-consolidation.sql`, `2026-06-10-draft-taxonomy-policies.sql`, `2026-06-10-media-storage.sql`, `2026-06-10-entity-comments.sql`, `2026-06-10-profile-follows-notifications.sql` (parte A fuori transazione) e abilitare Leaked Password Protection in Auth (dev+prod)

### 0.2.3 - 2026-05-27

Stato:

- pre-alpha

Contenuto:

- aggiunte route pubbliche `/builds` e `/profiles`: marketplace build pubbliche da `user_builds.is_public=true` e directory profili da `profiles.is_public=true`, con dati reali e link ai profili pubblici
- collegata la home: `tutte le build` apre `/builds`, `tutti i profili` apre `/profiles`; parsing immagini/specs reso piu' robusto tramite helper condiviso
- pagina `Tracks`: sezione `Ingressi rapidi` resa compatta su mobile con quick strip orizzontale, riducendo spazio occupato nel primo viewport
- pagina `Eventi`: aggiunta sezione collassata `Eventi passati` in fondo, alimentata da eventi pubblici reali gia' conclusi e ordinata dal piu' recente
- pagine legal (`/legal/privacy`, `/legal/terms`, `/legal/cookies`) riportate dentro `AppScaffold`, cosi' bottom navigation/footer restano visibili anche su mobile
- roadmap/checklist aggiornate con TODO di prodotto: `Segui profilo`, `Crea gruppo`, notifiche operative per gestori/creator evento, commenti moderati su entita' pubbliche, azioni reali per `Commenti` e `Condividi`
- nota tecnica aperta: creazione negozio ancora da verificare lato RLS remoto; il client invia `submitted_by`, `approval_status` e `is_public` coerenti con la policy locale, ma serve controllo diretto delle policy applicate su Supabase

### 0.2.2 - 2026-05-25

Stato:

- pre-alpha

Contenuto:

- nuovo fronte **Home dashboard v2** (cfr. `docs/superpowers/plans/2026-05-24-home-dashboard.md` e `docs/mockups/home-vision-v2.html`): home riscritta su contratti DB read-only, niente valori demo o fabbricati lato client
- delta `supabase/deltas/2026-05-24-home-dashboard-contracts.sql`: 4 nuove view `security_invoker` (`home_overview_stats`, `home_trending_tracks`, `home_featured_track`, `pitcoin_public_leaderboard`) + RPC `public.get_my_pitcoin_streak()` con `search_path` esplicito. Applicato su `pitlap-dev` (con fix in flight: `track_status_history.created_at` → `updated_at`)
- delta `supabase/deltas/2026-05-24-build-of-week.sql`: nuove tabelle `user_build_votes`, `weekly_featured_builds`, view `home_build_of_week`, funzione `private.refresh_current_build_of_week()` con award PitCoin idempotente, nuova action `build_of_week` (75 punti, per_entity_cap=1) nel catalogo. Eseguita una tantum la selezione della prima build
- delta `supabase/deltas/2026-05-24-user-location-context.sql`: aggiunte colonne `home_city`, `home_country`, `home_latitude`, `home_longitude` su `profiles` (con check constraint range lat/lng) + signature estesa `complete_onboarding(p_preferred_city, p_user_interests, p_home_city, p_home_country, p_home_latitude, p_home_longitude)` per persistere la zona di riferimento dell'utente
- delta `supabase/deltas/2026-05-24-activity-feed-images.sql`: riscritta la view `activity_feed` per esporre `image_url`/`image_urls` nel payload (track status, eventi, community)
- delta `supabase/deltas/2026-05-24-shop-submitters-rls-hardening.sql`: irrigidita la INSERT policy `shop submitters can insert own shops` (solo `auth.uid() = submitted_by`, `is_public=false`, status `draft|pending`) + auto-link `shop_managers` post-insert via trigger SECURITY DEFINER
- nuova feature Flutter `app/lib/features/community/application/home_dashboard_provider.dart`: modelli `HomeOverviewStats`, `HomeTrendingTrack`, `HomeBuildOfWeek`, `PitcoinLeaderboardEntry`, `HomeTrackWeather` + 6 provider Riverpod con fail-safe (ogni provider torna empty/null se la view o l'RPC manca, così la UI non crasha durante rollout incrementale)
- nuova feature Flutter `app/lib/features/location/application/user_location_context_provider.dart`: legge `profiles.home_*` e `preferred_city`, espone `UserLocationContext` con coordinate + radius, helper `distanceKmBetween` e `isWithinUserRadius` per il sort distance-aware del meteo
- riscritta `community_home_screen.dart` su pattern card-first (warm background, top bar brand, greeting, action chips, sezioni KPI/featured/trending/leaderboard/build-of-week/meteo/community), con empty state espliciti ("Arriva presto", "Classifica in partenza")
- `onboarding_screen.dart` allineato alla nuova signature `complete_onboarding` a 6 parametri (cattura città/paese/coordinate del luogo di riferimento)
- rifiniture su `shops_screen.dart`, `shop_detail_screen.dart`, `events_screen.dart`, `place_card.dart`, `content_scaffold_header.dart`, `community/domain/activity_feed_item.dart`, `legal_document_screen.dart`
- ARB IT/EN rigenerate per le nuove voci home (greeting, KPI, featured, trending, build-of-week, streak, classifica, meteo, empty state)
- health snapshot post-deploy: `home_overview_stats` = {open_tracks:6, events_next_30_days:3, new_spots_30_days:6, public_shops:7, geocoded_shops:3, public_builds:11}; top trending Arena RC Bologna (40), Offroad Parma (38), Drift Park Torino (37); leaderboard pubblica Davide 260 / Lorenzo 259 / Marco 223; build of the week settimana 2026-05-25 selezionata "Traxxas TRX-4 Gen2 Land Rover"; linter Supabase pulito sui nuovi oggetti

### 0.2.1 - 2026-05-23

Stato:

- pre-alpha

Contenuto:

- delta correttivo `supabase/deltas/2026-05-23b-pitcoin-security-hardening.sql`: REVOKE EXECUTE da `anon`/`authenticated` su tutte le 19 trigger function `trg_pitcoin_*` (defense in depth — return type `trigger` non era RPC-callable, ma il default GRANT era cattiva igiene)
- applicato live a `pitlap-dev` via MCP `apply_migration` (nome: `pitcoin_security_hardening_revoke_trigger_exec`). Linter Supabase `anon_security_definer_function_executable` ora pulito sui PitCoin trigger
- riscritto da zero `qa-temp/pitcoin-verification.sql` per compatibilità SQL Editor di Supabase: rimossi meta-comandi psql (`\set`, `\echo`, `\timing`) e l'uso scorretto di `rollback to savepoint` dentro blocchi PL/pgSQL DO. Nuovo design: i test usano `auth.uid()` come subject, scambio temporaneo di ruolo per il test admin-exclusion, cleanup automatico via marker `metadata.qa_marker=true` + ricomputo balance
- riparati `app_it.arb` / `app_en.arb` (chiusura JSON mancante dopo Edit del subagent) — 668 chiavi totali validate, incluse le 20 voci pitcoin
- health snapshot post-deploy verificato via MCP execute_sql: 88 transazioni backfill, 8 utenti con balance (admin escluso correttamente), 37 badge sbloccate su 10 chiavi distinte, distribuzione punti coerente con la spec (build_created=30, build_published=50, track_approved=100, shop_approved=80, arrival_checkin=3). Top leaderboard: Giuseppe 421 PitCoin, Claudia 282, Davide 260
- segnalata osservazione di prodotto: `identity_profile_complete` badge a 0 unlocked perché 0 profili pilota hanno `avatar_url` valorizzato — da rivedere il criterio (forse rimuovere `avatar_url`) o tenere come incentivo a completare onboarding

### 0.2.0 - 2026-05-23

Stato:

- pre-alpha

Contenuto:

- introdotto sistema **PitCoin & Badge** completo: reputation score continuo + 25 milestone badge (cfr. `docs/pitcoin-system.md`)
- nuovo delta `supabase/deltas/2026-05-23-pitcoin-system.sql` (~1950 righe): 5 tabelle nuove (`pitcoin_action_definitions`, `pitcoin_transactions`, `user_pitcoin_balances`, `pitcoin_badge_definitions`, `user_badges`), funzioni SECURITY DEFINER (`award_pitcoin`, `recompute_user_balance`, `check_badge_unlocks`), 16+ trigger sulle tabelle esistenti, RLS, view pubbliche `public_user_pitcoin` / `public_user_badges`, seed di azioni e badge, backfill retroattivo
- architettura Postgres-first: zero modifiche alle logiche Flutter esistenti, ogni azione dispositiva (creazione pista/negozio/spot/evento/build, pubblicazione build, check-in, follow, update gestore, ecc.) accredita PitCoin via trigger sul DB
- idempotenza ledger garantita da unique constraint `(user_id, action_key, source_table, source_id)` + `INSERT ... ON CONFLICT DO NOTHING`
- catalogo azioni admin-configurabile: base_points, daily_cap, per_entity_cap, lifetime_cap, cooldown_seconds, requires_approval — calibrazione senza migrazioni
- pattern submission/approval a due fasi: placeholder a 0 punti su submission, payout reale quando admin marca `approved`
- admin esclusi dall'accumulo per non viziare le metriche
- nuova feature Flutter `app/lib/features/pitcoin/`: modelli, repository read-only, providers Riverpod (con supporto `effectiveUserIdProvider` per impersonazione admin), 3 superfici UI additive (PitcoinBalanceCard nel profilo, PitcoinHistoryScreen su `/profile/activity`, PitcoinBadgesSection vetrina nel profilo + distintivi su profilo pubblico)
- estese ARB IT/EN con voci dedicate (titoli, CTA, tier, empty state); nomi e descrizioni azioni/badge letti dal DB tramite catalogo localizzato
- modifiche minimali a `profile_screen.dart` (card balance + sezione trofei) e `public_profile_screen.dart` (balance compatto accanto al ruolo + vetrina badge); nuova rotta `/profile/activity`
- script QA `qa-temp/pitcoin-verification.sql` con 12 test (idempotenza, cap, cooldown, admin exclusion, balance coerente, sblocco badge, pattern submission/approval, RLS, backfill rerun)

### 0.1.20 - 2026-05-10

Stato:

- pre-alpha

Contenuto:

- chiuso TC-WT-24: form `/shops/new` ora accessibile a shop_owner appena registrati (bypass del check ownership in modalita' creazione)
- chiuso TC-WT-23: bozza pista creata in impersonazione admin viene attributita all'utente osservato via `effectiveUserIdProvider` (campo `submitted_by`), appare correttamente in `/manager` di Lorenzo Bianchi
- chiusi TC-WT-19/20: counter "Da approvare" admin aggrega ora piste + negozi pending; editor shop legge dati anche se in stato pending
- chiuso TC-WT-12: nuovo `editableShopOrPublishedProvider` async con pattern `ref.listen` + flag `_hydrated` per popolare i form senza race condition
- chiuso TC-WT-01: redirect auth callback su otp_expired usa `router.replace()` per evitare assertion failure di go_router 17.1
- chiusi TC-WT-09/10/11: pulsanti `Apri mappa` e `Vicino a me` su `/nearby` ora navigano in-app a `/spots/map` invece di Google Maps esterno
- chiusi TC-WT-06/07/08/13/14/15/18: rifiniture design system (badge build pubblica tone success, data evento singola, location shop in subtitle, hero pattern documentato, copy form negozio production-ready)
- aggiornati `docs/test-checklist.md`, `docs/media-strategy.md`, `docs/roadmap.md` con decisioni di sessione

### 0.1.19 - 2026-05-08

Stato:

- pre-alpha

Contenuto:

- regression walkthrough completo da admin loggato su tutte le pagine principali (lista + detail + form + editor + admin tabs + action chains)
- identificati 18 bug nuovi documentati come TC-WT-01..18 in `docs/test-checklist.md`
- testato flusso operativo end-to-end per impersonazione track_organizer e shop_owner
- consolidato il design system con componenti unificati (`PlaceCard`, `Pill`, `StatusBadge`, `MetaRow`, `ContentScaffoldHeader`)

### 0.1.18 - 2026-05-07

Stato:

- pre-alpha

Contenuto:

- introdotto design system foundation in 4 file `app/theme/`: estensione `AppColors` con surface scale/orange family/status semantici/dark mode (24 token nuovi), nuova `AppSpacing` (xs..xxxl), `AppRadius` (sm..pill), `AppBreakpoints` (cardStack/navRail/contentMaxWidth) con helper boolean
- creato componente `PlaceCard` unificato in `shared/widgets/` con varianti standard/compact, layout responsive a un solo breakpoint (720px), slot fissi (media/header/location/signals/body/footer)
- creati componenti correlati: `Pill` con 6 tone semantici, `StatusBadge`, `MetaRow`
- refactorate 5 card su `PlaceCard`: track home, spots, shops, nearby, events
- allineate ai token le 2 card concettualmente distinte: BuildCard (garage), BaseFeedCard (community)
- estratto `ContentScaffoldHeader` come widget dedicato, riduzione di `ContentScaffold` da 263 a 71 righe
- documentato il design system in `docs/design-system.md` (canonico) e aggiornato `docs/ui-direction.md` con link
- centralizzati i breakpoint responsive: `AppScaffold` ora usa `AppBreakpoints.isExpanded()` invece di hardcoded 1100
- fix bug compile e import path durante consolidamento (path relativi corretti, l10n keys mancanti rimosse)

### 0.1.17 - 2026-04-22

Stato:

- pre-alpha

Changelog sintetico:

- migrato `shop editor` da bozza locale a persistenza reale su tabella `shops`
- applicata migrazione remota `shop_submitters_and_auto_manager` con insert policy per submitter e trigger che collega automaticamente `shop_managers`
- spostata la coda approvazioni admin dei negozi a lettura diretta da Supabase
- irrigidito il flusso `spots`: niente piu' successi silenziosi solo locali quando il DB fallisce
- applicato hardening DB sui flussi attivi con `set_updated_at` a `search_path` esplicito e nuovi indici per `shops`, `community_events` ed `external_links`

### 0.1.16 - 2026-04-22

Stato:

- pre-alpha

Contenuto:

- introdotto filtro citta' reale nella home piste, combinabile con ricerca testuale e filtri categoria
- estratta logica di filtro home in helper dedicato e aggiunti test mirati per matching e lista citta'
- completato un nuovo giro di pulizia `analyze` sui blocchi `place system` e `media upload system`

### 0.1.15 - 2026-04-21

Stato:

- pre-alpha

Contenuto:

- introdotti design doc e implementation plan dedicati ai sistemi condivisi `place` e `media upload`
- avviato il `place system` condiviso con `PlaceSelection`, provider MapTiler, `PlacePickerField` e `PlaceMapPreviewCard`
- collegati onboarding e `submit-place` al nuovo flusso di ricerca luogo canonica con coordinate e preview mappa
- avviato il `media upload system` condiviso con stato aggregato, stage label e progress card animata
- migliorata la progressione dei caricamenti immagini principali durante la preparazione locale, evitando il pattern fisso `0% -> 100%`
- corretto overflow int32 di `spots.image_accent` verso Postgres integer signed
- alleggerita la cache locale eventi su web per evitare `QuotaExceededError` da `data:image`
- riallineata la sezione admin eventi alla doppia origine dati `events` + `community_events`

### 0.1.14 - 2026-04-15

Stato:

- pre-alpha

Contenuto:

- introdotto edit spot per owner/admin con riuso del flusso `submit-place` e controllo permessi lato UI/submit
- allineata la resa spot usando la prima immagine caricata come cover visiva anche nel dettaglio hero
- estese le card piste verso un layout piu' vicino a `Spot`/`Negozi`, con pannello media e servizi visibili
- estese le card negozi e il relativo editor con gestione servizi/punti forti e prime card `I tuoi negozi` in `/shops` e `Gestione`

### 0.1.13 - 2026-04-14

Stato:

- pre-alpha

Contenuto:

- risolto il flusso `Apri` da coda approvazioni admin per le piste non ancora pubbliche, con preview locale visibile in route dettaglio per ruolo admin
- corretta la label stato nelle card bozza gestore: non resta piu' fissa su `Bozza gestore` dopo approvazione
- migliorato layout `/manager/tracks/new` con progress checklist, card readiness professionale e gating invio approvazione su requisiti minimi

### 0.1.12 - 2026-04-14

Stato:

- pre-alpha

Contenuto:

- evoluto `Gestione pista` in modalita' operativa giornaliera con preset rapidi, stato salvataggio esplicito e gestione modifiche non salvate
- aggiunta timeline `Ultimi aggiornamenti` per pista gestita, alimentata da `track_status_history` lato Supabase
- introdotti provider/repository dedicati allo storico aggiornamenti gestore e invalidazione mirata dopo save
- estesa checklist test con scenari integrati per pannello gestore V2 e affidabilita' read/write Supabase

### 0.1.11 - 2026-04-14

Stato:

- pre-alpha

Contenuto:

- introdotto hardening affidabilita' su repository Supabase con retry a backoff leggero per chiamate di lettura e scritture idempotenti (follow/arrivals)
- mantenuta esplicitamente senza retry la parte non idempotente dei log storici per evitare duplicazioni silenziose
- consolidata la base per test integrati orientati a resilienza rete e stabilita' read/write server

### 0.1.10 - 2026-04-14

Stato:

- pre-alpha

Contenuto:

- avviato il passaggio da `Gestione pista` dimostrativa a gestione reale con rotta dedicata per editing ownership-based della scheda pista
- migliorata la UX guest su `Vicino a te` con apertura diretta Google Maps (vista professionale) sia a livello sezione sia a livello card
- corretto il contrasto dei pulsanti outlined nelle hero scure `Spot` e `Mappa Spot`, eliminando i casi di pulsante visivamente "vuoto"
- rafforzata la privacy del blocco `Oggi in pista`: summary solo aggregata e messaggistica esplicita sulla non esposizione di nominativi
- consolidata la lettura summary `arrivals` usando il solo endpoint aggregato (`get_public_track_arrival_summary`), evitando fallback diretti su tabella raw
- aggiunta pulizia automatica degli `arrivals` storici dell'utente durante l'upsert giornaliero

### 0.1.9 - 2026-04-10

Stato:

- pre-alpha

Contenuto:

- introdotta la base schema/documentazione per `shop_follows` come preferiti negozio
- aggiunta in UI una prima distinzione tra eventi attivi e storico locale
- aggiunti contatori preferiti in UI per piste e negozi con basi provider dedicate
- introdotta una prima sezione `Biblioteca digitale` nel profilo
- aggiornati indice documenti e cartella Supabase con delta incrementali aggiuntivi

### 0.1.8 - 2026-04-09

Stato:

- pre-alpha

Contenuto:

- introdotta ownership negozio come percorso incrementale tramite `shops` e `shop_managers`
- aggiunto delta SQL dedicato per applicare permessi negozio senza rilanciare tutto lo schema
- allineata la documentazione Supabase e README al nuovo rollout incrementale

### 0.1.7 - 2026-04-09

Stato:

- pre-alpha

Contenuto:

- aggiunta una prima area `Admin` nel prodotto, visibile solo a chi ha ruolo admin
- introdotti overview, tassonomie e blocchi monitoraggio come base del futuro pannello completo
- aggiunta documentazione dedicata alla matrice permessi

### 0.1.6 - 2026-04-08

Stato:

- pre-alpha

Contenuto:

- introdotta base server-side per `track_follows` con schema, repository e sync preferiti pista autenticati
- allineata la baseline backend al modello iniziale reale dei `Preferiti`
- aggiornato backlog operativo per rollout remoto dei preferiti pista

### 0.1.5 - 2026-04-08

Stato:

- pre-alpha

Contenuto:

- tracciata matrice ruoli con estensione `admin` e requisito di pannello controllo completo
- aggiunto registro API/servizi esterni con note di attribuzione e privacy
- avviata integrazione meteo reale via provider esterno con fallback locale
- resa persistente localmente una parte delle funzioni testabili come preferiti, eventi creati e bozze negozio
- ulteriormente rifiniti gating guest/logged-in e flussi editabili su negozi, eventi e home

### 0.1.4 - 2026-04-07

Stato:

- pre-alpha

Contenuto:

- flusso magic link web ulteriormente consolidato con persistenza sessione e rientro sulla pista
- `Sto arrivando` persistito correttamente e visibile in `Oggi in pista`
- localizzazione IT/EN molto piu' coerente su home, dettaglio, login e pagine secondarie
- prime pagine legali pubbliche e raccolta consensi strutturata nella login
- profilo evoluto con primo modulo `Account`, logout e riepilogo consensi
- primi step su `Preferiti / Segui pista` e miglioramento schermate secondarie
- checklist e documentazione riallineate allo stato reale del progetto

### 0.1.3 - 2026-04-03

Stato:

- pre-alpha

Contenuto:

- introdotta checklist di sviluppo viva con punti completati, in corso e sospesi
- documentazione aggiornata per rendere piu' uniforme il follow-up del lavoro

### 0.1.2 - 2026-04-02

Stato:

- pre-alpha

Contenuto:

- menu laterale desktop richiudibile con animazione leggera
- dettaglio pista ulteriormente rifinito con hero piu' editoriale
- login magic link collegato a Supabase
- primo flusso reale `Sto arrivando` con persistenza in `arrivals`
- sezione `Oggi in pista` collegata allo stato personale della giornata

### 0.1.1 - 2026-04-02

Stato:

- pre-alpha

Contenuto:

- bootstrap Flutter attivo con shell responsive Android/Web
- integrazione Supabase client con configurazione via `--dart-define`
- home piste collegata a dati demo reali da Supabase
- dettaglio pista live per `slug` con stato, servizi, indirizzo e link mappa esterno
- allineamento documentazione allo stato reale del progetto

### 0.1.0 - 2026-04-02

Stato:

- pre-alpha

Contenuto:

- definizione iniziale del progetto PitLap
- creazione documentazione base di prodotto e tecnica
- introduzione supporto bilingue italiano/inglese come requisito
- creazione indice centrale dei documenti
- introduzione cartella `backup/` per snapshot di progetto
