#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT_DEFAULT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_ROOT="${REPO_ROOT_DEFAULT}"
APPLY_MODE=0

MAIN_SHA=""
ORIGIN_MAIN_SHA=""
WORKTREE_SHA=""
LINUX_RUN_ID=""
LINUX_RUN_SHA=""
WINDOWS_RUN_ID=""
WINDOWS_RUN_SHA=""
WINDOWS_LOCAL_BATCH_ID=""

print_usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --apply                        Write current-state docs in place
  --target-root <path>           Target repo/doc root (default: current repo)
  --main-sha <sha>               Current local main SHA to record
  --origin-main-sha <sha>        Current origin/main SHA to record (default: same as --main-sha)
  --worktree-sha <sha>           Current L0 worktree HEAD SHA (default: same as --main-sha)
  --linux-run-id <id>            Linux maintenance run id
  --linux-run-sha <sha>          Linux maintenance head SHA
  --windows-run-id <id>          Windows native evidence run id
  --windows-run-sha <sha>        Windows native evidence head SHA
  --windows-local-batch-id <id>  Local snapshot batch id under tests/_windows_l0_native_evidence_gh
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    --apply)
      APPLY_MODE=1
      shift
      ;;
    --target-root)
      TARGET_ROOT="$2"
      shift 2
      ;;
    --main-sha)
      MAIN_SHA="$2"
      shift 2
      ;;
    --origin-main-sha)
      ORIGIN_MAIN_SHA="$2"
      shift 2
      ;;
    --worktree-sha)
      WORKTREE_SHA="$2"
      shift 2
      ;;
    --linux-run-id)
      LINUX_RUN_ID="$2"
      shift 2
      ;;
    --linux-run-sha)
      LINUX_RUN_SHA="$2"
      shift 2
      ;;
    --windows-run-id)
      WINDOWS_RUN_ID="$2"
      shift 2
      ;;
    --windows-run-sha)
      WINDOWS_RUN_SHA="$2"
      shift 2
      ;;
    --windows-local-batch-id)
      WINDOWS_LOCAL_BATCH_ID="$2"
      shift 2
      ;;
    *)
      echo "[L0-DOCS-BACKFILL] Unknown option: $1" >&2
      exit 2
      ;;
  esac
done

fail() {
  echo "[L0-DOCS-BACKFILL] $1" >&2
  exit 2
}

[[ -n "${MAIN_SHA}" ]] || fail "missing --main-sha"
[[ -n "${LINUX_RUN_ID}" ]] || fail "missing --linux-run-id"
[[ -n "${LINUX_RUN_SHA}" ]] || fail "missing --linux-run-sha"
[[ -n "${WINDOWS_RUN_ID}" ]] || fail "missing --windows-run-id"
[[ -n "${WINDOWS_RUN_SHA}" ]] || fail "missing --windows-run-sha"
[[ -n "${WINDOWS_LOCAL_BATCH_ID}" ]] || fail "missing --windows-local-batch-id"
[[ -n "${ORIGIN_MAIN_SHA}" ]] || ORIGIN_MAIN_SHA="${MAIN_SHA}"
[[ -n "${WORKTREE_SHA}" ]] || WORKTREE_SHA="${MAIN_SHA}"

AUDIT_FILE="${TARGET_ROOT}/docs/audits/2026-04-11-l0-current-state-audit.md"
LEGACY_FILE="${TARGET_ROOT}/docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md"
WORKER_FILE="${TARGET_ROOT}/workers/worker1.md"
WINDOWS_SNAPSHOT_PATH="tests/_windows_l0_native_evidence_gh/${WINDOWS_LOCAL_BATCH_ID}/"

if [[ "${WINDOWS_RUN_SHA}" == "${MAIN_SHA}" ]]; then
  printf -v WINDOWS_POSTURE_LINE \
    -- '- 当前最新的 exact Windows native evidence 已直接对当前 `main@%s` 收证。' \
    "${MAIN_SHA}"
elif [[ "${ORIGIN_MAIN_SHA}" != "${MAIN_SHA}" ]]; then
  printf -v WINDOWS_POSTURE_LINE \
    -- '- 当前本地 `main` 已推进到 `%s`；当前 `origin/main` 仍在 `%s`；最新 exact Windows native evidence 仍锚定 `main@%s`。只有在确认 current `main` 相对该证据头没有新增 strict L0 代码或测试入口变化时，才应继续把差异理解为 docs / control-plane-only 增量。' \
    "${MAIN_SHA}" \
    "${ORIGIN_MAIN_SHA}" \
    "${WINDOWS_RUN_SHA}"
else
  printf -v WINDOWS_POSTURE_LINE \
    -- '- 当前 `main` 已推进到 `%s`；最新 exact Windows native evidence 仍锚定 `main@%s`，两者之间的差异应继续保持为 docs / control-plane-only 增量。' \
    "${MAIN_SHA}" \
    "${WINDOWS_RUN_SHA}"
fi

if [[ "${APPLY_MODE}" != "1" ]]; then
  echo "[L0-DOCS-BACKFILL] Planned targets:"
  echo "${AUDIT_FILE}"
  echo "${LEGACY_FILE}"
  echo "${WORKER_FILE}"
  exit 0
fi

mkdir -p "$(dirname "${AUDIT_FILE}")" "$(dirname "${LEGACY_FILE}")" "$(dirname "${WORKER_FILE}")"

