#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${SCRIPT_DIR}/tests_mem_allocator_only.lpi"
EXECUTABLE="${SCRIPT_DIR}/bin/tests_mem_allocator_only"

# Clean previous build artifacts
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

echo "Running tests..."
if ! "${EXECUTABLE}" --all --format=plain; then
  echo
  echo "Tests failed!"
  exit 1
fi

echo
echo "All tests passed."
exit 0
