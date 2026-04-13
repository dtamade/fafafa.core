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
rg -F "report_strict_l0_retained_refs_source_review_shortlist.sh" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing source-review shortlist command"
rg -F "dangerous_delete_paths=" "${AUDIT_FILE}" >/dev/null \
  || fail "audit missing dangerous delete shortlist routing"
rg -F "Base commit: \`1111111111111111111111111111111111111111\`" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing base commit"
rg -F "GitHub Actions \`L0 Linux Maintenance\` run \`1001\`" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing Linux run"
rg -F "GitHub Actions \`L0 Windows Native Evidence\` run \`1002\`" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing Windows run"
rg -F "test_hygiene_candidate_paths=" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing test hygiene candidate routing"
rg -F "source_review_candidate_paths=" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing source review candidate routing"
rg -F "report_strict_l0_retained_refs_source_review_shortlist.sh" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing source-review shortlist command"
rg -F "dangerous_delete_paths=" "${WORKER_FILE}" >/dev/null \
  || fail "worker handoff missing dangerous delete shortlist routing"
rg -F "merge commit：\`1111111111111111111111111111111111111111\`" "${LEGACY_FILE}" >/dev/null \
  || fail "legacy closeout missing main merge commit"

echo "[PASS] strict L0 current-state docs updater contract verified"
