#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HELPER_SCRIPT="${REPO_ROOT}/tests/print_windows_strict_l0_native_closeout_3cmd.sh"
SAMPLE_BATCH_ID="L0-CHECK-3CMD"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${HELPER_SCRIPT}" ]] || fail "missing L0 native closeout 3cmd helper"

set +e
OUTPUT="$(bash "${HELPER_SCRIPT}" "${SAMPLE_BATCH_ID}" 2>&1)"
RC=$?
set -e

if [[ "${RC}" != "0" ]]; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "L0 native closeout 3cmd helper failed rc=${RC}"
fi

for LPatt in \
  '[CLOSEOUT] strict L0 Windows native evidence handoff' \
  'bash tests/preflight_windows_strict_l0_native_evidence_gh.sh' \
  'bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh L0-CHECK-3CMD' \
  'set L0_WINDOWS_EVIDENCE_BATCH_ID=L0-CHECK-3CMD' \
  'tests\collect_windows_strict_l0_native_evidence.bat' \
  'tests\verify_windows_strict_l0_native_evidence.bat tests\_windows_l0_native_evidence\L0-CHECK-3CMD' \
  'bash tests/verify_windows_strict_l0_native_evidence.sh <snapshot-root> [expected-commit] [expected-ref]' \
  'bash tests/test_windows_strict_l0_native_closeout_stack.sh' \
  'code=22' \
  'fresh PASS'; do
  if ! printf '%s' "${OUTPUT}" | rg -n -F "${LPatt}" >/dev/null; then
    printf '%s\n' "${OUTPUT}" >&2
    fail "L0 native closeout 3cmd helper missing pattern: ${LPatt}"
  fi
done

echo "[PASS] strict L0 native closeout 3cmd contract verified"
