#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERIFIER_SCRIPT="${REPO_ROOT}/tests/verify_windows_strict_l0_native_evidence.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

require_literal_in_file() {
  local aFile="$1"
  local aPattern="$2"
  local aMessage="$3"

  if ! rg -n -F "${aPattern}" "${aFile}" >/dev/null; then
    fail "${aMessage}"
  fi
}

[[ -f "${VERIFIER_SCRIPT}" ]] || fail "missing L0 native evidence shell verifier"

require_literal_in_file "${VERIFIER_SCRIPT}" 'where_lazbuild_exe.txt' \
  "shell verifier does not require where_lazbuild evidence"
require_literal_in_file "${VERIFIER_SCRIPT}" 'module-logs' \
  "shell verifier does not require module log payloads"
require_literal_in_file "${VERIFIER_SCRIPT}" 'Downloaded artifact contract verified on Linux shell' \
  "shell verifier does not expose success marker"
require_literal_in_file "${VERIFIER_SCRIPT}" 'Downloaded artifact commit mismatch' \
  "shell verifier does not fail-close on commit mismatch"
require_literal_in_file "${VERIFIER_SCRIPT}" "tr -d '\\r'" \
  "shell verifier does not normalize CRLF content"

LTmpDir="$(mktemp -d)"
LSnapshot="${LTmpDir}/L0-TEST-SNAPSHOT"
LModuleLogDir="${LSnapshot}/module-logs"
LCommit="1234567890abcdef1234567890abcdef12345678"
LRef="l0-mainline-integration-20260409"

cleanup() {
  rm -rf "${LTmpDir}"
}
trap cleanup EXIT

mkdir -p "${LModuleLogDir}"

printf '[L0-NATIVE] strict L0 Windows native evidence capture\r\n[L0-NATIVE] Source: collect_windows_strict_l0_native_evidence.bat\r\n[L0-NATIVE] HostOS: Windows_NT\r\n[L0-NATIVE] Working dir: C:\\repo\\fafafa.core\r\n[L0-NATIVE] MatrixCommand: tests\\test_windows_strict_l0_batch_native_matrix.bat\r\n[L0-NATIVE] Total: 12\r\n[L0-NATIVE] Passed: 12\r\n[L0-NATIVE] Failed: 0\r\n[L0-NATIVE] MATRIX_EXIT_CODE=0\r\n' > "${LSnapshot}/evidence.log"
printf '# strict L0 Windows Native Evidence\r\n\r\n- Result: PASS\r\n' > "${LSnapshot}/summary.md"
printf 'git_commit=%s\r\ngit_ref_hint=%s\r\n' "${LCommit}" "${LRef}" > "${LSnapshot}/source_revision.txt"
printf 'host_os=Windows_NT\r\ntool_lazbuild_wrapper=C:\\repo\\fafafa.core\\tools\\lazbuild.bat\r\nwhere_lazbuild_exe=C:\\repo\\fafafa.core\\tests\\_windows_l0_native_evidence\\L0-TEST-SNAPSHOT\\where_lazbuild_exe.txt\r\n' > "${LSnapshot}/environment.txt"
printf '[PASS] strict L0 Windows native batch matrix verified\r\n' > "${LSnapshot}/native_matrix.log"
printf 'C:\\Lazarus\\lazbuild.exe\r\n' > "${LSnapshot}/where_lazbuild_exe.txt"

for LModuleName in \
  base.log \
  contracts.log \
  bits.log \
  layout.log \
  endian.log \
  span.log \
  option.log \
  result.log \
  platform.log \
  atomic.log \
  mem_allocator_foundation.log \
  mem_allocator_only.log; do
  printf '[BUILD] OK\r\n[TEST] OK\r\n[LEAK] OK\r\n' > "${LModuleLogDir}/${LModuleName}"
done

set +e
OUTPUT="$(bash "${VERIFIER_SCRIPT}" "${LSnapshot}" "${LCommit}" "${LRef}" 2>&1)"
RC=$?
set -e

if [[ "${RC}" != "0" ]]; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "shell verifier rejected a valid synthetic snapshot"
fi

if ! printf '%s' "${OUTPUT}" | rg -n 'Downloaded artifact contract verified on Linux shell|where lazbuild evidence' >/dev/null; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "shell verifier success output is missing expected markers"
fi

set +e
MISMATCH_OUTPUT="$(bash "${VERIFIER_SCRIPT}" "${LSnapshot}" deadbeef "${LRef}" 2>&1)"
MISMATCH_RC=$?
set -e

if [[ "${MISMATCH_RC}" == "0" ]]; then
  printf '%s\n' "${MISMATCH_OUTPUT}" >&2
  fail "shell verifier unexpectedly passed with a mismatched expected commit"
fi

if ! printf '%s' "${MISMATCH_OUTPUT}" | rg -n 'Downloaded artifact commit mismatch' >/dev/null; then
  printf '%s\n' "${MISMATCH_OUTPUT}" >&2
  fail "shell verifier mismatch output did not explain the commit mismatch"
fi

echo "[PASS] strict L0 native evidence shell verifier contract verified"
