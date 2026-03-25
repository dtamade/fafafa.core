# fafafa.core 架构分层文档

本文档定义 `fafafa.core` 当前有效的模块分层。这里的层级定义优先于历史阶段文档。

> 注意：
> `docs/legacy/phase0/PHASE0_*.md` 记录的是历史阶段和 API 冻结语境，不再作为当前 Layer 分配的唯一依据。
> 当前 L0 的详细定义以 `docs/fafafa.core.l0.foundation.md` 为准。

## 分层总览

```text
+------------------------------------------------------------------+
| Layer 3: Applications                                            |
| 用户应用、集成代码、产品层组合逻辑                                |
+------------------------------------------------------------------+
| Layer 2: Features                                                |
| crypto, json, process, socket, fs, archiver, lockfree, ...       |
+------------------------------------------------------------------+
| Layer 1: Core Services                                           |
| simd, math, collections, bytes, io, sync, thread, time,          |
| mem (non-allocator), ...                                         |
+------------------------------------------------------------------+
| Layer 0: Foundation Kernel                                       |
| settings, base, bits, layout, endian, atomic, option, result,    |
| mem.allocator contract                                           |
+------------------------------------------------------------------+
```

分层原则：

- 低层不能依赖高层。
- 同层允许单向依赖，但仍应避免循环依赖。
- L0 不是“先做出来的模块集合”，而是全框架共享的最小基础内核。

## Layer 0: Foundation Kernel

L0 只容纳真正的基础语义、内存模型和分配契约。它必须足够小，但又足够强，能稳定支撑上层模块。

当前 L0 的核心组成：

| 类别 | 单元 | 说明 |
|------|------|------|
| 构建与契约入口 | `fafafa.core.settings.inc` | 统一承载基础宏、契约开关和平台特性开关 |
| 基础语义 | `fafafa.core.base` | 基础类型、异常、函数类型、元组、通用约定 |
| 可空语义 | `fafafa.core.option.base`, `fafafa.core.option` | `Option<T>` 语义与组合子 |
| 结果语义 | `fafafa.core.result`, `fafafa.core.result.facade` | `Result<T, E>` 语义与稳定门面 |
| 位级基础 | `fafafa.core.bits` | 对齐、幂次判断与基础整数布局 helper |
| 布局契约 | `fafafa.core.layout` | `TMemLayout`、`TAllocCaps` 与默认对齐 / cache line / page size 契约 |
| 字节序语义 | `fafafa.core.endian` | endian 枚举、native 解析和 byte-swap |
| 原子与内存模型 | `fafafa.core.atomic.base`, `fafafa.core.atomic.compat`, `fafafa.core.atomic` | 原子操作、内存序、兼容层 |
| 分配契约 | `fafafa.core.mem.allocator.foundation`, `fafafa.core.mem.allocator.base`, `fafafa.core.mem.allocator.rtlAllocator`, `fafafa.core.mem.allocator.callbackAllocator` | `foundation` 是 strict L0 入口，`base + minimal backends` 提供分配器契约与最小实现 |

L0 的明确边界：

- `simd` 不属于 L0。它包含 capability、dispatch、public ABI 和多后端实现，属于核心服务层。
- `math` 不属于 L0。它是领域算法和数值工具层，不是最小语义内核。
- `collections` 不属于 L0。它引入容量策略、迭代器、所有权容器和更复杂的 API 表面。
- `bytes` / `io` / `sync` / `thread` / `time` 不属于 L0。它们已经是面向服务的上层能力。
- `fafafa.core.result.collect` 不属于 L0，因为它依赖 `fafafa.core.collections.vec`。
- `fafafa.core.mem.allocator.mimalloc`、`fafafa.core.mem.allocator.crtAllocator`、`fafafa.core.mem.allocator.instrumentation` 不属于严格 L0，它们是可选后端或调试扩展。

L0 的依赖关系可以概括为：

```text
                 RTL
                  |
      +-----------+-----------+
      |           |           |
 settings.inc    base      atomic.base
      |           |           |
      |       +---+---+       +--> atomic.compat --> atomic
      |       |       |
      |    option   result --> result.facade
      |
      +--> mem.allocator.base --> rtlAllocator / callbackAllocator --> allocator.foundation
```

