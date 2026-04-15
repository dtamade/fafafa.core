#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/run_strict_l0_mainline_closeout.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${TARGET_SCRIPT}" ]] || fail "missing strict L0 mainline closeout script"

run_case() {
  local aWaitRc="${1:-}"
  local aExpectedPattern="${2:-}"
  local aUnexpectedPattern="${3:-}"
  local LTmpDir
  local LStubHelper
  local LOutput
  local LRc

  LTmpDir="$(mktemp -d)"
  trap 'rm -rf "'"${LTmpDir}"'"' RETURN

  mkdir -p "${LTmpDir}/bin"

  cat > "${LTmpDir}/bin/git" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-C" ]]; then
  shift 2
fi
case "${1:-}" in
  ls-remote)
    printf '1111111111111111111111111111111111111111\trefs/heads/main\n'
    exit 0
    ;;
  rev-parse)
    case "${2:-}" in
      --verify)
        printf '1111111111111111111111111111111111111111\n'
        exit 0
        ;;
      HEAD)
        printf '1111111111111111111111111111111111111111\n'
        exit 0
        ;;
    esac
    ;;
esac
echo "[stub-git] unexpected invocation: $*" >&2
exit 99
EOF
  chmod +x "${LTmpDir}/bin/git"

  cat > "${LTmpDir}/bin/gh" <<'EOF'
#!/usr/bin/env bash
echo "[stub-gh] unexpected invocation: $*" >&2
exit 99
EOF
  chmod +x "${LTmpDir}/bin/gh"

  LStubHelper="${LTmpDir}/stub_helper.sh"
  cat > "${LStubHelper}" <<EOF
#!/usr/bin/env bash
GH_RUNLIB_LAST_STATUS=""
GH_RUNLIB_LAST_CONCLUSION=""
gh_runlib_wait_for_run_completion() {
  GH_RUNLIB_LAST_STATUS="completed"
  GH_RUNLIB_LAST_CONCLUSION="failure"
  return ${aWaitRc}
}
gh_runlib_get_run_head_sha() {
  printf '1111111111111111111111111111111111111111\n'
}
gh_runlib_find_latest_dispatch_run_id() {
  return 0
}
EOF
  chmod +x "${LStubHelper}"

  set +e
  LOutput="$(
    PATH="${LTmpDir}/bin:${PATH}" \
    L0_MAINLINE_CLOSEOUT_REPO_ROOT="${LTmpDir}" \
    L0_MAINLINE_CLOSEOUT_SHARED_GH_RUN_HELPER="${LStubHelper}" \
    bash "${TARGET_SCRIPT}" --linux-run-id 9101 --skip-windows 2>&1
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

run_case 10 "[L0-MAINLINE-CLOSEOUT] Workflow failed: run=9101, conclusion=failure" "Timeout waiting for run completion"
run_case 11 "[L0-MAINLINE-CLOSEOUT] Timeout waiting for run completion: 9101" "Workflow failed: run=9101"

echo "[PASS] strict L0 mainline closeout wait rc contract"
