#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PREFLIGHT_SCRIPT="${REPO_ROOT}/tests/preflight_windows_strict_l0_native_evidence_gh.sh"

info() {
  echo "[INFO] $1"
}

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

run_case() {
  local aLabel="$1"
  shift

  info "${aLabel}"
  "$@"
}

probe_gh_preflight() {
  local LOutput
  local LRC

  set +e
  LOutput="$(bash "${PREFLIGHT_SCRIPT}" 2>&1)"
  LRC=$?
  set -e

  case "${LRC}" in
    0)
      echo "${LOutput}"
      info "GH preflight PASS"
      ;;
    22)
      echo "${LOutput}"
      info "GH preflight currently fail-close at workflow-not-found (default-branch registration still pending)"
      ;;
    23)
      echo "${LOutput}"
      info "GH preflight currently fail-close at workflow-disabled"
      ;;
    31)
      echo "${LOutput}"
      info "GH preflight currently fail-close at billing/runner block"
      ;;
    *)
      printf '%s\n' "${LOutput}" >&2
      fail "unexpected GH preflight rc=${LRC}"
      ;;
  esac
}

run_case "windows lazbuild bootstrap contract" \
  bash "${REPO_ROOT}/tests/test_windows_lazbuild_bootstrap.sh"
run_case "windows lazbuild smoke preflight contract" \
  bash "${REPO_ROOT}/tests/test_windows_lazbuild_smoke_preflight_contract.sh"
run_case "strict L0 native batch matrix contract" \
  bash "${REPO_ROOT}/tests/test_windows_strict_l0_batch_native_matrix_contract.sh"
run_case "strict L0 native evidence collector/verifier/workflow contract" \
  bash "${REPO_ROOT}/tests/test_windows_strict_l0_native_evidence_contract.sh"
run_case "strict L0 native evidence GH helper contract" \
  bash "${REPO_ROOT}/tests/test_windows_strict_l0_native_evidence_gh_contract.sh"
run_case "strict L0 native evidence shell verifier contract" \
  bash "${REPO_ROOT}/tests/test_windows_strict_l0_native_evidence_shell_verifier_contract.sh"
run_case "strict L0 native closeout 3cmd contract" \
  bash "${REPO_ROOT}/tests/test_windows_strict_l0_native_closeout_3cmd_contract.sh"

probe_gh_preflight

echo "[PASS] strict L0 Windows native closeout stack verified"
