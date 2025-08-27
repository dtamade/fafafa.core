#!/bin/bash

# FreePascal SIMD 模块 ARM64/NEON 测试构建脚本
# 专门用于在 ARM64 环境下验证 NEON 实现

set -e

PROJECT="fafafa.core.simd.test.lpi"
TEST_EXECUTABLE="bin/fafafa.core.simd.test"
CLEAN_DIRS="lib bin"

CMD="${1:-build}"

# 检查是否在 ARM64 环境
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    echo "Warning: This script is designed for ARM64/AArch64 systems."
    echo "Current architecture: $ARCH"
    echo "NEON-specific tests may not be meaningful on this platform."
fi

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

# 编译选项
FPC_OPTIONS="-Mdelphi -Sh -O1 -g -gl -gh -Xg -vewnhi -l"
FPC_INCLUDES="-Fi../../src -Fu../../src"
FPC_OUTPUT="-FU./lib -o./bin/fafafa.core.simd.test"

# 根据是否启用 NEON 汇编设置编译选项
if [ "$ENABLE_NEON_ASM" = "1" ]; then
    echo "Building with NEON assembly enabled..."
    FPC_OPTIONS="$FPC_OPTIONS -dFAFAFA_SIMD_NEON_ASM"
else
    echo "Building with scalar fallback (NEON assembly disabled)..."
fi

# 编译项目
echo "Building $PROJECT for ARM64..."
if command -v lazbuild >/dev/null 2>&1; then
    # 使用 lazbuild（推荐）
    if [ "$ENABLE_NEON_ASM" = "1" ]; then
        lazbuild "$PROJECT" --build-mode=Debug --compiler-option="-dFAFAFA_SIMD_NEON_ASM"
    else
        lazbuild "$PROJECT" --build-mode=Debug
    fi
elif command -v fpc >/dev/null 2>&1; then
    # 直接使用 fpc
    fpc $FPC_OPTIONS $FPC_INCLUDES $FPC_OUTPUT fafafa.core.simd.test.lpr
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
        echo "Running ARM64/NEON validation tests..."
        
        # 设置环境变量
        export FAFAFA_SIMD_FORCE=""  # 让系统自动检测
        
        echo "=== Test Run 1: Auto-detected profile ==="
        "$TEST_EXECUTABLE" --all --format=plain
        test_result=$?
        
        if [ $test_result -eq 0 ]; then
            echo "=== Test Run 2: Force scalar profile ==="
            export FAFAFA_SIMD_FORCE=SCALAR
            "$TEST_EXECUTABLE" --suite=TTestCase_NEONValidation --format=plain
            scalar_result=$?
            
            if [ "$ENABLE_NEON_ASM" = "1" ]; then
                echo "=== Test Run 3: Force NEON profile ==="
                export FAFAFA_SIMD_FORCE=AARCH64-NEON
                "$TEST_EXECUTABLE" --suite=TTestCase_NEONValidation --format=plain
                neon_result=$?
                
                if [ $scalar_result -eq 0 ] && [ $neon_result -eq 0 ]; then
                    echo "=== All ARM64/NEON tests passed! ==="
                    exit 0
                else
                    echo "=== Some tests failed ==="
                    exit 1
                fi
            else
                echo "=== NEON assembly disabled, scalar tests only ==="
                exit $scalar_result
            fi
        else
            echo "=== Initial test run failed ==="
            exit $test_result
        fi
    else
        echo "Error: Test executable not found: $TEST_EXECUTABLE"
        exit 2
    fi
elif [ "$CMD" = "benchmark" ]; then
    if [ -x "$TEST_EXECUTABLE" ]; then
        echo "Running ARM64/NEON performance benchmarks..."
        
        echo "=== Benchmark 1: Scalar baseline ==="
        export FAFAFA_SIMD_FORCE=SCALAR
        "$TEST_EXECUTABLE" --suite=TTestCase_NEONValidation.Test_NEON_Performance_Baseline --format=plain
        
        if [ "$ENABLE_NEON_ASM" = "1" ]; then
            echo "=== Benchmark 2: NEON optimized ==="
            export FAFAFA_SIMD_FORCE=AARCH64-NEON
            "$TEST_EXECUTABLE" --suite=TTestCase_NEONValidation.Test_NEON_Performance_Baseline --format=plain
        fi
        
        echo "=== Benchmarks completed ==="
    else
        echo "Error: Test executable not found: $TEST_EXECUTABLE"
        exit 2
    fi
else
    echo "Build successful for ARM64."
    echo ""
    echo "Usage:"
    echo "  ./buildOrTest_arm64.sh test      - Run validation tests"
    echo "  ./buildOrTest_arm64.sh benchmark - Run performance benchmarks"
    echo ""
    echo "Environment variables:"
    echo "  ENABLE_NEON_ASM=1 - Enable NEON assembly implementations"
    echo "  FAFAFA_SIMD_FORCE - Force specific SIMD profile (SCALAR, AARCH64-NEON)"
    echo ""
    echo "Examples:"
    echo "  ENABLE_NEON_ASM=1 ./buildOrTest_arm64.sh test"
    echo "  FAFAFA_SIMD_FORCE=SCALAR ./buildOrTest_arm64.sh test"
fi
