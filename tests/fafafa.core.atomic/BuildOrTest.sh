#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$ROOT/../.." && pwd)"
cd "$ROOT"

PROJ="$ROOT/tests_atomic.lpi"
BIN="$ROOT/bin/tests_atomic"
LOG_DIR="$ROOT/logs"
BUILD_LOG="$LOG_DIR/build.txt"
TEST_LOG="$LOG_DIR/test.txt"
TOOLS_LAZBUILD="$REPO_ROOT/tools/lazbuild.sh"
MODULE_WARNING_PATTERN='(^|.*/)src/fafafa\.core\.atomic[^[:space:]]*.*(Warning:|Hint:)'

mkdir -p "$ROOT/bin" "$ROOT/lib" "$LOG_DIR"

LZ_Q=()
if [[ "${FAFAFA_BUILD_QUIET:-1}" != "0" ]]; then
  LZ_Q+=("--quiet")
fi

LAZBUILD_BIN="${LAZBUILD:-}"
if [[ -z "${LAZBUILD_BIN}" ]]; then
  if [[ -x "${TOOLS_LAZBUILD}" ]]; then
    LAZBUILD_BIN="${TOOLS_LAZBUILD}"
  else
    LAZBUILD_BIN="lazbuild"
  fi
fi

build_project() {
  echo "[BUILD] Project: $PROJ"
  : >"$BUILD_LOG"
  if "${LAZBUILD_BIN}" "${LZ_Q[@]}" --build-all "$PROJ" >"$BUILD_LOG" 2>&1; then
    echo "[BUILD] OK"
  else
    local LExitCode=$?
    echo "[BUILD] FAILED rc=$LExitCode (see $BUILD_LOG)"
    return "$LExitCode"
  fi
}

check_build_log() {
  if grep -nE "$MODULE_WARNING_PATTERN" "$BUILD_LOG" >/dev/null; then
    echo "[CHECK] Found warnings/hints from current module scope in build log:"
    grep -nE "$MODULE_WARNING_PATTERN" "$BUILD_LOG" || true
    return 1
  fi
  echo "[CHECK] OK (no current-module src/ warnings/hints)"
}

run_tests() {
  : >"$TEST_LOG"
  if [[ -x "$BIN" ]]; then
    "$BIN" --all --format=plain >"$TEST_LOG" 2>&1
  elif [[ -x "$BIN.exe" ]]; then
    "$BIN.exe" --all --format=plain >"$TEST_LOG" 2>&1
  else
    echo "[ERROR] Test executable not found: $BIN[.exe]"
    return 1
  fi
  echo "[TEST] OK"
}

check_heap_leaks() {
  if grep -nE '^[1-9][0-9]* unfreed memory blocks' "$TEST_LOG" >/dev/null; then
    echo "[LEAK] heaptrc reported leaks:"
    grep -nE '^[1-9][0-9]* unfreed memory blocks' "$TEST_LOG" || true
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
