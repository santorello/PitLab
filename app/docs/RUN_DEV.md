# Run Dev

Esecuzione dell'app PitLap collegata all'ambiente Supabase `dev`.

## Prerequisiti

- progetto Supabase `pitlap-dev` creato
- `Project URL` disponibile
- `Publishable key` disponibile
- file locale `.\config\dev.local.json` creato a partire da `.\config\dev.example.json`

## Comando web

```powershell
$flutter = 'C:\Users\beppe\Downloads\Posso Volare\flutter\bin\flutter.bat'

& $flutter run -d chrome `
  --web-port=58977 `
  --dart-define-from-file=.\config\dev.local.json
```

Nota operativa:

- incollare il comando senza i prompt `>>` di PowerShell
- usare solo la chiave `sb_publishable_...`
- tenere una porta web fissa in sviluppo per semplificare i redirect auth
- aggiungere `http://localhost:58977/**` negli Allowed Redirect URLs di Supabase
- dopo modifiche a dipendenze o bootstrap preferire `R` oppure un restart completo
- tenere `dev.local.json` fuori dal repository

## Script unico

Per eseguire `pub get`, `gen-l10n`, `analyze`, `test` e poi avviare Chrome:

```powershell
& '.\docs\run-dev.ps1'
```

## Comando Android

```powershell
$flutter = 'C:\Users\beppe\Downloads\Posso Volare\flutter\bin\flutter.bat'

& $flutter run -d android `
  --dart-define-from-file=.\config\dev.local.json
```

## Comando analyze

```powershell
& $flutter analyze
```

## Comando test

```powershell
& $flutter test
```

## Regole

- non usare `sb_secret_...` nel client
- non salvare la secret key nel repository
- se una secret key e' stata condivisa o esposta, va ruotata subito
- la `publishable key` puo' stare nel file locale di sviluppo, ma non va hardcodata negli script versionati
