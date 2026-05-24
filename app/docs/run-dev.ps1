param(
  [switch]$SkipChecks,
  [switch]$SkipTests
)

$flutter = 'C:\Users\beppe\Downloads\Posso Volare\flutter\bin\flutter.bat'

# Working directory deve essere app/ per i comandi flutter (pub get, gen-l10n, analyze, test, run)
$appDir = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $appDir
Write-Host "Working dir: $appDir" -ForegroundColor DarkGray

# Preferisce dev.local.json (config personale) se esiste, altrimenti usa dev.json (config condiviso).
$localConfig = Join-Path $appDir 'config\dev.local.json'
$sharedConfig = Join-Path $appDir 'config\dev.json'

if (Test-Path $localConfig) {
  $configPath = $localConfig
  Write-Host "Uso config locale: $configPath" -ForegroundColor Cyan
} elseif (Test-Path $sharedConfig) {
  $configPath = $sharedConfig
  Write-Host "Uso config condiviso: $configPath" -ForegroundColor Cyan
} else {
  Write-Host "Nessuna config trovata in app/config/" -ForegroundColor Red
  Write-Host "Atteso: dev.json o dev.local.json" -ForegroundColor Yellow
  exit 1
}

# pub get e' bloccante: serve per avere le dipendenze
& $flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# gen-l10n bloccante: serve per avere le classi di localizzazione aggiornate
& $flutter gen-l10n
if ($LASTEXITCODE -ne 0) {
  Write-Host "ATTENZIONE: gen-l10n ha restituito errore, ma i file generati esistono gia' - continuo." -ForegroundColor Yellow
}

# analyze e test sono pre-flight non bloccanti: utili come allerta ma non devono impedire il run.
# Usa -SkipChecks per saltare entrambi, -SkipTests per saltare solo i test.
if (-not $SkipChecks) {
  Write-Host "--- flutter analyze (non bloccante) ---" -ForegroundColor DarkGray
  & $flutter analyze
  if ($LASTEXITCODE -ne 0) {
    Write-Host "analyze ha trovato problemi (vedi sopra). Continuo con il run." -ForegroundColor Yellow
  }
}

if (-not $SkipChecks -and -not $SkipTests) {
  Write-Host "--- flutter test (non bloccante) ---" -ForegroundColor DarkGray
  & $flutter test
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Alcuni test falliscono (vedi sopra). Continuo con il run." -ForegroundColor Yellow
  }
}

# Libera la porta se già occupata da un processo precedente
$port = 8080
$pids = (netstat -ano | Select-String ":$port\s" | ForEach-Object {
  ($_ -split '\s+')[-1]
}) | Sort-Object -Unique
foreach ($p in $pids) {
  if ($p -match '^\d+$' -and $p -ne '0') {
    Write-Host "Termino processo su porta $port (PID $p)..."
    taskkill /PID $p /F 2>$null
  }
}
Start-Sleep -Milliseconds 500

& $flutter run -d chrome `
  --web-port=$port `
  --dart-define-from-file=$configPath
