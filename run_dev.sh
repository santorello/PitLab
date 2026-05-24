#!/bin/bash
# Avvia PitLap in modalità sviluppo su Chrome.
# Legge URL, chiavi e variabili da app/config/dev.json.
#
# Uso:
#   ./run_dev.sh            → Chrome (default)
#   ./run_dev.sh -d web     → web server headless
#
# Per aggiungere la chiave MapTiler, modifica app/config/dev.json:
#   "MAPTILER_API_KEY": "la_tua_chiave"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
CONFIG_FILE="$APP_DIR/config/dev.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌  Config non trovata: $CONFIG_FILE"
  exit 1
fi

cd "$APP_DIR"

DEVICE="${1:--d chrome}"

echo "🚀  Avvio PitLap dev su Chrome..."
echo "📄  Config: $CONFIG_FILE"
echo ""

flutter run $DEVICE \
  --dart-define-from-file="$CONFIG_FILE" \
  --web-port=8080
