#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"
shift || true

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${ROOT}}"
FPC_BIN="${FPC_BIN:-fpc}"
CC_BIN="${CC:-cc}"
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
LOG_DIR="${OUTPUT_ROOT}/logs"
PROJ="${ROOT}/fafafa.core.simd.publicabi.lpr"
LIB_PATH=""
HARNESS_SRC="${ROOT}/publicabi_smoke.c"
HARNESS_BIN="${BIN_DIR}/publicabi_smoke"
BUILD_LOG="${LOG_DIR}/build.txt"
TEST_LOG="${LOG_DIR}/test.txt"
EXPORT_LOG="${LOG_DIR}/exports.txt"

mkdir -p "${BIN_DIR}" "${LIB_DIR}" "${LOG_DIR}"

resolve_library_path() {
  local -a LCandidates
  local LCandidate

  LCandidates=()
  shopt -s nullglob
  LCandidates+=(
    "${BIN_DIR}"/libfafafa*.so
    "${BIN_DIR}"/*.so
    "${BIN_DIR}"/libfafafa*.dylib
    "${BIN_DIR}"/*.dylib
  )
  shopt -u nullglob

  for LCandidate in "${LCandidates[@]}"; do
    if [[ -f "${LCandidate}" ]]; then
      LIB_PATH="${LCandidate}"
      return 0
    fi
  done
  return 1
}

build_project() {
  echo "[BUILD] Project: ${PROJ}"
  : > "${BUILD_LOG}"
  (
    cd "${ROOT}"
    "${FPC_BIN}" -B -Mobjfpc -Scghi -O3 \
      -Fi"${REPO_ROOT}/src" \
      -Fu"${REPO_ROOT}/src" \
      -FE"${BIN_DIR}" \
      -FU"${LIB_DIR}" \
      "${PROJ}"
  ) > "${BUILD_LOG}" 2>&1 || return $?

  if ! resolve_library_path; then
    echo "[BUILD] FAILED (library missing in ${BIN_DIR})"
    tail -n 80 "${BUILD_LOG}" || true
    return 1
  fi

  echo "[BUILD] OK (${LIB_PATH})"
}

build_harness() {
  local -a LCompilerArgs

  echo "[BUILD] Harness: ${HARNESS_SRC}"
  LCompilerArgs=(-std=c11 -O2 "${HARNESS_SRC}" -o "${HARNESS_BIN}")
  if [[ "${TARGET_OS}" != "darwin" ]]; then
    LCompilerArgs+=(-ldl)
  fi
  "${CC_BIN}" "${LCompilerArgs[@]}"
}

validate_exports() {
  local -a REQUIRED_SYMBOLS
  local LSymbol

  REQUIRED_SYMBOLS=(
    "fafafa_simd_abi_version_major"
    "fafafa_simd_abi_version_minor"
    "fafafa_simd_abi_signature"
    "fafafa_simd_get_backend_pod_info"
    "fafafa_simd_backend_name"
    "fafafa_simd_backend_description"
    "fafafa_simd_get_public_api"
    "fafafa_simd_get_public_api_v2"
  )

  : > "${EXPORT_LOG}"

  if [[ "${TARGET_OS}" == "darwin" ]] && command -v nm >/dev/null 2>&1; then
    echo "[EXPORT] Running: nm -gU ${LIB_PATH}"
    nm -gU "${LIB_PATH}" > "${EXPORT_LOG}" 2>&1
  elif command -v readelf >/dev/null 2>&1; then
    echo "[EXPORT] Running: readelf --wide --dyn-syms ${LIB_PATH}"
    readelf --wide --dyn-syms "${LIB_PATH}" > "${EXPORT_LOG}" 2>&1
  elif command -v nm >/dev/null 2>&1; then
    echo "[EXPORT] Running: nm -D --defined-only ${LIB_PATH}"
    nm -D --defined-only "${LIB_PATH}" > "${EXPORT_LOG}" 2>&1
  else
    echo "[EXPORT] FAILED (readelf/nm not found; validate-exports requires a symbol inspection tool)"
    return 2
  fi

  for LSymbol in "${REQUIRED_SYMBOLS[@]}"; do
    if ! grep -F "${LSymbol}" "${EXPORT_LOG}" >/dev/null; then
      echo "[EXPORT] FAILED: missing symbol ${LSymbol}"
      cat "${EXPORT_LOG}"
      return 1
    fi
  done

  echo "[EXPORT] OK"
}

run_harness() {
  : > "${TEST_LOG}"
  "${HARNESS_BIN}" "${LIB_PATH}" > "${TEST_LOG}" 2>&1 || {
    if [[ "${TARGET_OS}" == "darwin" ]]; then
      {
        echo "[TEST] Darwin retry with FAFAFA_PUBLICABI_DLOPEN_SCOPE=global"
        FAFAFA_PUBLICABI_DLOPEN_SCOPE=global "${HARNESS_BIN}" "${LIB_PATH}"
      } >> "${TEST_LOG}" 2>&1 || true
    fi
    echo "[TEST] FAILED (see ${TEST_LOG})"
    cat "${TEST_LOG}"
    if [[ -f "${EXPORT_LOG}" ]]; then
      echo "[TEST] Export snapshot (${EXPORT_LOG})"
      cat "${EXPORT_LOG}"
    fi
    return 1
  }
  echo "[TEST] OK"
}

case "${ACTION}" in
  clean)
    rm -rf "${BIN_DIR}" "${LIB_DIR}" "${LOG_DIR}"
    ;;
  build)
    build_project
    build_harness
    ;;
  validate-exports)
    build_project
    validate_exports
    ;;
  test|run)
    build_project
    validate_exports
    build_harness
    run_harness
    ;;
  *)
    echo "Usage: $0 [clean|build|validate-exports|test|run]"
    exit 2
    ;;
esac
