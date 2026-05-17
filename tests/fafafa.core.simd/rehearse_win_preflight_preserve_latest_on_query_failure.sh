#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PREFLIGHT_SCRIPT="${ROOT}/preflight_windows_b07_evidence_gh.sh"

if [[ ! -f "${PREFLIGHT_SCRIPT}" ]]; then
  echo "[PREFLIGHT-PRESERVE-LATEST] Missing script: ${PREFLIGHT_SCRIPT}"
  exit 2
fi

LTmpRoot="$(mktemp -d)"
cleanup() {
  rm -rf "${LTmpRoot}"
}
trap cleanup EXIT

LRepoRoot="${LTmpRoot}/repo"
mkdir -p "${LRepoRoot}/tests/fafafa.core.simd" "${LTmpRoot}/bin"
cp "${PREFLIGHT_SCRIPT}" "${LRepoRoot}/tests/fafafa.core.simd/"

git -C "${LRepoRoot}" init -q
git -C "${LRepoRoot}" remote add origin "https://github.com/example/simd-fallback.git"

mkdir -p "${LRepoRoot}/tests/fafafa.core.simd/logs"
cat > "${LRepoRoot}/tests/fafafa.core.simd/logs/win_preflight_latest.json" <<'EOF'
{
  "checked_at_utc": "2026-05-17T08:00:00Z",
  "status": "FAIL",
  "code": "RECENT_BILLING_BLOCK",
  "exit_code": 31,
  "message": "workflow=simd-windows-b07-evidence.yml; run=123; age_hours=0.80; url=https://github.com/example/simd-fallback/actions/runs/123; message=X The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings"
}
EOF

cat > "${LRepoRoot}/tests/fafafa.core.simd/logs/win_preflight_latest.md" <<'EOF'
# SIMD Windows Evidence Preflight (latest)

- Status: FAIL
- Code: RECENT_BILLING_BLOCK
EOF

cat > "${LTmpRoot}/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$1" == "auth" && "$2" == "status" ]]; then
  exit 0
fi

if [[ "$1" == "repo" && "$2" == "view" ]]; then
  cat <<'JSON'
{"nameWithOwner":"example/simd-fallback"}
JSON
  exit 0
fi

if [[ "$1" == "workflow" && "$2" == "list" ]]; then
  exit 0
fi

echo "unexpected gh args: $*" >&2
exit 2
EOF
chmod +x "${LTmpRoot}/bin/gh"

set +e
LRunOutput="$(
  cd "${LRepoRoot}" && \
  PATH="${LTmpRoot}/bin:${PATH}" \
  bash tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh 2>&1
)"
LRunRc=$?
set -e

printf '%s\n' "${LRunOutput}"

if [[ "${LRunRc}" != "31" ]]; then
  echo "[PREFLIGHT-PRESERVE-LATEST] FAILED: expected rc=31 but got ${LRunRc}"
  exit 1
fi

if ! grep -F -- "preserving latest RECENT_BILLING_BLOCK report" <<<"${LRunOutput}" >/dev/null; then
  echo "[PREFLIGHT-PRESERVE-LATEST] FAILED: missing preserve-latest note"
  exit 1
fi

if ! grep -F -- "STATUS=FAIL CODE=RECENT_BILLING_BLOCK EXIT=31" <<<"${LRunOutput}" >/dev/null; then
  echo "[PREFLIGHT-PRESERVE-LATEST] FAILED: stdout should surface preserved billing-block truth"
  exit 1
fi

if ! grep -F -- '"code": "RECENT_BILLING_BLOCK"' "${LRepoRoot}/tests/fafafa.core.simd/logs/win_preflight_latest.json" >/dev/null; then
  echo "[PREFLIGHT-PRESERVE-LATEST] FAILED: latest report should stay RECENT_BILLING_BLOCK"
  cat "${LRepoRoot}/tests/fafafa.core.simd/logs/win_preflight_latest.json"
  exit 1
fi

if ! grep -F -- '"code": "WORKFLOW_QUERY_FAILED"' "${LRepoRoot}/tests/fafafa.core.simd/logs/win_preflight_latest.diagnostic.json" >/dev/null; then
  echo "[PREFLIGHT-PRESERVE-LATEST] FAILED: diagnostic report missing WORKFLOW_QUERY_FAILED"
  cat "${LRepoRoot}/tests/fafafa.core.simd/logs/win_preflight_latest.diagnostic.json"
  exit 1
fi

cat > "${LRepoRoot}/tests/fafafa.core.simd/logs/win_preflight_latest.json" <<'EOF'
{
  "checked_at_utc": "2026-05-17T00:00:00Z",
  "status": "FAIL",
  "code": "RECENT_BILLING_BLOCK",
  "exit_code": 31,
  "message": "stale billing-block cache"
}
EOF

rm -f "${LRepoRoot}/tests/fafafa.core.simd/logs/win_preflight_latest.diagnostic.json" \
      "${LRepoRoot}/tests/fafafa.core.simd/logs/win_preflight_latest.diagnostic.md"

set +e
LStaleOutput="$(
  cd "${LRepoRoot}" && \
  PATH="${LTmpRoot}/bin:${PATH}" \
  bash tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh 2>&1
)"
LStaleRc=$?
set -e

printf '%s\n' "${LStaleOutput}"

if [[ "${LStaleRc}" != "24" ]]; then
  echo "[PREFLIGHT-PRESERVE-LATEST] FAILED: stale cache should keep rc=24 but got ${LStaleRc}"
  exit 1
fi

if grep -F -- "preserving latest RECENT_BILLING_BLOCK report" <<<"${LStaleOutput}" >/dev/null; then
  echo "[PREFLIGHT-PRESERVE-LATEST] FAILED: stale cache should not preserve latest billing-block truth"
  exit 1
fi

if ! grep -F -- '"code": "WORKFLOW_QUERY_FAILED"' "${LRepoRoot}/tests/fafafa.core.simd/logs/win_preflight_latest.json" >/dev/null; then
  echo "[PREFLIGHT-PRESERVE-LATEST] FAILED: stale cache should allow latest report to become WORKFLOW_QUERY_FAILED"
  cat "${LRepoRoot}/tests/fafafa.core.simd/logs/win_preflight_latest.json"
  exit 1
fi

echo "[PREFLIGHT-PRESERVE-LATEST] OK"