TARGET_ROOT_ENV="${TARGET_ROOT}" \
AUDIT_FILE_ENV="${AUDIT_FILE}" \
LEGACY_FILE_ENV="${LEGACY_FILE}" \
WORKER_FILE_ENV="${WORKER_FILE}" \
MAIN_SHA_ENV="${MAIN_SHA}" \
ORIGIN_MAIN_SHA_ENV="${ORIGIN_MAIN_SHA}" \
WORKTREE_SHA_ENV="${WORKTREE_SHA}" \
LINUX_RUN_ID_ENV="${LINUX_RUN_ID}" \
LINUX_RUN_SHA_ENV="${LINUX_RUN_SHA}" \
WINDOWS_RUN_ID_ENV="${WINDOWS_RUN_ID}" \
WINDOWS_RUN_SHA_ENV="${WINDOWS_RUN_SHA}" \
WINDOWS_LOCAL_BATCH_ID_ENV="${WINDOWS_LOCAL_BATCH_ID}" \
WINDOWS_SNAPSHOT_PATH_ENV="${WINDOWS_SNAPSHOT_PATH}" \
WINDOWS_POSTURE_LINE_ENV="${WINDOWS_POSTURE_LINE}" \
python3 - <<'PY'
import os
from pathlib import Path

audit_file = Path(os.environ["AUDIT_FILE_ENV"])
legacy_file = Path(os.environ["LEGACY_FILE_ENV"])
worker_file = Path(os.environ["WORKER_FILE_ENV"])

main_sha = os.environ["MAIN_SHA_ENV"]
origin_main_sha = os.environ["ORIGIN_MAIN_SHA_ENV"]
worktree_sha = os.environ["WORKTREE_SHA_ENV"]
linux_run_id = os.environ["LINUX_RUN_ID_ENV"]
linux_run_sha = os.environ["LINUX_RUN_SHA_ENV"]
windows_run_id = os.environ["WINDOWS_RUN_ID_ENV"]
windows_run_sha = os.environ["WINDOWS_RUN_SHA_ENV"]
windows_snapshot_path = os.environ["WINDOWS_SNAPSHOT_PATH_ENV"]
windows_posture_line = os.environ["WINDOWS_POSTURE_LINE_ENV"]

local_main_head_line = f"- 当前本地 `main` head 是 `{main_sha}`。"
origin_main_head_line = f"- 当前 `origin/main` head 是 `{origin_main_sha}`。"

if worktree_sha == main_sha:
    if origin_main_sha == main_sha:
        worktree_head_line = "- 当前唯一 L0 branch 仍是 `l0-mainline`，它当前与 `main` / `origin/main` 同步，不再承载未合并增量。"
        maintenance_worktree_line = "- 当前唯一 L0 worktree 应继续保持在 `l0-mainline -> main / origin/main`。"
        worker_head_focus_line = (
            f"- 保持 merged-main current-state 文档显式写清：latest exact Windows native evidence 仍锚定 `main@{windows_run_sha}`；当前本地 `main`、`origin/main` 与 worktree head 仍共同记录为 `{main_sha}`。"
        )
    else:
        worktree_head_line = (
            f"- 当前唯一 L0 branch 仍是 `l0-mainline`；当前 worktree head 与本地 `main@{main_sha}` 一致，它现在是一个跟随本地 merged-main 的维护分支。"
        )
        maintenance_worktree_line = (
            f"- 当前唯一 L0 worktree 仍固定为 `l0-mainline`；当前 head 与本地 `main@{main_sha}` 一致，而 `origin/main` 仍停在 `{origin_main_sha}`。不要把这条维护分支误写成继续单纯跟随远端。"
        )
        worker_head_focus_line = (
            f"- 保持 merged-main current-state 文档显式写清：latest exact Windows native evidence 仍锚定 `main@{windows_run_sha}`；并把当前本地 `main@{main_sha}`、`origin/main@{origin_main_sha}` 与当前 worktree head `{worktree_sha}` 明确区分，避免把 docs / control-plane-only mainline closeout 混写成 origin/main 已同步。"
        )
else:
    worktree_head_line = (
        f"- 当前唯一 L0 worktree `l0-mainline` 目前位于 `{worktree_sha}`；相对本地 `main@{main_sha}` 仍承载待整理的本地 L0 增量。"
    )
    maintenance_worktree_line = (
        f"- 当前唯一 L0 worktree 仍固定为 `l0-mainline`；当前 head=`{worktree_sha}`，本地 `main`=`{main_sha}`，`origin/main`=`{origin_main_sha}`。merge 前不要把这条本地 worktree 的状态误写成已经进入 `origin/main`。"
    )
    worker_head_focus_line = (
        f"- 保持 merged-main current-state 文档显式写清：latest exact Windows native evidence 仍锚定 `main@{windows_run_sha}`；并把当前本地 `main@{main_sha}`、`origin/main@{origin_main_sha}` 与当前 worktree head `{worktree_sha}` 明确区分，避免把未合并 L0 增量误写成已经进 main。"
    )

