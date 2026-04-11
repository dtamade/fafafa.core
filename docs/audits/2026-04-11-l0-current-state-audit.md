# 2026-04-11 L0 Current State Audit

> 这份审计替代 `docs/audits/2026-04-10-l0-current-state-audit.md` 作为当前 strict non-SIMD L0 的最新状态说明。

## Summary

- 当前 strict non-SIMD L0 的权威边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
- 当前 strict non-SIMD L0 的稳定路线图仍固定为 `docs/fafafa.core.l0.roadmap.md`。
- strict L0 已在当前唯一的 L0 worktree 中完成对最新 `origin/main` 的 replay；当前集成分支为 `l0-mainline-integration-20260411`，对应 replay code commit 为 `78069dfc`。
- 当前 `HEAD` 的 merge-base 已经等于最新 `origin/main` `0684af55`，之前“分支落后主线 2 个提交”的 merge hygiene blocker 已收口。
- replay 后的 fresh Linux gate、`git diff --check`、Windows `.bat` runtime parity matrix 和 native closeout stack 都已重新通过。
- 当前还额外拿到了 commit-exact 的真实 Windows native evidence：GitHub Actions run `24278413198` 对分支 `l0-mainline-integration-20260411` 的提交 `3ed04784` 返回 `12/12 PASS`。

## What Changed Since 2026-04-10

### 1. The replay onto latest mainline is now complete

- 当前 replay 提交为：`78069dfc` `merge(l0): replay strict l0 closeout onto latest mainline`
- 新 integration 分支为：`l0-mainline-integration-20260411`
- 当前基线主线为：`0684af55` `Merge pull request #8 from dtamade/l0-windows-ci-enablement`
- 当前 merge-base 已等于 `origin/main`，说明 strict L0 已不再停留在“ahead 45, behind 2”的旧状态。

### 2. The replay method was upgraded from commit-sequence replay to final-tree replay

- `origin/main` 已通过 `0684af55` 吸收 `70f12256` 代表的一整段 Windows control-plane bundle。
- 因此，这次没有继续机械地重放旧的 45 个提交，而是在冻结 `l0-mainline-closeout-20260411` 后，用最终树差异把 proven strict L0 状态整合到最新主线上。
- 唯一需要人工裁决的冲突是 `tests/collect_windows_strict_l0_native_evidence.bat` 的 add/add；最终保留了 closeout 侧新增的 case-level 日志回收逻辑。

### 3. Verification was refreshed on the replayed branch

- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform`
  - 结果：PASS，`11/11`
- `git diff --check`
  - 结果：PASS
- `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
  - 结果：PASS；`base`、`contracts`、`bits`、`layout`、`endian`、`span`、`option`、`result`、`platform`、`atomic`、`mem_allocator_foundation`、`mem_allocator_only` 全部 fresh 通过
- `bash tests/test_windows_strict_l0_native_closeout_stack.sh`
  - 结果：PASS；GH preflight 为 `state=active`

## Current L0 Surface

- 基础语义：`settings.inc`、`base`、`contracts`、`option`、`result`
- 视图表达：`span`、`span2`
- 原始数据语义：`bits`、`platform`、`layout`、`endian`
- 内存模型：`atomic.core`、`atomic.base`、`atomic`、`atomic.compat`
- 分配契约：`mem.allocator.base`

当前边界没有变化。变化的是：当前这组边界已经在最新主线基线上完成 replay，并重新拿到了 fresh verification。

## Windows Evidence Posture

- 历史 strict L0 Windows native baseline 仍保留在 GitHub Actions run `24224880061`，对应代码修复锚点 `b8adade0`。
- 当前 latest-mainline replay 之后的 commit-exact Windows native evidence 已经补齐：
  - GitHub Actions run：`24278413198`
  - head branch：`l0-mainline-integration-20260411`
  - head sha：`3ed047847b0bf871b265ded8e4a14c517b84b414`
  - local snapshot：`tests/_windows_l0_native_evidence_gh/L0-20260411-native-gha-r10/`
  - artifact batch：`L0-GHA-24278413198-1`
  - result：`12/12 PASS`
- 这次 shell verifier 已对下载回来的 artifact 做了 commit/ref 校验，因此当前不是“只有旧 run 24224880061 可引用”的状态。
- `source_revision.txt` 里的 `git_tree_state=dirty` 来自 Windows runner checkout 时仓库内一批 unrelated tracked `.bat`/`.sh` 文件被标成 modified；artifact 自带的 `git_status_tracked.txt` 已记录这些路径。它没有改变 strict L0 evidence 的 commit/ref/result 结论，但说明这份证据包不应被误读成“整个仓库在 Windows host 上是 pristine checkout”。

## What Is Still Missing

### 1. Final merge execution still must avoid the dirty root `main` worktree

- 当前 L0 branch 已经是基于最新主线的干净集成面。
- 但根目录 `main` 工作树仍然是用户脏状态，不应用来直接承载最后的合并动作。

### 2. Commit-exact Windows evidence is now closed for the replayed branch

- 当前分支已经拿到对提交 `3ed04784` 的 commit-exact Windows native evidence。
- 后续只有在当前分支继续新增非文档改动、或 `origin/main` 再次前进并触发新一轮 replay 时，才需要再补 fresh GH run。

### 3. SIMD and sidecar ownership remain unchanged

- SIMD 仍由 SIMD owner 负责；L0 这里只保留边界与 handoff 说明。
- sidecar sync/fs/socket runner 的临时 handoff 分支仍保持不变，不应重新混回当前 L0 线。

## Merge Readiness

如果问题是“当前 strict L0 是否已经完成对最新主线的 replay 并具备继续进入合并准备窗口的条件”，当前答案是：是。

当前已经满足：

- 当前 integration branch 基于最新 `origin/main`
- 当前 `HEAD` 相对 `origin/main` 是 `ahead 1, behind 0`
- strict L0 聚合 gate 通过
- `git diff --check` 通过
- Windows `.bat` runtime-only parity matrix 通过
- `native_closeout_stack` 通过
- 没有把 SIMD owner 的工作或 root `main` 的脏改动混进当前 L0 分支

## Remaining Risks

- 根 `main` 工作树仍然是用户脏状态，不应拿来直接承载最后合并。
- 若后续主线在当前分支之上继续前进，需要在新的 `origin/main` 上再次做一次轻量 replay，而不是退回旧的 2026-04-10 清单。
- 当前 commit-exact Windows native artifact 绑定的是 `3ed04784`。如果后续在这个分支上继续提交非文档改动，仍需重新触发 GH native evidence。
