# 2026-04-14 L0 Rescue Examples/Docs Stale Skip Audit

## Scope

这轮只继续收 `l0-main-rescue` 里已经 fresh 复核、确认只会回退 today contract 的 examples/build/runner/doc stale cluster，并补一条 sidecar landing-zone docs 的 no-absorb 结论。

不做：

- broad absorb
- retained refs 删除
- SIMD 相关改动
- Windows native evidence 纪律放松

## Reviewed stale-skip cluster

### Rescue examples/build

- `examples/fafafa.core.atomic/BuildOrRun.sh`
- `examples/fafafa.core.base/BuildOrRun.sh`
- `examples/fafafa.core.base/example_base.lpr`
- `examples/fafafa.core.option/BuildOrRun.sh`
- `examples/fafafa.core.result/BuildOrRun.sh`
- `examples/fafafa.core.result/example_result_filters_and_try.lpr`

结论：这些 diff 只会回退 today example entry、脚本协议或已整理过的头部/格式，不应吸收，统一转入 `review_skip_paths=`。

### Rescue stale runner / doc

- `tests/fafafa.core.endian/BuildOrTest.bat`
- `tests/fafafa.core.fs/ArchivePerfResult.sh`
- `tests/fafafa.core.fs/BuildOrRunPerf.sh`
- `tests/fafafa.core.fs/BuildOrRunPerfAll.sh`
- `tests/fafafa.core.fs/BuildOrRunResolvePerf.sh`
- `tests/fafafa.core.fs/README-perf.md`
- `tests/fafafa.core.layout/BuildOrTest.bat`
- `tests/fafafa.core.mem/BuildOrTest.bat`
- `tests/fafafa.core.mem/BuildOrTest.sh`
- `tests/fafafa.core.mem/README.md`
- `tests/fafafa.core.option/BuildOrTest.bat`
- `tests/fafafa.core.option/README.md`
- `tests/fafafa.core.platform/BuildOrTest.bat`

结论：这些 diff 会回退 `FAFAFA_SKIP_BUILD=1` runtime-only 路径、统一 wrapper contract、README current-entry 叙事或 today shell 行为，因此同样不应吸收，统一转入 `review_skip_paths=`。

## Sidecar docs no-absorb

以下 landing-zone docs 继续以主线当前版本为 today contract：

- `docs/collections/legacy/README.md`
- `docs/reports/README.md`
- `docs/collections/reports/README.md`
- `docs/benchmarks/reports/README.md`
- `docs/legacy/l0/README.md`

结论：`sidecar` 暴露的旧 archive-pointer / legacy-pointer 文本不应吸收。

## Shortlist outcome

fresh `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 输出：

- `closeout`
  - `review_candidate_paths=0`
  - `review_skip_paths=20`
- `rescue`
  - `review_candidate_paths=28`
  - `review_skip_paths=54`
  - `src_review_paths=5`
  - `test_code_review_paths=21`
  - `test_script_review_paths=2`
  - `test_doc_review_paths=0`
  - `examples_build_review_paths=0`
  - `dangerous_delete_paths=68`

这说明本波把 `rescue` 的 examples/build/runner/doc surface 从手工 review 池里继续剥离掉了；当前剩余的手工 review 面主要是 `time.tick.hardware.*` 这组 src 与一批 test code，以及两个 lowercase wrapper 脚本。

## Why this is safe

- 没有 broad absorb retained refs
- 没有改变 strict L0 boundary
- 没有回灌旧 example entry / 旧 runner / 旧 docs narrative
- 没有把 sidecar 旧 pointer 文本覆盖当前 landing-zone docs
- 没有碰 SIMD
- Windows exact native evidence 纪律不变：只认 GitHub Actions / 真实 Windows runner

## Verification

```bash
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

## Current conclusion

strict non-SIMD L0 下一轮如果继续看 `source-review-first`，不应再把这批 rescue examples/build/runner/doc stale cluster 当成新的吸收入口；它们现在和前一波已经确认的 stale/no-op hotspot 一样，属于 `review_skip_paths=`。
