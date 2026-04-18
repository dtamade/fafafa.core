# fafafa.core 文档说明

推荐从 `docs/INDEX.md` 进入：这里是**唯一需要手工维护**的总索引页。

## 快速入口

- 文档总索引：`docs/INDEX.md`
- L0 稳定路线图：`docs/fafafa.core.l0.roadmap.md`
- L0 详细定义：`docs/fafafa.core.l0.foundation.md`
- 当前 L0 审计：`docs/audits/2026-04-11-l0-current-state-audit.md`
- tail shell/runner head-ahead / no-absorb 审计：`docs/audits/2026-04-15-l0-tail-shell-runner-head-ahead-no-absorb-audit.md`
- tail residual runner/source no-absorb 审计：`docs/audits/2026-04-15-l0-tail-residual-runner-source-no-absorb-audit.md`
- sidecar async runner slice 审计：`docs/audits/2026-04-15-l0-sidecar-async-runner-slice-audit.md`
- sync current example build repair 审计：`docs/audits/2026-04-19-l0-sync-current-example-build-repair-audit.md`
- sync condvar current-entry repair 审计：`docs/audits/2026-04-19-l0-sync-condvar-current-entry-build-repair-audit.md`
- sync.mutex current-entry repair 审计：`docs/audits/2026-04-19-l0-sync-mutex-current-entry-codetools-include-repair-audit.md`
- closeout/rescue source-review final clearout 审计：`docs/audits/2026-04-15-l0-closeout-rescue-final-source-review-clearout-audit.md`
- closeout/rescue final 10-path stale-skip 审计：`docs/audits/2026-04-19-l0-closeout-rescue-final-10path-stale-skip-audit.md`
- retained refs post-merge sidecar/tail 审计：`docs/audits/2026-04-14-l0-retained-refs-sidecar-tail-postmerge-audit.md`
- L0 当前延续计划：`docs/plans/2026-04-16-l0-mainline-continuation-plan.md`
- L0 历史批次 / 审计归档：`docs/legacy/l0/README.md`
- 测试指南：`docs/TESTING.md`
- CI 指南：`docs/CI.md`
- 目录结构规范：`docs/standards/DIRECTORY_STANDARDS.md`
- 工程规范：`docs/standards/ENGINEERING_STANDARDS.md`
- 命名规范：`docs/standards/NAMING_CONVENTION_PROJECT.md`

## L0 当前导航

