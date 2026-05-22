# fafafa.core.simd 快速参考

> 最后更新：2026-05-23 | 状态：STABLE

本文档是 `fafafa.core.simd` 模块的统一快速参考。面向使用者，不面向维护者。

## 快速开始

```pascal
uses
  fafafa.core.simd;           // 向量操作 + 自动后端选择
  // 或
  fafafa.core.simd.algorithms; // 宽度无关的高级数组操作

var
  a, b, c: TVecF32x4;
  sum: Single;
  data: array[0..255] of Single;
begin
  // 基础向量操作
  a := VecF32x4Splat(1.0);
  b := VecF32x4Splat(2.0);
  c := VecF32x4Add(a, b);    // [3.0, 3.0, 3.0, 3.0]

  // 宽度无关的数组操作（自动选择最宽 SIMD）
  SimdArrayAdd(@data[0], @data[128], @data[0], 128);
  sum := SimdReduceSum(@data[0], 256);
end;
```

## 模块结构

| 单元 | 用途 | 使用场景 |
|------|------|----------|
| `fafafa.core.simd` | 向量操作门面 | 需要显式向量类型操作 |
| `fafafa.core.simd.algorithms` | 宽度无关数组算法 | 批量数据处理，不关心向量宽度 |
| `fafafa.core.simd.api` | 内存/文本工具 | MemEqual, MemFindByte, Utf8Validate |
| `fafafa.core.simd.runtime` | 运行时控制 | 查询/切换后端 |
| `fafafa.core.simd.cpuinfo` | CPU 能力检测 | 查询硬件支持 |

## 向量类型

### 128-bit（SSE2 / NEON 基线）

| 类型 | 元素 | Lane 数 | 掩码类型 |
|------|------|---------|----------|
| `TVecF32x4` | Single | 4 | TMask4 |
| `TVecF64x2` | Double | 2 | TMask2 |
| `TVecI32x4` | Int32 | 4 | TMask4 |
| `TVecI64x2` | Int64 | 2 | TMask2 |

### 256-bit（AVX2）

| 类型 | 元素 | Lane 数 | 掩码类型 |
|------|------|---------|----------|
| `TVecF32x8` | Single | 8 | TMask8 |
| `TVecF64x4` | Double | 4 | TMask4 |
| `TVecI32x8` | Int32 | 8 | TMask8 |
| `TVecI64x4` | Int64 | 4 | TMask4 |

### 512-bit（AVX-512）

| 类型 | 元素 | Lane 数 | 掩码类型 |
|------|------|---------|----------|
| `TVecF32x16` | Single | 16 | TMask16 |
| `TVecF64x8` | Double | 8 | TMask8 |
| `TVecI32x16` | Int32 | 16 | TMask16 |
| `TVecI64x8` | Int64 | 8 | TMask8 |

## 向量操作 API

### 算术

```pascal
function VecF32x4Add(const a, b: TVecF32x4): TVecF32x4;
function VecF32x4Sub(const a, b: TVecF32x4): TVecF32x4;
function VecF32x4Mul(const a, b: TVecF32x4): TVecF32x4;
function VecF32x4Div(const a, b: TVecF32x4): TVecF32x4;
function VecF32x4Min(const a, b: TVecF32x4): TVecF32x4;
function VecF32x4Max(const a, b: TVecF32x4): TVecF32x4;
function VecF32x4Fma(const a, b, c: TVecF32x4): TVecF32x4; // a*b+c
```

所有宽度（x4/x8/x16）和类型（F32/F64/I32/I64/U32/U64）均有对应函数。命名规则：`Vec{Type}{Op}`。

### 比较

```pascal
function VecF32x4CmpEq(const a, b: TVecF32x4): TMask4;
function VecF32x4CmpLt(const a, b: TVecF32x4): TMask4;
function VecF32x4CmpGt(const a, b: TVecF32x4): TMask4;
function VecF32x4CmpLe(const a, b: TVecF32x4): TMask4;
function VecF32x4CmpGe(const a, b: TVecF32x4): TMask4;
function VecF32x4CmpNe(const a, b: TVecF32x4): TMask4;
```

### 归约

```pascal
function VecF32x4ReduceAdd(const a: TVecF32x4): Single;
function VecF32x4ReduceMin(const a: TVecF32x4): Single;
function VecF32x4ReduceMax(const a: TVecF32x4): Single;
function VecF32x4ReduceMul(const a: TVecF32x4): Single;
function VecF32x4Dot(const a, b: TVecF32x4): Single;
```

### 内存

```pascal
function VecF32x4Load(p: PSingle): TVecF32x4;
procedure VecF32x4Store(p: PSingle; const a: TVecF32x4);
function VecF32x4Splat(value: Single): TVecF32x4;
function VecF32x4Zero: TVecF32x4;
```

### 位运算（整数类型）

