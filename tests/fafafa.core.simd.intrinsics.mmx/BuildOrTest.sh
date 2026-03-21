#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"
shift || true

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${ROOT}}"
PROJ="${ROOT}/fafafa.core.simd.intrinsics.mmx.test.lpi"
FPC_BIN="${FPC_BIN:-fpc}"
TARGET_CPU="$(${FPC_BIN} -iTP 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
TARGET_OS="$(${FPC_BIN} -iTO 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
if [[ -z "${TARGET_CPU}" ]]; then
  TARGET_CPU="nativecpu"
fi
if [[ -z "${TARGET_OS}" ]]; then
  TARGET_OS="nativeos"
fi
UNIT_DIR="${OUTPUT_ROOT}/lib/${TARGET_CPU}-${TARGET_OS}"
BIN_DIR="${OUTPUT_ROOT}/bin"
BIN="${BIN_DIR}/fafafa.core.simd.intrinsics.mmx.test"
LOG_DIR="${OUTPUT_ROOT}/logs"
BUILD_LOG="${LOG_DIR}/build.txt"
TEST_LOG="${LOG_DIR}/test.txt"

mkdir -p "${BIN_DIR}" "${UNIT_DIR}" "${LOG_DIR}"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

LZ_Q=()
if [[ "${FAFAFA_BUILD_QUIET:-1}" != "0" ]]; then
  LZ_Q+=("--quiet")
fi

