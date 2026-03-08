#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"
shift || true

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${ROOT}}"
PROJ="${ROOT}/fafafa.core.simd.cpuinfo.x86.test.lpi"
FPC_BIN="${FPC_BIN:-fpc}"
TARGET_CPU="$(${FPC_BIN} -iTP 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
TARGET_OS="$(${FPC_BIN} -iTO 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
if [[ -z "${TARGET_CPU}" ]]; then
  TARGET_CPU="nativecpu"
fi
if [[ -z "${TARGET_OS}" ]]; then
  TARGET_OS="nativeos"
fi
BIN_DIR="${OUTPUT_ROOT}/bin"
LIB_DIR="${OUTPUT_ROOT}/lib/${TARGET_CPU}-${TARGET_OS}"
BIN="${BIN_DIR}/fafafa.core.simd.cpuinfo.x86.test"
LOG_DIR="${OUTPUT_ROOT}/logs"
BUILD_LOG="${LOG_DIR}/build.txt"
TEST_LOG="${LOG_DIR}/test.txt"

mkdir -p "${BIN_DIR}" "${LIB_DIR}" "${LOG_DIR}"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

LZ_Q=()
if [[ "${FAFAFA_BUILD_QUIET:-1}" != "0" ]]; then
  LZ_Q+=("--quiet")
fi

MODE="${FAFAFA_BUILD_MODE:-Debug}"

build_project() {
  echo "[BUILD] Project: ${PROJ} (mode=${MODE}, output_root=${OUTPUT_ROOT})"
  : >"${BUILD_LOG}"
  mkdir -p "${BIN_DIR}" "${LIB_DIR}" "${LOG_DIR}"
  if "${LAZBUILD_BIN}" "${LZ_Q[@]}" --build-mode="${MODE}" --build-all --opt="-FE${BIN_DIR}" --opt="-FU${LIB_DIR}" "${PROJ}" >"${BUILD_LOG}" 2>&1; then
    echo "[BUILD] OK"
  else
    local LRC=$?
    echo "[BUILD] FAILED rc=${LRC} (see ${BUILD_LOG})"
    return "${LRC}"
  fi
}

normalize_test_args() {
  local LArg
  local -a LArgs

  LArgs=()
  for LArg in "$@"; do
    if [[ "${LArg}" == "--list-suites" ]]; then
      LArgs+=("--list")
    else
      LArgs+=("${LArg}")
    fi
  done

  printf '%s\0' "${LArgs[@]}"
}

check_build_log() {
  if grep -nE '(^|.*/)src/.*(Warning:|Hint:)' "${BUILD_LOG}" >/dev/null; then
    echo "[CHECK] Found warnings/hints from src/ in build log:"
    grep -nE '(^|.*/)src/.*(Warning:|Hint:)' "${BUILD_LOG}" || true
    return 1
  fi
  echo "[CHECK] OK (no src/ warnings/hints)"
}

run_tests() {
  local -a LArgs
  local LArg

  if [[ ! -x "${BIN}" ]]; then
    echo "[TEST] Missing binary: ${BIN} (did build succeed?)"
    return 2
  fi

  LArgs=()
  if [[ $# -gt 0 ]]; then
    while IFS= read -r -d '' LArg; do
      LArgs+=("${LArg}")
    done < <(normalize_test_args "$@")
  fi

  echo "[TEST] Running: ${BIN} ${LArgs[*]}"
  : >"${TEST_LOG}"

  if "${BIN}" "${LArgs[@]}" >"${TEST_LOG}" 2>&1; then
    echo "[TEST] OK"
  else
    local LRC=$?
    echo "[TEST] FAILED rc=${LRC} (see ${TEST_LOG})"
    tail -n 120 "${TEST_LOG}" || true
    return "${LRC}"
  fi

  if grep -nE '^Invalid option' "${TEST_LOG}" >/dev/null; then
    echo "[TEST] FAILED: invalid option reported by test runner"
    grep -nE '^Invalid option' "${TEST_LOG}" || true
    return 2
  fi
}

check_heap_leaks() {
  if grep -nE '^[1-9][0-9]* unfreed memory blocks' "${TEST_LOG}" >/dev/null; then
    echo "[LEAK] FAILED: heaptrc reports unfreed blocks:"
    grep -nE '^[0-9]+ unfreed memory blocks' "${TEST_LOG}" || true
    return 1
  fi
  echo "[LEAK] OK"
}

case "${ACTION}" in
  clean)
    echo "[CLEAN] Removing ${BIN_DIR}, ${OUTPUT_ROOT}/lib, ${LOG_DIR}"
    rm -rf "${BIN_DIR}" "${OUTPUT_ROOT}/lib" "${LOG_DIR}"
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
