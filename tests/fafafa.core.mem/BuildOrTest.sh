#!/bin/bash

echo "========================================"
echo "fafafa.core.mem 模块测试构建脚本"
echo "========================================"
echo

PROJECT_NAME="tests_mem"
PROJECT_FILE="${PROJECT_NAME}.lpi"
BIN_DIR="bin"
DEBUG_EXE="${BIN_DIR}/${PROJECT_NAME}_debug"
RELEASE_EXE="${BIN_DIR}/${PROJECT_NAME}"

mkdir -p "$BIN_DIR"

echo "选择操作:"
echo "1. 编译 Debug 版本"
echo "2. 编译 Release 版本"
echo "3. 运行 Debug 测试"
echo "4. 运行 Release 测试"
echo "5. 清理编译文件"
echo "6. 完整测试 (编译+运行)"
echo
read -p "请输入选择 (1-6): " choice

case $choice in
    1)
        echo
        echo "编译 Debug 版本..."
        lazbuild --build-mode=Debug "$PROJECT_FILE"
        if [ $? -ne 0 ]; then
            echo "❌ Debug 编译失败"
            exit 1
        fi
        echo "✅ Debug 编译成功"
        ;;
    2)
        echo
        echo "编译 Release 版本..."
        lazbuild --build-mode=Release "$PROJECT_FILE"
        if [ $? -ne 0 ]; then
            echo "❌ Release 编译失败"
            exit 1
        fi
        echo "✅ Release 编译成功"
        ;;
    3)
        echo
        echo "运行 Debug 测试..."
        if [ ! -f "$DEBUG_EXE" ]; then
            echo "❌ Debug 可执行文件不存在，请先编译"
            exit 1
        fi
        "$DEBUG_EXE"
        echo
        echo "✅ Debug 测试完成"
        ;;
    4)
        echo
        echo "运行 Release 测试..."
        if [ ! -f "$RELEASE_EXE" ]; then
            echo "❌ Release 可执行文件不存在，请先编译"
            exit 1
        fi
        "$RELEASE_EXE"
        echo
        echo "✅ Release 测试完成"
        ;;
    5)
        echo
        echo "清理编译文件..."
        rm -rf lib
        rm -f "$DEBUG_EXE" "$RELEASE_EXE"
        echo "✅ 清理完成"
        ;;
    6)
        echo
        echo "执行完整测试..."
        echo
        echo "[1/4] 编译 Debug 版本..."
        lazbuild --build-mode=Debug "$PROJECT_FILE"
        if [ $? -ne 0 ]; then
            echo "❌ Debug 编译失败"
            exit 1
        fi
        echo "✅ Debug 编译成功"
        echo
        echo "[2/4] 运行 Debug 测试..."
        "$DEBUG_EXE"
        echo
        echo "[3/4] 编译 Release 版本..."
        lazbuild --build-mode=Release "$PROJECT_FILE"
        if [ $? -ne 0 ]; then
            echo "❌ Release 编译失败"
            exit 1
        fi
        echo "✅ Release 编译成功"
        echo
        echo "[4/4] 运行 Release 测试..."
        "$RELEASE_EXE"
        echo
        echo "✅ 完整测试完成"
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo
read -p "按回车键退出..."
