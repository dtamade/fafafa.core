#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/run_strict_l0_mainline_closeout.sh"
REAL_UPDATER_SCRIPT="${REPO_ROOT}/tests/update_strict_l0_current_state_docs.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

require_literal() {
  local aFile="${1:-}"
  local aLiteral="${2:-}"
  rg -F -- "${aLiteral}" "${aFile}" >/dev/null || fail "missing literal in ${aFile}: ${aLiteral}"
}

[[ -f "${TARGET_SCRIPT}" ]] || fail "missing strict L0 mainline closeout script"
[[ -f "${REAL_UPDATER_SCRIPT}" ]] || fail "missing strict L0 docs updater"

require_literal "${TARGET_SCRIPT}" "L0_MAINLINE_CLOSEOUT_REPO_ROOT"
require_literal "${TARGET_SCRIPT}" "L0_MAINLINE_CLOSEOUT_SHARED_GH_RUN_HELPER"
require_literal "${TARGET_SCRIPT}" "L0_MAINLINE_CLOSEOUT_WINDOWS_HELPER_SCRIPT"
require_literal "${TARGET_SCRIPT}" "L0_MAINLINE_CLOSEOUT_DOCS_UPDATER_SCRIPT"

LTmpDir="$(mktemp -d)"
trap 'rm -rf "${LTmpDir}"' EXIT

LTmpRepo="${LTmpDir}/repo"
LMockBin="${LTmpDir}/bin"
LSharedHelper="${LTmpDir}/shared-gh.sh"
LWindowsHelper="${LTmpDir}/windows-helper.sh"
LWindowsHelperMarker="${LTmpDir}/windows-helper.marker"
LAuditFile="${LTmpRepo}/docs/audits/2026-04-11-l0-current-state-audit.md"
LLegacyFile="${LTmpRepo}/docs/legacy/l0/2026-04-11-l0-mainline-refs-and-ci-closeout.md"
LWorkerFile="${LTmpRepo}/workers/worker1.md"
LMainSha="1111111111111111111111111111111111111111"
LOriginMainSha="2222222222222222222222222222222222222222"
LWorktreeSha="3333333333333333333333333333333333333333"
LWindowsSha="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
LBatchId="TEST-POSTMERGE-BATCH"

mkdir -p "${LTmpRepo}/docs/audits" "${LTmpRepo}/docs/legacy/l0" "${LTmpRepo}/workers" "${LMockBin}"

cat > "${LSharedHelper}" <<'EOF'
#!/usr/bin/env bash
gh_runlib_find_latest_dispatch_run_id() {
  echo "7001"
}

gh_runlib_wait_for_run_completion() {
  return 0
}

gh_runlib_get_run_head_sha() {
  local aRunId="${1:-}"
  case "${aRunId}" in
    7001)
      echo "1111111111111111111111111111111111111111"
      ;;
    8002)
      echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      ;;
    *)
      echo ""
      ;;
  esac
}
EOF
chmod +x "${LSharedHelper}"

cat > "${LWindowsHelper}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
[[ "\${1:-}" == "${LBatchId}" ]] || { echo "[FAIL] unexpected batch id: \${1:-}" >&2; exit 1; }
[[ "\${2:-}" == "8002" ]] || { echo "[FAIL] unexpected windows run id: \${2:-}" >&2; exit 1; }
[[ "\${L0_NATIVE_EVIDENCE_EXPECT_COMMIT:-}" == "${LWindowsSha}" ]] || { echo "[FAIL] unexpected expect commit: \${L0_NATIVE_EVIDENCE_EXPECT_COMMIT:-}" >&2; exit 1; }
[[ "\${L0_NATIVE_EVIDENCE_EXPECT_REF:-}" == "main" ]] || { echo "[FAIL] unexpected expect ref: \${L0_NATIVE_EVIDENCE_EXPECT_REF:-}" >&2; exit 1; }
printf '%s\n' "windows-helper-ok" > "${LWindowsHelperMarker}"
EOF
chmod +x "${LWindowsHelper}"

cat > "${LMockBin}/gh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${LMockBin}/gh"

cat > "${LMockBin}/git" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ "\${1:-}" == "-C" ]]; then
  shift 2
fi
case "\${1:-}" in
  ls-remote)
    printf '%s\trefs/heads/main\n' "${LOriginMainSha}"
    ;;
  rev-parse)
    if [[ "\${2:-}" == "--verify" && "\${3:-}" == "refs/heads/main^{commit}" ]]; then
      printf '%s\n' "${LMainSha}"
    elif [[ "\${2:-}" == "HEAD" ]]; then
      printf '%s\n' "${LWorktreeSha}"
    fi
    ;;
esac
EOF
chmod +x "${LMockBin}/git"

cat > "${LMockBin}/python3" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/python3 "$@"
EOF
chmod +x "${LMockBin}/python3"

