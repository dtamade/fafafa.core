# fafafa.core.layout — 布局契约与分配能力描述

> 当前 strict L0 边界以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准；后续推进顺序以 `docs/fafafa.core.l0.roadmap.md` 为准。
> `fafafa.core.layout` 属于 strict non-SIMD L0，负责跨 allocator / bytes / collections 共享的布局合同。

## 当前 source-of-truth

1. `docs/fafafa.core.l0.foundation.md`
2. `docs/fafafa.core.l0.roadmap.md`
3. `docs/ARCHITECTURE_LAYERS.md`
4. `src/fafafa.core.layout.pas`
5. `tests/fafafa.core.layout/README.md`
6. `tests/fafafa.core.layout/BuildOrTest.sh`
7. `tests/fafafa.core.layout/BuildOrTest.bat`

## 当前兼容策略

- `fafafa.core.layout` 是 `TMemLayout`、`TAllocCaps` 和默认布局常量的当前定义点。
- `src/fafafa.core.mem.layout.pas` 继续作为 compat 层存在，用于旧调用点与旧命名过渡，但不再是 strict L0 的 source-of-truth。
- 新代码应优先直接使用 `fafafa.core.layout`，不要再把布局契约埋在更宽的 `mem` 门面下。

## 目标

- 用最小 API 表达内存布局需求与分配器能力。
- 让布局与 allocator 实现解耦，成为更广义的底层合同。
- 保持只依赖 RTL 和 `fafafa.core.bits` 的 strict L0 依赖面。

## 当前 API

### 核心类型

- `TMemLayout`
  - `Create` / `TryCreate`
  - `ForType<T>` / `ForArray<T>`
  - `IsValid` / `IsZeroSized`
  - `AlignedSize` / `Extend` / `Pad`
  - `Empty` / `DefaultAlign`
- `TAllocCaps`
  - `Create`
  - `Default`
  - `ForSystemHeap`
  - `SupportsLayout`

### 常量与辅助函数

- `MEM_DEFAULT_ALIGN`
- `MEM_CACHE_LINE_SIZE`
- `MEM_PAGE_SIZE`
- `TryNextPowerOfTwo(aValue, out aResult)`

## 当前边界

- 这里承载的是布局合同，不承载 allocator backend、arena、pool 或 instrumentation 策略。
- `TAllocCaps` 只表达分配器真实能力，不替调用方做策略层决策。
- 如果你要看旧桥接层，回 `src/fafafa.core.mem.layout.pas`；如果你要看今天的 strict L0 合同，回本文件和 `src/fafafa.core.layout.pas`。

## 测试

- Linux/macOS：`bash tests/fafafa.core.layout/BuildOrTest.sh test`
- Windows：`tests\\fafafa.core.layout\\BuildOrTest.bat test`
- 当前测试入口会锁定 `TryNextPowerOfTwo`、`TMemLayout` 对齐归一化、`Extend/Pad` 语义与 `TAllocCaps.SupportsLayout` 行为。
- 如果你是在 Linux x64 上做 strict L0 日常维护，优先从 `bash tests/run_strict_l0_maintenance_loop.sh` 开始，而不是只单跑当前模块。
- 如果你需要 exact Windows native evidence，当前只接受 GitHub Actions 或真实 Windows runner 产物。
