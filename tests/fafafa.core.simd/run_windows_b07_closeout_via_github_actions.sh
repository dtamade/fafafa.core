#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
WORKFLOW_FILE="simd-windows-b07-evidence.yml"
ARTIFACT_NAME="${SIMD_WIN_EVIDENCE_ARTIFACT_NAME:-simd-windows-b07-evidence}"
EVIDENCE_LOG="${SIMD_WIN_EVIDENCE_LOG_FILE:-${ROOT}/logs/windows_b07_gate.log}"
CANONICAL_EVIDENCE_LOG="${ROOT}/logs/windows_b07_gate.log"
BATCH_ID="${1:-SIMD-$(date '+%Y%m%d')-152}"
RUN_ID_INPUT="${2:-}"
PREFLIGHT_SCRIPT="${ROOT}/preflight_windows_b07_evidence_gh.sh"
BATCH_DIR="${SIMD_WIN_CLOSEOUT_BATCH_DIR:-${ROOT}/logs/windows-closeout/${BATCH_ID}}"
BATCH_EVIDENCE_LOG="${BATCH_DIR}/windows_b07_gate.log"
BATCH_GATE_SUMMARY_MD="${BATCH_DIR}/gate_summary.md"
BATCH_GATE_SUMMARY_JSON="${BATCH_DIR}/gate_summary.json"
BATCH_CLOSEOUT_SUMMARY="${BATCH_DIR}/windows_b07_closeout_summary.md"
BATCH_FREEZE_JSON="${BATCH_DIR}/freeze_status.json"

print_usage() {
  cat <<EOF
Usage: $0 [batch-id] [run-id]

Default batch-id: SIMD-YYYYMMDD-152
Default run-id: auto-dispatch + auto-detect latest workflow_dispatch run for current HEAD
Explicit run-id: skip workflow dispatch and reuse an existing GH Actions run for download/verify/finalize

Environment:
  SIMD_WIN_EVIDENCE_REF              Git ref used for workflow dispatch (default: current branch)
  SIMD_WIN_EVIDENCE_ARTIFACT_NAME    Artifact name (default: simd-windows-b07-evidence)
  SIMD_WIN_EVIDENCE_LOG_FILE         Destination log file (default: tests/fafafa.core.simd/logs/windows_b07_gate.log)
  SIMD_WIN_EVIDENCE_POLL_SECONDS     Poll interval in seconds (default: 5)
  SIMD_WIN_EVIDENCE_POLL_MAX_TRIES   Poll retries (default: 60)
  SIMD_WIN_EVIDENCE_PREFLIGHT        1=enable preflight before dispatch (default: 1)
EOF
}

if [[ "${BATCH_ID}" == "-h" || "${BATCH_ID}" == "--help" ]]; then
  print_usage
  exit 0
fi

require_cmd() {
  local aCmd
  aCmd="$1"
  if ! command -v "${aCmd}" >/dev/null 2>&1; then
    echo "[WIN-EVIDENCE-GH] Missing command: ${aCmd}"
    exit 2
  fi
}

paths_equal() {
  local aLeft
  local aRight

  aLeft="$1"
  aRight="$2"

  python3 - "${aLeft}" "${aRight}" <<'PY'
from pathlib import Path
import os
import sys


def normalize(value: str) -> str:
    path = Path(value).expanduser()
    try:
        return str(path.resolve(strict=False))
    except Exception:
        return os.path.abspath(os.path.expanduser(str(path)))


sys.exit(0 if normalize(sys.argv[1]) == normalize(sys.argv[2]) else 1)
PY
}

is_billing_block_output() {
  local aText
  local LNormalized

  aText="${1:-}"
  if [[ -z "${aText}" ]]; then
    return 1
  fi

  LNormalized="$(printf '%s' "${aText}" | tr '[:upper:]' '[:lower:]')"
  if [[ "${LNormalized}" == *"recent account payments have failed"* ]] ||
     [[ "${LNormalized}" == *"spending limit needs to be increased"* ]] ||
     [[ "${LNormalized}" == *"billing & plans"* ]]; then
    return 0
  fi

  return 1
}

