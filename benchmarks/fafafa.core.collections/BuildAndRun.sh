#!/bin/bash
# fafafa.core.collections 性能基准测试构建脚本

echo "=========================================="
echo "fafafa.core.collections 性能基准测试"
echo "=========================================="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
PROJECT_FILE="$SCRIPT_DIR/collections_performance_benchmark.lpi"
BIN_DIR="$PROJECT_ROOT/bin"
EXECUTABLE="$BIN_DIR/collections_performance_benchmark"

build_project() {
    mkdir -p "$BIN_DIR"

    echo "    项目文件: $PROJECT_FILE"
    echo "    输出目录: $BIN_DIR"

    if ! /home/dtamade/freePascal/lazarus/lazbuild "$PROJECT_FILE" --quiet; then
        echo "构建失败!"
        return 1
    fi

    echo "构建成功"
    if [ -f "$EXECUTABLE" ]; then
        echo "    可执行文件: $EXECUTABLE"
        return 0
    else
        echo "错误: 未找到可执行文件"
        return 1
    fi
}

run_benchmark() {
    echo
    echo "运行性能基准测试..."
    echo "=========================================="

    cd "$PROJECT_ROOT"

    # 运行默认基准测试
    "$EXECUTABLE" --report=console

    echo
    echo "生成 JSON 报告..."
    "$EXECUTABLE" --report=json

    echo
    echo "基准测试完成!"
    echo "报告文件:"
    echo "  - 控制台输出: 上述"
    echo "  - JSON 报告: $PROJECT_ROOT/benchmarks/fafafa.core.collections/performance_report.json"
}

clean_build() {
    echo "清理构建产物..."

    # 删除二进制文件
    if [ -f "$EXECUTABLE" ]; then
        rm -f "$EXECUTABLE"
        echo "  已删除: $EXECUTABLE"
    fi

    # 删除编译单元
    if [ -d "$PROJECT_ROOT/lib" ]; then
        rm -rf "$PROJECT_ROOT/lib"
        echo "  已删除: $PROJECT_ROOT/lib"
    fi

    echo "清理完成"
}

case "${1:-build}" in
    "build")
        if build_project; then
            run_benchmark
        else
            echo "构建失败"
            exit 1
        fi
        ;;
    "clean")
        clean_build
        ;;
    "rebuild")
        clean_build
        if build_project; then
            run_benchmark
        else
            echo "构建失败"
            exit 1
        fi
        ;;
    "run")
        if [ ! -f "$EXECUTABLE" ]; then
            echo "错误: 未找到可执行文件，请先运行 build"
            exit 1
        fi
        run_benchmark
        ;;
    *)
        echo "用法: $0 [build|clean|rebuild|run]"
        echo "  build  - 构建并运行基准测试 (默认)"
        echo "  clean  - 清理构建产物"
        echo "  rebuild - 清理并重新构建"
        echo "  run    - 仅运行基准测试"
        exit 1
        ;;
esac
