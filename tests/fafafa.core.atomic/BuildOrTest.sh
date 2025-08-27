#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$SCRIPT_DIR/tests_atomic.lpi"
TEST_BIN="$SCRIPT_DIR/bin/tests_atomic"

# Clean outputs (iron rule before build)
rm -rf "$SCRIPT_DIR/bin" "$SCRIPT_DIR/lib"

# Build with lazbuild (must be in PATH)
echo "Building project: $PROJECT ..."
lazbuild "$PROJECT"

echo
echo "Build successful."

if [[ "${1:-}" == "test" ]]; then
  echo "Running tests..."
  if [[ -x "$TEST_BIN" ]]; then
    "$TEST_BIN" --all --format=plain
  elif [[ -x "$TEST_BIN.exe" ]]; then
    "$TEST_BIN.exe" --all --format=plain
  else
    echo "Test executable not found. Looked for:"
    echo "  $TEST_BIN"
    echo "  $TEST_BIN.exe"
    exit 1
  fi
else
  echo "To run tests, call this script with the 'test' parameter."
fi

