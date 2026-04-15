#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/run_windows_strict_l0_native_evidence_via_github_actions.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${TARGET_SCRIPT}" ]] || fail "missing Windows native evidence GH helper"

prepare_case_root() {
  local aRoot="${1:-}"

  mkdir -p "${aRoot}"
  cp "${TARGET_SCRIPT}" "${aRoot}/run_windows_strict_l0_native_evidence_via_github_actions.sh"
  chmod +x "${aRoot}/run_windows_strict_l0_native_evidence_via_github_actions.sh"

  cat > "${aRoot}/verify_windows_strict_l0_native_evidence.sh" <<'EOF'
#!/usr/bin/env bash
echo "[stub-verify] unexpected invocation: $*" >&2
exit 97
EOF
  chmod +x "${aRoot}/verify_windows_strict_l0_native_evidence.sh"

  cat > "${aRoot}/lib_github_actions_workflow_runs.sh" <<'EOF'
#!/usr/bin/env bash
GH_RUNLIB_LAST_STATUS=""
GH_RUNLIB_LAST_CONCLUSION=""
gh_runlib_find_latest_dispatch_run_id() {
  return 0
}
gh_runlib_get_run_head_sha() {
  printf '1111111111111111111111111111111111111111\n'
}
EOF
  chmod +x "${aRoot}/lib_github_actions_workflow_runs.sh"
}

run_case() {
  local aWaitRc="${1:-}"
  local aExpectedPattern="${2:-}"
  local aUnexpectedPattern="${3:-}"
  local LTmpDir
  local LOutput
  local LRc

  LTmpDir="$(mktemp -d)"
  trap 'rm -rf "'"${LTmpDir}"'"' RETURN

  prepare_case_root "${LTmpDir}"
  mkdir -p "${LTmpDir}/bin"

  cat > "${LTmpDir}/bin/gh" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "auth" && "${2:-}" == "status" ]]; then
  exit 0
fi
if [[ "${1:-}" == "run" && "${2:-}" == "view" ]]; then
  echo "[stub-gh] unexpected run view: $*" >&2
  exit 96
fi
echo "[stub-gh] unexpected invocation: $*" >&2
exit 99
EOF
  chmod +x "${LTmpDir}/bin/gh"

  python3 - "${LTmpDir}/lib_github_actions_workflow_runs.sh" "${aWaitRc}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
wait_rc = sys.argv[2]
text = path.read_text()
text += f"""
gh_runlib_wait_for_run_completion() {{
  GH_RUNLIB_LAST_STATUS="completed"
  GH_RUNLIB_LAST_CONCLUSION="failure"
  return {wait_rc}
}}
"""
path.write_text(text)
PY

  set +e
  LOutput="$(
    PATH="${LTmpDir}/bin:${PATH}" \
    L0_NATIVE_EVIDENCE_DOWNLOAD_ROOT="${LTmpDir}/downloads" \
    bash "${LTmpDir}/run_windows_strict_l0_native_evidence_via_github_actions.sh" TEST-BATCH 9101 2>&1
  )"
  LRc=$?
  set -e

  if [[ "${LRc}" != "1" ]]; then
    printf '%s\n' "${LOutput}" >&2
    fail "expected rc=1 for wait_rc=${aWaitRc}, got rc=${LRc}"
  fi

  if ! printf '%s' "${LOutput}" | rg -n -F "${aExpectedPattern}" >/dev/null; then
    printf '%s\n' "${LOutput}" >&2
    fail "wait_rc=${aWaitRc} missing expected output: ${aExpectedPattern}"
  fi

  if [[ -n "${aUnexpectedPattern}" ]] && printf '%s' "${LOutput}" | rg -n -F "${aUnexpectedPattern}" >/dev/null; then
    printf '%s\n' "${LOutput}" >&2
    fail "wait_rc=${aWaitRc} unexpectedly matched: ${aUnexpectedPattern}"
  fi
}

run_case 10 "[L0-NATIVE-EVIDENCE-GH] Workflow failed: run=9101, conclusion=failure" "Timeout waiting for workflow run completion"
run_case 11 "[L0-NATIVE-EVIDENCE-GH] Timeout waiting for workflow run completion: 9101" "Workflow failed: run=9101"

echo "[PASS] windows strict L0 native evidence wait rc contract"
