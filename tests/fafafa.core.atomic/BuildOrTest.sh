#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_LPI="$SCRIPT_DIR/tests_atomic.lpi"
PROJECT_LPR="$SCRIPT_DIR/tests_atomic.lpr"
TEST_BIN="$SCRIPT_DIR/bin/tests_atomic"

# Clean outputs (iron rule before build)
rm -rf "$SCRIPT_DIR/bin" "$SCRIPT_DIR/lib"
mkdir -p "$SCRIPT_DIR/bin" "$SCRIPT_DIR/lib"

echo "Building atomic tests..."

if command -v lazbuild >/dev/null 2>&1; then
  echo "[BUILD] Using lazbuild: $PROJECT_LPI"
  lazbuild "$PROJECT_LPI"
else
  echo "[BUILD] lazbuild not found; falling back to plain fpc: $PROJECT_LPR"

  # Keep flags minimal and portable; rely on fafafa.core.settings.inc for feature toggles.
  #
  # Special case: Some CI/Docker images ship an amd64-hosted i386-targeting FPC (cross toolchain).
  # In that setup FPC will otherwise try to link with the host ld (x86_64) and fail (cannot find -lc).
  # Using the i686-linux-gnu binutils prefix makes FPC pick the right ld search paths.
  FPC_EXTRA_OPTS=()
  if [[ "$(uname -m)" == "x86_64" ]] && [[ "$(fpc -iTP)" == "i386" ]]; then
    # -FD: where to search for binutils (as/ld)
    # -XP: prefix for cross binutils
    FPC_EXTRA_OPTS+=("-FD/usr/bin" "-XPi686-linux-gnu-")
  fi

  fpc -MObjFPC -Scghi -Cg -O1 -g -gl -l -vewnhibq \
    "${FPC_EXTRA_OPTS[@]}" \
    -Fu"$SCRIPT_DIR/../../src" -Fi"$SCRIPT_DIR/../../src" \
    -FU"$SCRIPT_DIR/lib" \
    -FE"$SCRIPT_DIR/bin" \
    -o"$TEST_BIN" \
    "$PROJECT_LPR"
fi

echo
echo "Build successful."

if [[ "${1:-}" == "test" ]]; then
  echo "Running tests..."
  if [[ -x "$TEST_BIN" ]]; then
    "$TEST_BIN" --all --format=plain
  elif [[ -x "$TEST_BIN.exe" ]]; then
    "$TEST_BIN.exe" --all --format=plain
  else
    echo "Test executable not found. Looked for:"
    echo "  $TEST_BIN"
    echo "  $TEST_BIN.exe"
    exit 1
  fi
else
  echo "To run tests, call this script with the 'test' parameter."
fi

