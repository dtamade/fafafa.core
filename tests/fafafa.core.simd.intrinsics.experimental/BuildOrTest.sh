#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"
shift || true

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
PROJ="${ROOT}/fafafa.core.simd.intrinsics.experimental.test.lpr"
FPC_BIN="${FPC_BIN:-fpc}"
CPU="$(${FPC_BIN} -iTP 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
OS="$(${FPC_BIN} -iTO 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
TRIPLET="${CPU}-${OS}"
BIN_DIR="${ROOT}/bin"
LIB_DIR="${ROOT}/lib/${TRIPLET}"
BIN="${BIN_DIR}/fafafa.core.simd.intrinsics.experimental.test"
LOG_DIR="${ROOT}/logs"
BUILD_LOG="${LOG_DIR}/build.txt"
TEST_LOG="${LOG_DIR}/test.txt"
X86_SMOKE_LOG="${LOG_DIR}/x86_sse2_smoke.txt"
X86_SMOKE_SOURCE="${LOG_DIR}/x86_sse2_smoke.pas"
X86_SMOKE_BIN="${BIN_DIR}/x86_sse2_smoke"
MMX_SMOKE_LOG="${LOG_DIR}/mmx_smoke.txt"
MMX_SMOKE_SOURCE="${LOG_DIR}/mmx_smoke.pas"
MMX_SMOKE_BIN="${BIN_DIR}/mmx_smoke"
SSE_SMOKE_LOG="${LOG_DIR}/sse_smoke.txt"
SSE_SMOKE_SOURCE="${LOG_DIR}/sse_smoke.pas"
SSE_SMOKE_BIN="${BIN_DIR}/sse_smoke"
SSE3_SMOKE_LOG="${LOG_DIR}/sse3_smoke.txt"
SSE3_SMOKE_SOURCE="${LOG_DIR}/sse3_smoke.pas"
SSE3_SMOKE_BIN="${BIN_DIR}/sse3_smoke"
AVX_SMOKE_LOG="${LOG_DIR}/avx_smoke.txt"
AVX_SMOKE_SOURCE="${LOG_DIR}/avx_smoke.pas"
AVX_SMOKE_BIN="${BIN_DIR}/avx_smoke"
AVX2_SMOKE_LOG="${LOG_DIR}/avx2_smoke.txt"
AVX2_SMOKE_SOURCE="${LOG_DIR}/avx2_smoke.pas"
AVX2_SMOKE_BIN="${BIN_DIR}/avx2_smoke"
AVX512_SMOKE_LOG="${LOG_DIR}/avx512_smoke.txt"
AVX512_SMOKE_SOURCE="${LOG_DIR}/avx512_smoke.pas"
AVX512_SMOKE_BIN="${BIN_DIR}/avx512_smoke"
FMA3_SMOKE_LOG="${LOG_DIR}/fma3_smoke.txt"
FMA3_SMOKE_SOURCE="${LOG_DIR}/fma3_smoke.pas"
FMA3_SMOKE_BIN="${BIN_DIR}/fma3_smoke"
EXPERIMENTAL_FLAG="${FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS:-0}"
HYGIENE_CHECKER="${REPO_ROOT}/tests/fafafa.core.simd/check_intrinsics_comment_swallow.py"

mkdir -p "${BIN_DIR}" "${LIB_DIR}" "${LOG_DIR}"

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
DEFINES=("-dFAFAFA_SIMD_EXPERIMENTAL_TEST_BUILD")
add_fu() {
  local LDir
  LDir="$1"
  [[ -d "${LDir}" ]] && FU+=("-Fu${LDir}")
}

if [[ "${EXPERIMENTAL_FLAG}" != "0" ]]; then
  DEFINES+=("-dFAFAFA_SIMD_EXPERIMENTAL_INTRINSICS")
fi

add_fu "${REPO_ROOT}/src"
add_fu "${ROOT}"
FI+=("-Fi${REPO_ROOT}/src" "-Fi${ROOT}")
if [[ -n "${UNITS_ROOT}" ]]; then
  add_fu "${UNITS_ROOT}/rtl"
  add_fu "${UNITS_ROOT}/rtl-objpas"
  add_fu "${UNITS_ROOT}/fcl-base"
  add_fu "${UNITS_ROOT}/fcl-fpcunit"
fi

