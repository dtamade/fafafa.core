#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/run_strict_l0_mainline_closeout.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${TARGET_SCRIPT}" ]] || fail "missing strict L0 mainline closeout script"

rg -F "lib_github_actions_workflow_runs.sh" "${TARGET_SCRIPT}" >/dev/null \
  || fail "mainline closeout script does not source the shared GH workflow helper"

OUTPUT="$(bash "${TARGET_SCRIPT}" --print-commands 2>&1)" || fail "mainline closeout script failed to satisfy contract"

printf '%s\n' "${OUTPUT}" | rg -F "gh workflow run l0-linux-maintenance.yml --ref main" >/dev/null \
  || fail "mainline closeout did not print the Linux maintenance workflow command"
printf '%s\n' "${OUTPUT}" | rg -F "bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh" >/dev/null \
  || fail "mainline closeout did not print the Windows native evidence helper command"
printf '%s\n' "${OUTPUT}" | rg -F "bash tests/update_strict_l0_current_state_docs.sh" >/dev/null \
  || fail "mainline closeout did not print the docs backfill command"
printf '%s\n' "${OUTPUT}" | rg -F -- "--origin-main-sha <origin-main-sha>" >/dev/null \
  || fail "mainline closeout did not print the origin/main docs backfill placeholder"
printf '%s\n' "${OUTPUT}" | rg -F -- "--worktree-sha <worktree-sha>" >/dev/null \
  || fail "mainline closeout did not print the worktree head docs backfill placeholder"

echo "[PASS] strict L0 mainline closeout contract verified"
