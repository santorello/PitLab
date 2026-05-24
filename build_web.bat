@echo off
REM Build PitLap per il web (Windows)
REM Output in app\build\web\

set FLUTTER="C:\Users\beppe\Downloads\Posso Volare\flutter\bin\flutter.bat"
set SCRIPT_DIR=%~dp0
set CONFIG=%SCRIPT_DIR%app\config\dev.json

cd /d "%SCRIPT_DIR%app"

echo Build PitLap web...
echo Config: %CONFIG%
echo.

%FLUTTER% build web --dart-define-from-file="%CONFIG%"

echo.
echo Build completata in app\build\web\
