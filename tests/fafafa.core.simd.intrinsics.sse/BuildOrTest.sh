#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PROJ="fafafa.core.simd.intrinsics.sse.test.lpi"
BIN="bin/fafafa.core.simd.intrinsics.sse.test"
LOG_DIR="$ROOT/logs"
BUILD_LOG="$LOG_DIR/build.txt"
TEST_LOG="$LOG_DIR/test.txt"

mkdir -p "$ROOT/bin" "$ROOT/lib" "$LOG_DIR"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

LZ_Q=()
if [[ "${FAFAFA_BUILD_QUIET:-1}" != "0" ]]; then
  LZ_Q+=("--quiet")
fi

detect_lazarusdir() {
  # Prefer explicit override.
  if [[ -n "${FAFAFA_LAZARUSDIR:-}" ]]; then
    echo "${FAFAFA_LAZARUSDIR}"
    return 0
  fi

  # Common fpcupdeluxe layout.
  if [[ -d "/opt/fpcupdeluxe/lazarus/lcl" ]]; then
    echo "/opt/fpcupdeluxe/lazarus"
    return 0
  fi

  # Best-effort: infer from lazbuild location if it sits in the Lazarus source root.
  local LLazbuildPath
  local LMaybeRoot
  LLazbuildPath="$(command -v "${LAZBUILD_BIN}" 2>/dev/null || true)"
  if [[ -n "${LLazbuildPath}" ]]; then
    LMaybeRoot="$(cd "$(dirname "${LLazbuildPath}")" && pwd)"
    if [[ -d "${LMaybeRoot}/lcl" ]]; then
      echo "${LMaybeRoot}"
      return 0
    fi
  fi

  echo ""
  return 0
}

build_project() {
  local LLazarusDir
  LLazarusDir="$(detect_lazarusdir)"

  echo "[BUILD] Project: $PROJ"
  : >"$BUILD_LOG"
  if [[ -n "${LLazarusDir}" ]]; then
    if "${LAZBUILD_BIN}" --lazarusdir="${LLazarusDir}" "${LZ_Q[@]}" --build-all "$PROJ" >"$BUILD_LOG" 2>&1; then
      echo "[BUILD] OK"
      return 0
    else
      local rc=$?
      echo "[BUILD] FAILED rc=$rc (see $BUILD_LOG)"
      return $rc
    fi
  fi

  if "${LAZBUILD_BIN}" "${LZ_Q[@]}" --build-all "$PROJ" >"$BUILD_LOG" 2>&1; then
    echo "[BUILD] OK"
  else
    local rc=$?
    echo "[BUILD] FAILED rc=$rc (see $BUILD_LOG)"
    return $rc
  fi
}

check_build_log() {
  # SIMD module acceptance: no warnings/hints from src/fafafa.core.simd.*
  if grep -nE 'src/fafafa\.core\.simd.*(Warning:|Hint:)' "$BUILD_LOG" >/dev/null; then
    echo "[CHECK] Found warnings/hints from SIMD units in build log:"
    grep -nE 'src/fafafa\.core\.simd.*(Warning:|Hint:)' "$BUILD_LOG" || true
    return 1
  fi
  echo "[CHECK] OK (no SIMD unit warnings/hints)"
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
