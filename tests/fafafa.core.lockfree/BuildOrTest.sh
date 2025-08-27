#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LAZBUILD="../../tools/lazbuild.sh"

PROJECT="fafafa.core.lockfree.tests.lpi"

TEST_EXECUTABLE="bin/lockfree_tests"

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

if [ "$1" = "test" ]; then
    echo "Running tests..."
    "$TEST_EXECUTABLE"
else
    echo "To run tests, call this script with the 'test' parameter."
fi
