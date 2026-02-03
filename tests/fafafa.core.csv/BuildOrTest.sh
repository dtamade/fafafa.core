#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="$SCRIPT_DIR/tests_csv.lpi"
BIN_DIR="$SCRIPT_DIR/bin"
LIB_DIR="$SCRIPT_DIR/lib"
TMP_DIR="$SCRIPT_DIR/tmp"
TEST_EXECUTABLE_BASE="$BIN_DIR/tests"

LAZBUILD_BIN="${LAZBUILD:-$(command -v lazbuild 2>/dev/null || true)}"
if [[ -z "${LAZBUILD_BIN}" ]]; then
  echo "[ERROR] lazbuild not found in PATH (set LAZBUILD=/path/to/lazbuild)"
  exit 1
fi

# Clean previous build artifacts (iron rule)
rm -rf "$BIN_DIR" "$LIB_DIR"
mkdir -p "$BIN_DIR" "$LIB_DIR" "$TMP_DIR"

echo "Building project: $PROJECT_FILE (Debug)"
"$LAZBUILD_BIN" "$PROJECT_FILE"

echo

echo "Build successful."

echo
if [[ "${1:-}" == "test" ]]; then
  echo "Running tests..."

  if [[ -x "${TEST_EXECUTABLE_BASE}" ]]; then
    TEST_EXECUTABLE="${TEST_EXECUTABLE_BASE}"
  elif [[ -x "${TEST_EXECUTABLE_BASE}.exe" ]]; then
    TEST_EXECUTABLE="${TEST_EXECUTABLE_BASE}.exe"
  else
    echo "[ERROR] Test executable not found. Looked for:"
    echo "  ${TEST_EXECUTABLE_BASE}"
    echo "  ${TEST_EXECUTABLE_BASE}.exe"
    exit 1
  fi

  # run tests with CWD switched to module tmp dir so relative CSV files go under tests/tmp
  pushd "$TMP_DIR" >/dev/null
  "$TEST_EXECUTABLE" --all --progress -u > "$BIN_DIR/last-run.txt" 2>&1
  "$TEST_EXECUTABLE" --all --format=xml > "$BIN_DIR/results.xml" 2>&1
  popd >/dev/null

  # show quick console log
  cat "$BIN_DIR/last-run.txt"
  echo "====== End of console log ======"
else
  echo "To run tests, call this script with the 'test' parameter."
fi