audit_text = f"""# 2026-04-11 L0 Current State Audit

> 这份审计反映 strict non-SIMD L0 在 latest mainline closeout 之后的 current state。

## Summary

- 当前 strict non-SIMD L0 的权威边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
- 当前 strict non-SIMD L0 的稳定路线图仍固定为 `docs/fafafa.core.l0.roadmap.md`。
- 当前这份 current-state audit 固定记录的 latest merged-main exact evidence head 是 `{windows_run_sha}`。
{local_main_head_line}
{origin_main_head_line}
{worktree_head_line}
- Linux x64 的 strict L0 日常维护继续固定为 `bash tests/run_strict_l0_maintenance_loop.sh`；对应 GitHub Actions workflow `l0-linux-maintenance.yml` 已进入 default branch，并已在 `main` fresh 通过。
- strict L0 的 Windows native evidence 当前继续由 GitHub Actions run `{windows_run_id}` 提供 exact evidence，shell-side artifact verifier 已在 Linux x64 本地复核通过。
- collections 域里 dated 的 plans / status / reviews 已进一步下沉到 `docs/collections/legacy/README.md`；当前 collections 入口继续固定为 `docs/fafafa.core.collections.md` 与 `docs/collections/guides/`。
- examples current-entry 也已进一步收紧到各 domain README、`BuildOrRun*` 和 `.lpr` / `.lpi`；`bin/`、`lib/` 与本地 logs 不再作为 today contract 的入口。
- 第六波之后，retained-refs inventory 还会继续把 tests drift 细分成 test code / scripts / docs / runtime records / control files / output artifacts / binary artifacts，并显式输出 `next_focus=`。
- 第七波之后，retained-refs inventory 还会继续把 docs residue 细分成 root/module/topic/guide/archive-pointer/collections-dated/legacy/report-topic，并显式输出 `docs_absorb_candidate_paths=`。
- 第八波之后，retained-refs inventory 还会继续显式输出 `test_hygiene_candidate_paths=` 与 `source_review_candidate_paths=`，让 `sidecar/tail` 和 `closeout/rescue` 的当前下一跳直接可读。
- 第九波之后，`sidecar/tail` 的一批 tracked hygiene residue 已经从主线真实清掉；`closeout/rescue` 继续通过 `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 暴露 `review_candidate_paths=` / `review_skip_paths=` / `simd_out_of_scope_paths=` / `dangerous_delete_paths=` / `reject_wholesale_absorb=`。
- 第十波之后，`mem allocator callback` 的低风险 rescue 语义已经在主线内做了小型 current-entry hardening；`closeout` 的 6 个 test README candidate 也已被明确确认为 stale downgrade，并由 no-downgrade contract 锁住。
- 第 2026-04-14 波之后，`sidecar` 又吸收了一小段未覆盖的 runtime hygiene：`tests/fafafa.core.env/build_log.txt`、`tests/fafafa.core.env/fpcdebug.txt` 与 `tests/fafafa.core.mem.manager.rtl/mem_manager_heaptrc_output.txt` 已不再属于主线 tracked surface。
- 第 2026-04-14 波之后，如果当前问题是 `sidecar/tail` 在 merged-main 之后还能不能删、各自还剩什么 exclusive batch，标准入口固定为 `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`；fresh 结果是 `sidecar_only_commit_count=1`、`tail_only_commit_count=8`，且 `sidecar_safe_delete_now=no`、`tail_safe_delete_now=no`。
- 虽然 inventory `--details` 仍把 `tail` 暴露成 `next_focus=test-hygiene-first`，但 fresh diff 已确认 `tests/cleanup_orphan_dirs.sh` + `tests/fafafa.core.fs/{{ArchivePerfResult,BuildOrRunPerf,BuildOrRunResolvePerf,BuildOrRunPerfAll}}.sh` + `tests/fafafa.core.fs/README-perf.md` 这组 shell/runner cluster 当前属于 current-HEAD-ahead / no-absorb；today contract 继续由 `bash tests/test_active_shell_runners.sh` 与 `bash tests/test_fs_perf_shell_scripts.sh` 守住。
- 同日 fresh diff 还确认：`src/fafafa.core.atomic.base.pas` 与 `src/fafafa.core.span.pas` 只剩 no-op residue；`tests/fafafa.core.option/BuildOrTest.bat` 与 `tests/fafafa.core.result/BuildOrTest.bat` 则属于 current-HEAD-ahead / no-absorb。today contract 固定为 `bash tests/test_l0_option_result_runner_hygiene.sh`。
- fresh shortlist 现在还会把已经完成 fresh 复核、确认属于 current-HEAD-ahead / already-absorbed / stale-no-downgrade 的热点下沉到 `review_skip_paths=`；`atomic` / `mem allocator callback` / Windows native CI control-plane 与已被 no-downgrade contract 锁住的 stale test docs 不应再被重复当作新的手工吸收入口。
- 第 2026-04-14 波之后，`closeout` 的 `mem allocator + fs perf wrapper/README` cluster 与 `rescue` 的 `mem/result/span + base/bits/contracts/result/span test-entry` cluster 也已经完成 fresh review：它们分别只会回退 today boundary、today runner 或 today docs narrative，因此当前统一转入 `review_skip_paths=`，不做吸收。
- 同日后续波之后，`rescue` 的 `examples/fafafa.core.atomic/base/option/result` BuildOrRun/example-source cluster，以及 `tests/fafafa.core.{{endian,layout,mem,option,platform}}` 的 stale runner/doc cluster 也已经完成 fresh review：它们只会把 today example entry、today wrapper contract 或 today docs 叙事回退成旧版本，因此同样统一转入 `review_skip_paths=`。
- 同日后续波还再次确认：`docs/collections/legacy/README.md`、`docs/reports/README.md`、`docs/collections/reports/README.md`、`docs/benchmarks/reports/README.md` 与 `docs/legacy/l0/README.md` 这些 landing-zone docs 继续以当前主线版本为准；`sidecar` 暴露的旧 archive-pointer / legacy-pointer 文本不应吸收。
- 第 2026-04-15 波之后，`closeout/rescue` 的 source-review shortlist 已 fresh 清空：`closeout.review_candidate_paths=0`、`rescue.review_candidate_paths=0`。同时 fresh API/runner 复核还确认：最后一个看起来像候选的 `tests/fafafa.core.collections/vecdeque/Test_vecdeque_span.pas` 其实是未接线且依赖已移除 `SliceView` API 的 stale dead test code；它继续只留在 `review_skip_paths=`，不构成 today absorb。
- 同日 `sidecar` 的唯一 exclusive mixed batch 也只切片吸收了 async runner hygiene：`tests/fafafa.core.fs.async/*` 与 `tests/fafafa.core.socket.async/*` 的 today contract 现在固定由 `bash tests/test_l0_async_test_runner_hygiene.sh` 守住；`examples/fafafa.core.sync*` / `examples/fafafa.core.sync.condvar*` 仍继续 defer，不做 broad absorb。
- 当前 4 个残留 L0 refs 仍承载独立 patch history；refs cleanup 结论继续保持显式 `no-op`。

## Mainline Closeout Snapshot

- 当前 latest merged-main exact evidence head：`{windows_run_sha}`
- 当前本地 `main` head：`{main_sha}`
- 当前 `origin/main` head：`{origin_main_sha}`
- 当前 L0 worktree head：`{worktree_sha}`
- GitHub Actions `L0 Linux Maintenance` run `{linux_run_id}`
  - head sha：`{linux_run_sha}`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence` run `{windows_run_id}`
  - head sha：`{windows_run_sha}`
  - 结果：`12/12 PASS`
- Linux shell verifier local snapshot：
  - `{windows_snapshot_path}`

{windows_posture_line}

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
- GitHub Actions `L0 Linux Maintenance` run `{linux_run_id}`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence` run `{windows_run_id}`
  - 结果：PASS；`12/12`

## Current L0 Surface

- 基础语义：`settings.inc`、`base`、`contracts`、`option`、`result`
- 视图表达：`span`、`span2`
- 原始数据语义：`bits`、`platform`、`layout`、`endian`
- 内存模型：`atomic.core`、`atomic.base`、`atomic`、`atomic.compat`
- 分配契约：`mem.allocator.base`

当前边界没有变化。变化的是：current-entry 的验证证据已经从“本地闭环 + branch-local 历史探测”推进成了“main 上 fresh Linux + exact Windows evidence”。

## Current Maintenance Rules

{maintenance_worktree_line}
- Linux x64 上的日常维护默认走 `bash tests/run_strict_l0_maintenance_loop.sh`。
- 如需 GitHub-side Linux 证据，当前标准命令是 `gh workflow run l0-linux-maintenance.yml --ref main`。
- 如需 GitHub-side Windows exact evidence，当前标准入口是 `l0-windows-native-evidence.yml`，并在下载后继续通过 `bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh <batch-id> <run-id>` 做 shell-side artifact 校验。
- 如需重新审计残留历史 L0 refs 是否仍承载独立 patch history，当前标准入口是 `bash tests/audit_strict_l0_retained_refs.sh`；它只给 decision，不直接删除 refs。
- 如需先判断 retained refs 该优先吸收哪一类 unique history，当前标准入口是 `bash tests/report_strict_l0_retained_refs_inventory.sh`；它会先给 absorb inventory，再决定下一批动作。
- 如需直接看代表性 unique commits 和路径样本，再执行 `bash tests/report_strict_l0_retained_refs_inventory.sh --details`。
- 第六波之后，`--details` 还会继续把 `code_or_tests` 细分成 `src / test source / test code / test script / test doc / runtime record / control file / CI workflow / output artifact / binary artifact`，并显式输出 `next_focus=`，方便继续做 retained-refs triage。
- 第七波之后，`--details` 还会继续给出 `docs_absorb_candidate_paths=`，把 sidecar/tail 上已经有稳定 landing zone 的 low-risk docs residue 直接暴露出来。
- 第八波之后，如果 `next_focus=test-hygiene-first`，优先看 `test_hygiene_candidate_paths=`；如果 `next_focus=source-review-first`，优先看 `source_review_candidate_paths=`；docs residue 则继续看 `docs_absorb_candidate_paths=`。
- 即使 inventory 继续给出 `next_focus=test-hygiene-first`，也不要默认把 `tests/cleanup_orphan_dirs.sh` 与 `tests/fafafa.core.fs/{{ArchivePerfResult,BuildOrRunPerf,BuildOrRunResolvePerf,BuildOrRunPerfAll}}.sh` 当成新的 `tail` absorb 入口；fresh diff 已确认当前 HEAD 在这组 shell/runner contract 上更先进。
- 这组 shell/runner today contract 的本地守门入口继续是 `bash tests/test_active_shell_runners.sh` 与 `bash tests/test_fs_perf_shell_scripts.sh`。
- 同日 fresh diff 还确认：`src/fafafa.core.atomic.base.pas` 与 `src/fafafa.core.span.pas` 只剩 no-op residue；`tests/fafafa.core.option/BuildOrTest.bat` 与 `tests/fafafa.core.result/BuildOrTest.bat` 则属于 current-HEAD-ahead / no-absorb。对应 today 守门入口固定为 `bash tests/test_l0_option_result_runner_hygiene.sh`。
- 第九波之后，如果 `next_focus=source-review-first`，当前标准入口是 `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`；它会继续显式输出 `review_candidate_paths=`、`review_skip_paths=`、`simd_out_of_scope_paths=`、`dangerous_delete_paths=` 与 `reject_wholesale_absorb=`。
- 第十波之后，如果 `closeout` 仍只剩 test-doc residue，先跑 `bash tests/test_strict_l0_retained_refs_closeout_test_docs_no_downgrade_contract.sh`，确认这些 README 没有把 current-entry 反向降级。
- 第 2026-04-14 波之后，如果 `closeout` shortlist 已清空，说明 `mem allocator + fs perf wrapper/README` 这组路径已经被判为 stale skip；它们只在 `tail` lane 里继续以 today shell hygiene contract 存在，不再是 `closeout` 的 source-review 候选。
- 同一波之后，`rescue` 里 `mem/result/span + base/bits/contracts/result/span test-entry` 这一簇也已经固定为 stale skip；尤其 `result` 的旧 anon-ref gating、`span` 的旧 single-span-only cut 与 `*.test.lpr` 缺 `settings.inc` 都不再应被当成吸收入口。
- 同日后续波之后，`rescue` 的 examples/build/runner/doc stale cluster 也已经固定为 stale skip；尤其 `examples/fafafa.core.atomic/base/option/result` 的 `BuildOrRun*` / example source、`tests/fafafa.core.{{endian,layout,mem,option,platform}}` 的 runner 变体，以及 `tests/fafafa.core.fs/README-perf.md`、`tests/fafafa.core.mem/README.md`、`tests/fafafa.core.option/README.md` 都不再应被当成新的吸收入口。
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
- 后续若 strict L0 再发生非文档代码或测试改动，仍应重新收 fresh Windows exact evidence，而不是复用 `{windows_run_id}`；Linux x64 本地只能继续做 shell-side artifact verifier，不能伪造 exact Windows native 结论。
- SIMD owner 与 sidecar handoff 的职责边界没有变化；L0 这里不应重新吸收那些工作。
"""

