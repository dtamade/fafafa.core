#!/bin/bash

echo "========================================"
echo "fafafa.core.socket 测试构建脚本"
echo "========================================"
echo

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$SCRIPT_DIR"
BIN_DIR="$TEST_DIR/bin"
LIB_DIR="$TEST_DIR/lib"

detect_lazarusdir() {
    if [ -n "${FAFAFA_LAZARUSDIR:-}" ] && [ -d "${FAFAFA_LAZARUSDIR}/lcl" ]; then
        echo "${FAFAFA_LAZARUSDIR}"
        return 0
    fi

    if [ -n "${LAZARUS_DIR:-}" ] && [ -d "${LAZARUS_DIR}/lcl" ]; then
        echo "${LAZARUS_DIR}"
        return 0
    fi

    for LCandidate in \
        "/opt/fpcupdeluxe/lazarus" \
        "/usr/lib/lazarus" \
        "/usr/local/share/lazarus" \
        "/usr/share/lazarus"; do
        if [ -d "${LCandidate}/lcl" ]; then
            echo "${LCandidate}"
            return 0
        fi
    done

    LLazbuildPath="$(command -v lazbuild 2>/dev/null || true)"
    if [ -n "${LLazbuildPath}" ]; then
        LMaybeRoot="$(cd "$(dirname "${LLazbuildPath}")" && pwd)"
        if [ -d "${LMaybeRoot}/lcl" ]; then
            echo "${LMaybeRoot}"
            return 0
        fi
        LMaybeRoot="$(cd "${LMaybeRoot}/.." 2>/dev/null && pwd || true)"
        if [ -n "${LMaybeRoot}" ] && [ -d "${LMaybeRoot}/lcl" ]; then
            echo "${LMaybeRoot}"
            return 0
        fi
    fi

    echo ""
    return 0
}

LAZARUS_DIR="$(detect_lazarusdir)"
if [ -z "${LAZARUS_DIR}" ]; then
    echo "错误: 找不到 Lazarus 根目录（缺少 lcl 子目录）"
    echo "请设置 FAFAFA_LAZARUSDIR 或 LAZARUS_DIR，例如 /opt/fpcupdeluxe/lazarus"
    exit 2
fi

PCP_DIR="$TEST_DIR/.lazarus"

echo "项目根目录: $PROJECT_ROOT"
echo "测试目录: $TEST_DIR"
echo "输出目录: $BIN_DIR"
echo "库目录: $LIB_DIR"
echo

# 检查 lazbuild 是否可用
if ! command -v lazbuild &> /dev/null; then
    echo "错误: 找不到 lazbuild 命令"
    echo "请确保 Lazarus 已正确安装并添加到 PATH 环境变量中"
    exit 1
fi

# 创建输出目录
if [ ! -d "$BIN_DIR" ]; then
    echo "创建输出目录: $BIN_DIR"
    mkdir -p "$BIN_DIR"
fi

if [ ! -d "$LIB_DIR" ]; then
    echo "创建库目录: $LIB_DIR"
    mkdir -p "$LIB_DIR"
fi

if [ ! -d "$PCP_DIR" ]; then
    mkdir -p "$PCP_DIR"
fi

echo "========================================"
echo "构建测试项目 (Debug 模式)"
echo "========================================"

lazbuild --pcp="$PCP_DIR" --lazarusdir="$LAZARUS_DIR" --build-mode=Debug "$TEST_DIR/tests_socket.lpi"
if [ $? -ne 0 ]; then
    echo "错误: 测试项目构建失败"
    exit 1
fi

echo "测试项目构建成功！"

# 运行模式与参数透传
MODE="${1:-build}"
shift || true
EXTRA_ARGS=("$@")

