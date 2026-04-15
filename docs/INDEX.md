# 文档总索引

本页只保留长期有效的入口，不再手工维护一份庞大的“全量清单”。

## 开始阅读

- 文档治理与放置规则：`docs/README.md`
- 架构分层：`docs/ARCHITECTURE_LAYERS.md`
- L0 稳定路线图：`docs/fafafa.core.l0.roadmap.md`
- L0 详细定义：`docs/fafafa.core.l0.foundation.md`
- L0 当前审计：`docs/audits/2026-04-11-l0-current-state-audit.md`
- tail shell/runner head-ahead / no-absorb 审计：`docs/audits/2026-04-15-l0-tail-shell-runner-head-ahead-no-absorb-audit.md`
- tail residual runner/source no-absorb 审计：`docs/audits/2026-04-15-l0-tail-residual-runner-source-no-absorb-audit.md`
- sidecar async runner slice 审计：`docs/audits/2026-04-15-l0-sidecar-async-runner-slice-audit.md`
- retained refs post-merge sidecar/tail 审计：`docs/audits/2026-04-14-l0-retained-refs-sidecar-tail-postmerge-audit.md`
- L0 当前延续计划：`docs/plans/2026-04-16-l0-mainline-continuation-plan.md`
- L0 历史批次 / 审计归档：`docs/legacy/l0/README.md`
- 工程规范：`docs/standards/ENGINEERING_STANDARDS.md`
- 目录规范：`docs/standards/DIRECTORY_STANDARDS.md`
- 命名规范：`docs/standards/NAMING_CONVENTION_PROJECT.md`
- 测试指南：`docs/TESTING.md`
- CI 指南：`docs/CI.md`
- 示例总览：`docs/EXAMPLES.md`
- 变更日志：`docs/CHANGELOG.md`

## Strict L0 模块入口

- `docs/fafafa.core.base.md`
- `docs/fafafa.core.contracts.md`
- `docs/fafafa.core.option.md`
- `docs/fafafa.core.result.md`
- `docs/fafafa.core.span.md`
- `docs/fafafa.core.bits.md`
- `docs/fafafa.core.platform.md`
- `docs/fafafa.core.layout.md`
- `docs/fafafa.core.endian.md`
- `docs/fafafa.core.atomic.md`
- `docs/fafafa.core.mem.md`

## 模块文档入口

模块主文档使用统一命名：

- `docs/fafafa.core.<module>.md`

模块扩展文档使用：

- `docs/fafafa.core.<module>.<topic>.md`

例如：

- `docs/fafafa.core.base.md`
- `docs/fafafa.core.contracts.md`
- `docs/fafafa.core.bits.md`
- `docs/fafafa.core.platform.md`
- `docs/fafafa.core.layout.md`
- `docs/fafafa.core.endian.md`
- `docs/fafafa.core.atomic.md`
- `docs/fafafa.core.option.md`
- `docs/fafafa.core.result.md`
- `docs/fafafa.core.mem.md`
- `docs/fafafa.core.span.md`
- `docs/fafafa.core.collections.md`
- `docs/fafafa.core.fs.md`
- `docs/fafafa.core.simd.md`

## 当前稳定子目录

当前仓库里真实存在、可以直接当导航入口使用的子目录包括：

- `docs/collections/`
- `docs/benchmarks/`
- `docs/adr/`
- `docs/standards/`
- `docs/reports/`
- `docs/reviews/`
- `docs/audits/`
- `docs/plans/`
- `docs/legacy/`
- `docs/refactoring/`
- `docs/topics/`
- `docs/design/`
- `docs/designs/`

说明：

- `mem`、`fs`、`term`、`lockfree`、`simd` 当前仍以 `docs/fafafa.core.<module>.md` 这类根入口定锚。
- 不要把旧路线图里的 `docs/mem/`、`docs/term/`、`docs/fs/`、`docs/lockfree/`、`docs/simd/` 当成当前仓库里已经存在的目录。
- 这些主题的历史阶段报告优先下沉到 `archive/reports/`，而不是再在 `docs/` 根层扩散。

