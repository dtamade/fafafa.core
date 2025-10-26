#!/bin/bash
# 简化基准测试构建脚本

echo "==========================================="
echo "集合性能基准测试 - 简化版"
echo "==========================================="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
BIN_DIR="$PROJECT_ROOT/bin"
EXECUTABLE="$BIN_DIR/simple_collections_benchmark"

mkdir -p "$BIN_DIR"

echo "编译基准测试..."
cd "$PROJECT_ROOT"

if ! /home/dtamade/freePascal/lazarus/lazbuild --build-mode=Debug "$SCRIPT_DIR/simple_benchmark.lpi"; then
    echo "编译失败!"
    exit 1
fi

echo
echo "运行基准测试..."
echo "==========================================="
"$EXECUTABLE"
echo "==========================================="
echo "基准测试完成!"
