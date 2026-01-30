#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
LAZBUILD="${LAZBUILD:-lazbuild}"
PROJECT="$SCRIPT_DIR/example_json.lpr"
BIN_DIR="$SCRIPT_DIR/bin"
mkdir -p "$BIN_DIR"

echo "[BUILD] $PROJECT"; "$LAZBUILD" "$PROJECT" --bm=Debug --ws=nogui || { echo "[BUILD] FAILED $PROJECT"; exit 1; }

EXE="$BIN_DIR/example_json"
if [[ -x "$EXE" || -f "$EXE" ]]; then
  echo "[RUN] example_json"
  "$EXE" || { echo "[RUN] FAILED example_json"; exit 1; }
else
  echo "[RUN] NOT_FOUND $EXE"; exit 1
fi