- L0 的稳定文档栈固定为：`docs/ARCHITECTURE_LAYERS.md` + `docs/fafafa.core.l0.foundation.md` + `docs/fafafa.core.l0.roadmap.md` + 最新 `docs/audits/*l0*.md`
- strict L0 模块入口统一收在 `docs/INDEX.md` 的 `Strict L0 模块入口` 区段
- strict L0 已经合并到 `main`；superseded 的 dated L0 plans/audits 统一下沉到 `docs/legacy/l0/`
- 当前如果要继续沿 L0 维护，优先看最新 audit、roadmap、foundation 和当前 continuation plan
- 当前 retained-refs stale-review 收口入口固定为：`docs/audits/2026-04-15-l0-closeout-rescue-final-source-review-clearout-audit.md`
- 当前 tail shell/runner no-absorb 收口入口固定为：`docs/audits/2026-04-15-l0-tail-shell-runner-head-ahead-no-absorb-audit.md`
- 当前 tail residual runner/source no-absorb 收口入口固定为：`docs/audits/2026-04-15-l0-tail-residual-runner-source-no-absorb-audit.md`
- 当前 sidecar async runner slice 收口入口固定为：`docs/audits/2026-04-15-l0-sidecar-async-runner-slice-audit.md`
- 当前 sync `example_sync` current-entry build 修复入口固定为：`docs/audits/2026-04-19-l0-sync-current-example-build-repair-audit.md`
- 当前 sync.condvar current-entry 修复入口固定为：`docs/audits/2026-04-19-l0-sync-condvar-current-entry-build-repair-audit.md`
- 当前 sync.mutex current-entry 修复入口固定为：`docs/audits/2026-04-19-l0-sync-mutex-current-entry-codetools-include-repair-audit.md`
- Linux x64 的日常维护入口固定为：`bash tests/run_strict_l0_maintenance_loop.sh`；它会串起 `bash tests/check_strict_l0_docs_consistency.sh`、`bash tests/check_repo_submodule_hygiene.sh`、`bash tests/test_active_shell_runners.sh`、`bash tests/test_strict_l0_examples_build_docs_contract.sh`、`bash tests/test_strict_l0_examples_smoke_contract.sh`、gate、`git diff --check`、runtime matrix 和 native closeout stack
- 当前 retained-refs triage 继续固定为：先看 `next_focus=`，再看 `test_hygiene_candidate_paths=` / `source_review_candidate_paths=` / `docs_absorb_candidate_paths=`；如果是 `source-review-first`，继续跑 `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
- 第 2026-04-15 波之后，`docs/audits/2026-04-15-l0-closeout-rescue-final-source-review-clearout-audit.md` 仍保留一波 clearout 的历史语境；但 current-entry 不再把这件事直接写成今天已经清空。现在要以 fresh `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 输出为准，只有它同时给出 `closeout.review_candidate_paths=0` 与 `rescue.review_candidate_paths=0`，才把 `closeout/rescue` 视为已清空；否则继续按 fresh shortlist 非零结果推进，而不是重开 broad absorb
- 第 2026-04-19 波之后，最后一簇 `env/os.unix/sync.mutex` source trio + `json/sync.mutex` examples cluster 也已经有了明确反证：前者受 `bash tests/test_os_unix_ifdef_elseif_compat_contract.sh` 约束，后者受 `bash tests/test_strict_l0_sync_mutex_example_older_fpc_contract.sh` 与 `bash tests/test_strict_l0_examples_smoke_contract.sh` 约束。因此它们继续只应落在 `review_skip_paths=`，不应再被当成新的吸收入口
- 同日 fresh diff 还确认：`tests/cleanup_orphan_dirs.sh` + `tests/fafafa.core.fs/{ArchivePerfResult,BuildOrRunPerf,BuildOrRunResolvePerf,BuildOrRunPerfAll}.sh` + `tests/fafafa.core.fs/README-perf.md` 这组 tail shell/runner cluster 当前属于 current-HEAD-ahead / no-absorb；today contract 继续只由 `bash tests/test_active_shell_runners.sh` 与 `bash tests/test_fs_perf_shell_scripts.sh` 守住，不再按 tail 版本回灌
- 同日 fresh diff 还确认：`src/fafafa.core.atomic.base.pas` 与 `src/fafafa.core.span.pas` 只剩 no-op residue；`tests/fafafa.core.option/BuildOrTest.bat` 与 `tests/fafafa.core.result/BuildOrTest.bat` 则属于 current-HEAD-ahead / no-absorb。today contract 继续由 `bash tests/test_l0_option_result_runner_hygiene.sh` 守住
- 同日 `sidecar` 的唯一 exclusive mixed batch 也只切片吸收了 async runner hygiene，小撮 today contract 继续由 `bash tests/test_l0_async_test_runner_hygiene.sh` 守住；`examples/fafafa.core.sync*` 与 `examples/fafafa.core.sync.condvar*` 仍然 defer，不做 broad absorb
- 同日 `example_sync` 这条 current-entry 另行修到了 current API，并由 `bash tests/test_l0_sync_current_example_build.sh` 守住；它只覆盖 `example_sync.lpi`，不代表 `sync/condvar` 旧 runner 批次已经 ready
- 同日 `examples/fafafa.core.sync.condvar` 这条 current-entry 也单独修回了 today build/run；today contract 仅由 `bash tests/test_l0_sync_condvar_current_example_build.sh` 守住 current-entry build，不代表 `sync/condvar` sidecar runner hygiene 批次已经 ready
- 同日 `examples/fafafa.core.sync.mutex` 这条 current-entry 也单独补了两层 today contract：`bash tests/test_l0_sync_mutex_current_entry_codetools_include_clean.sh` 固定拒绝 `include file not found "fafafa.core.settings.inc"` 这类项目入口噪音，`bash tests/test_l0_sync_mutex_current_entry_default_run.sh` 固定拒绝 advanced example 因毫秒计时分辨率触发的 `EZeroDivide`；它们只覆盖 current-entry include/run 质量，不代表 `sync.mutex` broader runner/source absorb 已经 ready
- 当前几份 landing-zone docs：`docs/collections/legacy/README.md`、`docs/reports/README.md`、`docs/collections/reports/README.md`、`docs/benchmarks/reports/README.md` 与 `docs/legacy/l0/README.md` 继续以主线版本为准，不吸收 `sidecar` 的旧 pointer 叙事
- 如果当前问题是 `sidecar/tail` 在 merged-main 之后还能不能删、各自还剩什么 exclusive batch，标准入口切到：`bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`

## 文档放置约定（清理后的结构）

- **模块文档（主入口）**：`docs/fafafa.core.<module>.md`
- **模块扩展文档**：`docs/fafafa.core.<module>.*.md`（例如 best-practices / troubleshooting / api）
- **规范/清单**：`docs/standards/`
- **稳定路线图 / 主题设计**：优先使用长期可维护的主题入口，例如 `docs/fafafa.core.l0.roadmap.md`
- **执行批次计划**：放 `docs/plans/YYYY-MM-DD-*.md`，只描述某一轮 dated batch，不再承担长期 current-entry
- **L0 历史批次 / 审计**：统一下沉到 `docs/legacy/l0/`
- **Collections 历史 plans / status / reviews**：统一下沉到 `docs/collections/legacy/`
- **Examples current-entry**：优先使用各 domain 的 `examples/<module>/README.md`、`BuildOrRun*` 和 `.lpr` / `.lpi`；`bin/` / `lib/` / 本地 logs 不作为 source-of-truth
- **报告/复盘/审计/评审**：放 `docs/reports/`、`docs/audits/`、`docs/reviews/`（不要堆在 `docs/` 根目录）
- **历史报告归档**：统一下沉到 `archive/reports/docs-root/`、`archive/reports/docs-collections/`、`archive/reports/docs-benchmarks/`；原目录只保留 README 指路页
- **ADR**：`docs/adr/`
- **可复用片段**：`docs/partials/`
- **执行日志 / scratch 计划**：不要长期留在仓库根目录；需要入库时，直接归档到 `plans/archive/`，稳定结论再提升到 `docs/plans/` 或 `docs/audits/`

> 目标：`docs/` 根目录只保留“长期有效”的入口与模块文档，过程性文档集中到子目录，避免越堆越乱。
