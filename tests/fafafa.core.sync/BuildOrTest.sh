#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="tests_sync"
PROJECT_FILE="${SCRIPT_DIR}/${PROJECT_NAME}.lpi"
BIN_DIR="${SCRIPT_DIR}/bin"
LIB_DIR="${SCRIPT_DIR}/lib"
TEST_BIN="${BIN_DIR}/${PROJECT_NAME}"

echo "========================================"
echo "fafafa.core.sync BuildOrTest"
echo "========================================"

# 检查 lazbuild 是否可用
if ! command -v lazbuild &>/dev/null; then
  echo "[ERROR] lazbuild not found in PATH"
  exit 1
fi

# Clean previous build artifacts (iron rule)
rm -rf "${BIN_DIR}" "${LIB_DIR}"
mkdir -p "${BIN_DIR}" "${LIB_DIR}"

echo "Building project: ${PROJECT_FILE} (Debug)"
lazbuild --lazarusdir="/opt/fpcupdeluxe/lazarus" "${PROJECT_FILE}"

echo

echo "Build successful."

action="${1:-}"
if [[ "${action}" == "test" || "${action}" == "run" ]]; then
  echo "Running tests..."

  if [[ -x "${TEST_BIN}" ]]; then
    "${TEST_BIN}" --all --format=plain --progress
  elif [[ -x "${TEST_BIN}.exe" ]]; then
    "${TEST_BIN}.exe" --all --format=plain --progress
  else
    echo "[ERROR] Test executable not found. Looked for:"
    echo "  ${TEST_BIN}"
    echo "  ${TEST_BIN}.exe"
    exit 1
  fi
else
  echo "To run tests, call this script with the 'test' parameter."
fi
