# 2026-04-13 L0 Retained Refs Tenth Mem Callback And Doc Guard Audit

> 这份审计记录 strict non-SIMD L0 在第九波 hygiene/shortlist 之后，继续只吸收一小段低风险 `mem allocator callback` rescue 语义，并明确拒绝 `closeout` 里会反向降级 current-entry 的 test README residue。

## Why this wave exists

- 第九波之后，`closeout` 还剩 `review_candidate_paths=6`，全部落在 test README。
- 但 fresh diff 复核表明，这 6 个 README 并不是“主线缺失的补强说明”，而是会删掉：
  - `bash tests/run_strict_l0_maintenance_loop.sh`
  - exact Windows native evidence 只接受 GitHub Actions / 真实 Windows runner
  - `atomic` 目录里“runtime output 不纳入版本库”的 current-entry 边界
- 同时，`l0-main-rescue` 里还有一段真正适合 today current-entry 小波次吸收的 non-SIMD mem 语义：
  - `src/fafafa.core.mem.allocator.callbackAllocator.pas`
  - `src/fafafa.core.mem.allocator.pas`

## What this wave changes

这轮继续保持 non-destructive、small-cut：

1. `callbackAllocator` 构造前置条件顺序收紧
   - nil callback 验证现在先于 `inherited Create`
   - contracts 开启时，失败更早发生在对象初始化之前
   - contracts 关闭时，today policy 不变，仍只保证 smoke 可运行
2. `foundation` 测试入口补齐 nil callback policy 覆盖
   - `test_allocator_foundation_runtime.pas` 现在覆盖：
     - nil `GetMem`
     - nil `AllocMem`
     - nil `ReallocMem`
     - nil `FreeMem`
   - 并继续显式区分 `FAFAFA_CORE_CONTRACTS` / `FAFAFA_CORE_NO_CONTRACTS`
3. `mem.allocator` 门面 wording 与 today L0 边界重新对齐
   - strict L0 contract：`allocator.base`
   - low-level facade / 小 concrete backend：`allocator.foundation`
   - optional/compat aggregate：`allocator`
4. 新增 `closeout` test-doc no-downgrade contract
   - 新命令：
     - `bash tests/test_strict_l0_retained_refs_closeout_test_docs_no_downgrade_contract.sh`
   - 这条 contract 会锁住当前主线 README，不让 stale `closeout` diff 反向删掉 current-entry 说明

## Why this batch is safe

- 没有 broad merge `closeout` / `rescue`
- 没有改 strict L0 模块边界
- 没有触碰 SIMD / `time.tick.*`
- 没有把 `closeout` 的 stale test-doc diff 当成 docs absorb 波次
- `callbackAllocator` 只改变 constructor 的前置条件检查顺序，不改变 today public policy

## Closeout test-doc review result

fresh `closeout` test-doc residue 现在的结论应固定为：

- `tests/fafafa.core.atomic/README.md`
- `tests/fafafa.core.endian/README.md`
- `tests/fafafa.core.layout/README.md`
- `tests/fafafa.core.mem.allocator.foundation/README.md`
- `tests/fafafa.core.platform/README.md`
- `tests/fafafa.core.span/README.md`

这些路径当前不是 absorb candidate，而是 stale downgrade candidate。

更具体地说，它们会试图从主线 current-entry 删除：

- Linux x64 strict L0 maintenance loop 入口
- exact Windows native evidence discipline
- `atomic` README 中“logs/heaptrc 仅是本地运行期产物”的边界

所以第十波之后，对这 6 个 README 的 today policy 应改成：

- 不吸收
- 不 broad restore
- 用 no-downgrade contract 锁住主线

## Fresh shortlist snapshot

