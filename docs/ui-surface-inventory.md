# PitLap UI Surface Inventory

Data: `2026-05-19`

Scopo:

- mappare pagine, popup, modali, campi e azioni oggi ricavabili dal codice Flutter
- creare una base verificabile per smoke test, regression test e test end-to-end futuri
- distinguere tra evidenza statica da codice e conferma visiva da frontend reale

Stato:

- fonte primaria attuale: codice locale in `app/lib`
- stato verifica frontend: `pending`
- nota: le etichette localizzate via `AppLocalizations` sono riportate con significato funzionale quando il testo runtime dipende da file l10n

## Legenda

- Accesso: `Guest`, `Auth`, `Manager`, `Shop manager`, `Admin`
- Stato UI: `static-code` se ricavato dal codice; `frontend-confirmed` quando confermato via browser
- Campo: input o dato visualizzato rilevante per test
- Azione: pulsante, toggle, navigazione, submit o comando dispositivo

## Route e Pagine

| Route | Schermata | Accesso | Superficie UI da codice | Backend/campi principali | Stato UI |
|---|---|---:|---|---|---|
| `/` | `CommunityHomeScreen` | Guest | Pulse counters, callout login, feed globale, card track/event/community/spot, stati empty/error | `activity_feed`: `actor_type`, `actor_id`, `actor_name`, `actor_slug`, `actor_city`, `event_type`, `title`, `subtitle`, `payload`, `created_at`; pulse da `track_status_current`, `events`, `spots` | static-code |
| `/tracks` | `TracksHomeScreen` | Guest | ricerca testuale, filtro città, chip categorie, language toggle, spotlight, card pista | `tracks`: `id`, `slug`, `name`, `city`, `short_description`; join `track_status_current(status,message)`, `track_services`, `track_category_links`; filtri `is_public`, `approval_status` | static-code |
| `/track/:slug` | `TrackDetailScreen` | Guest | hero/status, quick facts, descrizione, servizi/categorie, meteo, oggi in pista, follow/arrival/map actions | `tracks`: `id`, `slug`, `name`, `city`, `country`, `short_description`, `description`, `address`, `latitude`, `longitude`, `external_map_url`; RPC `get_public_track_arrival_summary`, `get_track_follower_count`; `arrivals`, `track_follows` | static-code |
| `/nearby` | `NearbyScreen` | Guest | ricerca località, filtri tipo `all/tracks/shops`, map/near-me actions, card miste | compone `publicTracksProvider` e `publicShopsProvider`; filtri in memoria | static-code |
| `/spots` | `SpotsScreen` | Guest | header spot, CTA mappa, CTA segnala spot, card con categoria/città/best_for/surface/foto | `public_spots`: `id`, `slug`, `title`, `city`, `category`, `best_for`, `surface`, `note`, `image_accent`, `photo_count`, `address`, `latitude`, `longitude`, `image_urls`, `video_url`, `is_custom`, `is_owned_by_current_user` | static-code |
| `/spots/map` | `SpotsMapScreen` | Guest | mappa, layer piste/spot, fit view, CTA segnala spot, pannello selezione, apri spot/pista, apri in mappa | `public_spots`; track pins da `tracks(slug,name,city,latitude,longitude,status)` | static-code |
| `/spot/:slug` | `SpotDetailScreen` | Guest | dettaglio spot, media/gallery, category/location, best_for, surface, note, video opzionale, edit/suggest CTA | `public_spots`; update custom via `spots` solo se owner | static-code |
| `/events` | `EventsScreen` | Guest | lista eventi, featured/current, sezione eventi utente, archive expander, crea/modifica se auth | `events`: `id`, `title`, `description`, `start_at`, `end_at`, `visibility`, join `tracks(name,city)`; `community_events` per eventi creati da profilo | static-code |
| `/event/:eventId` | `EventDetailScreen` | Guest | hero evento, condivisione, gallery, panoramica, venue/track context, RSVP leggero | `events` e provider eventi pubblici; immagini/event record locale | static-code |
| `/shops` | `ShopsScreen` | Guest | ricerca, banner manager se presente, draft manager, card negozio, save/follow, apri dettaglio | `shops`: `id`, `slug`, `name`, `city`, `short_description`, `subtitle`, `organization_name`, `image_url`, `gallery_images`, `website_url`, `phone`, `address`, `external_map_url`, `service_labels`, `hours`, `contacts`, `notes`; filtri `is_public`, `approval_status` | static-code |
| `/shop/:slug` | `ShopDetailScreen` | Guest | hero cover, specialità, orari, contatti, note, gallery, external links, follow, edit se permesso | `shops` pubblici approvati; `external_links`; `shop_follows`; RPC `get_shop_follower_count` | static-code |
| `/u/:publicSlug` | `PublicProfileScreen` | Guest | profilo pubblico, avatar, ruolo, garage pubblico, empty/not found | `profiles`: `id`, `public_slug`, `display_name`, `avatar_url`, `role`; `user_builds`: `id`, `title`, `meta`, `specs`, `image_urls` con `is_public=true` | static-code |
| `/login` | `LoginScreen` | Guest | email, scelta tipo account, checkbox consensi, link documenti legali, redirect/auth error | Supabase Auth; `user_consents`: `consent_type`, `accepted`, `document_version`, `source` | static-code |
| `/legal/privacy` | `LegalDocumentScreen` | Guest | sezioni privacy in card testuali | statico/l10n | static-code |
| `/legal/terms` | `LegalDocumentScreen` | Guest | sezioni termini in card testuali | statico/l10n | static-code |
| `/legal/cookies` | `LegalDocumentScreen` | Guest | sezioni cookie in card testuali | statico/l10n | static-code |
| `/garage` | `GarageScreen` | Auth | hero garage, lista build, add/edit build dialog, delete confirm, visibility toggle | `user_builds`: `id`, `owner_id`, `title`, `meta`, `specs`, `image_urls`, `is_public`, `created_at`, `updated_at` | static-code |
| `/profile` | `ProfileScreen` | Auth | overview, preferiti, eventi creati, build, dati base, quick links, external links, privacy, impostazioni | `profiles`, `user_consents`, `track_follows`, `shop_follows`, `community_events`, `user_builds`; RPC `request_account_deletion` | static-code |
| `/onboarding` | `OnboardingScreen` | Auth | wizard account type, interessi, città/place picker, riepilogo | RPC `complete_onboarding`; `profiles.preferred_city`, `profiles.user_interests`, `profiles.onboarding_completed` | static-code |
| `/submit-place` | `SubmitPlaceScreen` | Auth | tipo luogo, nome, città, indirizzo/place picker/GPS, descrizione, video URL, upload foto, submit | `spots` per custom spot; potenziali track/shop submission via repository | static-code |
| `/shop/:slug/edit` | `ShopEditorScreen` | Auth/Shop manager | form negozio: nome, subtitle, città, indirizzo, sito, organizzazione, cover, gallery, servizi, orari, contatti, note, external links | `shops`, `shop_managers`, `external_links`; campi editor completi | static-code |
| `/shops/new` | `ShopEditorScreen(isCreating)` | Shop manager | stesso form editor in modalità creazione/submission | `shops` insert con `approval_status` draft/pending | static-code |
| `/manager` | `ManagerScreen` | Manager | dashboard gestore, azioni rapide, piste/negozi gestiti, status panel, service toggles, event-ready toggles | `track_managers`, `shop_managers`, `tracks`, `shops`, `track_status_current/history`, `track_services` | static-code |
| `/manager/tracks/new` | `TrackEditorScreen` | Manager | form creazione pista: identità, posizione, media, contatti, servizi, preview, checklist, draft/submit | `tracks`, `track_services`, `track_categories`, `track_category_links` | static-code |
| `/manager/tracks/draft/edit` | `TrackEditorScreen(initialDraft)` | Manager | stesso editor con bozza precompilata | `tracks` draft/pending | static-code |
| `/manager/tracks/:slug/edit` | `ManagedTrackEditorScreen` | Manager | editor scheda pubblica pista, tassonomie, servizi, preview, external links | `tracks`, `track_services`, `track_categories`, `track_category_links`, `external_links` | static-code |
| `/admin` | `AdminSettingsScreen` | Admin | dashboard, approvazioni, utenti, piste, categorie pista, negozi, servizi negozio, eventi, info spot/garage/community/external links | `profiles`, `tracks`, `shops`, `events`, `community_events`, `track_categories`; update/delete/approve actions | static-code |

