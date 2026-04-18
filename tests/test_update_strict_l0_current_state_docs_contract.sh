#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/update_strict_l0_current_state_docs.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${TARGET_SCRIPT}" ]] || fail "missing strict L0 current-state docs updater"

LTmpDir="$(mktemp -d)"
trap 'rm -rf "${LTmpDir}"' EXIT

mkdir -p "${LTmpDir}/docs/audits" "${LTmpDir}/docs/legacy/l0" "${LTmpDir}/workers"

bash "${TARGET_SCRIPT}" \
  --apply \
  --target-root "${LTmpDir}" \
  --main-sha "1111111111111111111111111111111111111111" \
  --linux-run-id "1001" \
  --linux-run-sha "1111111111111111111111111111111111111111" \
  --windows-run-id "1002" \
  --windows-run-sha "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
  --windows-local-batch-id "TEST-L0-BATCH" >/dev/null 2>&1 \
  || fail "docs updater failed to apply sample current-state data"

AUDIT_FILE="${LTmpDir}/docs/audits/2026-04-11-l0-current-state-audit.md"
LEGACY_FILE="${LTmpDir}/docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md"
WORKER_FILE="${LTmpDir}/workers/worker1.md"

[[ -f "${AUDIT_FILE}" ]] || fail "docs updater did not write current-state audit"
[[ -f "${LEGACY_FILE}" ]] || fail "docs updater did not write legacy closeout"
[[ -f "${WORKER_FILE}" ]] || fail "docs updater did not write worker handoff"

rg -F "24284430625" "${AUDIT_FILE}" >/dev/null && fail "docs updater leaked live run ids into sample output"
rg -F "1111111111111111111111111111111111111111" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing current main SHA"
rg -F "GitHub Actions \`L0 Linux Maintenance\` run \`1001\`" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing Linux maintenance run id"
rg -F "GitHub Actions \`L0 Windows Native Evidence\` run \`1002\`" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing Windows native evidence run id"
rg -F "TEST-L0-BATCH" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing local Windows snapshot batch id"
rg -F "test_hygiene_candidate_paths=" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing test hygiene candidate routing"
rg -F "source_review_candidate_paths=" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing source review candidate routing"
rg -F "review_skip_paths=" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing source review skip routing"
rg -F "docs_absorb_candidate_paths=" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing docs absorb candidate routing"
rg -F "report_strict_l0_retained_refs_source_review_shortlist.sh" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing source-review shortlist command"
rg -F "只有当 fresh 输出同时给出 \`closeout.review_candidate_paths=0\` 与 \`rescue.review_candidate_paths=0\` 时，才把 \`closeout/rescue\` 视为已清空" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing fresh-shortlist dual-zero gating"
rg -F "docs/audits/2026-04-15-l0-closeout-rescue-final-source-review-clearout-audit.md" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing historical clearout audit reference"
rg -F "已 fresh 清空" "${AUDIT_FILE}" >/dev/null && fail "audit still claims shortlist already cleared"
rg -F "report_strict_l0_retained_refs_sidecar_tail_overlap.sh" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing sidecar-tail overlap command"
rg -F "tests/cleanup_orphan_dirs.sh" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing tail shell hygiene cleanup cluster"
rg -F "tests/test_active_shell_runners.sh" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing active shell runner contract"
rg -F "tests/test_fs_perf_shell_scripts.sh" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing fs perf shell contract"
rg -F "dangerous_delete_paths=" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing dangerous delete shortlist routing"
rg -F "sidecar_only_commit_count=" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing sidecar overlap count"
rg -F "tail_only_commit_count=" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing tail overlap count"
rg -F "仍锚定 \`main@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\`" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing merged-main Windows mismatch posture"
rg -F "Local main head: \`1111111111111111111111111111111111111111\` (\`main\`)" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing local main head"
rg -F "GitHub Actions \`L0 Linux Maintenance\` run \`1001\`" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing Linux run"
rg -F "GitHub Actions \`L0 Windows Native Evidence\` run \`1002\`" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing Windows run"
rg -F "test_hygiene_candidate_paths=" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing test hygiene candidate routing"
rg -F "source_review_candidate_paths=" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing source review candidate routing"
rg -F "review_skip_paths=" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing source review skip routing"
rg -F "docs_absorb_candidate_paths=" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing docs absorb candidate routing"
rg -F "report_strict_l0_retained_refs_source_review_shortlist.sh" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing source-review shortlist command"
rg -F "只有 fresh 双零才算清空" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing fresh dual-zero current-entry rule"
rg -F "已清空的 source-review lane" "${WORKER_FILE}" >/dev/null && fail "worker handoff still hardcodes cleared source-review lane"
rg -F "shortlist 已清空" "${WORKER_FILE}" >/dev/null && fail "worker handoff still claims shortlist already cleared"
rg -F "report_strict_l0_retained_refs_sidecar_tail_overlap.sh" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing sidecar-tail overlap command"
rg -F "tests/cleanup_orphan_dirs.sh" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing tail shell hygiene cleanup cluster"
rg -F "tests/test_active_shell_runners.sh" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing active shell runner contract"
rg -F "tests/test_fs_perf_shell_scripts.sh" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing fs perf shell contract"
rg -F "dangerous_delete_paths=" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing dangerous delete shortlist routing"
rg -F "sidecar_only_commit_count=" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing sidecar overlap count"
rg -F "tail_only_commit_count=" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing tail overlap count"
rg -F "仍锚定 \`main@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\`" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing merged-main Windows mismatch posture"
rg -F "docs/plans/2026-04-16-l0-mainline-continuation-plan.md" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing continuation plan source-of-truth entry"
rg -F -- "--origin-main-sha <origin-main-sha> --worktree-sha <worktree-sha>" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing split main/origin/worktree updater command"
rg -F "当前本地 \`main\` head：\`1111111111111111111111111111111111111111\`" "${LEGACY_FILE}" >/dev/null \
  || fail "legacy closeout missing local main head"
