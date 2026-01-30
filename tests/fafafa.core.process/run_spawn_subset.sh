#!/usr/bin/env bash
set -euo pipefail

# Minimal spawn fast-path test runner (Unix)
# - Enables FAFAFA_PROCESS_USE_POSIX_SPAWN
# - Builds a tiny subset target and runs selected suites to validate spawn path

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_LPI="$SCRIPT_DIR/tests_process.lpi"
BIN_DIR="$SCRIPT_DIR/bin"
EXE_CORE="$BIN_DIR/tests"

LAZBUILD=""
for p in "/usr/bin/lazbuild" "/usr/local/bin/lazbuild" "$HOME/lazarus/lazbuild" "/opt/lazarus/lazbuild"; do
  if [ -x "$p" ]; then LAZBUILD="$p"; break; fi
done

if [ -z "$LAZBUILD" ]; then
  echo "ERROR: lazbuild not found. Please install Lazarus or update the search paths." >&2
  exit 1
fi

# Build with macro
export LAZBUILD_OPT="-dFAFAFA_PROCESS_USE_POSIX_SPAWN"

echo "[1/2] Building with spawn macro..."
"$LAZBUILD" --build-mode=Default --pcp="$HOME/.lazarus" --bm="Default" --ws=nogui \
  --add-options="$LAZBUILD_OPT" "$PROJECT_LPI"

if [ ! -x "$EXE_CORE" ]; then
  echo "ERROR: test executable not found at $EXE_CORE" >&2
  exit 1
fi

# Run a subset that exercises spawn path
echo "[2/2] Running spawn path subset..."
"$EXE_CORE" --format=plain --progress \
  --suite=TTestCase_Process \
  --suite=TTestCase_TimeoutAPI \
  --suite=TTestCase_CombinedOutput

RC=$?
if [ $RC -ne 0 ]; then
  echo "=== Spawn subset tests failed with code $RC ==="
  exit $RC
fi

echo "=== Spawn subset tests passed ==="