关于 `mem.allocator` 的现状说明：

- `fafafa.core.mem.allocator.foundation`、`*.base`、`rtlAllocator`、`callbackAllocator` 符合严格 L0 的定位。
- `fafafa.core.mem.allocator.pas` 继续作为兼容 / 扩展门面统一重导出可选后端。
- 因为这个兼容门面会牵出 `mimalloc` 和条件编译的 `crtAllocator`，所以它不应再被当作 strict L0 的唯一入口。
- 当前架构文档把 “分配契约中心” 放在 `allocator.foundation + *.base + minimal backends` 上，而不是把所有 allocator 后端都视作纯 L0。

## Layer 1: Core Services

Layer 1 承载“框架级服务能力”。它可以依赖 L0，但不应反向下沉到 L0。

典型模块：

| 模块族 | 说明 |
|--------|------|
| `fafafa.core.simd*` | 向量能力、runtime dispatch、public ABI、后端选择 |
| `fafafa.core.math*` | 数学函数、安全整数、数值工具 |
| `fafafa.core.collections*` | 容器、序列、容量与迭代抽象 |
| `fafafa.core.bytes*`, `fafafa.core.io*` | 字节视图、读写抽象、缓冲 |
| `fafafa.core.sync*`, `fafafa.core.thread*`, `fafafa.core.time*` | 并发、线程、时间相关服务 |
| `fafafa.core.mem*`（除 allocator contract） | 内存池、管理器、对齐桥接、性能扩展 |

`simd` 在当前架构中明确归 Layer 1，而不是 Layer 0。原因不是它“不重要”，而是它已经承担了比基础内核更多的职责。

## Layer 2: Features

Layer 2 承载更贴近业务或子系统的功能模块。它们通常组合多个 L0/L1 能力形成完整功能。

典型模块：

| 模块族 | 说明 |
|--------|------|
| `fafafa.core.crypto*` | 密码学与加密能力 |
| `fafafa.core.json*` | JSON 解析与序列化 |
| `fafafa.core.process*` | 进程抽象与管理 |
| `fafafa.core.socket*`, `fafafa.core.fs*` | 网络与文件系统 |
| `fafafa.core.archiver*` | 归档、容器格式与压缩组合 |
| `fafafa.core.lockfree*` | 无锁数据结构与高级并发构件 |

## Layer 3: Applications

Layer 3 是框架使用者的应用层、集成层和产品层逻辑。它可以组合下层模块，但不反向影响分层边界。

## 分层规则

### 1. 依赖方向

```text
Layer N 可以依赖 Layer N-1, N-2, ... , Layer 0
Layer N 不能依赖 Layer N+1, N+2, ...
```

### 2. L0 准入规则

一个模块想进入 L0，至少要同时满足以下条件：

- 仅依赖 Free Pascal RTL 和已确认的 L0 单元。
- 提供的是跨框架复用的基础语义、内存模型、布局契约或分配契约。
- 不拥有线程、IO、文件系统、网络、runtime dispatch、容器策略或注册中心。
- API 面足够小，稳定性要求高，适合作为上层长期依赖点。

### 3. 平台与架构实现

- 平台差异优先通过 `.inc` 或低层专用单元承载。
- 平台实现可以进入 L0，但前提是它只是在实现已有基础契约，而不是引入新的服务层语义。

### 4. 接口优先，门面克制

- 跨层交互优先暴露稳定接口、记录或平坦函数。
- 门面单元可以存在，但不能把可选后端和调试扩展伪装成“天然基础层”。

## 变更记录

| 日期 | 变更 | 说明 |
|------|------|------|
| 2026-03-21 | 重新定义 L0 为 Foundation Kernel | 将 `simd` 移出 L0，明确 L0 只承载基础语义、原子内存模型和分配契约 |
| 2026-02-05 | 历史上曾将 `simd` 归入旧 L0 叙述 | 当时主要目的是切断 `simd` 与 `math` 的循环依赖 |
