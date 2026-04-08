# 2026-04-09 L0 Current State Audit

## Summary

- 当前 strict non-SIMD L0 的权威边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
- `fafafa.core.span` 现在正式承载最小只读单段 `span` 与双段 `span2` contract。
- 当前 L0 执行面仍然是 `l0-main-tail-cleanup-20260408` worktree。
- 原先混入该 worktree 的 sync/fs/socket runner sidecar 已安全转移到临时 branch `l0-sidecar-handoff-20260409`，不再阻塞 strict L0 继续推进。

## Current L0 Surface

- 基础语义：`settings.inc`、`base`、`contracts`、`option`、`result`
- 视图表达：`span`、`span2`
- 原始数据语义：`bits`、`platform`、`layout`、`endian`
- 内存模型：`atomic.core`、`atomic.base`、`atomic`、`atomic.compat`
- 分配契约：`mem.allocator.base`

## Current Findings

### 1. span2 is now small enough for L0

- 新增的是 read-only segmented view contract，不是 container API。
- 依赖面保持在 RTL + `fafafa.core.base`。
- `collections.slice` 继续保留 Layer 1 的 container `SliceView` 语义。

### 2. atomic/result/mem allocator boundary needed wording cleanup more than code churn

- `atomic.compat` 继续存在，但只能被视作 legacy bridge。
- `AndResult` / `OrResult` 继续存在，但只能被视作 deprecated compatibility API。
- `mem.allocator.foundation` 继续是 mem 域 low-level facade，不回退成 strict L0 source-of-truth。

### 3. Control-plane drift was real

- `workers/worker1.md` 在本轮之前仍携带过多 tail-cleanup / non-L0 historical noise。
- `docs/INDEX.md` 仍把 `2026-04-07` rescue 文档当作当前 follow-up 入口。
- 需要一个新的 dated audit + plan 把当前 truth 重新钉住。

## Verification Snapshot

- `bash tests/fafafa.core.span/BuildOrTest.sh test`
- `bash tests/fafafa.core.collections/BuildOrTest.sh test`
- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform`

## Remaining Risks

- 根 `main` 工作树仍然是用户脏状态，不应拿来直接承载 L0 收口。
- 临时 branch `l0-sidecar-handoff-20260409` 只是 sidecar 交接面，不应再并回当前 L0 实施面。
- SIMD 仍由 SIMD owner 负责；L0 这里只处理边界和非 SIMD contract。
