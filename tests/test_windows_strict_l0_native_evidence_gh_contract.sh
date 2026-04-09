#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PREFLIGHT_SCRIPT="${REPO_ROOT}/tests/preflight_windows_strict_l0_native_evidence_gh.sh"
HELPER_SCRIPT="${REPO_ROOT}/tests/run_windows_strict_l0_native_evidence_via_github_actions.sh"
SHELL_VERIFIER_SCRIPT="${REPO_ROOT}/tests/verify_windows_strict_l0_native_evidence.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

info() {
  echo "[INFO] $1"
}

require_literal_in_file() {
  local aFile="$1"
  local aPattern="$2"
  local aMessage="$3"
  if ! rg -n -F "${aPattern}" "${aFile}" >/dev/null; then
    fail "${aMessage}"
  fi
}

[[ -f "${PREFLIGHT_SCRIPT}" ]] || fail "missing L0 native GH preflight script"
[[ -f "${HELPER_SCRIPT}" ]] || fail "missing L0 native GH helper script"
[[ -f "${SHELL_VERIFIER_SCRIPT}" ]] || fail "missing L0 native shell verifier script"

require_literal_in_file "${PREFLIGHT_SCRIPT}" 'gh workflow list --all' \
  "preflight does not query workflow list"
require_literal_in_file "${PREFLIGHT_SCRIPT}" 'gh auth status' \
  "preflight does not require gh auth"
require_literal_in_file "${PREFLIGHT_SCRIPT}" 'WORKFLOW_NOT_FOUND' \
  "preflight does not expose workflow-not-found failure"
require_literal_in_file "${PREFLIGHT_SCRIPT}" 'RECENT_BILLING_BLOCK' \
  "preflight does not expose billing-block failure"

require_literal_in_file "${HELPER_SCRIPT}" 'gh workflow run' \
  "GH helper does not dispatch workflows"
require_literal_in_file "${HELPER_SCRIPT}" 'gh run download' \
  "GH helper does not download workflow artifacts"
require_literal_in_file "${HELPER_SCRIPT}" 'l0-windows-native-evidence.yml' \
  "GH helper does not target the L0 workflow"
require_literal_in_file "${HELPER_SCRIPT}" 'l0-windows-native-evidence' \
  "GH helper does not target the L0 artifact name"
require_literal_in_file "${HELPER_SCRIPT}" 'Refuse dispatch: local worktree has uncommitted changes.' \
  "GH helper does not fail-close on dirty local state"
require_literal_in_file "${HELPER_SCRIPT}" 'Workflow is not registered on GitHub Actions.' \
  "GH helper does not explain missing workflow registration"
require_literal_in_file "${HELPER_SCRIPT}" 'GitHub only exposes workflow_dispatch for workflows present on the repository default branch.' \
  "GH helper does not explain default-branch workflow registration"
require_literal_in_file "${HELPER_SCRIPT}" 'verify_windows_strict_l0_native_evidence.sh' \
  "GH helper does not invoke the shell verifier"
require_literal_in_file "${HELPER_SCRIPT}" 'Missing shell verifier:' \
  "GH helper does not fail-close when the shell verifier is absent"

set +e
OUTPUT="$(bash "${PREFLIGHT_SCRIPT}" 2>&1)"
RC=$?
set -e

case "${RC}" in
  0)
    if ! printf '%s' "${OUTPUT}" | rg -n 'OK:' >/dev/null; then
      printf '%s\n' "${OUTPUT}" >&2
      fail "preflight passed without an OK marker"
    fi
    ;;
  22)
    if ! printf '%s' "${OUTPUT}" | rg -n 'WORKFLOW_NOT_FOUND|workflow not found' >/dev/null; then
      printf '%s\n' "${OUTPUT}" >&2
      fail "preflight rc=22 without workflow-not-found guidance"
    fi
    ;;
  23)
    if ! printf '%s' "${OUTPUT}" | rg -n 'WORKFLOW_DISABLED|workflow state is not active' >/dev/null; then
      printf '%s\n' "${OUTPUT}" >&2
      fail "preflight rc=23 without workflow-disabled guidance"
    fi
    ;;
  31)
    if ! printf '%s' "${OUTPUT}" | rg -n 'RECENT_BILLING_BLOCK|billing' >/dev/null; then
      printf '%s\n' "${OUTPUT}" >&2
      fail "preflight rc=31 without billing-block guidance"
    fi
    ;;
  *)
    printf '%s\n' "${OUTPUT}" >&2
    fail "unexpected preflight rc=${RC}"
    ;;
esac

echo "[PASS] strict L0 native evidence GH contract verified"