build_project() {
  echo "[BUILD] Target: ${PROJ} (experimental=${EXPERIMENTAL_FLAG})"
  : >"${BUILD_LOG}"
  if [[ ! -f "${PROJ}" ]]; then
    echo "[BUILD] FAILED rc=2 (missing ${PROJ})"
    return 2
  fi

  if "${FPC_BIN}" \
    "${FU[@]}" \
    "${FI[@]}" \
    "${DEFINES[@]}" \
    -FE"${BIN_DIR}" \
    -FU"${LIB_DIR}" \
    -o"${BIN}" \
    "${PROJ}" >"${BUILD_LOG}" 2>&1; then
    echo "[BUILD] OK"
  else
    local LRC=$?
    echo "[BUILD] FAILED rc=${LRC} (see ${BUILD_LOG})"
    return "${LRC}"
  fi
}

check_build_log() {
  if grep -nE '(^|.*/)src/fafafa\.core\.simd\.intrinsics\..*(Warning:|Hint:)' "${BUILD_LOG}" >/dev/null; then
    echo "[CHECK] Found warnings/hints from SIMD intrinsics units in build log:"
    grep -nE '(^|.*/)src/fafafa\.core\.simd\.intrinsics\..*(Warning:|Hint:)' "${BUILD_LOG}" || true
    return 1
  fi
  echo "[CHECK] OK (no SIMD-unit warnings/hints)"
}

check_source_hygiene() {
  if [[ ! -f "${HYGIENE_CHECKER}" ]]; then
    echo "[CHECK] Missing hygiene checker: ${HYGIENE_CHECKER}"
    return 2
  fi
  echo "[CHECK] Running: python3 ${HYGIENE_CHECKER} --summary-line"
  python3 "${HYGIENE_CHECKER}" --summary-line
}

is_x86_cpu() {
  case "${CPU}" in
    x86_64|i386|i486|i586|i686)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

