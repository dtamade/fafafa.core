#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building Option operations benchmark..."
fpc -O3 -XX -Fi../../src -Fu../../src -FEbin -FUlib bench_option_operations.lpr

echo ""
echo "Running benchmark..."
./bin/bench_option_operations "$@"
