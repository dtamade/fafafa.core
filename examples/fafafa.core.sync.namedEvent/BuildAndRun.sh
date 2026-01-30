#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo "fafafa.core.sync.namedEvent Examples"
echo "========================================"

FAILED_BUILDS=0
TOTAL_BUILDS=0

echo
echo "[INFO] 编译所有示例程序..."

# 编译基本使用示例
echo "[INFO] 编译基本使用示例..."
TOTAL_BUILDS=$((TOTAL_BUILDS + 1))
if fpc -Mobjfpc -Sh -Fu../../src example_basic_usage.lpr; then
    echo "[SUCCESS] 基本使用示例编译成功"
else
    echo "[ERROR] 基本使用示例编译失败"
    FAILED_BUILDS=$((FAILED_BUILDS + 1))
fi

# 编译跨进程生产者
echo "[INFO] 编译跨进程生产者..."
TOTAL_BUILDS=$((TOTAL_BUILDS + 1))
if fpc -Mobjfpc -Sh -Fu../../src example_crossprocess_producer.lpr; then
    echo "[SUCCESS] 跨进程生产者编译成功"
else
    echo "[ERROR] 跨进程生产者编译失败"
    FAILED_BUILDS=$((FAILED_BUILDS + 1))
fi

# 编译跨进程消费者
echo "[INFO] 编译跨进程消费者..."
TOTAL_BUILDS=$((TOTAL_BUILDS + 1))
if fpc -Mobjfpc -Sh -Fu../../src example_crossprocess_consumer.lpr; then
    echo "[SUCCESS] 跨进程消费者编译成功"
else
    echo "[ERROR] 跨进程消费者编译失败"
    FAILED_BUILDS=$((FAILED_BUILDS + 1))
fi

# 编译多线程示例
echo "[INFO] 编译多线程示例..."
TOTAL_BUILDS=$((TOTAL_BUILDS + 1))
if fpc -Mobjfpc -Sh -Fu../../src example_multithreading.lpr; then
    echo "[SUCCESS] 多线程示例编译成功"
else
    echo "[ERROR] 多线程示例编译失败"
    FAILED_BUILDS=$((FAILED_BUILDS + 1))
fi

SUCCESS_BUILDS=$((TOTAL_BUILDS - FAILED_BUILDS))

echo
echo "========================================"
echo "编译结果汇总"
echo "========================================"
echo "总示例数: $TOTAL_BUILDS"
echo "编译成功: $SUCCESS_BUILDS"
echo "编译失败: $FAILED_BUILDS"

if [ $FAILED_BUILDS -eq 0 ]; then
    echo
    echo "🎉 所有示例编译成功！"
    echo
    echo "运行示例:"
    echo "  基本使用: ./example_basic_usage"
    echo "  多线程:   ./example_multithreading"
    echo "  跨进程:   先运行 ./example_crossprocess_consumer"
    echo "           再运行 ./example_crossprocess_producer"
    echo
    
    # 询问是否运行基本示例
    read -p "是否运行基本使用示例? (y/n): " RUN_BASIC
    if [[ "$RUN_BASIC" =~ ^[Yy]$ ]]; then
        echo
        echo "[INFO] 运行基本使用示例..."
        echo "========================================"
        ./example_basic_usage
        echo "========================================"
    fi
    
    exit 0
else
    echo
    echo "❌ 有 $FAILED_BUILDS 个示例编译失败，请检查错误信息"
    exit 1
fi
