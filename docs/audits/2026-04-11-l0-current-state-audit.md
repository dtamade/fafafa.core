# 2026-04-11 L0 Current State Audit

> 这份审计反映 strict non-SIMD L0 在 latest mainline closeout 之后的 current state。

## Summary

- 当前 strict non-SIMD L0 的权威边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
- 当前 strict non-SIMD L0 的稳定路线图仍固定为 `docs/fafafa.core.l0.roadmap.md`。
- 当前这份 current-state audit 固定记录的 latest merged-main evidence head 是 `c4fcfcf744b87cb1f8b67ad84beccce6b22b9af8`。
- 后续 docs / handoff bookkeeping head 允许继续领先于该 evidence head，但只能是 docs / control-plane-only 增量。
- 当前唯一 L0 branch 仍是 `l0-mainline`，但它现在只是一个跟随 `origin/main` 的维护分支，不再承载未合并增量。
- Linux x64 的 strict L0 日常维护继续固定为 `bash tests/run_strict_l0_maintenance_loop.sh`；对应 GitHub Actions workflow `l0-linux-maintenance.yml` 已进入 default branch，并已在 `main` fresh 通过。
- strict L0 的 Windows native evidence 当前继续由 GitHub Actions run `24379333706` 提供 exact evidence，shell-side artifact verifier 已在 Linux x64 本地复核通过。
- collections 域里 dated 的 plans / status / reviews 已进一步下沉到 `docs/collections/legacy/README.md`；当前 collections 入口继续固定为 `docs/fafafa.core.collections.md` 与 `docs/collections/guides/`。
- examples current-entry 也已进一步收紧到各 domain README、`BuildOrRun*` 和 `.lpr` / `.lpi`；`bin/`、`lib/` 与本地 logs 不再作为 today contract 的入口。
- 第六波之后，retained-refs inventory 还会继续把 tests drift 细分成 test code / scripts / docs / runtime records / control files / output artifacts / binary artifacts，并显式输出 `next_focus=`。
- 第七波之后，retained-refs inventory 还会继续把 docs residue 细分成 root/module/topic/guide/archive-pointer/collections-dated/legacy/report-topic，并显式输出 `docs_absorb_candidate_paths=`。
- 第八波之后，retained-refs inventory 还会继续显式输出 `test_hygiene_candidate_paths=` 与 `source_review_candidate_paths=`，让 `sidecar/tail` 和 `closeout/rescue` 的当前下一跳直接可读。
- 第九波之后，`sidecar/tail` 的一批 tracked hygiene residue 已经从主线真实清掉；`closeout/rescue` 继续通过 `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 暴露 `review_candidate_paths=` / `simd_out_of_scope_paths=` / `dangerous_delete_paths=` / `reject_wholesale_absorb=`。
- 第十波之后，`mem allocator callback` 的低风险 rescue 语义已经在主线内做了小型 current-entry hardening；`closeout` 的 6 个 test README candidate 也已被明确确认为 stale downgrade，并由 no-downgrade contract 锁住。
- fresh shortlist 继续显示 `closeout` 不能整包吸收：它当前仍是 `2 src + 1 test code + 6 stale test docs + dangerous_delete_paths=48`；`rescue` 仍是 `source-review-first` 且 `dangerous_delete_paths=61`。
- 当前 4 个残留 L0 refs 仍承载独立 patch history；refs cleanup 结论继续保持显式 `no-op`。

## Mainline Closeout Snapshot

- 当前 latest merged-main evidence head：`c4fcfcf744b87cb1f8b67ad84beccce6b22b9af8`
- GitHub Actions `L0 Linux Maintenance` run `24377364840`
  - head sha：`c4fcfcf744b87cb1f8b67ad84beccce6b22b9af8`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence` run `24379333706`
  - head sha：`c4fcfcf744b87cb1f8b67ad84beccce6b22b9af8`
  - 结果：`12/12 PASS`
- Linux shell verifier local snapshot：
  - `tests/_windows_l0_native_evidence_gh/L0-20260414-mainline-closeout-windows/`

- 当前最新的 exact Windows native evidence 已直接对当前 `main@c4fcfcf744b87cb1f8b67ad84beccce6b22b9af8` 收证。

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
- GitHub Actions `L0 Linux Maintenance` run `24377364840`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence` run `24379333706`
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
- 第九波之后，如果 `next_focus=source-review-first`，当前标准入口是 `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`；它会继续显式输出 `review_candidate_paths=`、`simd_out_of_scope_paths=`、`dangerous_delete_paths=` 与 `reject_wholesale_absorb=`。
- 第十波之后，如果 `closeout` 仍只剩 test-doc residue，先跑 `bash tests/test_strict_l0_retained_refs_closeout_test_docs_no_downgrade_contract.sh`，确认这些 README 没有把 current-entry 反向降级。
- 第九波之后，`tests/fafafa.core.archiver/last-run.txt`、`tests/fafafa.core.atomic/tests_atomic`、`tests/fafafa.core.sync.barrier/*_output.txt` 与 `tests/fafafa.core.fs/performance-data/*latest*` 这类 residue 已不再属于主线 tracked surface。
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
- 后续若 strict L0 再发生非文档代码或测试改动，仍应重新收 fresh Windows exact evidence，而不是复用 `24379333706`；Linux x64 本地只能继续做 shell-side artifact verifier，不能伪造 exact Windows native 结论。
- SIMD owner 与 sidecar handoff 的职责边界没有变化；L0 这里不应重新吸收那些工作。
