#!/bin/bash
# Build and run BitSet tests
set -e

cd "$(dirname "$0")"

mkdir -p bin lib

if command -v lazbuild >/dev/null 2>&1; then
  lazbuild -B tests_bitset.lpi --build-mode=Debug
  echo "Running BitSet tests..."
  ./bin/tests_bitset || true
else
  echo "lazbuild not found. Please install Lazarus or add fpcunit path manually."
  exit 1
fi

