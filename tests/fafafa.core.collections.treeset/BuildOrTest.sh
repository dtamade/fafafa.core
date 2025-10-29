#!/bin/bash

echo "========================================"
echo "fafafa.core.collections.treeset Test Build Script"
echo "========================================"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
TEST_DIR="$SCRIPT_DIR"
BIN_DIR="$PROJECT_ROOT/bin"
PROJECT_FILE="$TEST_DIR/tests_treeset.lpi"
EXECUTABLE="$BIN_DIR/tests_treeset"

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
        echo "Warning: Build successful but executable not found"
        return 1
    fi
}

run_test() {
    if [ ! -f "$EXECUTABLE" ]; then
        echo "Executable not found, please build first"
        echo "    File path: $EXECUTABLE"
        return 1
    fi
    
    echo "Running tests: $EXECUTABLE"
    cd "$PROJECT_ROOT"
    "$EXECUTABLE" --all --format=plain --progress
    if [ $? -ne 0 ]; then
        echo
        echo "Tests failed!"
        return 1
    else
        echo
        echo "All tests passed!"
        return 0
    fi
}

clean_only() {
    echo "Cleaning build files..."
    if [ -d "$TEST_DIR/lib" ]; then
        rm -rf "$TEST_DIR/lib"
        echo "    Deleted: $TEST_DIR/lib"
    fi
    if [ -f "$EXECUTABLE" ]; then
        rm -f "$EXECUTABLE"
        echo "    Deleted: $EXECUTABLE"
    fi
    echo "Clean completed"
    return 0
}

show_help() {
    echo
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  build    Build project only"
    echo "  test     Run tests only (requires build first)"
    echo "  clean    Clean build files"
    echo "  (no args) Build and run tests"
    echo
    echo "Examples:"
    echo "  $0           # Build and run tests"
    echo "  $0 build     # Build only"
    echo "  $0 test      # Run tests only"
    echo "  $0 clean     # Clean files"
    echo
    return 0
}

case "$1" in
    "test")
        run_test
        exit $?
        ;;
    "build")
        echo "Building test project only..."
        build_project
        exit $?
        ;;
    "clean")
        clean_only
        exit $?
        ;;
    "help"|"-h"|"--help")
        show_help
        exit 0
        ;;
    "")
        echo "Building test project..."
        build_project
        if [ $? -ne 0 ]; then
            echo "Build failed!"
            exit 1
        fi
        
        echo
        echo "Running tests..."
        run_test
        exit $?
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

