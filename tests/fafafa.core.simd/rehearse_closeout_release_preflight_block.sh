#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LBuildScript="${ROOT}/BuildOrTest.sh"

if [[ ! -f "${LBuildScript}" ]]; then
  echo "[CLOSEOUT-RELEASE-PREFLIGHT-REHEARSAL] Missing runner: ${LBuildScript}"
  exit 2
fi

LTmpRoot="$(mktemp -d)"
cleanup() {
  rm -rf "${LTmpRoot}"
}
trap cleanup EXIT

LStubRoot="${LTmpRoot}/stub_root"
mkdir -p "${LStubRoot}/logs"

cat > "${LStubRoot}/logs/win_preflight_latest.json" <<'EOM'
{
  "checked_at_utc": "2026-05-17T05:28:29Z",
  "status": "FAIL",
  "code": "RECENT_BILLING_BLOCK",
  "exit_code": 31
}
EOM

LFunctionFile="${LTmpRoot}/closeout_release_funcs.sh"
sed -n '/^win_preflight_latest_json_path()/,/^run_win_evidence_preflight()/p' "${LBuildScript}" | sed '$d' > "${LFunctionFile}"

if [[ ! -s "${LFunctionFile}" ]]; then
  echo "[CLOSEOUT-RELEASE-PREFLIGHT-REHEARSAL] FAILED: extracted function block is empty"
  exit 1
fi

LOutput="$(
  ROOT="${LStubRoot}" \
  SIMD_WIN_PREFLIGHT_JSON_FILE="${LStubRoot}/logs/win_preflight_latest.json" \
  CLOSEOUT_RELEASE_FUNCTION_FILE="${LFunctionFile}" \
  bash <<'EOF'
set -euo pipefail

source "${CLOSEOUT_RELEASE_FUNCTION_FILE}"

run_x86_impl_smoke() {
  echo "[TEST-STUB] x86"
}

run_closeout_host_local() {
  echo "[TEST-STUB] host-local"
}

run_win_evidence_preflight() {
  return 31
}

run_win_evidence_via_gh() {
  echo "SHOULD-NOT-RUN-GH"
  return 97
}

run_freeze_status() {
  echo "SHOULD-NOT-RUN-FREEZE"
  return 98
}

set +e
LRunOutput="$(run_closeout_release SIMD-REHEARSE-152 2>&1)"
LRunRC=$?
set -e

printf '%s\n' "${LRunOutput}"

if [[ "${LRunRC}" != "31" ]]; then
  echo "[CLOSEOUT-RELEASE-PREFLIGHT-REHEARSAL] FAILED: expected rc=31 but got ${LRunRC}"
  exit 1
fi

if ! grep -F -- "[CLOSEOUT-RELEASE] STOP latest preflight is RECENT_BILLING_BLOCK" <<<"${LRunOutput}" >/dev/null; then
  echo "[CLOSEOUT-RELEASE-PREFLIGHT-REHEARSAL] FAILED: missing stop note"
  exit 1
fi

if ! grep -F -- "[CLOSEOUT-RELEASE] state=code-green / release-evidence-blocked" <<<"${LRunOutput}" >/dev/null; then
  echo "[CLOSEOUT-RELEASE-PREFLIGHT-REHEARSAL] FAILED: missing state line"
  exit 1
fi

if ! grep -F -- "bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd SIMD-REHEARSE-152" <<<"${LRunOutput}" >/dev/null; then
  echo "[CLOSEOUT-RELEASE-PREFLIGHT-REHEARSAL] FAILED: missing win-closeout-3cmd hint"
  exit 1
fi

if grep -F -- "SHOULD-NOT-RUN-GH" <<<"${LRunOutput}" >/dev/null; then
  echo "[CLOSEOUT-RELEASE-PREFLIGHT-REHEARSAL] FAILED: GH step should not run after preflight block"
  exit 1
fi

if grep -F -- "SHOULD-NOT-RUN-FREEZE" <<<"${LRunOutput}" >/dev/null; then
  echo "[CLOSEOUT-RELEASE-PREFLIGHT-REHEARSAL] FAILED: freeze-status should not run after preflight block"
  exit 1
fi
EOF
)"

printf '%s\n' "${LOutput}"
echo "[CLOSEOUT-RELEASE-PREFLIGHT-REHEARSAL] OK"
