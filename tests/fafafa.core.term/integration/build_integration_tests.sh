#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="../../../bin"
SRC_DIR="../../../src"

echo "Building fafafa.core.term integration tests..."
echo "============================================="

echo
echo "Building terminal_compatibility_test.lpr..."
fpc -Fu$SRC_DIR -FE$BIN_DIR -FU../../../lib terminal_compatibility_test.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for terminal_compatibility_test.lpr"
    exit 1
fi

echo
echo "Building interactive_test.lpr..."
fpc -Fu$SRC_DIR -FE$BIN_DIR -FU../../../lib interactive_test.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for interactive_test.lpr"
    exit 1
fi

echo
echo "All integration tests built successfully!"
echo
echo "Available executables in $BIN_DIR:"
echo "  - terminal_compatibility_test  (Automated compatibility testing)"
echo "  - interactive_test             (Interactive feature testing)"
echo
echo "Usage:"
echo "  $BIN_DIR/terminal_compatibility_test"
echo "  $BIN_DIR/interactive_test"
echo
echo "Note: These tests should be run in different terminal environments"
echo "      to verify cross-platform compatibility:"
echo "  - xterm"
echo "  - gnome-terminal"
echo "  - konsole"
echo "  - kitty"
echo "  - alacritty"
echo "  - iTerm2 (macOS)"
echo "  - Terminal.app (macOS)"
echo "  - tmux/screen sessions"
echo
