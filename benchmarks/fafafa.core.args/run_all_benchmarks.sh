#!/bin/bash

# fafafa.core.args 性能基准测试运行脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 创建结果目录
mkdir -p results
mkdir -p bin

echo "========================================"
echo "fafafa.core.args Performance Benchmarks"
echo "========================================"
echo "Started at: $(date)"
echo

# 编译所有基准测试
echo "🔨 Compiling benchmarks..."

BENCHMARKS=(
    "args_parsing_benchmark"
    "args_options_benchmark"
    "args_memory_benchmark"
    "args_command_benchmark"
    "args_config_merge_benchmark"
)

for benchmark in "${BENCHMARKS[@]}"; do
    echo "  Compiling $benchmark..."
    if command -v lazbuild >/dev/null 2>&1; then
        lazbuild --build-mode=Release --quiet "$benchmark.lpr" -o "bin/$benchmark"
    else
        fpc -O2 -S2 -MObjFPC -Fu../../src -FEbin -FUlib "$benchmark.lpr"
    fi
done

echo "✅ All benchmarks compiled successfully"
echo

# 运行基准测试
echo "🚀 Running benchmarks..."

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_FILE="results/benchmark_results_$TIMESTAMP.txt"

{
    echo "fafafa.core.args Performance Benchmark Results"
    echo "=============================================="
    echo "Timestamp: $(date)"
    echo "System: $(uname -a)"
    echo "FreePascal: $(fpc -iV 2>/dev/null || echo 'Unknown')"
    echo
} > "$RESULTS_FILE"

for benchmark in "${BENCHMARKS[@]}"; do
    echo "📊 Running $benchmark..."
    echo "----------------------------------------" >> "$RESULTS_FILE"
    echo "Running $benchmark" >> "$RESULTS_FILE"
    echo "----------------------------------------" >> "$RESULTS_FILE"
    
    if [ -f "bin/$benchmark" ]; then
        "./bin/$benchmark" | tee -a "$RESULTS_FILE"
    else
        echo "❌ $benchmark not found, skipping..."
        echo "ERROR: $benchmark not found" >> "$RESULTS_FILE"
    fi
    
    echo >> "$RESULTS_FILE"
done

echo
echo "✅ All benchmarks completed!"
echo "📄 Results saved to: $RESULTS_FILE"

# 生成简要摘要
echo
echo "📈 Performance Summary:"
echo "======================"

# 提取关键性能指标
if [ -f "$RESULTS_FILE" ]; then
    echo "Parsing Performance:"
    grep -E "(args/sec|parses/sec)" "$RESULTS_FILE" | head -5 | sed 's/^/  /'
    
    echo
    echo "Query Performance:"
    grep -E "(ops/sec|queries/sec)" "$RESULTS_FILE" | head -3 | sed 's/^/  /'
    
    echo
    echo "Command Routing:"
    grep -E "routes/sec" "$RESULTS_FILE" | head -3 | sed 's/^/  /'
fi

echo
echo "🎯 Benchmark run completed at: $(date)"
echo "📁 Check the results/ directory for detailed output"
