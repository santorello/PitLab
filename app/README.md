# PitLap — App Flutter

App Flutter di PitLap, runtime Android + Web, backend Supabase.

Per documentazione di prodotto, roadmap, decision log e test plan vedi la cartella [`../docs/`](../docs/). La direzione architetturale e' nella [roadmap master](../docs/roadmap.md) e nel [decision log](../docs/decision-log.md).

## Quickstart sviluppo

### Configurazione

Il backend Supabase viene configurato via `--dart-define` da file JSON. Esempi pronti:

- `config/dev.json` — config condivisa per ambiente dev (committata)
- `config/dev.local.json` — config personale (gitignored, opzionale)

Se entrambi esistono, gli script preferiscono il file `local` su quello shared.

### Run su Chrome

Dalla root del progetto:

**Windows (PowerShell o cmd)**:

```
.\run_dev.bat
```

**Linux / macOS**:

```
./run_dev.sh
```

**PowerShell con pre-flight checks (pub get + gen-l10n + analyze + test)**:

```
cd app\docs
.\run-dev.ps1
```

Flag opzionali sul `run-dev.ps1`:

- `-SkipChecks` salta analyze + test (utile durante QA, parte solo `pub get` + `gen-l10n` + `run`)
- `-SkipTests` salta solo i test

Tutti gli script lanciano Flutter su porta fissa **8080**, URL stabile `http://localhost:8080/`.

### Run a mano

Se vuoi controllare ogni flag:

```
cd app
flutter run -d chrome \
  --dart-define-from-file=config/dev.json \
  --web-port=8080
```

### Analyze / test / gen-l10n

```
cd app
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

## Struttura cartelle `lib/`

```
lib/
├── app/                  # bootstrap, theme, l10n, routing
│   ├── bootstrap/        # entry point, app config, redirect auth
│   ├── theme/            # AppColors, AppSpacing, AppRadius, AppBreakpoints, AppTheme
│   ├── l10n/             # ARB + classi generate IT/EN
│   └── navigation/       # GoRouter + guard di route
├── core/widgets/         # AppScaffold, ContentScaffold, ContentScaffoldHeader, NotFoundScreen
├── shared/               # codice condiviso tra feature
│   ├── widgets/          # PlaceCard, Pill, StatusBadge, MetaRow, AdaptiveImage, ecc.
│   ├── media/            # MediaUploadController + LocalImageDataUrl
│   ├── models/           # model condivisi (track_list_item, track_detail, ecc.)
│   └── repositories/     # repository interface
└── features/             # una sottocartella per feature
    ├── auth/             # login, sessione, ruoli effettivi
    ├── tracks/           # piste: lista, dettaglio, editor, arrivals
    ├── shops/            # negozi: lista, dettaglio, editor
    ├── spots/            # spot: lista, mappa, dettaglio, editor
    ├── events/           # eventi community
    ├── garage/           # build personali
    ├── profile/          # profilo utente + public profile
    ├── manager/          # cockpit gestore pista
    ├── admin/            # pannello admin + impersonazione
    ├── community/        # activity feed home
    ├── discovery/        # nearby
    ├── onboarding/       # flusso onboarding 4 step
    ├── submissions/      # submit-place (spot/track/shop)
    └── legal/            # privacy/terms/cookies
```

Convenzioni:

- `presentation/` per screen + widget
- `application/` per provider Riverpod + controller
- `domain/` per model puri e logica di business
- `infrastructure/` per repository concreti (Supabase)

## Stack

- **Flutter** 3.x (Android + Web tramite CanvasKit)
- **Supabase** (Auth magic link + Postgres + Storage + Realtime)
- **Riverpod** per state management
- **go_router** 17.x per navigation
- **MapTiler** per mappe interattive (`/spots/map`)
- **Open-Meteo** per meteo pista

## Riferimenti documentazione

- [Design system](../docs/design-system.md) — token, componenti, pattern UI
- [Test checklist](../docs/test-checklist.md) — TC numerati + bug walkthrough
- [Roadmap](../docs/roadmap.md) — fasi, Gate Alpha, backlog post-MVP
- [Decision log](../docs/decision-log.md) — decisioni storiche datate
- [Permissions matrix](../docs/permissions-matrix.md) — ruoli e capability
- [Media strategy](../docs/media-strategy.md) — pipeline upload, moderation, modulo client
- [Supabase setup dev](../docs/supabase-dev-setup.md) — bootstrap backend locale

## Bug noti pre-Alpha

Vedi `docs/test-checklist.md` sezione "Walkthrough sessione 3 (2026-05-09)" per la lista corrente. Bug ancora aperti significativi:

- TC-WT-21: navigation tra rotte lascia widgets sovrapposti (P2, F5 pulisce)
- TC-WT-22: impersonazione admin persa al reload (P3)
- TC-WT-17: event detail manca CTA RSVP/calendar (P3)
