# 2026-04-10 L0 Current State Audit

> 这份审计替代 `docs/audits/2026-04-09-l0-current-state-audit.md` 作为当前 strict non-SIMD L0 的最新状态说明。

## Summary

- 当前 strict non-SIMD L0 的权威边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
- 当前 strict non-SIMD L0 的稳定路线图仍固定为 `docs/fafafa.core.l0.roadmap.md`。
- strict L0 的 Windows native evidence 已不再是 blocker；GitHub Actions run `24224880061` 已在真实 Windows runner 上 fresh 收到 `12/12` 通过证据。
- 这次通过证据对应提交 `b8adade0` `fix(l0): use run methods for allocator exception tests`，它清掉了 `mem_allocator_foundation` 和 `mem_allocator_only` 在 Windows FPC 3.2.2 下的最后一类 `AssertException(..., TRunMethod)` 兼容性问题。
- 当前 L0 还需要继续做的是 merge hygiene、文档同步和 compat surface discipline，而不是继续扩模块。

## What Changed Since 2026-04-09

### 1. Windows native parity is now closed for the current strict L0 lane

- `tests/run_windows_strict_l0_native_evidence_via_github_actions.sh` 已在 Linux x64 上成功触发真实 Windows workflow。
- GitHub Actions run `24224880061` 的 `Collect native evidence` 和 `Verify native evidence` 两步都已通过。
- 下载回当前 worktree 的 artifact summary 现在明确写出：
  - `Result: PASS`
  - `Exit Code: 0`
  - `Total: 12`
  - `Passed: 12`
  - `Failed: 0`
- 当前 artifact 本地快照目录：
  - `tests/_windows_l0_native_evidence_gh/L0-20260410-native-gha-r9/`
- `source_revision.txt` 明确记录：
  - `git_commit=b8adade028ee2011bb6868dc4b666ec7db71ece1`
  - `git_ref_hint=l0-mainline-integration-20260409`
  - `github_run_id=24224880061`

### 2. mem allocator modules are no longer the first Windows blocker

- `mem_allocator_foundation` 现在在真实 Windows artifact 中已经是：
  - `[BUILD] OK`
  - `[CHECK] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- `mem_allocator_only` 现在在真实 Windows artifact 中也已经是：
  - `[BUILD] OK`
  - `[CHECK] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前 strict L0 Windows native lane 不再有 “foundation 先红、allocator-only 还没轮到” 这一类状态漂移。

## Current L0 Surface

- 基础语义：`settings.inc`、`base`、`contracts`、`option`、`result`
- 视图表达：`span`、`span2`
- 原始数据语义：`bits`、`platform`、`layout`、`endian`
- 内存模型：`atomic.core`、`atomic.base`、`atomic`、`atomic.compat`
- 分配契约：`mem.allocator.base`

当前这个边界没有变化。变化的是验证状态，而不是模块范围。

## What Is Still Missing

### 1. Merge hygiene is still a process task

- 当前 L0 worktree 和 integration branch 已可独立审阅。
- 根 `main` 工作树仍然是用户脏状态，不应直接作为最终合并执行面。
- 因此，现在的剩余工作仍然首先是集成窗口与 merge hygiene，而不是补平台 blocker。

### 2. Compat surface still needs continued discipline

- `atomic.compat` 仍必须继续被标成 legacy bridge，而不是 today 推荐入口。
- `result` 的兼容 API 仍然需要维持 “可用但不鼓励扩散” 的文档口径。
- `mem.allocator.foundation` 虽然已经在 Windows lane 通过，但它仍只是 mem 域 low-level facade，不应被重新误读成 strict L0 本体。

### 3. Documentation and control-plane sync still need maintenance

- `foundation`、`roadmap`、`INDEX`、`README`、`worker` 和 dated plan 需要保持同一口径。
- dated `docs/plans/*.md` 只保留执行上下文；当前状态应始终以最新 audit 为准。

## Current Findings

### 1. The remaining L0 work is now mostly governance, not rescue

- 真实 Windows native evidence 已经补齐，说明 strict L0 当前不是“脚本接好了但生产证据没落地”的状态。
- 当前继续做 L0，更合理的主线是维护 current-entry、merge checklist 和 compat wording，而不是继续做救火式 platform triage。

### 2. The mem allocator contract boundary stayed stable

- strict L0 仍然只持有 `fafafa.core.mem.allocator.base`。
- `fafafa.core.mem.allocator.foundation`、`rtlAllocator`、`callbackAllocator` 仍然留在 mem 域低层 facade / backend 语义。
- 这次修复只是在测试层补齐 Windows FPC 兼容性，没有把具体 allocator backend 重新抬进 strict L0。

## Merge Readiness

如果问题是“当前 strict L0 还会不会被 Windows native evidence 卡住”，当前答案是：不会。

当前已经满足：

- strict L0 边界固定在 `foundation + roadmap + latest audit`
- Linux x64 本地 gate 通过
- Windows runtime-only parity matrix 通过
- 真实 Windows native evidence `12/12` 通过

当前仍不应跳过的事情：

- 不要在用户脏的根 `main` 工作树上直接做最终合并动作
- 不要把 SIMD owner 的工作混回当前 L0 worktree
- 在没有新的 candidate 审查之前，不要继续扩张 strict L0 面

## Verification Snapshot

- `git diff --check`
  - 结果：PASS
- `bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test`
  - 结果：PASS
- `bash tests/fafafa.core.mem/BuildOrTest.sh test`
  - 结果：PASS
- `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
  - 结果：PASS；`base`、`contracts`、`bits`、`layout`、`endian`、`span`、`option`、`result`、`platform`、`atomic`、`mem_allocator_foundation`、`mem_allocator_only` 全部 fresh 通过
- `bash tests/test_windows_strict_l0_native_closeout_stack.sh`
  - 结果：PASS
- `L0_NATIVE_EVIDENCE_POLL_MAX_TRIES=180 bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh L0-20260410-native-gha-r9`
  - 结果：PASS；下载回本地的 artifact 对应 GitHub Actions run `24224880061`

## Remaining Risks

- 根 `main` 工作树仍然是用户脏状态，不应拿来直接承载 L0 收口。
- SIMD 仍由 SIMD owner 负责；L0 这里只处理 strict non-SIMD L0 的边界、验证和控制面同步。
- 若后续 Windows lane 再次失败，优先读取 artifact 里的第一 blocker，不要退回凭感觉修改生产代码。
