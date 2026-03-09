#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"
shift || true

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJ="${ROOT}/fafafa.core.simd.cpuinfo.x86.test.lpi"
BIN="${ROOT}/bin/fafafa.core.simd.cpuinfo.x86.test"
LOG_DIR="${ROOT}/logs"
BUILD_LOG="${LOG_DIR}/build.txt"
TEST_LOG="${LOG_DIR}/test.txt"
LOCK_FILE="${ROOT}/.buildtest.lock"
LOCK_DIR="${ROOT}/.buildtest.lock.d"
LOCK_WAIT_SECONDS="${FAFAFA_BUILD_LOCK_WAIT_SECONDS:-300}"
LOCK_FD=0
LOCK_ACQUIRED=0

mkdir -p "${ROOT}/bin" "${ROOT}/lib" "${LOG_DIR}"

release_project_lock() {
  if [[ "${LOCK_FD}" -ne 0 ]]; then
    flock -u "${LOCK_FD}" 2>/dev/null || true
    eval "exec ${LOCK_FD}>&-"
    LOCK_FD=0
  fi
  if [[ "${LOCK_ACQUIRED}" -eq 1 ]]; then
    rmdir "${LOCK_DIR}" 2>/dev/null || true
    LOCK_ACQUIRED=0
  fi
}

acquire_project_lock() {
  local LDeadline

  if ! [[ "${LOCK_WAIT_SECONDS}" =~ ^[1-9][0-9]*$ ]]; then
    echo "[LOCK] Invalid FAFAFA_BUILD_LOCK_WAIT_SECONDS=${LOCK_WAIT_SECONDS} (expect positive integer)"
    exit 2
  fi

  if command -v flock >/dev/null 2>&1; then
    LOCK_FD=9
    eval "exec ${LOCK_FD}>\"${LOCK_FILE}\""
    if flock -w "${LOCK_WAIT_SECONDS}" "${LOCK_FD}"; then
      return 0
    fi
    echo "[LOCK] Timeout waiting for lock: ${LOCK_FILE} (${LOCK_WAIT_SECONDS}s)"
    exit 3
  fi

  LDeadline=$(( $(date +%s) + LOCK_WAIT_SECONDS ))
  while true; do
    if mkdir "${LOCK_DIR}" 2>/dev/null; then
      LOCK_ACQUIRED=1
      return 0
    fi
    if (( $(date +%s) >= LDeadline )); then
      echo "[LOCK] Timeout waiting for lock dir: ${LOCK_DIR} (${LOCK_WAIT_SECONDS}s)"
      exit 3
    fi
    sleep 1
  done
}

trap release_project_lock EXIT
acquire_project_lock

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

LZ_Q=()
if [[ "${FAFAFA_BUILD_QUIET:-1}" != "0" ]]; then
  LZ_Q+=("--quiet")
fi

MODE="${FAFAFA_BUILD_MODE:-Release}"

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
  local LBuildMode
  LLazarusDir="$(detect_lazarusdir)"
  LBuildMode="${MODE}"

  # This Lazarus project currently exposes Default/Debug build modes.
  # Map release requests to Default to keep non-debug execution.
  if [[ "${LBuildMode}" == "Release" ]]; then
    LBuildMode="Default"
  fi

  echo "[BUILD] Target: ${PROJ} (mode=${MODE}, lazarus-mode=${LBuildMode})"
  : >"${BUILD_LOG}"
  if [[ -n "${LLazarusDir}" ]]; then
    if "${LAZBUILD_BIN}" "${LZ_Q[@]}" --lazarusdir="${LLazarusDir}" --build-mode="${LBuildMode}" --build-all "${PROJ}" >"${BUILD_LOG}" 2>&1; then
      echo "[BUILD] OK"
      return 0
    else
      local rc=$?
      echo "[BUILD] FAILED rc=${rc} (see ${BUILD_LOG})"
      tail -n 120 "${BUILD_LOG}" || true
      return "${rc}"
    fi
  fi

  if "${LAZBUILD_BIN}" "${LZ_Q[@]}" --build-mode="${LBuildMode}" --build-all "${PROJ}" >"${BUILD_LOG}" 2>&1; then
    echo "[BUILD] OK"
  else
    local rc=$?
    echo "[BUILD] FAILED rc=${rc} (see ${BUILD_LOG})"
    tail -n 120 "${BUILD_LOG}" || true
    return "${rc}"
  fi
}

