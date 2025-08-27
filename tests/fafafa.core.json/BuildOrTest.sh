#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
LAZBUILD="${SCRIPT_DIR}/../../tools/lazbuild.sh"
if [ ! -x "$LAZBUILD" ]; then
  echo "[WARN] tools/lazbuild.sh not found or not executable, falling back to lazbuild in PATH"
  LAZBUILD="lazbuild"
fi
PROJECT="tests_json.lpi"
TEST_EXECUTABLE="./bin/tests_json_debug"

echo "[BUILD] Project: ${PROJECT}"
"${LAZBUILD}" "${PROJECT}"
BUILD_ERR=$?
if [ $BUILD_ERR -eq 0 ]; then
  echo "[BUILD] OK"
else
  echo "[BUILD] FAILED code=$BUILD_ERR"
fi

if [[ "${1:-}" == "test" ]]; then
  if [ -x "${TEST_EXECUTABLE}" ]; then
    echo "Running tests..."
    "${TEST_EXECUTABLE}"
    EXIT_CODE=$?
    echo "Test runner exit code: $EXIT_CODE"
    exit $EXIT_CODE
  else
    echo "[ERROR] Test executable not found: ${TEST_EXECUTABLE}"
    exit $BUILD_ERR
  fi
else
  if [ $BUILD_ERR -ne 0 ]; then
    exit $BUILD_ERR
  fi
  echo "To run tests, call this script with the 'test' parameter."
fi

