# ARM NEON 性能测试指南

本文档说明如何在 ARM 设备上测试 NEON SIMD 后端的性能。

## 方法一：在真实 ARM 设备上测试

### 支持的设备
- Apple Silicon Mac (M1/M2/M3)
- Raspberry Pi 4/5 (AArch64)
- Android 设备 (需要 Termux + FPC)
- ARM 服务器 (AWS Graviton, Ampere)

### 步骤

1. **安装 Free Pascal 编译器**
   ```bash
   # Raspberry Pi / Debian ARM64
   sudo apt install fpc
   
   # macOS (Homebrew)
   brew install fpc
   ```

2. **交叉编译（可选）**
   如果在 x86 机器上编译 ARM 二进制：
   ```bash
   # 安装 ARM64 交叉编译器
   fpcupdeluxe --os=linux --cpu=aarch64
   
   # 编译项目
   fpc -Paarch64 -Tlinux fafafa.core.simd.test.lpr
   ```

3. **运行测试**
   ```bash
   cd tests/fafafa.core.simd
   ./bin/fafafa.core.simd.test --all --format=plain
   ```

## 方法二：使用 QEMU 模拟

QEMU 可以在 x86 机器上模拟 ARM64，用于验证正确性（性能数据不准确）。

### 安装 QEMU
```bash
# Ubuntu/Debian
sudo apt install qemu-user qemu-user-static

# 安装 ARM64 libc（用于动态链接）
sudo apt install libc6-arm64-cross
```

### 使用 QEMU 运行
```bash
# 运行 ARM64 二进制
qemu-aarch64 -L /usr/aarch64-linux-gnu ./bin/fafafa.core.simd.test --all

# 或使用静态链接的二进制
qemu-aarch64-static ./bin/fafafa.core.simd.test --all
```

### 注意事项
- QEMU 模拟比原生运行慢 10-100 倍
- 性能基准测试结果不可信
- 主要用于功能验证

## 方法三：GitHub Actions ARM64 Runner

GitHub 提供 ARM64 runners，可用于 CI/CD 测试。

```yaml
# .github/workflows/arm-test.yml
name: ARM64 Tests
on: [push, pull_request]
jobs:
  test-arm64:
    runs-on: ubuntu-24.04-arm
    steps:
      - uses: actions/checkout@v4
      - name: Install FPC
        run: sudo apt-get install -y fpc
      - name: Build
        run: |
          cd tests/fafafa.core.simd
          fpc fafafa.core.simd.test.lpr
      - name: Test
        run: ./tests/fafafa.core.simd/fafafa.core.simd.test --all
```

## 预期性能

基于 NEON 128 位向量寄存器，预期相对于 scalar 的加速比：

| 操作 | 预期加速比 |
|------|-----------|
| F32x4 算术 | 3-4x |
| 内存比较 (MemEqual) | 8-16x |
| 字节求和 (SumBytes) | 8-16x |
| 字节计数 (CountByte) | 8-16x |
| 向量数学 (Dot/Length) | 2-3x |

实际性能取决于：
- 内存带宽
- 缓存命中率
- CPU 流水线效率
- 数据对齐

## NEON 后端实现状态

### 已实现 (真正的 AArch64 汇编)
- ✅ F32x4/F64x2/I32x4 算术 (fadd, fsub, fmul, fdiv)
- ✅ F32x8 (2x 128-bit NEON)
- ✅ 比较操作 (fcmeq, fcmlt, fcmle, fcmgt, fcmge)
- ✅ 规约 (faddp, fminp, fmaxp)
- ✅ 数学函数 (fabs, fsqrt, fmin, fmax, fma, frecpe, frsqrte)
- ✅ 取整 (frintm, frintp, frintn, frintz)
- ✅ 向量数学 (Dot, Cross, Length, Normalize)
- ✅ 内存操作 (Load, Store, Splat, Zero, Extract, Insert)
- ✅ 选择 (bsl)
- ✅ Facade: MemEqual, SumBytes, CountByte, MemFindByte

### Scalar Fallback (非 AArch64 平台)
所有函数都有 Pascal 标量实现作为后备。

## 调试技巧

### 检查活跃后端
```pascal
uses fafafa.core.simd.dispatch;

WriteLn('Active Backend: ', Ord(GetActiveBackend));
// 3 = sbNEON
```

### 强制使用特定后端
```pascal
SetActiveBackend(sbNEON);   // 强制 NEON
SetActiveBackend(sbScalar); // 强制 Scalar
ResetToAutomaticBackend;    // 恢复自动选择
```

### 比较不同后端性能
```pascal
// 测试 Scalar
SetActiveBackend(sbScalar);
MeasurePerformance('Scalar');

// 测试 NEON
SetActiveBackend(sbNEON);
MeasurePerformance('NEON');
```
