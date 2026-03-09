#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"
shift || true

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROG="${ROOT}/fafafa.core.simd.intrinsics.experimental.test.lpr"
BIN_DIR="${ROOT}/bin"
LIB_DIR="${ROOT}/lib"
BIN="${BIN_DIR}/fafafa.core.simd.intrinsics.experimental.test"
LOG_DIR="${ROOT}/logs"
BUILD_LOG="${LOG_DIR}/build.txt"
TEST_LOG="${LOG_DIR}/test.txt"

mkdir -p "${BIN_DIR}" "${LIB_DIR}" "${LOG_DIR}"

FPC_BIN="${FPC:-fpc}"

build_project() {
  local LExperimental
  local -a LDefines

  LExperimental="${1:-0}"
  LDefines=()
  if [[ "${LExperimental}" != "0" ]]; then
    LDefines+=("-dFAFAFA_SIMD_EXPERIMENTAL_INTRINSICS")
    LDefines+=("-dFAFAFA_SIMD_EXPERIMENTAL_TEST_BUILD")
  fi

  echo "[BUILD] Target: ${PROG} (experimental=${LExperimental})"
  : >"${BUILD_LOG}"

  if "${FPC_BIN}" -B -Mobjfpc -Sc -Si -O1 -g -gl -dDEBUG \
      "${LDefines[@]}" \
      -Fu"${ROOT}" -Fu"${ROOT}/../../src" -Fi"${ROOT}/../../src" \
      -FE"${BIN_DIR}" -FU"${LIB_DIR}" \
      -o"${BIN}" "${PROG}" >"${BUILD_LOG}" 2>&1; then
    echo "[BUILD] OK"
  else
    local LRC=$?
    echo "[BUILD] FAILED rc=${LRC} (see ${BUILD_LOG})"
    tail -n 120 "${BUILD_LOG}" || true
    return "${LRC}"
  fi
}

check_build_log() {
  if grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${BUILD_LOG}" >/dev/null; then
    echo "[CHECK] Found warnings/hints from SIMD units in build log:"
    grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${BUILD_LOG}" || true
    return 1
  fi
  echo "[CHECK] OK (no SIMD-unit warnings/hints)"
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

  printf '%s\n' "${LArgs[@]}"
}

run_tests() {
  local -a LArgs
  LArgs=()

  while IFS= read -r LLine; do
    if [[ -n "${LLine}" ]]; then
      LArgs+=("${LLine}")
    fi
  done < <(normalize_test_args "$@")

  if [[ ! -x "${BIN}" ]]; then
    echo "[TEST] Missing binary: ${BIN}"
    return 2
  fi

  echo "[TEST] Running: ${BIN} ${LArgs[*]}"
  : >"${TEST_LOG}"

  if "${BIN}" "${LArgs[@]}" >"${TEST_LOG}" 2>&1; then
    if grep -nE '^Invalid option' "${TEST_LOG}" >/dev/null; then
      echo "[TEST] FAILED: unsupported test argument (see ${TEST_LOG})"
      tail -n 120 "${TEST_LOG}" || true
      return 2
    fi
    echo "[TEST] OK"
  else
    local LRC=$?
    echo "[TEST] FAILED rc=${LRC} (see ${TEST_LOG})"
    tail -n 120 "${TEST_LOG}" || true
    return "${LRC}"
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

run_default_test() {
  build_project 0
  check_build_log
  run_tests "$@"
  check_heap_leaks
}

run_experimental_test() {
  build_project 1
  check_build_log
  run_tests "$@"
  check_heap_leaks
}

case "${ACTION}" in
  clean)
    echo "[CLEAN] Removing bin/, lib/, logs/"
    rm -rf "${BIN_DIR}" "${LIB_DIR}" "${LOG_DIR}"
    ;;
  build)
    build_project 0
    ;;
  build-experimental)
    build_project 1
    ;;
  check)
    build_project 0
    check_build_log
    ;;
  test)
    run_default_test "$@"
    ;;
  test-experimental)
    run_experimental_test "$@"
    ;;
  test-all)
    run_default_test "$@"
    run_experimental_test "$@"
    ;;
  *)
    echo "Usage: $0 [clean|build|build-experimental|check|test|test-experimental|test-all] [test-args...]"
    exit 2
    ;;
esac
