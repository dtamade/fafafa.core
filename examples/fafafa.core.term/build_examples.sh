#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAZBUILD="../../tools/lazbuild.sh"
BIN_DIR="bin"

echo "Building fafafa.core.term examples..."
echo "===================================="

echo
echo "Building example_term.lpi..."
"$LAZBUILD" "example_term.lpi"
if [ $? -ne 0 ]; then
    echo "Build failed for example_term.lpi"
    exit 1
fi

echo
echo "Building basic_example.lpr..."
fpc -Fu../../src -FE$BIN_DIR -FU../../lib basic_example.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for basic_example.lpr"
    exit 1
fi

echo
echo "Building keyboard_example.lpr..."
fpc -Fu../../src -FE$BIN_DIR -FU../../lib keyboard_example.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for keyboard_example.lpr"
    exit 1
fi

echo
echo "Building text_editor.lpr..."
fpc -Fu../../src -FE$BIN_DIR -FU../../lib text_editor.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for text_editor.lpr"
    exit 1
fi

echo
echo "Building progress_demo.lpr..."
fpc -Fu../../src -FE$BIN_DIR -FU../../lib progress_demo.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for progress_demo.lpr"
    exit 1
fi

echo
echo "Building menu_system.lpr..."
fpc -Fu../../src -FE$BIN_DIR -FU../../lib menu_system.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for menu_system.lpr"
    exit 1
fi

echo
echo "Building theme_demo.lpr..."
fpc -Fu../../src -FE$BIN_DIR -FU../../lib theme_demo.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for theme_demo.lpr"
    exit 1
fi

echo
echo "Building layout_demo.lpr..."
fpc -Fu../../src -FE$BIN_DIR -FU../../lib layout_demo.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for layout_demo.lpr"
    exit 1
fi

echo
echo "Building unicode_demo.lpr..."
fpc -Fu../../src -FE$BIN_DIR -FU../../lib unicode_demo.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for unicode_demo.lpr"
    exit 1
fi

echo
echo "Building recorder_demo.lpr..."
fpc -Fu../../src -FE$BIN_DIR -FU../../lib recorder_demo.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for recorder_demo.lpr"
    exit 1
fi

echo
echo "Building widgets_demo.lpr..."
fpc -Fu../../src -FE$BIN_DIR -FU../../lib widgets_demo.lpr
if [ $? -ne 0 ]; then
    echo "Build failed for widgets_demo.lpr"
    exit 1
fi

echo
echo "All examples built successfully!"
echo
echo "Available executables in $BIN_DIR:"
echo "  - example_term         (Complete feature demonstration)"
echo "  - basic_example        (Basic terminal control)"
echo "  - keyboard_example     (Keyboard input handling)"
echo "  - text_editor          (Simple text editor)"
echo "  - progress_demo        (Progress bars and spinners)"
echo "  - menu_system          (Interactive menu system)"
echo "  - theme_demo           (Theme system demonstration)"
echo "  - layout_demo          (Layout system demonstration)"
echo "  - unicode_demo         (Unicode support demonstration)"
echo "  - recorder_demo        (Recording and playback demonstration)"
echo "  - widgets_demo         (Terminal widgets demonstration)"
echo
