#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building Math operations benchmark..."
fpc -O3 -XX -Fi../../src -Fu../../src -FEbin -FUlib bench_math_operations.lpr

echo ""
echo "Running benchmark..."
./bin/bench_math_operations "$@"