LPrintOutput="$(
  PATH="${LMockBin}:$PATH" \
  L0_MAINLINE_CLOSEOUT_REPO_ROOT="${LTmpRepo}" \
  L0_MAINLINE_CLOSEOUT_SHARED_GH_RUN_HELPER="${LSharedHelper}" \
  L0_MAINLINE_CLOSEOUT_WINDOWS_HELPER_SCRIPT="${LWindowsHelper}" \
  L0_MAINLINE_CLOSEOUT_DOCS_UPDATER_SCRIPT="${REAL_UPDATER_SCRIPT}" \
  L0_MAINLINE_CLOSEOUT_WINDOWS_LOCAL_BATCH_ID="${LBatchId}" \
  bash "${TARGET_SCRIPT}" --print-commands
)" || fail "closeout print-commands contract failed"

printf '%s\n' "${LPrintOutput}" | rg -F -- "--linux-run-sha <linux-run-sha>" >/dev/null \
  || fail "print-commands missing linux run sha placeholder"
printf '%s\n' "${LPrintOutput}" | rg -F -- "--windows-run-sha <windows-run-sha>" >/dev/null \
  || fail "print-commands missing windows run sha placeholder"
printf '%s\n' "${LPrintOutput}" | rg -F -- "--origin-main-sha <origin-main-sha>" >/dev/null \
  || fail "print-commands missing origin/main sha placeholder"
printf '%s\n' "${LPrintOutput}" | rg -F -- "--worktree-sha <worktree-sha>" >/dev/null \
  || fail "print-commands missing worktree sha placeholder"

PATH="${LMockBin}:$PATH" \
L0_MAINLINE_CLOSEOUT_REPO_ROOT="${LTmpRepo}" \
L0_MAINLINE_CLOSEOUT_SHARED_GH_RUN_HELPER="${LSharedHelper}" \
L0_MAINLINE_CLOSEOUT_WINDOWS_HELPER_SCRIPT="${LWindowsHelper}" \
L0_MAINLINE_CLOSEOUT_DOCS_UPDATER_SCRIPT="${REAL_UPDATER_SCRIPT}" \
L0_MAINLINE_CLOSEOUT_WINDOWS_LOCAL_BATCH_ID="${LBatchId}" \
bash "${TARGET_SCRIPT}" \
  --apply-docs \
  --main-sha "${LMainSha}" \
  --linux-run-id "7001" \
  --windows-run-id "8002" \
  --windows-sha "${LWindowsSha}" >/dev/null 2>&1 \
  || fail "closeout post-merge apply-docs flow failed"

[[ -f "${LWindowsHelperMarker}" ]] || fail "closeout did not execute the injected Windows helper"
[[ -f "${LAuditFile}" ]] || fail "closeout did not backfill audit file"
[[ -f "${LLegacyFile}" ]] || fail "closeout did not backfill legacy file"
[[ -f "${LWorkerFile}" ]] || fail "closeout did not backfill worker file"

require_literal "${LAuditFile}" "GitHub Actions \`L0 Linux Maintenance\` run \`7001\`"
require_literal "${LAuditFile}" "GitHub Actions \`L0 Windows Native Evidence\` run \`8002\`"
require_literal "${LAuditFile}" "仍锚定 \`main@${LWindowsSha}\`"
require_literal "${LAuditFile}" "当前本地 \`main\` head：\`${LMainSha}\`"
require_literal "${LAuditFile}" "当前 \`origin/main\` head：\`${LOriginMainSha}\`"
require_literal "${LAuditFile}" "当前 L0 worktree head：\`${LWorktreeSha}\`"
require_literal "${LAuditFile}" "docs_absorb_candidate_paths="
require_literal "${LAuditFile}" "test_hygiene_candidate_paths="
require_literal "${LAuditFile}" "source_review_candidate_paths="
require_literal "${LAuditFile}" "dangerous_delete_paths="
require_literal "${LAuditFile}" "reject_wholesale_absorb="

require_literal "${LLegacyFile}" "HTTP 404"
require_literal "${LLegacyFile}" "当前本地 \`main\` 已推进到 \`${LMainSha}\`；当前 \`origin/main\` 仍在 \`${LOriginMainSha}\`；latest exact Windows native evidence 仍锚定 \`main@${LWindowsSha}\`"

require_literal "${LWorkerFile}" "仍锚定 \`main@${LWindowsSha}\`"
require_literal "${LWorkerFile}" "Remote main head: \`${LOriginMainSha}\` (\`origin/main\`)"
require_literal "${LWorkerFile}" "Current HEAD: \`${LWorktreeSha}\`"
require_literal "${LWorkerFile}" "docs/plans/2026-04-16-l0-mainline-continuation-plan.md"
require_literal "${LWorkerFile}" "--origin-main-sha <origin-main-sha> --worktree-sha <worktree-sha>"
require_literal "${LWorkerFile}" "docs_absorb_candidate_paths="
require_literal "${LWorkerFile}" "test_hygiene_candidate_paths="
require_literal "${LWorkerFile}" "source_review_candidate_paths="
require_literal "${LWorkerFile}" "dangerous_delete_paths="
require_literal "${LWorkerFile}" "reject_wholesale_absorb=yes"

echo "[PASS] strict L0 mainline closeout post-merge contract verified"
