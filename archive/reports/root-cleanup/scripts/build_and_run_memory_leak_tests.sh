#!/bin/bash
# Build and run memory leak tests

echo "======================================"
echo "fafafa.core Memory Leak Tests"
echo "======================================"
echo

# Find lazbuild
LAZBUILD="/home/dtamade/freePascal/lazarus/lazbuild"

# Create bin directory if not exists
mkdir -p bin

# List of tests to compile
TESTS=(
    "test_hashset_leak"
    "test_vec_leak"
    "test_vecdeque_leak"
    "test_list_leak"
    "test_priorityqueue_leak"
)

# Compile and run each test
for TEST in "${TESTS[@]}"; do
    echo "========================================"
    echo "Compiling $TEST..."
    echo "========================================"

    LPI_FILE="tests/${TEST}.lpi"

    if [ -f "$LPI_FILE" ]; then
        if $LAZBUILD "$LPI_FILE" --build-mode=Debug --quiet 2>&1; then
            echo "✓ Compilation successful"

            # Run the test
            echo
            echo "Running $TEST..."
            echo "========================================"
            ./bin/$TEST
            echo
            echo "========================================"
            echo "Completed: $TEST"
            echo "========================================"
            echo
        else
            echo "✗ Compilation failed for $TEST"
            echo
        fi
    else
        echo "✗ LPI file not found: $LPI_FILE"
        echo
    fi
done

echo "======================================"
echo "All tests completed!"
echo "======================================"
