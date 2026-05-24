# PitLap — QA Report v0.1.9
*Sessione QA completa · Aprile 2026*

---

## Stato generale

L'app è funzionante in modalità pre-alpha su Flutter Web (DDC). Le aree core — Piste, Negozi, Garage, Profilo, Gestione, Admin — sono navigabili. I flussi Supabase (lettura, scrittura, RLS) sono operativi. I bug trovati in questa sessione sono stati tutti risolti o catalogati come TODO pianificati.

---

## Bug risolti durante la sessione QA

### 🔴 CRITICO — Provider non inizializzato (due istanze)

**Sintomo:** Exception in console — `"Tried to read the state of an uninitialized provider"` — al rendering delle schermate Admin e Garage.

**Causa:** In Riverpod 3, il metodo `build()` di un `Notifier` deve restituire lo stato iniziale **in modo sincrono**. Usare `unawaited(asyncMethod())` all'interno di `build()` esegue la parte sincrona di `asyncMethod()` prima che `build()` ritorni, e se quella parte accede a `state`, l'eccezione è inevitabile.

**File 1: `admin_providers.dart` — `AdminUsersController.build()`**
- Chiamava `unawaited(_loadPage(reset: true))`, la cui parte sincrona leggeva `state.query` e `state.roleFilter`.
- Fix: `Future.microtask(() => _loadPage(reset: true))`

**File 2: `garage_providers.dart` — `GarageController.build()`**
- Chiamava `_loadBuilds()` direttamente; il metodo iniziava con `state = state.copyWith(isLoading: true)` prima del primo `await`.
- Fix: `Future.microtask(() => _loadBuilds(repository: repository, userId: user.id))`

---

### 🔴 CRITICO — Admin non poteva aprire l'editor di piste non assegnate

