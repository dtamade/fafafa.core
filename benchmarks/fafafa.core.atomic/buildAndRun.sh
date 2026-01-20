#!/bin/bash

# fafafa.core.atomic 基准测试构建和运行脚本 (Linux/macOS)

set -e

echo "=== fafafa.core.atomic 基准测试构建脚本 ==="
echo

# 设置路径
BENCHMARK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$BENCHMARK_DIR/../.."
SRC_DIR="$PROJECT_ROOT/src"
UTILS_DIR="$BENCHMARK_DIR/utils"
RESULTS_DIR="$BENCHMARK_DIR/results"

# 创建结果目录
mkdir -p "$RESULTS_DIR"

# 设置编译器参数
FPC_PARAMS="-Mobjfpc -Sh -O2 -g -gl -Ci -Co -Cr -Ct"
FPC_UNITS="-Fu$SRC_DIR -Fu$UTILS_DIR"
FPC_OUTPUT="-FE$BENCHMARK_DIR -FU$BENCHMARK_DIR/lib"

# 创建 lib 目录
mkdir -p "$BENCHMARK_DIR/lib"

echo "编译基础原子操作基准测试..."
fpc $FPC_PARAMS $FPC_UNITS $FPC_OUTPUT "$BENCHMARK_DIR/bench_atomic_basic.lpr"

echo "编译成功！"
echo

echo "运行基础原子操作基准测试..."
echo
"$BENCHMARK_DIR/bench_atomic_basic"

echo
echo "基准测试完成！"
echo "结果文件位于: $RESULTS_DIR"
echo

# 显示结果文件
if [ -f "$RESULTS_DIR/basic_atomic_results.json" ]; then
    echo "JSON 结果文件:"
    cat "$RESULTS_DIR/basic_atomic_results.json"
    echo
fi

if [ -f "$RESULTS_DIR/basic_atomic_results.csv" ]; then
    echo "CSV 结果文件:"
    cat "$RESULTS_DIR/basic_atomic_results.csv"
    echo
fi