rg -F "仍锚定 \`main@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\`" "${LEGACY_FILE}" >/dev/null \
  || fail "legacy closeout missing merged-main Windows mismatch posture"
rg -F "TEST-L0-BATCH" "${LEGACY_FILE}" >/dev/null \
  || fail "legacy closeout missing Windows snapshot path"

LTmpDirDiverged="$(mktemp -d)"
trap 'rm -rf "${LTmpDir}" "${LTmpDirDiverged}"' EXIT

mkdir -p "${LTmpDirDiverged}/docs/audits" "${LTmpDirDiverged}/docs/legacy/l0" "${LTmpDirDiverged}/workers"

bash "${TARGET_SCRIPT}" \
  --apply \
  --target-root "${LTmpDirDiverged}" \
  --main-sha "1111111111111111111111111111111111111111" \
  --origin-main-sha "2222222222222222222222222222222222222222" \
  --worktree-sha "3333333333333333333333333333333333333333" \
  --linux-run-id "2001" \
  --linux-run-sha "1111111111111111111111111111111111111111" \
  --windows-run-id "2002" \
  --windows-run-sha "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
  --windows-local-batch-id "TEST-L0-DIVERGED" >/dev/null 2>&1 \
  || fail "docs updater failed to apply diverged main/origin sample data"

DIVERGED_AUDIT_FILE="${LTmpDirDiverged}/docs/audits/2026-04-11-l0-current-state-audit.md"
DIVERGED_LEGACY_FILE="${LTmpDirDiverged}/docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md"
DIVERGED_WORKER_FILE="${LTmpDirDiverged}/workers/worker1.md"

[[ -f "${DIVERGED_AUDIT_FILE}" ]] || fail "diverged audit missing"
[[ -f "${DIVERGED_LEGACY_FILE}" ]] || fail "diverged legacy closeout missing"
[[ -f "${DIVERGED_WORKER_FILE}" ]] || fail "diverged worker handoff missing"

rg -F "当前本地 \`main\` head 是 \`1111111111111111111111111111111111111111\`。" "${DIVERGED_AUDIT_FILE}" >/dev/null \
  || fail "diverged audit missing local main head"
rg -F "当前 \`origin/main\` head 是 \`2222222222222222222222222222222222222222\`。" "${DIVERGED_AUDIT_FILE}" >/dev/null \
  || fail "diverged audit missing origin/main head"
rg -F "当前唯一 L0 worktree \`l0-mainline\` 目前位于 \`3333333333333333333333333333333333333333\`；相对本地 \`main@1111111111111111111111111111111111111111\` 仍承载待整理的本地 L0 增量。" "${DIVERGED_AUDIT_FILE}" >/dev/null \
  || fail "diverged audit missing worktree-vs-main line"
rg -F "当前本地 \`main\` head 是 \`1111111111111111111111111111111111111111\`；当前 \`origin/main\` head 是 \`2222222222222222222222222222222222222222\`；当前 L0 worktree head 是 \`3333333333333333333333333333333333333333\`；latest exact Windows native evidence 仍锚定 \`main@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\`。" "${DIVERGED_AUDIT_FILE}" >/dev/null \
  || fail "diverged audit missing local-vs-origin-vs-windows posture"
rg -F "Local main head: \`1111111111111111111111111111111111111111\` (\`main\`)" "${DIVERGED_WORKER_FILE}" >/dev/null \
  || fail "diverged worker missing local main head"
rg -F "Remote main head: \`2222222222222222222222222222222222222222\` (\`origin/main\`)" "${DIVERGED_WORKER_FILE}" >/dev/null \
  || fail "diverged worker missing origin/main head"
rg -F "当前本地 \`main@1111111111111111111111111111111111111111\`、\`origin/main@2222222222222222222222222222222222222222\` 与当前 worktree head \`3333333333333333333333333333333333333333\` 明确区分" "${DIVERGED_WORKER_FILE}" >/dev/null \
  || fail "diverged worker missing split head focus line"
