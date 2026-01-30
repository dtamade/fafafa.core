#!/bin/bash

# ===================================================================
# fafafa.core.process 示例程序运行脚本 (Linux)
# ===================================================================
#
# 功能：
# - 自动检查可执行文件是否存在
# - 如果不存在则自动构建
# - 运行示例程序并显示结果
# - 错误处理和状态报告
#
# 使用方法：
#   ./run.sh [debug|release]
#
# 示例：
#   ./run.sh          # 运行默认版本
#   ./run.sh debug    # 运行 Debug 版本
#   ./run.sh release  # 运行 Release 版本
#
# ===================================================================

echo
echo "==================================================================="
echo "fafafa.core.process 示例程序运行脚本"
echo "==================================================================="

# 设置路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../../bin"
EXECUTABLE_NAME="example_process"
EXECUTABLE_PATH="$OUTPUT_DIR/$EXECUTABLE_NAME"

# 检测构建模式
BUILD_MODE="debug"
if [ "$1" = "release" ]; then
    BUILD_MODE="release"
elif [ "$1" = "debug" ]; then
    BUILD_MODE="debug"
fi

echo "目标可执行文件: $EXECUTABLE_PATH"
echo "构建模式: $BUILD_MODE"
echo

# 检查可执行文件是否存在
if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo "⚠ 可执行文件不存在，开始自动构建..."
    echo

    # 调用构建脚本
    "$SCRIPT_DIR/build.sh" "$BUILD_MODE"

    if [ $? -ne 0 ]; then
        echo "❌ 构建失败，无法运行示例程序"
        echo
        echo "==================================================================="
        echo "运行失败"
        echo "==================================================================="
        exit 1
    fi

    echo
    echo "✓ 构建完成，继续运行..."
    echo
fi

# 再次检查可执行文件
if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo "❌ 错误: 找不到可执行文件 $EXECUTABLE_PATH"
    echo
    echo "请确保："
    echo "  1. 项目已正确构建"
    echo "  2. 构建输出目录正确"
    echo "  3. 没有构建错误"
    echo "  4. FreePascal 编译器已正确安装"
    echo
    echo "==================================================================="
    echo "运行失败"
    echo "==================================================================="
    exit 1
fi

# 确保可执行文件有执行权限
chmod +x "$EXECUTABLE_PATH"

echo "==================================================================="
echo "运行 fafafa.core.process 示例程序"
echo "==================================================================="
echo

# 切换到输出目录并运行程序
cd "$OUTPUT_DIR"
./"$EXECUTABLE_NAME"
RUN_RESULT=$?

echo
echo "==================================================================="

if [ $RUN_RESULT -eq 0 ]; then
    echo "✓ 示例程序运行成功！"
else
    echo "❌ 示例程序运行失败，退出码: $RUN_RESULT"
fi


# === 可选：运行 AutoDrain 示例 ===
echo

# === 可选：Combined vs CaptureAll 示例 ===
echo
echo "[INFO] 你可以运行 Combined vs CaptureAll 示例："
echo "  ./run_combined_vs_capture_all.sh"

echo "[INFO] 你可以运行 AutoDrain 示例："
echo "  ./run_autodrain.sh"

echo "==================================================================="
echo
