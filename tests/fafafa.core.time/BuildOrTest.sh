#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$SCRIPT_DIR/fafafa.core.time.test.lpi"
TEST_BIN="$SCRIPT_DIR/bin/fafafa.core.time.test"

# Clean outputs (iron rule before build)
rm -rf "$SCRIPT_DIR/bin" "$SCRIPT_DIR/lib"

# Build with lazbuild (must be in PATH)
echo "Building project: $PROJECT ..."
lazbuild "$PROJECT"

echo
echo "Build successful."

action="${1:-}"

test_exe() {
  if [[ -x "$TEST_BIN" ]]; then
    echo "$TEST_BIN"
    return 0
  elif [[ -x "$TEST_BIN.exe" ]]; then
    echo "$TEST_BIN.exe"
    return 0
  else
    echo "Test executable not found. Looked for:" >&2
    echo "  $TEST_BIN" >&2
    echo "  $TEST_BIN.exe" >&2
    return 1
  fi
}

run_tests() {
  local exe
  exe="$(test_exe)"
  "$exe"
}

case "${action}" in
  test)
    echo "Running tests..."
    run_tests
    ;;
  check-no-timer-exception)
    OUT_FILE="$SCRIPT_DIR/bin/fafafa.core.time.test.out"
    TIMEOUT_SECS="${TIMEOUT_SECS:-60}"

    echo "Running tests (capturing output to: $OUT_FILE) ..."
    rm -f "$OUT_FILE"

    set +e
    exe="$(test_exe)" || exit $?

    if command -v timeout >/dev/null 2>&1; then
      timeout "${TIMEOUT_SECS}s" "$exe" >"$OUT_FILE" 2>&1
      rc=$?
    else
      "$exe" >"$OUT_FILE" 2>&1
      rc=$?
    fi
    set -e

    if [[ $rc -ne 0 ]]; then
      echo "[FAIL] tests failed or timed out (exit=$rc). Tail:" >&2
      tail -n 80 "$OUT_FILE" >&2 || true
      exit $rc
    fi

    if grep -nF "[Timer Exception]" "$OUT_FILE"; then
      echo "[FAIL] found unexpected [Timer Exception] lines (see above)." >&2
      exit 1
    fi

    echo "[OK] no [Timer Exception] lines found."
    ;;
  "")
    echo "To run tests, call this script with 'test' or 'check-no-timer-exception'."
    ;;
  *)
    echo "Usage: $0 [test|check-no-timer-exception]" >&2
    exit 2
    ;;
 esac
