#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
TARGET_FILE="$ROOT_DIR/src/fafafa.core.os.unix.inc"

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "[FAIL] missing target file: $TARGET_FILE"
  exit 1
fi

if rg -n '\{\$ELSEIF\b' "$TARGET_FILE"; then
  echo "[FAIL] $TARGET_FILE still contains {\$ELSEIF}; keep this include on nested {\$IFDEF}/{\$ELSE}/{\$ENDIF} chains for older FPC compatibility."
  exit 1
fi

echo "[PASS] $TARGET_FILE avoids {\$ELSEIF} and stays compatible with older FPC conditional parsing."
