#!/bin/bash

# ===================================================================
# fafafa.core.process 示例项目构建脚本 (Linux)
# ===================================================================
#
# 功能：
# - 支持 Debug 和 Release 两种构建模式
# - 自动检测 Lazarus 安装路径
# - 输出详细的构建信息
# - 错误处理和状态报告
#
# 使用方法：
#   ./build.sh [debug|release]
#
# 示例：
#   ./build.sh          # 默认 Debug 模式
#   ./build.sh debug    # Debug 模式
#   ./build.sh release  # Release 模式
#
# ===================================================================

echo
echo "==================================================================="
echo "fafafa.core.process 示例项目构建脚本"
echo "==================================================================="

# 设置脚本目录和项目路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="$SCRIPT_DIR/example_process.lpi"
OUTPUT_DIR="$SCRIPT_DIR/../../bin"
LIB_DIR="$SCRIPT_DIR/lib"

# 检测构建模式
BUILD_MODE="Debug"
if [ "$1" = "release" ]; then
    BUILD_MODE="Release"
elif [ "$1" = "debug" ]; then
    BUILD_MODE="Debug"
fi

echo "构建模式: $BUILD_MODE"
echo "项目文件: $PROJECT_FILE"
echo "输出目录: $OUTPUT_DIR"
echo

# 检测 Lazarus 安装路径
LAZBUILD=""
if [ -f "/usr/bin/lazbuild" ]; then
    LAZBUILD="/usr/bin/lazbuild"
elif [ -f "/usr/local/bin/lazbuild" ]; then
    LAZBUILD="/usr/local/bin/lazbuild"
elif [ -f "$HOME/lazarus/lazbuild" ]; then
    LAZBUILD="$HOME/lazarus/lazbuild"
elif [ -f "/opt/lazarus/lazbuild" ]; then
    LAZBUILD="/opt/lazarus/lazbuild"
else
    echo "❌ 错误: 找不到 lazbuild"
    echo
    echo "请确保 Lazarus 已正确安装，或修改此脚本中的路径设置。"
    echo "支持的默认路径："
    echo "  - /usr/bin/lazbuild"
    echo "  - /usr/local/bin/lazbuild"
    echo "  - $HOME/lazarus/lazbuild"
    echo "  - /opt/lazarus/lazbuild"
    echo
    echo "您也可以通过以下方式安装 Lazarus："
    echo "  Ubuntu/Debian: sudo apt-get install lazarus"
    echo "  CentOS/RHEL:   sudo yum install lazarus"
    echo "  Arch Linux:    sudo pacman -S lazarus"
    echo
    exit 1
fi

echo "✓ 找到 Lazarus 构建工具: $LAZBUILD"

# 检查项目文件是否存在
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ 错误: 找不到项目文件 $PROJECT_FILE"
    exit 1
fi

# 创建输出目录
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "✓ 创建输出目录: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
fi

# 清理之前的构建产物（可选）
if [ -d "$LIB_DIR" ]; then
    echo "✓ 清理之前的构建产物..."
    rm -rf "$LIB_DIR"
fi

echo
echo "==================================================================="
echo "开始构建..."
echo "==================================================================="

# 执行构建
echo "执行命令: $LAZBUILD --build-mode=$BUILD_MODE $PROJECT_FILE"
"$LAZBUILD" --build-mode="$BUILD_MODE" "$PROJECT_FILE"

# 检查构建结果
if [ $? -ne 0 ]; then
    echo
    echo "❌ 构建失败！错误代码: $?"
    echo
    echo "可能的原因："
    echo "  - 源代码编译错误"
    echo "  - 依赖模块缺失"
    echo "  - 路径配置问题"
    echo "  - FreePascal 编译器未正确安装"
    echo
    echo "请检查上面的错误信息并修正问题后重试。"
    echo
    echo "==================================================================="
    echo "构建失败"
    echo "==================================================================="
    exit 1
fi

echo
echo "==================================================================="
echo "构建成功！"
echo "==================================================================="

# 检查输出文件
EXECUTABLE_NAME="example_process"
EXECUTABLE_PATH="$OUTPUT_DIR/$EXECUTABLE_NAME"

if [ -f "$EXECUTABLE_PATH" ]; then
    echo "✓ 可执行文件已生成: $EXECUTABLE_PATH"

    # 显示文件信息
    FILE_SIZE=$(stat -c%s "$EXECUTABLE_PATH" 2>/dev/null || stat -f%z "$EXECUTABLE_PATH" 2>/dev/null)
    FILE_TIME=$(stat -c%y "$EXECUTABLE_PATH" 2>/dev/null || stat -f%Sm "$EXECUTABLE_PATH" 2>/dev/null)

    echo "✓ 文件大小: $FILE_SIZE 字节"
    echo "✓ 修改时间: $FILE_TIME"

    # 设置执行权限
    chmod +x "$EXECUTABLE_PATH"
    echo "✓ 已设置执行权限"

    echo
    echo "运行示例："
    echo "  cd $OUTPUT_DIR"
    echo "  ./$EXECUTABLE_NAME"
    echo
    echo "或者使用运行脚本："
    echo "  ./run.sh"

else
    echo "❌ 警告: 找不到生成的可执行文件 $EXECUTABLE_PATH"
    echo "构建可能未完全成功，请检查构建日志。"

# === 可选示例：AutoDrain ===
echo
echo "[INFO] 构建可选示例（AutoDrain）..."
if [[ -x "$SCRIPT_DIR/run_autodrain.sh" ]]; then
  bash "$SCRIPT_DIR/run_autodrain.sh" || true
else
  # 直接尝试构建该单例
  fpc -MObjFPC -Scaghi -O1 -gw3 -gl -gh -Xg -gt -vewnhibq \
    -dFAFAFA_PROCESS_GROUPS \
    -Fi"$SCRIPT_DIR/lib" -Fi"$SCRIPT_DIR/../../src" -Fu"$SCRIPT_DIR/../../src" \
    -FU"$SCRIPT_DIR/lib" -FE"$SCRIPT_DIR/bin" -o"$SCRIPT_DIR/bin/example_autodrain" \
    "$SCRIPT_DIR/example_autodrain.lpr" || true
fi

fi

echo
echo "==================================================================="
echo "构建完成"
echo "==================================================================="
echo
