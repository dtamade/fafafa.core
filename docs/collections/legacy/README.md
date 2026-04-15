# Collections Legacy Docs

这里收纳的是 `fafafa.core.collections` 域里已经明确 dated / superseded 的计划、状态和审查文档。

这些文件仍然保留历史语境和 retained-refs 吸收线索，但它们不再承担 today contract。当前如果要看 collections 的稳定入口，请优先阅读：

- `docs/fafafa.core.collections.md`
- `docs/fafafa.core.collections.vec.md`
- `docs/fafafa.core.collections.vecdeque.md`
- `docs/collections/guides/README_TVec.md`
- `docs/collections/guides/README_VecDeque.md`
- `docs/collections/guides/UnChecked_Methods_Summary.md`

## Retained-Refs Landing Zone

第七波 retained-refs absorbability 之后，如果 `l0-sidecar-handoff-20260409` 或 `l0-main-tail-cleanup-20260408-final` 继续暴露：

- `docs/collections/plans/COLLECTIONS_REFINEMENT_PLAN.md`
- `docs/collections/status/COLLECTIONS_CURRENT_STATUS_2025-11-03.md`
- `docs/collections/status/COLLECTIONS_OVERVIEW_2025-11-03.md`

应优先把它们理解成“已存在稳定 landing zone 的低风险 collections dated docs residue”，而不是 today current-entry。

也就是说，retained-refs inventory 里的这批路径现在应优先落到这里的 legacy 语境，再决定是否还需要更进一步的 source review。

## Archived plans

- `docs/collections/legacy/COLLECTIONS_REFINEMENT_PLAN.md`
- `docs/collections/legacy/COLLECTIONS_NEW_CONTAINERS_PLAN_2025-11-03.md`

## Archived status

- `docs/collections/legacy/COLLECTIONS_CURRENT_STATUS_2025-11-03.md`
- `docs/collections/legacy/COLLECTIONS_OVERVIEW_2025-11-03.md`

## Archived reviews

- `docs/collections/legacy/COLLECTIONS_API_CONSISTENCY_REVIEW_2025-11-03.md`
- `docs/collections/legacy/COLLECTIONS_CODE_QUALITY_REVIEW_2025-11-03.md`

## How to use this folder

- 需要看当前 API / guide / usage：回到 `docs/fafafa.core.collections.md` 与 `docs/collections/guides/`
- 需要看 2025-11-03 那批规划、状态或评审语境：从这里进入
- 需要继续做 retained-refs docs-first 吸收：优先把这里视为历史批次，而不是 current-entry
