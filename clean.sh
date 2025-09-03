#!/bin/bash
# Clean script for fafafa.core project
# Removes all .o and .ppu files from the project directory

echo "Cleaning fafafa.core project..."
echo

# Clean .o and .ppu files with verbose output
echo "Removing .o and .ppu files..."
find . -name "*.o" -o -name "*.ppu" -print -delete

echo
echo "Cleanup completed!"

# Check for remaining files
echo "Checking for remaining files..."
remaining=$(find . -name "*.o" -o -name "*.ppu" | wc -l)

if [ "$remaining" -eq 0 ]; then
    echo "All compilation artifacts have been successfully removed."
else
    echo "Warning: Found $remaining remaining .o/.ppu files."
    find . -name "*.o" -o -name "*.ppu"
fi

echo
echo "Press Enter to continue..."
read -r
