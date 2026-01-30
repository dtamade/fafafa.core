#!/bin/bash
# Collections 内存泄漏验证脚本
# 使用 HeapTrc 运行所有 collections 泄漏测试

set -e  # 遇到错误立即退出

PROJECT_ROOT="/home/dtamade/projects/fafafa.core"
TEST_DIR="$PROJECT_ROOT/tests"
BIN_DIR="$TEST_DIR/leak_test_bin"
LOG_DIR="$TEST_DIR/leak_test_logs"
REPORT_FILE="$TEST_DIR/COLLECTIONS_MEMORY_LEAK_REPORT.md"

# 创建输出目录
mkdir -p "$BIN_DIR"
mkdir -p "$LOG_DIR"

# 测试列表
# 10 个核心集合内存测试（按容器类型分组）
TESTS=(
    "test_vec_leak"
    "test_vecdeque_leak"
    "test_list_leak"
    "test_hashmap_leak"
    "test_hashset_leak"
    "test_linkedhashmap_leak"
    "test_bitset_leak"
    "test_treeset_leak"
    "test_treemap_leak"
    "test_priorityqueue_leak"
)

echo "========================================"
echo "Collections Memory Leak Verification"
echo "========================================"
echo "Date: $(date)"
echo "Project: fafafa.core"
echo "Tool: Free Pascal HeapTrc (-gh -gl)"
echo ""

TOTAL=${#TESTS[@]}
PASSED=0
FAILED=0
FAILED_TESTS=()

# 编译和运行每个测试
for TEST_NAME in "${TESTS[@]}"; do
    TEST_FILE="$TEST_DIR/${TEST_NAME}.pas"
    BIN_FILE="$BIN_DIR/${TEST_NAME}"
    LOG_FILE="$LOG_DIR/${TEST_NAME}.log"

    echo "----------------------------------------"
    echo "Testing: $TEST_NAME"
    echo "----------------------------------------"

    # 检查测试文件是否存在
    if [ ! -f "$TEST_FILE" ]; then
        echo "  ⚠️  Test file not found: $TEST_FILE"
        echo "  SKIPPED"
        ((FAILED+=1))
        FAILED_TESTS+=("$TEST_NAME (file not found)")
        continue
    fi

    # 编译测试（带 HeapTrc）
    echo "  Compiling with HeapTrc..."
    if (
        cd "$TEST_DIR" && \
        fpc @fpc.cfg -gh -gl -B -dUseCThreads \
            -FE"$BIN_DIR" \
            -o"$BIN_FILE" \
            "$(basename "$TEST_FILE")"
    ) > "$LOG_FILE" 2>&1; then
        echo "  ✅ Compilation successful"
    else
        echo "  ❌ Compilation failed"
        echo "  See log: $LOG_FILE"
        ((FAILED+=1))
        FAILED_TESTS+=("$TEST_NAME (compilation failed)")
        continue
    fi

    # 运行测试
    echo "  Running test..."
    RUN_LOG="${LOG_FILE}.run"
    HEAP_LOG="${LOG_FILE}.heap"
    rm -f "$RUN_LOG" "$HEAP_LOG"
    if HEAPTRC="log=$HEAP_LOG" "$BIN_FILE" > "$RUN_LOG" 2>&1; then
        echo "  ✅ Test executed"
        cat "$RUN_LOG" >> "$LOG_FILE"
        if [ -f "$HEAP_LOG" ]; then
            {
                echo ""
                echo "---- HeapTrc Output ----"
                cat "$HEAP_LOG"
            } >> "$LOG_FILE"
        fi
        RUN_RC=0
    else
        RUN_RC=$?
        echo "  ❌ Test execution failed (rc=$RUN_RC)"
        if [ -f "$RUN_LOG" ]; then
            cat "$RUN_LOG" >> "$LOG_FILE"
        fi
        rm -f "$RUN_LOG" "$HEAP_LOG"
        ((FAILED+=1))
        FAILED_TESTS+=("$TEST_NAME (execution failed)")
        continue
    fi
    rm -f "$RUN_LOG" "$HEAP_LOG"

    # 检查内存泄漏
    if grep -q "0 unfreed memory blocks : 0" "$LOG_FILE"; then
        echo "  ✅ NO MEMORY LEAKS - Test passed!"
        ((PASSED+=1))
    else
        echo "  ❌ MEMORY LEAK DETECTED!"
        echo "  See details: $LOG_FILE"
        ((FAILED+=1))
        FAILED_TESTS+=("$TEST_NAME (memory leak)")
    fi

    echo ""
done

# 生成报告
echo "========================================"
echo "Summary"
echo "========================================"
echo "Total tests: $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -gt 0 ]; then
    echo "Failed tests:"
    for FAILED_TEST in "${FAILED_TESTS[@]}"; do
        echo "  - $FAILED_TEST"
    done
    echo ""
fi

echo "Detailed logs: $LOG_DIR/"
echo "Report will be generated: $REPORT_FILE"
echo ""

# 生成 Markdown 报告
cat > "$REPORT_FILE" << EOF
# Collections 内存泄漏验证报告

**生成时间**: $(date)
**测试工具**: Free Pascal HeapTrc
**编译选项**: \`-gh -gl\` (启用堆追踪和行号信息)

---

## 📊 执行摘要

| 指标 | 值 |
|------|----|
| 总测试数 | $TOTAL |
| ✅ 通过 | $PASSED |
| ❌ 失败 | $FAILED |
| 通过率 | $(( PASSED * 100 / TOTAL ))% |

**结论**: $([ $FAILED -eq 0 ] && echo "✅ 所有测试通过，无内存泄漏" || echo "❌ 检测到内存泄漏或测试失败")

---

## 📋 测试结果详情

EOF

# 为每个测试添加详情
for TEST_NAME in "${TESTS[@]}"; do
    LOG_FILE="$LOG_DIR/${TEST_NAME}.log"

    echo "### $TEST_NAME" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    if [ ! -f "$LOG_FILE" ]; then
        echo "⚠️ **状态**: SKIPPED (测试文件不存在)" >> "$REPORT_FILE"
    elif grep -q "0 unfreed memory blocks : 0" "$LOG_FILE" 2>/dev/null; then
        echo "✅ **状态**: PASSED (无内存泄漏)" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "**HeapTrc 输出**:" >> "$REPORT_FILE"
        echo '```' >> "$REPORT_FILE"
        grep -A 5 "Heap dump" "$LOG_FILE" | head -10 >> "$REPORT_FILE" 2>/dev/null || echo "(未找到 HeapTrc 输出)" >> "$REPORT_FILE"
        echo '```' >> "$REPORT_FILE"
    else
        echo "❌ **状态**: FAILED" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "**错误信息**: 请查看日志文件 \`$LOG_FILE\`" >> "$REPORT_FILE"
    fi

    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
done

# 添加报告尾部
cat >> "$REPORT_FILE" << EOF
## 📁 日志文件

所有详细日志保存在: \`$LOG_DIR/\`

- 编译日志和运行输出在各自的 \`.log\` 文件中
- HeapTrc 内存泄漏报告包含在运行输出中

---

## 🔍 如何手动运行单个测试

\`\`\`bash
# 编译
fpc -gh -gl -B -Fu./src -Fi./src -otest_name tests/test_name.pas

# 运行
./test_name

# 检查输出中是否包含:
# "0 unfreed memory blocks : 0"
\`\`\`

---

**报告结束**
EOF

echo "========================================"
echo "Report generated: $REPORT_FILE"
echo "========================================"

# 返回退出码
if [ $FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