check_build_log() {
  # Module acceptance criteria: no warnings/hints emitted from SIMD module units under src/.
  if grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${BUILD_LOG}" >/dev/null; then
    echo "[CHECK] Found warnings/hints from SIMD units in build log:"
    grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${BUILD_LOG}" || true
    return 1
  fi
  # Task-1 hardening: cpuinfo.x86 test sources must also stay warning/hint clean.
  if grep -nE '(fafafa\.core\.simd\.cpuinfo\.x86\.testcase\.pas|fafafa\.core\.simd\.cpuinfo\.x86\.test\.lpr).*(Warning:|Hint:)' "${BUILD_LOG}" >/dev/null; then
    echo "[CHECK] Found warnings/hints from cpuinfo.x86 test sources in build log:"
    grep -nE '(fafafa\.core\.simd\.cpuinfo\.x86\.testcase\.pas|fafafa\.core\.simd\.cpuinfo\.x86\.test\.lpr).*(Warning:|Hint:)' "${BUILD_LOG}" || true
    return 1
  fi
  echo "[CHECK] OK (no SIMD-unit and cpuinfo.x86-test warnings/hints)"
}

run_tests() {
  local LArg
  local -a LArgs=()

  if [[ ! -x "${BIN}" ]]; then
    echo "[TEST] Missing binary: ${BIN}"
    return 2
  fi

  for LArg in "$@"; do
    if [[ "${LArg}" == "--list-suites" ]]; then
      LArgs+=("--list")
    else
      LArgs+=("${LArg}")
    fi
  done

  echo "[TEST] Running: ${BIN} ${LArgs[*]}"
  : >"${TEST_LOG}"

  if "${BIN}" "${LArgs[@]}" >"${TEST_LOG}" 2>&1; then
    if grep -nE '^Invalid option' "${TEST_LOG}" >/dev/null; then
      echo "[TEST] FAILED: unsupported test argument (see ${TEST_LOG})"
      tail -n 120 "${TEST_LOG}" || true
      return 2
    fi
    if grep -nE '^[[:space:]]*Number of failures:[[:space:]]*[1-9][0-9]*|^[[:space:]]*Number of errors:[[:space:]]*[1-9][0-9]*|Time:[^[:cntrl:]]*[[:space:]]E:[1-9][0-9]*|Time:[^[:cntrl:]]*[[:space:]]F:[1-9][0-9]*' "${TEST_LOG}" >/dev/null; then
      echo "[TEST] FAILED: test runner reports failures/errors (see ${TEST_LOG})"
      grep -nE '^[[:space:]]*Number of failures:[[:space:]]*[0-9]+|^[[:space:]]*Number of errors:[[:space:]]*[0-9]+|Time:[^[:cntrl:]]*[[:space:]]E:[0-9]+|Time:[^[:cntrl:]]*[[:space:]]F:[0-9]+' "${TEST_LOG}" || true
      return 1
    fi
    echo "[TEST] OK"
  else
    local rc=$?
    echo "[TEST] FAILED rc=${rc} (see ${TEST_LOG})"
    tail -n 120 "${TEST_LOG}" || true
    return "${rc}"
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

check_windows_runner_parity() {
  local LBat
  local LMissing
  local LPattern
  local -a LRequired

  LBat="${ROOT}/buildOrTest.bat"
  LMissing=0

  if [[ ! -f "${LBat}" ]]; then
    echo "[CHECK] Missing Windows runner: ${LBat}"
    return 1
  fi

  LRequired=(
    'if /I "%ACTION%"=="check" goto :check'
    'if /I "%ACTION%"=="test" goto :test'
    'if /I "%~1"=="--list-suites" ('
    'set "NORMALIZED_TEST_ARGS=!NORMALIZED_TEST_ARGS! --list"'
    'findstr /b /c:"Invalid option" "%TEST_LOG%" >nul 2>nul'
    'findstr /r /c:"Number of failures:[ ]*[1-9][0-9]*" /c:"Number of errors:[ ]*[1-9][0-9]*" /c:"Time:.* E:[1-9][0-9]*" /c:"Time:.* F:[1-9][0-9]*" "%TEST_LOG%" >nul 2>nul'
    'findstr /r /c:"^[1-9][0-9]* unfreed memory blocks" "%TEST_LOG%" >nul 2>nul'
  )

  for LPattern in "${LRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows runner missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (windows runner parity signatures present)"
}

case "${ACTION}" in
  clean)
    echo "[CLEAN] Removing bin/, lib/, logs/"
    rm -rf "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/logs"
    ;;
  build)
    build_project
    ;;
  check)
    build_project
    check_build_log
    check_windows_runner_parity
    ;;
  debug)
    MODE="Debug"
    build_project
    check_build_log
    run_tests "$@"
    check_heap_leaks
    ;;
  release)
    MODE="Release"
    build_project
    check_build_log
    run_tests "$@"
    check_heap_leaks
    ;;
  test)
    build_project
    check_build_log
    run_tests "$@"
    check_heap_leaks
    ;;
  *)
    echo "Usage: $0 [clean|build|check|test|debug|release] [test-args...]"
    exit 2
    ;;
esac
