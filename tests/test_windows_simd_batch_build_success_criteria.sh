#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BATCH_RUNNER="${REPO_ROOT}/tests/fafafa.core.simd/buildOrTest.bat"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

if [[ ! -f "${BATCH_RUNNER}" ]]; then
  fail "missing SIMD batch runner: ${BATCH_RUNNER}"
fi

if ! command -v wine >/dev/null 2>&1; then
  echo "[SKIP] wine not found; skip Windows SIMD batch success-criteria smoke"
  exit 0
fi

win_path() {
  printf 'Z:\\%s' "$(printf '%s' "$1" | sed 's#^/##; s#/#\\\\#g')"
}

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/simd-batch-success-XXXXXX")"
trap 'rm -rf "${TMP_DIR}"' EXIT

WIN_REPO_ROOT="$(win_path "${REPO_ROOT}")"
WIN_TMP_DIR="$(win_path "${TMP_DIR}")"

cat > "${TMP_DIR}/success.log" <<'EOF'
Info: (lazarus) Execute Title="Compile Project, Mode: Release, Target: C:\repo\tests\fafafa.core.simd\bin2\fafafa.core.simd.test.exe"
(9015) Linking C:\repo\tests\fafafa.core.simd\bin2\fafafa.core.simd.test.exe
(1008) 42 lines compiled, 0.1 sec, 4096 bytes code, 128 bytes data
(1021) 1 warning(s) issued
(1022) 1 hint(s) issued
EOF

cat > "${TMP_DIR}/failure.log" <<'EOF'
Fatal: synthetic lazbuild failure
returned an error exitcode
EOF

cat > "${TMP_DIR}/fake_success_lazbuild.bat" <<EOF
@echo off
type ${WIN_TMP_DIR}\\success.log
exit /b 1
EOF

cat > "${TMP_DIR}/fake_failure_lazbuild.bat" <<EOF
@echo off
type ${WIN_TMP_DIR}\\failure.log
exit /b 1
EOF

cat > "${TMP_DIR}/fake_zero_rc_lazbuild.bat" <<EOF
@echo off
type ${WIN_TMP_DIR}\\success.log
exit /b 0
EOF

cat > "${TMP_DIR}/run_success.bat" <<EOF
@echo off
cd /d ${WIN_REPO_ROOT}
set "LAZBUILD=${WIN_TMP_DIR}\\fake_success_lazbuild.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\success-out"
call tests\\fafafa.core.simd\\buildOrTest.bat build
exit /b %ERRORLEVEL%
EOF

cat > "${TMP_DIR}/run_failure.bat" <<EOF
@echo off
cd /d ${WIN_REPO_ROOT}
set "LAZBUILD=${WIN_TMP_DIR}\\fake_failure_lazbuild.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\failure-out"
call tests\\fafafa.core.simd\\buildOrTest.bat build
exit /b %ERRORLEVEL%
EOF

cat > "${TMP_DIR}/run_zero_rc.bat" <<EOF
@echo off
cd /d ${WIN_REPO_ROOT}
set "LAZBUILD=${WIN_TMP_DIR}\\fake_zero_rc_lazbuild.bat"
set "SIMD_OUTPUT_ROOT=${WIN_TMP_DIR}\\zero-rc-out"
call tests\\fafafa.core.simd\\buildOrTest.bat build
exit /b %ERRORLEVEL%
EOF

set +e
SUCCESS_OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_success.bat" 2>&1)"
SUCCESS_RC=$?
set -e

if [[ ${SUCCESS_RC} -ne 0 ]]; then
  printf '%s\n' "${SUCCESS_OUTPUT}" >&2
  fail "synthetic compiled-summary batch case should succeed"
fi

if ! printf '%s' "${SUCCESS_OUTPUT}" | rg -n "\[BUILD\] WARN .*compile/link summary is present" >/dev/null; then
  printf '%s\n' "${SUCCESS_OUTPUT}" >&2
  fail "synthetic compiled-summary batch case did not emit the expected warn marker"
fi

if ! printf '%s' "${SUCCESS_OUTPUT}" | rg -n "\[BUILD\] OK" >/dev/null; then
  printf '%s\n' "${SUCCESS_OUTPUT}" >&2
  fail "synthetic compiled-summary batch case did not finish with BUILD OK"
fi

set +e
ZERO_RC_OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_zero_rc.bat" 2>&1)"
ZERO_RC_RC=$?
set -e

if [[ ${ZERO_RC_RC} -ne 0 ]]; then
  printf '%s\n' "${ZERO_RC_OUTPUT}" >&2
  fail "synthetic zero-rc compiled-summary batch case should succeed"
fi

if ! printf '%s' "${ZERO_RC_OUTPUT}" | rg -n "\[BUILD\] WARN .*expected binary path probe missed" >/dev/null; then
  printf '%s\n' "${ZERO_RC_OUTPUT}" >&2
  fail "synthetic zero-rc compiled-summary batch case did not emit the expected warn marker"
fi

if ! printf '%s' "${ZERO_RC_OUTPUT}" | rg -n "\[BUILD\] OK" >/dev/null; then
  printf '%s\n' "${ZERO_RC_OUTPUT}" >&2
  fail "synthetic zero-rc compiled-summary batch case did not finish with BUILD OK"
fi

set +e
FAILURE_OUTPUT="$(wine cmd /c "${WIN_TMP_DIR}\\run_failure.bat" 2>&1)"
FAILURE_RC=$?
set -e

if [[ ${FAILURE_RC} -eq 0 ]]; then
  printf '%s\n' "${FAILURE_OUTPUT}" >&2
  fail "synthetic fatal batch case should fail"
fi

if ! printf '%s' "${FAILURE_OUTPUT}" | rg -n "\[BUILD\] FAILED" >/dev/null; then
  printf '%s\n' "${FAILURE_OUTPUT}" >&2
  fail "synthetic fatal batch case did not emit BUILD FAILED"
fi

echo "[PASS] windows SIMD batch success criteria verified"
