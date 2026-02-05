# RISC-V Vector ABI 修复 - 快速参考

## 修复前后对比

### 双参数函数

**修复前 (错误)**:
```asm
function RISCVVAddF32x4(const a, b: TVecF32x4): TVecF32x4;
asm
  vle32.v v0, (a0)    // ❌ 错误: 从 a0 加载
  vle32.v v1, (a1)    // ❌ 错误: 从 a1 加载
  vfadd.vv v0, v0, v1
  vse32.v v0, (a0)    // ❌ 错误: 覆盖 a0
end;
```

**修复后 (正确)**:
```asm
function RISCVVAddF32x4(const a, b: TVecF32x4): TVecF32x4;
asm
  // RISC-V ABI: a0 = &Result, a1 = &a, a2 = &b
  vle32.v v0, (a1)    // ✅ 正确: 从 a1 加载参数 a
  vle32.v v1, (a2)    // ✅ 正确: 从 a2 加载参数 b
  vfadd.vv v0, v0, v1
  vse32.v v0, (a0)    // ✅ 正确: 存储到 Result
end;
```

### 单参数函数

**修复前 (错误)**:
```asm
function RISCVVAbsF32x4(const a: TVecF32x4): TVecF32x4;
asm
  vle32.v v0, (a0)    // ❌ 错误: 假设 a0 是参数 a
  vfabs.v v0, v0
  vse32.v v0, (a0)    // ❌ 错误: 覆盖 a0
end;
```

**修复后 (正确)**:
```asm
function RISCVVAbsF32x4(const a: TVecF32x4): TVecF32x4;
asm
  // RISC-V ABI: a0 = &Result, a1 = &a
  vle32.v v0, (a1)    // ✅ 正确: 从 a1 加载参数 a
  vfabs.v v0, v0
  vse32.v v0, (a0)    // ✅ 正确: 存储到 Result
end;
```

### 三参数函数

**修复前 (错误)**:
```asm
function RISCVVFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;
asm
  vle32.v v0, (a0)      // ❌ 错误
  vle32.v v1, (a1)      // ❌ 错误
  vle32.v v2, (a2)      // ❌ 错误
  vfmadd.vv v0, v1, v2
  vse32.v v0, (a0)      // ❌ 错误
end;
```

**修复后 (正确)**:
```asm
function RISCVVFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;
asm
  // RISC-V ABI: a0 = &Result, a1 = &a, a2 = &b, a3 = &c
  vle32.v v0, (a1)      // ✅ 正确: 参数 a
  vle32.v v1, (a2)      // ✅ 正确: 参数 b
  vle32.v v2, (a3)      // ✅ 正确: 参数 c
  vfmadd.vv v0, v1, v2
  vse32.v v0, (a0)      // ✅ 正确: 存储到 Result
end;
```

## ABI 规则总结

### 复合类型返回值 (TVec*)

| 参数数量 | 正确的寄存器分配 |
|---------|----------------|
| 0 参数 | `a0 = &Result` |
| 1 参数 | `a0 = &Result, a1 = &a` |
| 2 参数 | `a0 = &Result, a1 = &a, a2 = &b` |
| 3 参数 | `a0 = &Result, a1 = &a, a2 = &b, a3 = &c` |

### 标量类型返回值 (TMask*)

| 参数数量 | 正确的寄存器分配 |
|---------|----------------|
| 1 参数 | `a0 = &a, 返回值在 a0 (标量)` |
| 2 参数 | `a0 = &a, a1 = &b, 返回值在 a0 (标量)` |

**注意**: 标量返回值会覆盖 a0，这是正确的行为。

## 修复统计

- **总函数数**: 820 个
- **TVec* 返回**: 574 个 (已修复寄存器映射)
- **TMask* 返回**: 246 个 (仅添加注释)
- **编译错误**: 0
- **修复时间**: < 1 秒 (自动化脚本)

## 关键要点

1. ✅ **隐式返回指针**: 复合类型返回值通过 a0 传递的隐式指针
2. ✅ **参数移位**: 实际参数从 a1 开始，不是 a0
3. ✅ **不覆盖输入**: 结果写入 a0，保持输入参数不变
4. ✅ **标准兼容**: 符合 RISC-V 官方 ABI 标准

## 工具使用

```bash
# 修复 TVec* 函数
python3 fix_riscvv_abi_manual.py

# 添加 TMask* 注释
python3 fix_riscvv_tmask.py

# 验证编译
/opt/fpcupdeluxe/fpcsrc/compiler/ppcrossrv64_v -CpRV64GCV \
  -XPriscv64-linux-gnu- -dSIMD_BACKEND_RISCVV \
  src/fafafa.core.simd.riscvv.pas
```

## 参考资料

- [RISC-V Calling Convention](https://riscv.org/wp-content/uploads/2015/01/riscv-calling.pdf)
- [详细修复报告](archive/reports/issues/RISCVV_ABI_FIX_REPORT.md)
