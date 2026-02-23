#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
WORKFLOW_FILE=".github/workflows/simd-windows-b07-evidence.yml"
ARTIFACT_NAME="${SIMD_WIN_EVIDENCE_ARTIFACT_NAME:-simd-windows-b07-evidence}"
EVIDENCE_LOG="${SIMD_WIN_EVIDENCE_LOG_FILE:-${ROOT}/logs/windows_b07_gate.log}"
BATCH_ID="${1:-SIMD-$(date '+%Y%m%d')-152}"
RUN_ID_INPUT="${2:-}"

print_usage() {
  cat <<EOF
Usage: $0 [batch-id] [run-id]

Default batch-id: SIMD-YYYYMMDD-152
Default run-id: auto-dispatch + auto-detect latest workflow_dispatch run for current HEAD

Environment:
  SIMD_WIN_EVIDENCE_REF              Git ref used for workflow dispatch (default: current branch)
  SIMD_WIN_EVIDENCE_ARTIFACT_NAME    Artifact name (default: simd-windows-b07-evidence)
  SIMD_WIN_EVIDENCE_LOG_FILE         Destination log file (default: tests/fafafa.core.simd/logs/windows_b07_gate.log)
  SIMD_WIN_EVIDENCE_POLL_SECONDS     Poll interval in seconds (default: 5)
  SIMD_WIN_EVIDENCE_POLL_MAX_TRIES   Poll retries (default: 60)
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

find_latest_run_id_for_head() {
  local aHeadSha
  aHeadSha="$1"
  gh run list \
    --workflow "${WORKFLOW_FILE}" \
    --limit 30 \
    --json databaseId,headSha,event,status,conclusion,createdAt \
    | python3 - "${aHeadSha}" <<'PY'
import json
import sys

head_sha = sys.argv[1].strip().lower()
rows = json.load(sys.stdin)
for row in rows:
    row_sha = str(row.get("headSha", "")).strip().lower()
    if row_sha != head_sha:
        continue
    if row.get("event") != "workflow_dispatch":
        continue
    run_id = row.get("databaseId")
    if run_id is not None:
        print(run_id)
        break
PY
}

require_cmd gh
require_cmd python3
require_cmd git

if ! gh auth status >/dev/null 2>&1; then
  echo "[WIN-EVIDENCE-GH] gh auth required"
  exit 2
fi

LRef="${SIMD_WIN_EVIDENCE_REF:-$(git -C "${REPO_ROOT}" branch --show-current || true)}"
if [[ -z "${LRef}" ]]; then
  LRef="$(git -C "${REPO_ROOT}" rev-parse HEAD)"
fi
LHeadSha="$(git -C "${REPO_ROOT}" rev-parse "${LRef}")"
LPollSeconds="${SIMD_WIN_EVIDENCE_POLL_SECONDS:-5}"
LPollMaxTries="${SIMD_WIN_EVIDENCE_POLL_MAX_TRIES:-60}"
LRunId="${RUN_ID_INPUT}"

if [[ -z "${LRunId}" ]]; then
  echo "[WIN-EVIDENCE-GH] Dispatch workflow: ${WORKFLOW_FILE} (ref=${LRef}, head=${LHeadSha})"
  gh workflow run "${WORKFLOW_FILE}" --ref "${LRef}"

  for ((LTry = 1; LTry <= LPollMaxTries; LTry++)); do
    LRunId="$(find_latest_run_id_for_head "${LHeadSha}")"
    if [[ -n "${LRunId}" ]]; then
      break
    fi
    sleep "${LPollSeconds}"
  done
fi

if [[ -z "${LRunId}" ]]; then
  echo "[WIN-EVIDENCE-GH] Failed to locate workflow run id"
  exit 1
fi

echo "[WIN-EVIDENCE-GH] Watching run: ${LRunId}"
gh run watch "${LRunId}" --exit-status

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

mkdir -p "$(dirname "${EVIDENCE_LOG}")"
cp "${LSourceLog}" "${EVIDENCE_LOG}"
echo "[WIN-EVIDENCE-GH] Evidence log updated: ${EVIDENCE_LOG}"

echo "[WIN-EVIDENCE-GH] Verify downloaded evidence"
bash "${ROOT}/verify_windows_b07_evidence.sh" "${EVIDENCE_LOG}"

echo "[WIN-EVIDENCE-GH] Run closeout finalize"
bash "${ROOT}/run_windows_b07_closeout_finalize.sh" "${BATCH_ID}"
