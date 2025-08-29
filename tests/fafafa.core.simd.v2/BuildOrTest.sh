#!/bin/bash

# fafafa.core.simd.v2 构建和测试脚本
# 遵循项目规范的平面路径结构

set -e

PROJECT_NAME="fafafa.core.simd.v2.test"
PROJECT_FILE="${PROJECT_NAME}.lpi"
BINARY_PATH="bin/${PROJECT_NAME}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== fafafa.core.simd 2.0 构建和测试 ===${NC}"
echo ""

# 检查 lazbuild
if ! command -v lazbuild &> /dev/null; then
    echo -e "${RED}[ERROR] lazbuild 未找到，请确保 Lazarus 已安装并在 PATH 中${NC}"
    exit 1
fi

# 显示系统信息
echo -e "${BLUE}[INFO] 系统信息:${NC}"
echo "  操作系统: $(uname -s)"
echo "  架构: $(uname -m)"
echo "  编译器: $(fpc -iV)"
echo ""

# 创建输出目录
mkdir -p bin lib

# 构建项目
echo -e "${YELLOW}[BUILD] 构建项目: ${PROJECT_FILE}${NC}"
if lazbuild --build-mode=Debug "${PROJECT_FILE}"; then
    echo -e "${GREEN}[BUILD] 构建成功${NC}"
else
    echo -e "${RED}[BUILD] 构建失败${NC}"
    exit 1
fi

# 检查二进制文件
if [ ! -f "${BINARY_PATH}" ]; then
    echo -e "${RED}[ERROR] 二进制文件未生成: ${BINARY_PATH}${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}[TEST] 运行测试...${NC}"
echo ""

# 运行测试
if "./${BINARY_PATH}"; then
    echo ""
    echo -e "${GREEN}[SUCCESS] 所有测试通过！${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}[FAILURE] 测试失败！${NC}"
    exit 1
fi