## Popup, Modali e Dialog

Nota statica:

- ricerca codice: non risultano usi di `PopupMenuButton`, `PopupMenuItem` o `showMenu` sotto `app/lib`
- i riferimenti principali sono `showDialog`, `Dialog.fullscreen`, `showModalBottomSheet`, form inline e bottom sheet

| Superficie | File | Trigger da codice | Campi/controlli | Azioni | Stato UI |
|---|---|---|---|---|---|
| Add external link | `shared/widgets/external_links_section.dart:107` | pulsante aggiungi link quando `editable` | provider dropdown, label, URL con validazione, toggle pubblico | annulla, salva | static-code |
| Gallery shop | `features/shops/presentation/shop_detail_screen.dart:637` | gallery button/thumbnail | immagini gallery, navigazione visuale | chiudi | static-code |
| Track arrival/status bottom sheet | `features/tracks/presentation/track_detail_screen.dart:540` | today-at-track / arrival action | scelta stato `coming/maybe/cancelled` | salva stato, annulla | static-code |
| Spot gallery | `features/spots/presentation/spot_detail_screen.dart:409` | thumbnail gallery | immagini spot | chiudi/naviga | static-code |
| Build add/edit | `features/garage/presentation/garage_screen.dart:212` | add/edit build | titolo, meta, image URL, upload anteprima, specs, public toggle, rimozione immagini | salva, annulla | static-code |
| Build delete confirm | `features/garage/presentation/garage_screen.dart:538` | delete build | testo conferma | annulla, elimina | static-code |
| Event create | `features/events/presentation/events_screen.dart:297` | crea evento | titolo, location, venue, note, immagini/upload, data start/end | crea, annulla | static-code |
| Event edit | `features/events/presentation/events_screen.dart:741` | modifica evento | titolo, location, venue, note, immagini, data start/end | salva, annulla | static-code |
| Event detail gallery | `features/events/presentation/event_detail_screen.dart:271` | gallery immagini evento | immagini evento in `Dialog.fullscreen` | chiudi/naviga | static-code |
| Admin delete confirm | `features/admin/presentation/admin_settings_screen.dart:327` | delete entity | label entità | annulla, elimina | static-code |
| Admin role change | `features/admin/presentation/admin_settings_screen.dart:396` | cambia ruolo utente | radio `user/shop_owner/track_organizer/admin` | annulla, salva | static-code |
| Admin display name edit | `features/admin/presentation/admin_settings_screen.dart:457` | modifica display name | display name | annulla, salva | static-code |
| Admin track category inline editor | `features/admin/presentation/admin_settings_screen.dart:1679` | sezione categorie pista | text field add, chip categorie con delete | aggiungi, elimina | static-code |
| Admin editable tag inline editor | `features/admin/presentation/admin_settings_screen.dart:1776` | sezioni label/tag | text field add, elenco tag | aggiungi, elimina | static-code |
| Profile change email | `features/profile/presentation/profile_screen.dart:507` | cambia email | nuova email | invia conferma, annulla | static-code |
| Profile magic link | `features/profile/presentation/profile_screen.dart:601` | reset/accesso magic link | nessun campo diretto | invia magic link, annulla | static-code |
| Profile delete account | `features/profile/presentation/profile_screen.dart:671` | elimina account | conferma testuale | annulla, elimina account | static-code |
| Profile collection bottom sheet | `features/profile/presentation/profile_screen.dart:762` | tile preferiti/creati | lista tappabile o stato vuoto | apri elemento, chiudi | static-code |
| Profile basics editor | `features/profile/presentation/profile_screen.dart:1061` | edit basics | avatar URL/upload, display name, lingua preferita | salva, annulla | static-code |
| Profile public settings | `features/profile/presentation/profile_screen.dart:1688` | toggle profilo pubblico | switch pubblico/privato, slug profilo | salva | static-code |
| Shop editor | `features/shops/presentation/shop_editor_screen.dart:20` | route edit/create | nome, sottotitolo, città, indirizzo, sito, organizzazione, cover/upload, gallery/upload, servizi, contatti, orari, note | salva/crea/annulla | static-code |
| Track editor | `features/tracks/presentation/track_editor_screen.dart:18` | route manager new/edit | nome, slug, città, descrizioni, cover/upload, servizi, label, organizzazione, email, telefono, sito | salva bozza, invia approvazione | static-code |
| Onboarding wizard | `features/onboarding/presentation/onboarding_screen.dart:18` | primo accesso auth | tipo account, interessi, città/place picker, riepilogo | indietro, avanti, completa | static-code |
| Login flow | `features/auth/presentation/login_screen.dart:20` | route login | email, tipo account, tre checkbox consensi | invia magic link | static-code |
| Submit place flow | `features/submissions/presentation/submit_place_screen.dart:20` | route submit/edit spot | tipo, nome, città, place picker, GPS, descrizione, video URL, upload/rimozione foto | invia/salva | static-code |

