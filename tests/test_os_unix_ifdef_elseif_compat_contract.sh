#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
TARGET_FILES=(
  "$ROOT_DIR/src/fafafa.core.os.unix.inc"
  "$ROOT_DIR/src/fafafa.core.env.pas"
  "$ROOT_DIR/src/fafafa.core.sync.mutex.pas"
)
LFailed=0

for TARGET_FILE in "${TARGET_FILES[@]}"; do
  if [[ ! -f "$TARGET_FILE" ]]; then
    echo "[FAIL] missing target file: $TARGET_FILE"
    exit 1
  fi

  if rg -n '\{\$ELSEIF\b' "$TARGET_FILE"; then
    echo "[FAIL] $TARGET_FILE still contains {\$ELSEIF}; keep this strict-L0 compatibility subset on nested {\$IFDEF}/{\$ELSE}/{\$ENDIF} chains for older FPC compatibility."
    LFailed=1
  fi
done

if [[ "$LFailed" -ne 0 ]]; then
  exit 1
fi

echo "[PASS] strict-L0 compatibility subset avoids {\$ELSEIF} and stays compatible with older FPC conditional parsing."
