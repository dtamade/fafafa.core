#!/bin/bash
echo "Building fafafa.core.os system info example..."
lazbuild example_system_info.lpi
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi
echo "Build successful!"
echo
echo "Running example..."
echo
./bin/example_system_info
echo
echo "Example completed."
