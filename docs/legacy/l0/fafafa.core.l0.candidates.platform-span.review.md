# strict L0 候选审查：platform / span（历史记录）

> 该文件已从根 `docs/` 归档到 `docs/legacy/l0/`，避免和 today contract 文档混淆。
> 本页保留 2026-03-26 候选审查阶段的结论。
> today contract 请以 `docs/fafafa.core.l0.foundation.md`、`docs/ARCHITECTURE_LAYERS.md`、`docs/fafafa.core.l0.roadmap.md`、`docs/fafafa.core.platform.md` 和 `docs/fafafa.core.span.md` 为准。
> 更新：自 `2026-04-09` 起，`TReadOnlySpan2<T>` 与 `GetBlock` 已通过后续收口进入 strict L0；本页正文只保留 2026-03-26 当时的候选审查语境。

## 当前状态

- `fafafa.core.span` 已作为 strict L0 的最小只读单段视图合同落地。
- `fafafa.core.platform` 已作为 strict L0 的最小静态平台表达层落地。
- `TReadOnlySpan2<T>` 与 `GetBlock` 已在后续收口中进入 strict L0；deque 双段视图和容器 `SliceView` 仍不属于 strict L0。
- `fafafa.core.os` 仍不属于 strict L0。

## 仍然有效的历史结论

- `platform` 只有在被压缩成极小静态表达层之后，才适合进入 strict L0。
- `span` 只有在被切到最小 read-only single-segment contract 时，才适合进入 strict L0。
