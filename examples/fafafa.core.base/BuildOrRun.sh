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
echo "Building examples..."
$LAZBUILD *.lpi

# 运行示例
echo "Running examples..."
for exe in ./bin/*; do
    if [ -x "$exe" ] && [ -f "$exe" ]; then
        echo "=== Running $(basename "$exe") ==="
        "$exe"
        echo ""
    fi
done
