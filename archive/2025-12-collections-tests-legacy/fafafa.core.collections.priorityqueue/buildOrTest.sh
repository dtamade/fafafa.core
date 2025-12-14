#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔨 Building PriorityQueue tests..."
lazbuild --build-mode=Default runner_priorityqueue.lpi

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "🧪 Running tests..."
    echo "================================================"
    ./runner_priorityqueue --all --format=plain
    TEST_RESULT=$?
    echo "================================================"
    
    if [ $TEST_RESULT -eq 0 ]; then
        echo "✅ All tests passed!"
    else
        echo "❌ Some tests failed!"
        exit 1
    fi
else
    echo "❌ Build failed!"
    exit 1
fi
