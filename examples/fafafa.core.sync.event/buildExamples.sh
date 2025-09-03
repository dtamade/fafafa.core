#!/bin/bash

echo "========================================"
echo "fafafa.core.sync.event Examples Build Script"
echo "========================================"

# Create output directories
mkdir -p bin lib

# Check if lazbuild is available
if command -v lazbuild &> /dev/null; then
    echo "Using lazbuild..."
    USE_LAZBUILD=1
elif command -v fpc &> /dev/null; then
    echo "Using fpc directly..."
    USE_LAZBUILD=0
else
    echo "Error: Neither lazbuild nor fpc found!"
    exit 1
fi

echo "Building examples..."

# Build basic usage example
echo "Building example_basic_usage..."
if [ "$USE_LAZBUILD" = "1" ]; then
    lazbuild --build-mode=Release example_basic_usage.lpi
else
    fpc -O2 -Fu../../src -FUlib -FEbin example_basic_usage.lpr
fi

if [ $? -ne 0 ]; then
    echo "Failed to build example_basic_usage"
    exit 1
fi

# Build producer-consumer example
echo "Building example_producer_consumer..."
if [ "$USE_LAZBUILD" = "1" ]; then
    lazbuild --build-mode=Release example_producer_consumer.lpi
else
    fpc -O2 -Fu../../src -FUlib -FEbin example_producer_consumer.lpr
fi

if [ $? -ne 0 ]; then
    echo "Failed to build example_producer_consumer"
    exit 1
fi

# Build thread coordination example
echo "Building example_thread_coordination..."
if [ "$USE_LAZBUILD" = "1" ]; then
    lazbuild --build-mode=Release example_thread_coordination.lpi
else
    fpc -O2 -Fu../../src -FUlib -FEbin example_thread_coordination.lpr
fi

if [ $? -ne 0 ]; then
    echo "Failed to build example_thread_coordination"
    exit 1
fi

# Build auto vs manual example
echo "Building example_auto_vs_manual..."
if [ "$USE_LAZBUILD" = "1" ]; then
    lazbuild --build-mode=Release example_auto_vs_manual.lpi
else
    fpc -O2 -Fu../../src -FUlib -FEbin example_auto_vs_manual.lpr
fi

if [ $? -ne 0 ]; then
    echo "Failed to build example_auto_vs_manual"
    exit 1
fi

# Build timeout handling example
echo "Building example_timeout_handling..."
if [ "$USE_LAZBUILD" = "1" ]; then
    lazbuild --build-mode=Release example_timeout_handling.lpi
else
    fpc -O2 -Fu../../src -FUlib -FEbin example_timeout_handling.lpr
fi

if [ $? -ne 0 ]; then
    echo "Failed to build example_timeout_handling"
    exit 1
fi

# Set executable permissions
chmod +x bin/*

echo ""
echo "All examples built successfully!"
echo ""
echo "To run examples:"
echo "  ./bin/example_basic_usage"
echo "  ./bin/example_producer_consumer"
echo "  ./bin/example_thread_coordination"
echo "  ./bin/example_auto_vs_manual"
echo "  ./bin/example_timeout_handling"
echo ""
echo "Done!"
