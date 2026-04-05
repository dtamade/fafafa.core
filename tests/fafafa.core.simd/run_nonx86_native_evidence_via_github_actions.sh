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
  SIMD_NATIVE_EVIDENCE_EXPECT_COMMIT   Optional expected git commit for downloaded source_revision.txt
  SIMD_NATIVE_EVIDENCE_EXPECT_REF      Optional expected git ref hint for downloaded source_revision.txt
  SIMD_NATIVE_EVIDENCE_REQUIRE_SOURCE_REVISION  Force source_revision.txt to exist even on run-id reuse
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

is_workflow_missing_output() {
  local aText
  local LNormalized

  aText="${1:-}"
  if [[ -z "${aText}" ]]; then
    return 1
  fi

  LNormalized="$(printf '%s' "${aText}" | tr '[:upper:]' '[:lower:]')"
  if [[ "${LNormalized}" == *"http 404: not found"* ]] &&
     [[ "${LNormalized}" == *"/actions/workflows/"* ]]; then
    return 0
  fi

  return 1
}

run_workflow_dispatch() {
  local aWorkflowFile
  local aRef
  local LOutput
  local LRC

  aWorkflowFile="${1:-}"
  aRef="${2:-}"

  set +e
  LOutput="$(gh workflow run "${aWorkflowFile}" --ref "${aRef}" 2>&1)"
  LRC=$?
  set -e

  if [[ "${LRC}" == "0" ]]; then
    if [[ -n "${LOutput}" ]]; then
      printf '%s\n' "${LOutput}"
    fi
    return 0
  fi

  echo "[NATIVE-EVIDENCE-GH] Workflow dispatch failed: ${aWorkflowFile}"
  if [[ -n "${LOutput}" ]]; then
    echo "${LOutput}"
  fi

  if is_workflow_missing_output "${LOutput}"; then
    echo "[NATIVE-EVIDENCE-GH] Workflow is not registered on GitHub Actions."
    echo "[NATIVE-EVIDENCE-GH] GitHub only exposes workflow_dispatch for workflows present on the repository default branch."
    return 2
  fi

  if is_billing_block_output "${LOutput}"; then
    echo "[NATIVE-EVIDENCE-GH] Billing/runner block detected during workflow dispatch (exit=31)"
    return 31
  fi

  return "${LRC}"
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

find_unique_downloaded_file() {
  local aSearchRoot
  local aName
  local aLabel
  local -a LCandidates

  aSearchRoot="${1:-}"
  aName="${2:-}"
  aLabel="${3:-${aName}}"

  mapfile -t LCandidates < <(find "${aSearchRoot}" -type f -name "${aName}" | sort)
  if [[ "${#LCandidates[@]}" == "0" ]]; then
    return 10
  fi

  if [[ "${#LCandidates[@]}" != "1" ]]; then
    echo "[NATIVE-EVIDENCE-GH] Refuse artifact: multiple ${aLabel} files found in snapshot:" >&2
    printf '  - %s\n' "${LCandidates[@]}" >&2
    return 11
  fi

  printf '%s\n' "${LCandidates[0]}"
}

read_metadata_value() {
  local aFile
  local aKey

  aFile="${1:-}"
  aKey="${2:-}"
  if [[ -z "${aFile}" || -z "${aKey}" || ! -f "${aFile}" ]]; then
    return 0
  fi

  grep -F -- "${aKey}=" "${aFile}" | head -n 1 | cut -d'=' -f2- || true
}

looks_like_full_sha() {
  local aValue

  aValue="${1:-}"
  [[ "${aValue}" =~ ^[0-9a-fA-F]{40}$ ]]
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
LExpectedCommit="${SIMD_NATIVE_EVIDENCE_EXPECT_COMMIT:-}"
LExpectedRef="${SIMD_NATIVE_EVIDENCE_EXPECT_REF:-}"
LRequireSourceRevision="${SIMD_NATIVE_EVIDENCE_REQUIRE_SOURCE_REVISION:-0}"

if [[ -z "${LRunId}" ]]; then
  require_cmd git
  LRef="${SIMD_NATIVE_EVIDENCE_REF:-$(git -C "${REPO_ROOT}" branch --show-current || true)}"
  if [[ -z "${LRef}" ]]; then
    LRef="$(git -C "${REPO_ROOT}" rev-parse HEAD)"
  fi
  LHeadShaLocal="$(git -C "${REPO_ROOT}" rev-parse "${LRef}" 2>/dev/null || true)"
  LHeadShaRemote="$(git -C "${REPO_ROOT}" ls-remote --heads origin "${LRef}" 2>/dev/null | awk '{print $1}' | head -n 1 || true)"
  LHeadSha="${LHeadShaRemote:-${LHeadShaLocal}}"
  LExpectedCommit="${LHeadSha}"
  if [[ -z "${LExpectedRef}" ]]; then
    LExpectedRef="${LRef}"
  fi
  LRequireSourceRevision=1

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
  run_workflow_dispatch "${WORKFLOW_FILE}" "${LRef}"

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

set +e
LSummaryPath="$(find_unique_downloaded_file "${LLocalSnapshotDir}" 'summary.md' 'summary')"
LSummaryRc=$?
set -e
case "${LSummaryRc}" in
  0)
    ;;
  10)
    echo "[NATIVE-EVIDENCE-GH] Missing summary.md in downloaded artifact snapshot: ${LLocalSnapshotDir}"
    exit 1
    ;;
  *)
    exit 1
    ;;
