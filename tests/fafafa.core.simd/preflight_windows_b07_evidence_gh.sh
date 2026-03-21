#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
WORKFLOW_FILE="${SIMD_WIN_EVIDENCE_WORKFLOW_FILE:-simd-windows-b07-evidence.yml}"
LOOKBACK_LIMIT="${SIMD_WIN_PREFLIGHT_LOOKBACK_LIMIT:-6}"
BILLING_WINDOW_HOURS="${SIMD_WIN_PREFLIGHT_BILLING_WINDOW_HOURS:-24}"
PREFLIGHT_LOG_DIR="${SIMD_WIN_PREFLIGHT_LOG_DIR:-${ROOT}/logs}"
PREFLIGHT_JSON_FILE="${SIMD_WIN_PREFLIGHT_JSON_FILE:-${PREFLIGHT_LOG_DIR}/win_preflight_latest.json}"
PREFLIGHT_MD_FILE="${SIMD_WIN_PREFLIGHT_MD_FILE:-${PREFLIGHT_LOG_DIR}/win_preflight_latest.md}"

LRepo=""

print_usage() {
  cat <<EOF
Usage: $0 [--workflow <filename>] [--lookback <n>] [--billing-window-hours <hours>]

Default workflow: simd-windows-b07-evidence.yml

Exit codes:
  0   PASS
  20  missing command
  21  gh auth required
  22  workflow not found
  23  workflow disabled
  24  preflight api/parse error
  31  recent billing/runner block detected

Outputs:
  JSON: ${PREFLIGHT_JSON_FILE}
  MD:   ${PREFLIGHT_MD_FILE}
EOF
}

json_escape() {
  printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n' '\r' | sed -e 's/\r/\\n/g'
}

write_report() {
  local aStatus
  local aCode
  local aExitCode
  local aMessage
  local LTs
  local LRepoSafe
  local LMessageEscaped

  aStatus="$1"
  aCode="$2"
  aExitCode="$3"
  aMessage="$4"

  mkdir -p "${PREFLIGHT_LOG_DIR}"
  LTs="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  LRepoSafe="${LRepo:-}"
  LMessageEscaped="$(json_escape "${aMessage}")"

  cat > "${PREFLIGHT_JSON_FILE}" <<EOF
{
  "checked_at_utc": "${LTs}",
  "status": "${aStatus}",
  "code": "${aCode}",
  "exit_code": ${aExitCode},
  "workflow_file": "$(json_escape "${WORKFLOW_FILE}")",
  "repo": "$(json_escape "${LRepoSafe}")",
  "lookback_limit": ${LOOKBACK_LIMIT},
  "billing_window_hours": ${BILLING_WINDOW_HOURS},
  "message": "${LMessageEscaped}"
}
EOF

  cat > "${PREFLIGHT_MD_FILE}" <<EOF
# SIMD Windows Evidence Preflight (latest)

- Checked (UTC): ${LTs}
- Status: ${aStatus}
- Code: ${aCode}
- Exit: ${aExitCode}
- Workflow: ${WORKFLOW_FILE}
- Repo: ${LRepoSafe:-N/A}
- Lookback: ${LOOKBACK_LIMIT}
- Billing Window (hours): ${BILLING_WINDOW_HOURS}

## Detail

${aMessage}
EOF
}

fail_with() {
  local aExitCode
  local aCode
  local aMessage

  aExitCode="$1"
  aCode="$2"
  aMessage="$3"

  write_report "FAIL" "${aCode}" "${aExitCode}" "${aMessage}"
  echo "[PREFLIGHT] STATUS=FAIL CODE=${aCode} EXIT=${aExitCode}"
  echo "[PREFLIGHT] ${aMessage}"
  echo "[PREFLIGHT] report-json=${PREFLIGHT_JSON_FILE}"
  echo "[PREFLIGHT] report-md=${PREFLIGHT_MD_FILE}"
  exit "${aExitCode}"
}

pass_with() {
  local aCode
  local aMessage

  aCode="$1"
  aMessage="$2"

  write_report "PASS" "${aCode}" 0 "${aMessage}"
  echo "[PREFLIGHT] STATUS=PASS CODE=${aCode} EXIT=0"
  echo "[PREFLIGHT] ${aMessage}"
  echo "[PREFLIGHT] report-json=${PREFLIGHT_JSON_FILE}"
  echo "[PREFLIGHT] report-md=${PREFLIGHT_MD_FILE}"
  exit 0
}

