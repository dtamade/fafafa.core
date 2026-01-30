#!/bin/bash
#
# 清理测试产生的孤儿目录
# Issue #9: 清理测试孤儿目录
#
# 用法:
#   bash tests/cleanup_orphan_dirs.sh        # 预览模式（不删除）
#   bash tests/cleanup_orphan_dirs.sh --run  # 实际删除
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

DRY_RUN=1
if [[ "$1" == "--run" ]]; then
    DRY_RUN=0
fi

echo "=== 测试孤儿目录清理工具 ==="
echo "项目根目录: $PROJECT_ROOT"
echo ""

# 查找孤儿目录模式
ORPHAN_PATTERNS=(
    "copytree_*"
    "movetree_*"
    "removetree_*"
    "tmp_*"
    "*.tmp"
    "test_output_*"
    "_tmp*"
)

TOTAL_COUNT=0
TOTAL_SIZE=0

for pattern in "${ORPHAN_PATTERNS[@]}"; do
    echo "--- 模式: $pattern ---"

    # 查找匹配目录
    FOUND=0
    while IFS= read -r -d '' dir; do
        FOUND=1
        SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1 || echo "?")
        echo "  $dir ($SIZE)"
        ((TOTAL_COUNT++)) || true

        if [[ $DRY_RUN -eq 0 ]]; then
            rm -rf "$dir"
            echo "    [已删除]"
        fi
    done < <(find "$SCRIPT_DIR" -type d -name "$pattern" -print0 2>/dev/null)

    if [[ $FOUND -eq 0 ]]; then
        echo "  (无匹配)"
    fi
done

echo ""
echo "=== 汇总 ==="
echo "发现孤儿目录: $TOTAL_COUNT 个"

if [[ $DRY_RUN -eq 1 ]]; then
    echo ""
    echo "当前为预览模式。要实际删除，请运行:"
    echo "  bash tests/cleanup_orphan_dirs.sh --run"
else
    echo "已清理: $TOTAL_COUNT 个目录"
fi