## 如何判断一份文档是否权威

按下面顺序判断：

1. `docs/standards/*.md`
2. `docs/ARCHITECTURE_LAYERS.md`
3. `docs/fafafa.core.l0.foundation.md` / `docs/fafafa.core.l0.roadmap.md` 这类稳定主题入口
4. `docs/fafafa.core.<module>.md`
5. 真实存在的领域子目录中的长期文档
6. `docs/audits/`、`docs/plans/`、`docs/reports/`、`docs/reviews/`
7. `docs/legacy/` 与 `archive/reports/`

## 当前特别说明

- `docs/Architecture.md` 这种歧义命名已经停止作为全局架构入口使用。
- 历史 `PHASE0_*` 文档已归档到 `docs/legacy/phase0/`；当前 L0 以 `docs/fafafa.core.l0.foundation.md` 为准。
- L0 的长期路线图现在固定为 `docs/fafafa.core.l0.roadmap.md`；`docs/plans/2026-03-24-l0-docs-closeout-roadmap.md` 只保留更早一轮 docs 治理路线图语境，其他 superseded L0 批次计划/审计已统一下沉到 `docs/legacy/l0/README.md`。
- strict L0 已在 `main` 完成合并；`docs/legacy/l0/README.md` 记录了更早的 merge checklist、batch closeout、dated current-state audit 和 rescue closeout 历史。
- `docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md` 记录了当前残留 L0 refs 的审计结论，以及为什么这一步没有继续盲删历史 refs。
- 当前如果要判断 strict L0 的真实状态，优先看 `docs/audits/2026-04-11-l0-current-state-audit.md`、`docs/fafafa.core.l0.roadmap.md` 和 `docs/plans/2026-04-16-l0-mainline-continuation-plan.md`。
- 当前 retained-refs latest review closeout 入口固定为 `docs/audits/2026-04-15-l0-tail-shell-runner-head-ahead-no-absorb-audit.md`。
- `tail` residual runner/source no-absorb 入口继续固定为 `docs/audits/2026-04-15-l0-tail-residual-runner-source-no-absorb-audit.md`。
- `sidecar` async runner slice 入口继续固定为 `docs/audits/2026-04-15-l0-sidecar-async-runner-slice-audit.md`。
- `closeout/rescue` 的 source-review clearout 入口继续固定为 `docs/audits/2026-04-15-l0-closeout-rescue-final-source-review-clearout-audit.md`。
- Linux x64 的 strict L0 日常维护入口固定为 `bash tests/run_strict_l0_maintenance_loop.sh`；它会串起 docs consistency、active shell runners、examples/build current-entry contract、gate、`git diff --check`、runtime matrix 和 native closeout stack。
- strict L0 在 `main` 上的一波收口入口固定为 `bash tests/run_strict_l0_mainline_closeout.sh`；需要实际覆盖 current-state 文档时显式加 `--apply-docs`。
- 如果你已经拿到 Linux / Windows run id，只需要回填 current-state 审计、legacy closeout 和 worker handoff，入口固定为 `bash tests/update_strict_l0_current_state_docs.sh --apply ...`。
- 如果你要重新审计当前保留的历史 L0 refs 是否仍承载独立 patch history，入口固定为 `bash tests/audit_strict_l0_retained_refs.sh`；它只给 decision，不做删除。
- 如果你要先判断 retained refs 该从哪类 unique history 开始吸收，入口固定为 `bash tests/report_strict_l0_retained_refs_inventory.sh`；它会把 unique history 按 archive docs / current docs / code/tests / examples-build 分类。
- 如果你要直接看到每条 retained ref 的代表性 unique commits 和路径样本，使用 `bash tests/report_strict_l0_retained_refs_inventory.sh --details`。
- 第七波之后，`--details` 还会继续给出 `next_focus=` 与 `docs_absorb_candidate_paths=`，并把 docs residue 继续拆成 root entry、module docs、topics/guides、archive pointers、collections dated docs、legacy docs 和 report topics。
- 第七波之后，`sidecar/tail` 这两条 retained refs 的 low-risk docs residue landing zone 继续固定到 `docs/collections/legacy/README.md` 与几份 `docs/*/reports/README.md` 指路页。
- 第八波之后，`--details` 还会继续给出 `test_hygiene_candidate_paths=` 与 `source_review_candidate_paths=`，把 `sidecar/tail` 和 `closeout/rescue` 的当前下一跳直接暴露出来。
- 第九波之后，`sidecar/tail` 的一批 tracked test-hygiene residue 已经从主线真实清掉；如果 `closeout/rescue` 继续是 `source-review-first`，当前标准入口固定为 `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`。
- 第九波之后，shortlist 还会继续显式给出 `review_candidate_paths=`、`review_skip_paths=`、`simd_out_of_scope_paths=`、`dangerous_delete_paths=` 与 `reject_wholesale_absorb=`，帮助拒绝 broad absorb；其中 `review_skip_paths=` 专门承接已经完成 fresh 复核的 stale/no-op hotspot，避免重复人工审查。
- 第 2026-04-14 波之后，`closeout` 的 `mem allocator + fs perf wrapper/README` cluster 与 `rescue` 的 `mem/result/span + base/bits/contracts/result/span test-entry` cluster 也已经统一沉到 `review_skip_paths=`；它们不再是新的人工吸收入口。
- 同日后续波之后，`rescue` 的 examples/build/runner/doc stale cluster 也已经统一沉到 `review_skip_paths=`；尤其 `examples/fafafa.core.atomic/base/option/result` 的 `BuildOrRun*` / example source 和 `tests/fafafa.core.{endian,layout,mem,option,platform}` 的 stale runner/doc 不再是新的人工吸收入口。
- 同日后续波还确认 `docs/collections/legacy/README.md`、`docs/reports/README.md`、`docs/collections/reports/README.md`、`docs/benchmarks/reports/README.md` 与 `docs/legacy/l0/README.md` 的 landing-zone 叙事已经是 today contract；如果 `docs_absorb_candidate_paths=` 再暴露这些路径，优先判 stale/no-absorb，而不是回灌 `sidecar` 的旧 pointer 文本。
- 第 2026-04-15 波之后，fresh shortlist 已固定给出 `closeout.review_candidate_paths=0` 与 `rescue.review_candidate_paths=0`；这表示 `closeout/rescue` 的 source-review surface 已清空。
- 同日又确认：最后一个看起来像候选的 `tests/fafafa.core.collections/vecdeque/Test_vecdeque_span.pas`，其实是未接线且依赖已移除 `SliceView` API 的 stale dead test code；它继续只应留在 `review_skip_paths=`，不能再被当成 today contract 证据。
- 同日 fresh diff 还确认：`tests/cleanup_orphan_dirs.sh`、`tests/fafafa.core.fs/{ArchivePerfResult,BuildOrRunPerf,BuildOrRunResolvePerf,BuildOrRunPerfAll}.sh` 与 `tests/fafafa.core.fs/README-perf.md` 这组 tail shell/runner cluster 已经是 current-HEAD-ahead / no-absorb；today shell contract 继续以 `bash tests/test_active_shell_runners.sh` 与 `bash tests/test_fs_perf_shell_scripts.sh` 为准，不能按 tail 版本回灌。
- 同日 fresh diff 还确认：`src/fafafa.core.atomic.base.pas` 与 `src/fafafa.core.span.pas` 只剩 no-op residue；`tests/fafafa.core.option/BuildOrTest.bat` 与 `tests/fafafa.core.result/BuildOrTest.bat` 则属于 current-HEAD-ahead / no-absorb。today contract 固定为 `bash tests/test_l0_option_result_runner_hygiene.sh`。
- 同日 `sidecar` 的唯一 exclusive mixed batch 只切片吸收了 async runner hygiene；today contract 固定为 `bash tests/test_l0_async_test_runner_hygiene.sh`，不能把 inventory 的 `test-hygiene-first` 继续泛化成 broad sidecar absorb。
- 因此接下来如果 retained-refs 还要继续推进，优先回到 `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh` 或 inventory，而不是重新把 `closeout/rescue` shortlist 当成新的吸收入口。
- 第 2026-04-14 波之后，如果你当前关心的是 `sidecar/tail` 在 merged-main 之后还能不能删、各自还剩什么 exclusive batch，当前标准入口固定为 `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`。
- fresh overlap 已固定说明：`sidecar_only_commit_count=1`、`tail_only_commit_count=8`，并且 `sidecar_safe_delete_now=no`、`tail_safe_delete_now=no`。
- 根目录 `task_plan.md`、`findings.md`、`progress.md` 已从主线移除；最后一份快照归档在 `plans/archive/2026-04-07-mainline-working-set/`。
- 当前 L0 协作入口见 `workers/worker1.md`，当前 triage 判断见 `docs/audits/2026-04-11-l0-current-state-audit.md`，历史批次上下文见 `docs/legacy/l0/README.md`。
- `docs/fafafa.core.span.md`、`docs/fafafa.core.contracts.md` 和 `docs/fafafa.core.platform.md` 现在都对应 strict L0 的实体入口。
- 旧的 L0 candidate / merge-closeout 文档已经归档到 `docs/legacy/l0/`，不要再把那批候选结论当作 current-entry。
- `fafafa.core.span` 现在同时承载最小 `span` / `span2` contract；但 `fafafa.core.collections.slice` 仍然不等同于 strict L0，不要把 collections 的容器 `SliceView` 语义误读成已下沉到 L0。
- VecDeque 相关设计文档已归位到 `docs/collections/design/vecdeque-architecture.md`。
- `lockfree`、`mem`、`fs`、`term`、`simd` 当前仍以各自的 `docs/fafafa.core.<module>.md` 根文档作为 current-entry；不要从旧 closeout 文档里继承不存在的 `docs/<domain>/` 路径。
- `mem` / `term` / `sync` / `collections` 的历史完成报告、状态总结和实施总结，当前统一下沉到 `archive/reports/docs-root/`。
- SIMD 专题材料仍由 SIMD owner 维护；L0 这里只保留边界、审计和 handoff 说明。
- 已完成的根目录修复报告已迁移到 `archive/reports/`。
- collections / benchmarks 的阶段性 campaign 报告已迁移到 `archive/reports/docs-collections/` 与 `archive/reports/docs-benchmarks/`；原目录只保留归档指路页。
- collections 域内带日期的 plan / status / review 也已下沉到 `docs/collections/legacy/README.md`；当前入口仍以 `docs/fafafa.core.collections.md` 与 `docs/collections/guides/` 为准。
- examples current-entry 现在优先固定到各 domain 的 `examples/<module>/README.md`、`BuildOrRun*` 与 `.lpr` / `.lpi`；`bin/`、`lib/` 和本地 logs 不再当成稳定入口。
- `docs/reports/` 根下 dated fix/checkpoint/verification/audit 报告已基本迁移到 `archive/reports/docs-root/`；当前只保留 `docs/reports/time/` 这样的主题子目录与说明页。
- `UnChecked_Methods_Summary.md` 已从 `docs/reports/` 转正到 `docs/collections/guides/UnChecked_Methods_Summary.md`。
- 一批 root-level 的阶段性模块完成/测试报告也已迁到 `archive/reports/docs-root/`；不要再把 `completion-report` / `test-report` / `week*` 日报留在 `docs/` 根目录。
