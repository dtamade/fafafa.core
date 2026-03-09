# fafafa.core.simd - 现代 SIMD 框架

高性能、跨平台的 SIMD (单指令多数据) 向量运算框架，为 FreePascal 提供类似 Rust portable-simd 的 API。

## 先看什么

如果你是第一次进入这个模块，建议按下面顺序读：

- **想直接使用公开 API**：先看 `docs/fafafa.core.simd.api.md`，再看 `examples/simd_ops_demo.lpr`
- **想理解模块全貌**：看 `docs/fafafa.core.simd.md`
- **想维护或修改实现**：看 `docs/fafafa.core.simd.map.md`、`docs/fafafa.core.simd.maintenance.md`、`docs/fafafa.core.simd.checklist.md`
- **想知道当前稳定边界**：看 `docs/fafafa.core.simd.handoff.md` 与 `src/fafafa.core.simd.STABLE`
- **想快速看这轮收尾结果和回归矩阵**：看 `docs/fafafa.core.simd.closeout.md`

有两个文件需要特别区分：

- `src/fafafa.core.simd.architecture.md`：当前实现导向的架构说明，适合维护者阅读
- `src/fafafa.core.simd.next-steps.md`：历史草案，保留是为了追溯背景，不应再作为当前 API / 架构真相源

## 示例入口

- `examples/simd_ops_demo.lpr`：更接近真实公开 API 的使用方式，适合作为入门示例
- `examples/example_simd_dispatch.pas`：概念演示（conceptual demo），用来解释“按 CPU 特性挑选实现”的思路，不代表真实后端注册或派发接线方式

## Stable / Experimental 边界

先看结论：`fafafa.core.simd` 的**公开 façade / ABI** 可以按稳定入口来理解，但**后端成熟度并不完全相同**。

- **稳定面**：`fafafa.core.simd` / `fafafa.core.simd.api` 对外暴露的公开 façade，以及 `TSimdDispatchTable` 这类已明确写入稳定约束的 ABI 边界
- **后端成熟度有差异**：`Scalar`、`SSE2`、`AVX2`、`NEON` 更接近当前默认维护主线；`AVX-512` 受构建配置和验证范围影响；`sbRISCVV` 仍应视为 experimental / 受限成熟度后端
- **`sbRISCVV` 现在是显式 opt-in**：即使平台满足，`fafafa.core.simd` 也不会默认接线 `riscvv`；只有定义 `SIMD_EXPERIMENTAL_RISCVV` 时才会把它接入 umbrella unit
- **experimental intrinsics 默认隔离**：实验性 intrinsics 已有默认入口隔离检查，不属于默认 stable surface；默认入口链路不会把这些实验单元直接暴露成常规公开入口

这意味着：**可以把公开 API 当成稳定入口使用，但不要把每个 backend 都默认理解成同等成熟、同等验证深度。**

## 特性

- **多后端支持**: Scalar / SSE2 / SSE3 / SSSE3 / SSE4.1 / SSE4.2 / AVX2 / AVX-512 / ARM NEON
- **自动派发**: 运行时检测 CPU 特性，自动选择最优后端
- **零开销抽象**: 内联函数 + 函数指针表，无额外运行时开销
- **类型安全**: 强类型向量，编译期防止类型混用
- **Rust 风格别名**: `f32x4`, `i32x8` 等便捷类型别名

## 快速开始

```pascal
uses fafafa.core.simd;

var
  a, b, c: TVecF32x4;  // 或使用 f32x4 别名
begin
  // 创建向量
  a := VecF32x4Splat(1.5);     // [1.5, 1.5, 1.5, 1.5]
  b := VecF32x4Splat(2.0);     // [2.0, 2.0, 2.0, 2.0]

  // 算术运算
  c := VecF32x4Add(a, b);      // [3.5, 3.5, 3.5, 3.5]
  c := VecF32x4Mul(a, b);      // [3.0, 3.0, 3.0, 3.0]

  // 聚合运算
  WriteLn(VecF32x4ReduceAdd(c));  // 输出: 12.0
end;
```

## 向量类型

