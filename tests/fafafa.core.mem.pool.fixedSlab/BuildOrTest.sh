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

# 说明：
# - 该目录下的 .lpi 历史上包含固定 TargetOS（例如 win64），在 Linux/macOS 上需要显式覆盖为宿主 OS。
# - 该测试为 smoke test 程序（非 FPCUnit），输出目录位于 build/tests。
HOST_OS="$(uname -s)"
case "$HOST_OS" in
    Linux) TARGET_OS="linux" ;;
    Darwin) TARGET_OS="darwin" ;;
    *) TARGET_OS="linux" ;;
esac

rm -rf "${SCRIPT_DIR}/build/units" "${SCRIPT_DIR}/build/tests"
mkdir -p "${SCRIPT_DIR}/build/units" "${SCRIPT_DIR}/build/tests"

if ! $LAZBUILD --os="$TARGET_OS" fixed_slab_smoke_test.lpi; then
    # lazbuild 在某些最小配置环境下会在成功编译后返回非 0（例如输出 "File not found: \"\""），
    # 这里以生成的可执行文件是否存在作为最终判定，避免阻断测试执行。
    if [ ! -x "${SCRIPT_DIR}/build/tests/fixed_slab_smoke_test" ]; then
        echo "Build failed."
        exit 1
    fi
fi

# 运行测试
echo "Running tests..."
"${SCRIPT_DIR}/build/tests/fixed_slab_smoke_test"
