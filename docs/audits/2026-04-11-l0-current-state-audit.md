# 2026-04-11 L0 Current State Audit

> 这份审计替代 `docs/audits/2026-04-10-l0-current-state-audit.md` 作为当前 strict non-SIMD L0 的最新状态说明。

## Summary

- 当前 strict non-SIMD L0 的权威边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
- 当前 strict non-SIMD L0 的稳定路线图仍固定为 `docs/fafafa.core.l0.roadmap.md`。
- strict L0 已在当前唯一的 L0 worktree 中完成对最新 `origin/main` 的 replay；当前集成分支为 `l0-mainline-integration-20260411`，`HEAD` 为 `78069dfc`。
- 当前 `HEAD` 的 merge-base 已经等于最新 `origin/main` `0684af55`，之前“分支落后主线 2 个提交”的 merge hygiene blocker 已收口。
- fresh Linux gate、`git diff --check`、Windows `.bat` runtime parity matrix 和 native closeout stack 都已在 replay 后重新通过。

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

- 真实 Windows native evidence 仍以 GitHub Actions run `24224880061` 为当前代码证据锚点。
- 对应 strict L0 代码修复锚点仍是 `b8adade0`。
- 这次 `2026-04-11` replay 后没有重新触发 GH native evidence，原因是：
  - replay 的目标是把已验证过的 strict L0 closeout 树重放到最新主线；
  - 唯一手工冲突只发生在 native evidence collector 脚本，并且保留的是 closeout 侧已验证逻辑；
  - 本地 `native_closeout_stack` 已在 replay 后 fresh 通过。
- 如果后续真正进入主线合并窗口时需要“artifact 必须精确绑定到 `78069dfc`”这一层证据，再在分支推送后重新触发 GH native evidence 即可。

## What Is Still Missing

### 1. Final merge execution still must avoid the dirty root `main` worktree

- 当前 L0 branch 已经是基于最新主线的干净集成面。
- 但根目录 `main` 工作树仍然是用户脏状态，不应用来直接承载最后的合并动作。

### 2. Commit-exact Windows evidence is optional, not today's blocker

- 当前 replay 分支已经具备 current control-plane 和 fresh 本地复核。
- 如果后续流程要求“native artifact 必须精确绑定 replay commit `78069dfc`”，再补 fresh GH run；否则今天不需要因为这件事阻塞 L0 当前整理完成度。

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
- 如果最终主线合并政策要求 commit-exact 的 Windows native artifact，仍需在推送当前分支后重跑一次 GH native evidence。
