#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LAZBUILD="../../tools/lazbuild.sh"

PROJECT="example_node.lpi"

EXAMPLE_EXECUTABLE="bin/example_node"

echo "Building project: $PROJECT..."
"$LAZBUILD" "$PROJECT"

if [ $? -ne 0 ]; then
    echo
    echo "Build failed with error code $?."
    exit 1
fi

echo
echo "Build successful."
echo

if [ "$1" = "run" ]; then
    echo "Running example..."
    "$EXAMPLE_EXECUTABLE"
else
    echo "To run the example, call this script with the 'run' parameter."
fi