### 128-bit 向量
| 类型 | 别名 | 元素类型 | 元素数 |
|------|------|----------|--------|
| TVecF32x4 | f32x4 | Single | 4 |
| TVecF64x2 | f64x2 | Double | 2 |
| TVecI32x4 | i32x4 | Int32 | 4 |
| TVecI64x2 | i64x2 | Int64 | 2 |
| TVecI16x8 | i16x8 | Int16 | 8 |
| TVecI8x16 | i8x16 | Int8 | 16 |

### 256-bit 向量 (AVX)
| 类型 | 别名 | 元素类型 | 元素数 |
|------|------|----------|--------|
| TVecF32x8 | f32x8 | Single | 8 |
| TVecF64x4 | f64x4 | Double | 4 |
| TVecI32x8 | i32x8 | Int32 | 8 |

### 512-bit 向量 (AVX-512)
| 类型 | 别名 | 元素类型 | 元素数 |
|------|------|----------|--------|
| TVecF32x16 | f32x16 | Single | 16 |
| TVecF64x8 | f64x8 | Double | 8 |
| TVecI32x16 | i32x16 | Int32 | 16 |

## API 概览

### 算术运算
```pascal
VecF32x4Add(a, b)    // 加法
VecF32x4Sub(a, b)    // 减法
VecF32x4Mul(a, b)    // 乘法
VecF32x4Div(a, b)    // 除法
VecF32x4Fma(a, b, c) // 融合乘加: a*b + c
```

### 比较运算
```pascal
VecF32x4CmpEq(a, b)  // 相等，返回 TMask4
VecF32x4CmpLt(a, b)  // 小于
VecF32x4CmpLe(a, b)  // 小于等于
VecF32x4CmpGt(a, b)  // 大于
VecF32x4CmpGe(a, b)  // 大于等于
VecF32x4CmpNe(a, b)  // 不等
```

### 数学函数
```pascal
VecF32x4Abs(a)           // 绝对值
VecF32x4Sqrt(a)          // 平方根
VecF32x4Min(a, b)        // 逐元素最小值
VecF32x4Max(a, b)        // 逐元素最大值
VecF32x4Clamp(a, lo, hi) // 钳位
VecF32x4Floor(a)         // 向下取整
VecF32x4Ceil(a)          // 向上取整
VecF32x4Round(a)         // 四舍五入
```

### 聚合/归约
```pascal
VecF32x4ReduceAdd(a)  // 水平求和
VecF32x4ReduceMin(a)  // 水平最小值
VecF32x4ReduceMax(a)  // 水平最大值
VecF32x4ReduceMul(a)  // 水平求积
```

### 向量数学 (3D/4D)
```pascal
VecF32x4Dot(a, b)       // 4元素点积
VecF32x3Dot(a, b)       // 3元素点积 (忽略 w)
VecF32x3Cross(a, b)     // 叉积
VecF32x4Length(a)       // 向量长度
VecF32x4Normalize(a)    // 归一化
```

### 饱和算术
```pascal
VecI8x16SatAdd(a, b)  // 有符号 8-bit 饱和加法
VecI8x16SatSub(a, b)  // 有符号 8-bit 饱和减法
VecU8x16SatAdd(a, b)  // 无符号 8-bit 饱和加法
VecU8x16SatSub(a, b)  // 无符号 8-bit 饱和减法
VecI16x8SatAdd(a, b)  // 有符号 16-bit 饱和加法
VecI16x8SatSub(a, b)  // 有符号 16-bit 饱和减法
```

### 内存操作
```pascal
VecF32x4Load(p)             // 加载 (非对齐)
VecF32x4LoadAligned(p)      // 加载 (16字节对齐)
VecF32x4Store(p, v)         // 存储 (非对齐)
VecF32x4StoreAligned(p, v)  // 存储 (16字节对齐)
```

### Mask 操作
```pascal
Mask4All(mask)      // 所有位都为 true?
Mask4Any(mask)      // 任意位为 true?
Mask4None(mask)     // 所有位都为 false?
Mask4PopCount(mask) // 为 true 的位数
Mask4FirstSet(mask) // 第一个为 true 的索引
```