legacy_text = f"""# 2026-04-11 L0 Mainline Refs And CI Closeout

> 历史 closeout 记录：本文保留 `l0-linux-maintenance.yml` 还没有进入 default branch 时的 `HTTP 404` 诊断语境。该问题已在后续 mainline CI fresh pass 里得到解决。

## Historical Phase Summary

- 当时唯一 `L0` worktree 仍是 `l0-mainline`，workflow 可见性探测使用的 probe commit 是 `0970b629`。
- 当时 `.github/workflows/l0-linux-maintenance.yml` 只在 `origin/l0-mainline` 上可见，还没有进入 default branch。
- 因此 `gh workflow run l0-linux-maintenance.yml --ref l0-mainline` 返回 `HTTP 404`；这证明 GitHub 尚未注册 dispatch 入口，不是认证错误。
- 当时 4 个残留 `L0` refs 都仍承载独立 patch history，所以 refs cleanup 结论是显式 `no-op`。

## Final Resolution

- 当前本地 main merge commit：`{main_sha}`
- 当前 `origin/main` head：`{origin_main_sha}`
- GitHub Actions `L0 Linux Maintenance` run `{linux_run_id}`
  - head sha：`{linux_run_sha}`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence` run `{windows_run_id}`
  - head sha：`{windows_run_sha}`
  - 结果：`12/12 PASS`
- Linux shell verifier snapshot：
  - `{windows_snapshot_path}`

这说明：

- mainline Linux workflow 已可 dispatch 并 fresh 通过
- Windows exact evidence 也已收齐
- 当前本地 `main` 已推进到 `{main_sha}`；当前 `origin/main` 仍在 `{origin_main_sha}`；latest exact Windows native evidence 仍锚定 `main@{windows_run_sha}`。只有在确认 current `main` 相对该证据头没有新增 strict L0 代码或测试入口变化时，才应继续把差异理解为 docs / control-plane-only 增量。
- 这份文档现在只保留 pre-merge `HTTP 404` 的历史解释与 refs no-op 审计背景

## Retained Refs

当前继续保留：

- `l0-mainline`
- `l0-mainline-closeout-20260411`
- `l0-sidecar-handoff-20260409`
- `l0-main-rescue`
- `l0-main-tail-cleanup-20260408-final`

## Present-Day Interpretation

现在不应再把这份文档里的 `HTTP 404` 结论当 current blocker：

- 它只描述 workflow 进入 default branch 之前的历史状态
- 当前 mainline Linux workflow 已可 dispatch 并 fresh 通过
- 当前 latest Windows exact evidence run 是 `{windows_run_id}`
"""

