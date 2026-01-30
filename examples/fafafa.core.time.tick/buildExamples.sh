#!/bin/bash

set -e

echo "========================================"
echo "fafafa.core.time.tick Examples Build Script"
echo "========================================"

mkdir -p bin lib

if command -v lazbuild &> /dev/null; then
  echo "Building example_basic_usage with lazbuild..."
  lazbuild --build-mode=Release example_basic_usage.lpi
else
  echo "lazbuild not found; trying fpc directly..."
  fpc -O2 -Fu../../src -FUlib -FEbin example_basic_usage.lpr
fi

echo ""
echo "All examples built successfully!"
echo "Built outputs:"
find bin -maxdepth 2 -type f -name 'example_basic_usage*' -print 2>/dev/null || true

