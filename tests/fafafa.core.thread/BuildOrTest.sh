#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

LAZBUILD="lazbuild"

PROJECT="tests_thread.lpi"

# NOTE:
# tests_thread.lpi outputs to repo root: ../../bin/tests_thread[.exe]
TEST_EXECUTABLE="${TEST_EXECUTABLE:-../../bin/tests_thread}"

echo "Building project: $PROJECT..."
"$LAZBUILD" "$PROJECT"

if [ $? -ne 0 ]; then
    echo
    echo "Build failed with error code $?."
    exit 1
fi

echo
echo "Build successful."
echo

if [ "${1:-}" = "test" ]; then
    echo "Running tests..."
    if [[ -x "${TEST_EXECUTABLE}" ]]; then
        "${TEST_EXECUTABLE}" --all --format=plain
    elif [[ -x "${TEST_EXECUTABLE}.exe" ]]; then
        "${TEST_EXECUTABLE}.exe" --all --format=plain
    else
        echo "[ERROR] test executable not found: ${TEST_EXECUTABLE}[.exe]" >&2
        exit 127
    fi
else
    echo "To run tests, call this script with the 'test' parameter."
fi