```pascal
function VecI32x4And(const a, b: TVecI32x4): TVecI32x4;
function VecI32x4Or(const a, b: TVecI32x4): TVecI32x4;
function VecI32x4Xor(const a, b: TVecI32x4): TVecI32x4;
function VecI32x4Not(const a: TVecI32x4): TVecI32x4;
function VecI32x4ShiftLeft(const a: TVecI32x4; count: Integer): TVecI32x4;
function VecI32x4ShiftRight(const a: TVecI32x4; count: Integer): TVecI32x4;
```

### 掩码操作

```pascal
function Mask4Any(mask: TMask4): Boolean;
function Mask4All(mask: TMask4): Boolean;
function Mask4None(mask: TMask4): Boolean;
function Mask4PopCount(mask: TMask4): Integer;
function Mask4FirstSet(mask: TMask4): Integer; // -1 if none
```

## 宽度无关算法层 (fafafa.core.simd.algorithms)

自动选择当前硬件最宽的 SIMD 后端，用户无需关心向量宽度。

### 数组算术

```pascal
procedure SimdArrayAdd(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
procedure SimdArrayMul(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
procedure SimdArrayMulScalar(aSrc, aDst: PSingle; aCount: SizeUInt; aScalar: Single);
procedure SimdArrayAxpy(aAlpha: Single; aX, aY, aDst: PSingle; aCount: SizeUInt);
```

### 归约

```pascal
function SimdReduceSum(aSrc: PSingle; aCount: SizeUInt): Single;
function SimdReduceDot(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
function SimdReduceMin(aSrc: PSingle; aCount: SizeUInt): Single;
function SimdReduceMax(aSrc: PSingle; aCount: SizeUInt): Single;
```

### 内部机制

算法层通过 `TSimdLaneInfo` 探测当前最佳宽度，然后按 256-bit → 128-bit → scalar 的阶梯下降处理数据：

```
if Has256 then process 8 elements at a time (AVX2)
if Has128 then process 4 elements at a time (SSE2/NEON)
scalar tail for remaining elements
```

## 内存/文本工具 (fafafa.core.simd.api)

```pascal
function SimdMemEqual(a, b: Pointer; len: SizeUInt): Boolean;
function SimdMemFindByte(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
procedure SimdMemCopy(src, dst: Pointer; len: SizeUInt);
function SimdUtf8Validate(p: Pointer; len: SizeUInt): Boolean;
```

## 运行时控制

```pascal
// 查询当前后端
function GetActiveBackend: TSimdBackend;
function GetBackendName(backend: TSimdBackend): string;

// 切换后端（测试/诊断用）
function TrySetActiveBackend(backend: TSimdBackend): Boolean;

// 查询后端能力
function IsBackendAvailable(backend: TSimdBackend): Boolean;
function GetRegisteredBackends: TSimdBackendSet;
```

### 后端枚举

```pascal
type TSimdBackend = (
  sbScalar,   // 标量回退（全平台）
  sbSSE2,     // x86-64 基线
  sbSSE3,     // x86-64
  sbSSSE3,    // x86-64
  sbSSE41,    // x86-64
  sbSSE42,    // x86-64
  sbAVX2,     // x86-64 256-bit
  sbAVX512,   // x86-64 512-bit
  sbNEON,     // ARM64 128-bit
  sbRISCVV    // RISC-V V (experimental)
);
```

## 性能特征

| 操作 | 标量 | SSE2 | AVX2 | 加速比 |
|------|------|------|------|--------|
| VecF32x4Add | 4 ops | 1 instr | 1 instr | ~4x |
| VecF32x8Add | 8 ops | 2 instr | 1 instr | ~8x |
| MemEqual (1KB) | byte-by-byte | 16B/iter | 32B/iter | ~10-20x |
| ReduceSum (256) | 256 adds | 64 adds + reduce | 32 adds + reduce | ~6-8x |

## 派发机制

```
用户调用 VecF32x4Add(a, b)
  → inline: 读取全局 dispatch table 指针
  → 间接调用: dispatch^.AddF32x4(a, b)
  → 执行: SSE2/AVX2/NEON 汇编实现
```

热路径开销：~3-7 cycles（atomic_load + 间接调用）。

## 编译与使用

```pascal
// 最小使用
uses fafafa.core.simd;

// 编译
fpc -O3 -Fi./src -Fu./src your_program.pas
```

无需额外编译标志。后端在运行时自动检测并选择最优实现。

## 平台支持

| 平台 | 后端 | 状态 |
|------|------|------|
| Linux x86-64 | Scalar/SSE2/AVX2/AVX-512 | 完全验证 |
| Windows x86-64 | Scalar/SSE2/AVX2/AVX-512 | 完全验证 |
| macOS x86-64 | Scalar/SSE2/AVX2 | 编译验证 |
| Linux ARM64 | Scalar/NEON | QEMU 验证 |
| Linux RISC-V | Scalar/RISCVV | QEMU 验证 (experimental) |
