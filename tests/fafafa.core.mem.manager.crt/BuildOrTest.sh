#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 查找 lazbuild
LAZBUILD="${LAZBUILD:-lazbuild}"
if ! command -v "$LAZBUILD" &> /dev/null; then
    if [ -x "/opt/fpcupdeluxe/lazarus/lazbuild" ]; then
        LAZBUILD="/opt/fpcupdeluxe/lazarus/lazbuild --lazarusdir=/opt/fpcupdeluxe/lazarus"
    fi
fi

# 编译
echo "Building tests..."
$LAZBUILD *.lpi

# 运行测试
echo "Running tests..."
./bin/* --all --format=plain --progress