rg -F "当前本地 \`main\` head：\`1111111111111111111111111111111111111111\`" "${DIVERGED_LEGACY_FILE}" >/dev/null \
  || fail "diverged legacy closeout missing local main head"
rg -F "当前 \`origin/main\` head：\`2222222222222222222222222222222222222222\`" "${DIVERGED_LEGACY_FILE}" >/dev/null \
  || fail "diverged legacy closeout missing origin/main head"
rg -F "当前本地 \`main\` head 是 \`1111111111111111111111111111111111111111\`；当前 \`origin/main\` head 是 \`2222222222222222222222222222222222222222\`；当前 L0 worktree head 是 \`3333333333333333333333333333333333333333\`；latest exact Windows native evidence 仍锚定 \`main@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\`" "${DIVERGED_LEGACY_FILE}" >/dev/null \
  || fail "diverged legacy closeout missing local-vs-origin posture"

LTmpDirAligned="$(mktemp -d)"
trap 'rm -rf "${LTmpDir}" "${LTmpDirDiverged}" "${LTmpDirAligned}"' EXIT

mkdir -p "${LTmpDirAligned}/docs/audits" "${LTmpDirAligned}/docs/legacy/l0" "${LTmpDirAligned}/workers"

bash "${TARGET_SCRIPT}" \
  --apply \
  --target-root "${LTmpDirAligned}" \
  --main-sha "1111111111111111111111111111111111111111" \
  --origin-main-sha "2222222222222222222222222222222222222222" \
  --worktree-sha "2222222222222222222222222222222222222222" \
  --linux-run-id "3001" \
  --linux-run-sha "2222222222222222222222222222222222222222" \
  --windows-run-id "3002" \
  --windows-run-sha "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
  --windows-local-batch-id "TEST-L0-ALIGNED" >/dev/null 2>&1 \
  || fail "docs updater failed to apply origin-aligned active worktree sample data"

ALIGNED_AUDIT_FILE="${LTmpDirAligned}/docs/audits/2026-04-11-l0-current-state-audit.md"
ALIGNED_LEGACY_FILE="${LTmpDirAligned}/docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md"
ALIGNED_WORKER_FILE="${LTmpDirAligned}/workers/worker1.md"

[[ -f "${ALIGNED_AUDIT_FILE}" ]] || fail "aligned audit missing"
[[ -f "${ALIGNED_LEGACY_FILE}" ]] || fail "aligned legacy closeout missing"
[[ -f "${ALIGNED_WORKER_FILE}" ]] || fail "aligned worker handoff missing"

rg -F "当前唯一 L0 worktree \`l0-mainline\` 目前位于 \`2222222222222222222222222222222222222222\`，并与 \`origin/main@2222222222222222222222222222222222222222\` 一致；root \`main@1111111111111111111111111111111111111111\` 仍只作为本地脏工作区记录，不是当前执行面。" "${ALIGNED_AUDIT_FILE}" >/dev/null \
  || fail "aligned audit missing origin-aligned worktree line"
rg -F "当前 root \`main\` head 是 \`1111111111111111111111111111111111111111\`；当前 \`origin/main\` 与 active L0 worktree 已位于 \`2222222222222222222222222222222222222222\`；latest exact Windows native evidence 仍锚定 \`main@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\`。" "${ALIGNED_AUDIT_FILE}" >/dev/null \
  || fail "aligned audit missing active-lane windows posture"
rg -F "Local main head: \`1111111111111111111111111111111111111111\` (\`main\`)" "${ALIGNED_WORKER_FILE}" >/dev/null \
  || fail "aligned worker missing local main head"
rg -F "Remote main head: \`2222222222222222222222222222222222222222\` (\`origin/main\`)" "${ALIGNED_WORKER_FILE}" >/dev/null \
  || fail "aligned worker missing remote main head"
rg -F "当前 active L0 worktree head \`2222222222222222222222222222222222222222\` 与 \`origin/main@2222222222222222222222222222222222222222\` 一致，而 root \`main@1111111111111111111111111111111111111111\` 仍需单独记录" "${ALIGNED_WORKER_FILE}" >/dev/null \
  || fail "aligned worker missing active-lane focus line"
rg -F "当前本地 \`main\` head：\`1111111111111111111111111111111111111111\`" "${ALIGNED_LEGACY_FILE}" >/dev/null \
  || fail "aligned legacy closeout missing local main head"
rg -F "当前 \`origin/main\` head：\`2222222222222222222222222222222222222222\`" "${ALIGNED_LEGACY_FILE}" >/dev/null \
  || fail "aligned legacy closeout missing origin/main head"
rg -F "当前 root \`main\` head 是 \`1111111111111111111111111111111111111111\`；当前 \`origin/main\` 与 active L0 worktree 已位于 \`2222222222222222222222222222222222222222\`；latest exact Windows native evidence 仍锚定 \`main@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\`" "${ALIGNED_LEGACY_FILE}" >/dev/null \
  || fail "aligned legacy closeout missing active-lane windows posture"

echo "[PASS] strict L0 current-state docs updater contract verified"
