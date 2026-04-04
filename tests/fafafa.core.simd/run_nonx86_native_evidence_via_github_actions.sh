#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
BACKEND="${1:-}"
RUN_ID_INPUT="${2:-}"

print_usage() {
  cat <<EOF
Usage: $0 <backend> [run-id]

Backends:
  neon    Dispatch/download ARM64 NEON native evidence workflow
  riscvv  Dispatch/download RISCVV native evidence workflow

Default run-id: auto-dispatch + auto-detect latest workflow_dispatch run for current HEAD
Explicit run-id: skip workflow dispatch and reuse an existing GH Actions run for download only

Environment:
  SIMD_NATIVE_EVIDENCE_REF             Git ref used for workflow dispatch (default: current branch)
  SIMD_NATIVE_EVIDENCE_WORKFLOW_FILE   Override workflow file for the selected backend
  SIMD_NATIVE_EVIDENCE_ARTIFACT_NAME   Override artifact name for the selected backend
  SIMD_NATIVE_EVIDENCE_DOWNLOAD_ROOT   Local snapshot root (default: tests/fafafa.core.simd/logs/native-evidence-gh)
  SIMD_NATIVE_EVIDENCE_POLL_SECONDS    Poll interval in seconds (default: 5)
  SIMD_NATIVE_EVIDENCE_POLL_MAX_TRIES  Poll retries (default: 120)
EOF
}

if [[ -z "${BACKEND}" || "${BACKEND}" == "-h" || "${BACKEND}" == "--help" ]]; then
  print_usage
  exit 0
fi

require_cmd() {
  local aCmd

  aCmd="${1:-}"
  if ! command -v "${aCmd}" >/dev/null 2>&1; then
    echo "[NATIVE-EVIDENCE-GH] Missing command: ${aCmd}"
    exit 2
  fi
}

resolve_workflow_file() {
  local aBackend

  aBackend="${1:-}"
  if [[ -n "${SIMD_NATIVE_EVIDENCE_WORKFLOW_FILE:-}" ]]; then
    printf '%s\n' "${SIMD_NATIVE_EVIDENCE_WORKFLOW_FILE}"
    return 0
  fi

  case "${aBackend}" in
    neon)
      printf '%s\n' "simd-arm64-neon-evidence.yml"
      ;;
    riscvv)
      printf '%s\n' "simd-riscvv-native-evidence.yml"
      ;;
    *)
      return 1
      ;;
  esac
}

resolve_artifact_name() {
  local aBackend

  aBackend="${1:-}"
  if [[ -n "${SIMD_NATIVE_EVIDENCE_ARTIFACT_NAME:-}" ]]; then
    printf '%s\n' "${SIMD_NATIVE_EVIDENCE_ARTIFACT_NAME}"
    return 0
  fi

  case "${aBackend}" in
    neon)
      printf '%s\n' "simd-arm64-neon-evidence"
      ;;
    riscvv)
      printf '%s\n' "simd-riscvv-native-evidence"
      ;;
    *)
      return 1
      ;;
  esac
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

  aRunId="${1:-}"
  aPollSeconds="${2:-5}"
  aPollMaxTries="${3:-120}"

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
        echo "[NATIVE-EVIDENCE-GH] Workflow failed: run=${aRunId}, conclusion=${LConclusion}"
        LRunViewText="$(gh run view "${aRunId}" 2>&1 || true)"
        if [[ -n "${LRunViewText}" ]]; then
          echo "${LRunViewText}"
        fi
        if is_billing_block_output "${LRunViewText}"; then
          echo "[NATIVE-EVIDENCE-GH] Billing/runner block detected (exit=31)"
          return 31
        fi
        return 1
      fi
    fi
    sleep "${aPollSeconds}"
  done

  echo "[NATIVE-EVIDENCE-GH] Timeout waiting for workflow run completion: ${aRunId}"
  return 1
}

