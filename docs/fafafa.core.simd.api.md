# fafafa.core.simd API 文档

> **模块状态**: ✅ **稳定 (v1.0.0-stable)** | 生产就绪 | 2025-12-27
>
> 本模块已通过全面稳定性审计，可安全用于生产环境。
> 详见 [SIMD_STABILITY_REPORT.md](./SIMD_STABILITY_REPORT.md)

## 概述

`fafafa.core.simd` 是一个跨平台 SIMD 抽象层，支持多后端自动调度。

### 支持的后端

| 后端 | 平台 | 向量宽度 | 优先级 |
|------|------|----------|--------|
| AVX-512 | x86-64 | 512-bit | 100 |
| AVX2 | x86-64 | 256-bit | 50 |
| SSE4.2 | x86-64 | 128-bit | 20 |
| SSE4.1 | x86-64 | 128-bit | 18 |
| SSSE3 | x86-64 | 128-bit | 16 |
| SSE3 | x86-64 | 128-bit | 15 |
| SSE2 | x86-64 | 128-bit | 10 |
| NEON | ARM64 | 128-bit | 30 |
| RISC-V V | RISC-V | 可变 | 25 |
| Scalar | 全平台 | N/A | 1 |

## 设计原则

### 1. Rust 级别代码质量标准

本模块遵循以下质量标准：

- **内存安全**: 所有指针访问都有边界检查
- **对齐安全**: 对齐加载/存储函数包含断言验证
- **线程安全**: 后端切换使用内存屏障保护
- **IEEE 754 兼容**: 正确处理 NaN、Inf、-0.0

### 2. 命名规范

#### 低级向量操作（前缀风格）

```pascal
// 格式: <Backend><Operation><Type>
ScalarAddF32x4(a, b)    // Scalar 后端的 F32x4 加法
SSE2MulF32x4(a, b)      // SSE2 后端的 F32x4 乘法
AVX2DivF32x8(a, b)      // AVX2 后端的 F32x8 除法
```

#### 高级 Facade 操作（后缀风格）

```pascal
// 格式: <Operation>_<Backend>
MemEqual_Scalar(a, b, len)    // Scalar 后端的内存比较
MemCopy_AVX2(src, dst, len)   // AVX2 后端的内存拷贝
Utf8Validate_SSE2(p, len)     // SSE2 后端的 UTF-8 验证
```

这种区分有助于快速识别操作类型。

## 安全要求

### 对齐要求

| 函数 | 对齐要求 | 失败行为 |
|------|----------|----------|
| `LoadF32x4Aligned` | 16 字节 | Assert 失败 |
| `StoreF32x4Aligned` | 16 字节 | Assert 失败 |
| `LoadF32x4` | 无要求 | 正常工作 |
| `StoreF32x4` | 无要求 | 正常工作 |

**示例**:
```pascal
var
  buf: array[0..7] of Single;
  aligned: PSingle;
  v: TVecF32x4;
begin
  // 获取 16 字节对齐地址
  aligned := PSingle((PtrUInt(@buf[0]) + 15) and not PtrUInt(15));

  // 安全: 使用对齐地址
  v := LoadF32x4Aligned(aligned);

  // 安全: 非对齐加载无要求
  v := LoadF32x4(@buf[1]);
end;
```

### 索引边界处理

采用**饱和策略**（Saturation Strategy）而非异常：

```pascal
// 索引 < 0 饱和到 0
Extract(v, -1)   // 返回 v.f[0]

// 索引 > 3 饱和到 3
Extract(v, 99)   // 返回 v.f[3]

// 正常索引
Extract(v, 2)    // 返回 v.f[2]
```

**设计理由**: 性能优先，避免异常开销。

### 空指针处理

| 函数 | nil 指针行为 |
|------|-------------|
| `Utf8Validate(nil, n)` | 返回 `False` |
| `MemEqual(nil, p, n)` | 返回 `False` |
| `MemFindByte(nil, n, x)` | 返回 `-1` |
| `SumBytes(nil, n)` | 返回 `0` |

### 零长度处理

| 函数 | len=0 行为 |
|------|-----------|
| `MemEqual(a, b, 0)` | 返回 `True` |
| `Utf8Validate(p, 0)` | 返回 `True` |
| `MemFindByte(p, 0, x)` | 返回 `-1` |
| `SumBytes(p, 0)` | 返回 `0` |

## IEEE 754 浮点行为

### NaN 传播

```pascal
var a, b, r: TVecF32x4;
begin
  a.f[0] := NaN;
  b.f[0] := 1.0;

  r := AddF32x4(a, b);
  // r.f[0] = NaN  (NaN 传播)

  r := MulF32x4(a, b);
  // r.f[0] = NaN
end;
```

### 无穷大处理

```pascal
// Inf + 1 = Inf
// -Inf + 1 = -Inf
// Inf - Inf = NaN
// 0 * Inf = NaN
// 1 / 0 = Inf
// 1 / -0 = -Inf
```

### Reduction 与特殊值

