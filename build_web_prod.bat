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

REM --release: build ottimizzata e minificata
REM --base-href "/": Cloudflare Pages serve dalla radice del dominio
%FLUTTER% build web --release --base-href "/" --dart-define-from-file="%CONFIG%"

echo.
echo Build PROD completata in app\build\web\
echo Pubblica il contenuto di app\build\web\ su Cloudflare Pages.
