# 2026-04-09 L0 Kernel Span2 Closeout

> Status: completed historical batch.
>
> 当前 strict non-SIMD L0 的稳定路线图以 `docs/fafafa.core.l0.roadmap.md` 为准。
> 本页只保留 `span2` 准入这一轮 batch 的执行 closeout 语境。

## Goal

在不扩张到 container/service 语义的前提下，把 `span2` 以最小 read-only segmented view contract 形式纳入 strict non-SIMD L0，并同步收口当前 L0 控制面。

## Execution Status

- Batch 1-5 已完成。
- 当前 strict non-SIMD L0 已稳定覆盖：`settings/base/contracts/option/result/span/span2/bits/platform/layout/endian/atomic/mem.allocator.base`。
- 当前没有新的明确准入候选；后续若继续推进，应优先做 hygiene、稳定性和 source-of-truth 收口，而不是继续扩张 L0 面。

## Batch Scope

### Batch 1: clear the execution surface

- 把 sync/fs/socket runner sidecar 从当前 L0 worktree 分流到临时 branch `l0-sidecar-handoff-20260409`
- 保证当前 L0 worktree 只保留 strict L0 与 L0 control-plane 相关变更

### Batch 2: admit span2 into strict L0

- 在 `src/fafafa.core.span.pas` 中新增 `TReadOnlySpan2<T>`
- 保持 API 仅为：`FromTwo`、`ASpan`、`BSpan`、`Count`、`IsEmpty`、`Get`、`TryGet`、`GetPtr`、`GetBlock`、`SubSpan`
- 不引入 `collections.base` 依赖
- 不引入 `SliceView`、`MakeContiguous`、容量策略或可写语义

### Batch 3: align source-of-truth

- 更新 `docs/fafafa.core.span.md`
- 更新 `docs/fafafa.core.l0.foundation.md`
- 更新 `docs/ARCHITECTURE_LAYERS.md`
- 更新 `tests/fafafa.core.span/README.md`
- 给 `docs/legacy/l0/fafafa.core.span.candidate.md` 补充“历史语境”说明

### Batch 4: tighten boundary wording

- 给 `src/fafafa.core.atomic.base.pas` 补上 `{$I fafafa.core.settings.inc}`
- 把 `docs/fafafa.core.atomic.md` 重新定锚到 today contract + legacy appendix
- 把 `docs/fafafa.core.result.md` 明确为 `And_` / `Or_` 主入口、`AndResult` / `OrResult` compat-only
- 把 `docs/fafafa.core.mem.md` 明确为 mem 域导航，strict L0 allocator contract 仍在 `allocator.base`

### Batch 5: refresh control-plane

- 重写 `workers/worker1.md`
- 更新 `docs/INDEX.md` 与 `docs/README.md`
- 为 `2026-04-07` rescue plan/audit 加上 superseded note
- 新增 `2026-04-09` dated audit + plan 作为当前入口

## Verification

- `bash tests/fafafa.core.span/BuildOrTest.sh test`
- `bash tests/fafafa.core.collections/BuildOrTest.sh test`
- `bash tests/fafafa.core.atomic/BuildOrTest.sh test`
- `bash tests/fafafa.core.result/BuildOrTest.sh test`
- `bash tests/fafafa.core.platform/BuildOrTest.sh test`
- `bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test`
- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform`
- `git diff --check`

## Fresh Closeout Snapshot

- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform`
  - 结果：PASS，`11/11`
- `tests/fafafa.core.atomic/bin/tests_atomic --all --format=plain`
  - 结果：连续 `8` 轮 PASS，未复现早先单次聚合波动
- `git diff --check`
  - 结果：PASS