extract_billing_block_message() {
  local aText

  aText="${1:-}"
  python3 - "${aText}" <<'PY'
import re
import sys

patterns = [
    r"billing\s*&\s*plans",
    r"spending limit needs to be increased",
    r"recent account payments have failed",
    r"job was not started",
]

text = sys.argv[1] if len(sys.argv) > 1 else ""
for line in text.splitlines():
    low = line.lower()
    if any(re.search(pattern, low) for pattern in patterns):
        print(line.strip())
        sys.exit(0)
sys.exit(1)
PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    --workflow)
      if [[ $# -lt 2 ]]; then
        fail_with 24 "INVALID_ARGS" "missing value for --workflow"
      fi
      WORKFLOW_FILE="$2"
      shift 2
      ;;
    --lookback)
      if [[ $# -lt 2 ]]; then
        fail_with 24 "INVALID_ARGS" "missing value for --lookback"
      fi
      LOOKBACK_LIMIT="$2"
      shift 2
      ;;
    --billing-window-hours)
      if [[ $# -lt 2 ]]; then
        fail_with 24 "INVALID_ARGS" "missing value for --billing-window-hours"
      fi
      BILLING_WINDOW_HOURS="$2"
      shift 2
      ;;
    *)
      fail_with 24 "INVALID_ARGS" "unsupported argument: $1"
      ;;
  esac
done

if ! [[ "${LOOKBACK_LIMIT}" =~ ^[1-9][0-9]*$ ]]; then
  fail_with 24 "INVALID_ARGS" "lookback must be positive integer: ${LOOKBACK_LIMIT}"
fi

if ! [[ "${BILLING_WINDOW_HOURS}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  fail_with 24 "INVALID_ARGS" "billing-window-hours must be numeric: ${BILLING_WINDOW_HOURS}"
fi

for LCmd in gh python3 git; do
  if ! command -v "${LCmd}" >/dev/null 2>&1; then
    fail_with 20 "MISSING_COMMAND" "missing command: ${LCmd}"
  fi
done

if ! gh auth status >/dev/null 2>&1; then
  fail_with 21 "AUTH_REQUIRED" "gh auth required"
fi

LRepo="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
if [[ -z "${LRepo}" ]]; then
  fail_with 24 "REPO_RESOLVE_FAILED" "failed to resolve repository via gh repo view"
fi

LWorkflowJson="$(gh workflow list --all --limit 200 --json id,name,path,state 2>/dev/null || true)"
if [[ -z "${LWorkflowJson}" ]]; then
  fail_with 24 "WORKFLOW_QUERY_FAILED" "failed to query workflow list"
fi

read -r LWorkflowId LWorkflowState LWorkflowPath < <(
  python3 - "${WORKFLOW_FILE}" "${LWorkflowJson}" <<'PY'
import json
import sys

target = sys.argv[1].strip().lower()
rows = json.loads(sys.argv[2])

def match(row):
    path = str(row.get("path", "")).strip()
    name = str(row.get("name", "")).strip()
    path_lower = path.lower()
    name_lower = name.lower()
    if path_lower.endswith("/" + target):
        return True
    if path_lower == target:
        return True
    if name_lower == target:
        return True
    return False

for row in rows:
    if match(row):
        print(f"{row.get('id','')} {row.get('state','')} {row.get('path','')}")
        sys.exit(0)

print("  ")
PY
)

if [[ -z "${LWorkflowId}" ]]; then
  fail_with 22 "WORKFLOW_NOT_FOUND" "workflow not found: ${WORKFLOW_FILE}"
fi

if [[ "${LWorkflowState}" != "active" ]]; then
  fail_with 23 "WORKFLOW_DISABLED" "workflow state is not active: ${LWorkflowState} (${LWorkflowPath})"
fi

LRunsJson="$(gh run list --workflow "${WORKFLOW_FILE}" --limit "${LOOKBACK_LIMIT}" --json databaseId,status,conclusion,createdAt,url,event 2>/dev/null || true)"
if [[ -z "${LRunsJson}" || "${LRunsJson}" == "[]" ]]; then
  pass_with "OK" "workflow=${WORKFLOW_FILE}, repo=${LRepo}, note=no run history"
fi

mapfile -t LCandidateRuns < <(
  python3 - "${BILLING_WINDOW_HOURS}" "${LRunsJson}" <<'PY'
import json
import sys
from datetime import datetime, timezone

window_hours = float(sys.argv[1])
rows = json.loads(sys.argv[2])
now = datetime.now(timezone.utc)

for row in rows:
    run_id = row.get("databaseId")
    created = row.get("createdAt") or ""
    status = (row.get("status") or "").lower()
    conclusion = (row.get("conclusion") or "").lower()
    url = row.get("url") or ""
    if not run_id or not created:
        continue
    created_dt = datetime.fromisoformat(created.replace("Z", "+00:00"))
    age_hours = (now - created_dt).total_seconds() / 3600.0
    if age_hours > window_hours:
        continue
    if status != "completed" or conclusion != "failure":
        continue
    print(f"{run_id}\t{age_hours:.2f}\t{url}")
PY
)

if [[ "${#LCandidateRuns[@]}" -eq 0 ]]; then
  pass_with "OK" "workflow=${WORKFLOW_FILE}, repo=${LRepo}, note=no failed run in ${BILLING_WINDOW_HOURS}h window"
fi

for LRunRow in "${LCandidateRuns[@]}"; do
  IFS=$'\t' read -r LRunId LAgeHours LRunUrl <<<"${LRunRow}"
  LRunViewText="$(gh run view "${LRunId}" 2>/dev/null || true)"
  LBillingMsg="$(extract_billing_block_message "${LRunViewText}" || true)"
  if [[ -n "${LBillingMsg}" ]]; then
    fail_with 31 "RECENT_BILLING_BLOCK" "workflow=${WORKFLOW_FILE}; run=${LRunId}; age_hours=${LAgeHours}; url=${LRunUrl}; message=${LBillingMsg}"
  fi

  LJobsJson="$(gh api "repos/${LRepo}/actions/runs/${LRunId}/jobs" 2>/dev/null || true)"
  if [[ -z "${LJobsJson}" ]]; then
    continue
  fi

  mapfile -t LWinCheckRuns < <(
    python3 - "${LJobsJson}" <<'PY'
import json
import sys

obj = json.loads(sys.argv[1])
for job in obj.get("jobs", []):
    labels = [str(v).lower() for v in job.get("labels", [])]
    if any("windows" in item for item in labels):
        print(f"{job.get('id', '')}\t{job.get('check_run_url', '')}")
PY
  )

  for LCheckRunRow in "${LWinCheckRuns[@]}"; do
    LCheckRunAnnotationsEndpoint=""
    IFS=$'\t' read -r LJobId LCheckRunUrl <<<"${LCheckRunRow}"
    if [[ -z "${LJobId}" ]]; then
      continue
    fi

    if [[ -n "${LCheckRunUrl}" ]]; then
      LCheckRunAnnotationsEndpoint="${LCheckRunUrl#https://api.github.com/}"
      LCheckRunAnnotationsEndpoint="${LCheckRunAnnotationsEndpoint}/annotations"
      LAnnoJson="$(gh api "${LCheckRunAnnotationsEndpoint}" 2>/dev/null || true)"
    else
      LAnnoJson="$(gh api "repos/${LRepo}/check-runs/${LJobId}/annotations" 2>/dev/null || true)"
    fi
    if [[ -z "${LAnnoJson}" ]]; then
      continue
    fi

    LBillingMsg="$(
      python3 - "${LAnnoJson}" <<'PY'
import json
import sys

rows = json.loads(sys.argv[1])
messages = []
for row in rows:
    msg = str(row.get("message", "")).strip()
    if msg:
        messages.append(msg)
print("\n".join(messages))
PY
    )"
    LBillingMsg="$(extract_billing_block_message "${LBillingMsg}" || true)"

    if [[ -n "${LBillingMsg}" ]]; then
      fail_with 31 "RECENT_BILLING_BLOCK" "workflow=${WORKFLOW_FILE}; run=${LRunId}; age_hours=${LAgeHours}; job=${LJobId}; url=${LRunUrl}; message=${LBillingMsg}"
    fi
  done
done

pass_with "OK" "workflow=${WORKFLOW_FILE}, repo=${LRepo}, scanned_failed_runs=${#LCandidateRuns[@]}"
