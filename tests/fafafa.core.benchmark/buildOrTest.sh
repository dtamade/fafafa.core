#!/bin/bash

set -e

echo "========================================"
echo "fafafa.core.benchmark 测试构建脚本"
echo "========================================"
echo

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$SCRIPT_DIR"
BIN_DIR="$SCRIPT_DIR/bin"
PROJECT_FILE="$TEST_DIR/tests_benchmark.lpi"
EXECUTABLE="$BIN_DIR/tests_benchmark"

# 函数：构建项目
build_project() {
    echo "🔨 构建测试项目..."
    
    # 确保输出目录存在
    mkdir -p "$BIN_DIR"
    
    echo "   项目文件: $PROJECT_FILE"
    echo "   输出目录: $BIN_DIR"
    
    # 使用 lazbuild 构建项目
    if lazbuild --build-mode=Debug "$PROJECT_FILE"; then
        echo "✅ 构建成功"
        if [ -f "$EXECUTABLE" ]; then
            echo "   可执行文件: $EXECUTABLE"
            chmod +x "$EXECUTABLE"
        else
            echo "⚠️  警告: 构建成功但找不到可执行文件"
            return 1
        fi
    else
        echo "❌ 构建失败"
        return 1
    fi
}

# 函数：运行测试
run_test() {
    if [ ! -f "$EXECUTABLE" ]; then
        echo "❌ 可执行文件不存在，请先构建项目"
        echo "   文件路径: $EXECUTABLE"
        return 1
    fi
    
    echo "🧪 运行测试: $EXECUTABLE"
    cd "$PROJECT_ROOT"
    
    if "$EXECUTABLE" --all --format=plain --progress; then
        echo
        echo "✅ 所有测试通过！"
        return 0
    else
        TEST_RESULT=$?
        echo
        echo "❌ 测试失败，退出代码: $TEST_RESULT"
        return $TEST_RESULT
    fi
}

# 函数：清理构建文件
clean_build() {
    echo "🧹 清理构建文件..."
    
    if [ -d "$TEST_DIR/lib" ]; then
        rm -rf "$TEST_DIR/lib"
        echo "   已删除: $TEST_DIR/lib"
    fi
    
    if [ -f "$EXECUTABLE" ]; then
        rm -f "$EXECUTABLE"
        echo "   已删除: $EXECUTABLE"
    fi
    
    echo "✅ 清理完成"
}

# 函数：显示帮助
show_help() {
    echo
    echo "用法: $0 [命令]"
    echo
    echo "命令:"
    echo "  build    仅构建项目"
    echo "  test     仅运行测试（需要先构建）"
    echo "  clean    清理构建文件"
    echo "  help     显示此帮助信息"
    echo "  (无参数)  构建并运行测试"
    echo
    echo "示例:"
    echo "  $0           # 构建并运行测试"
    echo "  $0 build     # 仅构建"
    echo "  $0 test      # 仅运行测试"
    echo "  $0 clean     # 清理文件"
    echo
}

# 主逻辑
case "${1:-}" in
    "build")
        build_project
        ;;
    "test")
        run_test
        ;;
    "clean")
        clean_build
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    "")
        # 默认：构建并运行测试
        if build_project; then
            echo
            run_test
        else
            echo "❌ 构建失败，跳过测试运行"
            exit 1
        fi
        ;;
    *)
        echo "❌ 未知命令: $1"
        show_help
        exit 1
        ;;
esac
