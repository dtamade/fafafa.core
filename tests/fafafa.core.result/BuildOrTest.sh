#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd -- "$SCRIPT_DIR/../.." && pwd)
LAZBUILD="$ROOT_DIR/tools/lazbuild.bat"
PROJECT="$SCRIPT_DIR/tests_result.lpi"
BIN_DIR="$SCRIPT_DIR/bin"
LIB_DIR="$SCRIPT_DIR/lib"
TEST_EXECUTABLE="$BIN_DIR/tests"

mkdir -p "$BIN_DIR" "$LIB_DIR"

echo "Building project: $PROJECT ..."
"$LAZBUILD" "$PROJECT"
echo

if [[ "${1:-}" == "test" ]]; then
  echo "Running tests..."
  "$TEST_EXECUTABLE"
else
  echo "To run tests, call this script with the 'test' parameter."
fi

