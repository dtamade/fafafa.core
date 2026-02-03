#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${SCRIPT_DIR}/tests_id.lpi"
EXECUTABLE="${SCRIPT_DIR}/bin/tests_id"
LEAK_TEST="${SCRIPT_DIR}/bin/test_id_leak"

# Clean previous build artifacts (iron rule)
rm -rf "${SCRIPT_DIR}/bin" "${SCRIPT_DIR}/lib"
mkdir -p "${SCRIPT_DIR}/bin" "${SCRIPT_DIR}/lib"

echo "Building project: ${PROJECT} (Debug)"
if ! lazbuild --lazarusdir="/opt/fpcupdeluxe/lazarus" "${PROJECT}"; then
  echo
  echo "Build failed."
  exit 1
fi

echo
echo "Build successful."

if [[ "${1:-}" == "test" ]]; then
  echo "Running tests..."
  if ! "${EXECUTABLE}" --all --format=plain --progress; then
    echo
    echo "Tests failed!"
    exit 1
  fi
elif [[ "${1:-}" == "leak" ]]; then
  echo "Building leak test..."
  LEAK_PROJECT="${SCRIPT_DIR}/test_id_leak.lpi"
  if ! lazbuild --lazarusdir="/opt/fpcupdeluxe/lazarus" "${LEAK_PROJECT}"; then
    echo "Leak test build failed."
    exit 1
  fi
  echo "Running memory leak test..."
  "${LEAK_TEST}"
else
  echo "Usage: $0 [test|leak]"
  echo "  test - Run unit tests"
  echo "  leak - Run memory leak tests"
fi