## Form e Campi Editabili

### Login

- Email
- Tipo account iniziale
- Consenso termini
- Presa visione privacy
- Consenso marketing

### Onboarding

- Tipo account
- Interessi utente
- Città preferita tramite `PlacePickerField`
- Riepilogo selezioni

### Profile

- Display name
- Avatar/photo URL o upload
- Lingua preferita
- Profilo pubblico on/off
- Slug profilo pubblico
- Email nuova
- External links: provider, label, URL, pubblico

### Garage

- Build title
- Meta
- Image URL / upload
- Specs
- Public toggle

### Tracks

- Nome pista
- Slug pubblico
- Città
- Indirizzo
- Descrizione breve
- Descrizione lunga
- Email contatto
- Telefono
- Sito web / external map URL
- Società o club
- Cover image URL / upload
- Categorie pista
- Servizi pista e disponibilità
- Stato pista e messaggio

### Shops

- Nome negozio
- Subtitle
- Città
- Indirizzo
- Sito web
- Società o negozio
- Cover image URL / upload
- Gallery URLs
- Servizi e punti forti
- Orari
- Contatti
- Note
- External links: provider, label, URL, pubblico

### Events

- Titolo
- Location
- Venue
- Note/descrizione
- Image URLs / upload
- Data inizio
- Ora inizio
- Data/ora fine quando presente

