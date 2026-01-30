#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRJ="$SCRIPT_DIR/example_gcm_bench.lpi"

: "${LAZBUILD_EXE:=lazbuild}"
"$LAZBUILD_EXE" --build-mode=Release "$PRJ"

BIN="$SCRIPT_DIR/example_gcm_bench"
if [[ -f "$BIN" ]]; then
  echo
  echo "[run] $BIN"
  "$BIN"
else
  BIN_EXE="$SCRIPT_DIR/example_gcm_bench.exe"
  if [[ -f "$BIN_EXE" ]]; then
    echo
    echo "[run] $BIN_EXE"
    "$BIN_EXE"
  else
    echo "[error] built binary not found"
    exit 1
  fi
fi

