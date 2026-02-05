#!/usr/bin/env python3
"""
RISC-V V ABI 正确修复脚本
"""

import re
import sys

def fix_riscvv_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 找到 RISCVV_ASSEMBLY 块
    assembly_start = content.find('{$IFDEF RISCVV_ASSEMBLY}')
    assembly_end = content.find('{$ELSE}', assembly_start)

    if assembly_start == -1 or assembly_end == -1:
        print("Error: Cannot find RISCVV_ASSEMBLY block")
        return

    before = content[:assembly_start]
    assembly_block = content[assembly_start:assembly_end]
    after = content[assembly_end:]

    # 修复模式:
    # 1. 双参数函数: function XXX(const a, b: T): T; assembler; nostackframe;
    #    -> procedure _XXX_ASM(const a, b: T; var r: T); + function XXX wrapper

    # 修复 vsetivli 参数 (符号 -> 数值)
    # e32, m1, ta, ma = 0xD0
    # e64, m1, ta, ma = 0xD8
    # e32, m2, ta, ma = 0xD1
    # e64, m2, ta, ma = 0xD9
    # e32, m4, ta, ma = 0xD2

    assembly_block = re.sub(
        r'vsetivli\s+zero,\s*(\d+),\s*e32,\s*m1,\s*ta,\s*ma',
        r'vsetivli zero, \1, 0xD0',
        assembly_block
    )
    assembly_block = re.sub(
        r'vsetivli\s+zero,\s*(\d+),\s*e64,\s*m1,\s*ta,\s*ma',
        r'vsetivli zero, \1, 0xD8',
        assembly_block
    )
    assembly_block = re.sub(
        r'vsetivli\s+zero,\s*(\d+),\s*e32,\s*m2,\s*ta,\s*ma',
        r'vsetivli zero, \1, 0xD1',
        assembly_block
    )
    assembly_block = re.sub(
        r'vsetivli\s+zero,\s*(\d+),\s*e64,\s*m2,\s*ta,\s*ma',
        r'vsetivli zero, \1, 0xD9',
        assembly_block
    )
    assembly_block = re.sub(
        r'vsetivli\s+zero,\s*(\d+),\s*e32,\s*m4,\s*ta,\s*ma',
        r'vsetivli zero, \1, 0xD2',
        assembly_block
    )

    # 修复错误的寄存器映射
    # 之前错误地改成了 a2/a0，需要改回 a0/a1/a2

    # 对于 procedure _XXX_ASM(const a, b: T; var r: T):
    # 正确的是: a0=&a, a1=&b, a2=&r
    # 所以: vle32.v v0, (a0); vle32.v v1, (a1); vse32.v v0, (a2)

    # 找到所有错误的模式并修复
    # 错误: vle32.v v0, (a2) ... vle32.v v1, (a0) ... vse32.v v0, (a2)
    # 正确: vle32.v v0, (a0) ... vle32.v v1, (a1) ... vse32.v v0, (a2)

    # 修复双参数函数的加载顺序
    def fix_binary_op(match):
        full = match.group(0)
        # 替换错误的寄存器
        full = re.sub(r'vle32\.v\s+v0,\s*\(a2\)', 'vle32.v v0, (a0)', full)
        full = re.sub(r'vle32\.v\s+v1,\s*\(a0\)', 'vle32.v v1, (a1)', full)
        full = re.sub(r'vle64\.v\s+v0,\s*\(a2\)', 'vle64.v v0, (a0)', full)
        full = re.sub(r'vle64\.v\s+v1,\s*\(a0\)', 'vle64.v v1, (a1)', full)
        return full

    # 找到所有 procedure _RVV*_ASM 并修复
    assembly_block = re.sub(
        r'(procedure\s+_RVV.*?_ASM.*?end;)',
        fix_binary_op,
        assembly_block,
        flags=re.DOTALL
    )

    result = before + assembly_block + after

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(result)

    print(f"Fixed {filepath}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: fix_riscvv_correct.py <file>")
        sys.exit(1)
    fix_riscvv_file(sys.argv[1])