case "$MODE" in
  test|run)
    echo "========================================"
    echo "运行单元测试"
    echo "========================================"

    TEST_EXE="$BIN_DIR/tests_socket"

    if [ ! -f "$TEST_EXE" ] && [ -f "$PROJECT_ROOT/bin/tests_socket" ]; then
        # 兼容旧路径一次
        TEST_EXE="$PROJECT_ROOT/bin/tests_socket"
    fi

    if [ ! -f "$TEST_EXE" ]; then
        echo "错误: 找不到测试可执行文件: $TEST_EXE"
        exit 1
    fi

    # 设置可执行权限
    chmod +x "$TEST_EXE" 2>/dev/null || true

    LOG="$BIN_DIR/tests_socket.log"
    # 支持 JUnit 输出：设置环境变量 JUNIT=1（可选 JUNIT_OUT 指定路径）
    if [ -n "${JUNIT:-}" ]; then
      JUNIT_FILE="$BIN_DIR/tests_socket.junit.xml"
      if [ -n "${JUNIT_OUT:-}" ]; then JUNIT_FILE="$JUNIT_OUT"; fi
      echo "[JUnit] Writing to $JUNIT_FILE"
      "$TEST_EXE" --all --progress --format=xml "${EXTRA_ARGS[@]}" > "$JUNIT_FILE" 2>&1
      TEST_RESULT=$?
      SUMMARY=$(grep -E "<testsuite " "$JUNIT_FILE" | tail -n 1)
      if [ -n "$SUMMARY" ]; then echo "[JUnit] Summary: $SUMMARY"; else echo "[JUnit] Summary: see report $JUNIT_FILE"; fi
    else
      # 运行测试（plain）
      echo "执行测试: $TEST_EXE ${EXTRA_ARGS[*]}"
      "$TEST_EXE" --all --progress --format=plain "${EXTRA_ARGS[@]}" > "$LOG" 2>&1
      TEST_RESULT=$?
      SUMMARY=$(grep -E 'OK:|Failures|Errors' "$LOG" | tail -n 1)
      if [ -n "$SUMMARY" ]; then echo "Summary: $SUMMARY"; else echo "Summary: see log $LOG"; fi
    fi

    echo
    if [ $TEST_RESULT -eq 0 ]; then
        echo "✅ 所有测试通过！"
    else
        echo "❌ 测试失败，退出代码: $TEST_RESULT"
        echo "---- 日志末尾 50 行 ----"
        tail -n 50 "$LOG" || true
        exit $TEST_RESULT
    fi
    ;;
  perf)
    echo "========================================"
    echo "运行性能测试"
    echo "========================================"

    TEST_EXE="$BIN_DIR/tests_socket"

    if [ ! -f "$TEST_EXE" ] && [ -f "$PROJECT_ROOT/bin/tests_socket" ]; then
        # 兼容旧路径一次
        TEST_EXE="$PROJECT_ROOT/bin/tests_socket"
    fi

    if [ ! -f "$TEST_EXE" ]; then
        echo "错误: 找不到测试可执行文件: $TEST_EXE"
        exit 1
    fi

    # 设置可执行权限
    chmod +x "$TEST_EXE" 2>/dev/null || true

    PERF_LOG="$BIN_DIR/tests_socket_perf.log"
    # JUnit 支持
    if [ -n "${JUNIT:-}" ]; then
      JUNIT_FILE="$BIN_DIR/tests_socket_perf.junit.xml"
      if [ -n "${JUNIT_OUT:-}" ]; then JUNIT_FILE="$JUNIT_OUT"; fi
      echo "[PERF][JUnit] Writing to $JUNIT_FILE"
      ENABLE_PERF=1 "$TEST_EXE" --suite=TTestCase_Perf --progress --format=xml "${EXTRA_ARGS[@]}" > "$JUNIT_FILE" 2>&1
      PERF_RESULT=$?
      PERF_SUMMARY=$(grep -E "<testsuite " "$JUNIT_FILE" | tail -n 1)
      if [ -n "$PERF_SUMMARY" ]; then echo "[PERF][JUnit] Summary: $PERF_SUMMARY"; else echo "[PERF][JUnit] Summary: see report $JUNIT_FILE"; fi
    else
      echo "执行性能套件: $TEST_EXE ${EXTRA_ARGS[*]}"
      ENABLE_PERF=1 "$TEST_EXE" --suite=TTestCase_Perf --progress --format=plain "${EXTRA_ARGS[@]}" > "$PERF_LOG" 2>&1
      PERF_RESULT=$?
      PERF_SUMMARY=$(grep -E 'OK:|Failures|Errors' "$PERF_LOG" | tail -n 1)
      if [ -n "$PERF_SUMMARY" ]; then echo "[PERF] Summary: $PERF_SUMMARY"; else echo "[PERF] Summary: see log $PERF_LOG"; fi
    fi

    if [ $PERF_RESULT -eq 0 ]; then
        echo "✅ 性能测试通过"
    else
        echo "❌ 性能测试失败，退出代码: $PERF_RESULT"
        echo "---- 日志末尾 50 行 ----"
        tail -n 50 "$PERF_LOG" || true
        exit $PERF_RESULT
    fi
    ;;
  adv|advanced)
    echo "========================================"
    echo "构建并运行 ADVANCED 测试"
    echo "========================================"

    ADV_LPI="$TEST_DIR/tests_socket_advanced.lpi"
    ADV_EXE="$BIN_DIR/tests_socket_adv"

    echo "构建: $ADV_LPI"
    lazbuild --pcp="$PCP_DIR" --lazarusdir="$LAZARUS_DIR" "$ADV_LPI"
    if [ $? -ne 0 ]; then
        echo "错误: ADVANCED 项目构建失败"
        exit 1
    fi

    if [ ! -f "$ADV_EXE" ]; then
        # 有些平台可能带扩展名
        if [ -f "$ADV_EXE.exe" ]; then ADV_EXE="$ADV_EXE.exe"; fi
    fi

    if [ ! -f "$ADV_EXE" ]; then
        echo "错误: 找不到 ADV 可执行文件: $ADV_EXE"
        exit 1
    fi

    chmod +x "$ADV_EXE" 2>/dev/null || true

    ADV_LOG="$BIN_DIR/tests_socket_adv.log"
    # JUnit 支持
    if [ -n "${JUNIT:-}" ]; then
      JUNIT_FILE="$BIN_DIR/tests_socket_adv.junit.xml"
      if [ -n "${JUNIT_OUT:-}" ]; then JUNIT_FILE="$JUNIT_OUT"; fi
      echo "[ADV][JUnit] Writing to $JUNIT_FILE"
      "$ADV_EXE" --all --progress --format=xml "${EXTRA_ARGS[@]}" > "$JUNIT_FILE" 2>&1
      ADV_RESULT=$?
      ADV_SUMMARY=$(grep -E "<testsuite " "$JUNIT_FILE" | tail -n 1)
      if [ -n "$ADV_SUMMARY" ]; then echo "[ADV][JUnit] Summary: $ADV_SUMMARY"; else echo "[ADV][JUnit] Summary: see report $JUNIT_FILE"; fi
    else
      echo "执行 ADV 测试: $ADV_EXE ${EXTRA_ARGS[*]}"
      "$ADV_EXE" --all --progress --format=plain "${EXTRA_ARGS[@]}" > "$ADV_LOG" 2>&1
      ADV_RESULT=$?
      ADV_SUMMARY=$(grep -E 'OK:|Failures|Errors' "$ADV_LOG" | tail -n 1)
      if [ -n "$ADV_SUMMARY" ]; then echo "[ADV] Summary: $ADV_SUMMARY"; else echo "[ADV] Summary: see log $ADV_LOG"; fi
    fi

    if [ $ADV_RESULT -eq 0 ]; then
        echo "✅ ADV 测试通过"
    else
        echo "❌ ADV 测试失败，退出代码: $ADV_RESULT"
        echo "---- 日志末尾 50 行 ----"
        tail -n 50 "$ADV_LOG" || true
        exit $ADV_RESULT
    fi
    ;;
  *)
    echo "========================================"
    echo "构建完成"
    echo "========================================"
    echo
    echo "测试可执行文件: $BIN_DIR/tests_socket"
    echo
    echo "运行测试:"
    echo "  $0 test [--suite=NAME] [更多参数]"
    echo "  $0 perf [更多参数]"
    echo "  $0 adv  [更多参数]"
    ;;
esac

echo
echo "脚本执行完成"
