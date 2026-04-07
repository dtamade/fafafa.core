#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$ROOT/../.." && pwd)"
cd "$ROOT"

PROJ="$ROOT/tests_mem_allocator_only.lpi"
LOG_DIR="$ROOT/logs"
BUILD_LOG="$LOG_DIR/build.txt"
TEST_LOG="$LOG_DIR/test.txt"
TOOLS_LAZBUILD="$REPO_ROOT/tools/lazbuild.sh"
MODULE_WARNING_PATTERN='(^|.*/)src/fafafa\.core\.mem\.allocator[^[:space:]]*.*(Warning:|Hint:)'

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

resolve_mode() {
  case "$ACTION" in
    build|check|test)
      echo "Debug|$ROOT/bin/tests_mem_allocator_only_debug|$ROOT/bin/tests_mem_allocator_only"
      ;;
    build-no-contracts|check-no-contracts|test-no-contracts)
      echo "NoContracts|$ROOT/bin/tests_mem_allocator_only_nocontracts|$ROOT/bin/tests_mem_allocator_only"
      ;;
    *)
      return 1
      ;;
  esac
}

build_project() {
  local LMode="$1"
  echo "[BUILD] Project: $PROJ (mode=$LMode)"
  : >"$BUILD_LOG"
  if "${LAZBUILD_BIN}" "${LZ_Q[@]}" --bm="$LMode" --build-all "$PROJ" >"$BUILD_LOG" 2>&1; then
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
  local LBin="$1"
  local LBinFallback="$2"
  local LRunBin
  : >"$TEST_LOG"

  if [[ -x "$LBin" ]]; then
    LRunBin="$LBin"
  elif [[ -x "${LBin}.exe" ]]; then
    LRunBin="${LBin}.exe"
  elif [[ -x "$LBinFallback" ]]; then
    LRunBin="$LBinFallback"
  elif [[ -x "${LBinFallback}.exe" ]]; then
    LRunBin="${LBinFallback}.exe"
  else
    echo "[TEST] Missing binary: ${LBin}[.exe] or ${LBinFallback}[.exe] (did build succeed?)"
    return 2
  fi

  echo "[TEST] Running: $LRunBin"
  if "$LRunBin" --all --format=plain --progress >"$TEST_LOG" 2>&1; then
    echo "[TEST] OK"
  else
    local LExitCode=$?
    echo "[TEST] FAILED rc=$LExitCode (see $TEST_LOG)"
    return "$LExitCode"
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
  build|check|test|build-no-contracts|check-no-contracts|test-no-contracts)
    IFS='|' read -r BUILD_MODE TEST_BIN TEST_BIN_FALLBACK <<<"$(resolve_mode)"
    build_project "$BUILD_MODE"
    check_build_log
    if [[ "$ACTION" == test* ]]; then
      run_tests "$TEST_BIN" "$TEST_BIN_FALLBACK"
      check_heap_leaks
    fi
    ;;
  *)
    echo "Usage: $0 [build|check|test|build-no-contracts|check-no-contracts|test-no-contracts]"
    exit 2
    ;;
esac