find_latest_run_id_for_dispatch() {
  local aWorkflowFile
  local aHeadSha
  local aHeadBranch
  local aDispatchEpoch
  local LJson

  aWorkflowFile="${1:-}"
  aHeadSha="${2:-}"
  aHeadBranch="${3:-}"
  aDispatchEpoch="${4:-0}"
  LJson="$(gh run list \
    --workflow "${aWorkflowFile}" \
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

copy_downloaded_artifact() {
  local aSourceDir
  local aTargetDir

  aSourceDir="${1:-}"
  aTargetDir="${2:-}"

  rm -rf "${aTargetDir}"
  mkdir -p "${aTargetDir}"
  cp -a "${aSourceDir}/." "${aTargetDir}/"
}

require_cmd gh
require_cmd python3

if ! gh auth status >/dev/null 2>&1; then
  echo "[NATIVE-EVIDENCE-GH] gh auth required"
  exit 2
fi

WORKFLOW_FILE="$(resolve_workflow_file "${BACKEND}" || true)"
ARTIFACT_NAME="$(resolve_artifact_name "${BACKEND}" || true)"
if [[ -z "${WORKFLOW_FILE}" || -z "${ARTIFACT_NAME}" ]]; then
  echo "[NATIVE-EVIDENCE-GH] Unsupported backend: ${BACKEND}"
  print_usage
  exit 2
fi

LPollSeconds="${SIMD_NATIVE_EVIDENCE_POLL_SECONDS:-5}"
LPollMaxTries="${SIMD_NATIVE_EVIDENCE_POLL_MAX_TRIES:-120}"
LRunId="${RUN_ID_INPUT}"
LDispatchEpoch=0

if [[ -z "${LRunId}" ]]; then
  require_cmd git
  LRef="${SIMD_NATIVE_EVIDENCE_REF:-$(git -C "${REPO_ROOT}" branch --show-current || true)}"
  if [[ -z "${LRef}" ]]; then
    LRef="$(git -C "${REPO_ROOT}" rev-parse HEAD)"
  fi
  LHeadShaLocal="$(git -C "${REPO_ROOT}" rev-parse "${LRef}" 2>/dev/null || true)"
  LHeadShaRemote="$(git -C "${REPO_ROOT}" ls-remote --heads origin "${LRef}" 2>/dev/null | awk '{print $1}' | head -n 1 || true)"
  LHeadSha="${LHeadShaRemote:-${LHeadShaLocal}}"

  if [[ -n "$(git -C "${REPO_ROOT}" status --short --untracked-files=no)" ]]; then
    echo "[NATIVE-EVIDENCE-GH] Refuse dispatch: local worktree has uncommitted changes."
    echo "[NATIVE-EVIDENCE-GH] Commit/push or stash local SIMD changes before using GH native evidence."
    exit 2
  fi

  if [[ -n "${LHeadShaRemote}" && -n "${LHeadShaLocal}" && "${LHeadShaRemote}" != "${LHeadShaLocal}" ]]; then
    echo "[NATIVE-EVIDENCE-GH] Refuse dispatch: remote ref does not match local HEAD."
    echo "[NATIVE-EVIDENCE-GH] ref=${LRef} local=${LHeadShaLocal} remote=${LHeadShaRemote}"
    echo "[NATIVE-EVIDENCE-GH] Push the local SIMD fixes first, then rerun native-evidence-via-gh."
    exit 2
  fi

  echo "[NATIVE-EVIDENCE-GH] Dispatch workflow: ${WORKFLOW_FILE} (backend=${BACKEND}, ref=${LRef}, head=${LHeadSha})"
  LDispatchEpoch="$(date +%s)"
  gh workflow run "${WORKFLOW_FILE}" --ref "${LRef}"

  for ((LTry = 1; LTry <= LPollMaxTries; LTry++)); do
    LRunId="$(find_latest_run_id_for_dispatch "${WORKFLOW_FILE}" "${LHeadSha}" "${LRef}" "${LDispatchEpoch}")"
    if [[ -n "${LRunId}" ]]; then
      break
    fi
    sleep "${LPollSeconds}"
  done
else
  echo "[NATIVE-EVIDENCE-GH] Reuse existing workflow run: ${LRunId}"
fi

if [[ -z "${LRunId}" ]]; then
  echo "[NATIVE-EVIDENCE-GH] Failed to locate workflow run id"
  exit 1
fi

echo "[NATIVE-EVIDENCE-GH] Watching run: ${LRunId}"
wait_for_run_completion "${LRunId}" "${LPollSeconds}" "${LPollMaxTries}" || exit $?

LDownloadRoot="${SIMD_NATIVE_EVIDENCE_DOWNLOAD_ROOT:-${ROOT}/logs/native-evidence-gh}"
LLocalSnapshotDir="${LDownloadRoot}/${BACKEND}/run-${LRunId}"
LTempDir="$(mktemp -d)"
cleanup() {
  rm -rf "${LTempDir}"
}
trap cleanup EXIT

echo "[NATIVE-EVIDENCE-GH] Download artifact: ${ARTIFACT_NAME}"
gh run download "${LRunId}" -n "${ARTIFACT_NAME}" -D "${LTempDir}"

copy_downloaded_artifact "${LTempDir}" "${LLocalSnapshotDir}"

LSummaryPath="$(find "${LLocalSnapshotDir}" -type f -name 'summary.md' | sort | head -n 1 || true)"
LDispatchLogPath="$(find "${LLocalSnapshotDir}" -type f -name 'dispatch_publicabi.log' | sort | head -n 1 || true)"
LSourceRevisionPath="$(find "${LLocalSnapshotDir}" -type f -name 'source_revision.txt' | sort | head -n 1 || true)"

if [[ -z "${LSummaryPath}" ]]; then
  echo "[NATIVE-EVIDENCE-GH] Missing summary.md in downloaded artifact snapshot: ${LLocalSnapshotDir}"
  exit 1
fi

cat > "${LLocalSnapshotDir}/gh_run.txt" <<EOF
backend=${BACKEND}
workflow_file=${WORKFLOW_FILE}
artifact_name=${ARTIFACT_NAME}
run_id=${LRunId}
downloaded_at_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
EOF

echo "[NATIVE-EVIDENCE-GH] Local snapshot: ${LLocalSnapshotDir}"
echo "[NATIVE-EVIDENCE-GH] Summary: ${LSummaryPath}"
if [[ -n "${LDispatchLogPath}" ]]; then
  echo "[NATIVE-EVIDENCE-GH] Dispatch/PublicAbi log: ${LDispatchLogPath}"
fi
if [[ -n "${LSourceRevisionPath}" ]]; then
  echo "[NATIVE-EVIDENCE-GH] Source revision: ${LSourceRevisionPath}"
fi
