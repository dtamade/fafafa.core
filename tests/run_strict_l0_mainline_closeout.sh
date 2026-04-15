#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${L0_MAINLINE_CLOSEOUT_REPO_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
SHARED_GH_RUN_HELPER="${L0_MAINLINE_CLOSEOUT_SHARED_GH_RUN_HELPER:-${SCRIPT_DIR}/lib_github_actions_workflow_runs.sh}"
LINUX_WORKFLOW_FILE="${L0_MAINLINE_CLOSEOUT_LINUX_WORKFLOW_FILE:-l0-linux-maintenance.yml}"
MAIN_REF="${L0_MAINLINE_CLOSEOUT_MAIN_REF:-main}"
BATCH_ID="${L0_MAINLINE_CLOSEOUT_BATCH_ID:-L0-$(date '+%Y%m%d')-mainline-closeout}"
WINDOWS_LOCAL_BATCH_ID="${L0_MAINLINE_CLOSEOUT_WINDOWS_LOCAL_BATCH_ID:-${BATCH_ID}-windows}"
WINDOWS_HELPER_SCRIPT="${L0_MAINLINE_CLOSEOUT_WINDOWS_HELPER_SCRIPT:-${SCRIPT_DIR}/run_windows_strict_l0_native_evidence_via_github_actions.sh}"
DOCS_UPDATER_SCRIPT="${L0_MAINLINE_CLOSEOUT_DOCS_UPDATER_SCRIPT:-${SCRIPT_DIR}/update_strict_l0_current_state_docs.sh}"

APPLY_DOCS=0
PRINT_COMMANDS=0
SKIP_LINUX=0
SKIP_WINDOWS=0
LINUX_RUN_ID="${L0_MAINLINE_CLOSEOUT_LINUX_RUN_ID:-}"
WINDOWS_RUN_ID="${L0_MAINLINE_CLOSEOUT_WINDOWS_RUN_ID:-}"
MAIN_SHA_OVERRIDE="${L0_MAINLINE_CLOSEOUT_MAIN_SHA:-}"
WINDOWS_SHA_OVERRIDE="${L0_MAINLINE_CLOSEOUT_WINDOWS_SHA:-}"

print_usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --print-commands          Print the mainline closeout command chain and exit
  --apply-docs              Apply current-state docs backfill after evidence collection
  --skip-linux              Skip Linux maintenance workflow dispatch/reuse
  --skip-windows            Skip Windows native evidence dispatch/reuse
  --linux-run-id <id>       Reuse an existing Linux maintenance run
  --windows-run-id <id>     Reuse an existing Windows native evidence run
  --main-sha <sha>          Override the current local main SHA recorded in docs
  --windows-sha <sha>       Override the exact Windows evidence SHA recorded in docs

Environment:
  L0_MAINLINE_CLOSEOUT_REPO_ROOT             Override repo/doc root used by docs apply
  L0_MAINLINE_CLOSEOUT_SHARED_GH_RUN_HELPER  Override shared GH workflow helper path
  L0_MAINLINE_CLOSEOUT_WINDOWS_HELPER_SCRIPT Override Windows native evidence helper path
  L0_MAINLINE_CLOSEOUT_DOCS_UPDATER_SCRIPT   Override current-state docs updater path
  L0_MAINLINE_CLOSEOUT_MAIN_REF              Target ref (default: main)
  L0_MAINLINE_CLOSEOUT_BATCH_ID              Closeout batch id prefix
  L0_MAINLINE_CLOSEOUT_WINDOWS_LOCAL_BATCH_ID Local snapshot batch id for Windows helper
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    --print-commands)
      PRINT_COMMANDS=1
      shift
      ;;
    --apply-docs)
      APPLY_DOCS=1
      shift
      ;;
    --skip-linux)
      SKIP_LINUX=1
      shift
      ;;
    --skip-windows)
      SKIP_WINDOWS=1
      shift
      ;;
    --linux-run-id)
      LINUX_RUN_ID="$2"
      shift 2
      ;;
    --windows-run-id)
      WINDOWS_RUN_ID="$2"
      shift 2
      ;;
    --main-sha)
      MAIN_SHA_OVERRIDE="$2"
      shift 2
      ;;
    --windows-sha)
      WINDOWS_SHA_OVERRIDE="$2"
      shift 2
      ;;
    *)
      echo "[L0-MAINLINE-CLOSEOUT] Unknown option: $1" >&2
      exit 2
      ;;
  esac
done

