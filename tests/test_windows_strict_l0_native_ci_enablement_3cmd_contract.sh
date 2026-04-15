#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HELPER_SCRIPT="${REPO_ROOT}/tests/print_windows_strict_l0_native_ci_enablement_3cmd.sh"
SAMPLE_BATCH_ID="L0-CHECK-CI"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${HELPER_SCRIPT}" ]] || fail "missing L0 native CI enablement 3cmd helper"

set +e
OUTPUT="$(bash "${HELPER_SCRIPT}" "${SAMPLE_BATCH_ID}" 2>&1)"
RC=$?
set -e

if [[ "${RC}" != "0" ]]; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "L0 native CI enablement 3cmd helper failed rc=${RC}"
fi

for LPatt in \
  '[CLOSEOUT] strict L0 Windows CI enablement' \
  'git switch -C l0-windows-ci-enablement origin/main' \
  'git cherry-pick 5c2c6e40 f8e2a09b 743af329 2bdbd479 1c09a01a 57faf2ef c3e7011e 1ca0af89 c1b77313 dd9b7421 0c7dcc96 db4527cb' \
  'git cherry-pick f8eb351c 08801ab1' \
  'gh pr create --base main --head l0-windows-ci-enablement' \
  'bash tests/preflight_windows_strict_l0_native_evidence_gh.sh' \
  'bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh L0-CHECK-CI' \
  'bash tests/test_windows_strict_l0_native_closeout_stack.sh' \
  '不要再把 `c1b77313^..db4527cb` 当成最小 CI registration slice' \
  'code=22' \
  'Windows native parity'; do
  if ! printf '%s' "${OUTPUT}" | rg -n -F "${LPatt}" >/dev/null; then
    printf '%s\n' "${OUTPUT}" >&2
    fail "L0 native CI enablement helper missing pattern: ${LPatt}"
  fi
done

echo "[PASS] strict L0 native CI enablement 3cmd contract verified"
