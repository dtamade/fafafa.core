#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKFLOW_FILE="${REPO_ROOT}/.github/workflows/l0-linux-maintenance.yml"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${WORKFLOW_FILE}" ]] || fail "workflow file missing: .github/workflows/l0-linux-maintenance.yml"

rg -F "workflow_dispatch:" "${WORKFLOW_FILE}" >/dev/null \
  || fail "workflow missing workflow_dispatch trigger"
rg -F "workflow_call:" "${WORKFLOW_FILE}" >/dev/null \
  || fail "workflow missing workflow_call trigger"
rg -F "runs-on: ubuntu-latest" "${WORKFLOW_FILE}" >/dev/null \
  || fail "workflow missing ubuntu-latest runner"
rg -F "fp-units-win-rtl" "${WORKFLOW_FILE}" >/dev/null \
  || fail "workflow missing win64 rtl package install"
rg -F "fp-units-win-fcl" "${WORKFLOW_FILE}" >/dev/null \
  || fail "workflow missing win64 fcl package install"
rg -F "bash tests/run_strict_l0_maintenance_loop.sh" "${WORKFLOW_FILE}" >/dev/null \
  || fail "workflow missing strict L0 maintenance loop command"

echo "[PASS] strict L0 linux CI workflow contract verified"
