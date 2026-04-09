#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKFLOW_FILE="${L0_NATIVE_EVIDENCE_WORKFLOW_FILE:-l0-windows-native-evidence.yml}"
ARTIFACT_NAME="${L0_NATIVE_EVIDENCE_ARTIFACT_NAME:-l0-windows-native-evidence}"
BATCH_ID="${1:-L0-$(date '+%Y%m%d')-gha}"
RUN_ID_INPUT="${2:-}"
PREFLIGHT_SCRIPT="${SCRIPT_DIR}/preflight_windows_strict_l0_native_evidence_gh.sh"
DOWNLOAD_ROOT="${L0_NATIVE_EVIDENCE_DOWNLOAD_ROOT:-${REPO_ROOT}/tests/_windows_l0_native_evidence_gh}"
SNAPSHOT_DIR="${DOWNLOAD_ROOT}/${BATCH_ID}"

print_usage() {
  cat <<EOF
Usage: $0 [batch-id] [run-id]

Default batch-id: L0-YYYYMMDD-gha
Default run-id: auto-dispatch + auto-detect latest workflow_dispatch run for current HEAD
Explicit run-id: skip workflow dispatch and reuse an existing GH Actions run for download/verify only

Environment:
  L0_NATIVE_EVIDENCE_REF               Git ref used for workflow dispatch (default: current branch)
  L0_NATIVE_EVIDENCE_WORKFLOW_FILE     Override workflow file (default: l0-windows-native-evidence.yml)
  L0_NATIVE_EVIDENCE_ARTIFACT_NAME     Override artifact name (default: l0-windows-native-evidence)
  L0_NATIVE_EVIDENCE_DOWNLOAD_ROOT     Local snapshot root (default: tests/_windows_l0_native_evidence_gh)
  L0_NATIVE_EVIDENCE_EXPECT_COMMIT     Expected git_commit in downloaded source_revision.txt
  L0_NATIVE_EVIDENCE_EXPECT_REF        Expected git_ref_hint in downloaded source_revision.txt
  L0_NATIVE_EVIDENCE_POLL_SECONDS      Poll interval in seconds (default: 5)
  L0_NATIVE_EVIDENCE_POLL_MAX_TRIES    Poll retries (default: 60)
  L0_NATIVE_EVIDENCE_PREFLIGHT         1=enable preflight before dispatch (default: 1)

Exit codes:
  0   success
  1   workflow failed / artifact contract mismatch
  2   invalid usage / missing workflow / auth or local ref hygiene guard
  31  billing or quota runner block
EOF
}

if [[ "${BATCH_ID}" == "-h" || "${BATCH_ID}" == "--help" ]]; then
  print_usage
  exit 0
fi

require_cmd() {
  local aCmd="${1:-}"
  if ! command -v "${aCmd}" >/dev/null 2>&1; then
    echo "[L0-NATIVE-EVIDENCE-GH] Missing command: ${aCmd}"
    exit 2
  fi
}

is_workflow_missing_output() {
  local aText="${1:-}"
  local LNormalized

  LNormalized="$(printf '%s' "${aText}" | tr '[:upper:]' '[:lower:]')"
  [[ "${LNormalized}" == *"could not resolve to a workflow"* ]] || [[ "${LNormalized}" == *"404"* ]]
}

is_billing_block_output() {
  local aText="${1:-}"
  local LNormalized

  LNormalized="$(printf '%s' "${aText}" | tr '[:upper:]' '[:lower:]')"
  if [[ "${LNormalized}" == *"recent account payments have failed"* ]] ||
     [[ "${LNormalized}" == *"spending limit needs to be increased"* ]] ||
     [[ "${LNormalized}" == *"billing & plans"* ]]; then
    return 0
  fi
  return 1
}

run_workflow_dispatch() {
  local aWorkflowFile="${1:-}"
  local aRef="${2:-}"
  local LOutput
  local LRC

  set +e
  LOutput="$(gh workflow run "${aWorkflowFile}" --ref "${aRef}" 2>&1)"
  LRC=$?
  set -e

  if [[ "${LRC}" == "0" ]]; then
    [[ -n "${LOutput}" ]] && printf '%s\n' "${LOutput}"
    return 0
  fi

  echo "[L0-NATIVE-EVIDENCE-GH] Workflow dispatch failed: ${aWorkflowFile}"
  [[ -n "${LOutput}" ]] && echo "${LOutput}"

  if is_workflow_missing_output "${LOutput}"; then
    echo "[L0-NATIVE-EVIDENCE-GH] Workflow is not registered on GitHub Actions."
    echo "[L0-NATIVE-EVIDENCE-GH] GitHub only exposes workflow_dispatch for workflows present on the repository default branch."
    return 2
  fi

  if is_billing_block_output "${LOutput}"; then
    echo "[L0-NATIVE-EVIDENCE-GH] Billing/runner block detected (exit=31)"
    return 31
  fi

  return "${LRC}"
}