worker_text = f"""# worker1

- Owner: Codex
- Scope: strict non-SIMD L0 的 mainline 维护、verification / hygiene hardening，以及 docs / CI closeout
- Status: `active`
- Branch: `l0-mainline`
- Worktree: `/home/dtamade/projects/fafafa.core/.claude/worktrees/l0-main-promotion-20260407`
- Base commit: `{main_sha}` (`main`)
- Remote main head: `{origin_main_sha}` (`origin/main`)
- Current HEAD: `{worktree_sha}`
- Latest merged-main exact evidence head: `{windows_run_sha}`
- Current focus:
  - 维持当前唯一 L0 worktree 跟随 `main`
  - 维持 strict L0 的 current-entry 文档、模块边界和验证口径一致
  - 只清理安全可删的本地 L0 refs，保留仍然承载独立历史的锚点
  {worker_head_focus_line}
  - 把 Linux maintenance workflow 与 Windows exact-evidence lane 的 current-entry 命令、证据和 fail-close 语义写准
  - 把 retained-refs triage 的 `test_hygiene_candidate_paths=` / `source_review_candidate_paths=` / `docs_absorb_candidate_paths=` 保持为 today contract
  - 把 `tail` 的 `tests/cleanup_orphan_dirs.sh` + `tests/fafafa.core.fs/{{ArchivePerfResult,BuildOrRunPerf,BuildOrRunResolvePerf,BuildOrRunPerfAll}}.sh` + `tests/fafafa.core.fs/README-perf.md` 固定为 current-HEAD-ahead / no-absorb 结论，只用 `bash tests/test_active_shell_runners.sh` / `bash tests/test_fs_perf_shell_scripts.sh` 守住 today contract，不再按 tail 版本回灌
  - 把 `tail` 的 residual runner/source 小撮也固定为 no-absorb：`src/fafafa.core.atomic.base.pas` 与 `src/fafafa.core.span.pas` 只剩 no-op residue，`tests/fafafa.core.option/BuildOrTest.bat` 与 `tests/fafafa.core.result/BuildOrTest.bat` 则只允许 today 版本继续由 `bash tests/test_l0_option_result_runner_hygiene.sh` 守住
  - 把 `closeout` 的 `mem allocator + fs perf wrapper/README` stale cluster、`rescue` 的 `mem/result/span + base/bits/contracts/result/span test-entry` stale cluster，以及 `rescue` 的 examples/runner/doc stale cluster 一并固定到 `review_skip_paths=`，不要再重复人工吸收
  - 把 `closeout/rescue` shortlist 已清空这一状态固定成 today contract；并明确 `Test_vecdeque_span.pas` 只是 stale dead test code，不再把它误判成可吸收候选；如果 shortlist 继续是 0，下一跳回到 `sidecar/tail` overlap 或 inventory
  - 把 `sidecar/tail` 已吸收的 hygiene residue 与 `closeout/rescue` 的 shortlist-first 语义保持为 today contract，并继续拒绝 `dangerous_delete_paths=` 场景下的 wholesale absorb
  - 把 `sidecar` 的唯一 exclusive mixed batch 限定成 small-cut 推进：当前只吸收 `tests/fafafa.core.fs.async/*` 与 `tests/fafafa.core.socket.async/*` 这组 async runner hygiene，并用 `bash tests/test_l0_async_test_runner_hygiene.sh` 守住 today contract；`examples/fafafa.core.sync*` / `examples/fafafa.core.sync.condvar*` 继续 defer
  - 把 `docs/collections/legacy/README.md`、`docs/reports/README.md`、`docs/collections/reports/README.md`、`docs/benchmarks/reports/README.md` 与 `docs/legacy/l0/README.md` 这些 landing-zone docs 保持为 today contract，不吸收 `sidecar` 的旧 pointer 版本
  - 把 `sidecar/tail` 的 merged-main 之后 pairwise cleanup readiness 固定到 `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`
  - 保持 Windows exact evidence 只能来自 GitHub Actions / 真实 Windows runner 这一纪律
- Source of truth:
  - `docs/fafafa.core.l0.foundation.md`
  - `docs/fafafa.core.l0.roadmap.md`
  - `docs/ARCHITECTURE_LAYERS.md`
  - `docs/audits/2026-04-11-l0-current-state-audit.md`
  - `docs/audits/2026-04-15-l0-tail-shell-runner-head-ahead-no-absorb-audit.md`
  - `docs/audits/2026-04-15-l0-tail-residual-runner-source-no-absorb-audit.md`
  - `docs/audits/2026-04-15-l0-sidecar-async-runner-slice-audit.md`
  - `docs/audits/2026-04-15-l0-closeout-rescue-final-source-review-clearout-audit.md`
  - `docs/audits/2026-04-14-l0-closeout-rescue-stale-skip-audit.md`
  - `docs/audits/2026-04-14-l0-rescue-examples-docs-stale-skip-audit.md`
  - `docs/audits/2026-04-14-l0-retained-refs-sidecar-tail-postmerge-audit.md`
  - `docs/audits/2026-04-13-l0-premerge-ci-evidence-audit.md`
  - `docs/audits/2026-04-13-l0-retained-refs-ninth-hygiene-shortlist-audit.md`
  - `docs/audits/2026-04-13-l0-retained-refs-tenth-mem-callback-doc-guard-audit.md`
  - `docs/audits/2026-04-12-l0-retained-refs-absorption-audit.md`
  - `docs/legacy/l0/README.md`
  - `docs/collections/legacy/README.md`
  - `docs/reports/README.md`
  - `docs/collections/reports/README.md`
  - `docs/benchmarks/reports/README.md`
  - `docs/EXAMPLES.md`
  - `docs/plans/2026-04-16-l0-mainline-continuation-plan.md`
  - `docs/plans/2026-04-11-l0-post-merge-stabilization-plan.md`
  - `docs/plans/2026-04-15-l0-closeout-rescue-final-source-review-clearout-plan.md`
  - `docs/plans/2026-04-14-l0-closeout-rescue-stale-skip-wave.md`
  - `docs/plans/2026-04-14-l0-rescue-examples-docs-stale-skip-wave.md`
  - `docs/plans/2026-04-14-l0-retained-refs-sidecar-tail-postmerge-plan.md`
  - `docs/plans/2026-04-13-l0-retained-refs-seventh-absorption-plan.md`
  - `docs/plans/2026-04-13-l0-retained-refs-eighth-focus-routing-plan.md`
  - `docs/plans/2026-04-13-l0-retained-refs-ninth-hygiene-shortlist-plan.md`
  - `docs/plans/2026-04-13-l0-retained-refs-tenth-mem-callback-doc-guard-plan.md`
  - `docs/plans/2026-04-13-l0-premerge-ci-closeout-plan.md`
  - `docs/CI.md`
  - `tests/check_strict_l0_docs_consistency.sh`
  - `tests/run_strict_l0_maintenance_loop.sh`
  - `tests/run_strict_l0_mainline_closeout.sh`
  - `tests/report_strict_l0_retained_refs_inventory.sh`
  - `tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`
  - `tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
  - `tests/test_strict_l0_retained_refs_sidecar_hygiene_contract.sh`
  - `tests/test_strict_l0_retained_refs_hygiene_absorption_contract.sh`
  - `tests/test_active_shell_runners.sh`
  - `tests/test_fs_perf_shell_scripts.sh`
  - `tests/test_l0_option_result_runner_hygiene.sh`
  - `tests/test_l0_async_test_runner_hygiene.sh`
  - `tests/test_strict_l0_retained_refs_inventory_code_tests_contract.sh`
  - `tests/test_strict_l0_retained_refs_inventory_test_hygiene_contract.sh`
  - `tests/test_strict_l0_retained_refs_inventory_docs_current_entry_contract.sh`
  - `tests/test_strict_l0_retained_refs_inventory_focus_routing_contract.sh`
  - `tests/test_strict_l0_retained_refs_inventory_examples_build_contract.sh`
  - `tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh`
  - `tests/test_strict_l0_retained_refs_sidecar_tail_overlap_contract.sh`
  - `tests/test_strict_l0_retained_refs_closeout_test_docs_no_downgrade_contract.sh`
  - `tests/test_strict_l0_examples_build_docs_contract.sh`
  - `tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`
  - `tests/update_strict_l0_current_state_docs.sh`
  - `docs/fafafa.core.span.md`
  - `docs/fafafa.core.atomic.md`
  - `docs/fafafa.core.result.md`
  - `examples/fafafa.core.result/README.md`
  - `examples/fafafa.core.platform/README.md`
- Fresh verification:
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
  - `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
  - 结果：PASS
  - `bash tests/test_strict_l0_linux_ci_workflow_contract.sh`
  - 结果：PASS
  - `bash tests/test_windows_strict_l0_native_evidence_gh_contract.sh`
  - 结果：PASS
  - `bash tests/test_windows_strict_l0_native_evidence_main_ref_contract.sh`
  - 结果：PASS
  - `bash tests/run_strict_l0_maintenance_loop.sh`
  - 结果：PASS
  - GitHub Actions `L0 Linux Maintenance` run `24349423066`
  - 结果：PASS；pre-merge branch head=`bb2c4104f098699a9f387800b0688a11a12661c9`
  - `git diff --check`
  - 结果：PASS
  - GitHub Actions `L0 Linux Maintenance` run `{linux_run_id}`
  - 结果：PASS；head sha=`{linux_run_sha}`
  - GitHub Actions `L0 Windows Native Evidence` run `{windows_run_id}`
  - 结果：PASS；head sha=`{windows_run_sha}`
  - local Windows snapshot：
  - `{windows_snapshot_path}`
- Retained local refs:
  - `l0-mainline`
  - `l0-mainline-closeout-20260411`
  - `l0-sidecar-handoff-20260409`
  - `l0-main-rescue`
  - `l0-main-tail-cleanup-20260408-final`
- Risks / blockers:
  - 根目录 `main` 工作树仍然是用户脏状态，不能直接当作 L0 的当前执行面
  - 当前 4 个历史 L0 refs 仍承载独立 patch history，不能盲删
  - 后续若 strict L0 再发生非文档代码或测试改动，仍需重新补 fresh Windows exact evidence
  - `update_strict_l0_current_state_docs.sh` 必须继续与 today contracts 同步，不能再把 `--details` / shortlist-first / docs landing-zone 语义压缩掉
  - SIMD-only 残留仍由 SIMD owner 继续维护，L0 这里只保留边界与 handoff 说明
- Next step:
  - 继续只沿 strict L0 线推进，不把 sidecar 或 SIMD 工作重新混回当前 worktree
  - Linux x64 上的日常维护默认走 `bash tests/run_strict_l0_maintenance_loop.sh`
  - 如需重新判断 retained refs 是否还该保留，使用 `bash tests/audit_strict_l0_retained_refs.sh`
  - 如需先判断 retained refs 该优先吸收哪类 unique history，使用 `bash tests/report_strict_l0_retained_refs_inventory.sh`
  - 如需直接看 retained refs 的代表性 unique commits / paths，使用 `bash tests/report_strict_l0_retained_refs_inventory.sh --details`
  - 如需判断 `sidecar/tail` 在 merged-main 之后还能不能删、各自还剩什么 exclusive batch，使用 `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh`
- 如需把 `closeout/rescue` 的 source-review 候选与危险删除拆开，使用 `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
- 即使 `next_focus=test-hygiene-first`，也先把 `tests/cleanup_orphan_dirs.sh` 与 `tests/fafafa.core.fs/{{ArchivePerfResult,BuildOrRunPerf,BuildOrRunResolvePerf,BuildOrRunPerfAll}}.sh` + `tests/fafafa.core.fs/README-perf.md` 视为已完成 fresh review 的 head-ahead / no-absorb batch；today 守门仍是 `bash tests/test_active_shell_runners.sh` 与 `bash tests/test_fs_perf_shell_scripts.sh`
- 同样把 `src/fafafa.core.atomic.base.pas` / `src/fafafa.core.span.pas` 视为 no-op residue，并把 `tests/fafafa.core.option/BuildOrTest.bat` / `tests/fafafa.core.result/BuildOrTest.bat` 视为 current-HEAD-ahead / no-absorb batch；today 守门固定为 `bash tests/test_l0_option_result_runner_hygiene.sh`
- 同样不要把 `sidecar` 的唯一 exclusive mixed batch 整包 absorb；当前只把 async runner hygiene 小撮交给 `bash tests/test_l0_async_test_runner_hygiene.sh` 守门，`examples/fafafa.core.sync*` / `examples/fafafa.core.sync.condvar*` 继续 defer
- 如果 `next_focus=test-hygiene-first`，优先看 `test_hygiene_candidate_paths=`
  - 如果 `next_focus=source-review-first`，优先看 `source_review_candidate_paths=`
  - docs residue 继续看 `docs_absorb_candidate_paths=`
  - 只要看到 `review_skip_paths=`，先跳过这些已经完成 fresh 复核的 stale/no-op hotspot，不要再把它们混回新一轮吸收入口
  - 只要看到 `dangerous_delete_paths=` 或 `reject_wholesale_absorb=yes`，继续拒绝整包吸收
  - 当前 `sidecar` / `tail` 的 inventory `next_focus=` 仍固定暴露为 `test-hygiene-first`，但 post-merge ref cleanup readiness 先看 overlap 报表
  - fresh overlap 结果是 `sidecar_only_commit_count=1`、`tail_only_commit_count=8`，并且 `sidecar_safe_delete_now=no`、`tail_safe_delete_now=no`
  - 当前 `closeout/rescue` 里已经完成 fresh 复核的 `atomic` / `mem callback` / Windows native CI hotspot、stale test docs、`closeout` 的 fs perf stale cluster、`rescue` 的 mem/result/span test-entry stale cluster，以及 `rescue` 的 examples/runner/doc stale cluster，都会继续落在 `review_skip_paths=`；下一轮只看剩余未跳过的手工 review 候选
  - 如果 fresh shortlist 继续给出 `closeout.review_candidate_paths=0` 与 `rescue.review_candidate_paths=0`，就把 `closeout/rescue` 视为已清空的 source-review lane；下一跳回到 `sidecar/tail` overlap 或 retained-refs inventory
  - 如果 `docs_absorb_candidate_paths=` 继续暴露 landing-zone docs residue，优先确认是否只是 `sidecar` 的旧 pointer 文本；不要回灌当前 `docs/collections/legacy/README.md`、`docs/reports/README.md`、`docs/collections/reports/README.md`、`docs/benchmarks/reports/README.md` 与 `docs/legacy/l0/README.md` 的 today contract
  - 如需一波收口 Linux/Windows evidence 与 current-state docs，使用 `bash tests/run_strict_l0_mainline_closeout.sh`
  - 如需只回填 current-state 文档，使用 `bash tests/update_strict_l0_current_state_docs.sh --apply --main-sha <main-sha> --origin-main-sha <origin-main-sha> --worktree-sha <worktree-sha> --linux-run-id <linux-run-id> --linux-run-sha <linux-run-sha> --windows-run-id <windows-run-id> --windows-run-sha <windows-run-sha> --windows-local-batch-id <batch-id>`
  - 需要 Windows exact evidence 时，继续使用 GitHub Actions workflow + shell verifier，不在 Linux x64 本地伪造 native 结论
- Last updated: `2026-04-16`
"""

audit_file.write_text(audit_text, encoding="utf-8")
legacy_file.write_text(legacy_text, encoding="utf-8")
worker_file.write_text(worker_text, encoding="utf-8")
PY

echo "[L0-DOCS-BACKFILL] Updated current-state docs:"
echo "${AUDIT_FILE}"
echo "${LEGACY_FILE}"
echo "${WORKER_FILE}"
