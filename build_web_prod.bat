@echo off
REM ============================================================
REM Build PitLap WEB per PRODUZIONE (Cloudflare Pages)
REM Output in app\build\web\  -> da pubblicare su Cloudflare Pages
REM Punta al progetto Supabase PROD (pitlap-prod).
REM ============================================================

set FLUTTER="C:\Users\beppe\Downloads\Posso Volare\flutter\bin\flutter.bat"
set SCRIPT_DIR=%~dp0
set CONFIG=%SCRIPT_DIR%app\config\prod.json

cd /d "%SCRIPT_DIR%app"

echo Build PitLap web (PRODUZIONE)...
echo Config: %CONFIG%
echo.

REM Pagine SEO statiche (schede, hub, sitemap.xml, robots.txt) lette da PROD.
REM Vanno in app\web\ e Flutter le copia nella build. Se fallisce, niente deploy.
REM Cerca Python: prima il launcher "py", poi "python" (l'alias del Microsoft Store
REM risponde con errore 9009 e viene scartato).
set PY=
where py >nul 2>nul && set PY=py -3
if not defined PY (
  python --version >nul 2>nul && set PY=python
)
if not defined PY (
  echo ERRORE: Python 3 non installato. Installalo con:
  echo     winget install -e --id Python.Python.3.12
  echo poi chiudi e riapri il terminale e rilancia questo script.
  exit /b 1
)
%PY% "%SCRIPT_DIR%tools\build_seo_pages.py" --config "%CONFIG%" --out "%SCRIPT_DIR%app\web"
if errorlevel 1 (
  echo ERRORE: generazione pagine SEO fallita. Build interrotta.
  exit /b 1
)
echo.

REM --release: build ottimizzata e minificata
REM --base-href "/": Cloudflare Pages serve dalla radice del dominio
REM "call" e' obbligatorio: flutter e' un .bat e senza call questo script finirebbe qui.
call %FLUTTER% build web --release --base-href "/" --dart-define-from-file="%CONFIG%"
if errorlevel 1 (
  echo ERRORE: flutter build fallita.
  exit /b 1
)

echo.
echo Build PROD completata in app\build\web\
echo Pubblica il contenuto di app\build\web\ su Cloudflare Pages.
echo.
echo Quando il deploy e' online, premi un tasto: avviso Bing delle pagine (IndexNow).
echo Ctrl+C per saltare. Per rifarlo a mano: py tools\build_seo_pages.py --indexnow
pause >nul
%PY% "%SCRIPT_DIR%tools\build_seo_pages.py" --out "%SCRIPT_DIR%app\web" --indexnow
if errorlevel 1 echo ATTENZIONE: IndexNow non riuscito. Se e' 403 il deploy non e' ancora online: riprova dopo.