```pascal
// ReduceAdd([1, NaN, 3, 4]) = NaN
// ReduceMax([1, Inf, 3, 4]) = Inf
// ReduceMin([1, -Inf, 3, 4]) = -Inf
```

## 后端调度

### 自动选择

```pascal
uses fafafa.core.simd;

begin
  InitializeDispatch;  // 自动在 initialization 调用

  // 获取当前后端
  WriteLn(GetActiveBackend);  // sbAVX2, sbSSE2, sbScalar 等
end;
```

### 强制后端

```pascal
// 强制使用特定后端（用于测试）
SetActiveBackend(sbScalar);

// 恢复自动选择
ResetToAutomaticBackend;
```

### 线程安全

后端切换使用内存屏障保护：

```pascal
procedure SetActiveBackend(backend: TSimdBackend);
begin
  g_ForcedBackend := backend;
  g_BackendForced := True;
  WriteBarrier;           // 确保写入可见
  g_DispatchInitialized := False;
  MemoryBarrier;          // 完整屏障
  InitializeDispatch;
end;
```

## 使用示例

### 基础向量运算

```pascal
uses fafafa.core.simd;

var
  a, b, c: TVecF32x4;
  dt: PSimdDispatchTable;
begin
  dt := GetDispatchTable;

  a := dt^.SplatF32x4(1.0);
  b := dt^.SplatF32x4(2.0);
  c := dt^.AddF32x4(a, b);

  WriteLn(dt^.ExtractF32x4(c, 0));  // 输出: 3.0
end;
```

### 内存操作

```pascal
var
  buf1, buf2: array[0..1023] of Byte;
  dt: PSimdDispatchTable;
begin
  dt := GetDispatchTable;

  // 内存比较
  if dt^.MemEqual(@buf1[0], @buf2[0], 1024) then
    WriteLn('相等');

  // 查找字节
  idx := dt^.MemFindByte(@buf1[0], 1024, $FF);

  // UTF-8 验证
  if dt^.Utf8Validate(@buf1[0], 1024) then
    WriteLn('有效 UTF-8');
end;
```

### 新接口（TSimdBackendOps）

```pascal
uses
  fafafa.core.simd.backend.iface,
  fafafa.core.simd.backend.adapter;

var
  ops: TSimdBackendOps;
  a, b, c: TVecF32x4;
begin
  FillScalarOps(ops);

  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 0.5; b.f[1] := 1.0; b.f[2] := 1.5; b.f[3] := 2.0;

  c := ops.ArithmeticF32x4.Add(a, b);
  // c = [1.5, 3.0, 4.5, 6.0]
end;
```

## AVX/SSE 状态管理

### vzeroupper 要求

使用 YMM 寄存器（256位 AVX）后必须调用 `vzeroupper`：

```pascal
// 正确示例
function MyAVX2Function: Integer;
var usedYMM: Boolean;
begin
  usedYMM := False;

  if dataLen >= 32 then
  begin
    usedYMM := True;
    asm
      vmovdqu ymm0, [rax]  // 使用 YMM
      // ...
    end;
  end;

  // 所有退出路径都要清理
  if usedYMM then
    asm vzeroupper end;

  Result := 0;
end;
```

## 测试覆盖

| 测试类型 | 测试数 | 状态 |
|----------|--------|------|
| 主测试套件 | 380 | ✅ 全部通过 |
| 边界测试 | 44 | ✅ 全部通过 |
| 后端操作测试 | 15 | ✅ 全部通过 |
| 内存泄漏 | 0 | ✅ 无泄漏 |

运行测试:
```bash
# 主测试
./tests/fafafa.core.simd/bin/fafafa.core.simd.test

# 边界测试
./tests/fafafa.core.simd/bin/test_simd_boundary

# 后端操作测试
./tests/fafafa.core.simd/bin/test_backend_ops
```

## 版本历史

### v1.0.0-stable (2025-12-27)

**稳定性里程碑**:
- ✅ 通过全面稳定性审计
- ✅ 10 个后端运行时检测一致性验证
- ✅ 三态原子初始化线程安全性验证
- ✅ Dispatch table 完整性验证机制
- ✅ 439 个测试全部通过，0 内存泄漏

**新增后端**:
- SSE3 (水平运算优化)
- SSSE3 (字节混洗)
- SSE4.1 (扩展混合/舍入)
- SSE4.2 (字符串/CRC32)
- RISC-V V (向量扩展)

**新增功能**:
- `ValidateDispatchTable()` - Dispatch table 完整性验证
- `AssertDispatchTableValid()` - DEBUG 构建断言
- `CloneDispatchTable()` - 后端继承机制

**修复**:
- SSE3 `DotF32x3` 移除 SSE4.1 指令依赖
- SSE4.2 变量名与 x86 寄存器冲突

### v0.9.0 (2025-12)

- Rust 级别代码质量重构
- 添加对齐断言
- 实现索引饱和策略
- 修复 vzeroupper 问题
- 添加内存屏障
- 创建边界测试套件
