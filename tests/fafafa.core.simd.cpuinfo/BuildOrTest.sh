#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"
shift || true

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROG="${ROOT}/fafafa.core.simd.cpuinfo.test.lpr"
FPC_BIN="${FPC:-fpc}"
MODE="${FAFAFA_BUILD_MODE:-Release}"
BIN_ROOT_DIR="${ROOT}/bin"
LIB_ROOT_DIR="${ROOT}/lib"
LOG_DIR="${ROOT}/logs"
LOCK_FILE="${ROOT}/.buildtest.lock"
LOCK_DIR="${ROOT}/.buildtest.lock.d"
LOCK_WAIT_SECONDS="${FAFAFA_BUILD_LOCK_WAIT_SECONDS:-300}"
LOCK_FD=0
LOCK_ACQUIRED=0

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

detect_fpc_target() {
  local LCpu
  local LOS

  LCpu="$("${FPC_BIN}" -iTP 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
  LOS="$("${FPC_BIN}" -iTO 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"

  if [[ -z "${LCpu}" ]]; then
    LCpu="unknowncpu"
  fi
  if [[ -z "${LOS}" ]]; then
    LOS="unknownos"
  fi

  TARGET_CPU="${LCpu}"
  TARGET_OS="${LOS}"
}

TARGET_CPU=""
TARGET_OS=""
detect_fpc_target

BIN_DIR="${BIN_ROOT_DIR}/${TARGET_CPU}-${TARGET_OS}"
LIB_DIR="${LIB_ROOT_DIR}/${TARGET_CPU}-${TARGET_OS}"
TARGET_LOG_DIR="${LOG_DIR}/${TARGET_CPU}-${TARGET_OS}"
BIN="${BIN_DIR}/fafafa.core.simd.cpuinfo.test"
BUILD_LOG="${TARGET_LOG_DIR}/build.txt"
TEST_LOG="${TARGET_LOG_DIR}/test.txt"
LEGACY_BUILD_LOG="${LOG_DIR}/build.txt"
LEGACY_TEST_LOG="${LOG_DIR}/test.txt"

mkdir -p "${BIN_DIR}" "${LIB_DIR}" "${LOG_DIR}" "${TARGET_LOG_DIR}"
trap release_project_lock EXIT
acquire_project_lock

sync_legacy_log() {
  local LSource
  local LTarget

  LSource="${1}"
  LTarget="${2}"
  if [[ -f "${LSource}" ]]; then
    cp "${LSource}" "${LTarget}" || true
  fi
}

create_failure_snapshot() {
  local LSource
  local LPrefix
  local LStamp
  local LSnapshot

  LSource="${1:-}"
  LPrefix="${2:-failure}"
  if [[ -z "${LSource}" ]] || [[ ! -f "${LSource}" ]]; then
    return 0
  fi

  LStamp="$(date +%Y%m%d-%H%M%S)"
  LSnapshot="${TARGET_LOG_DIR}/${LPrefix}.${LStamp}.txt"
  if cp "${LSource}" "${LSnapshot}" >/dev/null 2>&1; then
    echo "${LSnapshot}"
  fi
}

print_log_tail() {
  local LPath
  local LLines

  LPath="${1:-}"
  LLines="${2:-120}"
  if [[ -z "${LPath}" ]]; then
    return 0
  fi

  if [[ ! -f "${LPath}" ]]; then
    echo "[LOG] Missing log: ${LPath}"
    return 0
  fi

  if [[ ! -s "${LPath}" ]]; then
    echo "[LOG] Empty log: ${LPath}"
    return 0
  fi

  echo "[LOG] tail -n ${LLines} ${LPath}"
  tail -n "${LLines}" "${LPath}" || true
}

normalize_mode() {
  case "${MODE}" in
    Debug|debug)
      MODE="Debug"
      ;;
    Release|release)
      MODE="Release"
      ;;
    *)
      echo "[BUILD] Unsupported mode: ${MODE} (expect Debug|Release)"
      return 2
      ;;
  esac
}

build_project() {
  local -a LModeFlags

  normalize_mode || return $?
  echo "[BUILD] Target: ${PROG} (mode=${MODE}, target=${TARGET_CPU}-${TARGET_OS})"
  : >"${BUILD_LOG}"

  if [[ "${MODE}" == "Debug" ]]; then
    LModeFlags=(-O1 -g -gl -dDEBUG)
  else
    LModeFlags=(-O2 -gl)
  fi

  if "${FPC_BIN}" -B -Mobjfpc -Sc -Si "${LModeFlags[@]}" \
      -Fu"${ROOT}" -Fu"${ROOT}/../../src" -Fi"${ROOT}/../../src" \
      -FE"${BIN_DIR}" -FU"${LIB_DIR}" \
      -o"${BIN}" "${PROG}" >"${BUILD_LOG}" 2>&1; then
    sync_legacy_log "${BUILD_LOG}" "${LEGACY_BUILD_LOG}"
    echo "[BUILD] OK"
  else
    local rc=$?
    local LSnapshot
    LSnapshot="$(create_failure_snapshot "${BUILD_LOG}" "build.failed" || true)"
    sync_legacy_log "${BUILD_LOG}" "${LEGACY_BUILD_LOG}"
    echo "[BUILD] FAILED rc=${rc} (see ${BUILD_LOG})"
    if [[ -n "${LSnapshot}" ]]; then
      echo "[BUILD] Snapshot: ${LSnapshot}"
    fi
    print_log_tail "${BUILD_LOG}" 120
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
  echo "[CHECK] OK (no SIMD-unit warnings/hints)"
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
    sync_legacy_log "${TEST_LOG}" "${LEGACY_TEST_LOG}"
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
    local LSnapshot
    LSnapshot="$(create_failure_snapshot "${TEST_LOG}" "test.failed" || true)"
    sync_legacy_log "${TEST_LOG}" "${LEGACY_TEST_LOG}"
    echo "[TEST] FAILED rc=${rc} (see ${TEST_LOG})"
    if [[ -n "${LSnapshot}" ]]; then
      echo "[TEST] Snapshot: ${LSnapshot}"
    fi
    print_log_tail "${TEST_LOG}" 120
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
    'findstr /r /c:"src\\fafafa\.core\.simd\..*Warning:" /c:"src\\fafafa\.core\.simd\..*Hint:" "%BUILD_LOG%" >nul 2>nul'
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

check_log_layout() {
  local LPath
  local LMissing
  local -a LExpected

  LExpected=(
    "${BUILD_LOG}"
    "${TEST_LOG}"
    "${LEGACY_BUILD_LOG}"
    "${LEGACY_TEST_LOG}"
  )
  LMissing=0

  for LPath in "${LExpected[@]}"; do
    if [[ ! -f "${LPath}" ]]; then
      echo "[CHECK] Missing expected log: ${LPath}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (target + legacy logs present)"
}

run_log_layout_check() {
  build_project || return $?
  check_build_log || return $?
  run_tests --list-suites || return $?
  check_heap_leaks || return $?
  check_log_layout || return $?
}

case "${ACTION}" in
  clean)
    echo "[CLEAN] Removing bin/, lib/, logs/"
    rm -rf "${BIN_ROOT_DIR}" "${LIB_ROOT_DIR}" "${LOG_DIR}"
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
  log-layout-check)
    run_log_layout_check
    ;;
  *)
    echo "Usage: $0 [clean|build|check|test|log-layout-check|debug|release] [test-args...]"
    exit 2
    ;;
esac
