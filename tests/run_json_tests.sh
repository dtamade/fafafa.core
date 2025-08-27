#!/usr/bin/env bash
set -euo pipefail

# Simple runner to build and run fafafa.core.json test suite (Linux/macOS)
# Usage:
#   chmod +x tests/run_json_tests.sh
#   tests/run_json_tests.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ="$ROOT/fafafa.core.json/tests_json.lpi"
BIN="$ROOT/fafafa.core.json/bin"

if [[ ! -f "$PROJ" ]]; then
  echo "[ERROR] Project file not found: $PROJ" >&2
  exit 1
fi

LAZBUILD_BIN="${LAZBUILD:-}"
if [[ -z "$LAZBUILD_BIN" ]]; then
  if command -v lazbuild >/dev/null 2>&1; then
    LAZBUILD_BIN="$(command -v lazbuild)"
  else
    for c in \
      "/usr/local/bin/lazbuild" \
      "/opt/lazarus/lazbuild" \
      "/Applications/Lazarus/lazbuild"; do
      [[ -x "$c" ]] && LAZBUILD_BIN="$c" && break
    done
  fi
fi

if [[ -z "$LAZBUILD_BIN" ]]; then
  echo "[ERROR] lazbuild not found in PATH or default locations. Export LAZBUILD or install Lazarus." >&2
  exit 1
fi

echo "[INFO] Using lazbuild: $LAZBUILD_BIN"
"$LAZBUILD_BIN" "$PROJ"

# Try common binary locations
EXE_POSIX="$BIN/tests_json"
EXE_MACAPP="$BIN/tests_json.app/Contents/MacOS/tests_json"
EXE_WIN="$BIN/tests_json.exe"

if [[ -f "$EXE_POSIX" ]]; then
  chmod +x "$EXE_POSIX" || true
  echo "[INFO] Running: $EXE_POSIX"
  "$EXE_POSIX"
  exit $?
fi

if [[ -x "$EXE_MACAPP" ]]; then
  echo "[INFO] Running: $EXE_MACAPP"
  "$EXE_MACAPP"
  exit $?
fi

if [[ -f "$EXE_WIN" ]]; then
  echo "[WARN] Windows binary found on non-Windows host: $EXE_WIN"
  echo "      If you need to run it here, use Wine or rebuild with a native target."
  exit 0
fi

echo "[INFO] Build finished, but test binary not found in $BIN. Please run from IDE or adjust paths."
exit 0

