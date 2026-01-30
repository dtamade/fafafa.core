#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$SCRIPT_DIR/ui_showcase.lpi"
EXE="$SCRIPT_DIR/bin/ui_showcase"

# Try using tools/lazbuild.sh if available, else system lazbuild
if [[ -x "$SCRIPT_DIR/../../tools/lazbuild.sh" ]]; then
  LAZBUILD="$SCRIPT_DIR/../../tools/lazbuild.sh"
else
  LAZBUILD="lazbuild"
fi

mkdir -p "$SCRIPT_DIR/bin" "$SCRIPT_DIR/lib"

echo "Building: $PROJECT"
"$LAZBUILD" "$PROJECT"

echo "Build successful."

if [[ "${1:-}" == "run" ]]; then
  if [[ -f "$EXE" ]]; then
    echo "Running: $EXE"
    "$EXE"
  else
    echo "Executable not found: $EXE"
    exit 1
  fi
else
  echo "To run: ./BuildOrRun_UI_Showcase.sh run"
fi

