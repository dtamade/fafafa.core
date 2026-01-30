#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building Result operations benchmark..."
fpc -O3 -XX -Fi../../src -Fu../../src -FEbin -FUlib bench_result_operations.lpr

echo ""
echo "Running benchmark..."
./bin/bench_result_operations "$@"
