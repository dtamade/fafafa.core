#!/usr/bin/env bash
set -euo pipefail

# Run from repo root inside container
if [[ ! -d tests/fafafa.core.simd ]]; then
  echo "[ERROR] Expected repo root with tests/fafafa.core.simd/"
  exit 2
fi

cd tests/fafafa.core.simd

TARGET_CPU="$(fpc -iTP)"
TARGET_OS="$(fpc -iTO)"
TARGET="${TARGET_CPU}-${TARGET_OS}"

BIN_DIR="bin2"
UNIT_DIR="lib2/${TARGET}"
LOG_DIR="logs"

BUILD_LOG="${LOG_DIR}/fpc_build_${TARGET}.txt"
TEST_LOG="${LOG_DIR}/fpc_test_${TARGET}.txt"
MODE="${FAFAFA_BUILD_MODE:-Release}"
FPC_EXTRA_DEFINES_STRING="${SIMD_FPC_EXTRA_DEFINES:-}"
FPC_EXTRA_ARGS_STRING="${SIMD_FPC_EXTRA_ARGS:-}"
FPC_EXTRA_DEFINES=()
FPC_EXTRA_ARGS=()

normalize_mode() {
  case "${MODE}" in
    Debug|debug)
      MODE="Debug"
      ;;
    Release|release)
      MODE="Release"
      ;;
    *)
      echo "[ERROR] Unsupported FAFAFA_BUILD_MODE=${MODE} (expect Debug|Release)"
      exit 2
      ;;
  esac
}

if [[ -n "${FPC_EXTRA_DEFINES_STRING}" ]]; then
  read -r -a FPC_EXTRA_DEFINES <<< "${FPC_EXTRA_DEFINES_STRING}"
fi
if [[ -n "${FPC_EXTRA_ARGS_STRING}" ]]; then
  read -r -a FPC_EXTRA_ARGS <<< "${FPC_EXTRA_ARGS_STRING}"
fi

mkdir -p "${BIN_DIR}" "${UNIT_DIR}" "${LOG_DIR}"
normalize_mode

echo "[FPC] version=$(fpc -iV) target=${TARGET} mode=${MODE}"
if [[ -n "${FPC_EXTRA_DEFINES_STRING}" ]]; then
  echo "[FPC] extra-defines=${FPC_EXTRA_DEFINES_STRING}"
fi
if [[ -n "${FPC_EXTRA_ARGS_STRING}" ]]; then
  echo "[FPC] extra-args=${FPC_EXTRA_ARGS_STRING}"
fi

echo "[BUILD] fpc fafafa.core.simd.test.lpr"
: >"${BUILD_LOG}"

FPC_MODE_FLAGS=()
if [[ "${MODE}" == "Debug" ]]; then
  # Debug: keep assertions and debug define.
  FPC_MODE_FLAGS=(-O1 -g -gl -gh -dDEBUG)
else
  # Release: no DEBUG define, keep heaptrc for leak gate parity.
  FPC_MODE_FLAGS=(-O2 -gl -gh)
fi

if fpc -B -Mobjfpc -Sc -Si "${FPC_MODE_FLAGS[@]}" \
  -Fu../../src -Fi../../src \
  -FE"${BIN_DIR}" -FU"${UNIT_DIR}" \
  "${FPC_EXTRA_DEFINES[@]}" \
  "${FPC_EXTRA_ARGS[@]}" \
  fafafa.core.simd.test.lpr >"${BUILD_LOG}" 2>&1; then
  echo "[BUILD] OK"
else
  rc=$?
  echo "[BUILD] FAILED rc=${rc} (see ${BUILD_LOG})"
  tail -n 120 "${BUILD_LOG}" || true
  exit "${rc}"
fi

# Module acceptance criteria: no warnings/hints emitted from SIMD module units under src/.
if grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${BUILD_LOG}" >/dev/null; then
  echo "[CHECK] Found warnings/hints from SIMD units in build log:"
  grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${BUILD_LOG}" || true
  exit 1
fi

echo "[CHECK] OK (no SIMD-unit warnings/hints)"

if [[ "${SIMD_RUN_ONLY_BUILD:-0}" != "0" ]]; then
  echo "[TEST] SKIP (SIMD_RUN_ONLY_BUILD=${SIMD_RUN_ONLY_BUILD})"
  exit 0
fi

BIN="${BIN_DIR}/fafafa.core.simd.test"
if [[ ! -x "${BIN}" ]]; then
  echo "[TEST] Missing binary: ${BIN}"
  exit 2
fi

echo "[TEST] Running: ${BIN} $*"
: >"${TEST_LOG}"

if "./${BIN}" "$@" >"${TEST_LOG}" 2>&1; then
  echo "[TEST] OK"
else
  rc=$?
  echo "[TEST] FAILED rc=${rc} (see ${TEST_LOG})"
  tail -n 120 "${TEST_LOG}" || true
  exit "${rc}"
fi

# heaptrc prints e.g. "0 unfreed memory blocks : 0" or "2 unfreed memory blocks : 38".
if grep -nE '^[1-9][0-9]* unfreed memory blocks' "${TEST_LOG}" >/dev/null; then
  echo "[LEAK] FAILED: heaptrc reports unfreed blocks:"
  grep -nE '^[0-9]+ unfreed memory blocks' "${TEST_LOG}" || true
  exit 1
fi

echo "[LEAK] OK"
