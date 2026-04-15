# 2026-04-11 L0 Current State Audit

> 这份审计反映 strict non-SIMD L0 在 latest mainline closeout 之后的 current state。

## Summary

- 当前 strict non-SIMD L0 的权威边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
- 当前 strict non-SIMD L0 的稳定路线图仍固定为 `docs/fafafa.core.l0.roadmap.md`。
- 当前这份 current-state audit 固定记录的 latest merged-main exact evidence head 是 `b8b5f719349bc68fc63da7fe51318af8a6af229f`。
- 当前 `origin/main` 与唯一 L0 worktree 当前都在 `b8b5f719349bc68fc63da7fe51318af8a6af229f`。
- 当前唯一 L0 branch 仍是 `l0-mainline`，它现在只是一个跟随 `origin/main` 的维护分支，不再承载未合并增量。
- Linux x64 的 strict L0 日常维护继续固定为 `bash tests/run_strict_l0_maintenance_loop.sh`；对应 GitHub Actions workflow `l0-linux-maintenance.yml` 已进入 default branch，并已在 `main` fresh 通过。
- strict L0 的 Windows native evidence 当前继续由 GitHub Actions run `24463558794` 提供 exact evidence，shell-side artifact verifier 已在 Linux x64 本地复核通过。
- collections 域里 dated 的 plans / status / reviews 已进一步下沉到 `docs/collections/legacy/README.md`；当前 collections 入口继续固定为 `docs/fafafa.core.collections.md` 与 `docs/collections/guides/`。
- examples current-entry 也已进一步收紧到各 domain README、`BuildOrRun*` 和 `.lpr` / `.lpi`；`bin/`、`lib/` 与本地 logs 不再作为 today contract 的入口。
- 第六波之后，retained-refs inventory 还会继续把 tests drift 细分成 test code / scripts / docs / runtime records / control files / output artifacts / binary artifacts，并显式输出 `next_focus=`。
- 第七波之后，retained-refs inventory 还会继续把 docs residue 细分成 root/module/topic/guide/archive-pointer/collections-dated/legacy/report-topic，并显式输出 `docs_absorb_candidate_paths=`。
- 第八波之后，retained-refs inventory 还会继续显式输出 `test_hygiene_candidate_paths=` 与 `source_review_candidate_paths=`，让 `sidecar/tail` 和 `closeout/rescue` 的当前下一跳直接可读。
- 第九波之后，`sidecar/tail` 的一批 tracked hygiene residue 已经从主线真实清掉；`closeout/rescue` 继续通过 `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 暴露 `review_candidate_paths=` / `review_skip_paths=` / `simd_out_of_scope_paths=` / `dangerous_delete_paths=` / `reject_wholesale_absorb=`。
- 第十波之后，`mem allocator callback` 的低风险 rescue 语义已经在主线内做了小型 current-entry hardening；`closeout` 的 6 个 test README candidate 也已被明确确认为 stale downgrade，并由 no-downgrade contract 锁住。
- 第 2026-04-14 波之后，`sidecar` 又吸收了一小段未覆盖的 runtime hygiene：`tests/fafafa.core.env/build_log.txt`、`tests/fafafa.core.env/fpcdebug.txt` 与 `tests/fafafa.core.mem.manager.rtl/mem_manager_heaptrc_output.txt` 已不再属于主线 tracked surface。
- 第 2026-04-14 波之后，如果当前问题是 `sidecar/tail` 在 merged-main 之后还能不能删、各自还剩什么 exclusive batch，标准入口固定为 `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`；fresh 结果是 `sidecar_only_commit_count=1`、`tail_only_commit_count=8`，且 `sidecar_safe_delete_now=no`、`tail_safe_delete_now=no`。
- 虽然 inventory `--details` 仍把 `tail` 暴露成 `next_focus=test-hygiene-first`，但 fresh diff 已确认 `tests/cleanup_orphan_dirs.sh` + `tests/fafafa.core.fs/{ArchivePerfResult,BuildOrRunPerf,BuildOrRunResolvePerf,BuildOrRunPerfAll}.sh` + `tests/fafafa.core.fs/README-perf.md` 这组 shell/runner cluster 当前属于 current-HEAD-ahead / no-absorb；today contract 继续由 `bash tests/test_active_shell_runners.sh` 与 `bash tests/test_fs_perf_shell_scripts.sh` 守住。
- 同日 fresh diff 还确认：`src/fafafa.core.atomic.base.pas` 与 `src/fafafa.core.span.pas` 只剩 no-op residue；`tests/fafafa.core.option/BuildOrTest.bat` 与 `tests/fafafa.core.result/BuildOrTest.bat` 则属于 current-HEAD-ahead / no-absorb。today contract 固定为 `bash tests/test_l0_option_result_runner_hygiene.sh`。
- fresh shortlist 现在还会把已经完成 fresh 复核、确认属于 current-HEAD-ahead / already-absorbed / stale-no-downgrade 的热点下沉到 `review_skip_paths=`；`atomic` / `mem allocator callback` / Windows native CI control-plane 与已被 no-downgrade contract 锁住的 stale test docs 不应再被重复当作新的手工吸收入口。
- 第 2026-04-14 波之后，`closeout` 的 `mem allocator + fs perf wrapper/README` cluster 与 `rescue` 的 `mem/result/span + base/bits/contracts/result/span test-entry` cluster 也已经完成 fresh review：它们分别只会回退 today boundary、today runner 或 today docs narrative，因此当前统一转入 `review_skip_paths=`，不做吸收。
- 同日后续波之后，`rescue` 的 `examples/fafafa.core.atomic/base/option/result` BuildOrRun/example-source cluster，以及 `tests/fafafa.core.{endian,layout,mem,option,platform}` 的 stale runner/doc cluster 也已经完成 fresh review：它们只会把 today example entry、today wrapper contract 或 today docs 叙事回退成旧版本，因此同样统一转入 `review_skip_paths=`。
- 同日后续波还再次确认：`docs/collections/legacy/README.md`、`docs/reports/README.md`、`docs/collections/reports/README.md`、`docs/benchmarks/reports/README.md` 与 `docs/legacy/l0/README.md` 这些 landing-zone docs 继续以当前主线版本为准；`sidecar` 暴露的旧 archive-pointer / legacy-pointer 文本不应吸收。
- 第 2026-04-15 波之后，`closeout/rescue` 的 source-review shortlist 已 fresh 清空：`closeout.review_candidate_paths=0`、`rescue.review_candidate_paths=0`。同时 fresh API/runner 复核还确认：最后一个看起来像候选的 `tests/fafafa.core.collections/vecdeque/Test_vecdeque_span.pas` 其实是未接线且依赖已移除 `SliceView` API 的 stale dead test code；它继续只留在 `review_skip_paths=`，不构成 today absorb。
- 同日 `sidecar` 的唯一 exclusive mixed batch 也只切片吸收了 async runner hygiene：`tests/fafafa.core.fs.async/*` 与 `tests/fafafa.core.socket.async/*` 的 today contract 现在固定由 `bash tests/test_l0_async_test_runner_hygiene.sh` 守住；`examples/fafafa.core.sync*` / `examples/fafafa.core.sync.condvar*` 仍继续 defer，不做 broad absorb。
- 当前 4 个残留 L0 refs 仍承载独立 patch history；refs cleanup 结论继续保持显式 `no-op`。

## Mainline Closeout Snapshot

- 当前 latest merged-main exact evidence head：`b8b5f719349bc68fc63da7fe51318af8a6af229f`
- 当前 `origin/main` head：`b8b5f719349bc68fc63da7fe51318af8a6af229f`
- 当前 L0 worktree head：`b8b5f719349bc68fc63da7fe51318af8a6af229f`
- GitHub Actions `L0 Linux Maintenance` run `24463267969`
  - head sha：`b8b5f719349bc68fc63da7fe51318af8a6af229f`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence` run `24463558794`
  - head sha：`b8b5f719349bc68fc63da7fe51318af8a6af229f`
  - 结果：`12/12 PASS`
- Linux shell verifier local snapshot：
  - `tests/_windows_l0_native_evidence_gh/L0-20260415-mainline-postmerge-closeout-windows/`

- 当前最新的 exact Windows native evidence 已直接对当前 `main@b8b5f719349bc68fc63da7fe51318af8a6af229f` 收证。

## Fresh Verification

- `bash tests/check_strict_l0_docs_consistency.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_docs_consistency_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_stable_docs_no_sha_contract.sh`
  - 结果：PASS
- `bash tests/test_update_strict_l0_current_state_docs_contract.sh`
  - 结果：PASS
- `bash tests/report_strict_l0_retained_refs_inventory.sh`
  - 结果：PASS
- `bash tests/report_strict_l0_retained_refs_inventory.sh --details`
  - 结果：PASS
- `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
  - 结果：PASS
- `bash tests/test_active_shell_runners.sh`
  - 结果：PASS
- `bash tests/test_fs_perf_shell_scripts.sh`
  - 结果：PASS
- `bash tests/test_l0_option_result_runner_hygiene.sh`
  - 结果：PASS
- `bash tests/test_l0_async_test_runner_hygiene.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_sidecar_hygiene_contract.sh`
  - 结果：PASS
- `bash tests/fafafa.core.env/BuildOrTest.sh build`
  - 结果：PASS
- `bash tests/fafafa.core.mem.manager.rtl/BuildOrTest.sh check`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_sidecar_tail_overlap_contract.sh`
  - 结果：PASS
- `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`
  - 结果：PASS
- `bash tests/audit_strict_l0_retained_refs.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_focus_routing_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_hygiene_absorption_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_linux_ci_workflow_contract.sh`
  - 结果：PASS
- `bash tests/test_windows_strict_l0_native_evidence_gh_contract.sh`
  - 结果：PASS
- `bash tests/test_windows_strict_l0_native_evidence_main_ref_contract.sh`
  - 结果：PASS
- `bash tests/run_strict_l0_maintenance_loop.sh`
  - 结果：PASS
- `git diff --check`
  - 结果：PASS
- GitHub Actions `L0 Linux Maintenance` run `24463267969`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence` run `24463558794`
  - 结果：PASS；`12/12`

## Current L0 Surface

- 基础语义：`settings.inc`、`base`、`contracts`、`option`、`result`
- 视图表达：`span`、`span2`
- 原始数据语义：`bits`、`platform`、`layout`、`endian`
- 内存模型：`atomic.core`、`atomic.base`、`atomic`、`atomic.compat`
- 分配契约：`mem.allocator.base`

当前边界没有变化。变化的是：current-entry 的验证证据已经从“本地闭环 + branch-local 历史探测”推进成了“main 上 fresh Linux + exact Windows evidence”。

## Current Maintenance Rules

- 当前唯一 L0 worktree 应继续保持在 `l0-mainline -> origin/main`。
- Linux x64 上的日常维护默认走 `bash tests/run_strict_l0_maintenance_loop.sh`。
- 如需 GitHub-side Linux 证据，当前标准命令是 `gh workflow run l0-linux-maintenance.yml --ref main`。
- 如需 GitHub-side Windows exact evidence，当前标准入口是 `l0-windows-native-evidence.yml`，并在下载后继续通过 `bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh <batch-id> <run-id>` 做 shell-side artifact 校验。
- 如需重新审计残留历史 L0 refs 是否仍承载独立 patch history，当前标准入口是 `bash tests/audit_strict_l0_retained_refs.sh`；它只给 decision，不直接删除 refs。
- 如需先判断 retained refs 该优先吸收哪一类 unique history，当前标准入口是 `bash tests/report_strict_l0_retained_refs_inventory.sh`；它会先给 absorb inventory，再决定下一批动作。
- 如需直接看代表性 unique commits 和路径样本，再执行 `bash tests/report_strict_l0_retained_refs_inventory.sh --details`。
- 第六波之后，`--details` 还会继续把 `code_or_tests` 细分成 `src / test source / test code / test script / test doc / runtime record / control file / CI workflow / output artifact / binary artifact`，并显式输出 `next_focus=`，方便继续做 retained-refs triage。
- 第七波之后，`--details` 还会继续给出 `docs_absorb_candidate_paths=`，把 sidecar/tail 上已经有稳定 landing zone 的 low-risk docs residue 直接暴露出来。
- 第八波之后，如果 `next_focus=test-hygiene-first`，优先看 `test_hygiene_candidate_paths=`；如果 `next_focus=source-review-first`，优先看 `source_review_candidate_paths=`；docs residue 则继续看 `docs_absorb_candidate_paths=`。
- 即使 inventory 继续给出 `next_focus=test-hygiene-first`，也不要默认把 `tests/cleanup_orphan_dirs.sh` 与 `tests/fafafa.core.fs/{ArchivePerfResult,BuildOrRunPerf,BuildOrRunResolvePerf,BuildOrRunPerfAll}.sh` 当成新的 `tail` absorb 入口；fresh diff 已确认当前 HEAD 在这组 shell/runner contract 上更先进。
- 这组 shell/runner today contract 的本地守门入口继续是 `bash tests/test_active_shell_runners.sh` 与 `bash tests/test_fs_perf_shell_scripts.sh`。
- 同日 fresh diff 还确认：`src/fafafa.core.atomic.base.pas` 与 `src/fafafa.core.span.pas` 只剩 no-op residue；`tests/fafafa.core.option/BuildOrTest.bat` 与 `tests/fafafa.core.result/BuildOrTest.bat` 则属于 current-HEAD-ahead / no-absorb。对应 today 守门入口固定为 `bash tests/test_l0_option_result_runner_hygiene.sh`。
- 第九波之后，如果 `next_focus=source-review-first`，当前标准入口是 `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`；它会继续显式输出 `review_candidate_paths=`、`review_skip_paths=`、`simd_out_of_scope_paths=`、`dangerous_delete_paths=` 与 `reject_wholesale_absorb=`。
- 第十波之后，如果 `closeout` 仍只剩 test-doc residue，先跑 `bash tests/test_strict_l0_retained_refs_closeout_test_docs_no_downgrade_contract.sh`，确认这些 README 没有把 current-entry 反向降级。
- 第 2026-04-14 波之后，如果 `closeout` shortlist 已清空，说明 `mem allocator + fs perf wrapper/README` 这组路径已经被判为 stale skip；它们只在 `tail` lane 里继续以 today shell hygiene contract 存在，不再是 `closeout` 的 source-review 候选。
- 同一波之后，`rescue` 里 `mem/result/span + base/bits/contracts/result/span test-entry` 这一簇也已经固定为 stale skip；尤其 `result` 的旧 anon-ref gating、`span` 的旧 single-span-only cut 与 `*.test.lpr` 缺 `settings.inc` 都不再应被当成吸收入口。
- 同日后续波之后，`rescue` 的 examples/build/runner/doc stale cluster 也已经固定为 stale skip；尤其 `examples/fafafa.core.atomic/base/option/result` 的 `BuildOrRun*` / example source、`tests/fafafa.core.{endian,layout,mem,option,platform}` 的 runner 变体，以及 `tests/fafafa.core.fs/README-perf.md`、`tests/fafafa.core.mem/README.md`、`tests/fafafa.core.option/README.md` 都不再应被当成新的吸收入口。
- 同日后续波还确认 `docs/collections/legacy/README.md`、`docs/reports/README.md`、`docs/collections/reports/README.md`、`docs/benchmarks/reports/README.md` 与 `docs/legacy/l0/README.md` 的 landing-zone 叙事已经是 today contract；如果 inventory 继续暴露这些 docs residue，优先判 stale/no-absorb，而不是回灌 `sidecar` 的旧 pointer 文本。
- 第 2026-04-15 波之后，如果 fresh shortlist 继续给出 `closeout.review_candidate_paths=0` 与 `rescue.review_candidate_paths=0`，说明 `closeout/rescue` 的 source-review surface 已清空；下一跳应回到 `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh` 或 retained-refs inventory，而不是重开 broad absorb。
- 第 2026-04-14 波之后，如果当前问题从 absorb class 变成了 `sidecar/tail` pairwise cleanup readiness，当前标准入口是 `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`；它会继续显式输出 `sidecar_only_commit_count=`、`tail_only_commit_count=`、`sidecar_safe_delete_now=`、`tail_safe_delete_now=` 与 `pairwise_cleanup_readiness=`。
- 同日如果当前问题落在 `sidecar` 的唯一 exclusive mixed batch 上，也不要 broad absorb；先把 async runner hygiene 限定到 `bash tests/test_l0_async_test_runner_hygiene.sh` 这一条 today contract，再把 sync/condvar examples 与 docs/log residue 继续留在 defer lane。
- 第九波之后，`tests/fafafa.core.archiver/last-run.txt`、`tests/fafafa.core.atomic/tests_atomic`、`tests/fafafa.core.sync.barrier/*_output.txt` 与 `tests/fafafa.core.fs/performance-data/*latest*` 这类 residue 已不再属于主线 tracked surface。
- 第 2026-04-14 波之后，`tests/fafafa.core.env/build_log.txt`、`tests/fafafa.core.env/fpcdebug.txt` 与 `tests/fafafa.core.mem.manager.rtl/mem_manager_heaptrc_output.txt` 也已从主线 tracked surface 移除，并由对应目录下的 `.gitignore` 接住。
- superseded 的 dated L0 plans / audits 现在统一下沉到 `docs/legacy/l0/`，不要再把那批文档当 current-entry。
- collections 域里 superseded 的 dated plans / status / reviews 现在统一下沉到 `docs/collections/legacy/README.md`，不要再把 `docs/collections/plans/`、`docs/collections/status/`、`docs/collections/reviews/` 里的历史批次误判成 current-entry。
- 当前保留的本地 L0 refs 只包括：
  - `l0-mainline`
  - `l0-mainline-closeout-20260411`
  - `l0-sidecar-handoff-20260409`
  - `l0-main-rescue`
  - `l0-main-tail-cleanup-20260408-final`

## Remaining Risks

- 根目录 `main` 工作树仍然是用户脏状态，不应把它误当成 L0 的当前执行面。
- 当前保留的 4 个历史 L0 refs 仍未被证明完全冗余，因此不能盲删。
- 后续若 strict L0 再发生非文档代码或测试改动，仍应重新收 fresh Windows exact evidence，而不是复用 `24463558794`；Linux x64 本地只能继续做 shell-side artifact verifier，不能伪造 exact Windows native 结论。
- SIMD owner 与 sidecar handoff 的职责边界没有变化；L0 这里不应重新吸收那些工作。
