#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LAZBUILD="../../tools/lazbuild.sh"

PROJECT="example_lockfree.lpi"
BENCH_PROJECT="bench_map_str_key.lpi"
STRICT_EXAMPLE="example_oa_strict_factories.lpr"

EXAMPLE_EXECUTABLE="bin/example_lockfree"
BENCH_EXECUTABLE="bin/bench_map_str_key"
STRICT_EXE="bin/example_oa_strict_factories"

echo "Building project: $PROJECT..."
"$LAZBUILD" "$PROJECT"

echo

echo "Building bench project: $BENCH_PROJECT..."
"$LAZBUILD" "$BENCH_PROJECT"

# Build strict factories example (no .lpi)
echo
FPC=fpc
FPC_FLAGS=(-Fu"$SCRIPT_DIR/../../src" -FE"$SCRIPT_DIR/../../bin")

echo "Building strict factories example: $STRICT_EXAMPLE ..."
$FPC ${FPC_FLAGS[@]} "$STRICT_EXAMPLE"
if [ $? -ne 0 ]; then
    echo
    echo "Build strict example failed."
    exit 1
fi




echo
echo "Build successful."
echo

if [ "$1" = "run" ]; then
    echo "Running example..."
    "$EXAMPLE_EXECUTABLE"
    echo
    echo "Running bench..."
    "$BENCH_EXECUTABLE"
    echo
    echo "Running strict factories example..."
    "$STRICT_EXE"
else
    echo "To run example, bench, and strict example, call this script with the 'run' parameter."
fi

    echo "Running example..."
    "$EXAMPLE_EXECUTABLE"
else
    echo "To run example, call this script with the 'run' parameter."
fi