detect_lazarusdir() {
  local LLazbuildPath
  local LMaybeRoot
  local LCandidate

  if [[ -n "${FAFAFA_LAZARUSDIR:-}" ]]; then
    echo "${FAFAFA_LAZARUSDIR}"
    return 0
  fi

  if [[ -d "/opt/fpcupdeluxe/lazarus/lcl" ]]; then
    echo "/opt/fpcupdeluxe/lazarus"
    return 0
  fi

  LLazbuildPath="$(command -v "${LAZBUILD_BIN}" 2>/dev/null || true)"
  if [[ -n "${LLazbuildPath}" ]]; then
    LLazbuildPath="$(readlink -f "${LLazbuildPath}" 2>/dev/null || echo "${LLazbuildPath}")"
    LMaybeRoot="$(cd "$(dirname "${LLazbuildPath}")" && pwd)"
    if [[ -d "${LMaybeRoot}/lcl" ]]; then
      echo "${LMaybeRoot}"
      return 0
    fi
  fi

  for LCandidate in /usr/lib/lazarus/* /usr/local/lib/lazarus/*; do
    if [[ -d "${LCandidate}/lcl" ]]; then
      echo "${LCandidate}"
      return 0
    fi
  done

  echo ""
  return 0
}

resolve_binary_from_build_log() {
  local LLine
  local LCandidate
  local LBase

  if [[ ! -f "${BUILD_LOG}" ]]; then
    return 1
  fi

  LLine="$(grep -E '\(9015\)[[:space:]]+Linking[[:space:]]+' "${BUILD_LOG}" | tail -n 1 || true)"
  if [[ -z "${LLine}" ]]; then
    return 1
  fi

  LCandidate="$(printf '%s\n' "${LLine}" | sed -E 's/.*\(9015\)[[:space:]]+Linking[[:space:]]+//')"
  LCandidate="$(printf '%s' "${LCandidate}" | tr -d '\r')"
  if [[ -z "${LCandidate}" ]]; then
    return 1
  fi

  if [[ "${LCandidate}" == /* && -f "${LCandidate}" ]]; then
    echo "${LCandidate}"
    return 0
  fi

  for LBase in "${ROOT}" "${OUTPUT_ROOT}" "${REPO_ROOT}" "$(pwd)"; do
    if [[ -f "${LBase}/${LCandidate}" ]]; then
      echo "${LBase}/${LCandidate}"
      return 0
    fi
  done

  return 1
}

normalize_built_binary() {
  local LResolved

  if [[ -f "${BIN}" || -f "${BIN}.exe" ]]; then
    return 0
  fi

  LResolved="$(resolve_binary_from_build_log)" || return 0
  if [[ -z "${LResolved}" || ! -f "${LResolved}" ]]; then
    return 0
  fi

  if [[ "${LResolved}" == "${BIN}" || "${LResolved}" == "${BIN}.exe" ]]; then
    return 0
  fi

  mkdir -p "${BIN_DIR}"
  cp "${LResolved}" "${BIN}"
  chmod +x "${BIN}" 2>/dev/null || true
  echo "[BUILD] Binary normalized: ${LResolved} -> ${BIN}"
}

build_project() {
  local LLazarusDir
  local -a LLazbuildArgs

  echo "[BUILD] Project: ${PROJ} (output_root=${OUTPUT_ROOT})"
  : >"${BUILD_LOG}"
  LLazarusDir="$(detect_lazarusdir)"
  LLazbuildArgs=("${LZ_Q[@]}" "--build-all")
  if [[ -n "${LLazarusDir}" ]]; then
    LLazbuildArgs=("--lazarusdir=${LLazarusDir}" "${LLazbuildArgs[@]}")
  fi
  if "${LAZBUILD_BIN}" --help 2>&1 | grep -q -- '--opt'; then
    LLazbuildArgs+=("--opt=-FE${BIN_DIR}" "--opt=-FU${UNIT_DIR}")
  elif [[ "${OUTPUT_ROOT}" != "${ROOT}" ]]; then
    echo "[BUILD] WARN: lazbuild without --opt support; output isolation may fall back to project-local bin/lib" >>"${BUILD_LOG}"
  fi

  if "${LAZBUILD_BIN}" "${LLazbuildArgs[@]}" "${PROJ}" >>"${BUILD_LOG}" 2>&1; then
    normalize_built_binary
    echo "[BUILD] OK"
  else
    local LRC=$?
    echo "[BUILD] FAILED rc=${LRC} (see ${BUILD_LOG})"
    return "${LRC}"
  fi
}

check_build_log() {
  if grep -nE 'src/fafafa\.core\.simd.*(Warning:|Hint:)' "${BUILD_LOG}" >/dev/null; then
    echo "[CHECK] Found warnings/hints from SIMD units in build log:"
    grep -nE 'src/fafafa\.core\.simd.*(Warning:|Hint:)' "${BUILD_LOG}" || true
    return 1
  fi
  echo "[CHECK] OK (no SIMD unit warnings/hints)"
}

resolve_test_binary() {
  local LCandidate

  for LCandidate in \
    "${BIN}" \
    "${BIN}.exe" \
    "${ROOT}/bin/fafafa.core.simd.intrinsics.mmx.test" \
    "${ROOT}/bin/fafafa.core.simd.intrinsics.mmx.test.exe"; do
    if [[ -f "${LCandidate}" ]]; then
      chmod +x "${LCandidate}" 2>/dev/null || true
      echo "${LCandidate}"
      return 0
    fi
  done

  while IFS= read -r LCandidate; do
    if [[ -n "${LCandidate}" && -f "${LCandidate}" ]]; then
      chmod +x "${LCandidate}" 2>/dev/null || true
      echo "${LCandidate}"
      return 0
    fi
  done < <(
    find "${OUTPUT_ROOT}" "${ROOT}" -maxdepth 3 -type f \
      \( -name 'fafafa.core.simd.intrinsics.mmx.test' -o -name 'fafafa.core.simd.intrinsics.mmx.test.exe' \) \
      2>/dev/null | sort -u
  )

  return 1
}

run_tests() {
  local LBinPath

  LBinPath="$(resolve_test_binary)" || {
    echo "[TEST] Missing binary: ${BIN} (did build succeed?)"
    return 2
  }

  echo "[TEST] Running: ${LBinPath} --all --format=plain"
  : >"${TEST_LOG}"
  if "${LBinPath}" --all --format=plain >"${TEST_LOG}" 2>&1; then
    echo "[TEST] OK"
  else
    local LRC=$?
    echo "[TEST] FAILED rc=${LRC} (see ${TEST_LOG})"
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

run_clean() {
  echo "[CLEAN] Removing ${BIN_DIR}, ${OUTPUT_ROOT}/lib, ${LOG_DIR}"
  rm -rf "${BIN_DIR}" "${OUTPUT_ROOT}/lib" "${LOG_DIR}"
}

case "${ACTION}" in
  clean)
    run_clean
    ;;
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
    echo "Usage: $0 [clean|build|check|test] [test-args...]"
    exit 2
    ;;
esac
