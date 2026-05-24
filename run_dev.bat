@echo off
setlocal enabledelayedexpansion
title PitLap - Dev Runner

REM Entry point unico per sviluppo locale PitLap su Windows.
REM Uso:
REM   run_dev.bat              avvia in debug su Chrome, porta 8080
REM   run_dev.bat run          avvia in debug su Chrome, porta 8080
REM   run_dev.bat debug        alias di run
REM   run_dev.bat qa           analyze + test + run
REM   run_dev.bat analyze      solo flutter analyze
REM   run_dev.bat test         solo flutter test
REM   run_dev.bat build        flutter build web
REM   run_dev.bat compile      alias di build
REM   run_dev.bat gen-l10n     rigenera localizzazioni
REM   run_dev.bat pub-get      flutter pub get

set "FLUTTER=C:\Users\beppe\Downloads\Posso Volare\flutter\bin\flutter.bat"
set "SCRIPT_DIR=%~dp0"
set "APP_DIR=%SCRIPT_DIR%app"
set "CONFIG=%APP_DIR%\config\dev.json"
set "WEB_PORT=8080"
set "MODE=%~1"

if "%MODE%"=="" set "MODE=run"

echo.
echo  =====================================================
echo       PitLap - Dev Runner
echo  =====================================================
echo.
echo  Modalita': %MODE%
echo  App:       %APP_DIR%
echo  Config:    %CONFIG%
echo  Porta web: %WEB_PORT%
echo.

call :check_prerequisites
if errorlevel 1 goto :end

cd /d "%APP_DIR%"

if /I "%MODE%"=="run" goto :run
if /I "%MODE%"=="debug" goto :run
if /I "%MODE%"=="qa" goto :qa
if /I "%MODE%"=="all" goto :qa
if /I "%MODE%"=="analyze" goto :analyze_only
if /I "%MODE%"=="test" goto :test_only
if /I "%MODE%"=="build" goto :build
if /I "%MODE%"=="compile" goto :build
if /I "%MODE%"=="gen-l10n" goto :gen_l10n
if /I "%MODE%"=="pub-get" goto :pub_get
if /I "%MODE%"=="help" goto :help
if /I "%MODE%"=="--help" goto :help

echo  [ERRORE] Modalita' non riconosciuta: %MODE%
echo.
goto :help

:check_prerequisites
if not exist "%FLUTTER%" (
    echo  [ERRORE] Flutter non trovato:
    echo  %FLUTTER%
    echo.
    echo  Aggiorna la variabile FLUTTER in run_dev.bat.
    echo.
    exit /b 1
)

if not exist "%APP_DIR%" (
    echo  [ERRORE] Cartella app mancante:
    echo  %APP_DIR%
    echo.
    exit /b 1
)

if not exist "%CONFIG%" (
    echo  [ERRORE] Config mancante:
    echo  %CONFIG%
    echo.
    echo  Assicurati che app\config\dev.json esista.
    echo.
    exit /b 1
)
exit /b 0

:qa
call :analyze
if errorlevel 1 (
    set /p CONT_A="  Analyze ha trovato problemi. Continuare comunque? [s/N] "
    if /I not "!CONT_A!"=="s" goto :end
)

call :test
if errorlevel 1 (
    set /p CONT_T="  Alcuni test sono falliti. Avviare comunque? [s/N] "
    if /I not "!CONT_T!"=="s" goto :end
)

goto :run

:analyze_only
call :analyze
goto :end

:test_only
call :test
goto :end

:analyze
echo.
echo  =====================================================
echo  FLUTTER ANALYZE
echo  -----------------------------------------------------
echo.
call "%FLUTTER%" analyze
set "LAST_EXIT=%ERRORLEVEL%"
if %LAST_EXIT% EQU 0 (
    echo.
    echo  [OK] Analyze completato senza errori.
)
exit /b %LAST_EXIT%

:test
echo.
echo  =====================================================
echo  FLUTTER TEST
echo  -----------------------------------------------------
echo.
call "%FLUTTER%" test
set "LAST_EXIT=%ERRORLEVEL%"
if %LAST_EXIT% EQU 0 (
    echo.
    echo  [OK] Test completati.
)
exit /b %LAST_EXIT%

:run
echo.
echo  =====================================================
echo  AVVIO DEBUG LOCALE
echo  -----------------------------------------------------
echo.
echo  URL atteso: http://localhost:%WEB_PORT%/
echo  Premi Ctrl+C per fermare l'app.
echo.
call "%FLUTTER%" run -d chrome --dart-define-from-file="%CONFIG%" --web-port=%WEB_PORT%
goto :end

:build
echo.
echo  =====================================================
echo  BUILD WEB
echo  -----------------------------------------------------
echo.
call "%FLUTTER%" build web --dart-define-from-file="%CONFIG%"
goto :end

:gen_l10n
echo.
echo  =====================================================
echo  GEN L10N
echo  -----------------------------------------------------
echo.
call "%FLUTTER%" gen-l10n
goto :end

:pub_get
echo.
echo  =====================================================
echo  PUB GET
echo  -----------------------------------------------------
echo.
call "%FLUTTER%" pub get
goto :end

:help
echo  Comandi disponibili:
echo.
echo    run_dev.bat              avvia in debug su Chrome
echo    run_dev.bat run          avvia in debug su Chrome
echo    run_dev.bat debug        alias di run
echo    run_dev.bat qa           analyze + test + run
echo    run_dev.bat analyze      solo analyze
echo    run_dev.bat test         solo test
echo    run_dev.bat build        build web
echo    run_dev.bat compile      alias di build
echo    run_dev.bat gen-l10n     rigenera localizzazioni
echo    run_dev.bat pub-get      scarica/aggiorna dipendenze Flutter
echo.
goto :end

:end
set "FINAL_EXIT=%ERRORLEVEL%"
echo.
echo  Fine. Exit code: %FINAL_EXIT%
echo.
pause
exit /b %FINAL_EXIT%
