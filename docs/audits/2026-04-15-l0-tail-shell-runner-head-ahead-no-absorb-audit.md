# 2026-04-15 L0 Tail Shell/Runner Head-Ahead No-Absorb Audit

> 这份审计记录 strict non-SIMD L0 在当前唯一 L0 worktree 上，对 `l0-main-tail-cleanup-20260408-final` 里最像“test-hygiene-first”候选的 shell/runner cluster 做 fresh diff 复核后的结论：**当前 HEAD 已经更先进，tail 版本不能回灌。**

## Scope

这轮只复核 `tail` 上这一组 shell/runner / perf 文档路径：

- `tests/cleanup_orphan_dirs.sh`
- `tests/fafafa.core.fs/ArchivePerfResult.sh`
- `tests/fafafa.core.fs/BuildOrRunPerf.sh`
- `tests/fafafa.core.fs/BuildOrRunPerfAll.sh`
- `tests/fafafa.core.fs/BuildOrRunResolvePerf.sh`
- `tests/fafafa.core.fs/README-perf.md`

纪律保持不变：

- 不 broad absorb retained refs
- 不删除 retained refs
- 不碰 SIMD lane

## Fresh evidence

fresh 复核命令：

```bash
git cherry -v HEAD l0-main-tail-cleanup-20260408-final
git diff HEAD..l0-main-tail-cleanup-20260408-final -- \
  tests/cleanup_orphan_dirs.sh \
  tests/fafafa.core.fs/ArchivePerfResult.sh \
  tests/fafafa.core.fs/BuildOrRunPerf.sh \
  tests/fafafa.core.fs/BuildOrRunPerfAll.sh \
  tests/fafafa.core.fs/BuildOrRunResolvePerf.sh \
  tests/fafafa.core.fs/README-perf.md
bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh
bash tests/report_strict_l0_retained_refs_inventory.sh --details
```

fresh 结论：

- `git cherry -v` 里，这组 shell/runner cluster 主要落在：
  - `e14a6ef4dddfd17e76b6f7d1eb992681972ff566 fix: normalize fs perf shell runners`
  - `5c84767fe1e839f5f39ac60d72b40a2783aa3202 fix: normalize active test shell runners`
- overlap 仍给出：
  - `tail_only_commit_count=8`
  - `pairwise_decision=keep-both`
  - `pairwise_cleanup_readiness=review-exclusive-batches-first`
- inventory `--details` 仍把 `tail` 暴露成 `next_focus=test-hygiene-first`

但 fresh diff 同时明确说明：**这组路径不是“主线缺失的 today value”，而是 tail 版本已经落后于当前 HEAD 的 today contract。**

## Why the tail versions are regressive

### `tests/cleanup_orphan_dirs.sh`

当前 HEAD 已经具备：

- `set -euo pipefail`
- `--root` / `--help`
- 更严格的参数与失败处理

tail 版本会回退成：

- `#!/bin/bash`
- 只有 `set -e`
- 没有 today 的参数入口与 fail-close 语义

### fs perf wrappers

当前 HEAD 已经把 Linux/macOS perf shell 入口统一到 today contract：

- `BuildOrRunPerf.sh` 继续提供 `buildonly / resolve / walk / all`
- `BuildOrRunResolvePerf.sh` / `BuildOrRunPerfAll.sh` 继续只是薄 wrapper
- `ArchivePerfResult.sh` 继续保持单次执行、归档输出与退出码语义一致

tail 版本会回退成旧 wrapper 形态：

- `BuildOrRunPerf.sh` 退回单一 bench wrapper
- `BuildOrRunResolvePerf.sh` / `BuildOrRunPerfAll.sh` 重新内联旧逻辑
- `ArchivePerfResult.sh` 会重复执行 perf 命令并丢失 today 的退出码保真语义

### `tests/fafafa.core.fs/README-perf.md`

当前 HEAD README 继续和 today shell contract 一致，明确：

- Linux/macOS 统一入口仍是 `BuildOrRunPerf.sh`
- 兼容 wrapper 仍保留
- 守门 contract 是：
  - `bash tests/test_active_shell_runners.sh`
  - `bash tests/test_fs_perf_shell_scripts.sh`

tail README 会把 today shell 叙事回退成旧版说明，和当前实际脚本 contract 不再一致。

## Reclassification

因此，这组路径现在应被重新定性为：

- `current-HEAD-ahead`
- `reviewed and intentionally skipped`
- `no-absorb`

也就是说：

- 不能再把它们当成 `tail` 的“下一批该吸收内容”
- 它们更适合被视为已经完成 fresh review 的 stale/regressive cluster
- today shell/runner contract 继续由主线现状 + contract tests 守住

## Why this is safe

- 没有丢掉 today contract；相反，是拒绝把更旧的 shell/runner 版本回灌进来
- `tail` 仍保留为 retained ref；这轮没有做删除
- `pairwise_cleanup_readiness=review-exclusive-batches-first` 仍保持原判
- Windows exact native evidence 纪律不变：只认 GitHub Actions / 真实 Windows runner
- 没有碰 SIMD

## What changes after this audit

从这轮开始：

1. `tests/cleanup_orphan_dirs.sh` + fs perf wrapper/README 不再被视为 `tail` 的 live absorb target
2. 如果 inventory 继续给出 `next_focus=test-hygiene-first`，也不能直接等价理解成“先吸收这组 shell/runner”
3. 这组 today contract 的本地守门入口继续固定为：
   - `bash tests/test_active_shell_runners.sh`
   - `bash tests/test_fs_perf_shell_scripts.sh`
4. `tail` 的下一跳应回到 overlap / inventory 去看其他 exclusive batches，而不是重复审这组已判定 head-ahead 的 shell/runner cluster

## Verification

```bash
bash tests/test_active_shell_runners.sh
bash tests/test_fs_perf_shell_scripts.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh
bash tests/report_strict_l0_retained_refs_inventory.sh --details
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```
