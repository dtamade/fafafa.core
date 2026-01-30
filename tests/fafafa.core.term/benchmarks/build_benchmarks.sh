#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="../../../bin"
SRC_DIR="../../../src"

echo "Building fafafa.core.term benchmarks..."
echo "====================================="

echo
echo "Building benchmark_term.lpr..."
fpc -Fu$SRC_DIR -FE$BIN_DIR -FU../../../lib benchmark_term.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for benchmark_term.lpr"
    exit 1
fi

echo
echo "Building performance_analyzer.lpr..."
fpc -Fu$SRC_DIR -FE$BIN_DIR -FU../../../lib performance_analyzer.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for performance_analyzer.lpr"
    exit 1
fi

echo
echo "All benchmarks built successfully!"
echo
echo "Available executables in $BIN_DIR:"
echo "  - benchmark_term         (Basic performance benchmarks)"
echo "  - performance_analyzer   (Detailed performance analysis)"
echo
echo "Usage:"
echo "  $BIN_DIR/benchmark_term"
echo "  $BIN_DIR/performance_analyzer"
echo