print_commands() {
  printf '%s\n' "gh workflow run ${LINUX_WORKFLOW_FILE} --ref ${MAIN_REF}"
  printf '%s\n' "L0_NATIVE_EVIDENCE_REF=${MAIN_REF} bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh ${WINDOWS_LOCAL_BATCH_ID}"
  printf '%s\n' "bash tests/update_strict_l0_current_state_docs.sh --apply --main-sha <main-sha> --origin-main-sha <origin-main-sha> --worktree-sha <worktree-sha> --linux-run-id <linux-run-id> --linux-run-sha <linux-run-sha> --windows-run-id <windows-run-id> --windows-run-sha <windows-run-sha> --windows-local-batch-id ${WINDOWS_LOCAL_BATCH_ID}"
}

if [[ "${PRINT_COMMANDS}" == "1" ]]; then
  print_commands
  exit 0
fi

if [[ ! -f "${SHARED_GH_RUN_HELPER}" ]]; then
  echo "[L0-MAINLINE-CLOSEOUT] Missing shared GH workflow helper: ${SHARED_GH_RUN_HELPER}" >&2
  exit 2
fi

# Shared helper centralizes GH workflow run lookup/wait/headSha parsing.
source "${SHARED_GH_RUN_HELPER}"

require_cmd() {
  local aCmd="${1:-}"
  if ! command -v "${aCmd}" >/dev/null 2>&1; then
    echo "[L0-MAINLINE-CLOSEOUT] Missing command: ${aCmd}" >&2
    exit 2
  fi
}

require_cmd gh
require_cmd git
require_cmd python3

ORIGIN_MAIN_SHA="$(git -C "${REPO_ROOT}" ls-remote --heads origin "${MAIN_REF}" 2>/dev/null | awk '{print $1}' | head -n 1 || true)"
if [[ -z "${ORIGIN_MAIN_SHA}" ]]; then
  echo "[L0-MAINLINE-CLOSEOUT] Failed to resolve remote SHA for ref=${MAIN_REF}" >&2
  exit 2
fi

LOCAL_MAIN_SHA="${MAIN_SHA_OVERRIDE:-$(git -C "${REPO_ROOT}" rev-parse --verify "refs/heads/${MAIN_REF}^{commit}" 2>/dev/null | head -n 1 || true)}"
LOCAL_MAIN_SHA="${LOCAL_MAIN_SHA:-${ORIGIN_MAIN_SHA}}"

WORKTREE_SHA="$(git -C "${REPO_ROOT}" rev-parse HEAD 2>/dev/null | head -n 1 || true)"
WORKTREE_SHA="${WORKTREE_SHA:-${LOCAL_MAIN_SHA}}"

LPollSeconds="${L0_MAINLINE_CLOSEOUT_POLL_SECONDS:-5}"
LPollMaxTries="${L0_MAINLINE_CLOSEOUT_POLL_MAX_TRIES:-120}"

if [[ "${SKIP_LINUX}" != "1" ]]; then
  if [[ -z "${LINUX_RUN_ID}" ]]; then
    echo "[L0-MAINLINE-CLOSEOUT] Dispatch Linux maintenance workflow: ${LINUX_WORKFLOW_FILE} (ref=${MAIN_REF}, head=${ORIGIN_MAIN_SHA})"
    LDispatchEpoch="$(date +%s)"
    gh workflow run "${LINUX_WORKFLOW_FILE}" --ref "${MAIN_REF}"
    for ((LTry = 1; LTry <= LPollMaxTries; LTry++)); do
      LINUX_RUN_ID="$(gh_runlib_find_latest_dispatch_run_id "${LINUX_WORKFLOW_FILE}" "${ORIGIN_MAIN_SHA}" "${MAIN_REF}" "${LDispatchEpoch}" strict)"
      if [[ -n "${LINUX_RUN_ID}" ]]; then
        break
      fi
      sleep "${LPollSeconds}"
    done
    if [[ -z "${LINUX_RUN_ID}" ]]; then
      echo "[L0-MAINLINE-CLOSEOUT] Failed to locate Linux maintenance run id" >&2
      exit 1
    fi
  fi

  echo "[L0-MAINLINE-CLOSEOUT] Watching Linux maintenance run: ${LINUX_RUN_ID}"
  if ! gh_runlib_wait_for_run_completion "${LINUX_RUN_ID}" "${LPollSeconds}" "${LPollMaxTries}"; then
    LWaitRc=$?
    if [[ "${LWaitRc}" == "10" ]]; then
      echo "[L0-MAINLINE-CLOSEOUT] Workflow failed: run=${LINUX_RUN_ID}, conclusion=${GH_RUNLIB_LAST_CONCLUSION:-unknown}" >&2
    else
      echo "[L0-MAINLINE-CLOSEOUT] Timeout waiting for run completion: ${LINUX_RUN_ID}" >&2
    fi
    exit 1
  fi
fi

