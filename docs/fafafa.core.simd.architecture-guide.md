# fafafa.core.simd 架构指南

> 最后更新：2026-05-23 | 反映当前代码真实状态

## 分层架构

```
┌─────────────────────────────────────────────────────────┐
│  用户代码                                                │
├─────────────────────────────────────────────────────────┤
│  Layer 1: Public Surface                                │
│  fafafa.core.simd          向量操作门面                  │
│  fafafa.core.simd.algorithms  宽度无关算法层             │
│  fafafa.core.simd.api      内存/文本工具                 │
│  fafafa.core.simd.runtime  运行时控制                    │
│  fafafa.core.simd.cpuinfo  CPU 能力检测                  │
├─────────────────────────────────────────────────────────┤
│  Layer 2: Control / Publication Seam                    │
│  fafafa.core.simd.dispatch   控制面（注册/选择/切换）    │
│  fafafa.core.simd.dataplane  数据面（已发布快照）        │
├─────────────────────────────────────────────────────────┤
│  Layer 3: Companion Surfaces                            │
│  fafafa.core.simd.direct     直接派发 companion          │
│  public ABI wrapper          外部 ABI 稳定包装          │
├─────────────────────────────────────────────────────────┤
│  Layer 4: Backend Adapters                              │
│  fafafa.core.simd.scalar     标量参考实现                │
│  fafafa.core.simd.sse2       SSE2 后端                   │
│  fafafa.core.simd.avx2       AVX2 后端                   │
│  fafafa.core.simd.neon       NEON 后端                   │
│  fafafa.core.simd.riscvv     RISC-V V 后端              │
│  ... (sse3/ssse3/sse41/sse42/avx512)                    │
├─────────────────────────────────────────────────────────┤
│  Layer 5: Raw Leaves (ISA Intrinsics)                   │
│  fafafa.core.simd.intrinsics.base    基础类型 TM128      │
│  fafafa.core.simd.intrinsics.x86.sse2  SSE2 raw leaf    │
│  fafafa.core.simd.intrinsics.avx2   AVX2 raw leaf       │
│  fafafa.core.simd.intrinsics.mmx    MMX raw leaf        │
│  fafafa.core.simd.intrinsics.sse    SSE raw leaf        │
│  ... (experimental: neon/rvv/sve/aes/sha/avx/fma3)      │
└─────────────────────────────────────────────────────────┘
```

## 核心设计原则

### 1. 零开销派发

热路径只需一次 atomic_load + 一次间接调用（~3-7 cycles）：

```pascal
function VecF32x4Add(const a, b: TVecF32x4): TVecF32x4; inline;
begin
  Result := GetSimdFacadeDispatchFastPath^.AddF32x4(a, b);
end;
```

### 2. 控制面/数据面分离

- **dispatch.pas**（控制面）：后端注册、优先级排序、强制选择。需要锁保护，不频繁调用。
- **dataplane.pas**（数据面）：维护不可变快照指针。热路径只需 atomic_load，无锁。

这是网络路由器级别的设计模式——控制面变更不阻塞数据面转发。

### 3. 后端继承链

```
Scalar → SSE2 → SSE3 → SSSE3 → SSE4.1 → SSE4.2 → AVX2 → AVX-512
```

每个后端通过 `CloneDispatchTable` 继承上一级的实现，只覆盖它能加速的操作。

### 4. 单元 Disposition 规则

| Disposition | 含义 | 能被 stable adapter 依赖？ |
|-------------|------|---------------------------|
| `active leaf` | 活跃维护，有测试 | ✅ 可以 |
| `experimental isolated` | 默认隔离，需 opt-in | ❌ 不可以 |
| `retire target` | 已确认可删除 | ❌ 不可以 |

## 派发表结构

```pascal
TSimdDispatchTable = record
  Backend: TSimdBackend;
  BackendInfo: TSimdBackendInfo;

  // 558 个函数指针槽位
  AddF32x4: function(const a, b: TVecF32x4): TVecF32x4;
  SubF32x4: function(const a, b: TVecF32x4): TVecF32x4;
  // ... 更多操作
end;
```

### 后端注册

```pascal
initialization
  RegisterSSE2Backend;  // 自动注册，填充 dispatch table
```

每个后端在 `initialization` 段自动注册。运行时根据 CPU 能力选择最优后端。

## 代码生成器 (tools/simdgen)

用于减少 boilerplate 的 Python 代码生成器：

```bash
python3 tools/simdgen/simdgen.py           # 生成 .inc 文件
python3 tools/simdgen/simdgen.py --audit   # 与现有代码做差异审计
```

当前状态：438/558 slots 审计通过，184 个 scalar 函数由生成代码提供。

## 验证体系

```bash
# 日常门禁
bash tests/fafafa.core.simd/BuildOrTest.sh gate

# 严格门禁（发布前）
bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict

# SSE2 结构检查
python3 tests/fafafa.core.simd/check_sse2_structure.py

# 审计
python3 tools/simdgen/simdgen.py --audit
```

## 文件索引

### 核心源码

| 文件 | 行数 | 职责 |
|------|------|------|
| `src/fafafa.core.simd.pas` | ~7500 | 公共门面 |
| `src/fafafa.core.simd.base.pas` | ~500 | 类型定义 |
| `src/fafafa.core.simd.dispatch.pas` | ~2500 | 派发表 + 控制面 |
| `src/fafafa.core.simd.dataplane.pas` | ~200 | 数据面快照 |
| `src/fafafa.core.simd.scalar.pas` | ~5000 | 标量参考实现 |
| `src/fafafa.core.simd.sse2.pas` | ~5000 | SSE2 后端 |
| `src/fafafa.core.simd.avx2.pas` | ~3000 | AVX2 后端 |
| `src/fafafa.core.simd.algorithms.pas` | ~300 | 宽度无关算法 |

### 文档

| 文件 | 用途 |
|------|------|
| `docs/fafafa.core.simd.quickref.md` | 快速参考（本文件的姊妹篇） |
| `docs/fafafa.core.simd.api.md` | 详细 API 文档 |
| `docs/SIMD_INTRINSICS_DISPOSITION.md` | 各 intrinsics 单元状态 |
| `docs/SIMD_BACKEND_TRUTH.md` | 后端真相源表 |
| `docs/SIMD_SSE2_MIGRATION_MAP.md` | SSE2 迁移分桶图 |
