# fafafa.core.platform 候选审查（历史记录）

> 该文件已从根 `docs/` 归档到 `docs/legacy/l0/`，避免和 today contract 文档混淆。
> 本页保留 2026-03-26 之前的候选审查语境。
> `fafafa.core.platform` 已在后续收口中以最小静态表达层形态落地，请以 `docs/fafafa.core.platform.md`、`docs/fafafa.core.l0.foundation.md`、`docs/ARCHITECTURE_LAYERS.md` 和 `docs/fafafa.core.l0.roadmap.md` 为准。

## 当前结论

- `fafafa.core.platform` 已存在并进入 strict L0。
- 当前模块只保留 OS / arch / pointer-width / 32-64 位判定。
- `fafafa.core.os` 仍然是 system probe / env / path / system info facade，不下沉进 strict L0。

## 历史价值

这个文件只保留一个历史结论：

- `platform` 只有在被压缩成极小静态表达层之后，才适合进入 strict L0。
