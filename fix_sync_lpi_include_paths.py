#!/usr/bin/env python3
"""
修复所有 sync 模块的 .lpi 文件，添加 include 路径
"""

import os
import re
import sys
from pathlib import Path

def fix_lpi_file(lpi_path):
    """修复单个 .lpi 文件的 include 路径"""
    try:
        with open(lpi_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 检查是否已经有正确的 include 路径
        if '<IncludeFiles Value="../../src"/>' in content:
            return False, "已有正确的 include 路径"

        # 查找所有 <SearchPaths> 块并修复
        fixed = False
        lines = content.split('\n')
        new_lines = []

        for i, line in enumerate(lines):
            new_lines.append(line)

            # 如果找到 <IncludeFiles Value=""/> 或 <IncludeFiles Value="..."/>
            if '<IncludeFiles Value=' in line and '../../src' not in line:
                # 替换为正确的路径
                new_line = re.sub(
                    r'<IncludeFiles Value="[^"]*"/>',
                    '<IncludeFiles Value="../../src"/>',
                    line
                )
                new_lines[-1] = new_line
                fixed = True

        if fixed:
            # 写回文件
            new_content = '\n'.join(new_lines)
            with open(lpi_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True, "已修复"
        else:
            return False, "未找到需要修复的 IncludeFiles 标签"

    except Exception as e:
        return False, f"错误: {str(e)}"

def main():
    """主函数"""
    # 查找所有 sync 模块的 .lpi 文件
    tests_dir = Path('/home/dtamade/projects/fafafa.core/tests')
    lpi_files = list(tests_dir.glob('fafafa.core.sync*/**/*.lpi'))

    print(f"找到 {len(lpi_files)} 个 sync 模块的 .lpi 文件")
    print()

    fixed_count = 0
    skipped_count = 0
    error_count = 0

    for lpi_file in sorted(lpi_files):
        rel_path = lpi_file.relative_to(tests_dir.parent)
        fixed, message = fix_lpi_file(lpi_file)

        if fixed:
            print(f"✓ 已修复: {rel_path}")
            fixed_count += 1
        elif "已有正确的 include 路径" in message:
            print(f"○ 跳过: {rel_path} ({message})")
            skipped_count += 1
        else:
            print(f"✗ 错误: {rel_path} ({message})")
            error_count += 1

    print()
    print(f"总结:")
    print(f"  已修复: {fixed_count}")
    print(f"  已跳过: {skipped_count}")
    print(f"  错误: {error_count}")
    print(f"  总计: {len(lpi_files)}")

if __name__ == '__main__':
    main()
