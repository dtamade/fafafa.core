#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN="$SCRIPT_DIR/bin/paste_storage_demo"

if [[ ! -x "$BIN" ]]; then
  echo "[INFO] paste_storage_demo not found or not executable. Trying to build examples..."
  if [[ -x "$SCRIPT_DIR/build_examples.sh" ]]; then
    bash "$SCRIPT_DIR/build_examples.sh"
  else
    echo "[ERROR] build_examples.sh not found. Cannot build demo." >&2
    exit 1
  fi
fi

if [[ -x "$BIN" ]]; then
  echo "Running paste_storage_demo ..."
  "$BIN"
else
  # Some environments produce .exe even on WSL; try fallback
  if [[ -x "$BIN.exe" ]]; then
    echo "Running paste_storage_demo.exe ..."
    "$BIN.exe"
  else
    echo "[ERROR] Unable to find or build paste_storage_demo binary." >&2
    exit 1
  fi
fi

