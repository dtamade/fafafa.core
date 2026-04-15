#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
APPLY_SCRIPT="${ROOT}/apply_windows_b07_closeout_updates.sh"
SUMMARY_SOURCE="${ROOT}/logs/windows_b07_closeout_summary.md"
EVIDENCE_SOURCE="${ROOT}/logs/windows_b07_gate.log"
FREEZE_SOURCE="${ROOT}/logs/freeze_status.json"

require_file() {
  local aPath

  aPath="$1"
  if [[ ! -f "${aPath}" ]]; then
    echo "[APPLY-REHEARSAL] Missing required file: ${aPath}"
    exit 2
  fi
}

prepare_case() {
  local aCaseRoot
  local aFreezeOffsetSeconds
  local aSummaryOffsetSeconds
  local aEvidenceOffsetSeconds

  aCaseRoot="$1"
  aFreezeOffsetSeconds="$2"
  aSummaryOffsetSeconds="$3"
  aEvidenceOffsetSeconds="$4"

  mkdir -p \
    "${aCaseRoot}/logs" \
    "${aCaseRoot}/repo/docs/plans" \
    "${aCaseRoot}/repo/tests/fafafa.core.simd/docs"

  cp "${SUMMARY_SOURCE}" "${aCaseRoot}/logs/windows_b07_closeout_summary.md"
  cp "${EVIDENCE_SOURCE}" "${aCaseRoot}/logs/windows_b07_gate.log"
  cp "${FREEZE_SOURCE}" "${aCaseRoot}/logs/freeze_status.json"
  cp "${REPO_ROOT}/docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md" \
    "${aCaseRoot}/repo/docs/plans/"
  cp "${REPO_ROOT}/tests/fafafa.core.simd/docs/simd_completeness_matrix.md" \
    "${aCaseRoot}/repo/tests/fafafa.core.simd/docs/"
  cp "${REPO_ROOT}/tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md" \
    "${aCaseRoot}/repo/tests/fafafa.core.simd/docs/"
  cp "${REPO_ROOT}/progress.md" "${aCaseRoot}/repo/"

  python3 - "${aCaseRoot}" "${EVIDENCE_SOURCE}" "${aFreezeOffsetSeconds}" "${aSummaryOffsetSeconds}" "${aEvidenceOffsetSeconds}" <<'PY'
from pathlib import Path
import os
import sys
import time

case_root = Path(sys.argv[1])
evidence_source = sys.argv[2]
freeze_offset_seconds = int(sys.argv[3])
summary_offset_seconds = int(sys.argv[4])
evidence_offset_seconds = int(sys.argv[5])

summary_path = case_root / "logs" / "windows_b07_closeout_summary.md"
evidence_path = case_root / "logs" / "windows_b07_gate.log"
freeze_path = case_root / "logs" / "freeze_status.json"

summary_text = summary_path.read_text(encoding="utf-8")
summary_text = summary_text.replace(evidence_source, str(evidence_path))
summary_path.write_text(summary_text, encoding="utf-8")

base_ns = time.time_ns()
offsets = [
    (freeze_path, freeze_offset_seconds),
    (summary_path, summary_offset_seconds),
    (evidence_path, evidence_offset_seconds),
]
for path, offset_seconds in offsets:
    target_ns = base_ns + offset_seconds * 1_000_000_000
    os.utime(path, ns=(target_ns, target_ns))
PY
}

run_case() {
  local aCaseRoot
  local LCaseRc

  aCaseRoot="$1"
  set +e
  bash "${APPLY_SCRIPT}" \
    "${aCaseRoot}/logs/windows_b07_closeout_summary.md" \
    --freeze-json "${aCaseRoot}/logs/freeze_status.json" \
    --target-root "${aCaseRoot}/repo" \
    --apply > "${aCaseRoot}/apply.out" 2>&1
  LCaseRc=$?
  set -e

  echo "${LCaseRc}"
}

require_file "${APPLY_SCRIPT}"
require_file "${SUMMARY_SOURCE}"
require_file "${EVIDENCE_SOURCE}"
require_file "${FREEZE_SOURCE}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "[APPLY-REHEARSAL] Missing python3"
  exit 2
fi

LTmpRoot="$(mktemp -d)"
trap 'rm -rf "${LTmpRoot}"' EXIT

LCaseReady="${LTmpRoot}/ready"
LCaseStaleSummary="${LTmpRoot}/stale-summary"
LCaseStaleEvidence="${LTmpRoot}/stale-evidence"

prepare_case "${LCaseReady}" 60 0 -60
prepare_case "${LCaseStaleSummary}" -60 60 0
prepare_case "${LCaseStaleEvidence}" 0 -60 60

LCaseReadyRc="$(run_case "${LCaseReady}")"
if [[ "${LCaseReadyRc}" != "0" ]]; then
  echo "[APPLY-REHEARSAL] FAILED: ready case should pass"
  cat "${LCaseReady}/apply.out"
  exit 1
fi
if ! grep -F -- "[CLOSEOUT] APPLY DONE" "${LCaseReady}/apply.out" >/dev/null; then
  echo "[APPLY-REHEARSAL] FAILED: ready case missing APPLY DONE"
  cat "${LCaseReady}/apply.out"
  exit 1
fi

LCaseStaleSummaryRc="$(run_case "${LCaseStaleSummary}")"
if [[ "${LCaseStaleSummaryRc}" == "0" ]]; then
  echo "[APPLY-REHEARSAL] FAILED: stale summary case unexpectedly passed"
  cat "${LCaseStaleSummary}/apply.out"
  exit 1
fi
if ! grep -F -- "Refuse apply: freeze json older than closeout summary" "${LCaseStaleSummary}/apply.out" >/dev/null; then
  echo "[APPLY-REHEARSAL] FAILED: stale summary case missing freshness rejection"
  cat "${LCaseStaleSummary}/apply.out"
  exit 1
fi

LCaseStaleEvidenceRc="$(run_case "${LCaseStaleEvidence}")"
if [[ "${LCaseStaleEvidenceRc}" == "0" ]]; then
  echo "[APPLY-REHEARSAL] FAILED: stale evidence case unexpectedly passed"
  cat "${LCaseStaleEvidence}/apply.out"
  exit 1
fi
if ! grep -F -- "Refuse apply: freeze json older than windows evidence log" "${LCaseStaleEvidence}/apply.out" >/dev/null; then
  echo "[APPLY-REHEARSAL] FAILED: stale evidence case missing freshness rejection"
  cat "${LCaseStaleEvidence}/apply.out"
  exit 1
fi

echo "[APPLY-REHEARSAL] case_ready_rc=${LCaseReadyRc}"
echo "[APPLY-REHEARSAL] case_stale_summary_rc=${LCaseStaleSummaryRc}"
echo "[APPLY-REHEARSAL] case_stale_evidence_rc=${LCaseStaleEvidenceRc}"
echo "[APPLY-REHEARSAL] PASS"