## 后端管理

```pascal
// 获取当前后端
backend := GetActiveBackend;  // 返回 TSimdBackend 枚举

// 强制使用特定后端
SetActiveBackend(sbAVX2);

// 查询当前二进制里真正可派发的后端（CPU 支持 + 已注册 + 标记可用）
backends := GetAvailableBackendList;
backends := GetDispatchableBackendList;  // 语义更明确的等价入口

// 查询 CPU/OS 支持的后端（不保证当前二进制一定会选中它）
backends := GetSupportedBackendList;
backends := GetAvailableBackends;  // cpuinfo 语义：supported-on-cpu

// 获取后端信息
info := GetBackendInfo(sbSSE2);
WriteLn(info.Name);          // 'SSE2'
WriteLn(info.Description);   // 'x86-64 SSE2 SIMD implementation'
```

## 对齐内存分配

```pascal
var
  p: PSingle;
begin
  // 分配 16 字节对齐内存
  p := AlignedAlloc(SizeOf(Single) * 4, 16);
  try
    VecF32x4StoreAligned(p, v);
  finally
    AlignedFree(p);
  end;
end;
```

## 高级：门面函数

SIMD 加速的内存/字符串操作：

```pascal
// 内存操作
MemEqual(a, b, len)        // 快速内存比较
MemFindByte(p, len, val)   // 查找字节
MemCopy(src, dst, len)     // 内存复制
MemSet(dst, len, val)      // 内存填充

// 字符串操作
Utf8Validate(p, len)       // UTF-8 验证
ToLowerAscii(p, len)       // ASCII 转小写
ToUpperAscii(p, len)       // ASCII 转大写
AsciiIEqual(a, b, len)     // ASCII 忽略大小写比较

// 统计操作
SumBytes(p, len)           // 字节求和
CountByte(p, len, val)     // 计数特定字节
BitsetPopCount(p, len)     // 位集合 popcount
```

## 性能提示

1. **使用对齐内存**: 16/32/64 字节对齐可提高 10-20% 性能
2. **避免频繁后端切换**: 后端切换有少量开销
3. **批量操作**: SIMD 在批量数据上效果最佳
4. **注意数据依赖**: 避免连续操作间的数据依赖

## 架构

```
┌─────────────────────────────────────────┐
│     高级 API (fafafa.core.simd.pas)     │  ← 用户接口
├─────────────────────────────────────────┤
│   派发层 (fafafa.core.simd.dispatch)    │  ← 运行时后端选择
├─────────────────────────────────────────┤
│  后端实现层 (scalar/sse2/avx2/neon...)  │  ← 硬件特定优化
├─────────────────────────────────────────┤
│   基础设施层 (base/cpuinfo/memutils)    │  ← 类型定义、工具
└─────────────────────────────────────────┘
```

详细架构设计参见 `src/fafafa.core.simd.architecture.md`。

## 代码组织

当前代码组织采用“主单元 + include 片段”的方式收口大文件：

- `fafafa.core.simd.pas` 已拆出 `types` / `framework` 相关 include，保持对外 API 不变。
- `fafafa.core.simd.dispatch.pas` 已拆出 hook 管理；`fafafa.core.simd.cpuinfo.pas` 已拆出 backend 选择逻辑。
- `AVX2`、`AVX-512`、`NEON` 的 register / facade / family / fallback 区块已经按注释边界拆出。
- `SSE2` 仍然保留更多主体实现；这是有意为之，因为它已经接近“继续物理拆分风险大于收益”的边界。

如果你要理解当前实现，建议先从 `fafafa.core.simd.pas`、`fafafa.core.simd.dispatch.pas`、`fafafa.core.simd.cpuinfo.pas` 读起，再看各 backend 的 `*.register.inc` 和 `*.facade.inc`。

更偏维护视角的说明，见 `docs/fafafa.core.simd.maintenance.md`；更短的阅读地图见 `docs/fafafa.core.simd.map.md`。



## 许可证

与 fafafa.core 主项目相同。