wait_for_run_completion() {
  local aRunId
  local aPollSeconds
  local aPollMaxTries
  local LJson
  local LStatus
  local LConclusion
  local LRunViewText

  aRunId="$1"
  aPollSeconds="$2"
  aPollMaxTries="$3"

  for ((LTry = 1; LTry <= aPollMaxTries; LTry++)); do
    LJson="$(gh run view "${aRunId}" --json status,conclusion,url 2>/dev/null || true)"
    if [[ -n "${LJson}" ]]; then
      read -r LStatus LConclusion < <(python3 - "${LJson}" <<'PY'
import json
import sys

raw = sys.argv[1].strip()
if not raw:
    print(" ")
    sys.exit(0)

obj = json.loads(raw)
status = obj.get("status", "") or ""
conclusion = obj.get("conclusion", "") or ""
print(f"{status} {conclusion}")
PY
)

      if [[ "${LStatus}" == "completed" ]]; then
        if [[ "${LConclusion}" == "success" ]]; then
          return 0
        fi
        echo "[WIN-EVIDENCE-GH] Workflow failed: run=${aRunId}, conclusion=${LConclusion}"
        LRunViewText="$(gh run view "${aRunId}" 2>&1 || true)"
        if [[ -n "${LRunViewText}" ]]; then
          echo "${LRunViewText}"
        fi
        if is_billing_block_output "${LRunViewText}"; then
          echo "[WIN-EVIDENCE-GH] Billing/runner block detected (exit=31)"
          return 31
        fi
        return 1
      fi
    fi
    sleep "${aPollSeconds}"
  done

  echo "[WIN-EVIDENCE-GH] Timeout waiting for workflow run completion: ${aRunId}"
  return 1
}

find_latest_run_id_for_dispatch() {
  local aHeadSha
  local aHeadBranch
  local aDispatchEpoch
  local LJson

  aHeadSha="$1"
  aHeadBranch="$2"
  aDispatchEpoch="$3"
  LJson="$(gh run list \
    --workflow "${WORKFLOW_FILE}" \
    --limit 30 \
    --json databaseId,headSha,headBranch,event,status,conclusion,createdAt 2>/dev/null || true)"

  if [[ -z "${LJson}" ]]; then
    return 0
  fi

  python3 - "${aHeadSha}" "${aHeadBranch}" "${aDispatchEpoch}" "${LJson}" <<'PY'
import json
import sys
from datetime import datetime

head_sha = sys.argv[1].strip().lower()
head_branch = sys.argv[2].strip()
dispatch_epoch = int(sys.argv[3] or "0")
raw = sys.argv[4].strip()
if not raw:
    sys.exit(0)

rows = json.loads(raw)
best = None

def to_epoch(created_at: str) -> int:
    if not created_at:
        return 0
    try:
        if created_at.endswith("Z"):
            created_at = created_at[:-1] + "+00:00"
        return int(datetime.fromisoformat(created_at).timestamp())
    except Exception:
        return 0

for row in rows:
    if row.get("event") != "workflow_dispatch":
        continue

    run_id = row.get("databaseId")
    if run_id is None:
        continue

    row_sha = str(row.get("headSha", "")).strip().lower()
    row_branch = str(row.get("headBranch", "")).strip()
    row_epoch = to_epoch(str(row.get("createdAt", "")).strip())

    if head_sha and row_sha == head_sha:
        score = 0
    elif head_branch and row_branch == head_branch:
        score = 1
    elif dispatch_epoch > 0 and row_epoch >= dispatch_epoch - 10:
        score = 2
    else:
        continue

    candidate = (score, -row_epoch, int(run_id))
    if best is None or candidate < best:
        best = candidate

if best is not None:
    print(best[2])
PY
}

require_cmd gh
require_cmd python3

if ! gh auth status >/dev/null 2>&1; then
  echo "[WIN-EVIDENCE-GH] gh auth required"
  exit 2
fi

LPollSeconds="${SIMD_WIN_EVIDENCE_POLL_SECONDS:-5}"
LPollMaxTries="${SIMD_WIN_EVIDENCE_POLL_MAX_TRIES:-60}"
LDispatchRetries="${SIMD_WIN_EVIDENCE_DISPATCH_RETRIES:-3}"
LDispatchBackoffSeconds="${SIMD_WIN_EVIDENCE_DISPATCH_BACKOFF_SECONDS:-2}"
LRunId="${RUN_ID_INPUT}"
LDispatchEpoch=0