### Spots / Submit Place

- Tipo luogo
- Nome
- Città
- Indirizzo/place picker/GPS
- Descrizione
- Video URL
- Immagini/upload
- Categoria, best_for, surface derivati da flusso spot

### Admin

- Ricerca utenti
- Display name utente
- Ruolo utente
- Track category label
- Shop service label
- Approval status/is_public per piste e negozi
- Event visibility

## Backend Contract Summary

| Feature | Oggetti backend | Campi selezionati o scritti |
|---|---|---|
| Tracks | `tracks`, `track_status_current`, `track_status_history`, `track_services`, `track_categories`, `track_category_links`, `arrivals`, `track_follows` | campi pubblici pista, status, servizi, categorie, arrivi aggregati, follow |
| Shops | `shops`, `shop_managers`, `shop_follows`, `external_links` | campi pubblici negozio, editor rich fields, gallery, follows, link esterni |
| Spots | `public_spots`, `spots` | discovery fields via view; write custom spot su tabella con `owner_id` non selezionato dal client |
| Events | `events`, `community_events`, `activity_feed` | eventi ufficiali, eventi community, feed unificato |
| Profile/Auth | `profiles`, `user_consents`, `user_builds` | profilo corrente, profilo pubblico, consensi, garage |
| Admin | `profiles`, `tracks`, `shops`, `events`, `community_events`, `track_categories` | overview, moderazione, ruolo utenti, approvazioni |

## Checklist Verifica Frontend

Per ogni route:

- [ ] pagina carica senza errore console
- [ ] titolo/header coerente
- [ ] campi static-code presenti o motivatamente assenti
- [ ] azioni guest non dispositive visibili
- [ ] azioni dispositive guest rimandano a login o sono nascoste
- [ ] stato loading/empty/error comprensibile
- [ ] dati sensibili non visibili a guest
- [ ] screenshot desktop acquisito
- [ ] screenshot mobile acquisito

Per ogni dialog/modale:

- [ ] trigger individuabile
- [ ] dialog apre
- [ ] campi previsti presenti
- [ ] validazione minima visibile
- [ ] annulla/chiudi funziona
- [ ] submit salva o produce errore gestito

## Gap da Chiudere con Browser QA

- Confermare testi localizzati runtime da `AppLocalizations`
- Confermare quali sezioni condizionali appaiono per guest, auth, manager e admin
- Confermare quali CTA sono nascoste e quali reindirizzano a login
- Confermare che i campi backend selezionati siano davvero renderizzati nelle card/dettagli
- Confermare layout desktop/mobile e presenza di overflow
- Confermare popup/modali non coperti da stati auth/ruoli senza dati seedati