check_unit_backend_smoke() {
  local aLabel
  local aProgramName
  local aSourcePath
  local aLogPath
  local aBinPath
  local aUnitRegex
  local -a aUnits

  aLabel="$1"
  aProgramName="$2"
  aSourcePath="$3"
  aLogPath="$4"
  aBinPath="$5"
  aUnitRegex="$6"
  shift 6
  aUnits=("$@")

  if ! is_x86_cpu; then
    echo "[CHECK] SKIP ${aLabel} smoke (target CPU=${CPU})"
    return 0
  fi

  {
    printf 'program %s;\n' "${aProgramName}"
    printf '{\$mode objfpc}{\$H+}\n'
    printf '{\$I %s/src/fafafa.core.settings.inc}\n' "${REPO_ROOT}"
    printf 'uses\n'
    local LIndex
    for LIndex in "${!aUnits[@]}"; do
      if [[ "${LIndex}" -eq $((${#aUnits[@]} - 1)) ]]; then
        printf '  %s;\n' "${aUnits[${LIndex}]}"
      else
        printf '  %s,\n' "${aUnits[${LIndex}]}"
      fi
    done
    printf 'begin\n'
    printf 'end.\n'
  } >"${aSourcePath}"

  echo "[CHECK] Running ${aLabel} smoke: ${aSourcePath}"
  : >"${aLogPath}"
  if "${FPC_BIN}" \
    "${FU[@]}" \
    "${FI[@]}" \
    "${DEFINES[@]}" \
    -FE"${BIN_DIR}" \
    -FU"${LIB_DIR}" \
    -o"${aBinPath}" \
    "${aSourcePath}" >"${aLogPath}" 2>&1; then
    :
  else
    local LRC=$?
    echo "[CHECK] FAILED ${aLabel} smoke rc=${LRC} (see ${aLogPath})"
    tail -n 120 "${aLogPath}" || true
    return "${LRC}"
  fi

  if grep -nE "(^|.*/)src/${aUnitRegex}\.pas.*(Warning:|Hint:)" "${aLogPath}" >/dev/null; then
    echo "[CHECK] FAILED ${aLabel} smoke: warnings/hints from checked intrinsics unit"
    grep -nE "(^|.*/)src/${aUnitRegex}\.pas.*(Warning:|Hint:)" "${aLogPath}" || true
    return 1
  fi

  echo "[CHECK] OK ${aLabel} smoke"
}

check_x86_backend_smoke() {
  check_unit_backend_smoke \
    "x86 backend" \
    "x86_sse2_smoke" \
    "${X86_SMOKE_SOURCE}" \
    "${X86_SMOKE_LOG}" \
    "${X86_SMOKE_BIN}" \
    'fafafa\.core\.simd\.intrinsics\.x86\.sse2' \
    fafafa.core.simd.intrinsics.base \
    fafafa.core.simd.intrinsics.x86.sse2
}

check_mmx_backend_smoke() {
  check_unit_backend_smoke \
    "MMX backend" \
    "mmx_smoke" \
    "${MMX_SMOKE_SOURCE}" \
    "${MMX_SMOKE_LOG}" \
    "${MMX_SMOKE_BIN}" \
    'fafafa\.core\.simd\.intrinsics\.mmx' \
    fafafa.core.simd.intrinsics.mmx
}

check_sse_backend_smoke() {
  check_unit_backend_smoke \
    "SSE backend" \
    "sse_smoke" \
    "${SSE_SMOKE_SOURCE}" \
    "${SSE_SMOKE_LOG}" \
    "${SSE_SMOKE_BIN}" \
    'fafafa\.core\.simd\.intrinsics\.sse' \
    fafafa.core.simd.intrinsics.sse
}

check_sse3_backend_smoke() {
  check_unit_backend_smoke \
    "SSE3 backend" \
    "sse3_smoke" \
    "${SSE3_SMOKE_SOURCE}" \
    "${SSE3_SMOKE_LOG}" \
    "${SSE3_SMOKE_BIN}" \
    'fafafa\.core\.simd\.intrinsics\.sse3' \
    fafafa.core.simd.intrinsics.sse3
}

check_avx_backend_smoke() {
  check_unit_backend_smoke \
    "AVX backend" \
    "avx_smoke" \
    "${AVX_SMOKE_SOURCE}" \
    "${AVX_SMOKE_LOG}" \
    "${AVX_SMOKE_BIN}" \
    'fafafa\.core\.simd\.intrinsics\.avx' \
    fafafa.core.simd.intrinsics.avx
}

check_avx2_backend_smoke() {
  check_unit_backend_smoke \
    "AVX2 backend" \
    "avx2_smoke" \
    "${AVX2_SMOKE_SOURCE}" \
    "${AVX2_SMOKE_LOG}" \
    "${AVX2_SMOKE_BIN}" \
    'fafafa\.core\.simd\.intrinsics\.avx2' \
    fafafa.core.simd.intrinsics.avx2
}

check_avx512_backend_smoke() {
  check_unit_backend_smoke \
    "AVX512 backend" \
    "avx512_smoke" \
    "${AVX512_SMOKE_SOURCE}" \
    "${AVX512_SMOKE_LOG}" \
    "${AVX512_SMOKE_BIN}" \
    'fafafa\.core\.simd\.intrinsics\.avx512' \
    fafafa.core.simd.intrinsics.avx512
}

check_fma3_backend_smoke() {
  check_unit_backend_smoke \
    "FMA3 backend" \
    "fma3_smoke" \
    "${FMA3_SMOKE_SOURCE}" \
    "${FMA3_SMOKE_LOG}" \
    "${FMA3_SMOKE_BIN}" \
    'fafafa\.core\.simd\.intrinsics\.fma3' \
    fafafa.core.simd.intrinsics.fma3
}

normalize_test_args() {
  local LArg
  local -a LArgs

  LArgs=()
  for LArg in "$@"; do
    case "${LArg}" in
      --list-suites)
        LArgs+=("--list")
        ;;
      test-all)
        ;;
      *)
        LArgs+=("${LArg}")
        ;;
    esac
  done

  printf '%s\0' "${LArgs[@]}"
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
    echo "[CLEAN] Removing bin/, lib/, logs/"
    rm -rf "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/logs"
    ;;
  build)
    build_project
    ;;
  check)
    build_project
    check_build_log
    check_source_hygiene
    check_x86_backend_smoke
    check_mmx_backend_smoke
    check_sse_backend_smoke
    check_sse3_backend_smoke
    check_avx_backend_smoke
    check_avx2_backend_smoke
    check_avx512_backend_smoke
    check_fma3_backend_smoke
    ;;
  debug|release|test|test-all)
    build_project
    check_source_hygiene
    check_x86_backend_smoke
    check_mmx_backend_smoke
    check_sse_backend_smoke
    check_sse3_backend_smoke
    check_avx_backend_smoke
    check_avx2_backend_smoke
    check_avx512_backend_smoke
    check_fma3_backend_smoke
    run_tests "$@"
    check_heap_leaks
    ;;
  *)
    echo "Usage: $0 [clean|build|check|test|test-all|debug|release] [test-args...]"
    exit 2
    ;;
esac
