#!/bin/bash

echo "Building fafafa.core.sync.spin tests for Linux..."

# Create output directories
mkdir -p bin lib

# Try lazbuild first
if command -v lazbuild &> /dev/null; then
    echo "Using lazbuild..."
    lazbuild --build-mode=Debug fafafa.core.sync.spin.test.lpi
    if [ $? -eq 0 ]; then
        echo "Build successful!"
        if [ -f "bin/fafafa.core.sync.spin.test" ]; then
            echo "Executable: bin/fafafa.core.sync.spin.test"
            chmod +x bin/fafafa.core.sync.spin.test
        fi
        exit 0
    else
        echo "lazbuild failed, trying fpc..."
    fi
fi

# Fallback to fpc
if command -v fpc &> /dev/null; then
    echo "Using fpc directly..."
    fpc -Fu../../src -Fu../ -FUlib -obin/fafafa.core.sync.spin.test fafafa.core.sync.spin.test.lpr
    if [ $? -eq 0 ]; then
        echo "Build successful!"
        chmod +x bin/fafafa.core.sync.spin.test
        echo "Executable: bin/fafafa.core.sync.spin.test"
    else
        echo "Build failed!"
        exit 1
    fi
else
    echo "Error: Neither lazbuild nor fpc found!"
    exit 1
fi
