#!/bin/bash

# Set paths relative to the script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAZBUILD="lazbuild"
PROJECT="${SCRIPT_DIR}/tests_tick.lpi"
TEST_EXECUTABLE="${SCRIPT_DIR}/bin/tests_tick"
LPR_FILE="${SCRIPT_DIR}/tests_tick.lpr"

# Build the project
echo "Building fafafa.core.tick test project: ${PROJECT}..."
${LAZBUILD} "${PROJECT}"

if [ $? -ne 0 ]; then
    echo
    echo "Build failed with error code $?."
    exit 1
fi

echo
echo "Build successful."
echo

# Run tests if the 'test' parameter is provided
if [ "$1" = "test" ]; then
    echo "Running fafafa.core.tick tests..."
    echo
    "${TEST_EXECUTABLE}"
else
    echo "To run tests, call this script with the 'test' parameter."
    echo "e.g., ./BuildOrTest.sh test"
fi
