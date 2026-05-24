@echo off
setlocal enabledelayedexpansion
title PitLap -- QA + Avvio Dev

REM Le virgolette DEVONO essere dentro la variabile, come in run_dev.bat
set FLUTTER="C:\Users\beppe\Downloads\Posso Volare\flutter\bin\flutter.bat"
set SCRIPT_DIR=%~dp0
set APP_DIR=%SCRIPT_DIR%app
set CONFIG=%APP_DIR%\config\dev.json

REM =====================================================
echo.
echo  =====================================================
echo       PitLap  --  Analyze + Test + Avvio Dev
echo  =====================================================
echo.

REM ── Controlli prerequisiti ────────────────────────────
if not exist %FLUTTER% (
    echo  [ERRORE] Flutter non trovato:
    echo  %FLUTTER%
    echo.
    echo  Aggiorna il percorso FLUTTER in questo file .bat
    echo.
    pause
    exit /b 1
)

if not exist "%CONFIG%" (
    echo  [ERRORE] Config mancante: %CONFIG%
    echo  Assicurati che app\config\dev.json esista.
    echo.
    pause
    exit /b 1
)

cd /d "%APP_DIR%"

REM ── 1. Analyze ────────────────────────────────────────
echo  [1/3]  FLUTTER ANALYZE
echo  -----------------------------------------------------
echo.

%FLUTTER% analyze
set ANALYZE_EXIT=%ERRORLEVEL%

echo.
if %ANALYZE_EXIT% EQU 0 (
    echo  [OK] Analyze completato senza errori.
) else (
    echo  [ATTENZIONE] Analyze ha trovato problemi.
    echo.
    set /p CONT_A="  Continuare comunque? [s/N] "
    if /i "!CONT_A!" NEQ "s" (
        echo.
        echo  Uscita. Risolvi i problemi e riprova.
        echo.
        pause
        exit /b %ANALYZE_EXIT%
    )
)

REM ── 2. Test ───────────────────────────────────────────
echo.
echo  =====================================================
echo  [2/3]  FLUTTER TEST
echo  -----------------------------------------------------
echo.

%FLUTTER% test
set TEST_EXIT=%ERRORLEVEL%

echo.
if %TEST_EXIT% EQU 0 (
    echo  [OK] Test completati -- tutti passati.
) else (
    echo  [ATTENZIONE] Alcuni test sono falliti.
    echo.
    set /p CONT_T="  Avviare l'app comunque? [s/N] "
    if /i "!CONT_T!" NEQ "s" (
        echo.
        echo  Uscita. Risolvi i test e riprova.
        echo.
        pause
        exit /b %TEST_EXIT%
    )
)

REM ── 3. Avvio Chrome ───────────────────────────────────
echo.
echo  =====================================================
echo  [3/3]  AVVIO IN CHROME
echo  -----------------------------------------------------
echo.
echo  Config: %CONFIG%
echo  Premi Ctrl+C per fermare l'app.
echo.

%FLUTTER% run -d chrome --dart-define-from-file="%CONFIG%"

echo.
echo  App terminata.
echo.
pause
