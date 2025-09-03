#!/bin/bash
# Build and test script for fafafa.core.sync.mutex.parkinglot
# Usage: ./buildOrTest.sh [build|test|clean|help]

set -e

PROJECT_NAME="fafafa.core.sync.mutex.parkinglot.test"
PROJECT_FILE="${PROJECT_NAME}.lpi"
EXECUTABLE="bin/${PROJECT_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    echo
    echo -e "${BLUE}fafafa.core.sync.mutex.parkinglot 测试构建脚本${NC}"
    echo
    echo "用法: $0 [命令]"
    echo
    echo "命令:"
    echo "  build  - 仅构建测试程序"
    echo "  test   - 构建并运行测试 (默认)"
    echo "  clean  - 清理构建产物"
    echo "  help   - 显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0           # 构建并运行所有测试"
    echo "  $0 build     # 仅构建"
    echo "  $0 test      # 构建并运行测试"
    echo "  $0 clean     # 清理"
    echo
}

build_project() {
    echo -e "${YELLOW}构建 ${PROJECT_NAME}...${NC}"
    echo

    if [ ! -f "$PROJECT_FILE" ]; then
        echo -e "${RED}错误: 找不到项目文件 $PROJECT_FILE${NC}"
        exit 1
    fi

    lazbuild --build-mode=Debug "$PROJECT_FILE"
    
    echo
    echo -e "${GREEN}构建成功!${NC}"
}

run_tests() {
    echo -e "${YELLOW}构建并测试 ${PROJECT_NAME}...${NC}"
    echo

    build_project

    if [ ! -f "$EXECUTABLE" ]; then
        echo -e "${RED}错误: 找不到可执行文件 $EXECUTABLE${NC}"
        exit 1
    fi

    echo
    echo -e "${BLUE}运行测试...${NC}"
    echo "================================================================================"

    if "./$EXECUTABLE" --format=plain --progress; then
        echo
        echo "================================================================================"
        echo -e "${GREEN}所有测试通过! ✓${NC}"
        exit 0
    else
        TEST_RESULT=$?
        echo
        echo "================================================================================"
        echo -e "${RED}测试失败! ✗ (退出代码: $TEST_RESULT)${NC}"
        exit $TEST_RESULT
    fi
}

clean_project() {
    echo -e "${YELLOW}清理构建产物...${NC}"

    rm -rf bin lib
    rm -f *.compiled *.o *.ppu

    echo -e "${GREEN}清理完成!${NC}"
}

# Main script logic
case "${1:-test}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    "build")
        build_project
        ;;
    "test")
        run_tests
        ;;
    "clean")
        clean_project
        ;;
    *)
        echo -e "${RED}未知命令: $1${NC}"
        show_help
        exit 1
        ;;
esac
