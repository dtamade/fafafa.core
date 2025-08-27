#!/bin/bash

# FreePascal SIMD 模块测试构建脚本
# 用于在 Linux 环境下编译和运行测试

set -e

PROJECT="fafafa.core.simd.test.lpi"
TEST_EXECUTABLE="bin/fafafa.core.simd.test"
CLEAN_DIRS="lib bin"

CMD="${1:-build}"

case "$CMD" in
    "clean")
        echo "Cleaning build artifacts..."
        for dir in $CLEAN_DIRS; do
            if [ -d "$dir" ]; then
                rm -rf "$dir"
            fi
        done
        echo "Clean completed."
        exit 0
        ;;
    "rebuild")
        echo "Rebuilding..."
        for dir in $CLEAN_DIRS; do
            if [ -d "$dir" ]; then
                rm -rf "$dir"
            fi
        done
        ;;
esac

# 确保输出目录存在
mkdir -p bin lib

# 编译项目
echo "Building $PROJECT..."
if command -v lazbuild >/dev/null 2>&1; then
    lazbuild "$PROJECT" --build-mode=Debug
elif command -v fpc >/dev/null 2>&1; then
    # 直接使用 fpc 编译
    fpc -Mdelphi -Sh -O1 -g -gl -gh -Xg -vewnhi -l \
        -Fi../../src \
        -Fu../../src \
        -FU./lib \
        -o./bin/fafafa.core.simd.test \
        fafafa.core.simd.test.lpr
else
    echo "Error: Neither lazbuild nor fpc found in PATH"
    exit 1
fi

if [ $? -ne 0 ]; then
    echo "Build failed with error code $?"
    exit 1
fi

if [ "$CMD" = "test" ]; then
    if [ -x "$TEST_EXECUTABLE" ]; then
        echo "Running tests..."
        export FAFAFA_SIMD_FORCE=SSE2
        "$TEST_EXECUTABLE" --all --format=plain
        exit_code=$?
        echo "Tests completed with exit code: $exit_code"
        exit $exit_code
    else
        echo "Error: Test executable not found: $TEST_EXECUTABLE"
        exit 2
    fi
else
    echo "Build successful. To run tests: ./buildOrTest.sh test"
fi
