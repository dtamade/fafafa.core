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

mkdir -p "${BIN_DIR}" "${UNIT_DIR}" "${LOG_DIR}"

echo "[FPC] version=$(fpc -iV) target=${TARGET}"

echo "[BUILD] fpc fafafa.core.simd.test.lpr"
: >"${BUILD_LOG}"

# DEBUG define enables the project's debug assertions/bounds checks via fafafa.core.settings.inc
# -gh enables heaptrc leak reporting.
if fpc -B -Mobjfpc -Sc -Si -O1 -g -gl -gh -dDEBUG \
  -Fu../../src -Fi../../src \
  -FE"${BIN_DIR}" -FU"${UNIT_DIR}" \
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
