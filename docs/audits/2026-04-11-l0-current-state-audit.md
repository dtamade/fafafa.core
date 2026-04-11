# 2026-04-11 L0 Current State Audit

> 这份审计反映 strict non-SIMD L0 在 PR `#9` 合并到 `main` 之后的 current state。

## Summary

- 当前 strict non-SIMD L0 的权威边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
- 当前 strict non-SIMD L0 的稳定路线图仍固定为 `docs/fafafa.core.l0.roadmap.md`。
- strict L0 的 latest-mainline replay 已经通过 PR `#9` 合并到 `main`；当前 `origin/main` 与当前唯一 L0 worktree 的 `HEAD` 都是 `f6585dd9`。
- 当前唯一 L0 branch 已切回 `l0-mainline` 并跟踪 `origin/main`，merge-prep 分支 `l0-mainline-integration-20260411` 已从本地和远端删除。
- Linux x64 的 strict L0 日常维护现在已经固化为 `bash tests/run_strict_l0_maintenance_loop.sh`；它会串起 docs consistency、strict L0 gate、`git diff --check`、runtime matrix 和 native closeout stack。
- post-merge 的 fresh Linux gate、`git diff --check`、Windows `.bat` runtime parity matrix 和 native closeout stack 都已重新通过。
- 最新的 commit-exact Windows native evidence 仍锚定 GitHub Actions run `24278413198` 对提交 `3ed04784` 的 `12/12 PASS`；后续 `1621c4a0` 与 merge commit `f6585dd9` 都没有改变 strict L0 代码或测试面。

## What Changed Since The Merge-Prep Phase

### 1. The merge window is closed

- PR：`#9` `l0: replay strict L0 closeout onto latest mainline`
- merged at：`2026-04-11T08:51:07Z`
- merge commit：`f6585dd9`
- 当前 L0 worktree 不再承担 merge-prep surface，而是承担 merged-main 上的 post-merge stabilization surface。

### 2. The unique L0 worktree is now a maintenance surface

- 当前 branch：`l0-mainline`
- 当前 tracking：`origin/main`
- 当前 `HEAD`：`f6585dd9`
- 当前 `origin/main`：`f6585dd9`
- 当前不再把 `docs/legacy/l0/2026-04-11-l0-mainline-merge-checklist.md` 或 `docs/legacy/l0/2026-04-11-l0-mainline-replay-execution-plan.md` 当 current-entry；它们现在只保留历史 closeout 语境。

### 3. Verification was refreshed on the merged-main result

- `bash tests/check_strict_l0_docs_consistency.sh`
  - 结果：PASS
- `bash tests/run_strict_l0_maintenance_loop.sh`
  - 结果：PASS
- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform`
  - 结果：PASS，`11/11`
- `git diff --check`
  - 结果：PASS
- `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
  - 结果：PASS；`base`、`contracts`、`bits`、`layout`、`endian`、`span`、`option`、`result`、`platform`、`atomic`、`mem_allocator_foundation`、`mem_allocator_only` 全部 fresh 通过
- `bash tests/test_windows_strict_l0_native_closeout_stack.sh`
  - 结果：PASS；GH preflight 为 `workflow=l0-windows-native-evidence.yml, state=active`

## Current L0 Surface

- 基础语义：`settings.inc`、`base`、`contracts`、`option`、`result`
- 视图表达：`span`、`span2`
- 原始数据语义：`bits`、`platform`、`layout`、`endian`
- 内存模型：`atomic.core`、`atomic.base`、`atomic`、`atomic.compat`
- 分配契约：`mem.allocator.base`

当前边界没有变化。变化的是：这组边界已经完成 merged-main 收口，当前工作重点转成 current-entry 稳定性与验证纪律维护。

## Windows Evidence Posture

- 历史 strict L0 Windows native baseline 仍保留在 GitHub Actions run `24224880061`，对应代码修复锚点 `b8adade0`。
- latest-mainline replay 阶段拿到的 commit-exact Windows native evidence 仍然有效：
  - GitHub Actions run：`24278413198`
  - head branch：`l0-mainline-integration-20260411`
  - head sha：`3ed047847b0bf871b265ded8e4a14c517b84b414`
  - local snapshot：`tests/_windows_l0_native_evidence_gh/L0-20260411-native-gha-r10/`
  - artifact batch：`L0-GHA-24278413198-1`
  - result：`12/12 PASS`
- 当前 `main@f6585dd9` 可以继续引用这份 exact evidence 作为 strict L0 代码验证锚点，因为 `3ed04784 -> 1621c4a0 -> f6585dd9` 这段增量只包含 docs / control-plane 变化，没有新的 strict L0 代码或测试改动。
- 如果后续需要“当前 HEAD / merge commit 自身的 exact Windows native evidence”，或者 strict L0 再发生非文档提交，仍应重新触发 GH native evidence，而不是继续复用 `24278413198`。

## Post-Merge Maintenance Rules

- 当前唯一 L0 worktree 应持续保持在 `l0-mainline -> origin/main`。
- 当前日常维护的最小验证闭环固定为：
  - strict L0 聚合 gate
  - `git diff --check`
  - `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
  - `bash tests/test_windows_strict_l0_native_closeout_stack.sh`
- Windows exact evidence 只接受 GitHub Actions 作为证据来源；Linux x64 本地环境只负责 runtime parity 与 native lane contract 复核。
- 当前保留的本地 L0 refs 只包括：
  - `l0-mainline`
  - `l0-mainline-closeout-20260411`
  - `l0-sidecar-handoff-20260409`
  - `l0-main-rescue`
  - `l0-main-tail-cleanup-20260408-final`

## Remaining Risks

- 根目录 `main` 工作树仍然是用户脏状态，不应把它误当成 L0 的当前执行面。
- 当前 exact Windows native evidence 的代码锚点仍是 `3ed04784`；这对 today strict L0 code surface 足够，但如果有人要求 merge commit 级别的 exact 证据，仍需补 fresh GH run。
- SIMD owner 与 sidecar handoff 的职责边界没有变化；L0 这里不应重新吸收那些工作。
