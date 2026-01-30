#!/bin/bash
# fafafa.core.id Benchmark Build and Run Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FPC="/home/dtamade/freePascal/fpc/bin/x86_64-linux/fpc"

cd "$SCRIPT_DIR"

echo "========================================"
echo "fafafa.core.id Performance Benchmark"
echo "========================================"
echo

# Compile with optimizations
echo "Compiling with -O3 optimizations..."
$FPC -O3 -XX \
    -Fi/home/dtamade/freePascal/fpc/units/x86_64-linux/rtl \
    -Fu/home/dtamade/freePascal/fpc/units/x86_64-linux/rtl \
    -Fu/home/dtamade/freePascal/fpc/units/x86_64-linux/rtl-objpas \
    -Fu/home/dtamade/freePascal/fpc/units/x86_64-linux/fcl-base \
    -Fu/home/dtamade/freePascal/fpc/units/x86_64-linux/pthreads \
    -Fu/home/dtamade/freePascal/fpc/units/x86_64-linux/regexpr \
    -Fi"$ROOT_DIR/src" \
    -Fu"$ROOT_DIR/src" \
    -FE"$SCRIPT_DIR/bin" \
    -FU"$SCRIPT_DIR/bin" \
    bench_id_generation.lpr

if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

echo
echo "Running benchmark..."
echo

cd "$SCRIPT_DIR"
./bin/bench_id_generation

echo
echo "Done!"
