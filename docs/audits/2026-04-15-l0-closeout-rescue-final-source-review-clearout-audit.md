# 2026-04-15 L0 Closeout/Rescue Final Source Review Clearout Audit

> 这份审计记录 strict non-SIMD L0 在当前唯一 L0 worktree 上，对 `closeout/rescue` retained-ref source-review surface 做最后一轮 fresh clearout 的结果。

## Scope

这轮只处理 `closeout/rescue` 的最后一批 source-review surface，并坚持下面三条纪律：

- 不 broad absorb retained refs
- 不删除 retained refs
- 不碰 SIMD lane

最后一个看起来像“可能要吸收”的路径，是 `tests/fafafa.core.collections/vecdeque/Test_vecdeque_span.pas`；但 fresh API/runner 复核后确认它其实是 stale dead test code，不是 today contract 增量。

## Fresh shortlist evidence

fresh 命令：

```bash
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
```

fresh 输出结论：

- `closeout`
  - `review_candidate_paths=0`
  - `review_skip_paths=20`
  - `dangerous_delete_paths=55`
  - `reject_wholesale_absorb=yes`
- `rescue`
  - `review_candidate_paths=0`
  - `review_skip_paths=82`
  - `simd_out_of_scope_paths=30`
  - `dangerous_delete_paths=68`
  - `reject_wholesale_absorb=yes`

这说明 `closeout/rescue` 的 source-review shortlist 已经 fresh 清空；剩下的 retained-ref surface 不是“还没看”，而是已经被显式分类到 `review_skip_paths=`、`simd_out_of_scope_paths=` 或 `dangerous_delete_paths=`。

## Last apparent candidate: reclassified to stale dead test code

文件：

- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_span.pas`

fresh 复核结果：

- `tests/fafafa.core.collections/vecdeque/tests_vecdeque.lpr` 当前并没有注册这个 unit
- 一旦尝试把它重新接进 runner，fresh 编译会直接报错：`TVecDeque` 已没有 `SliceView`
- 这说明它不是 “today code 只差一点 parity 去耦”，而是 **未接线 + 依赖已移除 API** 的 stale residue

结论：

- 不吸收这份 test unit
- 继续把它留在 `review_skip_paths=`
- 它不能再被当成 strict L0 / collections 之间的 today contract 证据

## What moved to `review_skip_paths=`

除这条已被重新定性为 stale dead test code 的 vecdeque residue 外，其余 surface 也继续只作为 stale/no-op/regression skip 处理，主要包括：

- `closeout`
  - `mem allocator + fs perf wrapper/README` stale cluster
- `rescue`
  - `mem/result/span + base/bits/contracts/result/span test-entry` stale cluster
  - `examples/fafafa.core.atomic/base/option/result` 的 stale `BuildOrRun*` / example-source cluster
  - `tests/fafafa.core.{endian,layout,mem,option,platform}` 的 stale runner/doc cluster
  - `src/fafafa.core.time.tick.hardware.{aarch64,armv7a,i386,riscv32,riscv64}.pas` 的 whitespace/style-only residue

这些路径之所以不吸收，不是因为“没空处理”，而是因为它们会回退 today boundary、today runner contract、today docs narrative，或者只剩样式级噪音，不构成应并回主线的 today value。

## Why this is safe

- 没有 broad absorb `closeout` / `rescue`
- 没有改变 strict L0 boundary
- 没有把 dead/stale collections test code 误写成 strict L0 contract
- 没有碰 SIMD
- `dangerous_delete_paths=` 仍显式阻止 wholesale absorb
- Windows exact native evidence 纪律不变：只认 GitHub Actions / 真实 Windows runner

## Next focus

既然 `closeout/rescue` shortlist 已清空，retained-refs 的下一跳不再是这两条线的 source review，而是：

1. `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`
2. `bash tests/report_strict_l0_retained_refs_inventory.sh`
3. `bash tests/report_strict_l0_retained_refs_inventory.sh --details`

也就是说，后续如果还要继续推进 retained refs，应该回到 `sidecar/tail` 的 overlap/readiness 或整体 inventory，而不是重新把已经清空的 `closeout/rescue` shortlist 当作吸收入口。

## Verification

这轮收口至少应复跑：

```bash
bash tests/fafafa.core.collections/vecdeque/BuildOrTest.sh
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```
