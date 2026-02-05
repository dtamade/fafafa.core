# RISC-V V 后端 ABI 修复报告

## 日期
2026-02-06

## 问题描述

之前尝试使用以下模式实现 RISC-V V 后端函数：

```pascal
function RISCVVAddF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // 假设 ABI: a0 = &Result, a1 = &a, a2 = &b
  vle32.v v0, (a1)
  vle32.v v1, (a2)
  vfadd.vv v0, v0, v1
  vse32.v v0, (a0)
end;
```

**测试结果**: 此模式在 RISC-V 平台上不工作！FPC 对返回 record 类型的函数的 ABI 处理与预期不符。

## 解决方案

采用 **包装函数模式**：

1. **内部 procedure**: 使用 `assembler; nostackframe;`，所有参数通过地址传递
2. **外部 wrapper**: 普通 function，调用内部 procedure

### 转换的函数数量

使用 Python 脚本自动转换了 **288 个函数**。

## 参考

- RISC-V ABI Specification
- RISC-V V Extension Specification

---

**修复者**: Claude (AI 辅助)
**审查状态**: 待人工审查
