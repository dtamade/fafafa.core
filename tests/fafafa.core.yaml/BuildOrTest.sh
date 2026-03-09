#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LAZBUILD_BIN="${LAZBUILD:-}"
if [[ -z "${LAZBUILD_BIN}" ]]; then
  if [[ -x "${SCRIPT_DIR}/../../tools/lazbuild.sh" ]]; then
    LAZBUILD_BIN="${SCRIPT_DIR}/../../tools/lazbuild.sh"
  else
    LAZBUILD_BIN="lazbuild"
  fi
fi

PROJECT="fafafa.core.yaml.test.lpi"
TEST_EXECUTABLE="./bin/fafafa.core.yaml.test"

echo "Building project: ${PROJECT}..."
"${LAZBUILD_BIN}" "${PROJECT}" --build-mode=Debug

echo
echo "Build successful."
echo

ACTION="${1:-test}"
if [[ "${ACTION}" == "test" || "${ACTION}" == "run" ]]; then
  if [[ -x "${TEST_EXECUTABLE}" ]]; then
    echo "Running tests..."
    "${TEST_EXECUTABLE}" --all --format=plain
  elif [[ -x "${TEST_EXECUTABLE}.exe" ]]; then
    echo "Running tests..."
    "${TEST_EXECUTABLE}.exe" --all --format=plain
  else
    echo "[ERROR] Test executable not found: ${TEST_EXECUTABLE}[.exe]" >&2
    exit 1
  fi
else
  echo "To run tests, call this script with the 'test' parameter."
fi
