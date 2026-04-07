#!/usr/bin/env bash
set -euo pipefail

# Spawn with PGID/groups subset runner (Unix)
# Requires: lazbuild

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_LPI="$SCRIPT_DIR/tests_process.lpi"
BIN_DIR="$SCRIPT_DIR/bin"
EXE_CORE="$BIN_DIR/tests"

LAZBUILD=""
for p in "/usr/bin/lazbuild" "/usr/local/bin/lazbuild" "$HOME/lazarus/lazbuild" "/opt/lazarus/lazbuild"; do
  if [ -x "$p" ]; then LAZBUILD="$p"; break; fi
done

if [ -z "$LAZBUILD" ]; then
  echo "ERROR: lazbuild not found." >&2
  exit 1
fi

OPTS="-dFAFAFA_PROCESS_USE_POSIX_SPAWN -dFAFAFA_POSIX_SPAWN_ATTR -dFAFAFA_POSIX_SPAWN_SETPGROUP -dFAFAFA_POSIX_SPAWN_FLAGS"

echo "[1/2] Building with spawn+groups macros..."
"$LAZBUILD" --build-mode=Default --pcp="$HOME/.lazarus" --ws=nogui \
  --add-options="$OPTS" "$PROJECT_LPI"

if [ ! -x "$EXE_CORE" ]; then echo "ERROR: tests not found" >&2; exit 1; fi

echo "[2/2] Running group-related suites..."
"$EXE_CORE" --format=plain --progress \
  --suite=TTestPipelineEnhanced

RC=$?
if [ $RC -ne 0 ]; then echo "=== Spawn groups subset failed: $RC ==="; exit $RC; fi

echo "=== Spawn groups subset passed ==="