if [[ -z "${LRunId}" ]]; then
  require_cmd git
  LRef="${SIMD_WIN_EVIDENCE_REF:-$(git -C "${REPO_ROOT}" branch --show-current || true)}"
  if [[ -z "${LRef}" ]]; then
    LRef="$(git -C "${REPO_ROOT}" rev-parse HEAD)"
  fi
  LHeadShaLocal="$(git -C "${REPO_ROOT}" rev-parse "${LRef}" 2>/dev/null || true)"
  LHeadShaRemote="$(git -C "${REPO_ROOT}" ls-remote --heads origin "${LRef}" 2>/dev/null | awk '{print $1}' | head -n 1 || true)"
  LHeadSha="${LHeadShaRemote:-${LHeadShaLocal}}"

  if [[ -n "$(git -C "${REPO_ROOT}" status --short --untracked-files=no)" ]]; then
    echo "[WIN-EVIDENCE-GH] Refuse dispatch: local worktree has uncommitted changes."
    echo "[WIN-EVIDENCE-GH] Commit/push or stash local SIMD changes before using GH Windows evidence."
    exit 2
  fi

  if [[ -n "${LHeadShaRemote}" && -n "${LHeadShaLocal}" && "${LHeadShaRemote}" != "${LHeadShaLocal}" ]]; then
    echo "[WIN-EVIDENCE-GH] Refuse dispatch: remote ref does not match local HEAD."
    echo "[WIN-EVIDENCE-GH] ref=${LRef} local=${LHeadShaLocal} remote=${LHeadShaRemote}"
    echo "[WIN-EVIDENCE-GH] Push the local closeout fixes first, then rerun win-evidence-via-gh."
    exit 2
  fi

  if [[ "${SIMD_WIN_EVIDENCE_PREFLIGHT:-1}" != "0" ]]; then
    if [[ ! -x "${PREFLIGHT_SCRIPT}" ]]; then
      echo "[WIN-EVIDENCE-GH] Missing preflight script: ${PREFLIGHT_SCRIPT}"
      exit 2
    fi
    echo "[WIN-EVIDENCE-GH] Preflight before dispatch"
    "${PREFLIGHT_SCRIPT}" --workflow "${WORKFLOW_FILE}"
  fi

  echo "[WIN-EVIDENCE-GH] Dispatch workflow: ${WORKFLOW_FILE} (ref=${LRef}, head=${LHeadSha})"
  LDispatchEpoch="$(date +%s)"
  gh workflow run "${WORKFLOW_FILE}" --ref "${LRef}"

  for ((LTry = 1; LTry <= LPollMaxTries; LTry++)); do
    LRunId="$(find_latest_run_id_for_dispatch "${LHeadSha}" "${LRef}" "${LDispatchEpoch}")"
    if [[ -n "${LRunId}" ]]; then
      break
    fi
    sleep "${LPollSeconds}"
  done
else
  echo "[WIN-EVIDENCE-GH] Reuse existing workflow run: ${LRunId}"
fi

if [[ -z "${LRunId}" ]]; then
  echo "[WIN-EVIDENCE-GH] Failed to locate workflow run id"
  exit 1
fi

echo "[WIN-EVIDENCE-GH] Watching run: ${LRunId}"
wait_for_run_completion "${LRunId}" "${LPollSeconds}" "${LPollMaxTries}" || {
  LWaitRc=$?
  exit "${LWaitRc}"
}

LTempDir="$(mktemp -d)"
cleanup() {
  rm -rf "${LTempDir}"
}
trap cleanup EXIT

echo "[WIN-EVIDENCE-GH] Download artifact: ${ARTIFACT_NAME}"
gh run download "${LRunId}" -n "${ARTIFACT_NAME}" -D "${LTempDir}"

LSourceLog="$(find "${LTempDir}" -type f -name 'windows_b07_gate.log' | head -n 1 || true)"
if [[ -z "${LSourceLog}" ]]; then
  echo "[WIN-EVIDENCE-GH] Missing windows_b07_gate.log in downloaded artifact"
  exit 1
fi

LSourceGateSummaryMd="$(find "${LTempDir}" -type f -name 'gate_summary.md' | head -n 1 || true)"
LSourceGateSummaryJson="$(find "${LTempDir}" -type f -name 'gate_summary.json' | head -n 1 || true)"

mkdir -p "$(dirname "${EVIDENCE_LOG}")" "$(dirname "${CANONICAL_EVIDENCE_LOG}")" "${BATCH_DIR}"
if ! paths_equal "${BATCH_GATE_SUMMARY_MD}" "${ROOT}/logs/gate_summary.md"; then
  rm -f "${BATCH_GATE_SUMMARY_MD}"
fi
if ! paths_equal "${BATCH_GATE_SUMMARY_JSON}" "${ROOT}/logs/gate_summary.json"; then
  rm -f "${BATCH_GATE_SUMMARY_JSON}"
fi
if ! paths_equal "${LSourceLog}" "${BATCH_EVIDENCE_LOG}"; then
  cp "${LSourceLog}" "${BATCH_EVIDENCE_LOG}"
fi
if ! paths_equal "${LSourceLog}" "${CANONICAL_EVIDENCE_LOG}"; then
  cp "${LSourceLog}" "${CANONICAL_EVIDENCE_LOG}"
