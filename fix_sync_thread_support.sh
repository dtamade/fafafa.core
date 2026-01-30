#!/bin/bash

# 修复所有 sync 模块的线程支持问题
# 为所有 .lpr 文件添加 cthreads 单元

echo "开始修复 sync 模块的线程支持..."

# 查找所有 sync 模块的 .lpr 文件
find tests/fafafa.core.sync* -name "*.lpr" -type f | while read -r lpr_file; do
    echo "处理: $lpr_file"

    # 检查文件是否已经包含 cthreads
    if grep -q "cthreads" "$lpr_file"; then
        echo "  ✓ 已包含 cthreads，跳过"
        continue
    fi

    # 检查文件是否有 uses 子句
    if ! grep -q "^uses" "$lpr_file"; then
        echo "  ✗ 没有找到 uses 子句，跳过"
        continue
    fi

    # 创建备份
    cp "$lpr_file" "$lpr_file.bak"

    # 使用 awk 在 uses 子句后添加 cthreads
    awk '
    /^uses/ {
        print $0
        print "  {$IFDEF UNIX}"
        print "  cthreads,"
        print "  {$ENDIF}"
        next
    }
    { print }
    ' "$lpr_file.bak" > "$lpr_file"

    echo "  ✓ 已添加 cthreads 单元"
done

echo ""
echo "修复完成！"
echo "备份文件保存为 *.lpr.bak"
