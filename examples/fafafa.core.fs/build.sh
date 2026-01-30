#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LAZBUILD="lazbuild" # Assumes lazbuild is in the system's PATH
PROJECT="$SCRIPT_DIR/example.fs.lpi"
TEST_EXECUTABLE="$SCRIPT_DIR/bin/example.fs"

echo "Building project: $PROJECT..."
$LAZBUILD $PROJECT

if [ $? -ne 0 ]; then
    echo ""
    echo "Build failed with error code $?."
    exit 1
fi

echo ""
echo "Build successful."
echo ""

if [ "$1" = "test" ]; then
    echo "Running fs example tests..."
    echo ""
    $TEST_EXECUTABLE
else
    echo "To run tests, call this script with the 'test' parameter."
fi