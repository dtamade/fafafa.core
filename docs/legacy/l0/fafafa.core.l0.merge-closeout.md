# fafafa.core strict L0 收口清单（历史记录）

> 该文件已从根 `docs/` 归档到 `docs/legacy/l0/`，避免和 today contract 文档混淆。
> 当前 strict non-SIMD L0 的总边界以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准；后续推进顺序以 `docs/fafafa.core.l0.roadmap.md` 为准。
> 本页只保留 2026-03 那一轮 `span/contracts/bits/layout/endian` 收口阶段的历史语境，不再作为 today checklist。

## 这份记录还剩什么价值

- 说明 `span` 是如何以最小只读单段 contract 的形态进入 strict L0 的。
- 说明 `contracts` / `bits` / `layout` / `endian` 这一批模块曾完成过一次集中收口。

## 今天已经发生的后续变化

- `fafafa.core.platform` 已在后续收口中以最小静态表达层形态进入 strict L0。
- `fafafa.core.mem.allocator.foundation`、`rtlAllocator`、`callbackAllocator` 已不再属于 strict L0；strict L0 只保留 `fafafa.core.mem.allocator.base` contract。

## 当前应查看的文档

1. `docs/fafafa.core.l0.foundation.md`
2. `docs/ARCHITECTURE_LAYERS.md`
3. `docs/fafafa.core.l0.roadmap.md`
4. `docs/fafafa.core.platform.md`
5. `docs/fafafa.core.span.md`
