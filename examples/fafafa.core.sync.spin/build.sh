#!/bin/bash

echo "Building fafafa.core.sync.spin examples..."

SRC_DIR="../../src"
BIN_DIR="bin"
LIB_DIR="lib"

mkdir -p "$BIN_DIR"
mkdir -p "$LIB_DIR"

echo
echo "Building basic usage example..."
/home/dtamade/fpc/fpc/bin/x86_64-linux/fpc.sh -MObjFPC -Scaghi -Fu"$SRC_DIR" -FE"$BIN_DIR" -FU"$LIB_DIR" example_basic_usage.pas
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo
echo "Building performance benchmark..."
/home/dtamade/fpc/fpc/bin/x86_64-linux/fpc.sh -MObjFPC -Scaghi -Fu"$SRC_DIR" -FE"$BIN_DIR" -FU"$LIB_DIR" benchmark_performance.pas
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo
echo "Building use cases example..."
/home/dtamade/fpc/fpc/bin/x86_64-linux/fpc.sh -MObjFPC -Scaghi -Fu"$SRC_DIR" -FE"$BIN_DIR" -FU"$LIB_DIR" example_use_cases.pas
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo
echo "All examples built successfully!"
echo
echo "To run examples:"
echo "  ./$BIN_DIR/example_basic_usage"
echo "  ./$BIN_DIR/benchmark_performance"
echo "  ./$BIN_DIR/example_use_cases"
