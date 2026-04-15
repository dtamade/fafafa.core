# 2026-04-14 L0 Closeout/Rescue Stale Skip Audit

> 这份审计记录 strict non-SIMD L0 在 `source-review-first` 路线上，对 `closeout/rescue` 剩余高噪音 retained-ref 候选做 fresh review 后的收口结果。

## Scope

这轮只处理 `closeout/rescue` 的 retained-ref stale surface：

- `closeout`
  - `src/fafafa.core.mem.allocator.pas`
  - `tests/fafafa.core.fs/{ArchivePerfResult,BuildOrRunPerf,BuildOrRunPerfAll,BuildOrRunResolvePerf}.sh`
  - `tests/fafafa.core.fs/README-perf.md`
- `rescue`
  - `src/fafafa.core.mem.allocator.pas`
  - `src/fafafa.core.result.pas`
  - `src/fafafa.core.span.pas`
  - `tests/fafafa.core.{base,bits,contracts,result,span}/BuildOrTest.bat`
  - `tests/fafafa.core.{base,bits,contracts,result,span}/*.test.lpr`
  - `tests/fafafa.core.{base,bits,contracts,result,span}/README.md`

## Review result

### closeout

- `src/fafafa.core.mem.allocator.pas`
  - 只有头注释措辞差异
  - 当前 HEAD 已与 `docs/fafafa.core.l0.foundation.md` / `docs/ARCHITECTURE_LAYERS.md` 一致：strict L0 core 是 `allocator.base`
  - 结论：**skip**
- fs perf wrapper / README cluster
  - retained ref 会回退当前统一 shell 入口、wrapper 语义与 README contract
  - `ArchivePerfResult.sh` 会回到双次执行 perf 的旧行为
  - `BuildOrRunPerf.sh` 会丢掉当前统一子命令入口
  - `BuildOrRunPerfAll.sh` / `BuildOrRunResolvePerf.sh` / `README-perf.md` 都会回到旧 wrapper 叙事
  - 结论：**stale downgrade → skip**

### rescue

- `src/fafafa.core.mem.allocator.pas`
  - rescue 会把 strict L0 优先入口重新写成 `allocator.foundation`
  - 这与 today L0 boundary 冲突
  - 结论：**stale boundary regression → skip**
- `src/fafafa.core.result.pas`
  - rescue 会把当前顶层组合子整批收缩回 `FAFAFA_CORE_ANONYMOUS_REFERENCES` 宏内
  - 当前 HEAD 明确保留传统函数指针 fallback；`FAFAFA_FORCE_NO_ANON + @GlobalFunc` 仍可编译
  - rescue 唯一像“改进”的别名整理只是样式级变化，不值得吸收
  - 结论：**stale API-surface regression → skip**
- `src/fafafa.core.span.pas`
  - rescue 会删掉 `TReadOnlySpan2<T>` / `GetBlock` / `SubSpan` 等 today contract
  - 结论：**stale span2 regression → skip**
- `BuildOrTest.bat` / `*.test.lpr` / `README.md` cluster
  - Windows runner 会回退到旧逻辑
  - `*.test.lpr` 会删掉统一 `settings.inc`
  - README 会回退 current-entry narrative
  - 结论：**stale runner/test-entry/doc regression → skip**

## What changed

- `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
  - 把上述 closeout/rescue stale cluster 下沉到 `review_skip_paths=`
- current-state docs / worker handoff
  - 明确这批 surface 已完成 fresh review
  - 明确它们不应再作为新的人工吸收入口

## Why this is safe

- 没有 broad absorb retained refs
- 没有改变 strict L0 boundary
- 没有回灌旧 runner / 旧 README narrative
- 没有碰 SIMD
- Windows exact native evidence 纪律不变：只认 GitHub Actions / 真实 Windows runner

## Verification

```bash
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
bash tests/test_update_strict_l0_current_state_docs_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/fafafa.core.result/BuildOrTest.sh test
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

## Current conclusion

- `closeout` 的 source-review candidate 应视为已清空；保留的只是 `review_skip_paths=` 记录
- `rescue` 的 boundary / runner / test-entry stale cluster 已完成 fresh review，不再值得继续人工重审
- 下一轮若还要沿 retained refs 往前推，应只看 **尚未进入 `review_skip_paths=` 的剩余候选**
