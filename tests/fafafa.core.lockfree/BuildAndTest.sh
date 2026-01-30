#!/bin/bash

# fafafa.core.lockfree 完整构建和测试脚本
# 用法: ./BuildAndTest.sh [clean|test|benchmark|all]

set -e  # 遇到错误立即退出

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
SRC_DIR="$ROOT_DIR/src"
BIN_DIR="$ROOT_DIR/bin"
TOOLS_DIR="$ROOT_DIR/tools"

# 检查是否存在 FPC 编译器
if ! command -v fpc &> /dev/null; then
    echo "错误: 未找到 FreePascal 编译器 (fpc)"
    echo "请确保 FreePascal 已正确安装并添加到 PATH 环境变量中"
    exit 1
fi

# 创建输出目录
mkdir -p "$BIN_DIR"

# 解析命令行参数
ACTION="${1:-all}"

echo "fafafa.core.lockfree 构建和测试系统"
echo "===================================="
echo

case "$ACTION" in
    "clean")
        echo "清理构建产物..."
        rm -f "$BIN_DIR/tests_lockfree"
        rm -f "$BIN_DIR/lockfree_tests"
        rm -f "$BIN_DIR/benchmark_lockfree"
        rm -f "$BIN_DIR/example_lockfree"
        rm -f "$BIN_DIR/aba_test"
        rm -rf "$SCRIPT_DIR/lib"
        echo "清理完成"
        ;;
        
    "test")
        echo "开始测试流程..."
        echo

        # 1. 编译基础测试
        echo "[1/4] 编译基础功能测试..."
        fpc -Fu"$SRC_DIR" -FE"$BIN_DIR" "$SCRIPT_DIR/tests_lockfree.lpr"

        # 2. 运行基础测试
        echo "[2/4] 运行基础功能测试..."
        "$BIN_DIR/tests_lockfree"

        # 3. 编译ABA问题验证测试
        echo "[3/4] 编译ABA问题验证测试..."
        fpc -Fu"$SRC_DIR" -FE"$BIN_DIR" "$ROOT_DIR/play/fafafa.core.lockfree/aba_test.lpr"

        # 4. 运行ABA测试
        echo "[4/4] 运行ABA问题验证测试..."
        echo "y" | "$BIN_DIR/aba_test"

        echo
        echo "✅ 所有测试通过！"
        ;;
        
    "benchmark")
        echo "开始性能基准测试..."
        echo

        # 编译基准测试
        echo "[1/2] 编译性能基准测试..."
        fpc -Fu"$SRC_DIR" -FE"$BIN_DIR" -O3 "$SCRIPT_DIR/benchmark_lockfree.lpr"

        # 运行基准测试
        echo "[2/2] 运行性能基准测试..."
        echo "y" | "$BIN_DIR/benchmark_lockfree"

        echo
        echo "✅ 性能基准测试完成！"
        ;;
        
    "all")
        echo "开始完整构建和测试流程..."
        echo

        # 1. 清理
        echo "清理构建产物..."
        rm -f "$BIN_DIR/tests_lockfree"
        rm -f "$BIN_DIR/lockfree_tests"
        rm -f "$BIN_DIR/benchmark_lockfree"
        rm -f "$BIN_DIR/example_lockfree"
        rm -f "$BIN_DIR/aba_test"
        rm -rf "$SCRIPT_DIR/lib"

        # 2. 编译所有项目
        echo "[1/7] 编译基础功能测试..."
        fpc -Fu"$SRC_DIR" -FE"$BIN_DIR" "$SCRIPT_DIR/tests_lockfree.lpr"

        echo "[2/7] 编译单元测试..."
        fpc -Fu"$SRC_DIR" -FE"$BIN_DIR" -dDEBUG "$SCRIPT_DIR/fafafa.core.lockfree.tests.lpr"

        echo "[3/7] 编译示例程序..."
        fpc -Fu"$SRC_DIR" -FE"$BIN_DIR" "$ROOT_DIR/examples/fafafa.core.lockfree/example_lockfree.lpr"

        echo "[4/7] 编译ABA验证测试..."
        fpc -Fu"$SRC_DIR" -FE"$BIN_DIR" "$ROOT_DIR/play/fafafa.core.lockfree/aba_test.lpr"

        echo "[5/8] 编译性能基准测试..."
        fpc -Fu"$SRC_DIR" -FE"$BIN_DIR" -O3 "$SCRIPT_DIR/benchmark_lockfree.lpr"

        echo "[6/8] 编译 OA HashMap 额外测试..."
        fpc -Fu"$SRC_DIR" -FE"$BIN_DIR" "$SCRIPT_DIR/test_oa_hashmap_extras.lpr"

        echo "[7/8] 编译 Padding 冒烟测试..."
        fpc -Fu"$SRC_DIR" -FE"$BIN_DIR" "$SCRIPT_DIR/test_padding_smoke.lpr"

        # 3. 运行所有测试
        echo "[8/8] 运行所有测试..."
        echo

        echo "--- 基础功能测试 ---"
        "$BIN_DIR/tests_lockfree"

        echo
        echo "--- ABA问题验证测试 ---"
        echo "y" | "$BIN_DIR/aba_test"

        echo
        echo "--- 示例程序测试 ---"
        echo "y" | "$BIN_DIR/example_lockfree"

        echo
        echo "--- OA HashMap 额外测试 ---"
        "$BIN_DIR/test_oa_hashmap_extras"

        echo
        echo "--- Padding 冒烟测试 ---"
        "$BIN_DIR/test_padding_smoke"

        echo
        echo "🎉 所有构建和测试完成！"
        echo
        echo "生成的文件:"
        echo "  - $BIN_DIR/tests_lockfree                (基础功能测试)"
        echo "  - $BIN_DIR/lockfree_tests                (单元测试)"
        echo "  - $BIN_DIR/example_lockfree              (示例程序)"
        echo "  - $BIN_DIR/aba_test                      (ABA验证测试)"
        echo "  - $BIN_DIR/benchmark_lockfree            (性能基准测试)"
        echo "  - $BIN_DIR/test_oa_hashmap_extras        (OA 额外测试)"
        echo "  - $BIN_DIR/test_padding_smoke            (Padding 冒烟测试)"
        echo
        echo "要运行性能基准测试，请执行:"
        echo "  ./BuildAndTest.sh benchmark"
        ;;

    *)
        echo "用法: ./BuildAndTest.sh [选项]"
        echo
        echo "选项:"
        echo "  clean      - 清理构建产物"
        echo "  test       - 编译并运行测试"
        echo "  benchmark  - 编译并运行性能基准测试"
        echo "  all        - 完整构建和测试流程 (默认)"
        echo
        echo "示例:"
        echo "  ./BuildAndTest.sh           # 完整构建和测试"
        echo "  ./BuildAndTest.sh test      # 只运行测试"
        echo "  ./BuildAndTest.sh benchmark # 只运行性能测试"
        echo "  ./BuildAndTest.sh clean     # 清理构建产物"
        exit 1
        ;;
esac

echo
echo "按回车键继续..."
read