post-code-commit `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 结果（latest implementation head=`e7ca1fdf9bed0ffb130eb4195137f0518bc14f5d`）：

- `l0-mainline-closeout-20260411`
  - `review_candidate_paths=9`
  - `src_review_paths=2`
  - `test_code_review_paths=1`
  - `test_doc_review_paths=6`
  - `simd_out_of_scope_paths=0`
  - `dangerous_delete_paths=47`
  - `reject_wholesale_absorb=yes`
- `l0-main-rescue`
  - `review_candidate_paths=73`
  - `src_review_paths=10`
  - `test_code_review_paths=29`
  - `test_script_review_paths=16`
  - `test_doc_review_paths=12`
  - `examples_build_review_paths=6`
  - `simd_out_of_scope_paths=30`
  - `dangerous_delete_paths=60`
  - `reject_wholesale_absorb=yes`

这说明：

- 第十波把 `mem callback` 的 2 个 `src` 路径和 1 个 foundation test 路径真正吸进了 today mainline，因此 `closeout` 相对 latest implementation head 不再只是 6 个 stale test-doc 路径。
- 但 `closeout` 仍然带着显式 `dangerous_delete_paths=`，所以 today policy 依旧不是 absorb，而是保留 shortlist + no-downgrade guard。
- `rescue` 的 today 结论没有变化，仍然必须保持 `source-review-first`，不能 broad merge。

## Windows exact evidence status for this local wave

这轮包含了非文档代码 / 测试变化，因此 exact Windows native evidence 纪律没有放松；不同的是，这个 blocker 现在已经按 branch-scoped pre-merge closeout 方式被补齐：

- Windows exact native evidence 仍只接受 GitHub Actions / 真实 Windows runner
- 当前 **CI-covered branch head** 是 `bb2c4104f098699a9f387800b0688a11a12661c9`
- GitHub Actions `L0 Windows Native Evidence` run `24349338362` 已对这个 branch-visible head 收到 exact evidence
- Linux shell-side artifact verifier 也已对 `tests/_windows_l0_native_evidence_gh/L0-20260413-l0-premerge-ci-windows/` 复核通过

这说明：

- 之前“remote `l0-mainline` 落后于代码 / 测试 head，不能宣称 exact Windows coverage”的 blocker 已解除
- 当前 exact Windows evidence 现在覆盖的是 `bb2c4104...` 这个 pre-merge branch head
- 由于 `e7ca1fdf...` 之后新增的是 docs / control-plane-only 提交，因此第十波 implementation head 也包含在这个 branch-visible evidence 之内
- 但这仍然不是 merged `main` closeout；`update_strict_l0_current_state_docs.sh` 继续只留给真正的 `origin/main` 合并收口

## Fresh verification

- `bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test`
  - 结果：PASS
- `bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test-no-contracts`
  - 结果：PASS
- `bash tests/fafafa.core.mem/BuildOrTest.sh test`
  - 结果：PASS
- `bash tests/fafafa.core.mem/BuildOrTest.sh test-no-contracts`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_closeout_test_docs_no_downgrade_contract.sh`
  - 结果：PASS
- `bash tests/check_strict_l0_docs_consistency.sh`
  - 结果：PASS
- `bash tests/run_strict_l0_maintenance_loop.sh`
  - 结果：PASS
- GitHub Actions `L0 Linux Maintenance` run `24349423066`
  - head sha：`bb2c4104f098699a9f387800b0688a11a12661c9`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence` run `24349338362`
  - head sha：`bb2c4104f098699a9f387800b0688a11a12661c9`
  - 结果：`12/12 PASS`
- `git diff --check`
  - 结果：PASS

## Current policy after this wave

- retained-refs triage 继续保持：
  1. inventory `--details`
  2. `test-hygiene-first` 先吃 hygiene residue
  3. `source-review-first` 立刻跑 shortlist
  4. `dangerous_delete_paths>0` 时拒绝 wholesale absorb
- `closeout` 的 6 个 test-doc candidate 现在进一步固定成：
  - stale downgrade
  - no-downgrade contract guarded
  - not docs-absorb work
- `rescue` 继续只适合做更小的 source-review-first 波次

## Next move

下一跳更适合这样推进：

1. 保持 `closeout/rescue` 的 shortlist-first，而不是 broad merge
2. 如果继续吸收 `rescue`，优先挑非 SIMD、小而可验证的 `src` / test source patch
3. 当前若再发生非文档代码 / 测试变化，Linux x64 继续先跑 `bash tests/run_strict_l0_maintenance_loop.sh`
4. exact Windows native evidence 继续只在 remote-visible ref 上通过 CI 收集；当前 `l0-mainline` pre-merge head 已收齐，但 merged `main` closeout 仍需按 merge 后语义单独记录
