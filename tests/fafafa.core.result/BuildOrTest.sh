#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT="$SCRIPT_DIR/tests_result.lpi"
BIN_DIR="$SCRIPT_DIR/bin"
LIB_DIR="$SCRIPT_DIR/lib"
TEST_EXECUTABLE_BASE="$BIN_DIR/tests"

LAZBUILD_BIN="${LAZBUILD:-$(command -v lazbuild 2>/dev/null || true)}"
if [[ -z "${LAZBUILD_BIN}" ]]; then
  echo "[ERROR] lazbuild not found in PATH (set LAZBUILD=/path/to/lazbuild)"
  exit 1
fi

# Clean previous build artifacts (iron rule)
rm -rf "$BIN_DIR" "$LIB_DIR"
mkdir -p "$BIN_DIR" "$LIB_DIR"

echo "Building project: $PROJECT (Debug)"
"$LAZBUILD_BIN" --build-mode=Debug "$PROJECT"

echo

echo "Build successful."

action="${1:-}"
if [[ "$action" == "test" ]]; then
  echo "Running tests..."

  if [[ -x "${TEST_EXECUTABLE_BASE}" ]]; then
    "${TEST_EXECUTABLE_BASE}" --all --format=plain --progress
  elif [[ -x "${TEST_EXECUTABLE_BASE}.exe" ]]; then
    "${TEST_EXECUTABLE_BASE}.exe" --all --format=plain --progress
  else
    echo "[ERROR] Test executable not found. Looked for:"
    echo "  ${TEST_EXECUTABLE_BASE}"
    echo "  ${TEST_EXECUTABLE_BASE}.exe"
    exit 1
  fi
else
  echo "To run tests, call this script with the 'test' parameter."
fi

