#!/bin/bash

# 设置脚本在遇到错误时退出
set -e

echo "========================================"
echo "fafafa.core.collections.vecdeque 示例构建脚本"
echo "========================================"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
PROJECT_FILE="$SCRIPT_DIR/example_vecdeque.lpi"
OUTPUT_DIR="$PROJECT_ROOT/bin"
LIB_DIR="$SCRIPT_DIR/lib"

# 检查 lazbuild 是否可用
if ! command -v lazbuild &> /dev/null; then
    echo "错误: 找不到 lazbuild 命令"
    echo "请确保 Lazarus 已正确安装并添加到 PATH 环境变量中"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"
mkdir -p "$LIB_DIR"

echo ""
echo "正在编译示例项目..."
echo "项目文件: $PROJECT_FILE"
echo "输出目录: $OUTPUT_DIR"
echo ""

# 编译 Debug 版本
echo "[1/2] 编译 Debug 版本..."
if lazbuild --build-mode=Debug "$PROJECT_FILE"; then
    echo "✅ Debug 版本编译成功"
else
    echo ""
    echo "❌ Debug 版本编译失败！"
    exit 1
fi

# 编译 Release 版本
echo ""
echo "[2/2] 编译 Release 版本..."
if lazbuild --build-mode=Release "$PROJECT_FILE"; then
    echo "✅ Release 版本编译成功"
else
    echo ""
    echo "❌ Release 版本编译失败！"
    exit 1
fi

# 运行示例
echo ""
echo "========================================"
echo "运行示例程序"
echo "========================================"
echo ""

EXAMPLE_EXE="$OUTPUT_DIR/example_vecdeque"
if [ ! -f "$EXAMPLE_EXE" ]; then
    echo "错误: 找不到示例可执行文件 $EXAMPLE_EXE"
    exit 1
fi

echo "执行示例: $EXAMPLE_EXE"
echo ""

# 运行示例并捕获退出代码
set +e
"$EXAMPLE_EXE"
EXAMPLE_RESULT=$?
set -e

echo ""
echo "========================================"
if [ $EXAMPLE_RESULT -eq 0 ]; then
    echo "✅ 示例运行完成！"
else
    echo "❌ 示例运行出现错误！"
    echo "退出代码: $EXAMPLE_RESULT"
fi
echo "========================================"

exit $EXAMPLE_RESULT
