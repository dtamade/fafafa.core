#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LAZBUILD="lazbuild"
PROJECT="${SCRIPT_DIR}/tests_fs.lpi"
BIN="${SCRIPT_DIR}/bin"
LIB="${SCRIPT_DIR}/lib"
TEST_EXE="${BIN}/tests_fs"

mkdir -p "${BIN}" "${LIB}"

echo "[BUILD] Project: ${PROJECT}"
"${LAZBUILD}" "${PROJECT}"
BUILD_ERR=$?

if [ $BUILD_ERR -eq 0 ]; then
  echo "[BUILD] OK"
else
  echo "[BUILD] FAILED code=$BUILD_ERR"
fi

echo
if [[ "${1:-}" == "test" ]]; then
  if [ -x "${TEST_EXE}" ]; then
    echo "Running tests..."
    "${TEST_EXE}" --all --progress --format=plain
    EXIT_CODE=$?
    echo "Test runner exit code: $EXIT_CODE"
    exit $EXIT_CODE
  else
    echo "[ERROR] Test executable not found: ${TEST_EXE}"
    exit $BUILD_ERR
  fi
else
  if [ $BUILD_ERR -ne 0 ]; then
    exit $BUILD_ERR
  fi
  echo "To run tests, call this script with the 'test' parameter."
fi