**Sintomo:** Cliccando "Modifica scheda" su una pista nel pannello Admin (che non risulta nella `track_managers` dell'admin), la schermata restava vuota / non caricava.

**Causa:** `managedTrackDetailProvider` usava solo `fetchManagedTrackBySlug` (che filtra per `track_managers.user_id`). Se l'admin non era in `track_managers` per quella pista, il provider restituiva `null`.

**Fix — tre file:**
1. `tracks_repository.dart` (abstract): aggiunto metodo `fetchAnyTrackBySlug`.
2. `supabase_tracks_repository.dart`: implementazione senza filtro `is_public` né join su `track_managers`.
3. `tracks_providers.dart`: in `managedTrackDetailProvider`, se `managed == null && role == 'admin'`, fallback a `fetchAnyTrackBySlug`.

---

### 🟡 MEDIUM — Testo errato in Admin Settings (sezione Garage)

**Sintomo:** La scheda admin "Spot & Garage" descriveva le build del Garage come salvate in locale, quando la migrazione a Supabase era già completata.

**Fix:** Aggiornato il testo in `admin_settings_screen.dart` — ora riporta correttamente che `user_builds` è su Supabase.

---

### 🟡 MEDIUM — Accenti italiani mancanti (65+ istanze)

**Sintomo:** In tutta l'app comparivano `verra'`, `gia'`, `puo'`, `visibilita'`, `Modalita'` ecc. invece di `verrà`, `già`, `può`, `visibilità`, `Modalità`.

**Causa:** Il file ARB (`app_it.arb`) e le stringhe hardcoded usavano l'apostrofo ASCII come sostituto degli accenti italiani.

**File corretti:**
- `app/lib/app/l10n/arb/app_it.arb` — 62 righe corrette
- `app/lib/app/l10n/generated/app_localizations_it.dart` — righe allineate
- `features/tracks/presentation/track_editor_screen.dart` — 6 stringhe hardcoded
- `features/manager/presentation/manager_screen.dart` — 5 stringhe hardcoded

**Pattern corretti (completo):**
`piu'→più`, `gia'→già`, `verra'→verrà`, `sara'→sarà`, `potra'→potrà`, `puo'→può`, `cosi'→così`, `Modalita'→Modalità`, `visibilita'→visibilità`, `disponibilita'→disponibilità`, `identita'→identità`, `proprieta'→proprietà`, `societa'→società`, `entita'→entità`, `finalita'→finalità`, `citta'→città`, `specialita'→specialità`, `qualita'→qualità`, `anzianita'→anzianità`, `integrita'→integrità`, `responsabilita'→responsabilità`, `funzionalita'→funzionalità`, `Perche'→Perché`, `Poiche'→Poiché`, ` e' →è`, `E' →È`, `com'e'→com'è`, `preparera'→preparerà`, `ospitera'→ospiterà`, `presentera'→presenterà`.

---

## Problemi architetturali aperti (non bloccanti per pre-alpha)

### ⚠️ GoRouter ricreato al cambio di auth state

`appRouterProvider` è un `Provider` che fa `ref.watch` su `isAdminProvider`, `canManageTracksProvider` e `canManageShopsProvider`. Quando questi cambiano (es. il profilo utente carica e il ruolo diventa `admin`), il `GoRouter` viene ricreato da zero. Questo può causare:
- Perdita di navigation request in volo (race condition).
- In casi estremi, navigazione verso route protette che mostrano il contenuto sbagliato per un frame.

**Soluzione consigliata (post-alpha):** Usare il pattern `refreshListenable` di GoRouter con un `ChangeNotifier` che wrappa i provider, evitando la ricreazione dell'intero router.

**Impatto attuale:** Basso — non causa crash, ma può richiedere un secondo tap su certi pulsanti di navigazione se il profilo carica lentamente.

---

## Fix aggiuntivi sessione v0.1.9+1 (aprile 2026)

### ✅ Pagina 404 custom
Creato `core/widgets/not_found_screen.dart` — schermata standalone on-brand con logo PitLap, numero 404 in display, messaggio in italiano e CTA "Torna alla home". Aggiunto `errorBuilder` al `GoRouter` in `app_router.dart`.

### ✅ GoRouter non più ricreato al cambio auth state
`appRouterProvider` ora usa `ref.listen` (non `ref.watch`) + `_RouterNotifier extends ChangeNotifier`. Il `GoRouter` è creato una sola volta; al cambio di ruolo/login viene notificato tramite `refreshListenable` per rivalutare i redirect senza ricreazione. Risolve la race condition e il doppio-tap su navigazione.

### ✅ Mappa unificata piste + spot
- Nuovo modello `TrackMapPin` (slug, name, city, lat, lng, status).
- `fetchPublicTrackPins()` aggiunto a repository astratto e implementazione Supabase (query leggera, filtro `is_public=true AND approval_status=approved AND lat IS NOT NULL`).
- `publicTrackPinsProvider` in `tracks_providers.dart`.
- `spots_map_screen.dart` riscritto come mappa unificata:
  - Marker arancio con flag e dot di stato per le piste.
  - Marker blu/grafite con pin per gli spot.
  - Toggle layer piste/spot animati.
  - Pannello dettaglio adattivo (pista o spot in base alla selezione).
  - Barra contatori in fondo alla mappa.

---

## Verifiche pendenti (da testare post-hot-restart)

| Scenario | Stato | Note |
|---|---|---|
| Admin apre editor pista non assegnata | ✅ Verificato | Confermato via console log nella sessione |
| Admin naviga a `/manager/tracks/new` | ⚠️ Da riverificare | URL cambia correttamente; comportamento schermata da confermare con hot restart pulito |
| Garage screen — assenza di exception al caricamento | ✅ Fix applicato | Richiede hot restart per attivare |
| Admin Users — assenza di exception al caricamento | ✅ Fix applicato | Verificato nella sessione |

---

## Feature gap / TODO pianificati

### Spot — dati locali
Gli spot sono gestiti in memoria locale. Non esiste ancora una tabella Supabase `spots`. La sezione è funzionale per il demo ma non persistente.
**Pianificato:** Migrazione a Supabase nella prossima iterazione.

### Track approval → link `track_managers`
Quando un admin approva una pista inviata da un organizzatore, il sistema non crea automaticamente il record in `track_managers`. L'organizzatore vede la pista nella coda approvazioni ma non nella propria schermata Gestione fino a intervento manuale lato DB.
**Pianificato:** Edge function o trigger Supabase per creare il link automatico all'approvazione.

### Gestione — piste draft non editabili
Nella schermata Gestione, le piste in stato `draft` o `pending` compaiono nella lista "in preparazione" ma non hanno un pulsante "Modifica" che riapra il `TrackEditorScreen` prepopolato. L'utente può solo vedere lo stato.
**Pianificato:** Aggiungere navigazione a un `TrackEditorScreen` in modalità edit per i draft.

### Nessuna pagina 404
Navigare a una route inesistente non mostra una pagina di errore dedicata — GoRouter redirige silenziosamente alla home. Per la produzione sarà necessario un `errorBuilder` configurato nel router.

### Impersonificazione ruolo (Admin) — lato UI only
Il toggle impersonificazione in Admin Settings simula il ruolo solo lato UI (provider locale). Non modifica il JWT né le RLS policy di Supabase. Va documentato chiaramente nell'interfaccia per evitare confusione durante i test.

**✅ Fix applicato (sessione v0.1.9+1):** tooltip dell'icona "Osserva" aggiornato con nota esplicita "Solo UI — non modifica JWT né policy RLS"; SnackBar di attivazione allungato a 3 s con la stessa nota in coda.

---

## Riepilogo modifiche file

| File | Tipo modifica |
|---|---|
| `admin/application/admin_providers.dart` | Fix critico: `Future.microtask` in `build()` |
| `garage/application/garage_providers.dart` | Fix critico: `Future.microtask` in `build()` |
| `tracks/application/tracks_providers.dart` | Fix critico: admin fallback in `managedTrackDetailProvider` |
| `shared/repositories/tracks_repository.dart` | Nuovo metodo `fetchAnyTrackBySlug` |
| `tracks/infrastructure/supabase_tracks_repository.dart` | Implementazione `fetchAnyTrackBySlug` |
| `admin/presentation/admin_settings_screen.dart` | Fix testo sezione Garage |
| `tracks/presentation/track_editor_screen.dart` | Fix 6 copy bug (accenti) |
| `manager/presentation/manager_screen.dart` | Fix 5 copy bug (accenti) |
| `app/l10n/arb/app_it.arb` | Fix 62 righe con accenti mancanti |
| `app/l10n/generated/app_localizations_it.dart` | Sincronizzato con ARB |

---

*Report generato al termine della sessione QA pre-alpha v0.1.9 · PitLap*
