# 2026-04-15 L0 Sidecar Async Runner Slice Audit

> 这份审计记录 strict non-SIMD L0 在当前唯一 L0 worktree 上，对 `l0-sidecar-handoff-20260409` 剩余唯一 exclusive commit 做 slice review 后，**只吸收 async test-runner hygiene 小批次** 的结论。

## Scope

这轮只处理 `sidecar` 的唯一 exclusive commit：

- `44974e49f2b3480c0c9a3f96c80bfe3a396ed619 chore(sync): preserve sidecar runner cleanup batch`

fresh `git show --stat --name-only` 已确认它是一个混合大包，里面同时包含：

- async tests / runners
- sync / condvar examples
- docs/audits 文字
- 本地日志 / 记录类路径

因此这轮只允许 small-cut slice absorb，不做整包回灌。

## What this wave absorbed

本波只吸收 async runner hygiene 小撮：

### `tests/fafafa.core.fs.async/`

- `BuildOrTest.bat`
- `run_async_tests.lpr`
- `test_async_basic.pas`
- `README.md`
- 删除 stale `test_simple.pas`
- 明确保持：`BuildOrTest.sh` 现在仍应缺席，直到 source blocker 真正解决

### `tests/fafafa.core.socket.async/`

- `BuildOrTest.bat`
- `BuildOrTest.sh`

## What this wave explicitly deferred

这轮明确不吸收下面这些 sidecar mixed-batch 内容：

- `examples/fafafa.core.sync*`
- `examples/fafafa.core.sync.condvar*`
- `docs/audits/l0_async_runner_audit_2026-04-08.md`
- `examples/fafafa.core.color/palette_demo.log`

也就是说：

- 不把 `sidecar` 的 sync/example lane 混回当前 L0 wave
- 不把 docs residue 和本地日志 residue 混进这轮 async runner hygiene
- 不 broad absorb `44974e49...`

## Fresh evidence

fresh 复核命令：

```bash
git show --stat --name-only --format=fuller 44974e49f2b3480c0c9a3f96c80bfe3a396ed619
git diff --stat HEAD..l0-sidecar-handoff-20260409 -- \
  tests/fafafa.core.fs.async \
  tests/fafafa.core.socket.async \
  examples/fafafa.core.sync \
  examples/fafafa.core.sync.condvar \
  docs/audits/l0_async_runner_audit_2026-04-08.md
bash tests/test_l0_async_test_runner_hygiene.sh
bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh
```

fresh 结论：

- `sidecar_only_commit_count=1`
- `pairwise_cleanup_readiness=review-exclusive-batches-first`
- exclusive commit `44974e49...` 仍然是 mixed batch
- async runner hygiene 这小撮现在已经在主线落地，并由独立 contract 守住

today 本地守门入口固定为：

```bash
bash tests/test_l0_async_test_runner_hygiene.sh
```

## Why this slice is safe

- 只动 async test-runner hygiene，不动 strict L0 公共 API 边界
- 不删 retained refs
- 不触碰 `examples/fafafa.core.sync*` / `examples/fafafa.core.sync.condvar*`
- 不把 `docs/audits/l0_async_runner_audit_2026-04-08.md` 误升成 today source-of-truth
- Windows exact native evidence 纪律不变：只认 GitHub Actions / 真实 Windows runner
- 不碰 SIMD

## Reclassification

从这轮开始：

1. `sidecar` 的唯一 exclusive commit 继续保留为 retained history
2. 但它里面的 async runner hygiene 小撮，已经不再是“未吸收 surface”
3. `sidecar` 后续如果还要推进，必须继续切片：
   - runner/test hygiene 可以继续 small-cut review
   - sync examples / condvar examples / docs residue 继续单独判断
4. 不能把 inventory 的 `test-hygiene-first` 泛化成 “整吃 sidecar mixed batch”

## Verification

```bash
bash tests/test_l0_async_test_runner_hygiene.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh
bash tests/report_strict_l0_retained_refs_inventory.sh --details
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```