esac

set +e
LDispatchLogPath="$(find_unique_downloaded_file "${LLocalSnapshotDir}" 'dispatch_publicabi.log' 'dispatch publicabi log')"
LDispatchLogRc=$?
set -e
case "${LDispatchLogRc}" in
  0)
    ;;
  10)
    LDispatchLogPath=""
    ;;
  *)
    exit 1
    ;;
esac

set +e
LSourceRevisionPath="$(find_unique_downloaded_file "${LLocalSnapshotDir}" 'source_revision.txt' 'source revision')"
LSourceRevisionRc=$?
set -e
case "${LSourceRevisionRc}" in
  0)
    ;;
  10)
    LSourceRevisionPath=""
    ;;
  *)
    exit 1
    ;;
esac

LSourceGitCommit=""
LSourceGitRefHint=""

if [[ -n "${LSourceRevisionPath}" ]]; then
  LSourceGitCommit="$(read_metadata_value "${LSourceRevisionPath}" git_commit)"
  LSourceGitRefHint="$(read_metadata_value "${LSourceRevisionPath}" git_ref_hint)"
elif [[ "${LRequireSourceRevision}" == "1" ]]; then
  echo "[NATIVE-EVIDENCE-GH] Missing source_revision.txt in downloaded artifact snapshot: ${LLocalSnapshotDir}"
  exit 1
fi

if [[ -n "${LExpectedCommit}" && -n "${LSourceGitCommit}" && "${LExpectedCommit,,}" != "${LSourceGitCommit,,}" ]]; then
  echo "[NATIVE-EVIDENCE-GH] Source revision git_commit mismatch: expected=${LExpectedCommit} actual=${LSourceGitCommit}"
  exit 1
fi

if [[ -n "${LExpectedRef}" && -n "${LSourceGitRefHint}" ]] && ! looks_like_full_sha "${LExpectedRef}" && [[ "${LExpectedRef}" != "${LSourceGitRefHint}" ]]; then
  echo "[NATIVE-EVIDENCE-GH] Source revision git_ref_hint mismatch: expected=${LExpectedRef} actual=${LSourceGitRefHint}"
  exit 1
fi

cat > "${LLocalSnapshotDir}/gh_run.txt" <<EOF
backend=${BACKEND}
workflow_file=${WORKFLOW_FILE}
artifact_name=${ARTIFACT_NAME}
run_id=${LRunId}
downloaded_at_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
source_revision_file=${LSourceRevisionPath}
source_git_commit=${LSourceGitCommit}
source_git_ref_hint=${LSourceGitRefHint}
expected_git_commit=${LExpectedCommit}
expected_git_ref=${LExpectedRef}
EOF

echo "[NATIVE-EVIDENCE-GH] Local snapshot: ${LLocalSnapshotDir}"
echo "[NATIVE-EVIDENCE-GH] Summary: ${LSummaryPath}"
if [[ -n "${LDispatchLogPath}" ]]; then
  echo "[NATIVE-EVIDENCE-GH] Dispatch/PublicAbi log: ${LDispatchLogPath}"
fi
if [[ -n "${LSourceRevisionPath}" ]]; then
  echo "[NATIVE-EVIDENCE-GH] Source revision: ${LSourceRevisionPath}"
fi
