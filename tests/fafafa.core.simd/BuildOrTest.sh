#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"
shift || true

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJ="${ROOT}/fafafa.core.simd.test.lpi"
BIN="${ROOT}/bin2/fafafa.core.simd.test"
LOG_DIR="${ROOT}/logs"
BUILD_LOG="${LOG_DIR}/build.txt"
TEST_LOG="${LOG_DIR}/test.txt"

mkdir -p "${ROOT}/bin2" "${ROOT}/lib2" "${LOG_DIR}"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

LZ_Q=()
if [[ "${FAFAFA_BUILD_QUIET:-1}" != "0" ]]; then
  LZ_Q+=("--quiet")
fi

MODE="${FAFAFA_BUILD_MODE:-Debug}"

build_project() {
  echo "[BUILD] Project: ${PROJ} (mode=${MODE})"
  : >"${BUILD_LOG}"
  if "${LAZBUILD_BIN}" "${LZ_Q[@]}" --build-mode="${MODE}" --build-all "${PROJ}" >"${BUILD_LOG}" 2>&1; then
    echo "[BUILD] OK"
  else
    local rc=$?
    echo "[BUILD] FAILED rc=${rc} (see ${BUILD_LOG})"
    return "${rc}"
  fi
}

check_build_log() {
  # Module acceptance criteria: no warnings/hints emitted from the SIMD module units under src/.
  if grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${BUILD_LOG}" >/dev/null; then
    echo "[CHECK] Found warnings/hints from SIMD units in build log:"
    grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${BUILD_LOG}" || true
    return 1
  fi
  echo "[CHECK] OK (no SIMD-unit warnings/hints)"
}

run_tests() {
  if [[ ! -x "${BIN}" ]]; then
    echo "[TEST] Missing binary: ${BIN} (did build succeed?)"
    return 2
  fi

  echo "[TEST] Running: ${BIN} $*"
  : >"${TEST_LOG}"

  if "${BIN}" "$@" >"${TEST_LOG}" 2>&1; then
    echo "[TEST] OK"
  else
    local rc=$?
    echo "[TEST] FAILED rc=${rc} (see ${TEST_LOG})"
    tail -n 80 "${TEST_LOG}" || true
    return "${rc}"
  fi
}

check_heap_leaks() {
  # heaptrc prints e.g. "0 unfreed memory blocks : 0" or "2 unfreed memory blocks : 38".
  if grep -nE '^[1-9][0-9]* unfreed memory blocks' "${TEST_LOG}" >/dev/null; then
    echo "[LEAK] FAILED: heaptrc reports unfreed blocks:"
    grep -nE '^[0-9]+ unfreed memory blocks' "${TEST_LOG}" || true
    return 1
  fi
  echo "[LEAK] OK"
}

case "${ACTION}" in
  clean)
    echo "[CLEAN] Removing bin2/, lib2/, logs/"
    rm -rf "${ROOT}/bin2" "${ROOT}/lib2" "${ROOT}/logs"
    ;;
  build)
    build_project
    ;;
  check)
    build_project
    check_build_log
    ;;
  debug)
    MODE="Debug"
    build_project
    run_tests "$@"
    check_heap_leaks
    ;;
  release)
    MODE="Release"
    build_project
    run_tests "$@"
    check_heap_leaks
    ;;
  test)
    build_project
    run_tests "$@"
    check_heap_leaks
    ;;
  *)
    echo "Usage: $0 [clean|build|check|test|debug|release] [test-args...]"
    exit 2
    ;;
esac
