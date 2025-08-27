#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${SCRIPT_DIR}/tests_collections.lpi"
EXECUTABLE="${SCRIPT_DIR}/bin/tests_collections"

# Clean previous build artifacts (iron rule)
rm -rf "${SCRIPT_DIR}/bin" "${SCRIPT_DIR}/lib"
mkdir -p "${SCRIPT_DIR}/bin" "${SCRIPT_DIR}/lib"

echo "Building project: ${PROJECT} (Debug)"
if ! lazbuild --build-mode=Debug "${PROJECT}"; then
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
else
  echo "To run tests, call this script with the 'test' parameter."
fi

