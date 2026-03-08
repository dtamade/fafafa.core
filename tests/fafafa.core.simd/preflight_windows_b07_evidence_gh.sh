#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
LOG_DIR="${ROOT}/logs"
WORKFLOW_FILE="${SIMD_WIN_EVIDENCE_WORKFLOW_FILE:-simd-windows-b07-evidence.yml}"
LOOKBACK_LIMIT="${SIMD_WIN_EVIDENCE_PREFLIGHT_LOOKBACK:-6}"
BILLING_WINDOW_HOURS="${SIMD_WIN_EVIDENCE_BILLING_WINDOW_HOURS:-24}"
JSON_OUT="${SIMD_WIN_EVIDENCE_PREFLIGHT_JSON:-${LOG_DIR}/win_preflight_latest.json}"
MD_OUT="${SIMD_WIN_EVIDENCE_PREFLIGHT_MD:-${LOG_DIR}/win_preflight_latest.md}"

mkdir -p "${LOG_DIR}"

write_outputs() {
  local aStatus
  local aCode
  local aExitCode
  local aMessage
  local aRepo
  local LCheckedAt

  aStatus="$1"
  aCode="$2"
  aExitCode="$3"
  aMessage="$4"
  aRepo="$5"
  LCheckedAt="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  python3 - "${JSON_OUT}" "${MD_OUT}" "${LCheckedAt}" "${aStatus}" "${aCode}" "${aExitCode}" "${WORKFLOW_FILE}" "${aRepo}" "${LOOKBACK_LIMIT}" "${BILLING_WINDOW_HOURS}" "${aMessage}" <<'PY'
import json
import sys
from pathlib import Path

json_path = Path(sys.argv[1])
md_path = Path(sys.argv[2])
checked_at = sys.argv[3]
status = sys.argv[4]
code = sys.argv[5]
exit_code = int(sys.argv[6])
workflow = sys.argv[7]
repo = sys.argv[8]
lookback = sys.argv[9]
billing = sys.argv[10]
message = sys.argv[11]

payload = {
    "checked_at_utc": checked_at,
    "status": status,
    "code": code,
    "exit_code": exit_code,
    "workflow_file": workflow,
    "repo": repo,
    "lookback_limit": int(lookback),
    "billing_window_hours": int(billing),
    "message": message,
}
json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
md_path.write_text(
    "# SIMD Windows Evidence Preflight (latest)\n\n"
    f"- Checked (UTC): {checked_at}\n"
    f"- Status: {status}\n"
    f"- Code: {code}\n"
    f"- Exit: {exit_code}\n"
    f"- Workflow: {workflow}\n"
    f"- Repo: {repo}\n"
    f"- Lookback: {lookback}\n"
    f"- Billing Window (hours): {billing}\n\n"
    "## Detail\n\n"
    f"{message}\n",
    encoding="utf-8",
)
PY
}

require_cmd() {
  local aCmd
  aCmd="$1"
  if ! command -v "${aCmd}" >/dev/null 2>&1; then
    write_outputs "FAIL" "MISSING_${aCmd^^}" 2 "missing command: ${aCmd}" "unknown"
    echo "[PREFLIGHT] Missing command: ${aCmd}"
    exit 2
  fi
}

require_cmd gh
require_cmd python3
require_cmd git

LRepo="${SIMD_WIN_EVIDENCE_REPO:-}"
if [[ -z "${LRepo}" ]]; then
  LRepo="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
fi
if [[ -z "${LRepo}" ]]; then
  LRepo="$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##' || true)"
fi
if [[ -z "${LRepo}" ]]; then
  LRepo="unknown"
fi

if ! gh auth status >/dev/null 2>&1; then
  write_outputs "FAIL" "GH_AUTH_REQUIRED" 2 "gh auth required" "${LRepo}"
  echo "[PREFLIGHT] gh auth required"
  exit 2
fi

LRunJson="$(gh run list --workflow "${WORKFLOW_FILE}" --limit "${LOOKBACK_LIMIT}" --json databaseId,createdAt,conclusion,status,url 2>/dev/null || true)"
if [[ -z "${LRunJson}" || "${LRunJson}" == "[]" ]]; then
  write_outputs "PASS" "CLEAN" 0 "workflow=${WORKFLOW_FILE}; no recent runs found" "${LRepo}"
  echo "[PREFLIGHT] PASS: no recent blocked workflow runs"
  exit 0
fi

LResult="$(python3 - "${LRunJson}" "${WORKFLOW_FILE}" "${LRepo}" "${LOOKBACK_LIMIT}" "${BILLING_WINDOW_HOURS}" <<'PY'
import json
import sys
from datetime import datetime, timezone

rows = json.loads(sys.argv[1])
workflow = sys.argv[2]
repo = sys.argv[3]
lookback = int(sys.argv[4])
window_hours = float(sys.argv[5])
now = datetime.now(timezone.utc)

for row in rows:
    created_at = row.get("createdAt")
    if not created_at:
        continue
    try:
        dt = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
    except ValueError:
        continue
    age_hours = (now - dt).total_seconds() / 3600.0
    if age_hours > window_hours:
        continue
    conclusion = str(row.get("conclusion") or "")
    if conclusion and conclusion.lower() == "success":
        continue
    run_id = row.get("databaseId")
    url = row.get("url") or ""
    print(f"CANDIDATE\t{run_id}\t{age_hours:.2f}\t{url}")
    sys.exit(0)

print(f"CLEAN\tworkflow={workflow}; lookback={lookback}; no recent billing-like failures within {window_hours:.0f}h")
PY
)"

if [[ "${LResult}" == CLEAN$'\t'* ]]; then
  LMessage="${LResult#CLEAN$'\t'}"
  write_outputs "PASS" "CLEAN" 0 "${LMessage}" "${LRepo}"
  echo "[PREFLIGHT] PASS: ${LMessage}"
  exit 0
fi

IFS=$'\t' read -r _ LRunId LAgeHours LRunUrl <<< "${LResult}"
LViewText="$(gh run view "${LRunId}" 2>/dev/null || true)"
LJobId="$(gh api "repos/${LRepo}/actions/runs/${LRunId}/jobs" --jq '.jobs[0].id // empty' 2>/dev/null || true)"
LBillingLine="$(printf '%s\n' "${LViewText}" | grep -Eim1 'billing|spending limit|payments have failed|Billing & plans' || true)"
if [[ -z "${LBillingLine}" ]]; then
  LBillingLine="recent workflow failure requires manual inspection"
fi
LMessage="workflow=${WORKFLOW_FILE}; run=${LRunId}; age_hours=${LAgeHours}; job=${LJobId:-unknown}; url=${LRunUrl}; message=${LBillingLine}"
if printf '%s' "${LBillingLine}" | grep -Eqi 'billing|spending limit|payments have failed|Billing & plans'; then
  write_outputs "FAIL" "RECENT_BILLING_BLOCK" 31 "${LMessage}" "${LRepo}"
  echo "[PREFLIGHT] FAIL: ${LMessage}"
  exit 31
fi

write_outputs "PASS" "CLEAN" 0 "${LMessage}" "${LRepo}"
echo "[PREFLIGHT] PASS: ${LMessage}"
