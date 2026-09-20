# Rebrand TrackHub → PitLap — Checklist finale

**Data:** 2026-05-20
**Stato lavoro Claude:** completato (codice, docs, asset). Restano step manuali sotto.

---

## Cosa è già stato fatto (riferimento)

Modifiche applicate al repo (159 + 103 = 262 sostituzioni totali, 65+ file toccati):

- `app/pubspec.yaml`: `name: pitlap_app`, description aggiornata
- `app/android/app/build.gradle.kts`: `namespace` e `applicationId` → `com.pitlap.app`
- `app/android/app/src/main/AndroidManifest.xml`: `android:label="PitLap"`
- `app/android/app/src/main/kotlin/com/pitlap/app/MainActivity.kt`: nuovo path + nuovo package
- `app/web/index.html`: `<title>`, meta description, apple-mobile-web-app-title
- `app/web/manifest.json`: `name`/`short_name`/`description`
- Tutti i `.dart` in `app/lib/` (esclusi i generated i18n) e `app/test/`
- ARB sorgenti `app_en.arb`, `app_it.arb` (32+32 stringhe utente)
- Tutti i `.md` in root + `docs/` + `docs/legal/`
- Script `.bat` e `.sh`
- `supabase/seed_demo.sql`
- `app/.idea/modules.xml` + rinomina `.iml` (`trackhub_app.iml` → `pitlap_app.iml`)
- File rinominati: `mockup-trackhub.svg` → `mockup-pitlap.svg`, `TrackHub_Review_*.docx` → `PitLap_Review_*.docx`, `TrackHub_Update_*.docx` → `PitLap_Update_*.docx`

Verifica grep finale: zero occorrenze residue di `trackhub`/`TrackHub`/`TRACKHUB` nei file sorgente.

---

## Step 1 — Pulizia residui filesystem (5 min)

In Esplora File Windows, dentro `Z:\ProgettiSviluppo\TrackHub\app\android\app\src\main\kotlin\com\`:

- Elimina la cartella `trackhub\` (è vuota — il mount Linux non è riuscito a rimuoverla)

Le cache si autorigenerano, ma per stare puliti puoi cancellare manualmente:

- `app\android\.gradle\`
- `app\android\.kotlin\`
- `app\.dart_tool\`
- `app\build\`

---

## Step 2 — Verifica build locale Flutter (10–15 min)

In Windows, **PowerShell** dalla cartella `Z:\ProgettiSviluppo\TrackHub\app\`:

```powershell
$flutter = 'C:\Users\beppe\Downloads\Posso Volare\flutter\bin\flutter.bat'

# 1. Reset pulito
& $flutter clean

# 2. Riscarica dipendenze (riscriverà pubspec.lock)
& $flutter pub get

# 3. Rigenera i file i18n dai nuovi ARB (creerà i .dart in lib/app/l10n/generated/)
& $flutter gen-l10n

# 4. Static analysis — deve passare senza errori
& $flutter analyze

# 5. Test suite
& $flutter test
```

**Se `flutter analyze` o `flutter test` falliscono:** segnala l'errore a Claude e si sistema in 2 minuti. Le aree a rischio sono:

- import residui non aggiornati (improbabili, ma possibili)
- generated i18n non rigenerati (basta rilanciare `flutter gen-l10n`)
- test che assumono il vecchio package name

---

## Step 3 — Smoke test runtime (10 min)

```powershell
# Web
& $flutter run -d chrome --web-port=58977 --dart-define-from-file=.\config\dev.local.json

