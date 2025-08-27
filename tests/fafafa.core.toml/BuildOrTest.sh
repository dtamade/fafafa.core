#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAZBUILD="${SCRIPT_DIR}/../../tools/lazbuild.bat"
PROJECT="tests_toml.lpi"
TEST_EXECUTABLE="./bin/tests_toml"

echo "Building project: ${PROJECT}..."
"${LAZBUILD}" "${PROJECT}"
echo

echo "Build successful."

echo
if [[ "${1-}" == "test" ]]; then
  echo "Running tests..."
  "${TEST_EXECUTABLE}"
else
  echo "To run tests, call this script with the 'test' parameter."
fi

