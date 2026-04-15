# 2026-04-15 L0 Tail Residual Runner/Source No-Absorb Audit

> 这份审计记录 strict non-SIMD L0 在当前唯一 L0 worktree 上，对 `l0-main-tail-cleanup-20260408-final` 剩余最像“还可能要吸”的 runner/source residue 做 fresh 复核后的结论：**它们要么是 no-op residue，要么是 current-HEAD-ahead；不应继续 absorb。**

## Scope

这轮只复核 `tail` 上剩下的四类 residual surface：

- `src/fafafa.core.atomic.base.pas`
- `src/fafafa.core.span.pas`
- `tests/fafafa.core.option/BuildOrTest.bat`
- `tests/fafafa.core.result/BuildOrTest.bat`

纪律保持不变：

- 不 broad absorb retained refs
- 不删除 retained refs
- 不碰 SIMD lane

## Fresh evidence

fresh 复核命令：

```bash
git diff --ignore-space-at-eol HEAD..l0-main-tail-cleanup-20260408-final -- \
  src/fafafa.core.atomic.base.pas \
  src/fafafa.core.span.pas
git diff HEAD..l0-main-tail-cleanup-20260408-final -- \
  tests/fafafa.core.option/BuildOrTest.bat \
  tests/fafafa.core.result/BuildOrTest.bat
bash tests/test_l0_option_result_runner_hygiene.sh
bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh
bash tests/report_strict_l0_retained_refs_inventory.sh --details
```

fresh 结论：

- `src/fafafa.core.atomic.base.pas`
  - `--ignore-space-at-eol` 下已没有实质差异
  - 当前只剩 no-op residue，不构成 today absorb value
- `src/fafafa.core.span.pas`
  - `--ignore-space-at-eol` 下同样已没有实质差异
  - 当前也只剩 no-op residue
- `tests/fafafa.core.option/BuildOrTest.bat`
  - tail 版本会回退 today runner hygiene
  - 当前 HEAD 已固定为 `BuildOrTest.bat` + `BuildOrTest.sh` 并拒绝旧的 `buildOrTest.bat`
- `tests/fafafa.core.result/BuildOrTest.bat`
  - 结论与 `option` 相同
  - tail 版本会把 today runner parity / hygiene 往回拉

## Why the current HEAD is ahead

### Source residue: `atomic.base` / `span`

这两条路径在 fresh diff 下已经不再承载可吸收的 today 行为差异：

- 不是缺失功能
- 不是缺失 contract
- 不是缺失 today docs / runner 语义

因此它们应归类为：

- `reviewed`
- `no-op residue`
- `no-absorb`

### Runner residue: `option` / `result`

当前 HEAD 已经把这两组入口固定成 today hygiene contract：

- 保留 `BuildOrTest.bat`
- 保留 `BuildOrTest.sh`
- 明确拒绝残留小写 runner `buildOrTest.bat`

today 本地守门入口固定为：

```bash
bash tests/test_l0_option_result_runner_hygiene.sh
```

因此 tail 版本不是“主线缺的补丁”，而是会回退 today runner hygiene 的旧形态。

## Reclassification

从这轮开始，这 4 条路径统一重新定性为：

- `src/fafafa.core.atomic.base.pas`
  - `no-op residue`
  - `no-absorb`
- `src/fafafa.core.span.pas`
  - `no-op residue`
  - `no-absorb`
- `tests/fafafa.core.option/BuildOrTest.bat`
  - `current-HEAD-ahead`
  - `no-absorb`
- `tests/fafafa.core.result/BuildOrTest.bat`
  - `current-HEAD-ahead`
  - `no-absorb`

这意味着：

1. `tail` 的 residual runner/source surface 不再是 live absorb target
2. inventory 里的 `test-hygiene-first` 不能再泛化理解成“继续吃 option/result runner residue”
3. `tail` 下一跳应回到 overlap / inventory 去看别的 exclusive batch，而不是重复审这组已完成结论的 residual paths

## Why this is safe

- 没有丢 today contract；反而是在拒绝把更旧的 runner 版本回灌进主线
- 没有改 strict L0 boundary
- 没有删除 retained refs
- `tail_only_commit_count=8` 与 `pairwise_cleanup_readiness=review-exclusive-batches-first` 的整体结论不变
- Windows exact native evidence 纪律不变：只认 GitHub Actions / 真实 Windows runner
- 没有碰 SIMD

## Verification

```bash
bash tests/test_l0_option_result_runner_hygiene.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh
bash tests/report_strict_l0_retained_refs_inventory.sh --details
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```
