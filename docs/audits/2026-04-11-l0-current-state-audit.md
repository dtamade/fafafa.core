# 2026-04-11 L0 Current State Audit

> 这份审计反映 strict non-SIMD L0 在 PR `#13` 合并到 `main` 之后的 current state。

## Summary

- 当前 strict non-SIMD L0 的权威边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
- 当前 strict non-SIMD L0 的稳定路线图仍固定为 `docs/fafafa.core.l0.roadmap.md`。
- 当前 `origin/main` 与唯一 L0 worktree 已同步到 merge commit `54a7ae056679c251a8a1f53442cfd20601b6f08f`。
- 当前唯一 L0 branch 仍是 `l0-mainline`，但它现在只是一个跟随 `origin/main` 的维护分支，不再承载未合并增量。
- Linux x64 的 strict L0 日常维护继续固定为 `bash tests/run_strict_l0_maintenance_loop.sh`；对应 GitHub Actions workflow `l0-linux-maintenance.yml` 已进入 default branch，并已在 `main` fresh 通过。
- strict L0 的 Windows native evidence 也已经对 `main@54a7ae05` fresh 收证：GitHub Actions run `24284111799` 为 `12/12 PASS`，shell-side artifact verifier 已在 Linux x64 本地复核通过。
- 当前 4 个残留 L0 refs 仍承载独立 patch history；refs cleanup 结论继续保持显式 `no-op`。

## What Changed Since The Earlier Post-Merge Snapshot

### 1. Mainline advanced again

- PR：`#13` `fix(l0): harden windows bootstrap and GH preflight contracts`
- merged at：`2026-04-11`
- merge commit：`54a7ae056679c251a8a1f53442cfd20601b6f08f`
- 本次合入把 Windows lazbuild bootstrap、GH preflight contract 与相关文档口径一起收进了 `main`。

### 2. Linux maintenance workflow is now a live mainline lane

- GitHub Actions run `24283828586`
  - ref：`l0-mainline`
  - head sha：`d746375bc5a75080239aedbe0769bcd283ac2369`
  - 结果：PASS
- GitHub Actions run `24283947269`
  - ref：`main`
  - head sha：`54a7ae056679c251a8a1f53442cfd20601b6f08f`
  - 结果：PASS

当前判断：

- `.github/workflows/l0-linux-maintenance.yml` 已经进入 default branch。
- `gh workflow run l0-linux-maintenance.yml --ref main` 现在是可用的 current-entry 命令。
- 更早那次 `gh workflow run ... --ref l0-mainline` 返回 `HTTP 404` 的现象只保留为 pre-merge 历史，不再是当前 blocker。

### 3. Exact Windows native evidence is fresh again on main

- GitHub Actions run `24284111799`
  - workflow：`L0 Windows Native Evidence`
  - ref：`main`
  - head sha：`54a7ae056679c251a8a1f53442cfd20601b6f08f`
  - result：`12/12 PASS`
- Linux shell verifier：
  - 命令：`L0_NATIVE_EVIDENCE_EXPECT_COMMIT=54a7ae056679c251a8a1f53442cfd20601b6f08f L0_NATIVE_EVIDENCE_EXPECT_REF=main bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh L0-20260411-native-gha-r11 24284111799`
  - 结果：PASS
  - 本地 snapshot：`tests/_windows_l0_native_evidence_gh/L0-20260411-native-gha-r11/`

当前判断：

- `main@54a7ae05` 已经拥有 exact Windows native evidence，不再只依赖旧的 replay-era 锚点。
- Windows exact evidence 仍然只接受 GitHub Actions 或真实 Windows runner 产物；Linux x64 本地只负责下载后的 contract 复核。

## Fresh Verification

- `bash tests/check_strict_l0_docs_consistency.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_docs_consistency_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_stable_docs_no_sha_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_linux_ci_workflow_contract.sh`
  - 结果：PASS
- `bash tests/test_windows_strict_l0_native_evidence_gh_contract.sh`
  - 结果：PASS；`AUTH_REQUIRED/rc=21` 与 live GH preflight 都已被 contract 覆盖
- `bash tests/run_strict_l0_maintenance_loop.sh`
  - 结果：PASS
- `git diff --check`
  - 结果：PASS
- GitHub Actions `L0 Linux Maintenance` run `24283947269`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence` run `24284111799`
  - 结果：PASS；`12/12`

## Current L0 Surface

- 基础语义：`settings.inc`、`base`、`contracts`、`option`、`result`
- 视图表达：`span`、`span2`
- 原始数据语义：`bits`、`platform`、`layout`、`endian`
- 内存模型：`atomic.core`、`atomic.base`、`atomic`、`atomic.compat`
- 分配契约：`mem.allocator.base`

当前边界没有变化。变化的是：current-entry 的验证证据已经从“本地闭环 + branch-local 历史探测”推进成了“main 上 fresh Linux + fresh Windows CI 双证据”。

## Windows Evidence Posture

- 历史 strict L0 Windows native baseline 仍保留在 GitHub Actions run `24224880061`，对应代码修复锚点 `b8adade0`。
- replay 阶段拿到的 commit-exact Windows native evidence 仍保留为历史锚点：
  - GitHub Actions run：`24278413198`
  - head sha：`3ed047847b0bf871b265ded8e4a14c517b84b414`
  - result：`12/12 PASS`
- 当前最新的 mainline exact evidence 已更新为：
  - GitHub Actions run：`24284111799`
  - head sha：`54a7ae056679c251a8a1f53442cfd20601b6f08f`
  - local snapshot：`tests/_windows_l0_native_evidence_gh/L0-20260411-native-gha-r11/`
  - result：`12/12 PASS`

## Current Maintenance Rules

- 当前唯一 L0 worktree 应继续保持在 `l0-mainline -> origin/main`。
- Linux x64 上的日常维护默认走 `bash tests/run_strict_l0_maintenance_loop.sh`。
- 如需 GitHub-side Linux 证据，当前标准命令是 `gh workflow run l0-linux-maintenance.yml --ref main`。
- 如需 GitHub-side Windows exact evidence，当前标准入口是 `l0-windows-native-evidence.yml`，并在下载后继续通过 `bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh <batch-id> <run-id>` 做 shell-side artifact 校验。
- 当前保留的本地 L0 refs 只包括：
  - `l0-mainline`
  - `l0-mainline-closeout-20260411`
  - `l0-sidecar-handoff-20260409`
  - `l0-main-rescue`
  - `l0-main-tail-cleanup-20260408-final`

## Remaining Risks

- 根目录 `main` 工作树仍然是用户脏状态，不应把它误当成 L0 的当前执行面。
- 当前保留的 4 个历史 L0 refs 仍未被证明完全冗余，因此不能盲删。
- 后续若 strict L0 再发生非文档代码或测试改动，仍应重新收 fresh Windows exact evidence，而不是复用 `24284111799`。
- SIMD owner 与 sidecar handoff 的职责边界没有变化；L0 这里不应重新吸收那些工作。
