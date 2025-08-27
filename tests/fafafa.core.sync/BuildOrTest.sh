#!/bin/bash

echo "========================================"
echo "fafafa.core.sync 测试构建脚本"
echo "========================================"

PROJECT_NAME="tests_sync"
PROJECT_FILE="${PROJECT_NAME}.lpi"
OUTPUT_DIR="../../bin"
OUTPUT_FILE="${OUTPUT_DIR}/${PROJECT_NAME}"

# 检查 lazbuild 是否可用
if ! command -v lazbuild &> /dev/null; then
    echo "错误: 找不到 lazbuild 命令"
    echo "请确保 Lazarus 已正确安装并添加到 PATH 环境变量中"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 清理之前的构建
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
fi

echo ""
echo "正在构建测试项目..."
echo "项目文件: $PROJECT_FILE"
echo "输出文件: $OUTPUT_FILE"
echo ""

# 构建 Debug 版本
lazbuild --build-mode=Debug "$PROJECT_FILE"
if [ $? -ne 0 ]; then
    echo ""
    echo "构建失败！"
    exit 1
fi

echo ""
echo "构建成功！"

# 检查是否要运行测试
if [ "$1" = "test" ] || [ "$1" = "run" ]; then
    echo ""
    echo "========================================"
    echo "运行测试..."
    echo "========================================"
    echo ""
    
    if [ ! -f "$OUTPUT_FILE" ]; then
        echo "错误: 找不到可执行文件 $OUTPUT_FILE"
        exit 1
    fi
    
    # 运行测试
    "$OUTPUT_FILE"
    TEST_RESULT=$?
    
    echo ""
    echo "========================================"
    if [ $TEST_RESULT -eq 0 ]; then
        echo "所有测试通过！"
    else
        echo "测试失败，退出代码: $TEST_RESULT"
    fi
    echo "========================================"
    
    exit $TEST_RESULT
else
    echo ""
    echo "使用方法:"
    echo "  $0          - 仅构建"
    echo "  $0 test     - 构建并运行测试"
    echo "  $0 run      - 构建并运行测试"
    echo ""
fi
