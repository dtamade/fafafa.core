#!/bin/bash

# 设置脚本在遇到错误时退出
set -e

echo "========================================"
echo "fafafa.core.collections.vecdeque 测试构建脚本"
echo "========================================"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
REPO_ROOT="$PROJECT_ROOT/.."
PROJECT_FILE="$SCRIPT_DIR/tests_vecdeque.lpi"
OUTPUT_DIR="$PROJECT_ROOT/bin"
LIB_DIR="$SCRIPT_DIR/lib"
LOCAL_BIN_DIR="$SCRIPT_DIR/bin"

# 检查 lazbuild 是否可用
if ! command -v lazbuild &> /dev/null; then
    echo "错误: 找不到 lazbuild 命令"
    echo "请确保 Lazarus 已正确安装并添加到 PATH 环境变量中"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"
mkdir -p "$LIB_DIR"
mkdir -p "$LOCAL_BIN_DIR"

echo ""
echo "正在编译测试项目..."
echo "项目文件: $PROJECT_FILE"
echo "输出目录: $OUTPUT_DIR"
echo ""

# 编译 Debug 版本
echo "[1/2] 编译 Debug 版本..."
if lazbuild --build-mode=Debug "$PROJECT_FILE"; then
    echo "✅ Debug 版本编译成功"
else
    echo ""
    echo "❌ Debug 版本编译失败！"
    exit 1
fi

# 编译 Release 版本
echo ""
echo "[2/2] 编译 Release 版本..."
if lazbuild --build-mode=Release "$PROJECT_FILE"; then
    echo "✅ Release 版本编译成功"
else
    echo ""
    echo "❌ Release 版本编译失败！"
    exit 1
fi

# 可选：先构建并运行一个最小独立用例（需要 fpc 可用）
if command -v fpc &> /dev/null; then
  echo ""
  echo "[预检] 构建并运行独立用例 test_strategy_pow2_rounding.pas (需要 fpc)"
  echo ""
  set +e
  fpc -Mobjfpc -Sh -O1 -g -gl -l -vewnhibq \
      -I"$REPO_ROOT/src" -Fu"$REPO_ROOT/src" \
      -FU"$LIB_DIR" -FE"$LOCAL_BIN_DIR" \
      "$SCRIPT_DIR/test_strategy_pow2_rounding.pas"
  BUILD_RC=$?
  set -e
  if [ $BUILD_RC -eq 0 ]; then
    echo "运行: $LOCAL_BIN_DIR/test_strategy_pow2_rounding"
    set +e
    "$LOCAL_BIN_DIR/test_strategy_pow2_rounding"
    RUN_RC=$?
    set -e
    if [ $RUN_RC -ne 0 ]; then
      echo "❌ 预检用例运行失败，退出代码: $RUN_RC"
      exit $RUN_RC
    else
      echo "✅ 预检用例通过"
    fi
  else
    echo "⚠️ 预检用例构建失败（跳过运行），退出代码: $BUILD_RC"
  fi
else
  echo "⚠️ 未检测到 fpc，跳过独立用例构建与运行"
fi

# 运行测试
echo ""
echo "========================================"
echo "运行测试套件"
echo "========================================"
echo ""

TEST_EXE="$OUTPUT_DIR/tests_vecdeque"
if [ ! -f "$TEST_EXE" ]; then
    echo "错误: 找不到测试可执行文件 $TEST_EXE"
    exit 1
fi

echo "执行测试: $TEST_EXE"
echo ""

# 运行测试并捕获退出代码
set +e
"$TEST_EXE" --all --format=plain --progress
TEST_RESULT=$?
set -e

echo ""
echo "========================================"
if [ $TEST_RESULT -eq 0 ]; then
    echo "✅ 测试完成 - 所有测试通过！"
else
    echo "❌ 测试完成 - 发现失败的测试！"
    echo "退出代码: $TEST_RESULT"
fi
echo "========================================"

exit $TEST_RESULT
