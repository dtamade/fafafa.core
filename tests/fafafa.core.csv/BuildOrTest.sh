#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAZBUILD="$ROOT_DIR/tools/lazbuild.bat"

PROJECT="tests_csv.lpi"
BIN_DIR="$SCRIPT_DIR/bin"
LIB_DIR="$SCRIPT_DIR/lib"
TMP_DIR="$SCRIPT_DIR/tmp"
TEST_EXECUTABLE="$BIN_DIR/tests.exe"

mkdir -p "$BIN_DIR" "$LIB_DIR" "$TMP_DIR"

echo "Building project: $PROJECT ..."
"$LAZBUILD" "$SCRIPT_DIR/$PROJECT"

echo

echo "Build successful."

echo
if [[ "${1:-}" == "test" ]]; then
  echo "Running tests..."
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

