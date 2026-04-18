#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"
shift || true

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${ROOT}}"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
PROJ="${ROOT}/fafafa.core.simd.cpuinfo.test.lpr"
FPC_BIN="${FPC_BIN:-fpc}"
CPU="$(${FPC_BIN} -iTP 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
OS="$(${FPC_BIN} -iTO 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
TRIPLET="${CPU}-${OS}"
BIN_DIR="${OUTPUT_ROOT}/bin"
LIB_DIR="${OUTPUT_ROOT}/lib/${TRIPLET}"
BIN="${BIN_DIR}/fafafa.core.simd.cpuinfo.test"
LOG_DIR="${OUTPUT_ROOT}/logs"
TARGET_LOG_DIR="${LOG_DIR}/${TRIPLET}"
BUILD_LOG="${LOG_DIR}/build.txt"
TEST_LOG="${LOG_DIR}/test.txt"
TARGET_TEST_LOG="${TARGET_LOG_DIR}/test.txt"

mkdir -p "${BIN_DIR}" "${LIB_DIR}" "${LOG_DIR}" "${TARGET_LOG_DIR}"

is_msys_shell() {
  case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

to_windows_path() {
  local aPath
  local LDrive
  local LRest

  aPath="${1:-}"
  if [[ -z "${aPath}" ]]; then
    echo ""
    return 0
  fi

  if [[ "${aPath}" =~ ^/([a-zA-Z])/(.*)$ ]]; then
    LDrive="${BASH_REMATCH[1]}"
    LRest="${BASH_REMATCH[2]//\//\\}"
    LDrive="$(printf '%s' "${LDrive}" | tr '[:lower:]' '[:upper:]')"
    echo "${LDrive}:\\${LRest}"
    return 0
  fi

  if [[ "${aPath}" =~ ^[a-zA-Z]:[\\/].* ]]; then
    echo "${aPath//\//\\}"
    return 0
  fi

  echo "${aPath}"
}

fpc_path_arg() {
  if is_msys_shell; then
    to_windows_path "${1:-}"
  else
    echo "${1:-}"
  fi
}

if is_msys_shell; then
  BIN="${BIN}.exe"
fi

UNITS_ROOT=""
PPC_BIN="$(command -v ppcx64 || command -v ppc$(getconf LONG_BIT 2>/dev/null || echo 64) || true)"
if [[ -n "${PPC_BIN}" ]]; then
  PPC_REAL="$(readlink -f "${PPC_BIN}" 2>/dev/null || echo "${PPC_BIN}")"
  FPC_ROOT_CANDIDATE="$(cd "$(dirname "${PPC_REAL}")/../.." && pwd)"
  if [[ -d "${FPC_ROOT_CANDIDATE}/units/${TRIPLET}" ]]; then
    UNITS_ROOT="${FPC_ROOT_CANDIDATE}/units/${TRIPLET}"
  fi
fi

if [[ -z "${UNITS_ROOT}" ]]; then
  FPC_VER="$(${FPC_BIN} -iV 2>/dev/null || true)"
  for c in \
    "/usr/lib/fpc/${FPC_VER}/units/${TRIPLET}" \
    "/usr/lib/x86_64-linux-gnu/fpc/${FPC_VER}/units/${TRIPLET}" \
    "/usr/lib/fpc/units/${TRIPLET}" \
    "$HOME/freePascal/fpc/units/${TRIPLET}" \
    "$HOME/fpc/units/${TRIPLET}"; do
    if [[ -d "${c}" ]]; then
      UNITS_ROOT="${c}"
      break
    fi
  done
fi

FU=()
FI=()
add_fu() {
  local LDir
  LDir="$1"
  [[ -d "${LDir}" ]] && FU+=("-Fu$(fpc_path_arg "${LDir}")")
}

add_fu "${REPO_ROOT}/src"
add_fu "${ROOT}"
FI+=("-Fi$(fpc_path_arg "${REPO_ROOT}/src")" "-Fi$(fpc_path_arg "${ROOT}")")
if [[ -n "${UNITS_ROOT}" ]]; then
  add_fu "${UNITS_ROOT}/rtl"
  add_fu "${UNITS_ROOT}/rtl-objpas"
  add_fu "${UNITS_ROOT}/fcl-base"
  add_fu "${UNITS_ROOT}/fcl-fpcunit"
fi

build_project() {
  local LProjArg
  local LBinDirArg
  local LLibDirArg
  local LBinArg

  echo "[BUILD] Project: ${PROJ} (mode=FPC, output_root=${OUTPUT_ROOT})"
  : >"${BUILD_LOG}"
  LProjArg="$(fpc_path_arg "${PROJ}")"
  LBinDirArg="$(fpc_path_arg "${BIN_DIR}")"
  LLibDirArg="$(fpc_path_arg "${LIB_DIR}")"
  LBinArg="$(fpc_path_arg "${BIN}")"
  if "${FPC_BIN}" \
    "${FU[@]}" \
    "${FI[@]}" \
    -FE"${LBinDirArg}" \
    -FU"${LLibDirArg}" \
    -o"${LBinArg}" \
    "${LProjArg}" >"${BUILD_LOG}" 2>&1; then
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

  if [[ ! -f "${BIN}" ]]; then
    echo "[TEST] Missing binary: ${BIN} (did build succeed?)"
    return 2
  fi
  chmod +x "${BIN}" 2>/dev/null || true

  LArgs=()
  if [[ $# -gt 0 ]]; then
    while IFS= read -r -d '' LArg; do
      LArgs+=("${LArg}")
    done < <(normalize_test_args "$@")
  fi

  echo "[TEST] Running: ${BIN} ${LArgs[*]}"
  : >"${TEST_LOG}"
  if "${BIN}" "${LArgs[@]}" >"${TEST_LOG}" 2>&1; then
    cp "${TEST_LOG}" "${TARGET_TEST_LOG}" || true
    echo "[TEST] OK"
  else
    local LRC=$?
    cp "${TEST_LOG}" "${TARGET_TEST_LOG}" || true
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
  debug|release|test)
    build_project
    run_tests "$@"
    check_heap_leaks
    ;;
  *)
    echo "Usage: $0 [clean|build|check|test|debug|release] [test-args...]"
    exit 2
    ;;
esac
