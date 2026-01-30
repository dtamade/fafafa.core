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
rm -rf "${SCRIPT_DIR}/bin" "${SCRIPT_DIR}/lib"
mkdir -p "${SCRIPT_DIR}/bin" "${SCRIPT_DIR}/lib"

if ! $LAZBUILD *.lpi; then
    # lazbuild 在某些最小配置环境下会在成功编译后返回非 0（例如输出 "File not found: \"\""），
    # 这里以生成的可执行文件是否存在作为最终判定，避免阻断测试执行。
    if ! ls -1 "${SCRIPT_DIR}/bin/"* >/dev/null 2>&1; then
        echo "Build failed."
        exit 1
    fi
fi

# 运行测试
echo "Running tests..."
for exe in "${SCRIPT_DIR}/bin/"*; do
    if [[ -f "$exe" && -x "$exe" && "$exe" != *.dbg ]]; then
        "$exe" --all --format=plain
    fi
done
