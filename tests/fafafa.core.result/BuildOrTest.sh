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

# 运行测试 - 排除 .dbg 文件
echo "Running tests..."
for exe in ./bin/*; do
    if [[ -x "$exe" && ! "$exe" == *.dbg ]]; then
        echo "[RUN] $exe --all --format=plain"
        "$exe" --all --format=plain || exit 1
    fi
done
