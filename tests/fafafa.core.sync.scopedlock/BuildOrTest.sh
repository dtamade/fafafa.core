#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PROJ="fafafa.core.sync.scopedlock.test.lpi"
BIN="bin/fafafa.core.sync.scopedlock.test"
LOG_DIR="$ROOT/logs"
BUILD_LOG="$LOG_DIR/build.txt"
TEST_LOG="$LOG_DIR/test.txt"

mkdir -p "$ROOT/bin" "$ROOT/lib" "$LOG_DIR"

LZ_Q=()
if [[ "${FAFAFA_BUILD_QUIET:-1}" != "0" ]]; then
  LZ_Q+=("--quiet")
fi

build_project() {
  echo "[BUILD] Project: $PROJ"
  : >"$BUILD_LOG"
  if lazbuild --lazarusdir="/opt/fpcupdeluxe/lazarus" "${LZ_Q[@]}" --build-all "$PROJ" >"$BUILD_LOG" 2>&1; then
    echo "[BUILD] OK"
  else
    local rc=$?
    echo "[BUILD] FAILED rc=$rc (see $BUILD_LOG)"
    return $rc
  fi
}

check_build_log() {
  # Module acceptance: no warnings/hints from src/
  if grep -nE '(^|.*/)src/.*(Warning:|Hint:)' "$BUILD_LOG" >/dev/null; then
    echo "[CHECK] Found warnings/hints from src/ in build log:"
    grep -nE '(^|.*/)src/.*(Warning:|Hint:)' "$BUILD_LOG" || true
    return 1
  fi
  echo "[CHECK] OK (no src/ warnings/hints)"
}

run_tests() {
  echo "[TEST] Running: $BIN"
  : >"$TEST_LOG"

  if [[ ! -x "$BIN" ]]; then
    echo "[TEST] Missing binary: $BIN (did build succeed?)"
    return 2
  fi

  if "$BIN" --all --format=plain >"$TEST_LOG" 2>&1; then
    echo "[TEST] OK"
  else
    local rc=$?
    echo "[TEST] FAILED rc=$rc (see $TEST_LOG)"
    return $rc
  fi
}

check_heap_leaks() {
  if grep -nE '^[1-9][0-9]* unfreed memory blocks' "$TEST_LOG" >/dev/null; then
    echo "[LEAK] FAILED: heaptrc reports unfreed blocks:"
    grep -nE '^[0-9]+ unfreed memory blocks' "$TEST_LOG" || true
    return 1
  fi
  echo "[LEAK] OK"
}

case "$ACTION" in
  build)
    build_project
    ;;
  check)
    build_project
    check_build_log
    ;;
  test)
    build_project
    check_build_log
    run_tests
    check_heap_leaks
    ;;
  *)
    echo "Usage: $0 [build|check|test]"
    exit 2
    ;;
esac