LINUX_RUN_SHA=""
if [[ -n "${LINUX_RUN_ID}" ]]; then
  LINUX_RUN_SHA="$(gh_runlib_get_run_head_sha "${LINUX_RUN_ID}")"
fi
LINUX_RUN_SHA="${LINUX_RUN_SHA:-${ORIGIN_MAIN_SHA}}"

if [[ "${SKIP_WINDOWS}" != "1" ]]; then
  LWindowsHelperLog="$(mktemp)"
  trap 'rm -f "${LWindowsHelperLog}"' EXIT

  if [[ -z "${WINDOWS_RUN_ID}" ]]; then
    set +e
    L0_NATIVE_EVIDENCE_REF="${MAIN_REF}" \
    L0_NATIVE_EVIDENCE_EXPECT_COMMIT="${WINDOWS_SHA_OVERRIDE:-${ORIGIN_MAIN_SHA}}" \
    L0_NATIVE_EVIDENCE_EXPECT_REF="${MAIN_REF}" \
    bash "${WINDOWS_HELPER_SCRIPT}" "${WINDOWS_LOCAL_BATCH_ID}" 2>&1 | tee "${LWindowsHelperLog}"
    LWindowsRc=${PIPESTATUS[0]}
    set -e
    if [[ "${LWindowsRc}" != "0" ]]; then
      exit "${LWindowsRc}"
    fi
    WINDOWS_RUN_ID="$(rg -o 'Watching run: [0-9]+' "${LWindowsHelperLog}" | tail -n 1 | awk '{print $3}')"
  else
    L0_NATIVE_EVIDENCE_EXPECT_COMMIT="${WINDOWS_SHA_OVERRIDE:-${ORIGIN_MAIN_SHA}}" \
    L0_NATIVE_EVIDENCE_EXPECT_REF="${MAIN_REF}" \
    bash "${WINDOWS_HELPER_SCRIPT}" "${WINDOWS_LOCAL_BATCH_ID}" "${WINDOWS_RUN_ID}"
  fi

  if [[ -z "${WINDOWS_RUN_ID}" ]]; then
    echo "[L0-MAINLINE-CLOSEOUT] Failed to capture Windows native evidence run id" >&2
    exit 1
  fi
fi

WINDOWS_RUN_SHA="${WINDOWS_SHA_OVERRIDE:-}"
if [[ -z "${WINDOWS_RUN_SHA}" && -n "${WINDOWS_RUN_ID}" ]]; then
  WINDOWS_RUN_SHA="$(gh_runlib_get_run_head_sha "${WINDOWS_RUN_ID}")"
fi
WINDOWS_RUN_SHA="${WINDOWS_RUN_SHA:-${ORIGIN_MAIN_SHA}}"

if [[ "${APPLY_DOCS}" == "1" ]]; then
  if [[ -z "${LINUX_RUN_ID}" ]]; then
    echo "[L0-MAINLINE-CLOSEOUT] Refuse docs apply without Linux run id" >&2
    exit 2
  fi
  if [[ -z "${WINDOWS_RUN_ID}" ]]; then
    echo "[L0-MAINLINE-CLOSEOUT] Refuse docs apply without Windows run id" >&2
    exit 2
  fi
  bash "${DOCS_UPDATER_SCRIPT}" \
    --apply \
    --target-root "${REPO_ROOT}" \
    --main-sha "${LOCAL_MAIN_SHA}" \
    --origin-main-sha "${ORIGIN_MAIN_SHA}" \
    --worktree-sha "${WORKTREE_SHA}" \
    --linux-run-id "${LINUX_RUN_ID}" \
    --linux-run-sha "${LINUX_RUN_SHA:-${ORIGIN_MAIN_SHA}}" \
    --windows-run-id "${WINDOWS_RUN_ID}" \
    --windows-run-sha "${WINDOWS_RUN_SHA:-${ORIGIN_MAIN_SHA}}" \
    --windows-local-batch-id "${WINDOWS_LOCAL_BATCH_ID}"
fi

echo "[PASS] strict L0 mainline closeout finished"
echo "[INFO] main_ref=${MAIN_REF}"
echo "[INFO] local_main_sha=${LOCAL_MAIN_SHA}"
echo "[INFO] origin_main_sha=${ORIGIN_MAIN_SHA}"
echo "[INFO] worktree_sha=${WORKTREE_SHA}"
[[ -n "${LINUX_RUN_ID}" ]] && echo "[INFO] linux_run_id=${LINUX_RUN_ID}"
[[ -n "${WINDOWS_RUN_ID}" ]] && echo "[INFO] windows_run_id=${WINDOWS_RUN_ID}"
echo "[INFO] windows_local_batch_id=${WINDOWS_LOCAL_BATCH_ID}"
