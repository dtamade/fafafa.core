#!/usr/bin/env bash

GH_RUNLIB_LAST_STATUS=""
GH_RUNLIB_LAST_CONCLUSION=""

gh_runlib_find_latest_dispatch_run_id() {
  local aWorkflowFile="${1:-}"
  local aHeadSha="${2:-}"
  local aHeadBranch="${3:-}"
  local aDispatchEpoch="${4:-0}"
  local aMatchMode="${5:-strict}"
  local LJson

  LJson="$(gh run list \
    --workflow "${aWorkflowFile}" \
    --limit 30 \
    --json databaseId,headSha,headBranch,event,createdAt 2>/dev/null || true)"

  if [[ -z "${LJson}" ]]; then
    return 0
  fi

  python3 - "${aHeadSha}" "${aHeadBranch}" "${aDispatchEpoch}" "${aMatchMode}" "${LJson}" <<'PY'
import json
import sys
from datetime import datetime

head_sha = sys.argv[1].strip().lower()
head_branch = sys.argv[2].strip()
dispatch_epoch = int(sys.argv[3] or "0")
match_mode = (sys.argv[4].strip() or "strict").lower()
raw = sys.argv[5].strip()
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

    if match_mode == "relaxed":
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
        continue

    if head_sha and row_sha != head_sha:
        continue
    if head_branch and row_branch != head_branch:
        continue
    if dispatch_epoch > 0 and row_epoch < dispatch_epoch - 10:
        continue

    candidate = (-row_epoch, int(run_id))
    if best is None or candidate < best:
        best = candidate

if best is None:
    sys.exit(0)

print(best[-1])
PY
}

gh_runlib_wait_for_run_completion() {
  local aRunId="${1:-}"
  local aPollSeconds="${2:-5}"
  local aPollMaxTries="${3:-60}"
  local LJson
  local LStatus
  local LConclusion

  GH_RUNLIB_LAST_STATUS=""
  GH_RUNLIB_LAST_CONCLUSION=""

  for ((LTry = 1; LTry <= aPollMaxTries; LTry++)); do
    LJson="$(gh run view "${aRunId}" --json status,conclusion 2>/dev/null || true)"
    if [[ -n "${LJson}" ]]; then
      read -r LStatus LConclusion < <(python3 - "${LJson}" <<'PY'
import json
import sys

raw = sys.argv[1].strip()
if not raw:
    print(" ")
    sys.exit(0)

obj = json.loads(raw)
print(f"{obj.get('status', '') or ''} {obj.get('conclusion', '') or ''}")
PY
)
      if [[ "${LStatus}" == "completed" ]]; then
        GH_RUNLIB_LAST_STATUS="${LStatus}"
        GH_RUNLIB_LAST_CONCLUSION="${LConclusion}"
        if [[ "${LConclusion}" == "success" ]]; then
          return 0
        fi
        return 10
      fi
    fi
    sleep "${aPollSeconds}"
  done

  GH_RUNLIB_LAST_STATUS="timeout"
  GH_RUNLIB_LAST_CONCLUSION=""
  return 11
}

gh_runlib_get_run_head_sha() {
  local aRunId="${1:-}"

  if [[ -z "${aRunId}" ]]; then
    return 0
  fi

  gh run view "${aRunId}" --json headSha 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin).get("headSha",""))'
}
