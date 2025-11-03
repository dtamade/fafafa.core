#!/bin/bash

echo "========================================"
echo "TCircularBuffer Test Build Script"
echo "========================================"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
TEST_DIR="$SCRIPT_DIR"
BIN_DIR="$PROJECT_ROOT/bin"
PROJECT_FILE="$TEST_DIR/test_circularbuffer.lpi"
EXECUTABLE="$BIN_DIR/test_circularbuffer"

build_project() {
    mkdir -p "$BIN_DIR"

    echo "    Project file: $PROJECT_FILE"
    echo "    Output directory: $BIN_DIR"

    if ! lazbuild --build-mode=Debug "$PROJECT_FILE"; then
        echo "Build failed!"
        return 1
    fi

    echo "Build successful"
    if [ -f "$EXECUTABLE" ]; then
        echo "    Executable: $EXECUTABLE"
        return 0
    else
        echo "ERROR: Executable not found: $EXECUTABLE"
        return 1
    fi
}

run_tests() {
    echo
    echo "Running tests..."
    echo "----------------------------------------"

    if ! "$EXECUTABLE"; then
        echo "Tests failed!"
        return 1
    fi

    echo "----------------------------------------"
    echo "Tests passed!"
    return 0
}

echo "Building project..."
if ! build_project; then
    exit 1
fi

if ! run_tests; then
    exit 1
fi

echo
echo "========================================"
echo "All tests passed!"
echo "========================================"
exit 0