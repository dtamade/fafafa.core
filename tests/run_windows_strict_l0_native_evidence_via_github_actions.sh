#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SHARED_GH_RUN_HELPER="${SCRIPT_DIR}/lib_github_actions_workflow_runs.sh"
WORKFLOW_FILE="${L0_NATIVE_EVIDENCE_WORKFLOW_FILE:-l0-windows-native-evidence.yml}"
ARTIFACT_NAME="${L0_NATIVE_EVIDENCE_ARTIFACT_NAME:-l0-windows-native-evidence}"
BATCH_ID="${1:-L0-$(date '+%Y%m%d')-gha}"
RUN_ID_INPUT="${2:-}"
PREFLIGHT_SCRIPT="${SCRIPT_DIR}/preflight_windows_strict_l0_native_evidence_gh.sh"
VERIFY_SHELL_SCRIPT="${SCRIPT_DIR}/verify_windows_strict_l0_native_evidence.sh"
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

if [[ ! -f "${SHARED_GH_RUN_HELPER}" ]]; then
  echo "[L0-NATIVE-EVIDENCE-GH] Missing shared GH workflow helper: ${SHARED_GH_RUN_HELPER}"
  exit 2
fi

source "${SHARED_GH_RUN_HELPER}"

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

copy_downloaded_artifact() {
  local aSourceDir="${1:-}"
  local aTargetDir="${2:-}"

  rm -rf "${aTargetDir}"
  mkdir -p "${aTargetDir}"
  cp -a "${aSourceDir}/." "${aTargetDir}/"
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
  LCurrentBranch="$(git -C "${REPO_ROOT}" branch --show-current 2>/dev/null || true)"
  LCurrentHeadSha="$(git -C "${REPO_ROOT}" rev-parse HEAD 2>/dev/null || true)"
  LHeadShaLocal="$(git -C "${REPO_ROOT}" rev-parse "${LRef}" 2>/dev/null || true)"
  LHeadShaRemote="$(git -C "${REPO_ROOT}" ls-remote --heads origin "${LRef}" 2>/dev/null | awk '{print $1}' | head -n 1 || true)"
  LHeadSha="${LHeadShaRemote:-${LHeadShaLocal:-${LCurrentHeadSha}}}"
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

  if [[ -n "${LHeadShaRemote}" && -n "${LCurrentHeadSha}" && "${LHeadShaRemote}" != "${LCurrentHeadSha}" ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Refuse dispatch: target ref does not match current worktree HEAD."
    echo "[L0-NATIVE-EVIDENCE-GH] ref=${LRef} current_branch=${LCurrentBranch:-<detached>} current_head=${LCurrentHeadSha} remote=${LHeadShaRemote}"
    if [[ -n "${LHeadShaLocal}" ]]; then
      echo "[L0-NATIVE-EVIDENCE-GH] local_named_ref=${LHeadShaLocal}"
    fi
    echo "[L0-NATIVE-EVIDENCE-GH] Fast-forward/switch the current L0 worktree to the target ref, then rerun the helper."
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
    LRunId="$(gh_runlib_find_latest_dispatch_run_id "${WORKFLOW_FILE}" "${LHeadSha}" "${LRef}" "${LDispatchEpoch}" relaxed)"
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
if ! gh_runlib_wait_for_run_completion "${LRunId}" "${LPollSeconds}" "${LPollMaxTries}"; then
  LWaitRc=$?
  if [[ "${LWaitRc}" == "10" ]]; then
    echo "[L0-NATIVE-EVIDENCE-GH] Workflow failed: run=${LRunId}, conclusion=${GH_RUNLIB_LAST_CONCLUSION:-unknown}"
    LRunViewText="$(gh run view "${LRunId}" 2>&1 || true)"
    [[ -n "${LRunViewText}" ]] && echo "${LRunViewText}"
    if is_billing_block_output "${LRunViewText}"; then
      echo "[L0-NATIVE-EVIDENCE-GH] Billing/runner block detected (exit=31)"
      exit 31
    fi
    exit 1
  fi
  echo "[L0-NATIVE-EVIDENCE-GH] Timeout waiting for workflow run completion: ${LRunId}"
  exit 1
fi

LTempDir="$(mktemp -d)"
cleanup() {
  rm -rf "${LTempDir}"
}
trap cleanup EXIT

echo "[L0-NATIVE-EVIDENCE-GH] Download artifact: ${ARTIFACT_NAME}"
gh run download "${LRunId}" -n "${ARTIFACT_NAME}" -D "${LTempDir}"

copy_downloaded_artifact "${LTempDir}" "${SNAPSHOT_DIR}"
if [[ ! -f "${VERIFY_SHELL_SCRIPT}" ]]; then
  echo "[L0-NATIVE-EVIDENCE-GH] Missing shell verifier: ${VERIFY_SHELL_SCRIPT}"
  exit 1
fi
bash "${VERIFY_SHELL_SCRIPT}" "${SNAPSHOT_DIR}" "${LExpectedCommit}" "${LExpectedRef}"