fi
if ! paths_equal "${EVIDENCE_LOG}" "${CANONICAL_EVIDENCE_LOG}" && ! paths_equal "${LSourceLog}" "${EVIDENCE_LOG}"; then
  cp "${LSourceLog}" "${EVIDENCE_LOG}"
fi
echo "[WIN-EVIDENCE-GH] Evidence log updated: ${EVIDENCE_LOG}"
echo "[WIN-EVIDENCE-GH] Canonical evidence log: ${CANONICAL_EVIDENCE_LOG}"
echo "[WIN-EVIDENCE-GH] Batch evidence log: ${BATCH_EVIDENCE_LOG}"

if [[ -n "${LSourceGateSummaryMd}" ]]; then
  if ! paths_equal "${LSourceGateSummaryMd}" "${BATCH_GATE_SUMMARY_MD}"; then
    cp "${LSourceGateSummaryMd}" "${BATCH_GATE_SUMMARY_MD}"
  fi
  if ! paths_equal "${LSourceGateSummaryMd}" "${ROOT}/logs/gate_summary.md"; then
    cp "${LSourceGateSummaryMd}" "${ROOT}/logs/gate_summary.md"
  fi
  echo "[WIN-EVIDENCE-GH] Batch gate summary md: ${BATCH_GATE_SUMMARY_MD}"
else
  echo "[WIN-EVIDENCE-GH] WARN: gate_summary.md missing in downloaded artifact; batch snapshot cleared and freeze-status will fallback to local canonical gate summary if needed"
fi

if [[ -n "${LSourceGateSummaryJson}" ]]; then
  if ! paths_equal "${LSourceGateSummaryJson}" "${BATCH_GATE_SUMMARY_JSON}"; then
    cp "${LSourceGateSummaryJson}" "${BATCH_GATE_SUMMARY_JSON}"
  fi
  if ! paths_equal "${LSourceGateSummaryJson}" "${ROOT}/logs/gate_summary.json"; then
    cp "${LSourceGateSummaryJson}" "${ROOT}/logs/gate_summary.json"
  fi
  echo "[WIN-EVIDENCE-GH] Batch gate summary json: ${BATCH_GATE_SUMMARY_JSON}"
else
  echo "[WIN-EVIDENCE-GH] WARN: gate_summary.json missing in downloaded artifact; batch snapshot cleared and verifier will fallback to log-only mode"
fi

echo "[WIN-EVIDENCE-GH] Verify downloaded evidence"
bash "${ROOT}/verify_windows_b07_evidence.sh" "${BATCH_EVIDENCE_LOG}" "${BATCH_GATE_SUMMARY_JSON}"

echo "[WIN-EVIDENCE-GH] Backfill cross gate (SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1)"
FAFAFA_BUILD_MODE="${FAFAFA_BUILD_MODE:-Release}" \
SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 \
bash "${ROOT}/BuildOrTest.sh" gate

echo "[WIN-EVIDENCE-GH] Run closeout finalize"
export SIMD_WIN_EVIDENCE_LOG_FILE="${BATCH_EVIDENCE_LOG}"
export SIMD_WIN_CLOSEOUT_SUMMARY_FILE="${BATCH_CLOSEOUT_SUMMARY}"
export SIMD_WIN_FREEZE_STATUS_JSON_FILE="${BATCH_FREEZE_JSON}"
export SIMD_FREEZE_WINDOWS_LOG_FILE="${BATCH_EVIDENCE_LOG}"
export SIMD_FREEZE_WINDOWS_CLOSEOUT_SUMMARY_FILE="${BATCH_CLOSEOUT_SUMMARY}"
export SIMD_WIN_CLOSEOUT_BATCH_DIR="${BATCH_DIR}"
if [[ -f "${BATCH_GATE_SUMMARY_MD}" ]]; then
  export SIMD_FREEZE_GATE_SUMMARY_FILE="${BATCH_GATE_SUMMARY_MD}"
else
  unset SIMD_FREEZE_GATE_SUMMARY_FILE || true
fi
bash "${ROOT}/run_windows_b07_closeout_finalize.sh" "${BATCH_ID}"

if [[ -f "${BATCH_CLOSEOUT_SUMMARY}" ]]; then
  cp "${BATCH_CLOSEOUT_SUMMARY}" "${ROOT}/logs/windows_b07_closeout_summary.md"
fi

if [[ -f "${BATCH_FREEZE_JSON}" ]]; then
  cp "${BATCH_FREEZE_JSON}" "${ROOT}/logs/freeze_status.json"
fi
