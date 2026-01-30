#!/bin/bash

# Standardized Build/Test Script for fafafa.core.process (Unix)
# - Uses lazbuild or fallback to fpc
# - Outputs to bin/ and lib/
# - Debug build with leak check

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
PROJECT="$SCRIPT_DIR/tests_process.lpi"
BIN_DIR="$SCRIPT_DIR/bin"
LIB_DIR="$SCRIPT_DIR/lib"
TEST_EXE="$BIN_DIR/tests"

# Ensure output directories
mkdir -p "$BIN_DIR"
mkdir -p "$LIB_DIR"

# Find lazbuild
LAZBUILD=""
for path in "/usr/bin/lazbuild" "/usr/local/bin/lazbuild" "$HOME/lazarus/lazbuild" "/opt/lazarus/lazbuild"; do
    if [ -f "$path" ]; then
        LAZBUILD="$path"
        break
    fi
done

# Build (prefer lazbuild; fallback to fpc)
echo "[1/2] Building project: $PROJECT ..."
if [ -n "$LAZBUILD" ]; then
    "$LAZBUILD" "$PROJECT"
    BUILD_RESULT=$?
else
    echo "WARNING: lazbuild not found, trying fpc directly..."
    fpc -Mobjfpc -Scghi -O1 -g -gl -l -vewnhibq -Fu"$ROOT_DIR/src" -FU"$LIB_DIR" -FE"$BIN_DIR" "$SCRIPT_DIR/tests_process.lpr"
    BUILD_RESULT=$?
fi

if [ $BUILD_RESULT -ne 0 ]; then
    echo
    echo "Build failed with error code $BUILD_RESULT."
    exit $BUILD_RESULT
fi

echo
echo "[OK] Build successful."
echo

# Set executable permission
if [ -f "$TEST_EXE" ]; then
    chmod +x "$TEST_EXE"
fi

# Run tests if requested
if [ "$1" = "test" ]; then
    if [ -f "$TEST_EXE" ]; then
        echo "[2/2] Running tests..."
        # Plain run (with progress); capture exit code
        "$TEST_EXE" --all --format=plain --progress
        TEST_RESULT=$?
        # Always produce JUnit report
        "$TEST_EXE" --all --format=junit --file="$BIN_DIR/tests.junit.xml" || true
        if [ $TEST_RESULT -ne 0 ]; then
            echo "=== Some tests failed with code $TEST_RESULT ==="
            exit $TEST_RESULT
        else
            echo "=== All tests passed ==="
            exit 0
        fi
    else
        echo "ERROR: Test executable not found: $TEST_EXE"
        exit 1
    fi
else
    echo "To run tests, call this script with the 'test' parameter."
fi

exit 0
