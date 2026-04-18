#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$ROOT/../.." && pwd)"
cd "$ROOT"

PROJ="$ROOT/fafafa.core.mem.allocator.foundation.test.lpi"
BIN="$ROOT/bin/fafafa.core.mem.allocator.foundation.test_debug"
BIN_FALLBACK="$ROOT/bin/fafafa.core.mem.allocator.foundation.test"
LOG_DIR="$ROOT/logs"
BUILD_LOG="$LOG_DIR/build.txt"
TEST_LOG="$LOG_DIR/test.txt"
TOOLS_LAZBUILD="$REPO_ROOT/tools/lazbuild.sh"
MODULE_WARNING_PATTERN='(^|.*/)src/fafafa\.core\.mem\.allocator(\.foundation|\.base|\.rtlAllocator|\.callbackAllocator)?[^[:space:]]*.*(Warning:|Hint:)'

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
  if "${LAZBUILD_BIN}" "${LZ_Q[@]}" --bm=Debug --build-all "$PROJ" >"$BUILD_LOG" 2>&1; then
    echo "[BUILD] OK"
  else
    local LExitCode=$?
    echo "[BUILD] FAILED rc=$LExitCode (see $BUILD_LOG)"
    return $LExitCode
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
  local LRunBin
  : >"$TEST_LOG"

  if [[ -x "$BIN" ]]; then
    LRunBin="$BIN"
  elif [[ -x "${BIN}.exe" ]]; then
    LRunBin="${BIN}.exe"
  elif [[ -x "$BIN_FALLBACK" ]]; then
    LRunBin="$BIN_FALLBACK"
  elif [[ -x "${BIN_FALLBACK}.exe" ]]; then
    LRunBin="${BIN_FALLBACK}.exe"
  else
    echo "[TEST] Missing binary: ${BIN}[.exe] or ${BIN_FALLBACK}[.exe] (did build succeed?)"
    return 2
  fi

  echo "[TEST] Running: $LRunBin"
  if "$LRunBin" --all --format=plain --progress >"$TEST_LOG" 2>&1; then
    echo "[TEST] OK"
  else
    local LExitCode=$?
    echo "[TEST] FAILED rc=$LExitCode (see $TEST_LOG)"
    return $LExitCode
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
