#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_FILE="${1:-${L0_NATIVE_EVIDENCE_WORKFLOW_FILE:-l0-windows-native-evidence.yml}}"
LOOKBACK_LIMIT="${L0_NATIVE_EVIDENCE_GH_LOOKBACK_LIMIT:-20}"

print_usage() {
  cat <<EOF
Usage: $0 [workflow-file]

Default workflow: l0-windows-native-evidence.yml

Exit codes:
  0   PASS
  20  missing command
  21  gh auth required
  22  workflow not found
  23  workflow disabled
  24  preflight api/parse error
  31  recent billing/runner block detected
EOF
}

fail_with() {
  local aCode="$1"
  local aLabel="$2"
  local aMessage="$3"

  echo "[L0-NATIVE-GH-PREFLIGHT] ${aLabel}: ${aMessage}"
  exit "${aCode}"
}

pass_with() {
  local aMessage="$1"
  echo "[L0-NATIVE-GH-PREFLIGHT] OK: ${aMessage}"
  exit 0
}

extract_billing_block_message() {
  local aText="${1:-}"
  local LNormalized

  LNormalized="$(printf '%s' "${aText}" | tr '[:upper:]' '[:lower:]')"
  if [[ "${LNormalized}" == *"recent account payments have failed"* ]]; then
    echo "recent account payments have failed"
    return 0
  fi
  if [[ "${LNormalized}" == *"spending limit needs to be increased"* ]]; then
    echo "spending limit needs to be increased"
    return 0
  fi
  if [[ "${LNormalized}" == *"billing & plans"* ]]; then
    echo "billing and plans access required"
    return 0
  fi
  return 1
}

if [[ "${WORKFLOW_FILE}" == "-h" || "${WORKFLOW_FILE}" == "--help" ]]; then
  print_usage
  exit 0
fi

for LCmd in gh python3 git; do
  if ! command -v "${LCmd}" >/dev/null 2>&1; then
    fail_with 20 "MISSING_COMMAND" "missing command: ${LCmd}"
  fi
done

if ! gh auth status >/dev/null 2>&1; then
  fail_with 21 "AUTH_REQUIRED" "gh auth required"
fi

if ! [[ "${LOOKBACK_LIMIT}" =~ ^[1-9][0-9]*$ ]]; then
  fail_with 24 "INVALID_ARGS" "lookback must be positive integer: ${LOOKBACK_LIMIT}"
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
    return (
        path_lower.endswith("/" + target)
        or path_lower == target
        or name_lower == target
    )

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
  pass_with "workflow=${WORKFLOW_FILE}, repo=${LRepo}, note=no run history"
fi

mapfile -t LCandidateRuns < <(
  python3 - "${LRunsJson}" <<'PY'
import json
import sys
from datetime import datetime, timezone

rows = json.loads(sys.argv[1])
now = datetime.now(timezone.utc)
for row in rows:
    run_id = row.get("databaseId")
    created = str(row.get("createdAt", "")).strip()
    url = str(row.get("url", "")).strip()
    if run_id is None or not created:
        continue
    if created.endswith("Z"):
        created = created[:-1] + "+00:00"
    try:
        age_hours = (now - datetime.fromisoformat(created)).total_seconds() / 3600.0
    except Exception:
        continue
    print(f"{run_id}\t{age_hours:.2f}\t{url}")
PY
)

for LRunRow in "${LCandidateRuns[@]}"; do
  IFS=$'\t' read -r LRunId LAgeHours LRunUrl <<<"${LRunRow}"
  LRunViewText="$(gh run view "${LRunId}" 2>/dev/null || true)"
  LBillingMsg="$(extract_billing_block_message "${LRunViewText}" || true)"
  if [[ -n "${LBillingMsg}" ]]; then
    fail_with 31 "RECENT_BILLING_BLOCK" "workflow=${WORKFLOW_FILE}; run=${LRunId}; age_hours=${LAgeHours}; url=${LRunUrl}; message=${LBillingMsg}"
  fi
done

pass_with "workflow=${WORKFLOW_FILE}, repo=${LRepo}, state=${LWorkflowState}"
