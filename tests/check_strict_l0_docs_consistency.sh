#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

check_main_sha_absent() {
  local aPath="$1"
  if rg -n "main@[0-9a-f]{7,}" "${REPO_ROOT}/${aPath}" >/dev/null; then
    fail "${aPath} still contains transient main SHA anchor"
  fi
  echo "[CHECK] transient main SHA absent in ${aPath}"
}

check_file() {
  local aPath="$1"
  if [[ ! -f "${REPO_ROOT}/${aPath}" ]]; then
    fail "missing required file: ${aPath}"
  fi
  echo "[CHECK] file exists: ${aPath}"
}

require_literal() {
  local aPath="$1"
  local aLiteral="$2"
  if ! rg -F --quiet -- "${aLiteral}" "${REPO_ROOT}/${aPath}"; then
    fail "${aPath} missing literal: ${aLiteral}"
  fi
  echo "[CHECK] literal found in ${aPath}: ${aLiteral}"
}

reject_literal() {
  local aPath="$1"
  local aLiteral="$2"
  if rg -F --quiet -- "${aLiteral}" "${REPO_ROOT}/${aPath}"; then
    fail "${aPath} still contains stale literal: ${aLiteral}"
  fi
  echo "[CHECK] stale literal absent in ${aPath}: ${aLiteral}"
}

REQUIRED_FILES=(
  "docs/README.md"
  "docs/INDEX.md"
  "docs/CI.md"
  "docs/TESTING.md"
  "docs/fafafa.core.l0.foundation.md"
  "docs/fafafa.core.l0.roadmap.md"
  "docs/audits/2026-04-11-l0-current-state-audit.md"
  "docs/audits/2026-04-12-l0-retained-refs-absorption-audit.md"
  "docs/plans/2026-04-11-l0-post-merge-stabilization-plan.md"
  "docs/legacy/l0/README.md"
  "docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md"
  "docs/legacy/l0/2026-04-11-l0-mainline-merge-checklist.md"
  "docs/legacy/l0/2026-04-11-l0-mainline-replay-execution-plan.md"
  "workers/worker1.md"
  "tests/run_strict_l0_maintenance_loop.sh"
  "tests/audit_strict_l0_retained_refs.sh"
  "tests/report_strict_l0_retained_refs_inventory.sh"
  "tests/run_strict_l0_mainline_closeout.sh"
  "tests/test_strict_l0_mainline_closeout_e2e_contract.sh"
  "tests/update_strict_l0_current_state_docs.sh"
  "tests/lib_github_actions_workflow_runs.sh"
  ".github/workflows/l0-linux-maintenance.yml"
)

for LPath in "${REQUIRED_FILES[@]}"; do
  check_file "${LPath}"
done

require_literal "docs/README.md" "docs/plans/2026-04-11-l0-post-merge-stabilization-plan.md"
require_literal "docs/README.md" "docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md"
require_literal "docs/README.md" "docs/legacy/l0/2026-04-11-l0-mainline-merge-checklist.md"
require_literal "docs/README.md" "docs/legacy/l0/2026-04-11-l0-mainline-replay-execution-plan.md"
require_literal "docs/README.md" "docs/audits/2026-04-12-l0-retained-refs-absorption-audit.md"
reject_literal "docs/README.md" "docs/plans/2026-04-11-l0-mainline-merge-checklist.md"
reject_literal "docs/README.md" "docs/plans/2026-04-11-l0-mainline-replay-execution-plan.md"

require_literal "docs/INDEX.md" "docs/plans/2026-04-11-l0-post-merge-stabilization-plan.md"
require_literal "docs/INDEX.md" "docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md"
require_literal "docs/INDEX.md" "docs/legacy/l0/2026-04-11-l0-mainline-merge-checklist.md"
require_literal "docs/INDEX.md" "docs/legacy/l0/2026-04-11-l0-mainline-replay-execution-plan.md"
require_literal "docs/INDEX.md" "docs/audits/2026-04-12-l0-retained-refs-absorption-audit.md"
reject_literal "docs/INDEX.md" "docs/plans/2026-04-11-l0-mainline-merge-checklist.md"
reject_literal "docs/INDEX.md" "docs/plans/2026-04-11-l0-mainline-replay-execution-plan.md"

require_literal "docs/legacy/l0/README.md" "2026-04-11-l0-mainline-refs-and-ci-closeout.md"

require_literal "docs/CI.md" "bash tests/run_strict_l0_maintenance_loop.sh"
require_literal "docs/CI.md" "bash tests/run_strict_l0_mainline_closeout.sh"
require_literal "docs/CI.md" "bash tests/update_strict_l0_current_state_docs.sh"
require_literal "docs/CI.md" "GitHub Actions"
require_literal "docs/CI.md" "gh workflow run l0-linux-maintenance.yml --ref l0-mainline"
require_literal "docs/CI.md" "default branch"
require_literal "docs/TESTING.md" "bash tests/run_strict_l0_maintenance_loop.sh"
require_literal "docs/TESTING.md" "bash tests/run_strict_l0_mainline_closeout.sh"
require_literal "docs/TESTING.md" "bash tests/update_strict_l0_current_state_docs.sh"
require_literal "docs/TESTING.md" "bash tests/audit_strict_l0_retained_refs.sh"
require_literal "docs/TESTING.md" "bash tests/report_strict_l0_retained_refs_inventory.sh"
require_literal "docs/INDEX.md" "bash tests/run_strict_l0_mainline_closeout.sh"
require_literal "docs/INDEX.md" "bash tests/update_strict_l0_current_state_docs.sh"
require_literal "docs/INDEX.md" "bash tests/audit_strict_l0_retained_refs.sh"
require_literal "docs/INDEX.md" "bash tests/report_strict_l0_retained_refs_inventory.sh"
require_literal "docs/audits/2026-04-11-l0-current-state-audit.md" "GitHub Actions"
require_literal "docs/audits/2026-04-11-l0-current-state-audit.md" "bash tests/report_strict_l0_retained_refs_inventory.sh"
require_literal "docs/fafafa.core.l0.roadmap.md" "Windows exact native evidence 只接受 GitHub Actions 作为证据来源"
require_literal "workers/worker1.md" "bash tests/run_strict_l0_maintenance_loop.sh"
require_literal "workers/worker1.md" "bash tests/run_strict_l0_mainline_closeout.sh"
require_literal "workers/worker1.md" "bash tests/update_strict_l0_current_state_docs.sh"
require_literal "workers/worker1.md" "bash tests/audit_strict_l0_retained_refs.sh"
require_literal "workers/worker1.md" "bash tests/report_strict_l0_retained_refs_inventory.sh"
require_literal "workers/worker1.md" "GitHub Actions"
require_literal ".github/workflows/l0-linux-maintenance.yml" "workflow_dispatch:"
require_literal ".github/workflows/l0-linux-maintenance.yml" "workflow_call:"
require_literal ".github/workflows/l0-linux-maintenance.yml" "bash tests/run_strict_l0_maintenance_loop.sh"

check_main_sha_absent "docs/README.md"
check_main_sha_absent "docs/INDEX.md"
check_main_sha_absent "docs/CI.md"
check_main_sha_absent "docs/fafafa.core.l0.roadmap.md"

echo "[PASS] strict L0 docs consistency verified"