# Android (con device/emulatore collegato)
& $flutter run -d android --dart-define-from-file=.\config\dev.local.json
```

Verifica visiva:

- Titolo browser → "PitLap - Dove il modellismo si incontra"
- Splash/icona Android → label "PitLap"
- Login funziona (testa il callback OAuth — vedi Step 4)
- Stringhe UI tradotte mostrano "PitLap" e non più "TrackHub"

---

## Step 4 — Rinomina progetto Supabase remoto (5 min)

**Non si può via API. Va fatto da dashboard Supabase.**

Procedura:

1. Apri https://supabase.com/dashboard/project/mqieterttnqdtdguaqoe
2. Settings → General → Project name
3. Cambia `trackhub-dev` → `pitlap-dev` → Save

**Importante:** il rename è puramente cosmetico. Il `ref` del progetto resta `mqieterttnqdtdguaqoe`, l'URL `db.mqieterttnqdtdguaqoe.supabase.co` non cambia, le API keys restano valide. L'app **non** va riconfigurata.

**Edge functions:** zero deployate (verificato via MCP). Niente da rinominare.

**Email auth templates** (Authentication → Email Templates):

Controlla i 6 template (Confirm signup, Invite, Magic link, Change email, Reset password, Reauthentication) e cerca eventuali occorrenze di "TrackHub" nel testo HTML/markdown. Se trovate, sostituiscile con "PitLap". Sono editabili direttamente da UI.

**Allowed Redirect URLs** (Authentication → URL Configuration):

Se hai aggiunto URL contenenti `trackhub` (es. `https://trackhub.app/auth/callback`), aggiungi gli equivalenti `pitlap.app`. Mantieni i vecchi finché non sei sicuro che nessuno li usi.

---

## Step 5 — Rinomina cartella workspace (1 min)

**Ultimissimo step, dopo che build + test passano.**

In Esplora File Windows:

- `Z:\ProgettiSviluppo\TrackHub\` → `Z:\ProgettiSviluppo\PitLap\`

Riapri il progetto da Android Studio/VS Code dal nuovo path.

**Nota:** gli script `.bat` referenziano path relativi (nessun hardcoded `Z:\ProgettiSviluppo\TrackHub\` trovato), quindi non si rompono. Il file `docs\RUN_DEV.md` accennava al vecchio path solo in commenti — già aggiornato.

---

## Step 6 — Repo Git (se versionato, 5 min)

Verifica se la cartella è un repo Git:

```powershell
cd Z:\ProgettiSviluppo\PitLap
git status
```

Se sì:

```powershell
# Stage tutto
git add -A

# Commit rebrand come singolo commit dedicato
git commit -m "rebrand: TrackHub → PitLap

- App display name: PitLap
- Android applicationId/namespace: com.pitlap.app
- Dart package: pitlap_app
- Bootstrap class: PitLapBootstrap
- Web manifest + index.html
- ARB i18n strings (en + it)
- All docs + scripts
- Tagline: Dove il modellismo si incontra
- Supabase project renamed (cosmetic): trackhub-dev → pitlap-dev
- New canonical domain: pitlap.app"

# Se hai un remoto su GitHub/GitLab, rinomina anche il repo da UI
# (Settings → Repository name), poi aggiorna l'origin localmente:
git remote set-url origin <nuovo-url>
```

---

## Step 7 — Acquisto domini e handle social (15 min, da fare tu)

- [ ] Compra `pitlap.app` (primario) su Namecheap/Cloudflare
- [ ] Compra `pitlap.it` (secondario, redirect → .app) su un registrar `.it`
- [ ] Considera anche `pitlap.com` se libero (terzo livello di protezione brand)
- [ ] Registra handle `@pitlap` su Instagram, TikTok, X, YouTube — anche solo per parking

---

## Step 8 — Asset visuali (separato, non bloccante)

Logo, app icon, splash, favicon — al momento sono ancora i placeholder Flutter generici. Quando vorrai mettere mano alla brand identity:

- App icon Android: sostituisci `app/android/app/src/main/res/mipmap-*/ic_launcher.*`
- Web icons: sostituisci `app/web/icons/Icon-*.png` + `favicon.png`
- Splash Android: sostituisci `app/android/app/src/main/res/drawable*/launch_background.xml`

---

## Riepilogo decisioni tecniche prese il 2026-05-20

| Cosa | Vecchio | Nuovo |
|---|---|---|
| Android applicationId + namespace | `com.trackhub.app.trackhub_app` | `com.pitlap.app` |
| Dart package | `trackhub_app` | `pitlap_app` |
| Classe bootstrap | `TrackHubBootstrap` | `PitLapBootstrap` |
| Dominio canonico | (nessuno) | `pitlap.app` |
| Progetto Supabase | `trackhub-dev` | `pitlap-dev` |
| App display name | `trackhub_app` | `PitLap` |
| Tagline | (nessuna ufficiale) | `Dove il modellismo si incontra` |

---

## Se qualcosa va storto

Apri Claude e dimmi: "Sono allo Step X, errore: ..." — ho memoria del progetto e del rebrand, riparto da dove serve in pochi minuti.
