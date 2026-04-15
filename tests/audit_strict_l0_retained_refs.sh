#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RETAINED_REFS=(
  "l0-mainline-closeout-20260411"
  "l0-sidecar-handoff-20260409"
  "l0-main-rescue"
  "l0-main-tail-cleanup-20260408-final"
)

print_usage() {
  cat <<'EOF'
Usage:
  bash tests/audit_strict_l0_retained_refs.sh
  bash tests/audit_strict_l0_retained_refs.sh --print-commands

This script audits the retained historical strict L0 refs non-destructively.
It never deletes refs; it only prints the current decision.
EOF
}

print_commands() {
  for LRef in "${RETAINED_REFS[@]}"; do
    printf '%s\n' "git merge-base HEAD ${LRef}"
    printf '%s\n' "git cherry -v HEAD ${LRef}"
  done
}

case "${1:-}" in
  --print-commands)
    print_commands
    exit 0
    ;;
  --help|-h)
    print_usage
    exit 0
    ;;
  "")
    ;;
  *)
    echo "[FAIL] unknown argument: ${1}" >&2
    print_usage >&2
    exit 2
    ;;
esac

LHeadSha="$(git -C "${REPO_ROOT}" rev-parse HEAD)"
echo "[INFO] strict L0 retained refs audit"
echo "[INFO] current_head=${LHeadSha}"

for LRef in "${RETAINED_REFS[@]}"; do
  LRefSha="$(git -C "${REPO_ROOT}" rev-parse "${LRef}")"
  LMergeBase="$(git -C "${REPO_ROOT}" merge-base HEAD "${LRef}")"
  LCherryOutput="$(git -C "${REPO_ROOT}" cherry -v HEAD "${LRef}" || true)"
  LUniqueCount="$(printf '%s\n' "${LCherryOutput}" | rg -c '^\+' || true)"
  LEquivalentCount="$(printf '%s\n' "${LCherryOutput}" | rg -c '^-' || true)"
  if [[ -z "${LUniqueCount}" ]]; then
    LUniqueCount=0
  fi
  if [[ -z "${LEquivalentCount}" ]]; then
    LEquivalentCount=0
  fi

  if [[ "${LRefSha}" == "${LHeadSha}" ]]; then
    LDecision="same-tip"
  elif [[ "${LUniqueCount}" != "0" ]]; then
    LDecision="retain-unique-history"
  else
    LDecision="candidate-delete"
  fi

  echo "== ${LRef} =="
  echo "ref_sha=${LRefSha}"
  echo "merge_base=${LMergeBase}"
  echo "unique_patch_count=${LUniqueCount}"
  echo "equivalent_patch_count=${LEquivalentCount}"
  echo "decision=${LDecision}"
done

echo "[PASS] strict L0 retained refs audit completed (non-destructive)"