wait_for_run_completion() {
  local aRunId="${1:-}"
  local aPollSeconds="${2:-5}"
  local aPollMaxTries="${3:-60}"
  local LJson
  local LStatus
  local LConclusion
  local LRunViewText

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
print(f"{obj.get('status','') or ''} {obj.get('conclusion','') or ''}")
PY
)
      if [[ "${LStatus}" == "completed" ]]; then
        if [[ "${LConclusion}" == "success" ]]; then
          return 0
        fi
        echo "[L0-NATIVE-EVIDENCE-GH] Workflow failed: run=${aRunId}, conclusion=${LConclusion}"
        LRunViewText="$(gh run view "${aRunId}" 2>&1 || true)"
        [[ -n "${LRunViewText}" ]] && echo "${LRunViewText}"
        if is_billing_block_output "${LRunViewText}"; then
          echo "[L0-NATIVE-EVIDENCE-GH] Billing/runner block detected (exit=31)"
          return 31
        fi
        return 1
      fi
    fi
    sleep "${aPollSeconds}"
  done

  echo "[L0-NATIVE-EVIDENCE-GH] Timeout waiting for workflow run completion: ${aRunId}"
  return 1
}

find_latest_run_id_for_dispatch() {
  local aWorkflowFile="${1:-}"
  local aHeadSha="${2:-}"
  local aHeadBranch="${3:-}"
  local aDispatchEpoch="${4:-0}"
  local LJson

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

find_unique_downloaded_file() {
  local aSearchRoot="${1:-}"
  local aName="${2:-}"
  local aLabel="${3:-${aName}}"
  local -a LCandidates

  mapfile -t LCandidates < <(find "${aSearchRoot}" -type f -name "${aName}" | sort)
  if [[ "${#LCandidates[@]}" == "0" ]]; then
    return 10
  fi

  if [[ "${#LCandidates[@]}" != "1" ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Refuse artifact: multiple ${aLabel} files found in snapshot:" >&2
    printf '  - %s\n' "${LCandidates[@]}" >&2
    return 11
  fi

  printf '%s\n' "${LCandidates[0]}"
}

copy_downloaded_artifact() {
  local aSourceDir="${1:-}"
  local aTargetDir="${2:-}"

  rm -rf "${aTargetDir}"
  mkdir -p "${aTargetDir}"
  cp -a "${aSourceDir}/." "${aTargetDir}/"
}

find_unique_downloaded_dir() {
  local aSearchRoot="${1:-}"
  local aName="${2:-}"
  local aLabel="${3:-${aName}}"
  local -a LCandidates

  mapfile -t LCandidates < <(find "${aSearchRoot}" -type d -name "${aName}" | sort)
  if [[ "${#LCandidates[@]}" == "0" ]]; then
    return 10
  fi

  if [[ "${#LCandidates[@]}" != "1" ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Refuse artifact: multiple ${aLabel} directories found in snapshot:" >&2
    printf '  - %s\n' "${LCandidates[@]}" >&2
    return 11
  fi

  printf '%s\n' "${LCandidates[0]}"
}

require_literal_in_file() {
  local aFile="${1:-}"
  local aPattern="${2:-}"
  local aLabel="${3:-pattern}"

  if ! grep -F -- "${aPattern}" "${aFile}" >/dev/null 2>&1; then
    echo "[L0-NATIVE-EVIDENCE-GH] Missing ${aLabel} in ${aFile}: ${aPattern}" >&2
    return 1
  fi

  return 0
}

extract_kv_value() {
  local aFile="${1:-}"
  local aKey="${2:-}"

  awk -F= -v key="${aKey}" '
    $1 == key {
      sub($1 "=","")
      print
      exit
    }
  ' "${aFile}"
}

require_kv_value() {
  local aFile="${1:-}"
  local aKey="${2:-}"
  local aLabel="${3:-${aKey}}"
  local LValue

  LValue="$(extract_kv_value "${aFile}" "${aKey}")"
  if [[ -z "${LValue}" ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Missing ${aLabel} in ${aFile}: ${aKey}=" >&2
    return 1
  fi

  printf '%s\n' "${LValue}"
}

extract_prefixed_value() {
  local aFile="${1:-}"
  local aPrefix="${2:-}"

  awk -v prefix="${aPrefix}" '
    index($0, prefix) == 1 {
      print substr($0, length(prefix) + 1)
      exit
    }
  ' "${aFile}"
}

normalize_ref_hint() {
  local aValue="${1:-}"

  aValue="${aValue#refs/heads/}"
  aValue="${aValue#origin/}"
  printf '%s\n' "${aValue}"
}

verify_downloaded_evidence_snapshot() {
  local aSnapshotRoot="${1:-}"
  local aExpectedCommit="${2:-}"
  local aExpectedRef="${3:-}"
  local LEvidenceLog
  local LSummaryPath
  local LSourceRevisionPath
  local LEnvironmentPath
  local LMatrixLog
  local LWhereLazbuildPath
  local LModuleLogDir
  local LEvidenceDir
  local LWorkingDir
  local LGitCommit
  local LGitRefHint
  local LHostOs
  local LToolWrapper
  local LWhereLazbuildValue
  local LExpectedCommitLower
  local LGitCommitLower
  local LExpectedRefNormalized
  local LGitRefNormalized
  local LModuleName

  set +e
  LEvidenceLog="$(find_unique_downloaded_file "${aSnapshotRoot}" 'evidence.log' 'evidence log')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-GH] Missing evidence.log in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac

  LSummaryPath="$(find_unique_downloaded_file "${aSnapshotRoot}" 'summary.md' 'summary')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-GH] Missing summary.md in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac

  LSourceRevisionPath="$(find_unique_downloaded_file "${aSnapshotRoot}" 'source_revision.txt' 'source revision')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-GH] Missing source_revision.txt in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac

  LEnvironmentPath="$(find_unique_downloaded_file "${aSnapshotRoot}" 'environment.txt' 'environment')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-GH] Missing environment.txt in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac

  LMatrixLog="$(find_unique_downloaded_file "${aSnapshotRoot}" 'native_matrix.log' 'native matrix log')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-GH] Missing native_matrix.log in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac

  LWhereLazbuildPath="$(find_unique_downloaded_file "${aSnapshotRoot}" 'where_lazbuild_exe.txt' 'where lazbuild evidence')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-GH] Missing where_lazbuild_exe.txt in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac

  LModuleLogDir="$(find_unique_downloaded_dir "${aSnapshotRoot}" 'module-logs' 'module log')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-GH] Missing module-logs directory in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac
  set -e

  LEvidenceDir="$(dirname "${LEvidenceLog}")"

  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] strict L0 Windows native evidence capture' 'collector source marker'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] Source: collect_windows_strict_l0_native_evidence.bat' 'collector batch source'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] HostOS: Windows_NT' 'Windows host marker'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] MatrixCommand: tests\test_windows_strict_l0_batch_native_matrix.bat' 'matrix command marker'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] Total: 12' 'module total marker'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] Passed: 12' 'module pass marker'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] Failed: 0' 'module fail marker'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] MATRIX_EXIT_CODE=0' 'matrix rc marker'

  LWorkingDir="$(extract_prefixed_value "${LEvidenceLog}" '[L0-NATIVE] Working dir: ')"
  if [[ -z "${LWorkingDir}" ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Missing Windows working dir marker in ${LEvidenceLog}" >&2
    return 1
  fi
  if [[ ! "${LWorkingDir}" == [A-Za-z]:\\* ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Invalid Windows working dir in ${LEvidenceLog}: ${LWorkingDir}" >&2
    return 1
  fi

  require_literal_in_file "${LSummaryPath}" '- Result: PASS' 'summary PASS marker'
  require_literal_in_file "${LMatrixLog}" '[PASS] strict L0 Windows native batch matrix verified' 'matrix PASS marker'

  LGitCommit="$(require_kv_value "${LSourceRevisionPath}" 'git_commit' 'source revision commit')"
  LGitRefHint="$(require_kv_value "${LSourceRevisionPath}" 'git_ref_hint' 'source revision ref hint')"
  LHostOs="$(require_kv_value "${LEnvironmentPath}" 'host_os' 'environment host_os')"
  LToolWrapper="$(require_kv_value "${LEnvironmentPath}" 'tool_lazbuild_wrapper' 'environment lazbuild wrapper')"
  LWhereLazbuildValue="$(require_kv_value "${LEnvironmentPath}" 'where_lazbuild_exe' 'environment where lazbuild path')"

  if [[ "${LHostOs}" != "Windows_NT" ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Invalid host_os in ${LEnvironmentPath}: ${LHostOs}" >&2
    return 1
  fi
  if [[ ! "${LToolWrapper}" == [A-Za-z]:\\* ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Invalid tool_lazbuild_wrapper path in ${LEnvironmentPath}: ${LToolWrapper}" >&2
    return 1
  fi
  if [[ ! "${LWhereLazbuildValue}" == [A-Za-z]:\\* ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Invalid where_lazbuild_exe path in ${LEnvironmentPath}: ${LWhereLazbuildValue}" >&2
    return 1
  fi
  if [[ ! -s "${LWhereLazbuildPath}" ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Empty where_lazbuild_exe.txt evidence: ${LWhereLazbuildPath}" >&2
    return 1
  fi

  if [[ -n "${aExpectedCommit}" ]]; then
    LExpectedCommitLower="$(printf '%s' "${aExpectedCommit}" | tr '[:upper:]' '[:lower:]')"
    LGitCommitLower="$(printf '%s' "${LGitCommit}" | tr '[:upper:]' '[:lower:]')"
    if [[ "${LGitCommitLower}" != "${LExpectedCommitLower}" ]]; then
      echo "[L0-NATIVE-EVIDENCE-GH] Downloaded artifact commit mismatch: expected=${aExpectedCommit} actual=${LGitCommit}" >&2
      return 1
    fi
  fi

  if [[ -n "${aExpectedRef}" ]]; then
    LExpectedRefNormalized="$(normalize_ref_hint "${aExpectedRef}")"
    LGitRefNormalized="$(normalize_ref_hint "${LGitRefHint}")"
    if [[ "${LGitRefNormalized}" != "${LExpectedRefNormalized}" ]]; then
      echo "[L0-NATIVE-EVIDENCE-GH] Downloaded artifact ref mismatch: expected=${aExpectedRef} actual=${LGitRefHint}" >&2
      return 1
    fi
  fi

  for LModuleName in \
    base.log \
    contracts.log \
    bits.log \
    layout.log \
    endian.log \
    span.log \
    option.log \
    result.log \
    platform.log \
    atomic.log \
    mem_allocator_foundation.log \
    mem_allocator_only.log; do
    if [[ ! -f "${LModuleLogDir}/${LModuleName}" ]]; then
      echo "[L0-NATIVE-EVIDENCE-GH] Missing module log in snapshot: ${LModuleLogDir}/${LModuleName}" >&2
      return 1
    fi
    require_literal_in_file "${LModuleLogDir}/${LModuleName}" '[BUILD] OK' "module build marker (${LModuleName})"
    require_literal_in_file "${LModuleLogDir}/${LModuleName}" '[TEST] OK' "module test marker (${LModuleName})"
    require_literal_in_file "${LModuleLogDir}/${LModuleName}" '[LEAK] OK' "module leak marker (${LModuleName})"
  done

  echo "[L0-NATIVE-EVIDENCE-GH] Downloaded artifact contract verified on Linux shell"
  echo "[L0-NATIVE-EVIDENCE-GH] Snapshot root: ${aSnapshotRoot}"
  echo "[L0-NATIVE-EVIDENCE-GH] Evidence dir: ${LEvidenceDir}"
  echo "[L0-NATIVE-EVIDENCE-GH] Summary: ${LSummaryPath}"
  echo "[L0-NATIVE-EVIDENCE-GH] Source revision: ${LSourceRevisionPath}"
  echo "[L0-NATIVE-EVIDENCE-GH] Environment: ${LEnvironmentPath}"
  echo "[L0-NATIVE-EVIDENCE-GH] where lazbuild evidence: ${LWhereLazbuildPath}"
  echo "[L0-NATIVE-EVIDENCE-GH] Canonical native PASS still comes from the Windows-host collector + verifier inside the workflow."
}

require_cmd gh
require_cmd python3

if ! gh auth status >/dev/null 2>&1; then
  echo "[L0-NATIVE-EVIDENCE-GH] gh auth required"
  exit 2
fi

LPollSeconds="${L0_NATIVE_EVIDENCE_POLL_SECONDS:-5}"
LPollMaxTries="${L0_NATIVE_EVIDENCE_POLL_MAX_TRIES:-60}"
LRunId="${RUN_ID_INPUT}"
LExpectedCommit="${L0_NATIVE_EVIDENCE_EXPECT_COMMIT:-}"
LExpectedRef="${L0_NATIVE_EVIDENCE_EXPECT_REF:-}"

if [[ -z "${LRunId}" ]]; then
  require_cmd git
  LRef="${L0_NATIVE_EVIDENCE_REF:-$(git -C "${REPO_ROOT}" branch --show-current || true)}"
  if [[ -z "${LRef}" ]]; then
    LRef="$(git -C "${REPO_ROOT}" rev-parse HEAD)"
  fi
  LHeadShaLocal="$(git -C "${REPO_ROOT}" rev-parse "${LRef}" 2>/dev/null || true)"
  LHeadShaRemote="$(git -C "${REPO_ROOT}" ls-remote --heads origin "${LRef}" 2>/dev/null | awk '{print $1}' | head -n 1 || true)"
  LHeadSha="${LHeadShaRemote:-${LHeadShaLocal}}"
  if [[ -z "${LExpectedCommit}" ]]; then
    LExpectedCommit="${LHeadSha}"
  fi
  if [[ -z "${LExpectedRef}" ]]; then
    LExpectedRef="${LRef}"
  fi

  if [[ -n "$(git -C "${REPO_ROOT}" status --short --untracked-files=no)" ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Refuse dispatch: local worktree has uncommitted changes."
    echo "[L0-NATIVE-EVIDENCE-GH] Commit/push or stash local L0 changes before using GH Windows evidence."
    exit 2
  fi

  if [[ -n "${LHeadShaRemote}" && -n "${LHeadShaLocal}" && "${LHeadShaRemote}" != "${LHeadShaLocal}" ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Refuse dispatch: remote ref does not match local HEAD."
    echo "[L0-NATIVE-EVIDENCE-GH] ref=${LRef} local=${LHeadShaLocal} remote=${LHeadShaRemote}"
    echo "[L0-NATIVE-EVIDENCE-GH] Push the local closeout fixes first, then rerun the helper."
    exit 2
  fi

  if [[ "${L0_NATIVE_EVIDENCE_PREFLIGHT:-1}" != "0" ]]; then
    if [[ ! -f "${PREFLIGHT_SCRIPT}" ]]; then
      echo "[L0-NATIVE-EVIDENCE-GH] Missing preflight script: ${PREFLIGHT_SCRIPT}"
      exit 2
    fi
    echo "[L0-NATIVE-EVIDENCE-GH] Preflight before dispatch"
    bash "${PREFLIGHT_SCRIPT}" "${WORKFLOW_FILE}"
  fi

  echo "[L0-NATIVE-EVIDENCE-GH] Dispatch workflow: ${WORKFLOW_FILE} (ref=${LRef}, head=${LHeadSha})"
  LDispatchEpoch="$(date +%s)"
  run_workflow_dispatch "${WORKFLOW_FILE}" "${LRef}" || {
    LDispatchRc=$?
    exit "${LDispatchRc}"
  }

  for ((LTry = 1; LTry <= LPollMaxTries; LTry++)); do
    LRunId="$(find_latest_run_id_for_dispatch "${WORKFLOW_FILE}" "${LHeadSha}" "${LRef}" "${LDispatchEpoch}")"
    if [[ -n "${LRunId}" ]]; then
      break
    fi
    sleep "${LPollSeconds}"
  done
else
  echo "[L0-NATIVE-EVIDENCE-GH] Reuse existing workflow run: ${LRunId}"
fi

if [[ -z "${LRunId}" ]]; then
  echo "[L0-NATIVE-EVIDENCE-GH] Failed to locate workflow run id"
  exit 1
fi

echo "[L0-NATIVE-EVIDENCE-GH] Watching run: ${LRunId}"
wait_for_run_completion "${LRunId}" "${LPollSeconds}" "${LPollMaxTries}" || {
  LWaitRc=$?
  exit "${LWaitRc}"
}

LTempDir="$(mktemp -d)"
cleanup() {
  rm -rf "${LTempDir}"
}
trap cleanup EXIT

echo "[L0-NATIVE-EVIDENCE-GH] Download artifact: ${ARTIFACT_NAME}"
gh run download "${LRunId}" -n "${ARTIFACT_NAME}" -D "${LTempDir}"

copy_downloaded_artifact "${LTempDir}" "${SNAPSHOT_DIR}"
verify_downloaded_evidence_snapshot "${SNAPSHOT_DIR}" "${LExpectedCommit}" "${LExpectedRef}"
